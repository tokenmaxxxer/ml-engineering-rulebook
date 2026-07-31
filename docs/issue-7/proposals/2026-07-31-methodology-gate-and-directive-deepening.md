---
subject: issue-7
role: ml-engineering
loop_state: scope-proposed
---

# ADR: enforce the adopted ml-engineering methodology as a plugin set

**Revision note (2026-07-31):** an approver PR-8 review comment rejected
this proposal's original single-gate/single-directive-deepening shape and
required a restructure: each adopted methodology becomes its own
independent plugin (core's `freelunch`/`scout` pattern — one rulebook,
several plugins), phase-1 and phase-2 norms are each expressed as *which
plugins compose to form them*, every plugin is self-contained
(directive/gate/tests as applicable) and registered in
`.claude-plugin/marketplace.json`, and the proposal must carry an explicit
plugin list (name, owned methodology, components, composition relation).
This revision replaces §Decision/§Rationale/§Consequences below in place;
§Context is extended, not replaced.

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

Decompose the single planned `ml-engineering` mega-plugin into a **plugin
set**: one independent plugin per adopted methodology, plus the existing
base role plugin unchanged as the identity/composition root. Each
methodology plugin is self-contained (its own `.claude-plugin/plugin.json`,
`hooks/` incl. `hooks.json`, and test pair) and is registered in
`.claude-plugin/marketplace.json` alongside `ml-engineering`. No plugin
duplicates another's write surface or required-element check.

### Plugin list

