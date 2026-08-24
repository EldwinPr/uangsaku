# FEAT14-debt-writeoff-and-adjust-entry — "Ikhlaskan" actually writes off the debt, the Record FAB turns primary, and UC-03's adjust flow finally gets an entry point

**Status:** DONE 2026-08-24. Three small, independent owner requests bundled into
one issue because they all touch the accounts module and are each too small to be
their own issue. No UC owns any of the three, same class as FEAT01-13. `insertAdjustment`
(UC-03) already exists and is untouched by D1/D3 — this issue only gives it a route in
and reuses its arithmetic in D1.

## Decisions

**D1 — The settle button actually writes off the remaining balance now, instead of
only flipping a flag.** Owner: *"tandai lunas doesn't do anything... right now lunas
doesn't change balance."* New `AccountDao.writeOffDebt(int accountId)`: in one drift
transaction — (a) computes the account's current derived balance with the exact same
`customSelect` expression `insertAdjustment` already uses; (b) get-or-creates a
`Categories` row named literally `"Ikhlaskan"` (a real category name, not a
localized string — user-visible category names in this app are always plain data,
never translated, the same way a user-typed account name never translates; searched
case-insensitively against existing categories in Dart, the same in-memory-compare
shape `AccountFormScreen._nameCollides` already uses, not a SQL `LOWER()` clause);
(c) inserts one `adjustment`-kind transaction for `0 − currentBalance` (i.e. drives the
balance to exactly zero), `toAccountId: accountId`, tagged with that category's id;
(d) sets `settled: true`, `settledAt: today()` — the same flag `setSettled()` already
sets, folded into this one transaction rather than a second call. `AccountsNotifier`
gains `writeOffDebt({required int accountId})` forwarding to it, returning nothing
(the read/write asymmetry, unchanged).

**D2 — The button's label changes, English and Indonesian differently, since the joke
is Indonesian-specific.** New ARB keys replace `markSettled`: `writeOffDebtButton` —
`id`: `"Ikhlaskan"` (the owner's own word — a culturally loaded "let it go, forgive it
sincerely," not a literal translation of "settled"); `en`: `"Write it off"` (plain,
functional — the joke doesn't carry across languages, so English gets the honest
description of what the button now does instead of a forced pun). `DebtDetailScreen`'s
`FilledButton.icon` calls `writeOffDebt` instead of `markSettled`; `Icons.check` stays
(still the "confirm/complete" icon, still accurate). `AccountsNotifier.markSettled`/
`AccountDao.setSettled` are **not removed or changed** — `setSettled` is message 5 on
`seq-uc10-debt-progress.drawio`, a real UC-10 primitive with its own passing test
(`debt_progress_test.dart`); this issue only stops `DebtDetailScreen`'s one button
from calling it, it does not delete a diagrammed method.

**D3 — `AccountFormScreen`'s edit flow gains an "Adjust balance" button, the first
real entry point `AccountFormMode.adjust` has ever had.** Owner, mid-conversation:
*"you also remind me for balance adjustment from the balance page, that is quite
important."* `insertAdjustment`/`AccountFormMode.adjust` have existed since UC-03 but
were never reachable outside tests (FEAT02 plan D3 explicitly left this out of scope
at the time). `_buildEditFlow` gains one `OutlinedButton.icon` below the existing
delete button, new ARB key `adjustBalanceButton` (`en`: `"Adjust balance"`, `id`:
`"Sesuaikan saldo"`), navigating to `AccountFormScreen(mode: AccountFormMode.adjust,
accountId: widget.accountId)` — the exact same route `DebtDetailScreen`'s own
in-progress figures already imply exists, just never linked to. No new screen, no new
DAO method — purely a missing navigation edge.

**D4 — The docked Record FAB turns `colorScheme.primary`, not `colorScheme.tertiary`.**
Owner: *"the + button primary color circle"* — confirmed to mean the bottom-nav
docked FAB, not `AccountsScreen`'s add-account FAB. It is already circular by default
(`FloatingActionButton()`'s default shape, unlike `.extended`) — this is a color-only
change: `backgroundColor: colorScheme.primary`, `foregroundColor: colorScheme.onPrimary`.

## Out of scope

- Any change to `insertAdjustment()` itself, or to UC-03's own (still-unreachable-
  elsewhere) semantics — `writeOffDebt` reuses its arithmetic, it does not modify it.
- A confirmation dialog before writing off — NFR-4's zero-refusals discipline applies
  here exactly as it does to every other consequential control in this app (delete,
  settle, save-over-empty-fields): one tap, no "are you sure."
- Any other FAB in the app (`AccountsScreen`'s add-account FAB, `RecordTransactionScreen`'s
  Save FAB) — only the docked Record FAB was named.
- Reusing the "Ikhlaskan" category name across locales, or making it user-configurable —
  it's a fixed, literal string, the joke itself.

## Definition of done

Four commands green. Widget/DAO tests: `writeOffDebt` on an account with a nonzero
balance inserts one `adjustment` transaction whose `amount` drives the derived balance
to exactly `0`, tagged with a category named `"Ikhlaskan"`; calling it twice reuses
the same category row (no duplicate `"Ikhlaskan"` categories); it also sets
`settled: true`. `DebtDetailScreen`'s button shows the new label and its own widget
test confirms it calls `writeOffDebt`, not `markSettled` (which the notifier keeps for
`markSettled` may be removed only if nothing else calls it — check before deleting).
`AccountFormScreen`'s edit flow's new button navigates to `AccountFormMode.adjust`
with the right `accountId`. The Record FAB's `backgroundColor`/`foregroundColor` read
`colorScheme.primary`/`onPrimary`. `git diff --stat app/drift_schemas/` empty — no
schema change (categories/transactions/accounts tables are unchanged shape, this
issue only writes rows into columns that already exist).
