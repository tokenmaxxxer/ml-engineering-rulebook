# 기록 — issue-2 core canon 참조 전환 (phase 2)

승인된 `docs/issue-2/proposals/core-canon-reference-conversion.md`대로 한 배치 실행.

## what was done

1. `ml-engineering/agents/warrant-hunter.md` 삭제 (canon `warrant@tokenmaxxxer-core`로 대체).
2. `ml-engineering/hooks/trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh` 삭제, `hooks.json`의 `PreToolUse` 블록 전체 제거
   (`SessionStart`만 유지) — 이 3게이트는 `core` 플러그인 설치 시 전역 등록되어
   기능 손실 없음(`handbook-trigger-gate`는 기존 로컬 복사본이 `exit 0`
   플레이스홀더였던 반면 canon은 실판정 로직을 갖고 있어 오히려 강화).
3. `ml-engineering/hooks/directive.sh`를 스텁 형식으로 교체 —
   `core/hooks/lib/role-directive.sh`를 source하고 `core_role_directive`를
   호출하며, 역할 고유 4값(`YOU_DECIDE`/`USE_WHEN`/`PRODUCES`/`HAND_OFF`)만
   `$'...'` ANSI-C 인용으로 보존. 기존 `RECORD: docs/issue-<n>/reports/ml-engineering.md...`
   줄은 `core_role_directive`가 자체 생성하므로 제거.
4. `README.md` install 절을 core README 패턴대로 갱신
   (`tokenmaxxxer-core` 마켓플레이스 + `core`/`warrant` 설치 선행 명시), Layout
   절에서 삭제된 파일 항목 제거.

## why

core issue #63/#66 canon이 이미 `tokenmaxxxer/tokenmaxxxer-core`의 `main`에
랜딩되어 있고(GitHub 이슈 상태는 여전히 OPEN이지만 코드 트리는 완료 —
phase-1 조사에서 직접 확인), 이 룰북이 자체 사본을 유지하면 이중 등록/드리프트
위험이 있다는 것이 issue-2 본문의 요청. rationale: 룰북 성숙화 phase 2보다
이 전환을 먼저 끝내야 한다는 순서 제약(이슈 본문)도 반영.

## upstream-basis

- `docs/issue-2/reports/implementation/current-state-survey.md` (phase 1) —
  core `main`을 직접 조회해 canon 파일 경로/시그니처 확인.
- `docs/issue-2/proposals/core-canon-reference-conversion.md` (phase 1, Approve됨).
- phase 2 실행 직전 재조회: `tokenmaxxxer/tokenmaxxxer-core`를 `main` 기준으로
  다시 clone해 `core/hooks/lib/role-directive.sh`(4-인자 함수, `RECORD:` 자체
  생성), `core/hooks/hooks.json`(3게이트 전역 등록), `core/hooks/tests/stub-check.sh`
  (구조 검사 정규식)이 제안서 가정과 변경 없이 일치함을 확인.

## RECORD_FIELDS_TERMINAL_STATES 결정

override하지 않음 — 이 역할의 loop_state 종료 집합이 canon 기본값(`landed`)과
다르다는 근거를 찾지 못해 canon 기본값을 그대로 채택. (제안서 §4 그대로.)

## stub-check.sh 통과 확인

`tokenmaxxxer/tokenmaxxxer-core`의 `core/hooks/tests/stub-check.sh`를 이
레포의 `ml-engineering/` 루트에 대해 실행:

```
$ bash core/hooks/tests/stub-check.sh ml-engineering
stub-check: ok — no vendored 'trailer-gate.sh' under ml-engineering
stub-check: ok — no vendored 'record-fields-gate.sh' under ml-engineering
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under ml-engineering
stub-check: ok — no vendored 'parse-check.sh' under ml-engineering
stub-check: ok — ml-engineering/hooks/directive.sh is a role-directive stub
```

전 항목 ok. 추가로 `directive.sh`를 `CLAUDE_ROLE=ml-engineering` 환경에서 직접
실행해 기존과 동일한 지시문 텍스트(YOU DECIDE/USE_WHEN/PRODUCES/WRITE_SCOPE/
HAND-OFF/BOUNDARY CASE)가 그대로 출력되고 `RECORD:` 줄이 canon 쪽에서 자동
생성됨을 확인.

## open findings

- 제안서 §1에서 지적한 대로, canon `warrant-hunter`는 역할별 hunt 경계(스탠스,
  hand-off 문구)를 파라미터화하지 않는다 — 이 역할 고유의 hunt 경계 문구는
  드롭됨(이슈 본문도 보존을 요구하지 않음). canon 쪽에 role별 힌트 주입 지점이
  생기면 재검토 필요.
- `docs/specs/approvers.md`는 여전히 플레이스홀더(비어 있음) — 이 이슈 범위 밖.

## loop_state

loop_state: landed
