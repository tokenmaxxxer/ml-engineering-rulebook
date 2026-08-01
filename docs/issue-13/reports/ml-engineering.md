---
subject: issue-13
role: ml-engineering
loop_state: landed
---

# Record: gate A+ final closure — phase 2 implementation

## What was done

Implemented `docs/issue-13/proposals/ml-engineering/gate-a-plus-final-closure.md`
(Approved via issue comment `APPROVE issue-13/ml-engineering`) verbatim —
a mechanical re-pull of core issue-75's confirmed guard/test shape
(`tokenmaxxxer/tokenmaxxxer-core` `52bdc15`) into this rulebook's 5
already-migrated gates.

### 1. Source guard — applied to all 5 gates

Each `<plugin>/hooks/methodology-gate.sh` line 2 changed from the
unguarded source to core's guarded form (own plugin name substituted for
`<gate-name>`):

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

| plugin | gate-name used in error string |
|---|---|
| ml-engineering-adr-proposal | `adr-proposal-gate.sh` |
| ml-engineering-eval-discipline | `eval-discipline-gate.sh` |
| ml-engineering-model-provenance | `model-provenance-gate.sh` |
| ml-engineering-slo-serving | `slo-serving-gate.sh` |
| ml-engineering-ml-test-score | `ml-test-score-gate.sh` |

No other line in any of the 5 files changed — issue-75's fix is additive
per core's own transition note; none of the 5 gates' own judging
semantics moved.

### 2. matcher/code parity — verified, no change

Survey §2 found no drift (all 5 `hooks.json` matchers are
`Write|Edit|MultiEdit`; all 5 gates check
`tool in ("Write", "Edit", "MultiEdit")`; no `Bash`/
`gate_bash_write_targets` claim anywhere). Re-confirmed at phase-2 time
by the `compliance-check.sh` run below, which would also flag
matcher/code drift and did not.

### 3. missing-core test case

Added one case per test file, mirroring core's `run-gate-lib-tests.sh`
case-7 shape (`missing-core` group): `CLAUDE_PLUGIN_ROOT_CORE` pointed at
a nonexistent path, fired against `PASS_CONTENT` (otherwise-allowed
content), asserting the gate denies (exit 2) — proving the deny comes
from the guard, not from the content check.

### 4. README/manifest sweep

No content change — re-verified survey §4's zero finding (below).

## Why

Per the approved proposal: core #75 already fixed, tested, and canonized
the exact guard shape and exact 7th test case this issue asks to apply;
re-pulling verbatim (rather than re-deriving an equivalent guard) keeps
one canonical implementation and one canonical test pattern instead of
per-rulebook drift, matching this rulebook's own canon-vendor discipline
(`stub-check.sh`, cited in this repo's README).

## Gate tests: full suite green

Each of the five `ml-engineering-*/tests/*.sh` files run individually,
including the new `missing-core-denies-not-allows` case, all exiting 0:

```
ml-engineering-adr-proposal/tests/adr-proposal-gate.sh:        15 passed, 0 failed
ml-engineering-eval-discipline/tests/eval-discipline-gate.sh:  16 passed, 0 failed
ml-engineering-model-provenance/tests/model-provenance-gate.sh: 15 passed, 0 failed
ml-engineering-slo-serving/tests/slo-serving-gate.sh:          15 passed, 0 failed
ml-engineering-ml-test-score/tests/ml-test-score-gate.sh:      16 passed, 0 failed
```

77 cases total, 0 failures.

## Compliance-check.sh

`core/hooks/tests/compliance-check.sh` (`CLAUDE_PLUGIN_ROOT_CORE`
resolved to the installed `core` plugin), run against each of the five
gates' `hooks/` directories:

```
compliance-check: ok — ml-engineering-adr-proposal/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-eval-discipline/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-model-provenance/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-slo-serving/hooks/methodology-gate.sh
compliance-check: ok — ml-engineering-ml-test-score/hooks/methodology-gate.sh
```

All 5: exit 0, no FAIL reasons (no unguarded source, no hand-rolled
kill-switch, no non-`gate_reconstruct_write` reconstruction).

## README/manifest stale-name / ghost-file sweep

- `find . -iname '*warrant-hunter*'`: zero hits; README's two mentions of
  the old path sit inside a "formerly … now …" migration sentence, not a
  live reference.
- All 6 `.claude-plugin/plugin.json` manifests: `name` matches directory,
  `description` uses only current role/gate names.
- `marketplace.json`'s 6 plugin `source` paths (`./ml-engineering`,
  `./ml-engineering-adr-proposal`, `./ml-engineering-slo-serving`,
  `./ml-engineering-ml-test-score`, `./ml-engineering-model-provenance`,
  `./ml-engineering-eval-discipline`) all resolve to existing directories
  — no ghost file.
- README's plugin table, install list, and layout section name the same
  6 current plugins; no stale name.

Net: 0 stale role names, 0 ghost files — same conclusion as the phase-1
survey; certified here per issue requirement 4 rather than left
unstated.

## What did not work

N/A — the proposal's mechanical re-pull applied cleanly on the first
pass for all 5 gates and all 5 test files; no rework was needed.

## Open findings

