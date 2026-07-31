# 기록 — issue-1 룰북 성숙화 (phase 2)

승인된 `docs/issue-1/proposals/ml-engineering-norms.md`대로 플러그인 반영 실행
(`APPROVE issue-1/ml-engineering`, 이슈 코멘트).

## what was done

1. `ml-engineering/hooks/directive.sh`의 `PRODUCES`를 제안서 §(d).1 문구로
   교체 — serving design/risk note 각각의 필수 구성요소를 명문화(serving
   pattern, service SLO, model-behavior SLO, staged rollout +
   promotion/rollback criteria / drift·latency·failure-mode 각 pass/fail
   스코어, ML-Test-Score 스타일 체크리스트). `$'...'` ANSI-C 인용 단일
   물리 라인 형식은 issue-2 phase-2가 세운 `core_role_directive`
   stub-check 통과 형식을 그대로 유지.
2. `docs/specs/record-norms.md` 신설 — phase-1 제안서 규범(ADR 4요소)과
   phase-2 산출물 규범(serving design/risk note 필수 구성요소)을 명문화.
3. `README.md`의 `produces` 불릿과 Layout 절을 갱신해 새 규범 문서를 가리키게 함.
4. record 필수 필드 게이트: **적용하지 않음** — 아래 "canon 재조회 결과" 참조.
5. `docs/issue-1/reports/ml-engineering.md`(본 파일) 신설 — phase-2 산출물
   자체가 이 역할의 record.

## why

제안서(Approve됨)가 이 역할의 phase-1 제안서/phase-2 산출물이 감이 아니라
도메인 조사(ADR 선례, MLflow/OneUptime 서빙 실무, Google ML Test Score)에
근거한 방법론을 따르도록 요구했고, 그 요구를 이 역할의 유일한 강제 지점인
`directive.sh`의 `PRODUCES`(record 필수 필드 선언)에 반영하는 것이 phase 2의
범위.

## upstream-basis

- `docs/issue-1/proposals/ml-engineering-norms.md` (phase 1, Approve됨).
- `docs/issue-1/reports/ml-engineering/current-state-survey.md`,
  `docs/issue-1/reports/ml-engineering/scout-brief.md` (phase 1 근거).
- phase 2 실행 시점 재조회: `gh api repos/tokenmaxxxer/tokenmaxxxer-core/contents/core/hooks/record-fields-gate.sh`
  로 canon `record-fields-gate.sh`(issue-66에서 canon 승격)의 현재 `main`
  내용을 직접 읽음.
- `docs/issue-2/proposals/core-canon-reference-conversion.md`,
  `docs/issue-2/reports/implementation.md` (canon 참조 전환 phase-2 선례 —
  이 phase-2가 먼저 랜딩되어야 한다는 순서 제약을 그대로 따름, 이미 이
  브랜치 기준 main에 랜딩된 상태로 확인).

## canon 재조회 결과 — record 필드 게이트 확장 지점 없음

제안서 §(d).2가 "canon `record-fields` 게이트가 이 역할 전용 필드 스키마를
인식하도록, `hooks.json`에 역할별 필드 목록을 env 또는 canon이 지원하는
확장 지점으로 주입"하기로 하되 그 확장 지점의 존재 여부를 phase 2 실행
시점에 확인하기로 유보했었다. `core/hooks/record-fields-gate.sh`의 현재
`main` 내용을 직접 읽은 결과: 이 게이트는 contract §20의 범용 구조
(what-was-done / why / upstream-basis / loop_state / open-findings)만
텍스트 존재 여부로 검사하며, `RECORD_FIELDS_TERMINAL_STATES`(loop_state
종료 집합) 외에는 어떤 역할별 필드-스키마 주입 지점도 없다(env var나
다른 확장 훅 없음). 따라서:

- 제안서 §(d).2/§(d).3(risk note 3섹션 중 하나라도 비거나 스코어가 없으면
  FAIL, serving design에 롤아웃 승격 조건 없으면 FAIL)을 **기계적 게이트로
  구현하지 않는다** — canon이 지원하지 않는 기능을 로컬에 새로 벤더링하는
  것은 issue-2 phase-2가 확립한 "canon 참조, 로컬 사본 금지" 원칙과
  정면충돌한다.
- 대신 그 구성요소 요구를 `docs/specs/record-norms.md`(신설, 명문 규범)와
  `directive.sh`의 `PRODUCES` 텍스트(세션마다 노출)로 강제한다 — 사람
  리뷰어가 PR 리뷰 시점에 이 규범 문서를 기준으로 record를 판정.
- **열린 리스크**: canon 쪽에 role별 필드-스키마 확장 지점이 추가되면
  (`RECORD_FIELDS_TERMINAL_STATES`와 유사한 패턴으로) 이 결정을 재검토하고
  기계적 게이트로 승격할 것.

## `docs/issue-<n>/reports/ml-engineering.md` 템플릿 결정

제안서 §(d).4도 유보되어 있었다. 위와 동일한 이유(canon record-fields-gate가
필드-존재만 검사하고 필드 구조는 검사하지 않음)로, 별도 템플릿 파일을
레포에 추가하지 않는다 — `docs/specs/record-norms.md`가 이미 그 구조를
명문화하며, 템플릿 파일을 별도로 두면 두 문서가 드리프트할 위험만 늘어난다.

## open findings

- record-fields 게이트의 역할별 필드-스키마 확장 지점 부재는 canon 쪽
  개선 여지(이 레포의 스코프 밖) — 위 "canon 재조회 결과" 절에 기록.
- `docs/specs/record-norms.md`의 강제는 현재 순수 리뷰어 규율에 의존한다
  (기계적 게이트 없음). 향후 canon이 확장 지점을 제공하면 이 리스크는
  해소됨.

## loop_state

loop_state: landed
