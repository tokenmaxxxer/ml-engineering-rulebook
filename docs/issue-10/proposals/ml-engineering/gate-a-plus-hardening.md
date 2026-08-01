# Gate A+ hardening (issue-10, ml-engineering) — proposal

Phase 1 — design proposal only. No implementation in this PR.

## Context

Audit (2026-08-01, current grade B-) of this rulebook's five
`methodology-gate.sh` PreToolUse hooks found: (1) a worst-in-class test
suite (2 cases per gate, plus one confirmed-dead check), (2) semantic
checks that mistake a prose mention anywhere in the document for correct
section placement, (3) a naive substring matcher where `"pass" in text`
matches inside `"bypass"`, (4) eval-discipline's check 3 is unreachable
dead code (see `docs/issue-10/reports/ml-engineering/current-state-survey.md`
§2 for exact file:line citations of all four). Precondition: core issue
#72 ("게이트 하우스 표준") has landed; `core/hooks/lib/gate-lib.sh` +
`gate-lib.py` are the canon shared library every downstream rulebook gate
must source, not reimplement (`docs/handbooks/gate-house-standard.md`).

## Decision

Migrate all five `ml-engineering-*/hooks/methodology-gate.sh` gates onto
`gate-lib.sh`/`gate-lib.py`, replacing every hand-rolled instance of the
shapes gate-lib now owns, and add two new locally-owned helpers (a
section-aware placement checker, a word-boundary marker matcher) for the
two requirements gate-lib does not and structurally should not cover.

## Rationale

Sourcing gate-lib.sh instead of reimplementing removes exactly the
defect classes it was built to remove (issue-72's own audit found the
same kill-switch-inverted and replace_all-ignored bugs in core's *own*
canon before the migration — this repo's five gates carry the identical
bugs today, confirmed in the survey). A from-scratch local fix would
re-derive logic that already exists, tested, in one place; five local
copies of the same fix is the exact "same shapes, 2-3 different idioms
each" failure mode issue-72's own background names as the reason
gate-lib.sh exists.

## Design principle: adopt by reference, do not reimplement

**Core's gate-lib.sh is adopted by reference (sourced), not
reimplemented.** Concretely:
- Bash side: `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"`
  at the top of each `methodology-gate.sh`, per the usage comment at
  `gate-lib.sh:11-26`.
- Python side: each gate's heredoc Python payload loads `gate-lib.py` via
  `importlib.util.spec_from_file_location` against
  `os.environ["GATE_LIB_PY"]` (exported by `gate-lib.sh` itself at
  `gate-lib.sh:28-29`), exactly as documented.
- `stub-check.sh`/`canon-manifest.txt` already mechanically catch a
  vendored copy of `gate-lib.sh`/`gate-lib.py` in any rulebook — this
  proposal relies on that existing enforcement rather than adding a new
  check.

**Local reimplementation risks to explicitly avoid:**
- Do not write a local `__fc`/`trap __fc EXIT` shim — call
  `gate_trap_fail_closed` instead (removes the shim duplicated at the top
  of all five current gates).
- Do not write a local `case ... in ""|0|false|no|off) ;; *) exit 0 ;;
  esac` kill-switch — call `gate_kill_switch_active` instead (this exact
  idiom is the confirmed live bug in this repo today; hand-rolling a
  "fixed" version locally risks re-introducing a variant of the same bug
  the shared function was written to close).
- Do not write a local `try: json.loads(...) except ValueError: deny(...)`
  block — call `gate_parse_json_or_deny` instead.
- Do not write a local `text.replace(old, new, 1)` reconstruction for
  Edit/MultiEdit — call `gate_reconstruct_write` instead (this is the
  literal fix for the replace_all requirement; a local rewrite risks
  missing the same `replace_all`-per-edit-in-MultiEdit subtlety
  `gate-lib.py:128-143` already gets right).