| Plugin | Owns (methodology) | Components | Composes with |
|---|---|---|---|
| `ml-engineering` (existing, unchanged) | Role identity, `PRODUCES` facet text pointing at the methodology plugins below, `SessionStart` directive | `hooks/directive.sh`, `hooks/hooks.json` (`SessionStart` only), `.claude-plugin/plugin.json` | Base — every session enables this plus whichever methodology plugins the current phase needs |
| `ml-engineering-adr-proposal` (new) | issue-1 §a: ADR-format phase-1 proposal, every domain-fact claim sourced, explicit rejected-alternative(s) statement | `hooks/methodology-gate.sh` (`PreToolUse`, matches `docs/issue-<n>/proposals/*ml-engineering*.md` only), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/adr-proposal-gate.sh` (pass/fail pair) | `ml-engineering` (base) — together these two form **phase-1 norm** |
| `ml-engineering-slo-serving` (new) | issue-1 §b serving design: serving pattern (batch/online/streaming), service+model-behavior SLO table, staged rollout, rollback conditions | `hooks/methodology-gate.sh` (`PreToolUse`, matches `docs/issue-<n>/reports/ml-engineering.md`, serving-keyword check only), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/slo-serving-gate.sh` | `ml-engineering` (base) + `ml-engineering-risk-score` — together these three form **phase-2 norm** |
| `ml-engineering-risk-score` (new) | issue-1 §b risk note: ML-Test-Score-style scored checklist (Breck et al. 2017, IEEE Big Data) across drift/latency/failure-mode | `hooks/methodology-gate.sh` (`PreToolUse`, same record path, risk-note keyword+score-marker check only), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/risk-score-gate.sh` | `ml-engineering` (base) + `ml-engineering-slo-serving` — together, phase-2 norm |

Each of the two record-side `PreToolUse` gates (`slo-serving`, `risk-score`)
matches the *same* record path but checks disjoint element sets (serving
vs. risk-note), so both fire independently on the same write and neither
needs to know the other exists — composition is "all matching gates must
pass," not a merged script. This mirrors how `ml-engineering` (base) and
`ml-engineering-adr-proposal` already compose today: distinct hooks.json
entries, independent kill switches, no shared runtime state.

1. **Directive deepening stays in the base plugin, split by facet.**
   `ml-engineering/hooks/directive.sh`'s `PRODUCES` slot expands from today's
   one-line summary into three facet blocks — phase-1 (naming
   `ml-engineering-adr-proposal`'s required elements), phase-2 serving
   (naming `ml-engineering-slo-serving`'s), phase-2 risk (naming
   `ml-engineering-risk-score`'s) — so the directive a session sees and the
   gates that mechanically check it stay in lockstep by construction.
   (Concrete text drafted in Consequences §1; not written to the file in
   this PR.)
2. **Three independent methodology gates, not one.** Each gate is modeled on
   `pricing/hooks/methodology-gate.sh`'s structure (matcher, fail-closed
   judge, substring-based element detection, kill switch) but owns exactly
   one methodology's required-element list, sitting on top of — never
   replacing — canon's `record-fields-gate.sh`. Splitting by methodology
   (rather than one script checking all three) means a future methodology
   change (e.g. issue-1 §b's risk-note rubric changing) touches one plugin,
   never the proposal-side or serving-side gates.
3. **No state-tracking machinery**, in any plugin. This role's methodology
   has no ordering constraint that a single document's own structure and
   the existing phase-1/phase-2 Approve gate don't already enforce (survey
   gap #3, brief "Skip" section). Recorded here as a considered-and-declined
   design choice, not an oversight.
4. **Gate tests travel with their owning plugin.** Each of the three new
   plugins ships its own pass/fail test pair (stdin JSON in, exit code out)
   under its own `tests/`, rather than one combined repo-root suite —
   consistent with each plugin being self-contained and independently
   registrable/disable-able.
5. **No new agents/checklist beyond each gate's own required-elements
   list.** This role's methodology has no repeated multi-step *procedure* a
   human or agent walks through interactively (unlike, say,
   `pricing-research`'s 6-step skill) — each plugin has a fixed set of
   required document elements, which its own gate checks directly. A
   handbook distilling §b into worked guidance remains available as future
   phase-2 scope but is not required by this proposal's own logic (see
   Rationale for why gates suffice here without one).
6. **Marketplace registration.** `.claude-plugin/marketplace.json` gains
   three entries (`ml-engineering-adr-proposal`, `ml-engineering-slo-serving`,
   `ml-engineering-risk-score`) alongside the existing `ml-engineering`
   entry, each with a one-line description naming its owned methodology —
   mirroring how `tokenmaxxxer-core`'s marketplace.json lists `core`,
   `terse`, `freelunch`, `scout`, `warrant` as siblings rather than one
   fused plugin.

## Rationale

**Why a plugin per methodology, not one `ml-engineering` mega-plugin.** The
approver's PR-8 feedback names the reference shape directly: core's
`freelunch`/`scout`/`warrant`/`terse` are independent plugins under one
marketplace, each owning exactly one methodology, not facets bundled into
`core` itself (`tokenmaxxxer-core/.claude-plugin/marketplace.json`, five
sibling entries). Bundling all three of this role's adopted methodologies
(ADR-proposal, SLO-serving, risk-score) into `ml-engineering`'s own
`hooks/` would repeat the exact shape core moved away from: one plugin
whose internals silently encode several unrelated methodologies, each only
discoverable by reading the script rather than the marketplace listing. As
independent plugins, each is independently versionable, disable-able (own
kill switch), and testable, and the marketplace listing itself becomes the
plugin-list documentation the approver asked for.

**Why a `pricing`-style gate shape inside each plugin, not
`implementation-rulebook`'s hook-machine depth.** The issue's success bar
names "implementation-rulebook의 훅 머신 수준" but this role's
`WRITE_SCOPE: []` (report-only, no code output) means there is no
multi-file, multi-session build cycle to track — the entire enforceable
surface is two documents (one phase-1 proposal, one phase-2 record).
`implementation-rulebook`'s depth comes from tracking work *across*
sessions and files (`state.sh`, `hunt-guard.sh`) because a coding role's
work literally spans them; importing that machinery here would enforce
process for work this role structurally cannot produce. The bar this
proposal targets instead is: **does the enforcement mechanism reach the
issue's actual ask (produces-required-elements checked mechanically, with
fail-closed and tested behavior) at the same rigor implementation-rulebook
applies to its own surface, packaged the way the approver requires (one
plugin per methodology)** — which is what the three gates above deliver for
this role's actual (narrower) surface. `pricing-rulebook` already solved
the gate-shape half of this problem (methodology-in-directive → mechanical
gate, report-only role) and is the issue text's own named reference, so its
per-gate structure is adopted directly rather than re-derived; the
plugin-per-methodology packaging is layered on top per the approver's
correction.

**Why on top of canon, never a copy — and true for each of the three
plugins independently.** The issue's own constraint ("캐논 스크립트는
참조만·복사 금지") and the already-landed issue-2 decision both require
this. `pricing/hooks/methodology-gate.sh` demonstrates the pattern works in
practice: it re-derives only the small amount of path-resolution logic it
needs (it cannot `source` canon's gate internals, since those are gate
*scripts*, not a library — `core/hooks/lib/role-directive.sh` is the only
canon file meant to be sourced, and it doesn't cover gate logic) while
leaving `record-fields-gate.sh` itself untouched and doing none of its job
twice. Splitting into three plugins does not change this: each of
`ml-engineering-adr-proposal`, `-slo-serving`, `-risk-score` re-derives the
same small path-resolution shim independently (a few lines each, not worth
extracting into a shared library canon doesn't provide), rather than one
plugin depending on internals of another.

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

### 1. `ml-engineering/hooks/directive.sh` — deepened `PRODUCES` text, naming the owning plugin per facet (phase 2 draft, not applied in this PR)

Per-facet, actionable form to replace the current one-line `PRODUCES`
(exact `$'...'` single-physical-line encoding finalized in phase 2, per the
issue-2-established convention):

```
PHASE 1 (proposal) — owned by ml-engineering-adr-proposal — steps:
  (1) current-state survey, (2) scout sweep per scout-directive unless a
  skip condition applies and is recorded, (3) ADR-format proposal citing
  (1)+(2).
  Judgment criteria: every domain-fact claim carries a named source;
  the proposal states which alternative(s) were rejected and why.
  Prohibited: unsourced "industry standard" claims; skipping the survey/
  scout stages without a recorded skip reason; executing phase-2 changes
  in a phase-1 PR.

