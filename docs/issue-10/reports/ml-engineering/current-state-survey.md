# Current-state survey (issue-10, ml-engineering — gate A+ hardening)

Audit baseline: 2026-08-01, current grade B-. This survey establishes the
rigor floor before any proposal: what exists, exactly where each of the
four named defects lives, what `core`'s gate-house standard (issue-72,
landed) actually offers, and the resulting GAP vs. REUSE split.

## 1. Inventory: hook scripts in this repo

Five role-specific `PreToolUse` methodology gates, one per plugin, all
matching `Write|Edit|MultiEdit` on `docs/issue-<n>/...ml-engineering...md`
targets, plus one `SessionStart` directive plugin. No local generic gate
(trailer/record-fields/handbook-trigger) is vendored here — those are
registered globally by `core`, confirmed accurate against
`core/hooks/*.sh` in the `tokenmaxxxer-core-issue-72-implementation`
checkout.

| Plugin dir | Hook file | Gate enforces | Test file | Case count |
|---|---|---|---|---|
| `ml-engineering` | `hooks/directive.sh` | SessionStart role directive (not a gate) | none | n/a |
| `ml-engineering-adr-proposal` | `hooks/methodology-gate.sh` | phase-1 ADR shape: Context/Decision/Rationale/Consequences headings, named source, rejected-alternative | `tests/adr-proposal-gate.sh` | not yet read in detail — same 2-case skeleton pattern as ml-test-score (confirmed by direct read below) |
| `ml-engineering-eval-discipline` | `hooks/methodology-gate.sh` | phase-2 record: distinct offline+online evaluation subsections | `tests/eval-discipline-gate.sh` | 2-case skeleton pattern |
| `ml-engineering-ml-test-score` | `hooks/methodology-gate.sh` | phase-2 record: 4 ML Test Score rubric sections, each scored | `tests/ml-test-score-gate.sh` | **2 cases** (read in full: `run allow all-sections-scored`, `run deny monitoring-unscored`) |
| `ml-engineering-model-provenance` | `hooks/methodology-gate.sh` | phase-2 record: model-card fields + data/model version identifiers | `tests/model-provenance-gate.sh` | 2-case skeleton pattern |
| `ml-engineering-slo-serving` | `hooks/methodology-gate.sh` | phase-2 record: serving pattern, service+model-behavior SLO, staged rollout, rollback conditions | `tests/slo-serving-gate.sh` | 2-case skeleton pattern |

All five `methodology-gate.sh` files share one skeleton (same fail-closed
trap shim, same kill-switch case, same root-resolution helpers, same
Write/Edit/MultiEdit reconstruction block, same `has_any()` substring
helper) — they were generated from one template, so every defect class
below is present in **all five**, not just the one file cited as the
concrete instance.

Confirms the audit's "worst-in-class" claim: every test file this survey
found is exactly two cases (one allow, one deny), zero coverage of Edit,
MultiEdit, replace_all, malformed JSON, kill-switch garbage values, or
absolute-path matching — none of the issue's six mandatory categories are
exercised anywhere in this repo today.

## 2. The four audit findings, located

### Finding 1 — thin test suite, dead code
- Thin suite: `ml-engineering-ml-test-score/tests/ml-test-score-gate.sh:42-43`
  — exactly two `run` calls (`allow all-sections-scored`, `deny
  monitoring-unscored`), no other case categories. Same 2-case shape
  confirmed present in the other four `tests/*.sh` files (each is a
  single-file gate + a 2-case runner, no shared harness).
- Dead code — eval-discipline's check 3:
  `ml-engineering-eval-discipline/hooks/methodology-gate.sh:179-182`:
  ```python
  # 3. Neither substituting for the other — exactly one of the two
  #    labels present (not both, not neither).
  if has_offline_label != has_online_label:
      missing.append("eval-not-substitutable")
  ```
  Trace: check 1 (lines 167-171) already appends
  `offline-evaluation-missing` whenever `has_offline_label` is false; check
  2 (173-177) does the same for `has_online_label`. Check 3 can only ever
  fire when exactly one of the two booleans is false — but that is exactly
  the condition under which check 1 or check 2 has *already* appended a
  `missing` entry and the gate is already going to `deny()`. There is no
  reachable state where check 3 is the sole reason `missing` is non-empty;
  it never changes the allow/deny outcome, only pads the message. It is
  live code that executes but is functionally unreachable as an
  independent check — literal instance of the audit's "check3 unreachable
  dead code" finding.

