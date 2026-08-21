# ISSUE-002 — Class diagrams (one per module)

**Status:** DONE 2026-08-20. All three diagrams drawn and visually verified. Amended
later the same day by ISSUE-004, which removed `isEditable()`, `stateOf()` and the
`BudgetPeriodState` box from `class-budgeting.drawio` when FR-16's lock went away — the
class tables below carry those strikethroughs inline.
**Depends on:** ISSUE-001 (DONE). `docs/diagrams/erd.drawio` is the design of
record for entity names; every class named below that corresponds to an entity is
a consumer of that name, not an independent source.

## Goal

Three diagrams — `docs/diagrams/class-accounts.drawio`,
`class-transactions.drawio`, `class-budgeting.drawio` — showing the real Dart
classes per module and what calls what, per
`context/document-writer-only/class-diagram-conventions.md`.

## Architecture shown

**Not EBC** — the owner rejected that framing explicitly. The conventions file's
default applies instead: show the real classes and their actual dependencies, with
no named pattern imposed. The shape, confirmed with the owner in conversation:

```
drift table  ──►  DAO  ──►  Riverpod provider  ──►  Screen (widget)
                                    ▲                     │
                                    └──── calls ──────────┘
```

Reads flow left to right as streams; writes are the screen calling a Notifier
method, which writes through the DAO. The screen never touches the DAO or the
database. Dependency arrows on the diagram therefore point Screen -> provider ->
DAO -> table, and never the other way.

## Classes to draw

Drafted here because the conventions file forbids putting a class on a diagram
before it is drafted in a plan. None of these exist in code yet — no code exists.

### Shared, drawn on all three diagrams

- `AppDatabase` — the single drift database. All three DAOs attach to it. It is
  the only class that appears on more than one diagram; noted on each so the
  sharing is visible without a system-wide diagram.

### Accounts module — `class-accounts.drawio`

| Class | What it is |
|---|---|
| `Accounts` | drift table declaration |
| `AccountGroup` | enum — `holding` / `receivable` / `payable` (D2) |
| `AccountDao` | queries + writes for accounts |
| `AccountBalance` | query result — one account and its derived balance |
| `FinancialPosition` | query result — UC-01's four figures |
| `DebtProgress` | query result — UC-10's paid / remaining |
| `accountBalancesProvider` | `StreamProvider` — read path for the account list |
| `financialPositionProvider` | `StreamProvider` — UC-01 |
| `debtProgressProvider` | `StreamProvider.family` keyed by account — UC-10 |
| `AccountsNotifier` (`accountsProvider`) | `Notifier` — `addAccount`, `adjustAccount`, `markSettled` |
| `BalanceSheetScreen` | UC-01 |
| `AccountFormScreen` | UC-02, UC-03 |
| `DebtDetailScreen` | UC-10 |

### Transactions module — `class-transactions.drawio`

| Class | What it is |
|---|---|
| `Transactions`, `Categories`, `Subcategories` | drift table declarations |
| `TransactionKind` | enum — the seven kinds from D1 |
| `TransactionDao` | one write path for all seven kinds |
| `CategoryDao` | **added 2026-08-20** — queries/writes for `Categories` + `Subcategories`. UC-13 is category CRUD against two tables that `TransactionDao` does not otherwise own; folding it in would have made one class the write path for two unrelated concerns |
| `transactionListProvider` | `StreamProvider` — UC-09 |
| `categoryTreeProvider` | `StreamProvider` — category/subcategory tree for pickers and UC-13 |
| `TransactionsNotifier` (`transactionsProvider`) | `Notifier` — `recordExpense`, `recordIncome`, `transfer`, `lend`, `borrow`, `repay`, `edit`, `delete` |
| `CategoriesNotifier` (`categoriesProvider`) | `Notifier` — UC-13 |
| `RecordTransactionScreen` | UC-04..UC-08 |
| `TransactionListScreen` | UC-09 |
| `CategoryManagerScreen` | UC-13 |

### Budgeting module — `class-budgeting.drawio`

