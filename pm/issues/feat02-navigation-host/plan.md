# FEAT02-navigation-host — Wire every screen into a reachable app shell

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request, interactive session ("add a
navigation host so I can actually try it"). No UC owns this, same as `FEAT01-foundation`:
it is infrastructure, not a use case, and `pm/findings.md` F8 has tracked its absence
since UC-11's close as "the owner's standing question." The owner just answered it.

**Traces to:** none (infrastructure, F8's resolution).
**Depends on:** every screen issue — all DONE.

## Why now, and what F8 was

Every screen since UC-13 shipped with no route to it; `MaterialApp.home` pointed at
whichever screen's issue closed last, orphaning the one before. Nine screens exist,
eight were unreachable at runtime (only exercised by tests). This issue is F8's fix.

## Decisions

**D1 — Bottom navigation, four primary destinations; two screens reached contextually.**
`app.dart`'s `App` widget is not on any class diagram (framework entry point, like
`AppDatabase`'s own omission of drift-generated classes) — no diagram edit is needed to
add a navigation shell around it.

Primary tabs (`NavigationBar`, Material 3):
1. **Balance Sheet** (`BalanceSheetScreen`) — home, unchanged (FR-1).
2. **Record** (`RecordTransactionScreen`).
3. **Transactions** (`TransactionListScreen`).
4. **Budget** (`BudgetOverviewScreen`).

Reached from within a tab, not the bar itself:
- **`AccountFormScreen`, create mode** — a FAB on the Balance Sheet tab.
- **`AccountFormScreen`, edit mode** — tapping an account row on the Balance Sheet tab.
- **`DebtDetailScreen`** — a trailing icon on `RECEIVABLE`/`PAYABLE` rows only (the
  screen is meaningless for `HOLDING` accounts).
- **`SetBudgetScreen`** — an app-bar action on the Budget tab (`BudgetOverviewScreen`
  shows consumption; `SetBudgetScreen` is where the amounts are set — the two belong
  together).
- **`CategoryManagerScreen`, `CurrencyScreen`** — app-bar actions on the Balance Sheet
  tab (settings-shaped, not a daily action).

**D2 — Nothing about any existing screen's behavior changes.** This issue adds
navigation *to* screens; it does not touch what they do once reached. No DAO, provider,
or business-logic file changes.

**D3 — `AccountFormScreen`'s edit-vs-adjust ambiguity is resolved by the tap target,
not a new parameter.** Both modes take an `accountId`; the Balance Sheet row's tap opens
edit mode (rename/regroup/delete) since that is the more general "manage this account"
action. Adjusting the opening amount (UC-03) has no entry point from this shell — it
never had one; `pm/findings.md` doesn't name it as blocked, and inventing one is outside
what was asked.

## Out of scope

- Any change to a screen's own logic, tests, or diagram.
- A dedicated way to reach UC-03's adjust flow (not asked for; can be added later).
- Deep linking, named routes, or state restoration — plain `Navigator.push` is enough
  for a first pass.

## Definition of done

Four commands green from `app/`; a widget test proving every one of the four bottom
destinations renders its screen, and that tapping into `AccountFormScreen` (both modes),
`DebtDetailScreen`, `SetBudgetScreen`, `CategoryManagerScreen` and `CurrencyScreen`
reaches them.
