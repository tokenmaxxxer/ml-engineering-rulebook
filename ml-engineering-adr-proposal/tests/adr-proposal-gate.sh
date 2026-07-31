#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/methodology-gate.sh"
pass=0; fail=0

report() { # want got name
  if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-20s want=%s got=%s\n' "$3" "$1" "$2"; else fail=$((fail+1)); printf 'FAIL   %-20s want=%s got=%s\n' "$3" "$1" "$2"; fi
}

run_case() { # name want content
  name="$1"; want="$2"; content="$3"
  td="$(mktemp -d)"
  ( cd "$td" && git init -q ) >/dev/null 2>&1
  payload="$(python3 -c '
import json, sys
content = sys.argv[1]
cwd = sys.argv[2]
payload = {
    "tool_name": "Write",
    "tool_input": {
        "file_path": "docs/issue-7/proposals/x-ml-engineering.md",
        "content": content,
    },
    "cwd": cwd,
}
print(json.dumps(payload))
' "$content" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

PASS_CONTENT='# Context
Some background here.
# Decision
We decided to do X.
# Rationale
Because of reasons (Smith 2020).
# Consequences
Things will change.

Rejected alternative: approach Y was considered and declined because of cost.'

FAIL_CONTENT='# Context
Some background here.
# Decision
We decided to do X.
# Rationale
Because of reasons (Smith 2020).
# Consequences
Things will change.'

run_case "pass-case" allow "$PASS_CONTENT"
run_case "fail-case" deny "$FAIL_CONTENT"

echo "== $pass passed, $fail failed =="
if [ "$fail" -ne 0 ]; then exit 1; else exit 0; fi
