#!/bin/bash
# Runs offline after the agent finishes. Never download anything here.
# Always writes a reward: a missing reward file is a Harbor error, not a 0.
mkdir -p /logs/verifier
reward=0
trap 'echo "$reward" > /logs/verifier/reward.txt' EXIT
python3 /tests/verify.py && reward=1
exit 0
