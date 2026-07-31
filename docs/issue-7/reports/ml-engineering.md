---
subject: issue-7
role: ml-engineering
loop_state: landed
---

# Record: methodology gate — plugin set implementation

## What was done

Implemented the plugin set decided in
`docs/issue-7/proposals/2026-07-31-methodology-gate-and-directive-deepening.md`
(revision 2, Approved via issue comment `APPROVE issue-7/ml-engineering`).
Five new, independent, self-contained plugins were added at repo root
(`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/methodology-gate.sh`,
`tests/*.sh` each), registered in `.claude-plugin/marketplace.json` alongside
the existing `ml-engineering` base plugin:

- `ml-engineering-adr-proposal` — phase-1 ADR-proposal gate (matches
  `docs/issue-<n>/proposals/*ml-engineering*.md`).
- `ml-engineering-slo-serving` — phase-2 serving-design gate.
- `ml-engineering-ml-test-score` — phase-2 ML Test Score gate (Breck et al.
  2017's four rubric sections, each requiring a scored verdict).
- `ml-engineering-model-provenance` — phase-2 model-card + data/model
  versioning gate.
- `ml-engineering-eval-discipline` — phase-2 offline/online evaluation gate.

The four record-side gates (`slo-serving`, `ml-test-score`,
`model-provenance`, `eval-discipline`) all match the same
`docs/issue-<n>/reports/ml-engineering.md` path but check disjoint element
sets, firing independently per the proposal's composition model. Each gate
re-derives the path-resolution/fail-closed boilerplate from
`pricing/hooks/methodology-gate.sh` (referenced, not copied) and owns its
own kill switch (`ML_ENGINEERING_<NAME>_GATE_OFF=1`).

`ml-engineering/hooks/directive.sh`'s `PRODUCES` slot was deepened from a
one-line summary into the five-facet form drafted in the proposal's
Consequences §1, naming each owning plugin per facet.
`.claude-plugin/marketplace.json` gained the five new entries.

## Why

Per contract v3 §19, phase 2 opens only after Approve; the approver's PR-8
review required a plugin-per-methodology shape (mirroring core's
`freelunch`/`scout`/`warrant`), which this record executes verbatim against
the already-approved plugin list and file set (proposal §Files).

## Gate tests: passing and failing samples

### `ml-engineering-adr-proposal`

- Pass: content with `# Context` / `# Decision` / `# Rationale` /
  `# Consequences` headings, a `(Smith 2020)`-style source, and the phrase
  "rejected alternative" → gate allows (exit 0).
- Fail: same content with the rejected-alternative sentence removed → gate
  denies (exit 2), listing `rejected-alternative` as the missing element.
- Verified: `bash ml-engineering-adr-proposal/tests/adr-proposal-gate.sh` →
  `2 passed, 0 failed`.

### `ml-engineering-slo-serving`

- Pass: content naming a serving pattern, latency/availability SLOs, a
  drift threshold, staged rollout with promotion stages, and rollback
  conditions → gate allows.
- Fail: same content with the rollback sentence removed → gate denies,
  listing `rollback-conditions`.
- Verified: `bash ml-engineering-slo-serving/tests/slo-serving-gate.sh` →
  `2 passed, 0 failed`.

### `ml-engineering-ml-test-score`

- Pass: all four Breck et al. 2017 section headers (`Data Tests`,
  `Model Tests`, `ML Infrastructure Tests`, `Monitoring Tests`), each
  followed by a pass/fail/score marker → gate allows.
- Fail: same content with the Monitoring Tests section's verdict marker
  removed → gate denies, listing `section-unscored:monitoring tests`.
- Verified: `bash ml-engineering-ml-test-score/tests/ml-test-score-gate.sh`
  → `2 passed, 0 failed`.

### `ml-engineering-model-provenance`

- Pass: model card fields (intended use, limitations, training data,
  evaluation data) plus a dataset version and a model version identifier
  → gate allows.
- Fail: same content with the model-version identifier removed → gate
  denies, listing `model-version`.
- Verified:
  `bash ml-engineering-model-provenance/tests/model-provenance-gate.sh` →
  `2 passed, 0 failed`.

### `ml-engineering-eval-discipline`

- Pass: a labeled "Offline evaluation" subsection (metric + holdout
  dataset) and a labeled "Online evaluation" subsection (shadow deployment)
  → gate allows.
- Fail: same content with the online-evaluation subsection removed → gate
  denies, listing `online-evaluation-missing` and `eval-not-substitutable`.
- Verified: `bash ml-engineering-eval-discipline/tests/eval-discipline-gate.sh`
  → `2 passed, 0 failed`.

## What did not work

Nothing structural — all five gates passed their own pass/fail test pair on
first integration; no gate needed rework once the shared boilerplate
(path-resolution, fail-closed trap, JSON payload parsing, re-derived from
`pricing/hooks/methodology-gate.sh`) was fixed across all five.

## Open findings

None.
