# UC12-budget-consumption — See what is left of this month's budget

**Status:** DONE 2026-08-23. Was AUTO-CONFIRMED (unattended mode, 2026-08-23). Every D-entry below cites an
artifact the owner has already confirmed — the sequence diagram, `class-budgeting.drawio`,
`docs/fr-nfr.md`, `docs/enums.md`, the workbook UC-12 row, `context/index/decisions.md`, or
the shipped code those artifacts govern. Nothing here is a new choice; the one Q that could
have touched this issue is shown not to block (D7).

**Traces to:** UC-12 (`docs/workbook.xlsx` → UC FR, "Review Budget Consumption") — FR-13,
FR-17, constrained by FR-12/FR-14/NFR-4.
**Depends on:** UC11-set-budget, UC04-record-money-movement — both **DONE** in
`pm/tracker.yaml`. **Preflight passes**: dependencies satisfied; no scope overlap with any
active issue (UC02B-edit-account and UC03-adjust-account are HALTED and own account
edit/delete and adjustment *creation* respectively — neither appears on this diagram, and
neither writes to Budgeting).

## Goal

After this issue the owner can open a budget view for the current month and see, for each
budget group, the amount set, how much has been spent against it, and how much is left —
plus an "Others" line carrying every bit of spending that was recorded with no budget group,
so the month's spending is fully accounted for (FR-13, FR-17). The figures are one live
drift query: recording a transaction on UC-04's form or changing an amount on UC-11's screen
re-emits them with nothing stored to fix up (NFR-2). Going over an amount produces a
negative remaining that is *displayed*, never a warning, a block, or a disabled control
(FR-12, NFR-4).

This is the last of Budgeting's two use cases and the last unwritten method on
`class-budgeting.drawio`'s `BudgetDao` (`watchConsumption()`), the only consumer of the
diagram's `BudgetConsumption` result class, and the first user of `budgetConsumptionProvider`.

## Scope — the sequence diagram

`docs/diagrams/seq-uc12-budget-consumption.drawio` is the scope (render committed at
`pm/issues/uc12-budget-consumption/seq-uc12-budget-consumption.png`). Five lifelines, six
messages, **no write path at all** — this is a view.

| Lifeline | Class | File |
|---|---|---|
| Owner | actor | — |
| BudgetOverviewScreen | `BudgetOverviewScreen`, ConsumerWidget — **new** | `app/lib/src/budgeting/budget_overview_screen.dart` |
| budgetConsumptionProvider | `budgetConsumptionProvider` — **new** | `app/lib/src/budgeting/budgeting_providers.dart` |
| BudgetDao | `BudgetDao` — **exists** (UC-11); gains `watchConsumption()` | `app/lib/src/budgeting/budget_dao.dart` |
| AppDatabase | `AppDatabase` — exists | `app/lib/src/database/app_database.dart` |

