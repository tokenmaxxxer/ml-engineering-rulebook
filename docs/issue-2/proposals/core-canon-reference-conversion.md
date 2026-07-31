# 제안 — core canon 참조 전환 (issue-2)

Phase 1 제안만. 실행은 phase 2(Approve 후)로 미룸.

## 배경 요약

core `warrant`/`core/hooks/*` canon이 `tokenmaxxxer/tokenmaxxxer-core`의 `main`에
이미 랜딩되어 있음(core issue #63/#66은 GitHub 이슈 상태로는 여전히 OPEN이지만, 코드
트리는 완료 상태 — 현재-상태 조사 참조). 이 레포는 이 canon 전환을 아직 아무도
적용하지 않은 첫 사례.

## 항목별 계획

### 1) `agents/warrant-hunter.md` 제거 → canon 참조

- `ml-engineering/agents/warrant-hunter.md` 삭제.
- 이 레포의 marketplace/README에 `warrant@tokenmaxxxer-core` 설치가 전제라는 문구
  추가(core README의 install 패턴 준용):
  ```
  claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
  claude plugin install core@tokenmaxxxer-core
  claude plugin install warrant@tokenmaxxxer-core
  claude plugin marketplace add tokenmaxxxer/ml-engineering-rulebook
  claude plugin install ml-engineering
  ```
- 역할 고유 hunt 경계(스탠스 세트, "학습 데이터 파이프라인이면 → data-engineering"
  hand-off 문구)는 canon `warrant-hunter.md`에 파라미터화 지점이 없음 — canon은
  스탠스를 디스패치 시점 프롬프트로 주입하는 구조라 룰북 쪽에 남길 자리가 없다. 이슈
  본문도 이 보존을 요구하지 않으므로 **드롭**한다. (열린 리스크: canon 쪽에 role별
  hand-off 힌트를 얹을 자리가 생기면 재검토 — 이 제안은 phase 2 실행 시점의 canon
  상태를 기준으로 한 번 더 확인한다.)

### 2) 3게이트 복사본 + 훅 등록 제거

삭제 대상:
```
ml-engineering/hooks/trailer-gate.sh
ml-engineering/hooks/record-fields-gate.sh
ml-engineering/hooks/handbook-trigger-gate.sh
```
`ml-engineering/hooks/hooks.json`에서 `PreToolUse` 블록 전체 제거(이 3게이트만 등록되어
있었으므로 `PreToolUse` 키 자체가 사라짐). `SessionStart` 블록(`directive.sh`)은 유지.
결과 `hooks.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" }
        ]
      }
    ]
  }
}
```
`core` 플러그인 설치 시 `core/hooks/hooks.json`이 이 3게이트를 전역 등록하므로 기능
손실 없음 — 오히려 `handbook-trigger-gate`는 현재 로컬 복사본이 항상 `exit 0`
플레이스홀더였던 반면 canon은 실제 판정 로직이 있어 **강화**된다.

### 3) `directive.sh` 스텁화

`core/hooks/tests/stub-check.sh`의 구조 검사(줄 단위: source 언급/`core_role_directive`
언급/단순 변수대입 외의 줄은 FAIL)를 통과하려면 멀티라인 인자를 그대로 넘기면 안 됨.
`$'...'`(ANSI-C 인용, 단일 물리 라인 안에 `\n` 이스케이프)로 `WRITE_SCOPE`/
`BOUNDARY CASE` 같은 이 역할 고유 텍스트를 보존:

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: 모델을 서비스로 안정적으로 서빙 가능한가"
USE_WHEN="USE_WHEN: 모델 서빙 표면이 걸릴 때"
PRODUCES=$'PRODUCES (required record fields): serving design, risk note (drift/latency/failure mode)\nWRITE_SCOPE: [] (report-only role \xe2\x80\x94 no code/doc write outside the record itself)'
HAND_OFF=$'HAND-OFF: \xed\x95\x99\xec\x8a\xb5 \xeb\x8d\xb0\xec\x9d\xb4\xed\x84\xb0 \xed\x8c\x8c\xec\x9d\xb4\xed\x94\x84\xeb\x9d\xbc\xec\x9d\xb8\xec\x9d\xb4\xeb\xa9\xb4 \xe2\x86\x92 data-engineering\n\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above,\nstop and hand off per the arrow \xe2\x80\x94 do not silently absorb another role'"'"'s\nscope. Record the hand-off point in this role'"'"'s record before opening the\nnext role'"'"'s session.'
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
```
(실제 실행 시 UTF-8 리터럴을 그대로 써서 `\xNN` 이스케이프 없이 작성 — 여기선 안전한
표기를 위해 예시를 단순화했음. phase 2에서 실제 파일은 평문 한국어를 `$'...'` 안에
직접 담아 작성한다.) `core_role_directive`가 `RECORD:` 줄을 자체 생성하므로 기존
directive.sh의 `RECORD: docs/issue-<n>/reports/ml-engineering.md...` 줄은 중복 —
제거.

### 4) `RECORD_FIELDS_TERMINAL_STATES`

이 역할의 record loop_state 종료 집합이 canon 기본값(`landed`)과 다르다는 근거를
현재 스켈레톤 어디에서도 찾지 못함(§20 placeholder 상태). **명시적으로 override하지
않음** — canon 기본값을 그대로 채택한다는 결정을 이 문서에 기록해 "역할별 실차이
검토를 건너뛴 것"과 구분한다. phase 2 실행 중 실제 loop_state 사용 패턴이 드러나면
그때 `hooks.json`에 `env`로 `RECORD_FIELDS_TERMINAL_STATES` 주입을 추가한다.

### 5) stub-check.sh 통과 확인

phase 2에서 core 리포의 `core/hooks/tests/stub-check.sh`를 이 레포의 `ml-engineering/`
루트에 대해 실행하고 결과(각 항목 ok/FAIL)를 `docs/issue-2/reports/implementation.md`에
기록한다. 이 문서 자체는 계약상 phase-2 산출물이라 지금은 작성하지 않는다.

## 순서/리스크 메모

- core issue #63/#66이 GitHub상 OPEN인 채로 코드가 랜딩된 상태 불일치를 확인했다 —
  phase 2 실행 직전에 core `main`을 재조회해 이 제안이 가정한 canon 파일 경로/시그니처가
  바뀌지 않았는지 재확인한다(특히 `core_role_directive` 인자 개수, `stub-check.sh`의
  정규식).
- 이 전환은 이 레포의 "룰북 성숙화" phase 2보다 먼저 끝나야 한다는 순서 제약(이슈
  본문)을 감안해, 이 PR의 Approve를 그 이슈보다 먼저 받는 쪽을 권장한다(실행 순서
  자체는 인간의 머지 판단 영역이라 이 제안서는 강제하지 않는다).
