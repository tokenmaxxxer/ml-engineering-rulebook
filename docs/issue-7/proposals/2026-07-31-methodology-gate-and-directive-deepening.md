---
subject: issue-7
role: ml-engineering
loop_state: scope-proposed
---

# ADR: enforce the adopted ml-engineering methodology mechanically

Phase 1 proposal only. Execution (plugin changes) deferred to phase 2, after
Approve per contract v3 s19. This document itself follows the ADR format
mandated by `docs/issue-1/proposals/ml-engineering-norms.md` §a (this role's
own adopted phase-1 norm) and cites its sources per that norm's evidence
rule.

## Context

`docs/issue-1/proposals/ml-engineering-norms.md` (already landed, `ad9381f`)
adopted a methodology for both phases of this role: ADR-format phase-1
proposals with sourced claims (§a), and for phase-2, SLO-based serving
design with staged rollout (§b, serving design) and an ML-Test-Score-style
scored checklist for the risk note (§b, risk note; source cited there: Breck
et al. 2017, IEEE Big Data). That adoption reached only as far as prose: the
`PRODUCES` line in `ml-engineering/hooks/directive.sh` now *names* the
required elements, but nothing checks that a phase-1 proposal or the
phase-2 record actually contains them (`docs/issue-7/reports/ml-engineering/survey.md`
gap #1). Separately, `docs/issue-2/proposals/core-canon-reference-conversion.md`
(already landed, `cca999a`) removed every local `PreToolUse` gate this repo
had — all three were generic canon copies, now provided globally by the
`core` plugin — leaving this repo with zero role-specific enforcement of any
kind.

The scout brief (`docs/issue-7/reports/ml-engineering/scout-brief.md`)
found that `pricing-rulebook` solved the identical problem (methodology
adopted in a norms doc, `PRODUCES` updated, then converted to an actual
`PreToolUse` gate) with `pricing/hooks/methodology-gate.sh`, and that the
issue text itself names this file as the reference. The brief also compared
`implementation-rulebook`'s `coding/hooks/state.sh` (cross-session state
tracking for a code-writing role) and found it a segment mismatch for this
report-only role — see Rationale.

## Decision

1. **Directive deepening**: expand `ml-engineering/hooks/directive.sh`'s
   `PRODUCES` slot from the current one-line summary into per-facet,
   actionable text — phase-1 steps/judgment criteria/prohibitions and
   phase-2 required-components/judgment criteria/prohibitions — encoded so
   the mechanical gate below can check for the same elements the directive
   now states in prose. (Concrete text drafted in Consequences §1; not
   written to the file in this PR.)