None. All four issue requirements are closed: (1) source guard applied
to all 5 gates verbatim per core #75's canon shape; (2) matcher/code
parity re-verified with no drift; (3) missing-core case added to all 5
test files, full suite green (77/77), compliance-check clean on all 5;
(4) README/manifest sweep re-verified at 0 stale names / 0 ghost files.

## Scope note

`WRITE_SCOPE: []` for this role — the methodology-gate scripts and test
files are core-canon-pattern infrastructure this rulebook hosts in its
own repo, not this role's `PRODUCES` (ADR/serving/ML-Test-Score/
provenance/eval-discipline records). This record certifies the
infrastructure re-pull; it introduces no change to any of the 5 gates'
own judging semantics for those records.

## Serving design / risk note (record-norms.md §Phase 2)

This issue's deliverable is tooling (the 5 gates' source-guard/test
fixes), not an ML serving surface — sections below describe the gates'
own operational posture, unchanged from issue-10's record since this
closure is infrastructure parity, not a redesign.

### Serving pattern
Online serving: each gate is a synchronous, single pass/deny verdict per
`PreToolUse` invocation.

### Service SLO
Latency: sub-second per gate (77 test cases, full suite under 3s
wall-clock, this run). Availability: `gate_trap_fail_closed` (from
gate-lib, sourced unconditionally once the guard succeeds) remaps any
crash to deny; the new guard itself now also converts a missing-core
condition from silent-allow to deny (exit 2) — the exact availability
gap this closure fixes.

### Model-behavior SLO
Not applicable in the trained-model sense (no model runs behind this
gate); the closest analogue is a drift threshold on the gate's own
allow/deny verdict — pinned by the fixed pass/fail expectations in every
`ml-engineering-*/tests/*.sh` file (77 cases, 0 unexpected drift from
expected verdicts this run).

### Rollout
Lands in this PR behind the existing phase-2 Approve gate; the
currently-installed plugin copy only picks up the guard on its next
reinstall — a natural canary boundary, not a scripted percentage
promotion.

### Rollback conditions
Revert this PR's merge commit; the prior (unguarded) gate scripts remain
byte-identical one commit back in git history — plain `git revert`, no
data migration.

## Offline evaluation

Pre-merge verification was entirely offline: the 77 test cases in "Gate
tests: full suite green" above are a metric (pass/fail count per gate)
run against a fixed, version-controlled fixture set (`PASS_CONTENT`/
`FAIL_CONTENT` plus the new `CLAUDE_PLUGIN_ROOT_CORE=/no-such-core-9f3a`
missing-core case) in each `tests/*.sh` file — not against live traffic.
Threshold: 100% pass required; result 77/77 met it.

## Online evaluation

No online evaluation applies: the gates only ever see this repo's own
future `PreToolUse` writes one at a time, with no canary/shadow/A-B split
at the granularity of a single synchronous hook decision — each write
either hits the currently-live gate version or it doesn't, per the
"Rollout" note above.

## Model card

- Intended use: block a `Write`/`Edit`/`MultiEdit` to this rulebook's own
  phase-1/phase-2 documents when a required methodology element is
  missing or misplaced, and fail closed (deny) rather than silently
  allow when core is unreachable.
- Limitations: covers only `Write`/`Edit`/`MultiEdit`-tool writes to the
  exact path patterns each gate matches; a write via `Bash` is out of
  scope (unchanged from issue-10 — survey §2 confirms no gate claims
  Bash coverage).
- Training data: none — deterministic, rule-based text checks, not a
  trained model.
- Evaluation data: the 77-case fixture suite above (held fixed across
  this PR; the new `missing-core-denies-not-allows` fixture was added
  because it was missing, not tuned to make an existing check pass).

Dataset version: fixture suite as of this commit (issue-13 phase 2, 5
files each gaining 1 new case over the issue-10 baseline).
Model version: gate logic as of this commit (issue-13 phase 2 —
issue-10's gate-lib.sh-sourced logic plus the issue-75 source guard,
sourcing behavior otherwise unchanged).

## Data Tests
pass: every fixture used by the 77-case suite is hand-authored and
version-controlled alongside the gate it tests; the new missing-core
fixture is schema-identical to the existing ones (one JSON tool-call
payload in via `_fire`, one exit code out), only the injected
`CLAUDE_PLUGIN_ROOT_CORE` env var differs.

## Model Tests
pass: guard change reviewed against core's own `52bdc15` guard line
character-for-character (diffed by hand, table in §1 above); every
proposal acceptance point (guard applied, matcher parity re-verified,
missing-core case added + suite green + compliance-check clean, sweep
re-verified) is checked off in "Open findings" above.

## ML Infrastructure Tests
pass: reproducible from a clean checkout — each `tests/*.sh` file is
self-contained (own `git init`'d tmpdir per case, no shared mutable
state) and requires only `CLAUDE_PLUGIN_ROOT_CORE` pointing at an
installed `core` plugin; rollback safety covered under "Rollback
conditions" above (plain `git revert`).

## Monitoring Tests
pass: `compliance-check.sh`, re-run at any future point against this
repo's `hooks/` directories, now also catches the specific defect this
issue closed (unguarded `gate-lib.sh` source) — a future edit that
drops the `||` guard will fail it going forward.
