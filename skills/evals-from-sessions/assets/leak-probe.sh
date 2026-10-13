#!/bin/bash
# Leak probe: build the task image and try to recover the reference solution from it.
# Usage: leak-probe.sh <task-dir> <solution-strings.txt>
#   solution-strings.txt: one fixed string per line that only the reference diff
#   contains (added lines, the episode commit SHA and message, new file names).
# Expected: commits=1, refs=1, reflog<=1, remotes=0, tags=0, stash=0, hooks=0, hits=0.
# Exit code: 0 = clean, 1 = possible leak, 2 = usage or build error.
set -u
task=${1:?task dir}; strings=${2:?strings file}
[ -f "$task/environment/Dockerfile" ] && [ -s "$strings" ] || { echo "usage error"; exit 2; }
tag="efs-leak-probe-$(basename "$task" | tr 'A-Z_' 'a-z-')"
docker build -q -t "$tag" "$task/environment" >/dev/null || { echo "build failed"; exit 2; }
docker run --rm --network none -u 0 --entrypoint sh \
  -v "$(realpath "$strings")":/probe-strings:ro "$tag" -c '
wd=$(pwd); bad=0
say() { echo "$1=$2 (expect $3)"; [ "$2" -le "$3" ] || bad=1; }
if command -v git >/dev/null && git -C "$wd" rev-parse --git-dir >/dev/null 2>&1; then
  g="git -C $wd"
  say commits "$($g rev-list --all 2>/dev/null | wc -l)" 1
  say refs "$($g for-each-ref | wc -l)" 1
  say reflog "$($g reflog 2>/dev/null | wc -l)" 1
  say remotes "$($g remote | wc -l)" 0
  say tags "$($g tag | wc -l)" 0
  say stash "$($g stash list 2>/dev/null | wc -l)" 0
  say hooks "$(find "$($g rev-parse --git-dir)/hooks" -type f ! -name "*.sample" 2>/dev/null | wc -l)" 0
  say unreachable_objects "$($g fsck --unreachable --no-reflogs 2>/dev/null | wc -l)" 0
  echo "messages: $($g log --all --format=%s | tr "\n" "|")"
else
  echo "no git repository in $wd"
fi
hits=$(grep -rIlF -f /probe-strings / --exclude-dir=proc --exclude-dir=sys \
  --exclude-dir=dev 2>/dev/null | grep -v "^/probe-strings$")
n=$(printf "%s" "$hits" | grep -c . || true)
say string_hit_files "$n" 0
[ -n "$hits" ] && printf "%s\n" "$hits" | head -20
exit $bad'
rc=$?
docker image rm -f "$tag" >/dev/null 2>&1
[ $rc -eq 0 ] && echo "LEAK PROBE: clean" || echo "LEAK PROBE: possible leak"
exit $rc
