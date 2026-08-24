# FEAT08-transaction-ux-and-name-block — In/out colors, Record closes to Home, account names hard-block

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request (manual-testing
feedback, round two), items 2, 3 and 4. No UC owns this, same class as FEAT01-07.

**Depends on:** `FEAT06-save-ux-and-uniqueness` — DONE (this issue revises what FEAT06
shipped for the record-save close behaviour and the duplicate-name notice).

## The three asks

*"After creating a transaction, closing the create transaction menu IS needed."*
*"Different colors for transaction in green out red."*
*"Hard block same account name."*

## Decisions

**D1 — Transaction list rows: green for income, red for expense, unstyled otherwise.**
`_TransactionTile` in `transaction_list_screen.dart` colors its title `Text` by
`transaction.kind`: `TransactionKind.income` → a fixed green (`Colors.green.shade700`
light / `Colors.green.shade300` dark — `ColorScheme` has no semantic success color to
borrow, so this is a literal constant, the same way `_defaultSeedColor` is one in
`app.dart`), `TransactionKind.expense` → `colorScheme.error` (already the theme's red,
no new constant needed). The other five kinds (`transfer`, `lend`, `borrow`, `repayment`,
`adjustment`) stay the default text color — each touches two sides at once, so "in" or
"out" is not a fact about the row without picking a viewpoint account, which nothing on
this screen has (UC-09 D3/D6 draws the tile per-row, not per-account). Matches the
existing `TransactionKind` semantics exactly (`transactions_table.dart`: `expense` is
`fromAccountId` set/`toAccountId` null, `income` the reverse) — no new predicate, no
`to_account_id IS NULL` check duplicated here.

**D2 — `RecordTransactionScreen` switches back to the Home tab after a successful save,
replacing FEAT06 D2's form-clear-and-stay.** `RecordTransactionScreen` is reached only as
`AppShell`'s Record tab/FAB (`app.dart`) — it takes a new required `onSaved: VoidCallback`
constructor parameter; `AppShell` passes `() => _select(0)` (index 0 is Home, per its own
`IndexedStack` order). `_save()` still clears the form and fires the write exactly as
FEAT06 shipped it (fire-and-forget `Future<void>`, form cleared so a fast re-entry to this
tab starts blank, not mid-duplicate) — it additionally calls `widget.onSaved()` right
after, switching `_index` to 0. The `recordedMessage` `SnackBar` FEAT06 added stays: it
now surfaces on whichever screen is visible after the switch (Home), which is the same
`ScaffoldMessenger` instance either way — one `Scaffold` roots the whole `IndexedStack`
(`app.dart`). This is "closing the create transaction menu" the way a persistent tab
*can* close: leaving it, not popping a route that was never pushed.

**D3 — Account-name collision becomes a real refusal: `AccountFormScreen`'s create and
edit flows do not write when the typed name collides.** Replaces FEAT06 D3's
warn-and-proceed. `_nameCollides()` is unchanged (case-insensitive against
`accountBalancesProvider`, excluding the account's own id in edit mode); `_save()`'s
create/edit branches change shape: on a collision, show a single-button dialog
(`_showBlockedNotice()`, replacing `_showDuplicateNameNotice()` — new ARB keys
`duplicateAccountNameBlockedTitle`/`duplicateAccountNameBlockedContent`, the existing
`duplicateAccountNameTitle`/`duplicateAccountNameDialogContent` keys retired since
nothing calls them once this lands) and **return without calling
`accountsProvider.notifier`'s write and without popping the route** — the screen stays
open with the name still typed in, so correcting it and saving again is the very next
action available. A non-colliding name still writes and pops exactly as FEAT06 shipped.
Adjust mode is untouched (never touches `name`, D3 never ran there either).

**D4 — This is a deliberate, argued exception to NFR-4, recorded where the NFR lives.**
`docs/fr-nfr.md`'s NFR-4 fit criterion currently reads *"no user action in the app is
refused... the count is the test, so a block cannot be added quietly"* — exactly the
gate this decision has to clear, not route around. At close: add one line to that
section naming this as the sole counted exception (mirroring how the old FR-16 budget
lock was once "the one" before it was removed 2026-08-20), citing the owner's own
2026-08-24 answer (*asked directly whether duplicate account names should warn-and-
proceed or hard-block; owner: "Hard block for real"*) as the argument. `decisions.md`
gets the same entry. This is the one control in the entire app that refuses — every
other screen's zero-refusals discipline (delete, save-with-empty-fields, same-account
transfer, etc.) is untouched by this issue.

## Out of scope

- Any other field's uniqueness (category names, budget group names — not asked for,
  same scope line FEAT06 drew).
- Recoloring anything other than `TransactionListScreen`'s rows (not the Record form,
  not `AccountsScreen`'s balances — not asked for).
- Popping `AccountFormScreen`/closing anything on a successful, non-colliding save —
  unchanged from FEAT06.
- `TransactionListScreen`'s edit sheet's own close-on-save behaviour — unchanged
  (already pops correctly, FEAT06).

## Definition of done

Four commands green. Widget tests: an income row renders in the green style, an expense
row in `colorScheme.error`, a transfer row in the default color; `RecordTransactionScreen`
calls its `onSaved` callback after a successful save (fake callback assertion, not a real
`AppShell` mount); `AppShell` switches to index 0 when `RecordTransactionScreen`'s
`onSaved` fires; `AccountFormScreen`'s create and edit flows do **not** call
`accountsProvider.notifier`'s write and do **not** pop when the typed name collides
(case-insensitively) with another non-deleted account, and **do** write and pop when it
does not. `git diff --stat app/drift_schemas/` empty. `docs/fr-nfr.md` NFR-4 and
`context/index/decisions.md` both carry the exception before commit.
