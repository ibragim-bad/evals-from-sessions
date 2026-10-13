#!/bin/bash
# Reference solution. Runs in the task container as the oracle agent.
set -euo pipefail
cd /app
# private: apply the episode's own change.
git apply --whitespace=nowarn /solution/fix.patch
# shareable: write the fixed files instead, for example
# cat > /app/tool.py <<'PY'
# ...
# PY
