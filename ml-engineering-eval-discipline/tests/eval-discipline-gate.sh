#!/usr/bin/env bash
# Standalone tests for ml-engineering-eval-discipline/hooks/methodology-gate.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/methodology-gate.sh"

pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-28s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-28s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

run() { # want name content
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/ml-engineering.md","content":%s},"cwd":"%s"}' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$3")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

PASS_CONTENT='## Offline evaluation
Offline evaluation was run against a holdout dataset, with primary metric AUC.

## Online evaluation
Online evaluation used a shadow deployment before rollout.'

FAIL_CONTENT='## Offline evaluation
Offline evaluation was run against a holdout dataset, with primary metric AUC.'

run allow pass-case "$PASS_CONTENT"
run deny  fail-case "$FAIL_CONTENT"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
if [ "$fail" -eq 0 ]; then exit 0; else exit 1; fi
