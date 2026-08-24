# FEAT07-home-overview-charts — Charts on Home, and Home stops looking empty

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request (manual-testing
feedback, round two), items 1 and 5: *"a chart would be helpful"* / *"overall it needs
to be more informative and the app itself still looks empty"* — clarified via
follow-up: Home specifically, three charts: balance trend over time, income vs
expense, spending by category. No UC owns this, same class as FEAT01-06.

**Depends on:** `FEAT06-save-ux-and-uniqueness` — DONE.

## Decisions

**D1 — New dependency: `fl_chart`.** No charting code exists anywhere in the app.
`fl_chart` is the standard Flutter charting package (line/bar/pie all in one, pure
Dart, no platform channel) — add it to `app/pubspec.yaml` and run `flutter pub get`.

**D2 — All three queries live in `AccountDao`, not `TransactionDao`.** `BalanceSheetScreen`
(Home) is an accounts-module screen; ISSUE-005 D1 already licenses `AccountDao` reaching
`Transactions` directly (`watchPosition()` does this today), and reaching `Categories`
the same way is the identical licence read one table further — no screen in this app
watches a provider from a module other than the one it lives in yet, and this issue is
not the place to start that pattern. Three new query-result classes in `account_dao.dart`,
next to `FinancialPosition`/`AccountBalance`/`DebtProgress`; three new methods on
`AccountDao`; three new `StreamProvider`s in `accounts_providers.dart`, hand-written
(the two standing reasons: drift row types break `riverpod_generator`, and none of these
three need the generator's naming anyway since they're new names this issue picks).

**D3 — `BalanceTrendPoint` (balance trend chart).** `watchBalanceTrend({int days = 30})`
→ `Stream<List<BalanceTrendPoint>>`, one point per calendar day for the trailing `days`
days including today. Each point's balance is the same `net` expression `watchPosition()`
computes (opening amounts of all non-deleted accounts, plus every transaction's signed
movement), bounded to `occurred_on <= that day` — i.e. the running net position *as of*
that day, not that day's movement alone. Generate the day series with a `WITH RECURSIVE`
CTE (SQLite has no built-in date-series function); each day's balance is a correlated
subquery over `Transactions` bounded by the day. `BalanceTrendPoint(date, netBalance)`,
both fields plain (`DateTime`, `int` minor units — NFR-2). Line chart, `fl_chart`'s
`LineChart`.

**D4 — `IncomeExpenseSummary` (income vs expense chart).** `watchIncomeExpense()` →
`Stream<IncomeExpenseSummary>`, current calendar month only (matches the budgeting
module's existing in-month convention, `budget_dao.dart`). Two fields: `income` (Σ
`amount` WHERE `from_account_id IS NULL`, in-month) and `expense` (Σ `amount` WHERE
`to_account_id IS NULL`, in-month) — the same predicates FR-1/UC-12 already use to mean
"income" and "spending" (never a `kind` filter, per D5 of `watchPosition`'s own
precedent). Both non-negative magnitudes. Two-bar `BarChart`.

**D5 — `CategorySpending` (spending-by-category chart).** `watchCategorySpending()` →
`Stream<List<CategorySpending>>`, current calendar month, `to_account_id IS NULL` rows
only (the same spending predicate as D4), grouped by `category_id`, joined to
`Categories.name`. A row with `category_id IS NULL` groups into one bucket labelled by
a new ARB key (`uncategorizedLabel`) rather than being dropped — every expense is
accounted for in the chart, or the chart itself misrepresents total spending. `Sub`category
is not broken out (categories only — subcategory-level would be a second chart nobody
asked for). Donut, `fl_chart`'s `PieChart`.

**D6 — Home layout: figures stay, charts join them, in one scroll.** `BalanceSheetScreen`
keeps its existing four `_FigureCard`s at the top (UC-01's scope is unchanged — this
issue adds to the screen, it doesn't touch what FR-1 already ships) and appends the three
charts below, each in its own titled `Card` for visual separation, in the order D3→D4→D5
(time trend first, this-period breakdown after). Each chart degrades to an
empty-state message (a new ARB key, `chartNoDataYet`) rather than rendering a blank or
crashing on zero rows/zero total — `fl_chart` divides by the pie total internally, and a
brand-new install's Home (no transactions yet) must not throw.

**D7 — Loading and error states match the four figures' existing shape.** Each chart's
`StreamProvider.autoDispose` is `.when`'d the same way `positionAsync` already is on this
screen: a loading placeholder (not a spinner stacked three times), and an error renders
text, never a silently-wrong chart.

## Out of scope

- Any change to what `watchPosition()`/`watchBalances()` computes or returns — this issue
  only adds three new read methods beside them.
- Charts anywhere other than Home (no chart on `AccountsScreen`, `TransactionListScreen`,
  or `BudgetOverviewScreen` — not asked for).
- A user-adjustable date range or period picker — 30 days / current month are fixed,
  matching every other period-scoped figure already in this app (`budget_dao.dart`'s
  in-month convention).
- Any new schema, table or column — every figure here is derived at read time from
  `Accounts`/`Transactions`/`Categories`, already-existing tables (NFR-2).
- Tapping a chart to drill into its data — display only.

## Definition of done

Four commands green (`app/`: `dart run build_runner build --delete-conflicting-outputs`,
`dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`). Widget tests:
each of the three charts renders given seeded data (assert on the underlying data the
chart widget was built from, not pixel output — this project's established pattern for
anything visual); each chart's empty-state message shows given zero rows; `AccountDao`
tests for `watchBalanceTrend`/`watchIncomeExpense`/`watchCategorySpending` assert the
computed figures against a small hand-built transaction set, including one uncategorized
expense landing in the `Uncategorized` bucket. `git diff --stat app/drift_schemas/`
empty — no schema change. `class-accounts.drawio` gains the three query-result classes,
three `AccountDao` methods and three providers; re-exported PNG visually checked before
commit.
