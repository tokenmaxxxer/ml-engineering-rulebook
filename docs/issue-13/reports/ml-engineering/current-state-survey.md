# issue-13 current-state survey — gate A+ final closure

Scope: the 2026-08-01 re-audit's residual-defect list for this rulebook
(issue text, verbatim): common-only (source guard), the other 4/4 fixes
already confirmed landed. Surveyed against the actually-landed state of
both prerequisites, pulled fresh (not from any stale local cache):
`tokenmaxxxer/tokenmaxxxer-core` at `52bdc15` (`deliver(implementation):
gate-lib source guard + gate_bash_write_targets py parity (issue-75)
(#77)`) and `tokenmaxxxer/on-the-record` #182 (not independently
re-verified here — this rulebook has no spawn.py of its own; the fix is
consumed transitively via `CLAUDE_PLUGIN_ROOT_CORE` already being present
in every gate's source line, confirmed below).

## 1. Source guard (the confirmed common defect)

Core canon's fixed shape (`core/hooks/lib/gate-lib.sh` usage comment,
`docs/handbooks/gate-house-standard.md`, both at `52bdc15`):

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

The `||` guard is mandatory: an unguarded source that fails when core is
unreachable defines no `gate_*` function, and the resulting shell
"command not found" (127) is read by every
`gate_kill_switch_active ... || { exit 0; }` call site as the kill switch
being off — silent allow, not deny.

Grep across this repo's 5 methodology-gate plugins
(`grep -n 'gate-lib.sh"' */hooks/methodology-gate.sh`) finds all 5 still
on the pre-issue-75 unguarded form:

```
ml-engineering-adr-proposal/hooks/methodology-gate.sh:2
ml-engineering-slo-serving/hooks/methodology-gate.sh:2
ml-engineering-model-provenance/hooks/methodology-gate.sh:2
ml-engineering-ml-test-score/hooks/methodology-gate.sh:2
ml-engineering-eval-discipline/hooks/methodology-gate.sh:2
```

each reading:

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

— no `|| { ... exit 2; }`. This is the exact defect class core #75 fixed
in its own 7 gates; this rulebook migrated to gate-lib.sh under issue-10
(`cd977f1`, before core #75 landed) and never re-pulled the guarded line,
so it inherited the pre-fix example verbatim — consistent with core's own
transition note ("every rulebook that already migrated per this handbook
before issue-75 should re-pull the guarded source line").

`compliance-check.sh` (core, `52bdc15`) now detects exactly this: "a gate
that sources `gate-lib.sh` with no `||` guard on the same line." Not yet
run against this repo's gates — deferred to phase 2 per requirement 3
below (WRITE_SCOPE is `[]`; running/recording compliance-check output is
phase-2 record work, not phase-1 proposal work).

## 2. matcher/code coverage parity (requirement 2)

Each of the 5 gates' `hooks/hooks.json` `PreToolUse` matcher is
`Write|Edit|MultiEdit`; each gate's Python payload checks
`tool in ("Write", "Edit", "MultiEdit")` (grepped across all 5
`methodology-gate.sh`). No gate calls `gate_bash_write_targets` and none
claims `Bash` coverage anywhere (README's per-plugin table, hooks.json).
Matcher and code already agree — no drift found on this axis. (Contrast
with core's own transition note calling out a *different* rulebook,
pr-communications, that *did* call the sh-only `gate_bash_write_targets`
from its Python payload pre-#75 and fail-closed on every Bash call; this
repo's gates never called that function at all, so the py-parity half of
issue-75 does not apply here.)

## 3. missing-core test case (requirement 3)

Core's `run-gate-lib-tests.sh` now mandates 7 case groups (previously 6);
the new case 7 is: "`gate-lib.sh` sourced with
`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and no valid
relative fallback — must assert **deny** (exit 2), not the pre-issue-75
silent-allow bug."

This rulebook's 5 test files
(`*/tests/*-gate.sh`, one per methodology-gate plugin) were grepped for
`missing-core`, `nonexistent`, and `CLAUDE_PLUGIN_ROOT_CORE`: none
contains a missing-core deny case today. Requirement 3's "missing-core
케이스 포함 전 스위트 배송 상태 green" is not yet met by any of the 5.

## 4. README / manifest stale-name and ghost-file sweep (requirement 4)

- `find . -iname '*warrant-hunter*'` (repo-wide, git-excluded): zero
  hits. The role's rotating-stance hunt agent was relocated to
  `warrant@tokenmaxxxer-core`; README's two mentions of the old path
  (`ml-engineering/agents/warrant-hunter.md`) are both in a "formerly …
  is now …" sentence documenting the move, not a live reference to a file
  that should exist — not a ghost-file defect under this reading.
- All 6 `.claude-plugin/plugin.json` manifests (`ml-engineering` +
  5 gate plugins) checked: `name` fields match their directory names,
  `description` fields use only current role/gate names, no reference to
  a superseded role name.
- README's plugin table, install-command list, and layout section all
  name the same 6 current plugin names; no stale plugin name found.
- Net: requirement 4 already holds at 0 stale-name / 0 ghost-file
  instances found. Recorded here as verified-clean, not left unstated,
  since the issue lists it as a requirement to close, not merely to
  check.

## Scope boundary

`WRITE_SCOPE: []` — this role's phase-2 output is report-only (the
methodology-gate *content* is core-canon infrastructure, not this role's
`PRODUCES`). The source-guard/test fixes below are nonetheless this
rulebook's own repo's files (5 `methodology-gate.sh`, 5 test files), not
core's — core #75 already fixed core's own canon; closing this issue
means re-pulling that fix into this rulebook's 5 already-migrated gates,
which is squarely this repo's own remediation work per
`docs/handbooks/gate-house-standard.md`'s "each rulebook's own A+
remediation issue does that work."

## Scout: skip condition

Skipped. Skip condition: the spec leaves no design decision open — core
#75 already fixed, tested, and canonized the exact guard shape and the
exact 7th test case this issue asks to apply; this rulebook's job is a
mechanical re-pull of an already-landed, already-reviewed upstream fix
into 5 call sites and 5 test files, not a fresh design choice a
scout sweep could inform.
