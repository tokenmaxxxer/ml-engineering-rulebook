#!/usr/bin/env bash
# Standalone tests for ml-engineering-model-provenance/hooks/methodology-gate.sh
# Covers the gate-house standard's mandatory categories (issue-10): Edit
# with replace_all, MultiEdit with mixed replace_all, malformed JSON,
# kill-switch garbage value, absolute/./-prefixed path matching, plus this
# gate's own section-placement regression (model-card fields anchored to
# their own heading, not a bare mention anywhere).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/methodology-gate.sh"
# CLAUDE_PLUGIN_ROOT_CORE must resolve to an installed core plugin's root
# (gate-lib.sh lives at $CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh) for
# these tests to run at all — the gate sources it by reference, per
# docs/handbooks/gate-house-standard.md. Set it in the invoking shell/CI
# before running this file; it is intentionally not defaulted here.
GATE_OFF_VAR="ML_ENGINEERING_MODEL_PROVENANCE_GATE_OFF"
TARGET_REL="docs/issue-7/reports/ml-engineering.md"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-28s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-28s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

new_td() { td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; }

_mk_write_payload() { # file_path content cwd
python3 - "$1" "$2" "$3" <<'PY'
import json,sys
fp,content,cwd=sys.argv[1],sys.argv[2],sys.argv[3]
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":fp,"content":content},"cwd":cwd}))
PY
}

_mk_edit_payload() { # file_path old new replace_all(true/false/"") cwd
python3 - "$1" "$2" "$3" "$4" "$5" <<'PY'
import json,sys
fp,old,new,ra,cwd=sys.argv[1:6]
ti={"file_path":fp,"old_string":old,"new_string":new}
if ra: ti["replace_all"]=(ra=="true")
print(json.dumps({"tool_name":"Edit","tool_input":ti,"cwd":cwd}))
PY
}

_mk_multiedit_payload() { # file_path cwd edits_json
python3 - "$1" "$2" "$3" <<'PY'
import json,sys
fp,cwd,edits_json=sys.argv[1:4]
edits=json.loads(edits_json)
print(json.dumps({"tool_name":"MultiEdit","tool_input":{"file_path":fp,"edits":edits},"cwd":cwd}))
PY
}

_fire() { # payload td extra_env(optional)
  local payload="$1" tdd="$2" extra="${3:-}"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$tdd" $extra bash "$GATE" >/dev/null 2>&1
  rc=$?
}

run_write() { # want name content [extra_env]
  local want="$1" name="$2" content="$3" extra="${4:-}"
  new_td
  local payload; payload="$(_mk_write_payload "$TARGET_REL" "$content" "$td")"
  _fire "$payload" "$td" "$extra"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

run_write_abs() { # want name content path_kind(abs|dotslash)
  local want="$1" name="$2" content="$3" kind="$4"
  new_td
  local path
  case "$kind" in
    abs) path="$td/$TARGET_REL" ;;
    dotslash) path="./$TARGET_REL" ;;
  esac
  local payload; payload="$(_mk_write_payload "$path" "$content" "$td")"
  _fire "$payload" "$td"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

