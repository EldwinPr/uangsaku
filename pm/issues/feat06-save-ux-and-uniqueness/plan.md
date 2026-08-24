# FEAT06-save-ux-and-uniqueness — Close/confirm on save, a recognizable save icon, account-name uniqueness

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request, the last item from the same
manual-testing feedback round. No UC owns this, same class as FEAT01-05.

**Depends on:** `FEAT05-category-picker` — DONE.

## The original report, split into three concrete fixes

*"After creating account and transaction, it doesn't close the new account/transaction
thing, so [you] can click it multiple times, the thing is there is no warning that the
transaction happened. One more thing: save icon needs to be changed to something more
recognizable, since floppy disk is niche to the newer generation."* Plus, from earlier in
the same round: *"no unique holdings account name."*

## Decisions

**D1 — Every `Icons.save` becomes `Icons.check`.** Four sites, found by grep, all of
them: `account_form_screen.dart`, `set_budget_screen.dart`,
`record_transaction_screen.dart`, `transaction_list_screen.dart`'s edit sheet. Simple,
universally understood, no ambiguity with any other icon already in use on those
screens.

**D2 — "Close on save" means different things depending on how the screen is reached,
and the dialogs (`CategoryManagerScreen`'s add/rename, `SetBudgetScreen`'s add/rename
group) already close themselves correctly** — they're `showDialog<String>` returning the
typed value via `Navigator.pop(controller.text)`, and the caller performs the write only
after the dialog is gone. **Not in scope**, already correct. The actual gap is in four
places:

- **`AccountFormScreen`** (create/edit/adjust — always reached via `Navigator.push`):
  save now calls `Navigator.of(context).pop()` immediately after firing the write (the
  write is `Future<void>`, fire-and-forget by design — `riverpod.md`'s read/write
  asymmetry already means nothing on this screen ever needed to await a result). Popping
  is what makes a second tap on the same button impossible, without disabling anything
  (NFR-4 is untouched — the control was never refused, the screen just isn't there to
  tap a second time). A `SnackBar` on the screen returned to (`AccountsScreen` or
  `BalanceSheetScreen`, whichever pushed it) is optional polish, not required — the
  screen's own re-emission of the changed list is already the existing confirmation
  mechanism.
- **`TransactionListScreen`'s `_EditSheet`** (a `showModalBottomSheet`): same fix — save
  calls `Navigator.of(context).pop()` right after firing `edit(...)`, closing the sheet.
- **`RecordTransactionScreen`** (a persistent *tab*, not pushed — there is nothing to
  pop). Two changes instead: (a) **clear the form back to its initial blank state**
  immediately after firing the write, so a fast second tap submits a blank/default entry
  rather than a silent duplicate of the same data (still legal to submit per NFR-4 — this
  is not a refusal, it changes what a re-tap *does*, not whether it's allowed); (b) show a
  `SnackBar` confirming the write fired (e.g. "Recorded" / localized). This is the
  screen the original report names directly.
- **`SetBudgetScreen`**'s per-row save icon: nothing to close (it's an inline list row,
  not a form to leave) — add a brief `SnackBar` confirmation only.

**D3 — Account-name uniqueness: warn, never block, same shape as the currency-relabel
notice.** `AccountFormScreen`'s create and edit flows (not adjust — that flow never
touches `name`) check the typed name against the currently-loaded `accountBalancesProvider`
list (already watched or watchable on this screen — no new DAO method, no new query,
case-insensitive comparison, excluding the account's own id when editing) before firing
the write. If another **non-deleted** account already has that name: show a one-button
acknowledge-and-proceed dialog (`AlertDialog`, single "OK", no cancel — identical shape
to `SettingsScreen`'s currency-relabel notice), then the write and the close-on-save from
D2 both still happen, unconditionally, exactly as `SettingsScreen`'s `setCurrency()` call
sits outside its own `opt` box. **This is a warning, not a validation rule** — NFR-4's
zero-refusals fit criterion forbids anything stronger, and nothing here disables the save
control or blocks the write.

**D4 — Nothing else about NFR-4 changes.** No new disabled state anywhere. No new schema,
no new DAO method beyond nothing (D3 reuses an existing provider).

## Out of scope

- Any change to what a save/create/delete write actually does or which fields it touches.
- `CategoryManagerScreen`/`SetBudgetScreen`'s add/rename **dialogs** — already close
  correctly (D2).
- Uniqueness for anything other than `Account.name` (category names, budget group names,
  etc. — not asked for).
- Undo/toast-with-undo — a plain confirmation is what was asked for.

## Definition of done

Four commands green. Widget tests: `AccountFormScreen`'s save pops the route (create,
edit and adjust modes); `TransactionListScreen`'s edit sheet closes on save;
`RecordTransactionScreen`'s form clears and a confirmation shows after a successful
save; `SetBudgetScreen`'s row save shows a confirmation; every `Icons.save` site now
reads `Icons.check`; creating/editing an account with a name that collides
(case-insensitively) with another non-deleted account shows the one-button warning and
still saves — and a non-colliding name never shows it. `git diff --stat
app/drift_schemas/` empty.
