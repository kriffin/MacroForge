#!/usr/bin/env bash
# Headless tests: the addon's logic against a fake WoW API (tests/wow_stub.lua).
# Usage: tests/run.sh   (needs lua 5.1+; CI uses 5.3)
set +u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
fail=0
for t in "$ROOT"/tests/test_*.lua; do
  out=$(cd "$ROOT/tests" && lua -e "ROOT=[[$ROOT]]" "$t" 2>&1)
  if [ $? -eq 0 ]; then
    printf '  ok   %-18s %s\n' "$(basename "$t" .lua)" "$(echo "$out" | tail -1)"
  else
    printf '  FAIL %-18s\n%s\n' "$(basename "$t" .lua)" "$out"
    fail=1
  fi
done
exit $fail
