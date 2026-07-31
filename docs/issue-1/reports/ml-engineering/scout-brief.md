# Scout brief (issue-1, ml-engineering)

Mode: parallel WebSearch, 4 angles (serving-design, monitoring/drift, MLOps
maturity, ADR/design-doc format) → judge point 1 (all four are legit
textbook/industry-standard hits, high overlap on SLO/rollout + maturity-level
framing) → 1 deepening round (ML Test Score rubric) → judge point 2: dry,
stopped. Stages used: 2 of 5 budget.

## Category must-bes
- Serving design must state SLOs for both the *service* (latency/availability/
  throughput/cost) and the *model's predictive behavior* (accuracy, drift,
  calibration) — not service metrics alone.
- Rollout must be staged (canary/shadow/blue-green) with an explicit
  comparison window (e.g. ≥24h) against baseline before full promotion.
- Risk assessment must be a checklist/rubric, not prose: the field's
  strongest artifact (Google's ML Test Score) is 28 concrete, scoreable
  tests across data/model/infra/monitoring — not a free-form risk essay.
- MLOps maturity models (Google 3-level, Microsoft 5-level) converge on one
  axis: how much of validate→train→deploy→monitor→retrain is automated and
  reproducible — a serving design should say where on that axis it sits.
- ADR format (Nygard/adr.github.io) converges on: Title, Status, Context,
  Decision, Consequences — short, one-decision-per-doc, evidence embedded in
  Context.

## Performance axes strong exemplars compete on
1. Falsifiability of the risk note (scoreable checklist vs. vague prose).
2. Explicit rollout staging with a stated comparison window.
3. Dual-axis SLOs (service perf + model behavior), not just latency.

## Adopt / skip
- **Adopt**: ML Test Score-style checklist as the risk-note skeleton;
  dual-axis SLO requirement for serving design; ADR shape (context/decision/
  consequences) for the phase-1 proposal itself.
- **Skip**: full MLOps maturity-level self-assessment as a mandatory
  section — this role's `WRITE_SCOPE: []` (report-only, no pipeline code)
  makes a full lifecycle-automation audit out of scope; borrow only the
  "where does automation/reproducibility stand" question as one risk-note
  line, not a whole maturity rubric.

## Segment fit
This role is report-only (serving design + risk note), not a full MLOps
build-out — so the adopted methodology is checklist-and-SLO-driven
documentation, not process/tooling maturity assessment.

## Gap line
Current directive (`PRODUCES`) already names the two required content
classes (serving design, risk note) but specifies no internal method for
either and no phase-1 evidence-format norm. All three gaps identified in the
current-state survey are filled by this scout: serving-design method (SLO +
staged rollout), risk-note method (scoreable checklist), proposal evidence
format (ADR shape). Plugin-mechanics gap (RECORD_FIELDS_TERMINAL_STATES,
WRITE_SCOPE) needed no external search — resolved from repo read alone.

Sources:
- https://mlflow.org/articles/managing-ai-model-serving-latency-a-developers-guide/
- https://oneuptime.com/blog/post/2026-01-30-mlops-canary-model-deployment/view
- https://galileo.ai/blog/ml-model-monitoring
- https://www.bentoml.com/blog/a-guide-to-ml-monitoring-and-drift-detection
- https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/mlops-maturity-model
- https://www.zenml.io/blog/everything-you-ever-wanted-to-know-about-mlops-maturity-models
- https://adr.github.io/
- https://github.com/architecture-decision-record/architecture-decision-record
- https://research.google.com/pubs/archive/45742.pdf (Breck et al., "The ML Test Score")
