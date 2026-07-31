# Scout brief (issue-7, ml-engineering)

Mode: batched-sequential fallback (single session, no parallel subagent/tool
dispatch available for local-repo reads) — 3 stages: sweep (read named
precedent + canon gate + one alternate pattern), one deepening round (read
the precedent's own phase-1 proposal doc), judge point (saturated — a second
round would not change the build decision below).

## Must-bes (from the field)
- A role-specific methodology gate is a **small file on top of** the canon
  generic gate, never a replacement or a copy of it — `pricing/hooks/
  methodology-gate.sh` explicitly frames itself as "on top of (never instead
  of) the core canon record-fields-gate.sh's generic §20 fields" and reuses
  canon's own resolve/target-detection helpers by re-deriving them locally
  (canon exposes no shared library for this yet), not by sourcing canon
  internals.
- Fail-closed on every ambiguous path: unparseable JSON, unresolvable
  content from an `Edit`/`MultiEdit` whose `old_string` doesn't match, no
  python3 on PATH, internal exception — all `deny`/`exit 2`, never silently
  pass. Source: `pricing/hooks/methodology-gate.sh` L30-33, 84-91, 153-159,
  221-223 (mirrors `core/hooks/record-fields-gate.sh`'s own fail-closed
  wrapper, L1-3, 222-224).
- Kill switch env var per gate, same naming convention:
  `<ROLE-PREFIX>_METHODOLOGY_GATE_OFF=1`. Source: `pricing/hooks/
  methodology-gate.sh` L19, 25-28.
- Matcher scope is narrow and content-based, not path-only: proposal writes
  matched by `docs/issue-<n>/proposals/*<role>*.md` regex, record writes by
  the exact `docs/issue-<n>/reports/<role>.md` path; anything else exits 0
  (not this gate's business). Source: same file, L94-95, 118-119.
- Required-element check is substring/keyword detection over the
  post-write text (handles `Write` full-content, `Edit`/`MultiEdit` by
  replaying the edit against current content), never an LLM judgment call.
  Source: same file, L129-159, 161-218.
- State/order tracking is reserved for genuine multi-step *within-role*
  sequencing that a single document's structure cannot already express —
  e.g. `implementation-rulebook`'s `coding/hooks/state.sh` tracks an
  open-PR/no-PR/record-exists cycle across sessions via `gh pr view` +
  branch-name parsing, because that state lives outside any one file.
  Source: `implementation-rulebook/coding/hooks/state.sh` (whole file, esp.
  L10-27).

## Performance axes the precedent competes on
1. Enforces domain elements (method named, required structural fields
   present) mechanically, not just record-shape (§20 generic fields already
   covered by canon).
2. Composes with, never duplicates, the canon record-fields-gate's own
   fail-closed/path-resolution machinery.
3. Ships a same-PR gate test pair (pass case, fail case) rather than
   asserting untested gate logic.

## Adopt / skip
- **Adopt**: pricing's file shape (single bash script, python3 heredoc
  judge, `__fc` trap, `deny()` helper, matcher regexes for proposal+record
  paths, substring-based element checks) as the direct template for
  `ml-engineering/hooks/methodology-gate.sh`.
- **Skip**: order/state-tracking machinery (`state.sh`-style). This role's
  methodology has no cross-file/cross-session ordering constraint beyond (a)
  ADR internal structure (Context-before-Decision, checked by the same
  substring gate, not a separate state file) and (b) the phase-1/phase-2
  Approve gate, which is contract-v3-level and not this role's to duplicate.
  Recorded as a deliberate skip, matching the survey's gap #3.

## Segment fit
This role's write surface (report-only, two record artifacts: serving
design + risk note, both already named in `PRODUCES`) is a closer structural
match to `pricing-rulebook`'s (also report-only, methodology-in-directive,
one gate) than to `implementation-rulebook`'s (code-writing role, needs
`state.sh` because work spans sessions/PRs) — segment fit favors the pricing
template over the coding template.

## Gap line
Current state already meets: methodology *content* is decided (issue-1
§a-c) and named in `PRODUCES`. Missing: every must-be above except
"content decided" — no mechanical gate, no fail-closed enforcement, no
kill switch, no gate tests, no explicit skip record for state-tracking.

Sources:
- /home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh
- /home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/docs/issue-1/proposals/methodology-norms.md
- /home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/record-fields-gate.sh
- /home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/state.sh
