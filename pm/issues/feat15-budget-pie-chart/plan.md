# FEAT15-budget-pie-chart — A donut chart of budget allocation on top of the Budget page

**Status:** DONE 2026-08-24. Owner's direct request (manual-testing feedback,
round six): *"pie chart for budget allocation, in budget page on top of the rows."*
No UC owns this, same class as FEAT01-14.

**Depends on:** none of the accounts-module issues in this same round (FEAT13/14) —
touches only `budgeting/`, safe to build in parallel with them.

## Decisions

**D1 — "Budget allocation" means each group's `amount` (what was set aside), not
`spent`.** `BudgetConsumptionProvider`/`BudgetDao.watchConsumption()` (UC-12) already
emit `BudgetConsumption { groupId, name, amount, spent, remaining }` — one row per
budget group plus the "Others" bucket. The chart's slices are each row's `amount`,
answering "how did I divide my budget," which is what "allocation" names; `spent` is
already shown per-row below the chart (`budgetSpentSubtitle`), so charting it too
would just repeat the list in pie form rather than add a new view. The "Others" row's
`amount` is always `0` (`BudgetDao`'s D4 — it exists to catch un-grouped *spending*,
it is never itself budgeted), so it contributes nothing visible and needs no special
exclusion.

**D2 — New private `_BudgetAllocationChart`, `fl_chart`'s `PieChart`, reusing FEAT07's
established shape.** `BudgetOverviewScreen`'s `_list()` gains this chart above the
existing `ListView` of rows (`"on top of the rows"`) — not a separate scrollable
region, one `Column` inside the same `ListView` so the page still scrolls as one
surface, matching `BalanceSheetScreen`'s chart-then-figures layout precedent. Same
degrade-on-zero shape every other chart in this app already has (FEAT07 D7): an empty
`rows` list, or every row's `amount` being `0`, shows a `chartNoDataYet`-style message
instead of an empty/degenerate pie. Colors cycle through the theme's palette the same
way `_CategorySpendingCard` already does (`colorScheme.primary/secondary/tertiary/
error/primaryContainer/secondaryContainer`, repeating via modulo) — no new palette
invented. No new ARB key for the chart title beyond one: `budgetAllocationChartTitle`.

**D3 — No new DAO method, no new provider.** The chart reads the exact same
`budgetConsumptionProvider` the row list already watches — one `ref.watch` in
`BudgetOverviewScreen`, passed down to both the chart and `_list()`. This is display
only; nothing about `BudgetDao`'s SQL or `FinancialPosition`/`DebtProgress` changes.

## Out of scope

- Charting `spent` or `remaining` instead of/alongside `amount` — not asked for.
- Any interaction on the chart (tapping a slice to filter the list, etc.) — display only,
  matching every other chart in this app.
- A chart on `SetBudgetScreen` — only `BudgetOverviewScreen` was named.

## Definition of done

Four commands green. Widget tests: seeded budget groups with nonzero amounts render a
`PieChart`; an empty database (or all-`amount`-zero groups, including a database with
only the "Others" row) shows the empty-state message instead of a chart, same pattern
`balance_sheet_screen_test.dart`'s chart tests already use; the chart appears above
the existing `ListTile` rows in widget-tree order. `git diff --stat app/drift_schemas/`
empty — no schema change, presentation only.