- Do not bake `realpath`/symlink resolution into a new wrapper around
  `gate_normalize_path` — that function's contract is deliberately
  filesystem-free (`gate-lib.py:52-55`); keep each gate's own existing
  `resolve()` closure doing `os.path.realpath(root)` /
  `os.path.realpath(a)` locally, calling `gate_normalize_path` for the
  string-algebra step only (per the scout brief's "skip" item).

## Per-requirement design

### 1a. Fail-closed trap at the very top

Replace, in each of the five `methodology-gate.sh` bash preambles:
```bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
```
with:
```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
```
sourced as the literal first statement, before `set -uo pipefail`, per
`gate-lib.sh`'s own documented call order — an early failure in path
resolution is still caught.

### 1b. Malformed JSON => deny

Replace each gate's local `try: ev = json.loads(raw) ... except
ValueError: deny(...)` / `if not isinstance(ev, dict): deny(...)` pair
with a call to `gate_lib.gate_parse_json_or_deny(raw, deny)` inside the
heredoc Python payload, after loading `gate-lib.py` via
`importlib.util.spec_from_file_location` against `os.environ["GATE_LIB_PY"]`.
Covers truncated JSON, non-object top level, and empty payload uniformly
across all five gates instead of five separate hand-written try/except
blocks.

### 1c. Kill-switch: garbage values => gate stays ACTIVE

Replace, in each gate's bash preamble:
```bash
case "${ML_ENGINEERING_<NAME>_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```
with:
```bash
gate_kill_switch_active "${ML_ENGINEERING_<NAME>_GATE_OFF:-}" || { trap - EXIT; exit 0; }
```
This is the exact fix for the confirmed live bug (survey §3): a garbage
value like `1x` now stays active instead of silently disabling the gate.
`trap - EXIT` before the early exit is required so the fail-closed trap
does not itself fire on a deliberate, legitimate `exit 0`.

### 1d. Absolute-path normalization

Each gate's Python `resolve(p)` closure keeps its own
`os.path.realpath` call for symlink safety (per the "do not reimplement"
list above), but the relative/absolute/`./`-prefix algebra step is
replaced with a call to `gate_lib.gate_normalize_path(root, p)` (imported
the same way as `gate_parse_json_or_deny`), then `os.path.realpath()`
applied to the result before the existing prefix/regex match against
`RECORD_RE`/`PROPOSAL_RE`. This directly satisfies requirement 1's
absolute-path-normalization ask and the standard's mandatory test case 5
(absolute `file_path` matching the same scope a relative-path fixture
matches, plus a `./`-prefixed variant).

### 1e. Edit/MultiEdit/replace_all rework

Replace each gate's local block:
```python
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
            ...
            text = text.replace(o, n, 1)
        if ok:
            new_text = text
```
with a single call:
```python
new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
if not ok:
    new_text = None
```
covering `Write`/`Edit`/`MultiEdit` uniformly (including
`NotebookEdit` for free, unused today but future-proofed) and honoring
`replace_all` per the tool's real documented semantics — every occurrence
when `replace_all` is true, first-occurrence-only otherwise, independently
per edit inside a `MultiEdit`'s `edits[]` array. This is the concrete fix
for "full rework of how the hook handles Edit/MultiEdit... including
replace_all."

### 1f. Deny reasons surfaced via stderr

Already the case in all five gates today (`echo "<gate>: refused — $1"
>&2; exit 2` bash-side; `sys.stderr.write(...); sys.exit(2)`
Python-side) — this requirement is satisfied by migrating the bash-side
`deny()` closure to call `gate_deny "<gate-name>"` (same stderr-then-exit-2
shape, `gate-lib.sh:72-75`) and keeping the Python-side `deny()` closures
as-is (they already write to stderr; `gate_deny` has no Python
counterpart to call from inside the heredoc, so the existing local
closure stays, unchanged in behavior). Net effect: no regression, and
confirmed by test case additions (below) that a deny path always produces
non-empty stderr.

### 2. Semantic checks: substring => section/adjacency/structural

Concrete mechanism, applied to all five gates' domain checks (generalizing
`ml-engineering-ml-test-score`'s existing partial header-slicing
approach, fixing its own bugs along the way):

1. Parse the document into `(heading_text, start_offset, end_offset)`
   triples via a markdown-heading regex (`^#+\s*(.+)$`, multiline),
   sorted by `start_offset`; each heading's span runs to the next
   heading's start or end-of-document — this is the existing
   `ml-test-score` slicing logic, kept.
2. For a requirement expressed as "must appear in section X": locate the
   span whose heading matches X (case-insensitive substring or a
   configured alias list, as `ml-test-score`'s `SECTIONS` already does),
   then search **only within that span** for the required marker/term —
   never the whole document. This directly fixes `adr-proposal`'s
   "named source"/"rejected alternative" checks (currently whole-document
   `has_any()`) and `model-provenance`'s model-card field checks
   (currently whole-document `field not in low`) by requiring, e.g., the
   "rejected alternative" language to occur specifically within the
   `## Consequences` (or `## Rationale`) span, and each model-card field
   to occur within a heading matching that field's own name or an
   explicit model-card section.
3. For a requirement expressed as "heading X must exist" with no
   in-body term (the ADR section markers already do this correctly via
   `^#+\s*name\b` — keep unchanged): no change needed, cited in the
   survey as the one already-adjacency-correct check in this repo.
4. `eval-discipline`'s offline/online checks move from
   `"offline evaluation" in low` to "a span whose heading matches
   `offline evaluation` exists, and within that span at least one of
   metric/holdout/backtest occurs" — this also mechanically removes
   check 3's dead code, since the offline/online heading-adjacency check
   *is* the "not substitutable" guarantee once each is independently
   span-scoped (a document with only an "online evaluation" heading and
   no "offline evaluation" heading no longer needs a separate
   not-substituting check; the missing span check already catches it).

This is a **new local helper**, e.g. `_sections(text)` /
`_span_for(heading_pattern, text)`, added once (as a small shared snippet
duplicated per gate, matching this repo's existing one-file-per-gate
convention — a shared local file is an option to consider in phase 2 if
duplication proves costly, but is out of scope for this phase-1 proposal)
in each gate's Python payload — gate-lib.sh/py have no such helper (survey
§4/§6 GAP), and per the scout brief this is intentional: section-name
semantics are domain knowledge gate-lib cannot generalize.

