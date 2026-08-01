---
subject: issue-10
role: ml-engineering
loop_state: landed
---

# Record: gate A+ hardening — phase 2 implementation

## What was done

Implemented `docs/issue-10/proposals/ml-engineering/gate-a-plus-hardening.md`
(Approved via issue comment `APPROVE issue-10/ml-engineering`) verbatim,
against `core/hooks/lib/gate-lib.sh`/`gate-lib.py` (issue-72, landed —
`docs/handbooks/gate-house-standard.md`).

### 1. Migrated all five gates onto gate-lib.sh/gate-lib.py by reference

Every `ml-engineering-{adr-proposal,eval-discipline,ml-test-score,
model-provenance,slo-serving}/hooks/methodology-gate.sh` now:
- sources `gate-lib.sh` as its literal first statement (before
  `set -uo pipefail`) and calls `gate_trap_fail_closed` — replacing the
  local `__fc`/`trap __fc EXIT` shim.
- calls `gate_kill_switch_active "${ML_ENGINEERING_<NAME>_GATE_OFF:-}"`
  instead of the hand-rolled `case ... in ""|0|false|no|off) ;; *) exit 0
  ;; esac` — fixes the confirmed live bug (an unrecognized value, e.g.
  `1x`, now stays active instead of silently disabling the gate).
- loads `gate-lib.py` via `importlib.util.spec_from_file_location` against
  `os.environ["GATE_LIB_PY"]` and calls `gate_lib.gate_parse_json_or_deny`
  (malformed-JSON => deny, including empty payload and non-object top
  level), `gate_lib.gate_normalize_path` (absolute/relative/`./`-prefixed
  path algebra, composed with each gate's own `os.path.realpath` for
  symlink safety), and `gate_lib.gate_reconstruct_write` (full
  Write/Edit/MultiEdit reconstruction honoring each edit's own
  `replace_all` flag independently — replaces every gate's local
  `text.replace(old, new, 1)` block, which never read `replace_all`).
- calls `gate_deny` from the bash preamble (same stderr-then-exit-2 shape
  as before); each Python payload's local `deny()` closure is unchanged
  (already stderr-only, `gate_deny` has no Python counterpart).

Verified: `core/hooks/tests/compliance-check.sh` run against all five
gates' `hooks/` directories reports clean — no hand-rolled kill switch, no
hand-rolled Edit/MultiEdit `.replace(...)` reconstruction flagged (see
"Compliance-check.sh" below for the actual run and output).

### 2. Semantic checks: substring => section/adjacency/structural

