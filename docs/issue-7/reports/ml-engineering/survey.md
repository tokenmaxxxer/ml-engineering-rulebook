# Current-state survey (issue-7, ml-engineering)

## Write surfaces in scope
- `ml-engineering/hooks/directive.sh` — `SessionStart` directive built via
  canon `core_role_directive`. Current `PRODUCES` line already carries the
  issue-1 methodology content as prose (serving pattern/service SLO/
  model-behavior SLO/staged rollout; drift/latency/failure-mode scored
  checklist) — landed by issue-1 phase 2 (`ad9381f`). This is a one-line
  directive string, not an enforcement mechanism: nothing currently checks
  that a phase-1 proposal or the phase-2 record actually contains these
  elements.
- `ml-engineering/hooks/hooks.json` — only a `SessionStart` entry
  (`directive.sh`). No `PreToolUse` block exists in this plugin. Per the
  issue-2 canon-reference conversion (`cca999a`, already merged), the three
  generic canon gates (`trailer-gate`, `record-fields-gate`,
  `handbook-trigger-gate`) are registered globally by the `core` plugin, not
  locally — this repo carries no local `PreToolUse` gate of its own, generic
  or role-specific.
- `docs/issue-1/proposals/ml-engineering-norms.md` — the adopted methodology
  (ADR-format phase-1 proposal norm in §a; serving-design/risk-note
  methodology in §b; rationale in §c; an unexecuted "plugin reflection plan"
  in §d). This is the norms document the issue asks to convert from
  directive-text-only into a mechanical gate. §d already names the target
  shape (`PRODUCES` update — done; record-fields schema extension — flagged
  as unresolved at issue-1 phase-2 time; a role-specific gate — not
  attempted).
- `docs/issue-1/reports/ml-engineering.md` — phase-2 record for issue-1 (this
  role's own record). Read for what "landed" looked like without a gate, to
  see whether the two required record sections (serving design, risk note)
  were actually present in checkable form or only as prose claims.
- No `docs/issue-7/` tree existed before this survey (created now).

## What's already fixed (cannot be redesigned in phase 1 of this issue)
- The adopted methodology itself (issue-1 §a-§c) — this issue is about
  **enforcing** it, not re-choosing it. Re-litigating method choice is out of
  scope; the issue's problem statement is explicitly "directive 한 줄로만
  남았다" (methodology survived only as a directive line + docs, no
  enforcement).
- `WRITE_SCOPE: []` (report-only role) — any gate/test/agent this issue adds
  lives under `ml-engineering/` (hooks) and `docs/` (proposals/reports),
  never adds a code-writing surface for this role.
- Canon scripts (`core/hooks/*.sh`, `core/hooks/lib/role-directive.sh`) are
  reference-only per `core canon-scripts.md` — the issue's own constraint
  and `docs/issue-2/proposals/core-canon-reference-conversion.md`'s already-
  landed decision. Any new gate must be a small role-owned file sitting on
  top of (never copying) canon, registered via this plugin's own
  `hooks.json`.
- `RECORD_FIELDS_TERMINAL_STATES` — issue-2 phase 2 explicitly declined to
  override this (kept canon default `landed`); issue-7 has no new evidence
  to reopen that.

## Gaps / unknowns (what scout should aim at)
1. **No local `PreToolUse` gate exists in this repo at all** — issue-2 phase
   2 removed the only three that existed (all generic canon copies) and
   registered nothing role-specific in their place. A methodology gate for
   this issue is a net-new file and a net-new `hooks.json` entry, not an
   edit to something pre-existing.
2. **Shape of a sibling role-specific methodology gate** — is there a
   precedent elsewhere in the `tokenmaxxxer` rulebook family for a role
   adding its own `PreToolUse` gate on top of canon's generic
   `record-fields-gate`, and what does its matcher/parse/fail-closed
   structure look like? (Issue text names `pricing-rulebook`'s
   `methodology-gate.sh` explicitly as the reference.)
3. **Order-tracking precedent** — issue text: "방법론상 순서 제약이 있으면
   상태 추적으로 강제." Does this role's methodology actually have an
   internal ordering constraint (survey → evidence → adoption, as the issue
   text's example) that isn't already covered by (a) the ADR document
   structure itself (Context precedes Decision precedes Consequences within
   one file) and (b) the existing phase-1/phase-2 Approve gate (contract
   v3 s19, already state-tracked at the role-handoff layer, not this role's
   to duplicate)? If no additional ordering constraint exists beyond what
   ADR-shape and the phase gate already enforce, state-tracking machinery is
   unneeded — cite a source pattern (e.g. `implementation-rulebook`'s
   `coding/hooks/state.sh`) for what state-tracking looks like when it *is*
   needed, to compare against.
4. **Gate test harness conventions** — where do sibling rulebooks put gate
   tests (`tests/` at repo root per the issue), and what does a pass/fail
   test pair look like for a `PreToolUse` gate that reads stdin JSON?

## Skip record
N/A — scouting applies. This issue asks for a concrete enforcement design
modeled on a named external precedent (`pricing-rulebook`'s
`methodology-gate.sh`) plus this role's own adopted-but-unenforced norms;
neither is a pure bugfix nor a fully-specified spec, so the scout directive's
sweep is not skipped.
