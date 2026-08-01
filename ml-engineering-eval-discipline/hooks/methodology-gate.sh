#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "eval-discipline-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — ml-engineering-eval-discipline
# role-specific gate.
#
# Target: docs/issue-<n>/reports/ml-engineering.md (phase-2 record) — this
# role's own write surface per docs/issue-1/proposals/ml-engineering-norms.md
# (§b).
#
# Requires distinct, both-required offline and online evaluation
# subsections, per Zinkevich, "Rules of Machine Learning: Best Practices
# for ML Engineering," Google — each subsection's supporting term
# (metric/holdout/backtest, A/B/shadow/canary) must occur inside that
# subsection's own heading span, not merely anywhere in the document.
# Fails closed when a required element is absent or misplaced.
#
# Sources gate-lib.sh/gate-lib.py (docs/handbooks/gate-house-standard.md,
# issue-72) for the fail-closed trap, kill switch, JSON parsing, path
# normalization, and Write/Edit/MultiEdit reconstruction — see that file's
# usage comment for the exact call convention.
#
# Kill switch: export ML_ENGINEERING_EVAL_DISCIPLINE_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-ml-engineering}"
deny() { gate_deny "ml-engineering-eval-discipline" "$1"; }

gate_kill_switch_active "${ML_ENGINEERING_EVAL_DISCIPLINE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "methodology-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "methodology-gate: empty tool-use payload on stdin; cannot evaluate the eval-discipline gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (eval-discipline check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("ml-engineering-eval-discipline: refused — %s\n" % m); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (eval-discipline).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    root_real = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/ml-engineering\.md$')

    def resolve(p):
        tail = gate_lib.gate_normalize_path(root, p)
        if tail is None:
            return None
        a = root if tail == "" else root + "/" + tail
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return posixpath.normpath(a)

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if r is None or not (r == root_real or r.startswith(root_real + "/")):
        sys.exit(0)
    rel = r[len(root_real):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not an eval-discipline write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on eval-discipline." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the eval-discipline fields can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    def has_any(text, *needles):
        return any(nd in text for nd in needles)

    _HEADING_RE = re.compile(r'^#+\s*(.+)$', re.M)

    def _sections(text):
        heads = [(m.start(), m.group(1).strip().lower()) for m in _HEADING_RE.finditer(text)]
        heads.sort()
        spans = []
        for i, (start, name) in enumerate(heads):
            end = heads[i + 1][0] if i + 1 < len(heads) else len(text)
            spans.append((name, start, end))
        return spans

    def _span_text(sections, low_text, *aliases):
        for name, start, end in sections:
            if any(a in name for a in aliases):
                return low_text[start:end]
        return None

    sections = _sections(low)
    missing = []

    # 1. Labeled offline-evaluation subsection, scoped to its own heading
    #    span (not "mentioned anywhere in the document").
    offline_scope = _span_text(sections, low, "offline evaluation")
    if offline_scope is None:
        missing.append("offline-evaluation-missing")
    elif not has_any(offline_scope, "metric", "holdout", "backtest"):
        missing.append("offline-evaluation-incomplete")

    # 2. Labeled online-evaluation subsection, scoped the same way.
    online_scope = _span_text(sections, low, "online evaluation")
    if online_scope is None:
        missing.append("online-evaluation-missing")
    elif not has_any(online_scope, "a/b", "shadow", "canary"):
        missing.append("online-evaluation-incomplete")

    # (The former check 3 — "neither substituting for the other" — is
    # removed: it fired only when exactly one of the two spans was missing,
    # a state under which check 1 or check 2 above has already appended a
    # `missing` entry and the gate is already denying. It never changed the
    # allow/deny outcome; it was dead code, per the audit finding.)

    if missing:
        deny(
            "ml-engineering evaluation-discipline write is missing required element(s): %s. Per "
            "Zinkevich, \"Rules of Machine Learning: Best Practices for ML Engineering,\" Google, "
            "and docs/issue-1/proposals/ml-engineering-norms.md §b, every ml-engineering phase-2 "
            "record must carry a distinct, labeled offline evaluation subsection (with a metric, "
            "holdout, or backtest term inside that subsection) and a distinct, labeled online "
            "evaluation subsection (with an A/B, shadow, or canary term inside that subsection)." % ", ".join(missing)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("methodology-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "ml-engineering-eval-discipline: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