| Class | What it is |
|---|---|
| `BudgetGroups`, `BudgetPeriods` | drift table declarations |
| ~~`BudgetPeriodState`~~ | **REMOVED 2026-08-20 by ISSUE-004.** Was the `open` / `locked` / `closed` enum. The owner removed FR-16's lock, `locked` ceased to exist, and the remaining pair collapsed into a date comparison that gates nothing — so there is no status enum and no state diagram. See `docs/statuses.md` |
| `BudgetDao` | period queries, consumption query |
| `BudgetConsumption` | query result — amount / spent / remaining, including the null-group "Others" (D5) |
| `Clock` | injected time source. Originally justified by FR-16's lock being the only time-dependent behaviour; that lock is gone (ISSUE-004), and `Clock` survives only because deciding which period is current is still a question about today's date. Weaker justification than before — drop it if nothing turns out to ask it the time |
| `budgetConsumptionProvider` | `StreamProvider` — UC-12 |
| `BudgetNotifier` (`budgetProvider`) | `Notifier` — `setAmount`, `delete`. ~~plus the lock check~~ — no lock check; ISSUE-004 removed `isEditable()` |
| `BudgetOverviewScreen` | UC-12 |
| `SetBudgetScreen` | UC-11 |

## Three decisions — all now closed

**1. Generated drift classes are omitted. CONFIRMED 2026-08-19.** drift generates a
row class (`Account`) and a companion (`AccountsCompanion`) per table. They are real
classes, so the conventions file's "one box = one real class" arguably admits them —
but drawing 12 boxes nobody authored would roughly double each diagram to show
generator output. Settled: draw only the table declaration you write, with a note on
each diagram saying the row and companion classes are generated from it.

**2. State management: Riverpod. DECIDED 2026-08-20 — this is what unblocked the
issue.** `decisions.md` had deliberately left it open. The owner chose Riverpod after
a walkthrough of the four candidates. Reasoning recorded in
`context/index/decisions.md`; the short version is that drift DAOs already return
reactive streams and Riverpod's `StreamProvider` consumes a stream with no adapter
layer, while Bloc would require hand-written event/state classes wrapping streams
that were already fine, and plain `setState` would delete the middle layer these
diagrams exist to show.

*Consequence for the diagrams.* The middle band was drafted as
`AccountsViewModel` / `TransactionsViewModel` / `BudgetViewModel`. Under Riverpod it
splits in two, which is the honest shape rather than a cosmetic rename:
**`StreamProvider` objects carry the reads** and **`Notifier` classes carry the
writes**. The chain and the arrow direction are unchanged, and the screen still never
touches the DAO — it watches a provider.

**3. `Transaction` naming risk: CLEARED 2026-08-20, no rename.** Plan step 2.
Verified against the drift documentation rather than assumed: drift runs transactions
through a **method**, `transaction(() async {...})` on the database or DAO — there is
no public drift class named `Transaction` for a generated row class to collide with.
The conflict drift's FAQ documents is the reverse case (*your own* imported
`Transaction` shadowing the generated one), which does not apply here because the
generated row class is the only `Transaction` in the project. `Transactions` (table)
-> `Transaction` (row) stands, and **the ERD needs no change**. If a third-party
`Transaction` is ever imported, the documented fix is drift's modular code
generation, not a rename.
Sources: <https://drift.simonbinder.eu/dart_api/transactions/>, <https://drift.simonbinder.eu/faq/>

## Steps

1. ~~Confirm this plan.~~ Done.
2. ~~Verify the `Transaction` naming risk.~~ Done — cleared, see decision 3.
3. Draw the three diagrams.
4. Export each to PNG and look at the full render, not crops. Three separate
   defects on ISSUE-001's single diagram got through everything except this step.
5. `grep -c '<!--'` each file; must be 0.
6. Close per the `CLAUDE.md` checklist.

## Out of scope

- The budget-month state diagram (`Budget_Period` open -> locked -> closed) — done
  separately as ISSUE-003.
- The component diagram.
- Any actual Dart code.