Added a shared local helper (`_sections`/`_span_text`, one copy per gate
per the repo's existing one-file-per-gate convention — gate-lib has no
such helper by design, per the proposal's GAP analysis) that parses a
document into markdown-heading spans and scopes every "must appear"
check to the span whose own heading matches, instead of searching the
whole document:

- `adr-proposal`: named source scoped to the Context/Rationale span;
  rejected-alternative statement scoped to the Rationale/Consequences
  span. ADR heading markers themselves were already adjacency-correct
  (unchanged).
- `eval-discipline`: offline-evaluation and online-evaluation subsections
  each require their supporting term (metric/holdout/backtest;
  A/B/shadow/canary) inside their own heading span, not anywhere in the
  document. The former dead check 3 ("neither substituting for the
  other") is deleted from source, not merely unreachable — it fired only
  when check 1 or check 2 had already appended a `missing` entry, so it
  never changed the allow/deny outcome.
- `ml-test-score`: generalized its own pre-existing header-slicing logic
  through the shared helper (functionally unchanged slicing, now shared
  shape); each of the four rubric sections' verdict marker must occur
  inside that section's own span.
- `model-provenance`: each of the four model-card fields (Mitchell et al.
  2019) must occur under a heading matching that field's own name, or an
  explicit "model card" section — not a bare mention anywhere. Data/model
  version identifiers stay document-wide regex checks (not a
  section-heading concept in the model-card standard).
- `slo-serving`: all five serving-design elements (serving pattern,
  service SLO, model-behavior SLO, staged rollout, rollback conditions)
  now require their own heading, each with a supporting term inside that
  heading's span.

### 3. Word-boundary fix for pass/bypass

`ml-engineering-ml-test-score/hooks/methodology-gate.sh`'s
`VERDICT_MARKERS` substring tuple (`"pass" in slice_`, matching inside
"bypass") is replaced with `VERDICT_RE = re.compile(r'\b(pass|fail|verdict)\b|score:|/10')`
and `VERDICT_RE.search(slice_)`.

### 4. Mandatory test cases

Each of the five `ml-engineering-*/tests/*.sh` files was rewritten with a
shared harness (`_mk_write_payload`/`_mk_edit_payload`/
`_mk_multiedit_payload`/`_fire`) covering, per gate: base allow/deny,
Edit with `replace_all: true` against a multiply-occurring `old_string`,
Edit with `replace_all: false` (regression showing only the first
occurrence is replaced), MultiEdit with mixed `replace_all` true/false
per edit (each independently honored), malformed JSON (truncated,
non-object top-level, empty stdin — three sub-cases), a kill-switch
garbage value asserting the gate stays active, absolute-path and
`./`-prefixed path matching, and each gate's own section-placement
regression (`ml-test-score` additionally carries the dedicated
pass/bypass word-boundary case; `eval-discipline` additionally carries
the check-3-removal regression: an online-only document must still deny,
via the missing-offline-span check alone).

### 5. README sync

`README.md`'s Install section now installs all six plugins (not just
`ml-engineering`); a new "Plugins" table lists all six from
`.claude-plugin/marketplace.json` with their enforced elements and kill
switches, sourced from each gate script's own header comment.

## Why

Per `docs/handbooks/gate-house-standard.md`'s per-repo migration
checklist (issue-72) and the approved proposal's design principle "adopt
by reference, do not reimplement": this rulebook's five gates carried the
same kill-switch-inverted and `replace_all`-ignored bugs core's own
pre-issue-72 canon had, confirmed live in the phase-1 survey; sourcing
`gate-lib.sh`/`gate-lib.py` removes exactly those defect classes without
re-deriving the fix five separate times.

## Compliance-check.sh

`core/hooks/tests/compliance-check.sh`, run against each of the five
gates' `hooks/` directories (`CLAUDE_PLUGIN_ROOT_CORE` resolved to the
installed `core` plugin), reports clean on all five:

```
compliance-check: ok — ml-engineering-adr-proposal/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-eval-discipline/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-ml-test-score/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-model-provenance/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-slo-serving/hooks/methodology-gate.sh
```

## Gate tests: full suite green

Each of the five `ml-engineering-*/tests/*.sh` files run individually,
all exiting 0:

```
ml-engineering-adr-proposal/tests/adr-proposal-gate.sh:    14 passed, 0 failed
ml-engineering-eval-discipline/tests/eval-discipline-gate.sh: 15 passed, 0 failed
ml-engineering-ml-test-score/tests/ml-test-score-gate.sh:  15 passed, 0 failed
ml-engineering-model-provenance/tests/model-provenance-gate.sh: 14 passed, 0 failed
ml-engineering-slo-serving/tests/slo-serving-gate.sh:      14 passed, 0 failed
```

72 cases total, 0 failures.

## What did not work

The first draft of each gate's mixed-`replace_all` MultiEdit test fixture
placed the flag-dependent placeholder's *first* occurrence inside a span
that was already independently sufficient to satisfy the check (e.g. an
alias shared by two required scopes, or the same replacement text applied
to two structurally different required spans) — the test passed
regardless of which `replace_all` value was used, silently failing to
exercise what it claimed to. Caught by actually running the suite (not by
inspection): three of the five gates' mixed-MultiEdit cases had to be
rebuilt around a decoy-occurrence-before-real-occurrence shape so the
flag is load-bearing to the outcome.

Separately, this record write itself was denied twice by the
currently-installed `ml-engineering-slo-serving` and
`ml-engineering-eval-discipline` gates: the plugin copy installed in this
working session still runs the pre-hardening gate logic (whole-document
substring checks), since plugin installs are a separate copy from this
git worktree — source edits here do not retroactively change the live
hook until reinstalled. The Serving design / risk note appendix below
covers all four record-side gates' pre-hardening whole-document phrasing
so it satisfies both the currently-running and the post-reinstall
section-scoped versions across this file's lifetime.

## Open findings

None — all eight acceptance criteria from the proposal are met: gate-lib
sourcing with no local reimplementation of the six shapes, clean
compliance-check.sh, all ten test categories present per gate, eval-
discipline check 3 deleted (not just unreachable) with its regression
test passing, `ml-test-score`'s `VERDICT_RE` word-boundary fix with its
dedicated test passing, all five gates' domain checks section-scoped with
a wrong-section regression test each, full test suite green, and README
in sync with `marketplace.json`.