Plus one query-result class, `BudgetConsumption` — **on the class diagram already** ("query
result · amount / spent / remaining · includes the null-group 'Others' (D5)"), so it is
written, not invented. No class here is absent from `class-budgeting.drawio`, which is why
**no class-diagram change is proposed**.

The six messages, verbatim: (1) Owner → Screen *"opens the budget view for the month"*;
(2) provider → DAO *"watchConsumption(month)"*; (3) DAO → AppDatabase *"query amount / spent
per group, including the null-group 'Others' (FR-17)"*; (4) AppDatabase → DAO *"rows"*;
(5) DAO → provider *"BudgetConsumption[] stream"*; (6) provider → Screen *"amount / spent /
remaining per group, including Others (FR-13, FR-17)"*.

## Decisions

### D1 — Scope is those six messages, read-only, and nothing else

No write path is drawn, so none is built: no amount editing (UC-11's `SetBudgetScreen`
owns it), no group CRUD (also UC-11's, moved there 2026-08-21), no transaction recording
(UC-04's). The diagram's overspending note is part of the scope and binds the
implementation: *"overspending is shown, not blocked (FR-12, NFR-4) — a data value, not a
branch"*, i.e. a negative `remaining` is rendered and nothing else happens. *(seq-uc12
messages 1–6 and note 20; CLAUDE.md's diagram-is-scope gate; workbook UC-12 Constraint
"overspending is shown, not blocked".)*

### D2 — "Spent" is `to_account_id IS NULL`, in the month, grouped by `budget_group_id`

The definition is already fixed in two confirmed places and is not re-decided here:
`docs/enums.md`'s `Transaction.kind` table — *"'is this spending?' is `to_account_id IS
NULL`"*, which is what makes FR-8's "a transfer is not an expense" and FR-9's "lending is not
spending" structural — and the same sentence on `Transactions` in
`app/lib/src/transactions/transactions_table.dart` (*"Never re-derive it from `kind`"*).
`AccountDao.watchPosition()`'s doc comment reserves the predicate for this issue by name:
*"no `to_account_id IS NULL` spending predicate (spending is UC-12's figure, not FR-1's)"*.

So: **no `kind` filter anywhere in this query** (lessons.md §5 — a query that names the wrong
subject passes for the wrong reason; `kind` is the wrong subject here). A row counts toward a
group's `spent` when `to_account_id IS NULL` **and** `occurred_on` falls inside the month's
`[starts_on, ends_on]` bounds **and** its `budget_group_id` is that group. FR-14 is what
bounds it to the month: *"the figures reflect that month only — nothing carried in from the
month before"*. *(docs/enums.md; transactions_table.dart; account_dao.dart doc comment;
workbook UC-12 Constraint FR-14.)*

### D3 — One query in `BudgetDao`, joining `Transactions` — the ISSUE-005 D1 shape

`watchConsumption()` is a single watched `customSelect` inside `BudgetDao` that joins
`BudgetGroups`, `BudgetPeriods` and `Transactions`, with `readsFrom` naming all three so the
stream re-emits on any of them. It does **not** call `TransactionDao` and does not stitch
results together in Dart — decisions.md 2026-08-20 (ISSUE-005 D1): *"Modules reach each
other's data by SQL join, not by calling another module's DAO."* `BudgetDao` already reaches
`Transactions` this way in `deleteGroup()`, and `AccountDao.watchBalances()` /
`watchDebtProgress()` are the shipped read precedents. *(decisions.md 2026-08-20; shipped
budget_dao.dart / account_dao.dart.)*

Shape of the result set, per message 3:

- **One row per budget group**, whether or not it has spending and whether or not it has an
  amount for the month — a budget with nothing spent yet is precisely what FR-13 exists to
  show. The group's `amount` is its `BudgetPeriods` row for this month (matched on
  `starts_on`, the same way `watchPeriods()` already matches), and **no pre-fill from the
  previous month is applied here**: FR-15's pre-fill is UC-11's setting affordance, and FR-14
  forbids last month's number appearing in this month's figures.
- **Plus exactly one "Others" row**, the `budget_group_id IS NULL` bucket, always present and
  last. *(FR-17; ERD note "budget_group_id NULL on a Transaction = the 'Others' bucket
  (FR-17). Not a row."; decisions.md 2026-08-19 "'Others' … is the null `budget_group_id`,
  not a row that could be renamed or deleted"; message 6 says "including Others"
  unconditionally.)*
- **Ordering:** groups by `budget_group_id` ascending, Others last. The diagram draws no
  ordering; deterministic-by-insertion-id is this project's stated neutral choice for exactly
  that case (`watchBalances()`: *"Ordered by insertion id so emissions are deterministic (the
  diagram draws no ordering; this is the neutral one)"*). Others cannot sort by an id it does
  not have, and it is not a group, so it goes last.

### D4 — `BudgetConsumption`: `amount`, `spent`, `remaining = amount - spent`; Others carries a null id and null name

The class diagram fixes the three figures. Filling them in:

- All three are **`int` minor units**, never `double` (NFR-2, `Settings.currency`, and every
  amount column shipped).
- `remaining` is **`amount - spent`, defined once** (a getter on the class), so it cannot
  drift from the other two. Negative is a legitimate value and is rendered as such — note 20
  again: overspending is *a data value, not a branch*.
- A group with **no `BudgetPeriods` row for the month has `amount` 0**, not an error and not a
  gap. Forced by the diagram: "Others" is drawn as carrying amount/spent/remaining like every
  other line, and Others can *never* have an amount — `BudgetPeriods.budget_group_id` is NOT
  NULL and references a real group, so no period row can exist for the null bucket. Zero is
  the only value that makes `remaining = amount - spent` hold for every line, and it makes
  untagged spending show as negative remaining, which is what FR-17's "the month's totals stay
  complete" means. *(class-budgeting.drawio `BudgetConsumption` box; seq-uc12 msg 6;
  budgeting_table.dart; FR-17.)*
- **Others is identified by `groupId == null` / `name == null` in the query result, and the
  string "Others" is applied by the screen.** The ERD and decisions.md both insist Others is
  not a row; giving it a synthetic id or storing its label in the data layer would contradict
  that. FR-17 supplies the label at the only place it belongs, the view. *(ERD note;
  decisions.md 2026-08-19; FR-17.)*
- It is a **class, not a `typedef` record** — unlike UC-11's `BudgetRow`, which is a record
  precisely *because* `class-budgeting.drawio` has no box for it. `BudgetConsumption` has a
  box. Same rule, opposite answer. *(budgeting_providers.dart `BudgetRow` doc comment;
  coding-conventions "code may not invent a class the diagrams don't have" — and may not
  demote one they do.)*

### D5 — The month argument is `monthsAgo`, defaulting to 0, from the injected `Clock`

Message 2 is `watchConsumption(month)`. The month is expressed the way this DAO already
expresses it: `watchConsumption({int monthsAgo = 0})`, resolved through `BudgetDao`'s
existing injected `Clock` and its existing private `_monthStart` / `_monthEnd` helpers —
`monthsAgo: 0` is the current calendar month. This is `watchPeriods({int monthsAgo = 0})`'s
signature and mechanism verbatim; inventing a second month vocabulary in one DAO would be the
new decision, not reusing this one. Calendar month, not payday-to-payday, was settled
2026-08-20. *(shipped budget_dao.dart; class-budgeting.drawio's Clock note — "deciding which
period is the current one is still a question about today's date"; decisions.md 2026-08-20
calendar-month ruling.)*

The screen passes nothing and therefore shows the current month; **no month picker is drawn
on the diagram**, so none is built (see Out of scope). The provider is a plain
`StreamProvider`, not a `.family` — the class diagram types it *"StreamProvider · UC-12"*,
where UC-10's `debtProgressProvider` is explicitly typed *"StreamProvider.family"* when a
parameter was meant. *(class-budgeting.drawio; class-accounts.drawio contrast; shipped
accounts_providers.dart.)*

### D6 — The read path: one stream, one hand-written `StreamProvider.autoDispose`

`budgetConsumptionProvider` wraps exactly one drift stream:

- **`StreamProvider`, not a Notifier** — the class diagram types it so, and the diagram draws
  a single subscription feeding message 5.
- **The UC-11 ruling is not triggered.** decisions.md 2026-08-22 mandates the hand-subscribed
  `Notifier` shape for a screen reading **more than one** stream (that is why `BudgetNotifier`
  looks as it does, with three). This screen reads one, so the plain `StreamProvider.autoDispose`
  that `financialPositionProvider` / `accountBalancesProvider` ship applies.
- **Hand-written, not `@riverpod`** — `riverpod_generator` throws `InvalidTypeException` on any
  provider whose signature mentions a drift row class, and would rename the provider away from
  the class diagram's `budgetConsumptionProvider`. Standing exception since UC-13.
  *(decisions.md 2026-08-21 and 2026-08-22; shipped accounts_providers.dart / budgeting_providers.dart.)*

The Screen → provider `watch()` call is not drawn (the diagram starts the read path at
message 2, provider → DAO). Per this project's settled as-built practice it is added to the
diagram at close, exactly as UC-09/UC-10/UC-11/UC-13 did — an emission presupposes a
subscription, so it adds nothing the diagram does not already imply. *(Step 7; UC-09 D2 and
the UC10/UC13 tracker summaries.)*

### D7 — Q4 does not block this issue; Q3 does not touch it

- **Q4 (adjustment side/sign encoding).** This issue creates no adjustment and interprets no
  `kind`: the spending predicate is a *column* test fixed by `enums.md` and the shipped table
  doc comment (D2), applied to whatever rows exist. Nothing branches on kind or sign, so no
  answer to Q4 can force a rewrite of `watchConsumption()`. Additionally, **no adjustment row
  can exist yet** — UC-03 owns the only write path and is HALTED. *(pm/questions.md Q4;
  UC01/UC10 precedent for proceeding on the same ground.)*
- **Q3 (transactions of a deleted account).** UC-12 deletes nothing and reads no account at
  all; `Accounts` is not even in the query. *(pm/questions.md Q3.)*

### D8 — NFR-4 on a screen with no controls

A read-only view cannot refuse an action, and none is added: no confirmation, no warning
banner, no "over budget" modal, no control of any kind that is disabled. Overspending renders
as a negative number (D4). An empty database renders empty lines, not an error; loading
renders a placeholder, as on every shipped screen. Per ISSUE-009's requirement the named
requirements get explicit tests: **FR-13** (amount/spent/remaining per group, draining as
spending is inserted through the same tables UC-04 writes), **FR-17** (untagged spending lands
under Others and nowhere else), **FR-14** (spending outside the month contributes nothing),
**FR-12/NFR-4** (spending past the amount emits a negative remaining and the widget renders it
with nothing blocked). *(NFR-4 fit criterion; workbook UC-12 constraints; ISSUE-009 summary.)*

### D9 — Reachability: F8's next orphan, stated not fixed

No navigation host exists and none appears on any class diagram, so `BudgetOverviewScreen`
ships exercised by its tests and possibly unreachable at runtime; `home` stays
`BalanceSheetScreen` permanently (UC-01's ruling). This issue does not invent a navigation
host — that remains findings F8, the owner's call. *(F8; UC-01 summary; UC-09 D8 precedent.)*

### D10 — Registers this issue updates at close (lessons.md §1)

Beyond the standard checklist: **`map.yaml`** gains the UC-12 entry; **seq-uc12** gets its
as-built pass (step 7), which also clears this diagram from findings **F3** — its isolate note
still names `NativeDatabase.createInBackground` instead of the FEAT01 ruling-2 mechanism
(`driftDatabase()` → `createBackgroundConnection`) — so F3's count narrows by one; and the
**stale class doc comment in `budget_dao.dart`** must be corrected, found while planning: it
says *"`watchConsumption()` is UC-12's and is **not** written here, per the plan's `Out of
scope`"*, which stops being true the moment step 2 lands. Also **F8**'s orphan count and, per
F5's standing gap, the workbook row is marked implemented only if F5 has a place to record it
by then.

## Steps

1. `BudgetConsumption` in `app/lib/src/budgeting/budget_dao.dart` (alongside the DAO, as
   `FinancialPosition` / `AccountBalance` sit in `account_dao.dart`): `int? groupId`,
   `String? name`, `int amount`, `int spent`, and `remaining` as `amount - spent` (D4).
2. `BudgetDao.watchConsumption({int monthsAgo = 0})` — one watched `customSelect` returning
   one row per budget group plus the Others row, per D2/D3/D5: amount from the month's
   `BudgetPeriods` row (0 when absent), spent as the summed `Transactions.amount` where
   `to_account_id IS NULL` and `occurred_on` is within the month bounds, grouped by
   `budget_group_id`; ordered by `budget_group_id` with Others last; `readsFrom` naming
   `budgetGroups`, `budgetPeriods` and `transactions`. Plain-class DAO, unchanged shape
   (decisions.md 2026-08-21, UC-13 ruling 1).
3. DAO tests in `app/test/budgeting/budget_dao_test.dart`: a group with an amount and partial
   spending; a group with an amount and none; a group with spending and no period row (amount
   0, negative remaining); untagged spending appearing only under Others; a transfer, a lend
   and an income contributing **nothing** (all have `to_account_id` set — the FR-8/FR-9
   property, lessons.md §5); spending dated in the previous and next month contributing
   nothing (FR-14); an adjustment row with `to_account_id` NULL counting as spending, pinned
   as a test so the predicate's column-only nature is visible when Q4 lands (D7); Others
   present with 0/0/0 when nothing is untagged.
4. `budgetConsumptionProvider` in `app/lib/src/budgeting/budgeting_providers.dart` —
   hand-written `StreamProvider.autoDispose<List<BudgetConsumption>>` over
   `watchConsumption()` (D6).
5. `BudgetOverviewScreen` in `app/lib/src/budgeting/budget_overview_screen.dart` — a
   `ConsumerWidget` watching that provider; one line per entry showing name (or "Others" for a
   null name, D4), amount, spent and remaining, currency-formatted the way the shipped screens
   format amounts; loading and empty states as elsewhere. No controls (D8).
6. Widget tests in `app/test/budgeting/budget_overview_screen_test.dart` per D8, including the
   overspent line rendering a negative remaining with nothing blocked or disabled (NFR-4).
7. `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` — all green (plus
   `build_runner` only if generation is actually needed; no schema change is made, so
   `schemaVersion` stays 1 and `drift_schema_v1.json` must remain byte-identical).
8. **As-built pass on `seq-uc12-budget-consumption.drawio`**: add the Screen → provider
   subscription message (D6); correct the isolate note to `driftDatabase()` →
   `createBackgroundConnection` (F3); export to PNG, **look at the render** (lessons §3),
   commit it over `pm/issues/uc12-budget-consumption/seq-uc12-budget-consumption.png` with the
   refreshed `renders.lock`.
9. Close per CLAUDE.md's checklist plus D10: `map.yaml` UC-12 entry; the stale
   `budget_dao.dart` class doc comment corrected; `pm/tracker.yaml` → Done with a one-line
   summary; `pm/log.md` dated entry; F3 and F8 updated.

## Out of scope

- **Any write path** — the diagram draws none. Setting or editing an amount, deleting a
  period, and creating/renaming/deleting a budget group are all UC-11's shipped screen;
  recording a transaction is UC-04's form.
- **Choosing a different month / month navigation** — message 1 opens *the* month and no
  message selects one; the DAO's `monthsAgo` parameter exists (D5) but the screen passes the
  default. A month picker would be a new use case, not a widening of this one.
- **Quarterly / yearly rollups (NFR-3)** — the `starts_on`/`ends_on` columns exist for them;
  nothing here aggregates across periods.
- **Carrying last month's amount into this month's figures** — FR-15's pre-fill is UC-11's
  setting behaviour; FR-14 forbids it in the report.
- **Warning, nagging, or blocking on overspend** — FR-12 and NFR-4; it is a number.
- **Drilling into the transactions behind a figure** — no message, no lifeline; the
  transaction list is UC-09's screen.
- **Searching or filtering** — `fr-nfr.md` §3 keeps it deliberately deferred.
- **Schema changes of any kind** — this issue is read-only; `schemaVersion` stays 1.
- **A navigation host / making the screen reachable** — findings F8, owner's call.
- **Indexes or query tuning** — nothing measured slow (NFR-2's own condition).

## Open questions

Neither blocks; both are recorded so they are not rediscovered as bugs.

1. **Presentation of an unset amount.** D4 makes a group with no period row show `amount` 0.
   The owner may later prefer a blank or a dash there. Presentation only, no downstream
   consequence, and no artifact fixes it either way.
2. **Adjustments and budget consumption, once Q4 lands.** Today's predicate (D2) counts any
   row with `to_account_id` NULL as spending, which will include adjustments encoded that way.
   That follows directly from `enums.md`, and no adjustment can exist until UC-03 unblocks, so
   nothing is at risk now — but it is the one place Q4's answer becomes visible in a budget
   figure, and step 3 pins it with a test so the behaviour is inspectable rather than implicit.
