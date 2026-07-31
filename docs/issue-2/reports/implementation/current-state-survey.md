# issue-2 현재 상태 조사 — core canon 참조 전환

## 이 레포의 현재 write surface

```
ml-engineering/.claude-plugin/plugin.json
ml-engineering/agents/warrant-hunter.md   <- 역할 무관 복제본 (core canon과 골격 동일)
ml-engineering/hooks/hooks.json           <- SessionStart(directive) + PreToolUse(3게이트) 등록
ml-engineering/hooks/directive.sh         <- 공통 보일러플레이트 + 역할 고유부 혼재
ml-engineering/hooks/handbook-trigger-gate.sh  <- 플레이스홀더(exit 0 고정), 역할 무관
ml-engineering/hooks/record-fields-gate.sh     <- REQUIRED_FIELDS=["serving-design","risk-note"] 하드코딩, 역할 무관 로직
ml-engineering/hooks/trailer-gate.sh           <- 역할 무관 로직, ML_ENGINEERING_* 환경변수만 로컬
```

`docs/specs/approvers.md`는 비어 있음(플레이스홀더). `.claude-plugin/marketplace.json`은
`ml-engineering` 플러그인 하나만 `./ml-engineering`에서 소싱.

## core canon 쪽 실제 상태 (tokenmaxxxer/tokenmaxxxer-core, main)

core issue #63/#66은 GitHub상 **OPEN**으로 남아 있으나, 코드는 이미 `main`에 랜딩되어
있음 — 이슈 상태와 코드 상태가 불일치. 이 조사는 이슈 상태가 아니라 실제 트리 내용을
근거로 삼았다.

- `core/hooks/hooks.json` — `SessionStart: directive.sh`, `PreToolUse(.*): board-gate.sh,
  approval-gate.sh, gh-guard.sh, trailer-gate.sh, record-fields-gate.sh,
  handbook-trigger-gate.sh`. `core` 플러그인이 설치되면 이 3게이트는 **전역으로** 이미
  발동한다 — 룰북이 자기 복사본을 갖고 있으면 이중 등록.
- `core/hooks/lib/role-directive.sh` — `core_role_directive <you_decide> <use_when>
  <produces> <hand_off>` 함수. `CLAUDE_ROLE` 없으면 no-op, kill switch는
  `<ROLE_UPPER>_CYCLE_OFF`. 4개 인자만 받고 `RECORD:` 줄은 함수가 직접 생성한다.
- `core/hooks/record-fields-gate.sh` — REQUIRED 필드가 §20 고정 집합(what-was-done/why/
  upstream-basis/loop_state/open-findings)으로 이미 일반화되어 있고, 룰북별
  `serving-design`/`risk-note` 같은 role-specific 필드 하드코딩은 **canon에 없다**
  (canon은 계약 §20의 공통 필드만 검사; produces 필드 자체는 검사하지 않음 — 이 레포
  현재의 record-fields-gate.sh가 검사하는 `serving-design`/`risk-note`는 canon으로
  승격되지 않은, 이 룰북만의 더 엄격한 요구였다는 뜻). 종료 상태 집합만
  `RECORD_FIELDS_TERMINAL_STATES`(공백 구분, 기본값 `landed`)로 주입 가능.
- `core/hooks/handbook-trigger-gate.sh` — 플레이스홀더가 아니라 실제 판정 로직(의존성
  매니페스트/Dockerfile/.env/migrations/CI workflow/run-script 스테이징 감지 +
  `docs/handbooks/` 동반 여부 확인)이 이미 구현되어 있음. 이 레포의 로컬 복사본은 항상
  `exit 0`(TODO 플레이스홀더)이었으므로, canon 참조 전환은 기능적으로 **강화**다.
- `core/hooks/trailer-gate.sh` — `Subject: issue-<n>` 트레일러 검사, `CLAUDE_ROLE`에서
  role 이름을 읽음. 이 레포의 로컬 복사본과 판정 로직은 동일(§13 계약과 부합).
- `core/hooks/tests/stub-check.sh` — 드리프트 재발 탐지기(issue-66 item 4).
  `hooks/` 트리 안에 `trailer-gate.sh` / `record-fields-gate.sh` /
  `handbook-trigger-gate.sh` / `parse-check.sh` 파일명이 남아 있으면 FAIL.
  `directive.sh`는 존재 자체는 허용하되 **구조적으로** 검사한다: 매 줄이 (a) 빈줄/주석/
  shebang, (b) `role-directive.sh`를 언급하는 줄, (c) `core_role_directive`를 언급하는
  줄, (d) 단순 변수대입(`VAR=...`, 한 줄) 중 하나가 아니면 FAIL — **여러 줄에 걸친 문자열
  리터럴(멀티라인 인자)은 이 정규식을 통과하지 못한다.** 스텁을 다시 쓸 때 이 제약이
  가장 좁은 병목이다(제안서 §3 참조).
- `warrant/` (core 리포 내 별도 플러그인, `tokenmaxxxer-core` 마켓플레이스에
  `warrant@tokenmaxxxer-core`로 등록됨) — `agents/warrant-hunter.md`는 역할 토큰이 전혀
  없는 완전 역할-무관 에이전트(스탠스는 디스패처가 프롬프트로 주입하는 구조이지 파일
  안에 역할별 스탠스 목록이 있는 게 아님). `hooks/{state.sh,hunt-state.sh,scope-gate.sh,
  hunt-guard.sh,directive.sh}`도 함께 온다. **이 파일들 중 어느 것도 이 레포의
  role-specific 문구(`모델을 서비스로 안정적으로 서빙 가능한가`, 학습 데이터 파이프라인
  hand-off)를 담을 자리가 없다** — canon warrant-hunter는 스탠스/경계를 역할별로
  파라미터화하지 않는다.

## 선행 사례 확인 (다른 룰북이 이미 전환했는가)

`implementation-rulebook`(core issue #63 본문에 "adapted from implementation-rulebook's
agents/warrant-hunter.md"라고 인용된 원본)의 `main`을 직접 확인함:
**아직 전환되지 않음** — `coding/hooks/`에 `trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh`, `hunt-guard.sh`, `hunt-state.sh`, `state.sh` 로컬 복사본이
모두 그대로 있고, `directive.sh`도 스텁 형태가 아님. 즉 **이 전환의 실제 사례가 아직
어느 룰북에도 없다** — 이 이슈(#2)가 사실상 첫 적용이 된다. 다른 룰북의 검증된 패턴을
베낄 수 없고, canon 파일 자체의 헤더 주석(설계 의도)에서 직접 도출해야 했다.

## 열린 질문 (제안서로 넘김)

1. `warrant` 플러그인 설치 경로 — `on-the-record`가 역할별로 설치하는 것으로 보이나
   (core README: "on-the-record enables them per role"), 이 레포 자체의
   marketplace.json/README가 `core`·`warrant` 의존을 문서화해야 하는지는 core의
   README 패턴(마켓플레이스 add + 개별 plugin install 커맨드 나열)을 준용해 제안서에서
   제안한다.
2. 이 역할의 role-specific hunt 경계(스탠스/hand-off 문구)가 canon에 자리가 없다는 점은
   기능 손실이 아니라 canon의 설계 범위 밖 — 이슈 본문에도 이를 보존하라는 항목이 없어
   드롭하는 쪽으로 제안한다(제안서 §1).