### 3. Word-boundary fix for pass/bypass

Replace, at `ml-engineering-ml-test-score/hooks/methodology-gate.sh:168,194`:
```python
VERDICT_MARKERS = ("pass", "fail", "score:", "/10", "verdict")
...
if not any(marker in slice_ for marker in VERDICT_MARKERS):
```
with a regex using explicit word boundaries for the alphabetic markers
(the punctuation-bearing markers `score:`/`/10` need no boundary fix,
since they cannot occur as a substring of an unrelated word the same way
`pass` can):
```python
VERDICT_RE = re.compile(r'\b(pass|fail|verdict)\b|score:|/10')
...
if not VERDICT_RE.search(slice_):
```
`\b` is sufficient here (no need for `re.IGNORECASE` beyond the existing
`slice_ = low[...]` lower-casing already in place). This is the literal
fix for Finding 3; audited for the same latent risk in the `has_any()`
helper shared by the other four gates (currently used only for
multi-word phrases like `"offline evaluation"`, `"rejected alternative"`,
`"dataset version"` — none are single short tokens vulnerable to the
same class of false-positive today, so no other gate needs this specific
fix, but the new section-aware helper from requirement 2 should use
`\b`-anchored matching for any future single-word marker by convention).

## Mandatory test cases, mapped to hook files

Each of the five `ml-engineering-*/tests/*.sh` gains all six categories
(adapting the standard's `run-gate-lib-tests.sh` shape, case 6 —
Bash-tool write — omitted since none of these gates match the `Bash`
tool):

| Category | Fixture sketch | Lives in |
|---|---|---|
| Edit (single, no replace_all) | old_string present once, section-placed correctly → allow; wrong section → deny | all 5 `tests/*.sh` |
| Edit with `replace_all: true` against a multiply-occurring `old_string` | verify every occurrence replaced, not just first | all 5 `tests/*.sh` |
| MultiEdit, mixed `replace_all` true/false per edit | verify each edit's own flag honored independently | all 5 `tests/*.sh` |
| replace_all edits (dedicated) | a MultiEdit edit with `replace_all: true` on a multiply-occurring string, combined with another edit `replace_all: false` in the same call | all 5 `tests/*.sh` |
| Malformed JSON hook input | truncated JSON, non-object top-level (e.g. a JSON array), empty stdin — three sub-cases | all 5 `tests/*.sh` |
| Kill-switch garbage value | `ML_ENGINEERING_<NAME>_GATE_OFF=xyz123` → gate must still evaluate (stay active), not silently allow | all 5 `tests/*.sh` |
| Absolute-path matching | same target file addressed via a relative path and an equivalent absolute path (plus a `./`-prefixed variant) both hit the same allow/deny outcome | all 5 `tests/*.sh` |
| Section-placement (new, per requirement 2) | required term present in document but in the wrong section → deny; same term in the correct section → allow | all 5 `tests/*.sh` (per-gate content differs) |
| `pass`/`bypass` word-boundary (new, per requirement 3) | a scored section whose only occurrence of "pass" is inside the word "bypass" → deny (currently would incorrectly allow) | `ml-engineering-ml-test-score/tests/ml-test-score-gate.sh` specifically |
| eval-discipline check-3 removal | regression case: online-only document denies via the online/offline span check alone, no separate "not-substitutable" message needed | `ml-engineering-eval-discipline/tests/eval-discipline-gate.sh` |

## README sync plan

