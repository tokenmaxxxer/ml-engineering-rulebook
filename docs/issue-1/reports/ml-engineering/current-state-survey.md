# Current-state survey (issue-1, ml-engineering)

## Write surfaces in scope
- `ml-engineering/hooks/directive.sh` — SessionStart directive: `YOU_DECIDE` /
  `USE_WHEN` / `PRODUCES` (record fields + WRITE_SCOPE) / `HAND_OFF`, fed to
  `core_role_directive` (canon, referenced not copied — see issue-2 proposal).
- record-fields gate (canon, globally registered by `core`) — enforces which
  fields must appear in `docs/issue-<n>/reports/ml-engineering.md`; this repo has
  no local override of required fields beyond what `directive.sh`'s `PRODUCES`
  line declares.
- No existing phase-1 proposal norm anywhere in this repo. `docs/issue-2/proposals/core-canon-reference-conversion.md`
  is the only precedent PR-side proposal doc, but its subject (mechanical canon
  reference conversion) has no methodology/evidence content to model — it is
  process-shaped, not domain-shaped, so it sets a *document shape* precedent only
  (헤더, "Phase 1 제안만" 스코프 고지, 항목별 절 구성) not a methodology precedent.

## What's already fixed (cannot be redesigned in phase 1)
- `YOU_DECIDE`: "모델을 서비스로 안정적으로 서빙 가능한가"
- `USE_WHEN`: "모델 서빙 표면이 걸릴 때"
- `PRODUCES`: "serving design, risk note (drift/latency/failure mode)"
- `WRITE_SCOPE: []` — report-only role, no code/doc write outside the record.
- `HAND_OFF`: 학습 데이터 파이프라인 → data-engineering.

These four lines are the actual product boundary this role's phase-2 record
must satisfy. They already name two required content classes — a serving
design and a risk note — but say nothing about *how* to arrive at either
(methodology) or what evidence a reviewer should expect to see cited.

## Gaps / unknowns (what scout should aim at)
1. **Serving-design methodology** — no stated framework for "is this
   servable": no mention of load/latency SLOs, capacity planning, rollback/
   canary strategy, or serving-pattern taxonomy (batch vs online vs
   streaming). Scout angle: what do textbook/industry ML-serving frameworks
   require as a documented serving design?
2. **Risk-note methodology** — "drift/latency/failure mode" named but no
   structure for how these are assessed (checklist? severity scale? FMEA-style
   decomposition?). Scout angle: what structured risk-assessment methods are
   standard for ML serving specifically (model monitoring frameworks, MLOps
   maturity models)?
3. **Proposal (phase 1) evidence format** — contract v3 only says phase 1 is
   "research + proposal"; nothing in this repo specifies what counts as
   sufficient evidence/citation format for adopting a methodology. No local
   precedent to borrow from.
4. **Plugin reflection mechanics** — `directive.sh`'s `PRODUCES` var and the
   canon `RECORD_FIELDS_TERMINAL_STATES` are the only two levers this repo
   currently uses to force record shape (per issue-2 proposal §4, this repo
   has not yet exercised a role-specific override of the latter). Scout does
   not need to search externally for this — it's a mechanical fact about this
   repo's own plugin wiring, already known from reading directive.sh/hooks.json.

## Skip record
N/A — scouting applies (this issue explicitly asks for a "폭넓게" domain
survey feeding a methodology choice; not a bugfix, not a fully-specified
spec).