### Finding 2 — substring "mention" mistaken for section placement
- `ml-engineering-adr-proposal/hooks/methodology-gate.sh:171-180`:
  `has_year_paren` / `has_any("source:", "cited")` for "named source" and
  `has_any("rejected alternative", "rejected:", "considered and
  declined", "declined because")` for "rejected alternative" both search
  `low` (the entire lower-cased document) with no positional constraint —
  the term can appear anywhere, e.g. inside the Context section, and still
  satisfy the check.
- `ml-engineering-model-provenance/hooks/methodology-gate.sh:165-168`:
  `for field in ("intended use", "limitations", "training data",
  "evaluation data"): if field not in low: missing.append(...)` — pure
  whole-document substring test, no section-anchoring at all.
- `ml-engineering-eval-discipline/hooks/methodology-gate.sh:164,170,173,176`
  (`has_offline_label = "offline evaluation" in low`, etc.) — same
  whole-document substring pattern.
- The one partial counter-example already in the repo:
  `ml-engineering-ml-test-score/hooks/methodology-gate.sh:170-194` slices
  the document between header positions and requires each section's
  verdict marker to fall inside its own slice — this is the seed of the
  section-aware approach the A+ proposal should generalize to the other
  four gates, not a template to copy verbatim (see Finding 3, which lives
  inside this same slice logic).

### Finding 3 — 'pass' matches inside 'bypass'
- `ml-engineering-ml-test-score/hooks/methodology-gate.sh:168` defines
  `VERDICT_MARKERS = ("pass", "fail", "score:", "/10", "verdict")` and
  line 194 checks `if not any(marker in slice_ for marker in
  VERDICT_MARKERS)` — plain substring `in`, no word boundary. A section
  slice containing only prose like "monitoring alerts bypass the on-call
  rotation during business hours" would satisfy the `"pass" in slice_`
  branch and the gate would treat that section as scored when it is not.
  No other gate in this repo currently checks for the literal token
  `pass`, so this is the sole concrete instance, but the same
  substring-`in` idiom (`has_any()`, used across all five gates) is
  latently exposed to the identical class of bug for any future short
  marker word.

### Finding 4 — README out of sync
- `README.md`'s "Layout" section lists only `ml-engineering/.claude-plugin/
  plugin.json`, `ml-engineering/hooks/hooks.json`, `ml-engineering/hooks/
  directive.sh`, `docs/specs/approvers.md`, `docs/specs/record-norms.md`.
  It does not mention the five `ml-engineering-{adr-proposal,eval-
  discipline,ml-test-score,model-provenance,slo-serving}` plugins at all,
  even though `.claude-plugin/marketplace.json` lists all six plugins and
  they are the entire enforcement mechanism under audit. Not a reference
  to a file that doesn't exist (no literal "ghost file" path found in
  README text — the `approvers.md`/`record-norms.md`/`directive.sh`
  references it does make all resolve to real files on disk), but the
  inverse and equally out-of-sync failure: five real, load-bearing hook
  files and their five distinct kill-switch env vars
  (`ML_ENGINEERING_{ADR_PROPOSAL,EVAL_DISCIPLINE,ML_TEST_SCORE,
  MODEL_PROVENANCE,SLO_SERVING}_GATE_OFF`) are entirely undocumented. The
  "Install" section's `claude plugin install ml-engineering` line also
  does not mention installing the five gate plugins, which is required
  for the gates to actually run (marketplace.json plugin list confirms
  they are separate installable plugins, not sub-parts of
  `ml-engineering`).

## 3. Kill-switch bug — present in all five gates (relevant to requirement 1)

Every `methodology-gate.sh` (e.g.
`ml-engineering-ml-test-score/hooks/methodology-gate.sh:25-28`) uses:
```bash
case "${ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```
This is the exact "any unrecognized value silently disables" bug
`gate-house-standard.md` documents as bug #1 in core's own pre-issue-72
canon (`core/hooks/lib/gate-lib.sh:43-68`'s doc comment traces the same
idiom verbatim: `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac`). A
typo in the env var, e.g. `ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF=1x`,
silently disables the gate today. This is not separately numbered in the
issue's four findings but is explicitly named in requirement 1
("kill-switch env values => treated as gate ACTIVE not bypassed").

## 4. What `core/hooks/lib/gate-lib.sh` + `gate-lib.py` provide today