2. **Methodology gate**: add `ml-engineering/hooks/methodology-gate.sh`, a
   `PreToolUse` gate (Write|Edit|MultiEdit) modeled directly on `pricing/
   hooks/methodology-gate.sh`'s structure (matcher, fail-closed judge,
   substring-based element detection, kill switch), sitting on top of —
   never replacing — canon's `record-fields-gate.sh`. It targets this
   role's own write surfaces only: `docs/issue-<n>/proposals/*ml-
   engineering*.md` (phase-1) and `docs/issue-<n>/reports/ml-engineering.md`
   (phase-2).
3. **No state-tracking machinery.** This role's methodology has no ordering
   constraint that a single document's own structure and the existing
   phase-1/phase-2 Approve gate don't already enforce (survey gap #3, brief
   "Skip" section). Recorded here as a considered-and-declined design
   choice, not an oversight.
4. **Gate tests**: a same-PR pass/fail test pair under the repo-root
   `tests/` directory (issue text's own requirement), exercising the new
   gate directly (stdin JSON in, exit code out) rather than only asserting
   it exists.
5. **No new agents/checklist beyond the gate's own required-elements list.**
   This role's methodology has no repeated multi-step *procedure* a human
   or agent walks through interactively (unlike, say, `pricing-research`'s
   6-step skill) — it has a fixed set of required document elements, which
   a gate checks directly. A handbook distilling §b into worked guidance
   remains available as future phase-2 scope but is not required by this
   proposal's own logic (see Rationale for why a gate suffices here without
   one).

## Rationale

**Why a `pricing`-style gate, not `implementation-rulebook`'s hook-machine
depth.** The issue's success bar names "implementation-rulebook의 훅 머신
수준" but this role's `WRITE_SCOPE: []` (report-only, no code output) means
there is no multi-file, multi-session build cycle to track — the entire
enforceable surface is two documents (one phase-1 proposal, one phase-2
record). `implementation-rulebook`'s depth comes from tracking work *across*
sessions and files (`state.sh`, `hunt-guard.sh`) because a coding role's
work literally spans them; importing that machinery here would enforce
process for work this role structurally cannot produce. The bar this
proposal targets instead is: **does the enforcement mechanism reach the
issue's actual ask (produces-required-elements checked mechanically, with
fail-closed and tested behavior) at the same rigor implementation-rulebook
applies to its own surface** — which is what the gate below delivers for
this role's actual (narrower) surface. `pricing-rulebook` already solved
exactly this shape of problem (methodology-in-directive → mechanical gate,
report-only role) and is the issue text's own named reference, so its
structure is adopted directly rather than re-derived.

**Why on top of canon, never a copy.** The issue's own constraint ("캐논
스크립트는 참조만·복사 금지") and the already-landed issue-2 decision both
require this. `pricing/hooks/methodology-gate.sh` demonstrates the pattern
works in practice: it re-derives only the small amount of path-resolution
logic it needs (it cannot `source` canon's gate internals, since those are
gate *scripts*, not a library — `core/hooks/lib/role-directive.sh` is the
only canon file meant to be sourced, and it doesn't cover gate logic) while
leaving `record-fields-gate.sh` itself untouched and doing none of its job
twice.

**Rejected alternative: push the role-specific fields into
`record-fields-gate.sh` itself (canon).** Rejected because that file is
explicitly shared across every role (`core/hooks/record-fields-gate.sh`
comment, "Promoted to core canon... per-role divergence... kept as
configuration") and currently has exactly one role-specific extension point
(`RECORD_FIELDS_TERMINAL_STATES`), not a field-schema one. Adding a field
schema there is a canon change this role cannot make unilaterally (out of
`write_scope`, and canon state is explicitly a shared-risk item per
`docs/issue-2/proposals/core-canon-reference-conversion.md`'s own note) —
the same conclusion `pricing/hooks/methodology-gate.sh`'s design already
reached ("no change to `record-fields-gate.sh` itself... the new
pricing-specific gate adds the domain check on top of, not instead of, the
generic §20 fields").

**Rejected alternative: state-tracking for phase ordering.** The issue
allows this "if needed" (필요 시). Considered and declined: the only
ordering the methodology imposes (조사→근거→채택, survey → evidence →
adoption) is already structurally enforced twice over — once by the ADR
format itself (Context, which must cite the survey/scout-brief, precedes
Decision, which precedes Consequences) and once by contract v3's own
phase-1/phase-2 Approve gate, which this role has no authority to
re-implement. Adding a third, role-local state file would duplicate an
enforcement that already exists at a level this role doesn't own, which is
exactly the kind of unnecessary layer the issue's own reference
(`implementation-rulebook`) does *not* apply where a single document
already carries the ordering (its `hunt-guard.sh`/`state.sh` machinery
exists because coding work spans multiple files and sessions, not because
every ordering constraint needs a state machine).

**Rejected alternative: an interactive agent walking the methodology
step-by-step.** `pricing-research`'s 6-step skill exists because pricing
methodology involves a *branching* decision procedure (scope-gate routes to
different methods; design-gate branches by method family) that benefits
from step-by-step guidance. This role's methodology (§b) is a fixed
checklist, not a branching procedure — a gate that checks "are these
sections present and scored" covers the same ground without needing an
agent to walk anyone through branches that don't exist here.

## Consequences

### 1. `ml-engineering/hooks/directive.sh` — deepened `PRODUCES` text (phase 2 draft, not applied in this PR)

Per-facet, actionable form to replace the current one-line `PRODUCES`
(exact `$'...'` single-physical-line encoding finalized in phase 2, per the
issue-2-established convention):

```
PHASE 1 (proposal) — steps: (1) current-state survey, (2) scout sweep
  per scout-directive unless a skip condition applies and is recorded,
  (3) ADR-format proposal citing (1)+(2).
  Judgment criteria: every domain-fact claim carries a named source;
  the proposal states which alternative(s) were rejected and why.
  Prohibited: unsourced "industry standard" claims; skipping the survey/
  scout stages without a recorded skip reason; executing phase-2 changes
  in a phase-1 PR.

