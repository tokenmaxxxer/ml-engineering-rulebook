# Scout brief — issue-2 core canon 참조 전환

**모드**: batched-sequential fallback (병렬 서브에이전트/병렬 툴콜 미사용 — 각 조회가
바로 앞 조회 결과에 의존해 순차 확인이 필요했음: core issue 상태 → core 트리 존재 →
개별 canon 파일 내용 → 선행사례 검색). 스테이지 수: 3 (core canon 조회, 선행사례 조회,
판단) — budget(5스테이지/3분) 이내.

**must-be (canon이 강제하는 것)**:
- `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`는 룰북에
  로컬 복사본이 있으면 `stub-check.sh`가 FAIL — 삭제가 선택이 아니라 필수.
- `directive.sh`는 존재해야 하되 `role-directive.sh` 소스 + `core_role_directive`
  호출 + 단순 변수대입 줄만 허용 — 멀티라인 문자열 인자를 그대로 두면 구조 검사에 걸림.
  Source: `core/hooks/tests/stub-check.sh` (tokenmaxxxer/tokenmaxxxer-core, main).

**성능/차별화 축**: 이 레포는 report-only 역할(write_scope: [])이라 `handbook-trigger-gate`
발동 대상 자체가 거의 없음(코드/의존성 파일을 안 씀) — canon 전환으로 얻는 실질 이득은
`record-fields-gate`/`trailer-gate`의 유지보수 단일화와, 현재 항상 `exit 0`인
`handbook-trigger-gate` 플레이스홀더가 canon의 실제 판정 로직으로 교체되는 것.

**adopt**: `$'...'` ANSI-C 인용으로 멀티라인 내용을 단일 물리 라인 변수대입에 담아
`core_role_directive` 인자로 넘기는 패턴 — stub-check.sh의 줄 단위 정규식을 통과하면서
`WRITE_SCOPE`/`BOUNDARY CASE` 같은 이 역할 고유 텍스트를 보존.
**skip**: canon `warrant-hunter.md`에 역할별 스탠스 텍스트를 끼워 넣는 것 — canon
설계 자체가 스탠스를 파일이 아니라 디스패치 시점 프롬프트로 주입하는 구조라 룰북
쪽에서 손댈 지점이 없음; 이슈 본문도 이를 요구하지 않음.

**세그먼트 적합성**: 이 레포는 이 전환의 첫 적용 사례(선행 룰북 미전환 확인, survey
참조) — 참고할 "잘된 예시"가 아직 없어 canon 파일 헤더 주석에서 설계 의도를 직접
역산했다.

**gap line**: 이 레포가 이미 충족: 없음(3게이트 모두 로컬 복사본으로 존재 자체는
충족하지만 정확히 그게 문제). 이 레포에 없는 것(canon이 채워야 할 것): 실제 동작하는
handbook-trigger 판정 로직, 단일 소스의 트레일러/레코드필드 게이트, 스텁 형태
directive.sh.

**Sources**:
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/tests/stub-check.sh
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/lib/role-directive.sh
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/record-fields-gate.sh
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/handbook-trigger-gate.sh
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/.claude-plugin/marketplace.json
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/README.md
- https://api.github.com/repos/tokenmaxxxer/implementation-rulebook/contents/coding/hooks (선행사례 미전환 확인)
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/issues/63, /66 (둘 다 OPEN이지만 코드는 main에 랜딩됨 — 상태 불일치를 제안서에 기록)
