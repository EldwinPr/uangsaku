# ISSUE-005 — System component diagram

**Status:** DONE 2026-08-20. Owner confirmed D1 (SQL join, not DAO-to-DAO) and the
background isolate; diagram drawn, render visually verified, closed per the checklist.
Surfaced a cross-module cycle (Accounts <-> Transactions) that the per-module class
diagrams could not show — recorded in `context/index/decisions.md`.
**Depends on:** ISSUE-001 (DONE, `erd.drawio` — entity/table names), ISSUE-002 (DONE,
the three class diagrams — the DAOs, providers and query-result classes named below
come from there and are not re-decided here).
**Traces to:** UC-01..UC-13 (system-level artifact, same as the ERD).

## Goal

One diagram — `docs/diagrams/component-overview.drawio` — per
`context/guide/component-conventions.md`: the modules of this app as black boxes,
and every edge that crosses between them, labeled with its real mechanism.

## Why this is worth drawing, given the convention's stated purpose doesn't apply

`component-conventions.md` says the point of the diagram is making a real
process/network boundary visible against a merely organizational one. **This app has
no real boundary to show.** Flutter + drift over SQLite, no backend (`decisions.md`,
2026-08-19), and backup is an export file rather than sync — so there is no queue job
and no HTTP call anywhere, and every edge is an in-process direct call drawn solid.

The value is elsewhere, and is specific to this project: the three class diagrams each
draw one module's `Screen -> provider -> DAO -> AppDatabase -> tables` chain **in
isolation**, and nothing in the repo shows what crosses between them. Two known
cross-module reads already exist and neither is visible anywhere today:

- `AccountDao`'s `FinancialPosition` (UC-01) and `AccountBalance` (UC-02) must read
  `Transactions` — a table the Transactions module owns. NFR-2 forces this: balances
  are derived from what was recorded, never stored alongside it.
- `BudgetDao`'s `BudgetConsumption` (UC-12) must read `Transactions` too, filtered by
  budget group, including the null-group "Others" (FR-17).
- `RecordTransactionScreen` (UC-04..UC-08) needs an account picker and a budget-group
  picker — data owned by the other two modules (FR-10).

## Decisions this issue must make

Proposals. Confirming this plan confirms them. Cheap to change on the diagram,
expensive once drift schema exists.

### D1 — Cross-module access is a query join on the shared database, not a call into
another module's DAO

Two candidates:

- **(a) Call the other module's DAO.** `AccountDao` asks `TransactionDao` for the rows
  it needs. Keeps each table behind exactly one owner; costs a round trip through Dart
  for what SQLite would do in one statement, and makes UC-01's four figures several
  queries stitched together in Dart instead of one.
- **(b) Join the other module's tables in your own query.** `AccountDao` writes one
  SQL statement joining `Accounts` and `Transactions`. This is what the ISSUE-002
  class diagrams already imply — `FinancialPosition` and `BudgetConsumption` are
  drawn as single query-result classes, which only holds if a single query produces
  them.

**Proposed: (b).** It is what is already drawn, it is what NFR-2 wants (one source per
number, computed in one place), and drift's generated join API makes it the ordinary
way to write this. The honest cost is that module boundaries here are enforced by
nothing at all — not even by "only my DAO touches my tables" — so the diagram must
show that rather than imply an encapsulation the code will not have. Each such edge is
labeled `direct call: SQL join on <table>` and points at the table's owning module.

### D2 — `AppDatabase` is drawn as its own component box

It is the only element all three modules share and the mechanism of every cross-module
edge under D1, so leaving it out as "infrastructure" would hide the coupling this
diagram exists to expose. Alternative rejected: three modules with edges to each other
and no database box, which would suggest the modules talk directly.

### D3 — Boxes are the three modules, plus `AppDatabase`. Nothing below module
granularity

`Accounts`, `Transactions`, `Budgeting` — the same three `Modul` values the workbook
and `map.yaml` already use. Screens, providers and DAOs stay off this diagram; they
are the class diagrams' job, and `component-conventions.md` is explicit that one box
is one business domain.

## Answered 2026-08-20 — drift runs on a background isolate

Was carried as an open question; the owner decided it rather than deferring.
`NativeDatabase.createInBackground`, so SQLite runs off the UI isolate. Full
reasoning and the precise framing (it is *not* concurrent access — drift still
serialises statements; what changes is where they run) in `context/index/decisions.md`.

**Consequence for this diagram:** the module -> `AppDatabase` edges are the only
boundary-crossing edges in the system and are drawn as such. Everything else stays
solid. Step 5 below is amended accordingly — the conventions file gains a worked case
where the boundary distinction *does* carry information, on a system with no backend.

## Steps

1. Confirm this plan (D1, D2, D3) and answer or defer the isolate question.
2. Draw `docs/diagrams/component-overview.drawio` via `diagram-drawio-author`.
3. Export to PNG and look at the whole render, not crops.
4. `grep -c '<!--'` the file; must be 0.
5. Append to `component-conventions.md`: an isolate boundary is a fourth kind of
   edge its table does not cover, and it is the one that makes the diagram carry
   information on a local-only app with no backend, no queue and no HTTP. The file
   currently justifies itself entirely on network/process boundaries, which a
   phone-only app would otherwise never have; that gap was found by use.
6. Close per the `CLAUDE.md` checklist.

## Out of scope

- Per-UC sequence diagrams. They belong to implementation issues; ISSUE-001's plan
  already recorded that the sequence-diagram gate does not bind a documentation issue.
  No code exists and no implementation issue has been opened.
- Any change to the ERD or the class diagrams. If drawing this surfaces a cross-module
  edge that contradicts them, stop and raise it rather than fixing it here.
- The remaining `fr-nfr.md` section 4 items — currency, "what a month means",
  transaction note. None of them add or remove a module edge.
