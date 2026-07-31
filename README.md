# ml-engineering-rulebook

Rulebook for the `ml-engineering` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 모델을 서비스로 안정적으로 서빙 가능한가
- **use_when**: 모델 서빙 표면이 걸릴 때
- **produces**: serving design, risk note (drift/latency/failure mode)
- **write_scope**: []
- **hand-off**: 학습 데이터 파이프라인이면 → data-engineering

## Install

Requires `tokenmaxxxer-core` (contract v3 protocol machinery) and
`warrant` (rotating-stance hunt agent), both from the `tokenmaxxxer-core`
marketplace:

```
claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
claude plugin install core@tokenmaxxxer-core
claude plugin install warrant@tokenmaxxxer-core
claude plugin marketplace add tokenmaxxxer/ml-engineering-rulebook
claude plugin install ml-engineering
```

## Layout

- `ml-engineering/.claude-plugin/plugin.json` — plugin manifest
- `ml-engineering/hooks/hooks.json` — SessionStart wiring (directive.sh only;
  the role-agnostic gates — trailer/record-fields/handbook-trigger — are
  registered globally by `core`, not vendored here)
- `ml-engineering/hooks/directive.sh` — SessionStart role directive, a stub
  over `core/hooks/lib/role-directive.sh`'s shared boilerplate
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The rotating-stance hunt agent (formerly `ml-engineering/agents/warrant-hunter.md`)
is now `warrant@tokenmaxxxer-core` — install it alongside `core` above.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