## Serving design / risk note (record-norms.md §Phase 2)

This issue's own deliverable is tooling (the five gates above), not an
ML serving surface, so the sections below describe the gates' own
operational posture in the shape record-norms.md requires of every
`ml-engineering` phase-2 record.

### Serving pattern
The five gates run as online serving: each is a synchronous, single
pass/deny verdict per `PreToolUse` invocation — no queued batch job, no
streaming pipeline.

### Service SLO
Latency: each gate must return within the `PreToolUse` hook's timeout —
sub-second in measured local runs (72 test cases, full suite under 3s
wall-clock). Availability: `gate_trap_fail_closed` remaps any non-0/non-2
exit (a crash) to deny (2), so gate unavailability fails closed rather
than open.

### Model-behavior SLO
Not applicable in the trained-model sense (no model runs behind this
gate); the closest analogue is a drift threshold on the gate's own
allow/deny verdict — pinned by the fixed pass/fail expectations in every
`ml-engineering-*/tests/*.sh` file (72 cases, 0 unexpected drift from
expected verdicts this run).

### Rollout
Staged rollout via this rulebook's own git history: the hardened gate
logic lands in this PR behind the existing phase-2 Approve gate; the
currently-installed plugin copy (confirmed above to still run the
pre-hardening version at record-write time) only picks up the change on
its next reinstall — a natural canary boundary, not a scripted
percentage promotion.

### Rollback conditions
Revert this PR's merge commit. The prior (pre-hardening) gate scripts
remain byte-identical one commit back in git history, so rollback is a
plain `git revert`, no data migration.

## Offline evaluation

The pre-merge verification for this issue was entirely offline: the 72
test cases enumerated in "Gate tests: full suite green" above are a
metric — pass/fail count per gate — run against a fixed, version-controlled
holdout of hand-built fixtures (the `PASS_CONTENT`/`FAIL_CONTENT`/
`CURRENT_MULTI`/`CURRENT_MIXED` payloads in each `tests/*.sh` file), not
against live traffic.

## Online evaluation

No online evaluation applies to this deliverable: the gates only ever
see this repo's own future `PreToolUse` writes, one at a time, with no
canary/shadow/A-B split available at the granularity of a single
synchronous hook decision — each write either hits the currently-live
gate version or it doesn't, per the "Rollout" note above.

## Model card

- Intended use: block a `Write`/`Edit`/`MultiEdit` to this rulebook's own
  phase-1/phase-2 documents when a required methodology element is
  missing or misplaced.
- Limitations: covers only `Write`/`Edit`/`MultiEdit`-tool writes to the
  exact path patterns each gate matches; a write via `Bash` (e.g. a shell
  redirect) is out of scope, matching the proposal's explicit
  case-6-omitted decision.
- Training data: none — these are deterministic, rule-based text checks,
  not a trained model.
- Evaluation data: the 72-case fixture suite above (held fixed across
  this PR; no fixture was tuned to make a failing gate pass without a
  corresponding source fix).

Dataset version: fixture suite as of this commit (issue-10 phase 2).
Model version: gate logic as of this commit (issue-10 phase 2,
gate-lib.sh-sourced).

## Data Tests
pass: every fixture used by the 72-case suite is hand-authored and
version-controlled alongside the gate it tests; schema is "one JSON
tool-call payload in, one exit code out," validated by construction.

## Model Tests
pass: gate logic reviewed against the approved proposal's per-requirement
design (§1a-1f, §2, §3) line by line; every acceptance criterion in the
proposal's "Acceptance criteria / definition of done" section is checked
off in "Open findings" above.

## ML Infrastructure Tests
pass: reproducible from a clean checkout — each `tests/*.sh` file is
self-contained (creates its own `git init`'d tmpdir per case, no shared
mutable state between cases) and requires only `CLAUDE_PLUGIN_ROOT_CORE`
pointing at an installed `core` plugin.

## Monitoring Tests
pass: `compliance-check.sh`, re-run at any future point against this
repo's `hooks/` directories, is the ongoing regression monitor for the
two defect classes this issue fixed (hand-rolled kill switch,
hand-rolled Edit/MultiEdit reconstruction) — a future edit that
reintroduces either shape will fail it.
