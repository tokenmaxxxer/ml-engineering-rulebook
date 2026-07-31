# ml-engineering — phase-1 proposal norm / phase-2 output norm

Codifies `docs/issue-1/proposals/ml-engineering-norms.md` (Approved,
`APPROVE issue-1/ml-engineering`). Not mechanically gated — canon
`record-fields-gate.sh` only checks the generic contract §20 structure
(what-was-done / why / upstream-basis / loop_state / open-findings); it has
no per-role field-schema extension point (confirmed by reading
`tokenmaxxxer/tokenmaxxxer-core`'s `core/hooks/record-fields-gate.sh` at
phase-2 execution time — no such hook exists). Reviewers enforce this spec
by reading it against the record at PR review time.

## Phase 1 — proposal norm

Every phase-1 proposal in this repo follows ADR shape:

1. **배경/Context** — cite the current-state survey and scout brief; no
   uncited domain claims.
2. **채택안/Decision**.
3. **근거/Rationale** — why the choice fits this role's `YOU_DECIDE`; name
   and reject at least one alternative.
4. **결과/Consequences** — what phase-2 output/gates this forces.

All domain-fact claims carry an inline source link; uncited sentences are
marked as an assumption or dropped.

## Phase 2 — output norm

`PRODUCES` (see `ml-engineering/hooks/directive.sh`) names two record
fields; this fixes *how* each is built.

### serving design
SLO-based design + staged rollout (canary/shadow). Required components:
- serving pattern (batch/online/streaming)
- service SLO table (latency/availability/throughput/cost, as applicable)
- model-behavior SLO (what's tracked, against what threshold)
- rollout stages + promotion criteria (e.g. canary N% × comparison window × threshold)
- rollback criteria and procedure

### risk note
Scorable checklist, not prose (ML Test Score, Breck et al. 2017). Three
required sections, each pass/fail or numerically scored:
- **Drift** — baseline distribution, statistic/threshold, action on trigger.
- **Latency** — p50/p95/p99 targets vs. measured/expected, action on breach.
- **Failure mode** — per identified mode: symptom → detection signal →
  mitigation/rollback.

MLOps maturity models (full pipeline automation/reproducibility) are
explicitly out of scope — `WRITE_SCOPE: []` (report-only, no pipeline code)
makes full lifecycle maturity assessment out of this role's scope. A
one-line automation/reproducibility note inside the failure-mode section is
allowed, not required.
