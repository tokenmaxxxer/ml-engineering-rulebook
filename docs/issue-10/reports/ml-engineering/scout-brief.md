# Scout brief (issue-10, ml-engineering — gate A+ hardening)

Scope note up front: this is an internal engineering scout, not market
research. The comparable-systems surface inside this working tree is
narrow — the only genuinely comparable prior art is core's own
gate-house standard and its own pre-issue-72 gates (the thing it fixed
in itself). Stating that plainly rather than padding with a longer list.

**Must-bes** (non-negotiable properties any hardened gate needs, drawn
from `gate-house-standard.md` + `gate-lib.sh`/`gate-lib.py` source):
1. Fail-closed on any non-0/2 exit, installed as the literal first
   statement (`gate_trap_fail_closed`, `gate-lib.sh:36-41`) — before
   `set -uo pipefail`, so even a syntax error is caught.
2. Kill-switch narrows the *disabling* set to recognized on-spellings
   only; every off-spelling and unrecognized value stays active
   (`gate_kill_switch_active`, `gate-lib.sh:61-68`).
3. `replace_all` honored per-edit for both `Edit` and `MultiEdit`
   (`gate_reconstruct_write`, `gate-lib.py:87-153`) — core's own
   `record-fields-gate.sh` shipped without this and it was a live bug in
   the canon repo itself, not a hypothetical.

**Performance axes** a hardened gate is judged on (per the standard's own
six-case harness, `gate-house-standard.md:58-75`): correctness under
malformed input (deny, not crash), correctness under multi-edit/
replace_all reconstruction, path-matching correctness under
absolute/relative/`./`-prefixed variants, and kill-switch correctness
under garbage values. Notably *not* judged on speed — these are
PreToolUse hooks running once per write, not a hot loop; no evidence in
`gate-lib.sh`/`gate-lib.py` of any performance-driven design choice (no
caching, no early-exit optimization beyond ordinary short-circuiting).

**One pattern to adopt**: `gate-lib.sh`'s "reference only, never copy"
convention enforced mechanically by `stub-check.sh` against
`canon-manifest.txt` (`gate-house-standard.md:91-94`) — the shared
library is sourced by path at runtime, not vendored as a text copy, so a
future gate-lib fix propagates to every rulebook without a re-sync PR.
This repo's current five gates already don't vendor core's generic gates
(README's own note, confirmed accurate against `core/hooks/*.sh`), so
adopting `gate-lib.sh`/`gate-lib.py` the same way is a direct extension
of a pattern already in use here, not a new discipline.

**One pattern to skip**: core's own gate-lib deliberately keeps
`gate_normalize_path` filesystem-free (pure string algebra, no
`realpath`) and pushes symlink-safety onto the caller
(`gate-lib.py:52-55`). Do not "improve" on this by baking `realpath` into
a new shared helper in this repo — the existing five gates already do
their own `os.path.realpath(root)` + `os.path.realpath(a)` resolution
locally (each gate's own `resolve()` closure), which is the right layer
for it per gate-lib's own documented contract. Duplicating realpath logic
inside a local wrapper around `gate_normalize_path` would be exactly the
kind of local reimplementation issue-10's "adopt by reference" precondition
forbids.

**GAP**: gate-lib.sh/py offer no section-aware text-placement helper and
no word-boundary text-matching helper — both are needed for Finding 2/3's
fixes and neither has any prior-art instance to scout inside this
repo or core (`ml-engineering-ml-test-score`'s existing header-slicing
logic is the *closest* local precedent, itself only a partial, buggy
solution — see the current-state survey's Finding 2/3 sections). This
must be designed fresh in the proposal, not borrowed.

**Sources** (internal, all read in full for this scout):
- `core/hooks/lib/gate-lib.sh` (research checkout:
  `/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-72-implementation/core/hooks/lib/gate-lib.sh`)
- `core/hooks/lib/gate-lib.py` (same dir)
- `docs/handbooks/gate-house-standard.md` (reference copy read at
  `/tmp/claude-1000/core-ref/gate-house-standard.md`)
- This repo's `ml-engineering-ml-test-score/hooks/methodology-gate.sh`
  (only gate in this repo with any section-slicing logic, and the one
  carrying the concrete `pass`/`bypass` bug)
- This repo's `docs/issue-7/reports/ml-engineering/survey.md` (prior
  scout precedent format followed here)

No web research performed — bash strict-mode/trap idioms used in
`gate-lib.sh` (the `trap 'rc=$?; ...' EXIT` pattern) are standard and
already fully specified by the internal source; nothing external was
needed to evaluate them.
