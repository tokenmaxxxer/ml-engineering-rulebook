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

**Revision note 2 (2026-07-31, WEAK domain review):** a second approver
PR-8 review comment graded the prior revision WEAK on domain coverage: the
risk-note plugin scored only three ad hoc dimensions (drift/latency/
failure-mode) instead of Breck et al. 2017's actual four-section rubric
(Data Tests, Model Tests, Infrastructure Tests, Monitoring Tests), and the
adopted set omitted model cards, data/model versioning, and offline/online
evaluation discipline — all standard ML-engineering production-readiness
practice, not covered by any plugin in revision 1. This revision (a)
replaces `ml-engineering-risk-score` with `ml-engineering-ml-test-score`,
scored across all four of the rubric's original sections, and (b) adds two
new plugins, `ml-engineering-model-provenance` (model card + data/model
versioning) and `ml-engineering-eval-discipline` (offline vs. online
evaluation as distinct, both-required disciplines). §Decision's plugin
table, §Consequences §1/§2/§3/§4, and §Files are updated in place; §Context,
§Rationale's already-settled arguments (plugin-per-methodology shape,
pricing-style gate depth, canon boundary, no state-tracking, no interactive
agent) are extended, not replaced, since none of that reasoning is what the
WEAK grade challenged.

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

Breck et al. 2017's actual rubric (already the source cited by the adopted
issue-1 §b norm) scores production readiness across four named sections —
Data Tests, Model Tests, ML Infrastructure Tests, Monitoring Tests, each
with several yes/no test items summed into a readiness score — not the
three ad hoc dimensions (drift/latency/failure-mode) revision 1's
`ml-engineering-risk-score` checked. Separately, standard ML-engineering
production practice this role's own methodology (issue-1
`ml-engineering-norms.md` §b) never enumerated but the WEAK review flagged
as missing: model documentation via model cards (Mitchell et al. 2019,
"Model Cards for Model Reporting," FAT* '19 — model details, intended use,
limitations, evaluation data, training data, ethical considerations),
data/model versioning as a named provenance discipline (Sculley et al.
2015, "Hidden Technical Debt in Machine Learning Systems," NeurIPS —
identifies unversioned data/model artifacts as a technical-debt source
distinct from code versioning), and offline evaluation (holdout/backtest
metrics before deploy) kept distinct from online evaluation (A/B/shadow/
canary after deploy) as two required, non-substitutable disciplines
(Zinkevich, "Rules of Machine Learning: Best Practices for ML Engineering,"
Google — rules on measuring training/serving skew and validating via live
experiments, not offline metrics alone).

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
| `ml-engineering-slo-serving` (new) | issue-1 §b serving design: serving pattern (batch/online/streaming), service+model-behavior SLO table, staged rollout, rollback conditions | `hooks/methodology-gate.sh` (`PreToolUse`, matches `docs/issue-<n>/reports/ml-engineering.md`, serving-keyword check only), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/slo-serving-gate.sh` | `ml-engineering` (base) + the three plugins below — together these form **phase-2 norm** |
| `ml-engineering-ml-test-score` (new, replaces revision-1's `ml-engineering-risk-score`) | issue-1 §b risk note, full rubric (Breck et al. 2017, IEEE Big Data): four scored sections — Data Tests, Model Tests, ML Infrastructure Tests, Monitoring Tests | `hooks/methodology-gate.sh` (`PreToolUse`, same record path, checks all four section headers + a score marker per item), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/ml-test-score-gate.sh` | `ml-engineering` (base) + `ml-engineering-slo-serving` |
| `ml-engineering-model-provenance` (new) | model documentation and artifact versioning: model card (Mitchell et al. 2019, FAT* '19 — model details, intended use, limitations, evaluation data, training data, ethical considerations) plus data/model version identifiers (Sculley et al. 2015, NeurIPS, unversioned artifacts named as a technical-debt source) | `hooks/methodology-gate.sh` (`PreToolUse`, same record path, checks model-card section markers + a version-identifier pattern for both data and model), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/model-provenance-gate.sh` | `ml-engineering` (base) + `ml-engineering-slo-serving` |
| `ml-engineering-eval-discipline` (new) | offline vs. online evaluation kept as two distinct, both-required disciplines (Zinkevich, "Rules of Machine Learning," Google — live-experiment validation, not offline metrics alone) | `hooks/methodology-gate.sh` (`PreToolUse`, same record path, checks an offline-evaluation subsection with metric+dataset and a separately-labeled online-evaluation subsection with method: A/B, shadow, or canary), `hooks/hooks.json`, `.claude-plugin/plugin.json`, `tests/eval-discipline-gate.sh` | `ml-engineering` (base) + `ml-engineering-slo-serving` |

Each of the four record-side `PreToolUse` gates (`slo-serving`,
`ml-test-score`, `model-provenance`, `eval-discipline`) matches the *same*
record path but checks a disjoint element set (serving design, four-section
risk rubric, model card + versioning, offline/online eval), so all four
fire independently on the same write and none needs to know the others
exist — composition is "all matching gates must pass," not a merged
script. This mirrors how `ml-engineering` (base) and
`ml-engineering-adr-proposal` already compose today: distinct hooks.json
entries, independent kill switches, no shared runtime state.

1. **Directive deepening stays in the base plugin, split by facet.**
   `ml-engineering/hooks/directive.sh`'s `PRODUCES` slot expands from today's
   one-line summary into five facet blocks — phase-1 (naming
   `ml-engineering-adr-proposal`'s required elements), phase-2 serving
   (naming `ml-engineering-slo-serving`'s), phase-2 risk (naming
   `ml-engineering-ml-test-score`'s), phase-2 model provenance (naming
   `ml-engineering-model-provenance`'s), phase-2 evaluation (naming
   `ml-engineering-eval-discipline`'s) — so the directive a session sees and
   the gates that mechanically check it stay in lockstep by construction.
   (Concrete text drafted in Consequences §1; not written to the file in
   this PR.)
2. **Five independent methodology gates, not one.** Each gate is modeled on
   `pricing/hooks/methodology-gate.sh`'s structure (matcher, fail-closed
   judge, substring-based element detection, kill switch) but owns exactly
   one methodology's required-element list, sitting on top of — never
   replacing — canon's `record-fields-gate.sh`. Splitting by methodology
   (rather than one script checking all five) means a future methodology
   change (e.g. the ML Test Score rubric's sections changing) touches one
   plugin, never the proposal-side or other record-side gates.
3. **No state-tracking machinery**, in any plugin. This role's methodology
   has no ordering constraint that a single document's own structure and
   the existing phase-1/phase-2 Approve gate don't already enforce (survey
   gap #3, brief "Skip" section). Recorded here as a considered-and-declined
   design choice, not an oversight.
4. **Gate tests travel with their owning plugin.** Each of the five new
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
   five entries (`ml-engineering-adr-proposal`, `ml-engineering-slo-serving`,
   `ml-engineering-ml-test-score`, `ml-engineering-model-provenance`,
   `ml-engineering-eval-discipline`) alongside the existing `ml-engineering`
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
sibling entries). Bundling all five of this role's adopted methodologies
(ADR-proposal, SLO-serving, ML-Test-Score, model-provenance,
eval-discipline) into `ml-engineering`'s own
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

**Why on top of canon, never a copy — and true for each of the five
plugins independently.** The issue's own constraint ("캐논 스크립트는
참조만·복사 금지") and the already-landed issue-2 decision both require
this. `pricing/hooks/methodology-gate.sh` demonstrates the pattern works in
practice: it re-derives only the small amount of path-resolution logic it
needs (it cannot `source` canon's gate internals, since those are gate
*scripts*, not a library — `core/hooks/lib/role-directive.sh` is the only
canon file meant to be sourced, and it doesn't cover gate logic) while
leaving `record-fields-gate.sh` itself untouched and doing none of its job
twice. Splitting into five plugins does not change this: each of
`ml-engineering-adr-proposal`, `-slo-serving`, `-ml-test-score`,
`-model-provenance`, `-eval-discipline` re-derives the same small
path-resolution shim independently (a few lines each, not worth extracting
into a shared library canon doesn't provide), rather than one plugin
depending on internals of another.

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
  ML Test Score (owned by ml-engineering-ml-test-score), four scored
    sections per Breck et al. 2017's full rubric (pass/fail or numeric
    score per item — prose-only entries are non-conforming):
    Data Tests — feature expectations, distribution/schema checks,
    privacy/compliance of inputs.
    Model Tests — offline metric thresholds vs. baseline, staleness
    tolerance, quality on important data slices.
    ML Infrastructure Tests — training reproducibility, model-serving
    integration test, rollback safety.
    Monitoring Tests — training/serving skew detection, prediction-quality
    tracking in production, alerting on regression.
  model provenance (owned by ml-engineering-model-provenance):
    model card — model details, intended use, limitations, evaluation
    data, training data, ethical considerations (Mitchell et al. 2019).
    data/model versioning — a version identifier for the training dataset
    and a version identifier for the model artifact, both traceable to the
    record.
  evaluation discipline (owned by ml-engineering-eval-discipline), two
    distinct required subsections:
    offline evaluation — metric(s), holdout/backtest dataset identity,
    result vs. threshold.
    online evaluation — method (A/B, shadow, or canary), comparison
    metric, decision rule for promote/rollback.
  Judgment criteria: every risk-note item resolves to a checkable verdict,
    not narrative description; model card and versioning fields are
    present and traceable, not placeholder text; offline and online
    evaluation are reported separately, never one substituting the other.
  Prohibited: an ML Test Score section present but unscored; a serving
    design missing rollback conditions; a model card missing training-data
    or limitations fields; a version identifier that is not present for
    both data and model; an evaluation section that reports only offline
    or only online results; adopting the MLOps full-lifecycle-maturity
    frame (out of `WRITE_SCOPE: []` per issue-1 §b's explicit skip).
```

### 2. Five new plugins, each with its own gate (phase 2)

All five follow `pricing/hooks/methodology-gate.sh`'s structure (bash
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
- **`ml-engineering-ml-test-score/hooks/methodology-gate.sh`** — matches
  the same record path. Kill switch `ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF=1`.
  Checks: all four Breck et al. rubric section headers present (Data
  Tests, Model Tests, ML Infrastructure Tests, Monitoring Tests), each
  paired with at least one score/verdict marker (pass/fail/score-bearing
  digit) per section — mirroring `pricing/hooks/methodology-gate.sh`'s
  "digits present but no labeling language" check (its element 5) adapted
  to "section present but no score."
- **`ml-engineering-model-provenance/hooks/methodology-gate.sh`** —
  matches the same record path. Kill switch
  `ML_ENGINEERING_MODEL_PROVENANCE_GATE_OFF=1`. Checks: model-card section
  markers present (intended use, limitations, training data, evaluation
  data), plus a version-identifier pattern present for both the training
  dataset and the model artifact.
- **`ml-engineering-eval-discipline/hooks/methodology-gate.sh`** —
  matches the same record path. Kill switch
  `ML_ENGINEERING_EVAL_DISCIPLINE_GATE_OFF=1`. Checks: a labeled offline-
  evaluation subsection with metric+dataset present, and a separately
  labeled online-evaluation subsection with method (A/B/shadow/canary)
  present — both required, neither substituting for the other.

Each plugin's own `.claude-plugin/plugin.json` and `hooks/hooks.json`
(single `PreToolUse` entry) make it independently loadable/disable-able —
none depends on another's files.

### 3. Gate tests travel with their owning plugin (new, phase 2)

- `ml-engineering-adr-proposal/tests/adr-proposal-gate.sh`
- `ml-engineering-slo-serving/tests/slo-serving-gate.sh`
- `ml-engineering-ml-test-score/tests/ml-test-score-gate.sh`
- `ml-engineering-model-provenance/tests/model-provenance-gate.sh`
- `ml-engineering-eval-discipline/tests/eval-discipline-gate.sh`

Each feeds its own gate script a pass-case payload (content with all of
that plugin's required elements) and a fail-case payload (one element
missing), asserting exit 0 / exit 2 respectively, following the pattern
visible in `implementation-rulebook/tests/run-gate-tests.sh` (test runner
shape, referenced not copied).

### 4. `.claude-plugin/marketplace.json` — five new entries

Alongside the existing `ml-engineering` entry, add `ml-engineering-adr-
proposal`, `ml-engineering-slo-serving`, `ml-engineering-ml-test-score`,
`ml-engineering-model-provenance`, `ml-engineering-eval-discipline`, each
`source` pointing at its own top-level directory, each `description`
naming its one owned methodology — mirroring
`tokenmaxxxer-core/.claude-plugin/marketplace.json`'s five-sibling shape.

### 5. `ml-engineering/hooks/hooks.json` unchanged

The base plugin keeps only its existing `SessionStart` entry
(`directive.sh`); it gains no `PreToolUse` entry itself — that lives in the
five new plugins.

### 6. `docs/issue-7/reports/ml-engineering.md` — deferred

Per contract v3 s19, this role's own phase-2 record is phase-2 output like
code; not written in this PR.

## How success will be judged
- A future ml-engineering phase-1 proposal missing a source citation or a
  rejected-alternative statement is denied by `ml-engineering-adr-
  proposal`'s gate before it can be committed.
- A future ml-engineering phase-2 record with an ML Test Score section
  present but no scored verdict in any of its four sections (prose-only)
  is denied by `ml-engineering-ml-test-score`'s gate — mirroring how
  `pricing/hooks/methodology-gate.sh` denies a digit-bearing verdict with
  no label.
- A future ml-engineering phase-2 record missing a rollback condition in
  its serving design is denied by `ml-engineering-slo-serving`'s gate.
- A future ml-engineering phase-2 record with a model card missing
  training-data or limitations fields, or missing a version identifier for
  data or model, is denied by `ml-engineering-model-provenance`'s gate.
- A future ml-engineering phase-2 record reporting only offline or only
  online evaluation results is denied by `ml-engineering-eval-discipline`'s
  gate.
- `.claude-plugin/marketplace.json` lists all six plugins (base +
  five methodology plugins), each independently named and described —
  the plugin list itself is the artifact the approver's feedback asked for.
- `docs/issue-7/reports/ml-engineering.md` (once Approved) records all
  five gates' implementation plus, per gate, both a passing and a failing
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
- `ml-engineering-ml-test-score/.claude-plugin/plugin.json` (new)
- `ml-engineering-ml-test-score/hooks/methodology-gate.sh` (new)
- `ml-engineering-ml-test-score/hooks/hooks.json` (new)
- `ml-engineering-ml-test-score/tests/ml-test-score-gate.sh` (new)
- `ml-engineering-model-provenance/.claude-plugin/plugin.json` (new)
- `ml-engineering-model-provenance/hooks/methodology-gate.sh` (new)
- `ml-engineering-model-provenance/hooks/hooks.json` (new)
- `ml-engineering-model-provenance/tests/model-provenance-gate.sh` (new)
- `ml-engineering-eval-discipline/.claude-plugin/plugin.json` (new)
- `ml-engineering-eval-discipline/hooks/methodology-gate.sh` (new)
- `ml-engineering-eval-discipline/hooks/hooks.json` (new)
- `ml-engineering-eval-discipline/tests/eval-discipline-gate.sh` (new)
- `.claude-plugin/marketplace.json` (edited — five new plugin entries)
- `docs/issue-7/reports/ml-engineering.md` (phase-2 record)