PHASE 2 (record) — required components:
  serving design: serving pattern (batch/online/streaming), service SLO
    table (latency/availability/throughput/cost), model-behavior SLO
    (what's tracked + threshold), rollout stages + promotion criteria,
    rollback conditions.
  risk note, three scored sections (pass/fail or numeric score per item —
    prose-only entries are non-conforming):
    drift — baseline distribution, statistic/threshold, action on trigger.
    latency — p50/p95/p99 target vs. observed/expected, action on breach.
    failure mode — per mode: symptom → detection signal → mitigation/
    rollback.
  Judgment criteria: every risk-note item resolves to a checkable verdict,
    not narrative description.
  Prohibited: a risk-note section present but unscored; a serving design
    missing rollback conditions; adopting the MLOps full-lifecycle-maturity
    frame (out of `WRITE_SCOPE: []` per issue-1 §b's explicit skip).
```

### 2. `ml-engineering/hooks/methodology-gate.sh` (new, phase 2)

`PreToolUse` gate, structure mirrored from `pricing/hooks/
methodology-gate.sh` (bash `__fc` fail-closed trap, python3 heredoc judge,
`deny()`/exit 2 on violation, path-resolution matching this repo's own
proposal/record paths, kill switch `ML_ENGINEERING_METHODOLOGY_GATE_OFF=1`).
Required-element checks, mapped to §1's deepened `PRODUCES`:
- Proposal writes (`docs/issue-<n>/proposals/*ml-engineering*.md`): ADR
  section markers present (Context/Decision/Rationale/Consequences or
  their Korean equivalents used in this repo's existing docs), at least one
  named source pattern, at least one explicitly rejected alternative.
- Record writes (`docs/issue-<n>/reports/ml-engineering.md`): serving-design
  keywords (serving pattern, SLO, rollout, rollback) all present; risk-note
  keywords for all three sections (drift, latency, failure mode) each paired
  with a score/verdict marker (pass/fail/score-bearing digit) — mirroring
  `pricing/hooks/methodology-gate.sh`'s "digits present but no labeling
  language" check (its element 5) adapted to "section present but no
  score."

### 3. Gate tests (new, phase 2)

`tests/ml-engineering-methodology-gate.sh` (repo root, per issue text) —
feeds the gate script a pass-case payload (proposal/record content with all
required elements) and a fail-case payload (one element missing each),
asserting exit 0 / exit 2 respectively, following the pattern visible in
`implementation-rulebook/tests/run-gate-tests.sh` (test runner shape,
referenced not copied).

### 4. No `ml-engineering/hooks/hooks.json` change until phase 2

Phase 2 adds one `PreToolUse` entry wiring the new gate; `SessionStart`
entry (`directive.sh`) unchanged.

### 5. `docs/issue-7/reports/ml-engineering.md` — deferred

Per contract v3 s19, this role's own phase-2 record is phase-2 output like
code; not written in this PR.

## How success will be judged
- A future ml-engineering phase-1 proposal missing a source citation or a
  rejected-alternative statement is denied by the new gate before it can be
  committed.
- A future ml-engineering phase-2 record with a risk-note section present
  but no scored verdict (prose-only) is denied by the gate — mirroring how
  `pricing/hooks/methodology-gate.sh` denies a digit-bearing verdict with no
  label.
- `docs/issue-7/reports/ml-engineering.md` (once Approved) records the
  gate's implementation plus both a passing and a failing sample write,
  matching `pricing-rulebook`'s own success criterion for its analogous
  gate.

## Files (write set, once approved — phase 2 only)

- `ml-engineering/hooks/directive.sh` (edited — deepened `PRODUCES`)
- `ml-engineering/hooks/methodology-gate.sh` (new)
- `ml-engineering/hooks/hooks.json` (edited — new `PreToolUse` entry)
- `tests/ml-engineering-methodology-gate.sh` (new)
- `docs/issue-7/reports/ml-engineering.md` (phase-2 record)
