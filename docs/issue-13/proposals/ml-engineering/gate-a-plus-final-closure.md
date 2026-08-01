# issue-13 — 게이트 A+ 최종 마감: 재감사 잔여 결함 보수 (proposal)

Phase 1 ONLY. No execution in this PR.

## Context (배경)

The 2026-08-01 re-audit (issue-13 body) leaves exactly one common defect
open across this rulebook's gates — the source guard — with the other
4/4 previously-flagged items already confirmed fixed. Two prerequisites
are named as already landed: core issue-75
(`tokenmaxxxer/tokenmaxxxer-core` commit `52bdc15`,
`deliver(implementation): gate-lib source guard + gate_bash_write_targets
py parity (issue-75) (#77)`) and on-the-record issue-182
(`CLAUDE_PLUGIN_ROOT_CORE` injection). The current-state survey
(`docs/issue-13/reports/ml-engineering/current-state-survey.md`) pulled
core fresh from GitHub (not from any locally cached copy, which was
stale) and confirmed:

1. All 5 of this rulebook's `methodology-gate.sh` files still source
   `gate-lib.sh` unguarded — the exact pre-issue-75 defect core's own
   transition note calls out as needing a re-pull
   (survey §1; core `docs/handbooks/gate-house-standard.md` at `52bdc15`).
2. Matcher (`hooks.json` `PreToolUse` → `Write|Edit|MultiEdit`) and code
   (`tool in ("Write", "Edit", "MultiEdit")`) already agree across all 5
   gates; no `Bash`/`gate_bash_write_targets` claim exists anywhere in
   this repo, so no drift to close on that axis (survey §2).
3. None of the 5 gates' test files carries core's new 7th mandatory case
   (missing-core → deny); the full-suite-green + compliance-check-clean
   record the issue asks for cannot exist until that case is added and
   passing (survey §3).
4. README/manifest sweep for stale role names and ghost files: zero
   instances found (survey §4) — this requirement is already satisfied
   and needs no phase-2 change, only recording as verified in the
   phase-2 record.

Source: `tokenmaxxxer/tokenmaxxxer-core` `52bdc15` (core/hooks/lib/gate-
lib.sh usage comment; docs/handbooks/gate-house-standard.md, both parts
of the diff introducing the guarded form and the 7th test case) —
authoritative because it is the landed prerequisite this issue names.

## Decision (채택안)

Re-pull core's confirmed guard shape and 7th-case test pattern verbatim
into this rulebook's 5 gate plugins, mechanically, with no local
variation:

1. **Source guard.** In each of the 5 `hooks/methodology-gate.sh` files,
   change line 2 from the unguarded

   ```sh
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
   ```

   to the guarded form, substituting each gate's own plugin name for
   `<gate-name>`:

   ```sh
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
   ```

   No other line changes — issue-75's fix is additive per core's own
   transition note ("no public function's existing behavior changed"),
   so this is a drop-in source-line swap, not a rewrite of the 5 gates'
   own judging logic.

2. **matcher/code parity.** No change — survey §2 found no drift. Record
   this as a verified-pass in the phase-2 record rather than inventing a
   fix for a gap that does not exist.

3. **missing-core test case.** Add a 6th case to each of the 5
   `tests/*-gate.sh` files, mirroring core's case 7 shape: source the
   gate with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and
   no valid relative core checkout at `../../core`, and assert the gate
   process exits 2 (deny) rather than 0 (silent allow) or an unguarded
   127. Run each rulebook's full test suite plus
   `compliance-check.sh <plugin>/hooks` (core, invoked the same way
   `stub-check.sh` is per `docs/handbooks/gate-house-standard.md`) and
   record both as green/clean in the phase-2 record — this satisfies
   requirement 3's "missing-core 케이스 포함 전 스위트 배송 상태 green +
   compliance-check 통과 record 기록" literally.

4. **README/manifest sweep.** No content change — survey §4 found zero
   stale names / ghost files. Phase 2 records the sweep result (what was
   checked, zero found) rather than silently doing nothing; a
   requirement stated as "옛 이름은 하드 에러" needs a recorded check
   even when the check comes back clean, so the closure record shows the
   requirement was verified, not skipped.

## Rationale (근거)

**Why re-pull verbatim instead of re-deriving a guard independently:**
core #75 already went through its own phase-1/phase-2 cycle (issues
`#76`/`#77`) and is the named prerequisite this issue explicitly defers
to ("공통 항목은 core #75의 확정 가드/규칙을 참조 적용"). Re-deriving a
different-but-equivalent guard expression would risk exactly the kind of
per-rulebook drift `docs/handbooks/gate-house-standard.md`'s canon-vendor
ban exists to prevent (`stub-check.sh` enforcement, cited in this repo's
own README) — the whole point of sourcing `gate-lib.sh` by reference is
one canonical implementation, and the same discipline applies to the
*call-site* wrapper text, not only the library body.

**Rejected alternative:** writing this rulebook's own local `||`-guard
wrapper function (e.g. a repo-local `source_gate_lib_or_deny` helper)
instead of inlining core's exact guarded line at each of the 5 call
sites. Rejected because core's usage comment is the single normative
text every rulebook is expected to copy verbatim (`docs/handbooks/gate-
house-standard.md`'s "Usage, from a gate script" block is written as a
literal copy-paste target, not a template to wrap); a local helper adds
an indirection layer with no behavior difference and makes future
re-pulls of core's guard changes a diff against a wrapper instead of a
diff against the canonical line, working against the very re-pull
mechanism issue-75's transition note assumes.

**Rejected alternative:** treating README/manifest (item 4) as already
closed and omitting any phase-2 record entry for it, since no file
changes. Rejected because the issue names it as one of four requirements
to "수정" and item 4's own wording treats absence-of-defect as something
to certify ("잔재 0"), not something to leave unstated; a phase-2 record
that is silent on a requirement reads as unaddressed even when the
underlying state was already clean.

## Consequences (결과)

Phase 2 (opens only on `APPROVE issue-13/ml-engineering` or an
approvers.md reviewer's PR-review Approve, contract v3 §19) will, on this
same branch:

- Apply the guarded source line to all 5 `hooks/methodology-gate.sh`
  files.
- Add the missing-core deny test case to all 5 `tests/*-gate.sh` files
  and run each rulebook's suite to green.
- Run `compliance-check.sh` against each of the 5 gate plugins' `hooks/`
  directories and confirm clean (no unguarded-source, no hand-rolled
  kill-switch, no non-`gate_reconstruct_write` reconstruction findings).
- Write `docs/issue-13/reports/ml-engineering.md` recording: the guard
  fix applied per-file, the new test case's pass status per plugin, the
  compliance-check output (clean), and the README/manifest sweep result
  (zero stale names/ghost files, unchanged).
- No change to any gate's judging semantics (ADR-shape checks, ML Test
  Score section checks, model-card field checks, SLO-serving section
  checks, eval-discipline section checks) — this issue is infrastructure
  parity with core canon, not a methodology-rule change, so none of the
  5 gates' own pass/fail criteria for a role's document move.
