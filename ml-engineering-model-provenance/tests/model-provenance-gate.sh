#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/methodology-gate.sh"

fails=0
total=0

run_case() {
  local name="$1" content="$2" expect_rc="$3"
  total=$((total + 1))

  local tmpdir
  tmpdir="$(mktemp -d)"
  ( cd "$tmpdir" && git init -q )

  local payload
  payload="$(python3 -c '
import json, sys
content = sys.argv[1]
cwd = sys.argv[2]
payload = {
    "tool_name": "Write",
    "tool_input": {
        "file_path": "docs/issue-7/reports/ml-engineering.md",
        "content": content,
    },
    "cwd": cwd,
}
print(json.dumps(payload))
' "$content" "$tmpdir")"

  local rc
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$tmpdir" bash "$GATE" >/dev/null 2>"$tmpdir/stderr.log"
  rc=$?

  if [ "$rc" -eq "$expect_rc" ]; then
    echo "ok - $name (rc=$rc)"
  else
    echo "FAIL - $name (expected rc=$expect_rc, got rc=$rc)"
    cat "$tmpdir/stderr.log" >&2
    fails=$((fails + 1))
  fi

  rm -rf "$tmpdir"
}

PASS_CONTENT='# ml-engineering report

Intended use: batch scoring of loan applications.
Limitations: not validated for adversarial inputs.
Training data: internal loans dataset, 2020-2024.
Evaluation data: held-out 2024 Q4 slice.

Dataset version: v1.2
Model version: v3.0
'

FAIL_CONTENT='# ml-engineering report

Intended use: batch scoring of loan applications.
Limitations: not validated for adversarial inputs.
Training data: internal loans dataset, 2020-2024.
Evaluation data: held-out 2024 Q4 slice.

Dataset version: v1.2
'

run_case "pass: all model-card fields + data/model version present" "$PASS_CONTENT" 0
run_case "fail: model version missing" "$FAIL_CONTENT" 2

echo "---"
echo "$total cases, $fails failed"

if [ "$fails" -ne 0 ]; then
  exit 1
fi
exit 0
