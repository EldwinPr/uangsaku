# FEAT16-admin-fee-toggle — A manual admin-fee toggle on Transfer/Lend/Borrow/Repay

**Status:** DONE 2026-08-24. Owner's direct request (manual-testing feedback,
round seven): *"for transfer or some transactions make sure there is admin fee toggle
manual input."* Clarified via one `AskUserQuestion` round. No UC owns this, same class
as FEAT01-15.

**Depends on:** `UC04-record-money-movement` (the form and the six writable kinds this
issue adds a toggle to).

## Decisions

**D1 — Scope: Transfer, Lend, Borrow and Repay — not Expense/Income.** Owner's
clarified answer: any two-account movement of the owner's own or a person's money can
carry a real bank/transfer fee; a plain expense or income has no second account to
have moved money *between*, so no toggle appears there. `_Flow.expense`/`_Flow.income`
are untouched.

**D2 — Mechanics: the fee writes as a second, linked `expense` transaction — the main
transaction posts its full typed amount unchanged.** Owner's clarified answer: a
second `TransactionKind.expense` row, `amount` = the manually typed fee,
`fromAccountId` = **the same account already debited by the main transaction** (per
flow: Transfer's source, Lend's own wallet, Borrow's PAYABLE/debt account, Repay's
whichever side `debtIsSource` resolves to — these are already computed locally in
`_save()`), `occurredOn` = the same date, tagged with the fee category (D3). This
keeps every existing balance/budget/spending query correct with zero changes: the fee
is real spending, so it must exist as a real `to_account_id IS NULL` row for FR-8/FR-9
and UC-12's budget consumption to see it, exactly like any other expense. The main
transaction's own `amount` is never adjusted by the fee — the two are independent
rows, not one row split into two fields. If the flow's resolved `fromAccountId` is
null (an empty account pool), the fee row is skipped rather than written with a null
side — an admin fee with no account to charge is not spending anywhere yet, unlike the
main transaction, which the existing empty-pool handling already lets proceed with a
null side (plan D9 of UC-04's own plan, still true here).

**D3 — Fee category: a new fixed "Admin Fee" category, get-or-created, plain data —
not localized.** Owner's clarified answer, and the same rule FEAT14's "Ikhlaskan"
category already established (`decisions.md` 2026-08-24): a category name is
user-visible *data*, not chrome, so it is never routed through `AppLocalizations` —
kept as the literal string `"Admin Fee"` in both locales. New `TransactionDao`
private helper doing an in-memory case-insensitive scan against existing categories
(mirrors `AccountFormScreen._nameCollides` / FEAT14's `_ikhlaskanCategoryId()` shape,
not a SQL `LOWER()`), get-or-creating the row and reusing it on every subsequent fee
write — never a second `"Admin Fee"` row.

**D4 — Both rows write atomically, in one drift transaction.** New
`TransactionDao.insertWithAdminFee({required TransactionKind kind, required int
amount, required DateTime occurredOn, int? fromAccountId, int? toAccountId, String?
note, int? feeAmount})`: wraps the existing `insert()` (the main transaction, kind as
today) and — only when `feeAmount != null && feeAmount != 0 && fromAccountId !=
null` — a second `insert(kind: expense, amount: feeAmount, fromAccountId:
fromAccountId, categoryId: <get-or-created Admin Fee id>, occurredOn: occurredOn)`
inside one `_db.transaction()` block, so a fee is never written without its main
transaction landing too (or vice versa). `TransactionsNotifier.transfer()`/`lend()`/
`borrow()`/`repay()` each gain one new optional `int? feeAmount` parameter, forwarded
straight through — `recordExpense`/`recordIncome`/`edit`/`delete` are untouched, and
`TransactionDao.insert()` itself is untouched (still the one-row primitive
`insertWithAdminFee()` calls twice, not replaced).

**D5 — UI: one checkbox + one manual amount field, shown only for the four in-scope
flows.** `RecordTransactionScreen` gains a persistent `Row(Checkbox, Text)` — new ARB
key `adminFeeCheckboxLabel` — rendered right after the amount field, visible only when
`_flow` is transfer/lend/borrow/repay; checking it reveals a manual `TextField` (new
ARB key `adminFeeAmountLabel`, reusing the existing `amountHintMinor` hint) for typing
the fee in the same minor-unit convention every other amount field already uses. On
`_save()`, when the flow is in scope and the checkbox is checked, the typed fee text
parses the same way the main amount already does — `int.tryParse(...) ?? 0` (F7
precedent, NFR-4: an empty or unparseable fee proceeds as `0`, i.e. the toggle stays
checked but writes no fee row per D2's `feeAmount != 0` guard, never a refusal) — and
is passed to the notifier call already firing for that flow. The checkbox and its
typed amount reset to unchecked/blank on every save-and-clear cycle and every flow
switch, the same way every other per-flow field already does (`_save()`'s existing
`setState` reset block).

**D6 — `class-transactions.drawio` updated in the main session before dispatch.**
`TransactionDao`'s box gains `insertWithAdminFee() · FEAT16` as a new method line
(height 240→260); `CategoryDao`'s box below it shifts down to keep its 20px gap
(y=440→460); the subtitle gains `, FEAT16.`. No new class, no new edge — the fee write
reaches `Categories` through the same `AppDatabase` edge `insert()` already implies
for `categoryId`, exactly the way `AccountDao`'s edge already covered FEAT14's
`writeOffDebt()`. Render exported and visually verified — no overlap with the band
border or the box below.

## Out of scope

- A toggle on Expense/Income (D1 — no second account to have a fee "between").
- Deriving the fee automatically from a percentage or a bank preset — manual typed
  input only, per the owner's own wording ("manual input").
- Editing an already-recorded fee, or `TransactionListScreen`'s edit sheet gaining the
  same toggle — only the recording form was named.
- Any change to `TransactionDao.insert()`, `update()`, `delete()`, or any of
  `recordExpense`/`recordIncome`/`edit`/`delete` — untouched.
- Un-linking or cascading a fee row when its main transaction is later edited or
  deleted (UC-09) — the two rows are independent once written, same as any other pair
  of unrelated ledger rows; deleting the main transaction does not delete its fee.

## Definition of done

Four commands green. DAO tests: `insertWithAdminFee` with a nonzero `feeAmount` and a
non-null `fromAccountId` writes two rows — the main kind unchanged and one `expense`
row for the fee amount tagged with a category literally named `"Admin Fee"`; calling
it twice reuses the same category row (no duplicates); a `feeAmount` of `null` or `0`
writes only the main row; a non-null nonzero `feeAmount` with a null `fromAccountId`
also writes only the main row (fee skipped, D2). Widget tests: the checkbox +
manual-amount field render for Transfer/Lend/Borrow/Repay and do NOT render for
Expense/Income; checking it and typing a fee, then saving, drives `transfer`/`lend`/
`borrow`/`repay` to include the typed `feeAmount`; leaving it unchecked passes no fee
regardless of stray text in the (hidden) field; the checkbox and field reset after
save and after switching flows. `git diff --stat app/drift_schemas/` empty — no schema
change, this issue only writes rows into columns that already exist.
