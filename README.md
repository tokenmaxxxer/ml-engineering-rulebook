# ml-engineering-rulebook

Rulebook for the `ml-engineering` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 모델을 서비스로 안정적으로 서빙 가능한가
- **use_when**: 모델 서빙 표면이 걸릴 때
- **produces**: serving design (serving pattern, service SLO, model-behavior SLO,
  staged rollout + promotion/rollback criteria), risk note (drift/latency/failure-mode,
  each scored pass/fail — see `docs/specs/record-norms.md`)
- **write_scope**: []
- **hand-off**: 학습 데이터 파이프라인이면 → data-engineering

## Install

Requires `tokenmaxxxer-core` (contract v3 protocol machinery, including
`core/hooks/lib/gate-lib.sh` — the gate-house standard library the five
methodology-gate plugins below source by reference) and `warrant`
(rotating-stance hunt agent), both from the `tokenmaxxxer-core`
marketplace, plus all six plugins from this repo's own marketplace (one
role plugin, five methodology gates — installing only `ml-engineering`
leaves the gates that actually enforce methodology not running):

```
claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
claude plugin install core@tokenmaxxxer-core
claude plugin install warrant@tokenmaxxxer-core
claude plugin marketplace add tokenmaxxxer/ml-engineering-rulebook
claude plugin install ml-engineering
claude plugin install ml-engineering-adr-proposal
claude plugin install ml-engineering-eval-discipline
claude plugin install ml-engineering-ml-test-score
claude plugin install ml-engineering-model-provenance
claude plugin install ml-engineering-slo-serving
```

## Layout

- `ml-engineering/.claude-plugin/plugin.json` — plugin manifest
- `ml-engineering/hooks/hooks.json` — SessionStart wiring (directive.sh only;
  the role-agnostic gates — trailer/record-fields/handbook-trigger — are
  registered globally by `core`, not vendored here)
- `ml-engineering/hooks/directive.sh` — SessionStart role directive, a stub
  over `core/hooks/lib/role-directive.sh`'s shared boilerplate
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)
- `docs/specs/record-norms.md` — phase-1 proposal norm (ADR shape) and
  phase-2 output norm (serving design / risk note required components),
  per issue-1

The rotating-stance hunt agent (formerly `ml-engineering/agents/warrant-hunter.md`)
is now `warrant@tokenmaxxxer-core` — install it alongside `core` above.

## Plugins

All six plugins from `.claude-plugin/marketplace.json`. The five
methodology-gate plugins are `PreToolUse` gates on `Write`/`Edit`/
`MultiEdit`, each with its own `hooks/methodology-gate.sh` and
`tests/*.sh`; all five source `core/hooks/lib/gate-lib.sh` /
`gate-lib.py` by reference (never vendored — see `stub-check.sh`'s
enforcement, docs/handbooks/gate-house-standard.md) for the fail-closed
trap, kill switch, JSON parsing, path normalization, and Write/Edit/
MultiEdit reconstruction, and add their own local section/adjacency-aware
semantic checks on top.

| Plugin | Enforces | Kill switch |
|---|---|---|
| `ml-engineering` | SessionStart role directive (not a gate) | n/a |
| `ml-engineering-adr-proposal` | phase-1 ADR shape (Context/Decision/Rationale/Consequences headings), a named source scoped to Context/Rationale, an explicit rejected-alternative statement scoped to Rationale/Consequences | `ML_ENGINEERING_ADR_PROPOSAL_GATE_OFF` |
| `ml-engineering-eval-discipline` | distinct offline + online evaluation subsections, each with a supporting term inside its own heading span | `ML_ENGINEERING_EVAL_DISCIPLINE_GATE_OFF` |
| `ml-engineering-ml-test-score` | four ML Test Score rubric sections (Breck et al. 2017), each scored with a word-boundary-matched verdict marker inside its own section | `ML_ENGINEERING_ML_TEST_SCORE_GATE_OFF` |
| `ml-engineering-model-provenance` | model-card fields (Mitchell et al. 2019) each anchored to its own heading, plus data/model version identifiers | `ML_ENGINEERING_MODEL_PROVENANCE_GATE_OFF` |
| `ml-engineering-slo-serving` | serving pattern, service SLO, model-behavior SLO, staged rollout, rollback conditions, each under its own heading | `ML_ENGINEERING_SLO_SERVING_GATE_OFF` |

Any value other than a recognized on-spelling (`1`/`true`/`yes`/`on`,
case-insensitive) leaves a gate active — an unrecognized/garbage value
never silently disables it (`gate_kill_switch_active`,
docs/handbooks/gate-house-standard.md).

This is scaffolding, not a finished rulebook: fill in doctrine detail and
handoff enforcement beyond what the five methodology gates above already
check before treating it as load-bearing.
