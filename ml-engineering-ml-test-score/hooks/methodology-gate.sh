#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — ml-engineering-role-specific.
#
# Targets: docs/issue-<n>/reports/ml-engineering.md (phase-2 record) — this
# role's own write surface per docs/issue-1/proposals/ml-engineering-norms.md
# (b).
#
# Implements Breck et al. 2017's ("The ML Test Score: A Rubric for ML
# Production Readiness and Technical Debt Reduction", IEEE Big Data) four
# named rubric sections — Data Tests, Model Tests, ML Infrastructure Tests,
# Monitoring Tests. Each section that is present must also carry a scored
# verdict marker (pass/fail/score:/ /10 /verdict) within its own slice of
# the document, not merely somewhere in the document. Fails closed when a
# required section is absent entirely, or present but unscored, mirroring
# the pricing gate's "digits present but no labeling language" pattern.
#
# Kill switch: export ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-ml-engineering}"
deny() { echo "ml-engineering-ml-test-score: refused — $1" >&2; exit 2; }

case "${ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "methodology-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "methodology-gate: empty tool-use payload on stdin; cannot evaluate the ML Test Score gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (ML Test Score check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("ml-engineering-ml-test-score: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge ML Test Score sections on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on the ML Test Score gate.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (ML Test Score).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/ml-engineering\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not the ML Test Score write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the ML Test Score gate." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the ML Test Score sections can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    SECTIONS = [
        ("data tests", ("data tests",)),
        ("model tests", ("model tests",)),
        ("ml infrastructure tests", ("ml infrastructure tests", "infrastructure tests")),
        ("monitoring tests", ("monitoring tests",)),
    ]
    VERDICT_MARKERS = ("pass", "fail", "score:", "/10", "verdict")

    # Find header positions for each section name that appears, to slice
    # the document into per-section spans bounded by the next occurring
    # section header (of any of the four) or end of document.
    header_positions = []  # (start_index, name)
    for name, aliases in SECTIONS:
        for alias in aliases:
            idx = low.find(alias)
            if idx != -1:
                header_positions.append((idx, name))
                break
    header_positions.sort()

    missing = []
    present_names = {name for _, name in header_positions}
    for name, _aliases in SECTIONS:
        if name not in present_names:
            missing.append("section-missing:%s" % name)
            continue
        # locate this section's start and the next header's start
        starts = [i for i, n in header_positions if n == name]
        start = starts[0]
        later = [i for i, _n in header_positions if i > start]
        end = min(later) if later else len(low)
        slice_ = low[start:end]
        if not any(marker in slice_ for marker in VERDICT_MARKERS):
            missing.append("section-unscored:%s" % name)

    if missing:
        deny(
            "ml-engineering ML Test Score record is missing required element(s): %s. Per "
            "Breck et al. 2017 (\"The ML Test Score: A Rubric for ML Production Readiness "
            "and Technical Debt Reduction\", IEEE Big Data) and "
            "docs/issue-1/proposals/ml-engineering-norms.md §b, every phase-2 "
            "docs/issue-<n>/reports/ml-engineering.md record must carry all four rubric "
            "sections — Data Tests, Model Tests, ML Infrastructure Tests, Monitoring "
            "Tests — and each present section must carry a scored verdict marker "
            "(pass/fail/score:/ /10 /verdict) within its own section." % ", ".join(missing)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("methodology-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "ml-engineering-ml-test-score: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
