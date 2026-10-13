# Provenance

- Source session: SESSION-ID (`PATH/TO/SESSION.jsonl`), JSONL lines N-M
- Episode: which user request, in one sentence.
- Mode: private | shareable
- Private only: repository REPO, parent commit SHA, episode commit SHA (or clean diff)

## Requirements

- The solution must ...

## Failure modes

- MISTAKE OR EDGE CASE from the session -> check name in `tests/verify.py`.

## Must be discovered (frozen; never edit after authoring starts)

Empty list: the task is `routine`; state every rule in the instruction.


- CAUSE / LAYER / RULE / OPTION the agent must find out by itself.
  Nearest user sentence: "..." (line N). Evidence: lines N, M.

## Origin of files

- private: `environment/repo/` is `git archive <parent-commit>`; `solution/fix.patch`
  is the episode diff; tests added by the episode live in `tests/`.
- shareable: all code, data, names and values are synthetic. Nothing from the
  source repository, data or model output is included.