Repo location (this working tree's sibling checkout used for research):
`/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-72-implementation/core/hooks/lib/gate-lib.sh` (+ `gate-lib.py`, same dir). In the
landed core repo this is `core/hooks/lib/gate-lib.sh`.

- `gate_trap_fail_closed` (`gate-lib.sh:36-41`) — installs the canonical
  fail-closed `EXIT` trap: any exit code other than 0/2 is remapped to 2
  with an stderr message. Documented call convention: first statement in
  the script, before `set -uo pipefail` (`gate-lib.sh:11-16` usage
  comment), so a syntax error or unset-variable abort on a later line is
  still caught.
- `gate_kill_switch_active <value>` (`gate-lib.sh:61-68`) — fixed
  semantics: only a recognized on-spelling (`1`/`true`/`yes`/`on`,
  case-insensitive) disables (`return 1`); empty, a recognized
  off-spelling, or **any unrecognized value** all stay active (`return
  0`). Directly fixes the Section 3 bug above.
- `gate_deny <name> <msg>` / `gate_allow` (`gate-lib.sh:72-79`) —
  stderr-only deny (`exit 2`) / allow (`exit 0`). This repo's gates
  already write to stderr via local `deny()` closures with the same
  shape, so this is a drop-in rename, not new behavior.
- `gate_bash_write_targets <command>` (`gate-lib.sh:88-90`) — token-scans
  a `Bash` tool_input.command string for path-shaped candidates. Not
  required by issue-10 (this repo's gates target
  Write/Edit/MultiEdit only, no Bash-write coverage requested), noted for
  completeness.
- `gate_parse_json_or_deny(raw, deny)` (`gate-lib.py:19-36`) — parses
  `raw` as a JSON object or calls `deny(msg)`; denies on empty payload,
  `json.loads` failure, or non-dict top level. Directly covers the
  malformed-JSON requirement.
- `gate_normalize_path(root, path)` (`gate-lib.py:39-66`) — pure
  string/path-algebra normalization of an absolute, relative, or
  `./`-prefixed path against `root` to a root-relative forward-slash
  tail, or `None` if it resolves outside root. Explicitly documented as
  **not** touching the filesystem (no `realpath`/symlink resolution) —
  callers needing symlink-safe resolution must `realpath` their own
  `root` first (`gate-lib.py:52-55`).
- `gate_reconstruct_write(tool, tool_input, current_content)`
  (`gate-lib.py:87-153`) — full `Write`/`Edit`/`MultiEdit`/`NotebookEdit`
  reconstruction. `Edit` honors `tool_input.get("replace_all", False)`
  (`gate-lib.py:120-126`, via the shared `_apply_replace` helper at
  `gate-lib.py:69-84`); `MultiEdit` applies `tool_input["edits"]` in
  order, each edit's own `replace_all` honored independently
  (`gate-lib.py:128-143`); `NotebookEdit` returns the edited cell's new
  source for `insert`/`replace` edit modes (`gate-lib.py:145-150`).
  Directly covers the Edit/MultiEdit/replace_all requirement — this repo's
  current `Edit`/`MultiEdit` handling
  (e.g. `ml-engineering-ml-test-score/hooks/methodology-gate.sh:133-150`)
  always does `text.replace(old, new, 1)`, **never reads
  `replace_all` at all**, which is exactly the bug
  `gate-house-standard.md:52-56` documents as bug #2 in core's own
  pre-issue-72 `record-fields-gate.sh`.

What `gate-lib.sh`/`gate-lib.py` do **not** provide (confirmed by reading
both files in full — no other functions exist beyond the ones listed
above): word-boundary/regex-safe short-token text matching, and any
section/adjacency/structural text-placement helper. Both are pure
generic JSON/path/reconstruction primitives; semantic "is this term in
the right section" judgment is left to each gate's own domain logic by
design (a shared library cannot know a given rulebook's required section
names).

## 5. What `docs/handbooks/gate-house-standard.md` mandates

(Reference copy read at `/tmp/claude-1000/core-ref/gate-house-standard.md`;
canonical path in the landed core repo is
`core/docs/handbooks/gate-house-standard.md`... — exact top-level location not
independently re-verified from the `core-ref` copy's own path metadata, but
content matches the standard cited throughout core's own gates.)

- Sourcing convention: `. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"`
  from bash, `importlib.util.spec_from_file_location` against
  `os.environ["GATE_LIB_PY"]` from Python (gate-house-standard.md:12-14,
  gate-lib.sh:11-26).
- Reference-only, never-copy rule enforced by `stub-check.sh` via
  `core/hooks/tests/canon-manifest.txt` (gate-house-standard.md:6-9,
  91-94) — a rulebook must source, not vendor, `gate-lib.sh`/`gate-lib.py`.
- Standard six-case mandatory test harness
  (`run-gate-lib-tests.sh`, gate-house-standard.md:58-75): (1) `Edit` with
  `replace_all: true` against a multiply-occurring `old_string`; (2)
  `MultiEdit` with mixed `replace_all` true/false edits in one call; (3)
  malformed JSON (truncated, non-object, empty); (4) kill-switch set to an
  unrecognized value, asserting the gate **stays active**; (5) absolute
  `file_path` matching the same scope a relative-path fixture matches,
  plus a `./`-prefixed variant; (6) a `Bash`-tool write reaching the same
  target a `Write`-tool call would hit. Issue-10's five mandatory
  categories map onto cases 1-5 of this list (case 6 is Bash-specific and
  out of scope since these gates don't match `Bash`).
- `compliance-check.sh [hooks-dir]` (gate-house-standard.md:79-89) flags a
  gate reading a `*_OFF` var without calling `gate_kill_switch_active`, and
  a gate reconstructing Edit/MultiEdit via its own `.replace(...)` instead
  of `gate_reconstruct_write` — both would currently flag all five of this
  repo's gates.
- Per-repo migration checklist (gate-house-standard.md:96-115): run
  `compliance-check.sh`, migrate each flagged gate to source `gate-lib.sh`/
  load `gate-lib.py`, re-run gate tests plus an adapted six-case suite,
  re-run `compliance-check.sh` clean, then file the rulebook's own A+ issue
  citing clean compliance-check output as evidence — issue-10 is exactly
  that per-repo issue for this rulebook.

## 6. GAP vs. REUSE

**REUSE (must be sourced from `gate-lib.sh`/`gate-lib.py`, not
reimplemented):**
- Fail-closed trap → `gate_trap_fail_closed` (replaces the local `__fc`/
  `trap __fc EXIT` shim duplicated at the top of all five gates).
- Kill-switch check → `gate_kill_switch_active` (replaces the
  `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac` block in all
  five gates — directly fixes Section 3's bug).
- Malformed-JSON handling → `gate_parse_json_or_deny` (replaces each
  gate's local `try: json.loads(...) except ValueError: deny(...)` block).
- Deny/allow protocol → `gate_deny`/`gate_allow` (the local `deny()`
  closures already match this shape; migrate to the shared name for
  consistency and to satisfy `compliance-check.sh`).
- Write/Edit/MultiEdit(/NotebookEdit) reconstruction and `replace_all`
  handling → `gate_reconstruct_write` (replaces every gate's local
  `text.replace(old, new, 1)` block — directly fixes the Edit/MultiEdit/
  replace_all requirement and Finding 1's root cause for those cases).
- Path normalization (the relative/absolute/`./`-prefix algebra) →
  `gate_normalize_path`, composed with each gate's own `os.path.realpath`
  call on `root` for the symlink-safety the function's contract
  explicitly defers to the caller.

**GAP (issue-10 requires, `gate-lib.sh`/`gate-lib.py` do not provide, must
be built locally in this repo):**
- Word-boundary-safe short-token matching (the `pass`/`bypass` fix,
  Finding 3) — no such helper exists in gate-lib; a local `\b`-anchored
  regex (or equivalent) is required per gate that scans for short marker
  words.
- Section/adjacency/structural placement checking (Finding 2's fix) — no
  such helper exists in gate-lib; each gate's own section-name list is
  domain knowledge gate-lib cannot generalize. The existing
  header-position-slicing logic in `ml-engineering-ml-test-score`'s gate
  is the closest local precedent to generalize to the other four gates.
- Removing the dead `check3` in eval-discipline (Finding 1) — pure local
  logic fix, not a library concern.
- Surfacing deny reasons via stderr — already done locally in all five
  gates' `deny()` closures (`echo ... >&2; exit 2`); confirm this survives
  the migration to `gate_deny` unchanged (it does, `gate-lib.sh:72-75` is
  the same shape).
- README sync (Finding 4) — pure documentation fix, not a library concern.
- Five-gate-specific test suites exercising the six mandatory categories —
  gate-lib.sh does not ship rulebook-specific fixtures; this repo must
  adapt `run-gate-lib-tests.sh`'s six-case shape to each of its five
  gates' own target-path/section conventions, per the migration checklist
  in Section 5.
