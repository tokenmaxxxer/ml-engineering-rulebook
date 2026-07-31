#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: 모델을 서비스로 안정적으로 서빙 가능한가"
USE_WHEN="USE_WHEN: 모델 서빙 표면이 걸릴 때"
PRODUCES=$'PRODUCES (required record fields):\n  serving design (serving pattern, service SLO, model-behavior SLO, staged rollout + promotion/rollback criteria),\n  risk note (drift/latency/failure-mode — each scored pass/fail, ML-Test-Score-style checklist, not prose)\nWRITE_SCOPE: [] (report-only role — no code/doc write outside the record itself)'
HAND_OFF=$'HAND-OFF: 학습 데이터 파이프라인이면 → data-engineering\n\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above,\nstop and hand off per the arrow — do not silently absorb another role\'s\nscope. Record the hand-off point in this role\'s record before opening the\nnext role\'s session.'
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
