# FEAT04-nav-redesign — Five-tab bottom nav; Record as a colored circular quick action

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request, second item from the same
manual-testing feedback round as `FEAT03`. No UC owns this, same class as FEAT01/02/03.

**Depends on:** `FEAT03-settings-and-i18n` — DONE (every new string this issue adds
must go through the same `AppLocalizations` mechanism, not a hardcoded string).

## Decisions

**D1 — `AccountsScreen` is a new screen, split out of `BalanceSheetScreen`.**
`BalanceSheetScreen` currently renders both the four top-level figures *and* the
per-account list (with its FAB, row-tap-to-edit, and debt-details icon). Split:

- `BalanceSheetScreen` keeps only the four figures (`financialPositionProvider`) —
  nothing else moves here.
- New `app/lib/src/accounts/accounts_screen.dart` — `AccountsScreen` gets everything the
  account list currently does: `accountBalancesProvider`, the FAB (→
  `AccountFormScreen()` create mode), row tap (→ edit mode), the `RECEIVABLE`/`PAYABLE`
  trailing icon (→ `DebtDetailScreen`). Copy the behavior verbatim — this is a screen
  split, not a redesign of what either screen does.
- The two app-bar actions (Categories, Settings) stay on `BalanceSheetScreen`'s app bar
  — it remains the app's primary/first screen, and these are app-level, not
  account-specific.

**D2 — Five tabs, in this order:** Home (renamed from "Balance Sheet" — concise, and
what it is now that the account list moved out), Accounts, **Record** (center, see D3),
Transactions, Budget. `AppShell`'s `IndexedStack` grows to five children in this order;
index 2 is `RecordTransactionScreen`.

**D3 — Record becomes a colored circular quick-action button, not a normal nav
destination.** Standard Material pattern: `Scaffold.floatingActionButton` at
`FloatingActionButtonLocation.centerDocked`, a circular FAB in a distinct color
(`Theme.of(context).colorScheme.tertiary` — distinguishes it from the primary-seeded
nav bar without hardcoding a color FEAT03's theme picker doesn't control), tapping it
sets the `IndexedStack` index to Record's (2), same mechanism as tapping any other
destination. `bottomNavigationBar` becomes a `BottomAppBar` with `shape:
CircularNotchedRectangle()` so the FAB nests into a notch, two destinations on each
side (Home, Accounts | Transactions, Budget) via `IconButton`s reading the same
`_index` state `NavigationBar` used — visual selection state (which icon is
"selected"/tinted) preserved the same way `NavigationBar` showed it.

**D4 — Every new/changed label goes through `AppLocalizations`.** No hardcoded strings
in the new `AccountsScreen`, the renamed "Home" tab label, or any new tooltip — `FEAT03`
just built the mechanism, this issue is its first real consumer beyond FEAT03 itself.

**D5 — Nothing about NFR-4 changes.** No new refusals; the FAB and every nav destination
are always tappable.

## Out of scope

- Category autocomplete picker — next issue.
- Save-flow UX, account-name uniqueness — issue after that.
- Any change to what `BalanceSheetScreen`'s four figures compute, or what
  `AccountFormScreen`/`DebtDetailScreen` do once reached.

## Definition of done

Four commands green. Widget tests: all five destinations render their screen (Home,
Accounts, Record, Transactions, Budget); the FAB opens Record; `AccountsScreen`'s FAB/row
tap/debt icon behave exactly as `BalanceSheetScreen`'s did before the split (port the
existing `app_shell_test.dart` assertions to target `AccountsScreen` instead of
`BalanceSheetScreen` where they tested the account list); `BalanceSheetScreen` no longer
renders the account list.