PHASE 2 (record) — required components:
  serving design (owned by ml-engineering-slo-serving): serving pattern
    (batch/online/streaming), service SLO table (latency/availability/
    throughput/cost), model-behavior SLO (what's tracked + threshold),
    rollout stages + promotion criteria, rollback conditions.
  risk note (owned by ml-engineering-risk-score), three scored sections
    (pass/fail or numeric score per item — prose-only entries are
    non-conforming):
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

### 2. Three new plugins, each with its own gate (phase 2)

All three follow `pricing/hooks/methodology-gate.sh`'s structure (bash
`__fc` fail-closed trap, python3 heredoc judge, `deny()`/exit 2 on
violation, path-resolution matching this repo's own proposal/record paths)
but each owns one methodology's kill switch and required-element list:

- **`ml-engineering-adr-proposal/hooks/methodology-gate.sh`** — matches
  `docs/issue-<n>/proposals/*ml-engineering*.md` only. Kill switch
  `ML_ENGINEERING_ADR_PROPOSAL_GATE_OFF=1`. Checks: ADR section markers
  present (Context/Decision/Rationale/Consequences or their Korean
  equivalents used in this repo's existing docs), at least one named source
  pattern, at least one explicitly rejected alternative.
- **`ml-engineering-slo-serving/hooks/methodology-gate.sh`** — matches
  `docs/issue-<n>/reports/ml-engineering.md` only. Kill switch
  `ML_ENGINEERING_SLO_SERVING_GATE_OFF=1`. Checks: serving-design keywords
  (serving pattern, SLO, rollout, rollback) all present.
- **`ml-engineering-risk-score/hooks/methodology-gate.sh`** — matches the
  same record path. Kill switch `ML_ENGINEERING_RISK_SCORE_GATE_OFF=1`.
  Checks: risk-note keywords for all three sections (drift, latency,
  failure mode), each paired with a score/verdict marker (pass/fail/
  score-bearing digit) — mirroring `pricing/hooks/methodology-gate.sh`'s
  "digits present but no labeling language" check (its element 5) adapted
  to "section present but no score."

Each plugin's own `.claude-plugin/plugin.json` and `hooks/hooks.json`
(single `PreToolUse` entry) make it independently loadable/disable-able —
none depends on another's files.

### 3. Gate tests travel with their owning plugin (new, phase 2)

- `ml-engineering-adr-proposal/tests/adr-proposal-gate.sh`
- `ml-engineering-slo-serving/tests/slo-serving-gate.sh`
- `ml-engineering-risk-score/tests/risk-score-gate.sh`

Each feeds its own gate script a pass-case payload (content with all of
that plugin's required elements) and a fail-case payload (one element
missing), asserting exit 0 / exit 2 respectively, following the pattern
visible in `implementation-rulebook/tests/run-gate-tests.sh` (test runner
shape, referenced not copied).

### 4. `.claude-plugin/marketplace.json` — three new entries

Alongside the existing `ml-engineering` entry, add `ml-engineering-adr-
proposal`, `ml-engineering-slo-serving`, `ml-engineering-risk-score`, each
`source` pointing at its own top-level directory, each `description`
naming its one owned methodology — mirroring
`tokenmaxxxer-core/.claude-plugin/marketplace.json`'s five-sibling shape.

### 5. `ml-engineering/hooks/hooks.json` unchanged

The base plugin keeps only its existing `SessionStart` entry
(`directive.sh`); it gains no `PreToolUse` entry itself — that lives in the
three new plugins.

### 6. `docs/issue-7/reports/ml-engineering.md` — deferred

Per contract v3 s19, this role's own phase-2 record is phase-2 output like
code; not written in this PR.

## How success will be judged
- A future ml-engineering phase-1 proposal missing a source citation or a
  rejected-alternative statement is denied by `ml-engineering-adr-
  proposal`'s gate before it can be committed.
- A future ml-engineering phase-2 record with a risk-note section present
  but no scored verdict (prose-only) is denied by `ml-engineering-risk-
  score`'s gate — mirroring how `pricing/hooks/methodology-gate.sh` denies
  a digit-bearing verdict with no label.
- A future ml-engineering phase-2 record missing a rollback condition in
  its serving design is denied by `ml-engineering-slo-serving`'s gate.
- `.claude-plugin/marketplace.json` lists all four plugins (base +
  three methodology plugins), each independently named and described —
  the plugin list itself is the artifact the approver's feedback asked for.
- `docs/issue-7/reports/ml-engineering.md` (once Approved) records all
  three gates' implementation plus, per gate, both a passing and a failing
  sample write, matching `pricing-rulebook`'s own success criterion for its
  analogous gate.

## Files (write set, once approved — phase 2 only)

- `ml-engineering/hooks/directive.sh` (edited — deepened `PRODUCES`, naming
  the owning plugin per facet)
- `ml-engineering-adr-proposal/.claude-plugin/plugin.json` (new)
- `ml-engineering-adr-proposal/hooks/methodology-gate.sh` (new)
- `ml-engineering-adr-proposal/hooks/hooks.json` (new)
- `ml-engineering-adr-proposal/tests/adr-proposal-gate.sh` (new)
- `ml-engineering-slo-serving/.claude-plugin/plugin.json` (new)
- `ml-engineering-slo-serving/hooks/methodology-gate.sh` (new)
- `ml-engineering-slo-serving/hooks/hooks.json` (new)
- `ml-engineering-slo-serving/tests/slo-serving-gate.sh` (new)
- `ml-engineering-risk-score/.claude-plugin/plugin.json` (new)
- `ml-engineering-risk-score/hooks/methodology-gate.sh` (new)
- `ml-engineering-risk-score/hooks/hooks.json` (new)
- `ml-engineering-risk-score/tests/risk-score-gate.sh` (new)
- `.claude-plugin/marketplace.json` (edited — three new plugin entries)
- `docs/issue-7/reports/ml-engineering.md` (phase-2 record)
