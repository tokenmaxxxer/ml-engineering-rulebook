# 제안 — ml-engineering 룰북 phase 1/phase 2 규범 (issue-1)

Phase 1 제안만. 실행(플러그인 반영)은 phase 2(Approve 후)로 미룸.
근거: `docs/issue-1/reports/ml-engineering/current-state-survey.md`(현재 write
surface·고정값·갭) + `docs/issue-1/reports/ml-engineering/scout-brief.md`(광역
서베이 결과).

## (a) Phase 1 제안서 규범 — 방법론·필수 섹션·근거 형식

**방법론**: ADR(Architecture Decision Record) 형식을 이 룰북의 모든 phase-1
제안서에 적용한다. 근거: Nygard(2011) 이래 업계 표준으로 정착했고
(adr.github.io, UK GDS·Spotify 등 채택 사례), "하나의 결정 = 하나의 짧은
문서, Context에 근거를 내장" 구조가 이 역할의 phase-1 산출물(연구→제안)과
정확히 일치한다 — 제안서 자체가 "이 역할이 어떤 방법론을 채택하는가"라는
단일 아키텍처 결정이기 때문이다.

**필수 섹션** (ADR 4요소를 이 룰북 용어로 사상):
1. **배경/Context** — 조사한 도메인 근거 요약(현재-상태 조사 + 스카우트
   브리프 링크). 인용 없는 주장은 금지.
2. **채택안/Decision** — 이번 문서의 (b)(c)(d)에 해당.
3. **근거/Rationale** — 왜 이 방법론이 이 역할의 의도된 가치(`YOU_DECIDE`:
   "모델을 서비스로 안정적으로 서빙 가능한가")와 논리적으로 맞아떨어질 수밖에
   없는지. 대안을 하나 이상 명시하고 기각 이유를 남긴다.
4. **결과/Consequences** — 이 채택이 phase 2 산출물·게이트에 강제하는 구체적
   변화(§d로 연결).

**근거 형식**: 모든 도메인 사실 주장은 출처(논문/공식 문서/표준)를 인라인
링크로 단다. 출처 없는 문장은 "가정"으로 명시하거나 삭제한다(스카우트
디렉티브의 SOURCE LINKS 규칙을 제안서 자체에도 적용).

## (b) Phase 2 산출물 규범 — 방법론·필수 구성요소

`PRODUCES`가 이미 두 산출물을 지정: **serving design**, **risk note**.
이번 제안은 "어떻게 만드는가"만 채운다(무엇을 만드는지는 phase 1에서 바꿀 수
없는 고정값 — 현재-상태 조사 참조).

### serving design
**방법론**: SLO 기반 서빙 설계 + 단계적 롤아웃(canary/shadow).
근거: MLflow/OneUptime 등 업계 실무가 수렴하는 두 축 — (i) 서비스 SLO
(latency/availability/throughput/cost)와 (ii) 모델 행동 SLO(accuracy
drift/calibration/fairness)를 모두 요구하고, 승격 전 canary/shadow 트래픽을
baseline과 일정 기간(≥24h 권장, time-of-day 효과 포착) 비교하도록 요구한다.

**필수 구성요소**:
- 서빙 패턴(batch/online/streaming) 명시
- 서비스 SLO 표(latency/availability/throughput/cost 중 해당 항목)
- 모델 행동 SLO(무엇을 어떤 기준으로 추적하는지)
- 롤아웃 단계와 승격 조건(예: canary N% 트래픽 × 비교 윈도우 × 승격 기준)
- 롤백 조건과 절차

### risk note
**방법론**: 산문형 리스크 서술이 아니라 **스코어 가능한 체크리스트**.
근거: Google의 ML Test Score(Breck et al., 2017, IEEE Big Data)가 정량화
가능한 28개 테스트/모니터링 항목을 제시하며 실무 표준으로 널리 인용된다 —
스카우트 결과 "강한 리스크 노트는 산문이 아니라 체크리스트"라는 패턴이 가장
뚜렷한 성능축이었다(현재 `PRODUCES`가 요구하는 drift/latency/failure mode
세 항목과 직접 대응).

**필수 구성요소** (`PRODUCES`의 3항목을 체크리스트 3섹션으로 강제):
- **Drift 섹션**: 무엇을 기준 분포로 삼는지, 어떤 통계량/임계값으로 드리프트를
  판정하는지, 판정 시 조치.
- **Latency 섹션**: p50/p95/p99 목표치와 실측/예상치, 초과 시 조치.
- **Failure mode 섹션**: 식별된 실패 모드별로 (증상 → 탐지 신호 → 완화/롤백
  조치) 3열.