Current state (verified against files on disk, not just README claims):
`.claude-plugin/marketplace.json` lists six plugins
(`ml-engineering` + five gate plugins); `README.md`'s "Layout" section
names only `ml-engineering/.claude-plugin/plugin.json`,
`ml-engineering/hooks/hooks.json`, `ml-engineering/hooks/directive.sh`,
`docs/specs/approvers.md`, `docs/specs/record-norms.md` — all five real
files, no literal ghost-file path found in the current README text. The
sync defect is the inverse: five real, load-bearing gate plugins and
their five distinct kill-switch env vars are entirely absent from the
README, and the "Install" section's single `claude plugin install
ml-engineering` line does not mention installing the five gate plugins
required for enforcement to actually run.

Corrected README will state:
- A "Plugins" or expanded "Layout" section listing all six
  `.claude-plugin/plugin.json`-bearing dirs from `marketplace.json`, each
  with its one-line purpose (already written, verbatim reusable, in
  `marketplace.json`'s own `description` fields).
- An "Install" section installing all six plugins, not just
  `ml-engineering` (`claude plugin install ml-engineering-adr-proposal`,
  etc., one line per plugin).
- A table of the five kill-switch env vars
  (`ML_ENGINEERING_ADR_PROPOSAL_GATE_OFF`,
  `ML_ENGINEERING_EVAL_DISCIPLINE_GATE_OFF`,
  `ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF`,
  `ML_ENGINEERING_MODEL_PROVENANCE_GATE_OFF`,
  `ML_ENGINEERING_SLO_SERVING_GATE_OFF`) and what each gates, sourced
  from each gate script's own header comment (already accurate, just
  never surfaced in README).
- A one-line note that all five gate plugins source `core/hooks/lib/
  gate-lib.sh`/`gate-lib.py` per `gate-house-standard.md`, matching the
  existing note about the three generic canon gates being registered
  globally by `core` (that existing note stays, verified still accurate).

## Acceptance criteria / definition of done for phase 2

1. All five `methodology-gate.sh` files source `gate_trap_fail_closed`,
   `gate_kill_switch_active`, `gate_parse_json_or_deny`,
   `gate_normalize_path`, `gate_reconstruct_write`, `gate_deny` — no local
   reimplementation of any of these six shapes remains (verified by
   diffing against the "do not reimplement" list above).
2. `core/hooks/tests/compliance-check.sh` run against this repo's five
   `hooks/` dirs reports clean (no hand-rolled kill-switch, no hand-rolled
   Edit/MultiEdit `.replace()` reconstruction flagged).
3. Every one of the ten test categories in the table above exists as at
   least one case in every applicable gate's test file.
4. Eval-discipline's check 3 is removed from the source (not just
   unreachable — deleted), and its regression test (last row of the
   table) passes.
5. The `ml-test-score` gate's `VERDICT_MARKERS` substring check is
   replaced by the `\b`-anchored `VERDICT_RE`, and its dedicated
   `bypass`-does-not-count-as-`pass` test case passes.
6. All five gates' domain checks (named source, rejected alternative,
   model-card fields, offline/online evaluation, ADR headings) are
   section-span-scoped per the mechanism in requirement 2, each with at
   least one "term present but in wrong section → still denies" test
   case.
7. **Full test suite green** — every `ml-engineering-*/tests/*.sh` file
   exits 0, run individually and (if a repo-root aggregate runner is
   added in phase 2, mirroring `core/hooks/tests/run-all.sh`'s pattern)
   via that aggregate — as the final phase-2 gate before the A+
   remediation issue is closed.
8. README's Layout/Install sections and kill-switch table match the
   plugin list in `.claude-plugin/marketplace.json` and each gate
   script's own header comment, verified by a straight diff at PR time
   (no plugin present in marketplace.json but absent from README, and
   vice versa).

## Consequences

Adopting `gate-lib.sh`/`gate-lib.py` by reference means this rulebook's
five gates now depend on core's shared library staying available at
`${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/`; a future core change to
`gate_reconstruct_write`'s semantics propagates to all five gates without
a local re-sync PR, which is the intended benefit but also means this
repo's gates are no longer independently self-contained — a regression in
core's own gate-lib now has blast radius here too, mitigated by core's own
`run-gate-lib-tests.sh` gating that library's changes upstream. The two
new local helpers (section-span parsing, word-boundary marker matching)
become five-times-duplicated code (one copy per gate file, matching this
repo's existing one-file-per-gate convention) rather than a shared local
module; phase 2 should weigh extracting a local `lib/` if duplication
proves costly, but this proposal does not mandate that extraction now.

Rejected alternative: reimplementing fail-closed/kill-switch/JSON/
path/reconstruction logic locally in each of the five gates instead of
sourcing gate-lib.sh — considered and declined, because issue-10's own
precondition explicitly forbids local reimplementation of what gate-lib.sh
already covers, and because a from-scratch local fix would re-derive
exactly the "same shapes, 2-3 different idioms each" duplication issue-72
was created to eliminate (five independent hand-fixes of the same
kill-switch idiom are five independent chances to get the fix subtly
wrong again, which is exactly how the current bug arrived in this repo
in the first place).

This proposal implements nothing; phase 2 is the implementation PR that
satisfies the criteria above.

Source: `docs/handbooks/gate-house-standard.md` (issue-72, core, 2026-08-01).
