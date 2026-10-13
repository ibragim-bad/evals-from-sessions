# Harbor contract (minimal)

The skill works with any recent Harbor. The examples below use Harbor 0.24.0 syntax:
every command was checked with `--help` and run on a toy task under 0.24.0. On another
version, confirm the flags with `harbor run --help`, `harbor task init --help` and
`harbor check --help` before use, and keep `schema_version` from the `harbor task init`
skeleton.

Install: `uv tool install harbor`. Leak scans: gitleaks 8 (`gitleaks dir`).

## Task layout

```
<task-name>/
  instruction.md          # the prompt; first line = canary comment (stripped by Harbor)
  task.toml               # name, version, timeouts, resources, network, metadata
  environment/Dockerfile  # build context = environment/ ; agent works in WORKDIR
  environment/repo/       # private: git archive of the parent commit; shareable: new starter
  tests/test.sh           # verifier entrypoint (uploaded only for verification)
  tests/verify.py         # checks + canary line; hidden fixtures next to it
  solution/solve.sh       # reference solution (uploaded only for the oracle agent)
  solution/fix.patch      # private mode: the episode diff
  provenance.md           # authoring notes; never copied into the image
```

`harbor task init personal/<task-name> -p <tasks-dir> --no-pytest` creates the
skeleton; copy the template files over it.

## Container paths

| Path | Meaning |
|---|---|
| `WORKDIR` of the Dockerfile (template: `/app`) | where the agent starts |
| `/tests` | `tests/` contents, present only during verification |
| `/solution` | `solution/` contents, present only for `-a oracle` |
| `/logs/verifier/reward.txt` | `1` or `0`; a missing file is a Harbor error (`RewardFileNotFoundError`), not a `0` |
| `/logs/agent/` | agent logs, downloaded into the trial dir |

By default the verifier runs in the agent's container after the agent finishes
(`[verifier] environment_mode = "shared"`), so it sees the final files and git state.

## Canary

Harbor strips leading instruction lines that are an HTML comment or `#` comment
containing the word `canary`, so the agent never sees them. Put the same GUID in
`tests/verify.py`. The template ships one GUID; generate a new one per benchmark with
`python3 -c "import uuid; print(uuid.uuid4())"`.

## task.toml

```toml
schema_version = "1.4"   # 0.24.0; use the value from your `harbor task init` skeleton

[task]
name = "personal/<task-name>"
version = "1.0.0"
description = "<one line>"

[metadata]               # free-form
source_session = "<id>"
category = "<category>"
mode = "private"         # or "shareable"
visibility = "private"

[verifier]
timeout_sec = 120.0

[agent]
timeout_sec = 1200.0

[environment]
network_mode = "public"
build_timeout_sec = 600.0
cpus = 2
memory_mb = 2048
storage_mb = 4096
```

## Network

`network_mode` is `public` (default), `allowlist` or `no-network`. The agent needs the
network to reach its model API and to install itself.

- **Private tasks: `public` is fine.** The repository and its fix exist only on your
  machine, so the agent cannot find the solution online.
- **Synthetic shareable tasks: `public` is fine** too. An allowlist ties the task to
  one agent's install hosts, and other scaffolds need other hosts.
- **Anything derived from public code** (an open-source repository, a public issue or
  PR): use `network_mode = "allowlist"`, with the agent phase limited to the model
  endpoint (and package registries if the task needs them), or reject the episode.
  Otherwise the agent can fetch the upstream fix.

```toml
[agent]                   # agent phase only: the model API (+ registries if needed)
network_mode = "allowlist"
allowed_hosts = ["api.openai.com"]

[environment]             # setup baseline: Harbor installs the agent here
network_mode = "allowlist"
allowed_hosts = ["api.openai.com", "deb.debian.org", "raw.githubusercontent.com",
  "github.com", "nodejs.org", "registry.npmjs.org"]
```

Checked with a Pi smoke run on `python:3.12-slim`: the agent installed, passed, and
could not reach `github.com` during its run. Without the install hosts in
`[environment]` the setup fails (`apt-get` exit 100) before the agent starts. Never put
code hosts such as `github.com` into the `[agent]` list. Other agents need their own
install hosts.

`harbor run --allow-agent-host <host>` adds a host for the agent phase only.

## Commands

Always pass the reasoning effort explicitly (`--ak thinking=<level>` or `--effort`):
defaults differ across agents and versions. Pin the agent version with `--ak version=`.

```bash
J=<validation-dir>/jobs

# Starter state must fail: the nop agent does nothing. Expect 0.0.
harbor run -p <tasks-dir>/<task> -a nop -o $J --job-name <task>-nop -y -q

# Oracle: solve.sh then the verifier, five attempts in one job. Expect all 1.0.
harbor run -p <tasks-dir>/<task> -a oracle -k 5 -o $J --job-name <task>-oracle -y -q

# Mutant or alt-correct: oracle on a temp copy whose solve.sh is the mutant.
tmp=$(mktemp -d) && cp -r <tasks-dir>/<task> "$tmp/" \
  && cp <mutant.sh> "$tmp/<task>/solution/solve.sh" \
  && harbor run -p "$tmp/<task>" -a oracle -o $J --job-name <task>-mut-<name> -y -q

# Leak probe (from the skill assets).
<skill>/assets/leak-probe.sh <tasks-dir>/<task> <validation-dir>/solution-strings.txt

# Task quality rubric (runs an agent; default is claude-code + claude-sonnet-4-6).
harbor check <tasks-dir>/<task> -a pi -m openai/<model> --ak version=<agent-version> \
  --ak thinking=medium -o $J --job-name <task>-check -q
# Findings: $J/<task>-check/check_report.json

# Smoke run with a real agent. Credentials come from the host environment
# (OPENAI_API_KEY for provider `openai`, ANTHROPIC_API_KEY for `anthropic`).
harbor run -p <tasks-dir>/<task> -a pi -m openai/<model> \
  --ak version=<agent-version> --ak thinking=medium -o $J --job-name <task>-smoke -y -q
# Options per agent: `harbor agent schema pi`. Extra env: --ae KEY=VALUE.

# Optional please-hack smoke: the prefix template asks the agent to game the verifier.
harbor run -p <tasks-dir>/<task> -a pi -m openai/<model> --ak version=<agent-version> \
  --ak thinking=medium --ak prompt_template_path=<skill>/assets/please-hack.j2 \
  -o $J --job-name <task>-hack -y -q
```

`-p` may point at a directory of tasks. `-n` sets concurrency; `-k` attempts.

`harbor job regrade <job-dir> -p <task>` re-runs only the verifier on recorded
artifacts. It requires `[verifier] environment_mode = "separate"` (a dedicated
verifier container that sees only collected artifacts); tasks with the default shared
verifier cannot be regraded, so re-run them instead.

## Reading results

```
$J/<job-name>/
  result.json                     # job summary
  <task>__<id>/result.json        # verifier_result.rewards.reward, exception_info, agent_result (tokens, cost_usd)
  <task>__<id>/verifier/reward.txt
  <task>__<id>/verifier/test-stdout.txt   # your PASS/FAIL lines
  <task>__<id>/agent/             # agent logs (pi.txt for Pi, oracle.txt for oracle)
  <task>__<id>/trial.log          # build/setup/infrastructure errors
```

```bash
cat $J/<job-name>/*/verifier/reward.txt
python3 -c "import json,glob; [print(f, json.load(open(f)).get('exception_info')) for f in glob.glob('$J/<job-name>/*/result.json')]"
```

A non-null `exception_info` means an infrastructure or timeout failure, not a model
failure. The smoke run must have none.