run_edit() { # want name current old new replace_all
  local want="$1" name="$2" current="$3" old="$4" new="$5" ra="$6"
  new_td
  mkdir -p "$td/$(dirname "$TARGET_REL")"
  printf '%s' "$current" > "$td/$TARGET_REL"
  local payload; payload="$(_mk_edit_payload "$TARGET_REL" "$old" "$new" "$ra" "$td")"
  _fire "$payload" "$td"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

run_multiedit() { # want name current edits_json
  local want="$1" name="$2" current="$3" edits_json="$4"
  new_td
  mkdir -p "$td/$(dirname "$TARGET_REL")"
  printf '%s' "$current" > "$td/$TARGET_REL"
  local payload; payload="$(_mk_multiedit_payload "$TARGET_REL" "$td" "$edits_json")"
  _fire "$payload" "$td"
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

run_raw() { # want name raw_payload
  local want="$1" name="$2" raw="$3"
  new_td
  printf '%s' "$raw" | env CLAUDE_PROJECT_DIR="$td" bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

PASS_CONTENT='# ml-engineering report

## Intended use
batch scoring of loan applications.

## Limitations
not validated for adversarial inputs.

## Training data
internal loans dataset, 2020-2024.

## Evaluation data
held-out 2024 Q4 slice.

Dataset version: v1.2
Model version: v3.0
'

FAIL_CONTENT='# ml-engineering report

## Intended use
batch scoring of loan applications.

## Limitations
not validated for adversarial inputs.

## Training data
internal loans dataset, 2020-2024.

## Evaluation data
held-out 2024 Q4 slice.

Dataset version: v1.2
'

# "evaluation data" is only mentioned in prose under Limitations, never as
# its own heading nor inside an explicit "model card" section => deny.
WRONG_SECTION_CONTENT='# ml-engineering report

## Intended use
batch scoring of loan applications.

## Limitations
not validated for adversarial inputs; evaluation data quality was not audited.

## Training data
internal loans dataset, 2020-2024.

Dataset version: v1.2
Model version: v3.0
'

run_write allow all-model-card-fields-and-versions "$PASS_CONTENT"
run_write deny  model-version-missing               "$FAIL_CONTENT"
run_write deny  evaluation-data-mentioned-wrong-section "$WRONG_SECTION_CONTENT"

# --- Edit, single occurrence, section-placed correctly => allow ---
run_edit allow edit-adds-model-version "$FAIL_CONTENT" "Dataset version: v1.2" "Dataset version: v1.2
Model version: v3.0" ""

# --- Edit with replace_all: true against a multiply-occurring old_string.
#     The version checks are document-wide, not section-scoped, so the
#     differentiator here is a decoy occurrence before the real one: with
#     replace_all=false only the (irrelevant) decoy gets fixed, leaving the
#     real "Model:" line — and the gate's model-version match — broken. ---
CURRENT_MULTI='# ml-engineering report

## Intended use
batch scoring of loan applications.

## Limitations
not validated for adversarial inputs.

## Training data
internal loans dataset, 2020-2024.

## Evaluation data
held-out 2024 Q4 slice.

Dataset: v1.2
Decoy: TBD
Model: TBD
'
run_edit allow edit-replace-all-true  "$CURRENT_MULTI" "TBD" "v3.0" "true"
run_edit deny  edit-replace-all-false "$CURRENT_MULTI" "TBD" "v3.0" "false"

# --- MultiEdit, mixed replace_all true/false per edit, each independently
#     honored: edit A always fixes Dataset (its own decoy precedes it, but
#     replace_all:true covers both); edit B's own flag decides whether the
#     real "Model:" line gets fixed. ---
CURRENT_MIXED='# ml-engineering report

## Intended use
batch scoring of loan applications.

## Limitations
not validated for adversarial inputs.

## Training data
internal loans dataset, 2020-2024.

## Evaluation data
held-out 2024 Q4 slice.

Decoy1: X_A
Dataset: X_A
Decoy2: X_B
Model: X_B
'
EDITS_MIXED_DENY='[{"old_string":"X_A","new_string":"v1.2","replace_all":true},{"old_string":"X_B","new_string":"v3.0","replace_all":false}]'
EDITS_MIXED_ALLOW='[{"old_string":"X_A","new_string":"v1.2","replace_all":true},{"old_string":"X_B","new_string":"v3.0","replace_all":true}]'
run_multiedit deny  multiedit-mixed-false-leaves-model-version-unfixed "$CURRENT_MIXED" "$EDITS_MIXED_DENY"
run_multiedit allow multiedit-mixed-both-true                          "$CURRENT_MIXED" "$EDITS_MIXED_ALLOW"

# --- malformed JSON: truncated, non-object top-level, empty ---
run_raw deny malformed-json-truncated '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/ml-engineering.md","content":'
run_raw deny malformed-json-array     '["not", "an", "object"]'
run_raw deny malformed-json-empty     ''

# --- kill-switch garbage value: gate must stay ACTIVE (still evaluates and denies FAIL_CONTENT) ---
run_write deny kill-switch-garbage-stays-active "$FAIL_CONTENT" "${GATE_OFF_VAR}=1x"

# --- absolute-path / ./-prefixed matching ---
run_write_abs allow absolute-path-match "$PASS_CONTENT" abs
run_write_abs allow dotslash-path-match "$PASS_CONTENT" dotslash

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
exit_code=$?
if [ "$fail" -ne 0 ]; then exit 1; else exit 0; fi