- 각 항목에 pass/fail 또는 점수를 매길 수 있어야 한다(산문 서술만으로는
  불충분 — 스코어 불가능한 리스크 노트는 이 규범 위반).

**명시적 스킵**: Google/Microsoft MLOps 성숙도 모델(전체 파이프라인
자동화·재현성 평가)은 채택하지 않는다. 근거: 이 역할은
`WRITE_SCOPE: []`(report-only, 파이프라인 코드 작성 없음)이라 전체 라이프사이클
성숙도 평가는 스코프 밖이다. 다만 "이 서빙 경로의 자동화/재현성 수준"이라는
질문 하나만 risk note의 failure mode 섹션에 한 줄로 남기는 것은 허용(강제하지
않음).

## (c) 각 채택의 논리적 근거 (요약)

- ADR 형식 채택 = phase 1의 산출물 자체가 "방법론을 정하는 단일 결정"이므로
  ADR의 단위(하나의 결정)와 이 역할의 phase-1 단위가 일치.
- SLO+롤아웃 방법론 채택 = `YOU_DECIDE`("서비스로 안정적으로 서빙 가능한가")가
  묻는 질문에 직접 답하는 유일한 두 축(서비스 성능, 모델 행동)이 업계 서빙
  실무에서 검증된 축이기 때문 — 다른 축(예: 비용 최적화만, 또는 정확도만)은
  `YOU_DECIDE`의 "안정적으로"라는 요구를 부분적으로만 충족.
- 체크리스트형 risk note 채택 = `PRODUCES`가 이미 "risk note"를 요구하지만
  형식을 정하지 않았고, 산문형은 검증(review) 불가능 — 체크리스트만이 phase-2
  게이트가 기계적으로 "필드가 채워졌는가"를 넘어 "필드가 스코어 가능한가"까지
  검사할 수 있게 한다.
- MLOps 성숙도 모델 스킵 = `WRITE_SCOPE: []` 고정값과 직접 충돌하는 유일한
  후보였으므로 배제.

## (d) 플러그인 반영 계획 (phase 2 실행 항목 — 지금 실행하지 않음)

1. **`ml-engineering/hooks/directive.sh` `PRODUCES` 갱신**: 현재
   `PRODUCES=$'PRODUCES (required record fields): serving design, risk
   note (drift/latency/failure mode)\nWRITE_SCOPE: ...'`을, 아래 방법론
   문구를 덧붙이는 형태로 교체:
   ```
   PRODUCES (required record fields):
     serving design (serving pattern, service SLO, model-behavior SLO,
       staged rollout + promotion/rollback criteria),
     risk note (drift/latency/failure-mode — each scored pass/fail,
       ML-Test-Score-style checklist, not prose)
   WRITE_SCOPE: [] (report-only role — no code/doc write outside the record itself)
   ```
   (실제 문구는 phase 2에서 `stub-check.sh` 구조 검사 규칙에 맞춰 `$'...'`
   단일 물리 라인으로 작성 — issue-2 제안서 §3의 인코딩 방식 준용.)
2. **record 필수 필드 게이트**: canon `record-fields` 게이트가 이 역할
   전용 필드 스키마를 인식하도록, `hooks.json`에 역할별 필드 목록(위 §b의
   구성요소 리스트)을 env 또는 canon이 지원하는 확장 지점으로 주입. canon
   쪽에 role별 필드 스키마 확장 지점이 있는지는 phase 2 실행 시점에
   `tokenmaxxxer-core`의 `main`을 재조회해 확인(issue-2 제안서가 이미 이
   패턴을 지적함 — canon 상태 변동 리스크 공유).
3. **게이트**: risk note의 세 섹션(drift/latency/failure mode) 중 하나라도
   비어 있거나 스코어(pass/fail 또는 수치)가 없으면 record-fields 게이트가
   FAIL하도록 스키마 정의. serving design에 롤아웃 승격 조건이 없으면 동일하게
   FAIL.
4. **`docs/issue-<n>/reports/ml-engineering.md` 템플릿**: phase 2에서 이
   레포에 템플릿 파일을 추가할지, directive.sh의 텍스트만으로 강제할지는
   phase 2 실행 시점에 canon의 record 강제 메커니즘을 확인한 뒤 결정(지금은
   결정하지 않음 — 이 문서는 방법론/구성요소만 확정).

## 순서 메모

`docs/issue-2/proposals/core-canon-reference-conversion.md`(별도 이슈, canon
참조 전환)가 이 룰북의 phase 2보다 먼저 랜딩되어야 한다는 순서 제약이 이미
issue-2 제안서에 기록되어 있음 — 이 제안의 phase 2 실행도 그 순서를 따른다.
