# evals-from-sessions

`evals-from-sessions` is an agent skill. It turns your own coding-agent sessions into
verified [Harbor](https://github.com/harbor-framework/harbor) eval tasks, so you can
compare agents, models and settings on your own work by price and time.

Guide: [Turn your agent sessions into evals. Mine found a 2× cheaper setup](https://ibragim.dev/writing/)
· Leaderboard: [ibragim.dev/leaderboard](https://ibragim.dev/leaderboard/)

## What it does

The skill follows the six steps of the guide:

1. **Find tasks in your session history.** Copy the sessions, scan the copy with
   gitleaks, and list candidate task episodes in `candidates.md`.
2. **Turn a session into a task spec.** Write `provenance.md`: requirements, failure
   modes, and what the agent must discover by itself. Tasks with something to discover
   are labeled `discovery`; tasks where you stated every rule are labeled `routine` and
   kept, because they still show which setup solves your everyday work cheaper and faster.
3. **Build the Harbor task.** Use a snapshot of your own repository (private mode) or a
   re-authored synthetic task (shareable mode). Close the usual cheating paths: no
   future git history, no reference diff in the image, hidden tests.
4. **Check the verifier.** Nop fails, oracle passes 5 of 5, near-miss solutions fail,
   an alternative correct solution passes. Then a leak probe and `harbor check`.
5. **Run it.** One smoke run with a real agent, and an optional calibration with two
   setups × three runs.
6. **Review and repeat.** Classify every failure (model mistake, ambiguity, verifier
   false negative), fix the task, bump its version, and re-run.

The skill stops when a task is *ready for human review*. Comparing setups across many
runs (`harbor run -p tasks/ ... -k 3`) is your next step, not part of the skill.

## Where you take part

- **Checkpoint 1:** approve the candidate list (`candidates.md`).
- **Checkpoint 2:** approve the task spec (`provenance.md`) before the agent builds the task.
- **Final review:** check each finished task and its `report.md` before it enters your set.

Unattended runs write `AWAITING_REVIEW` at a checkpoint and stop.

## Requirements

- Docker and git
- Python 3.11+
- Harbor: `uv tool install harbor` (any recent version; command examples use 0.24 syntax)
- gitleaks 8
- Credentials for one agent and model, for `harbor check` and the smoke run

## Install

skills CLI (Claude Code, Codex, Pi and other agents):

```bash
npx skills add ibragim-bad/evals-from-sessions
```

Claude Code plugin:

```text
/plugin marketplace add ibragim-bad/evals-from-sessions
/plugin install evals-from-sessions@evals-from-sessions
```

Codex plugin:

```bash
codex plugin marketplace add ibragim-bad/evals-from-sessions
codex plugin add evals-from-sessions@evals-from-sessions
```

Pi package:

```bash
pi install git:github.com/ibragim-bad/evals-from-sessions
```

Update: `claude plugin update evals-from-sessions@evals-from-sessions`,
`codex plugin marketplace upgrade evals-from-sessions`, or `pi update --extensions`.

Manual: copy `skills/evals-from-sessions/` into your agent's skills directory, for
example `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/` or
`~/.pi/agent/skills/`.

## Use

Start your agent in an empty work directory and ask, for example:

```text
Use evals-from-sessions to turn my Claude Code sessions from the last month into
eval tasks. Work directory: ./evals. Stop at each checkpoint.
```

## Layout

```text
skills/evals-from-sessions/
  SKILL.md                        # the workflow
  references/harbor-contract.md   # Harbor layout, network, commands
  assets/task-template/           # starting files for one task
  assets/leak-probe.sh            # tries to recover the solution from the image
  assets/please-hack.j2           # optional "please game the verifier" smoke prompt
```

## Safety

Session transcripts can contain API keys and private code. The skill works on a copy,
scans it with gitleaks, and never writes secrets. Private-mode tasks contain a snapshot
of your repository: keep them private. Publish only shareable tasks.

## License

MIT
