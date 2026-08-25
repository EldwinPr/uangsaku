# FEAT19-payable-auto-negate — A PAYABLE account's amount is typed positive, stored negative automatically

**Status:** DONE 2026-08-25. Owner's direct request (manual-testing feedback,
round nine): *"utang input must not be -, automatically -."* Clarified via one
`AskUserQuestion` round. No UC owns this, same class as FEAT01-18.

**Depends on:** `UC02-add-account` (the opening-amount field) and
`UC03-adjust-account` (the target-amount field) — this issue changes what both
already-shipped fields compute before writing, not their write path itself.

## Decisions

**D1 — This reverses UC02 plan D6's "no group-dependent sign transformation" for
`PAYABLE` specifically, and only for `PAYABLE`.** D6 was a deliberate original
ruling (*"the app applies no group-based negation"*, cited from FR-4's "it just holds
a negative amount" and the sequence diagram's message 2→3 showing no transformation
between the form and `insert(account)`) — this issue is the owner revisiting that
choice after living with it: typing a leading `-` for every debt was worse UX than
just always treating `PAYABLE`'s amount field as a magnitude. `RECEIVABLE`/`HOLDING`/
`PERSON` are **unaffected** — they keep accepting a signed number exactly as today
(`HOLDING` can legitimately be negative/overdrawn; `RECEIVABLE` is a magnitude by
construction already; `PERSON` genuinely needs both signs since its direction isn't
fixed, FEAT11 D2).

**D2 — Applies to both the create flow's opening-amount field and the adjust flow's
target-amount field (confirmed via `AskUserQuestion`), each independently.**
`AccountFormScreen._save()`'s create branch: `final rawOpening =
int.tryParse(_openingAmountController.text) ?? 0; final openingAmount = _group ==
AccountGroup.PAYABLE ? -rawOpening.abs() : rawOpening;` — `.abs()` first so a typed
value keeps the same negation result whether or not the owner still types a leading
`-` out of habit (defensive against double-negation, not a validation gate — nothing
is refused, F7's `int.tryParse(...) ?? 0` precedent is unchanged). The adjust flow
needs to know the account's *stored* group (it isn't picked on this screen —
`_buildAdjustFlow` shows no group selector) to decide whether to negate: read it off
the already-watched `accountBalancesProvider` list by matching `widget.accountId`,
the same lookup `_buildAdjustFlow` already does for `currentAmount`. When that
account's group is `PAYABLE`, the typed target amount is treated the same way — a
positive magnitude auto-negated before being passed to `adjustAccount`'s
`targetAmount`. `AccountDao.insertAdjustment()` itself is untouched — it still
receives a plain signed `int` and still computes `diff = targetAmount - current`
exactly as it always has; only what the screen hands it changes.

**D3 — No UI/keyboard change, no new ARB key, no hint-text change.** The field stays
`TextField` with `keyboardType: numberWithOptions(signed: true)` for every group,
unconditionally — simplicity over a conditionally-different keyboard, and the
existing hint strings (`openingAmountHint`, `targetAmountHint`) are left as they are.
The behavior change alone (a typed `500000` under `PAYABLE` silently becomes `-500000`
on save) satisfies *"must not be -, automatically -"* without needing the owner to
notice anything different about the field itself until they check the result.

## Out of scope

- `FEAT18-account-sections-and-sign-coloring` (the separate, unrelated display
  change to `AccountsScreen` — different file, tracked as its own issue).
- Editing an existing `PAYABLE` account's opening amount directly — `AccountFormScreen`
  never shows `opening_amount` in edit mode (UC02B plan D3, unchanged); correcting it
  stays the adjust flow's job, covered by D2 above.
- `RecordTransactionScreen`'s Borrow flow amount field — already always entered
  positive; direction there lives entirely in which account occupies `fromAccountId`
  vs `toAccountId` (UC-04 plan D5), never in the amount's sign, so nothing there needs
  to change.
- Any change to `AccountDao.insertAdjustment()`'s own arithmetic, or to
  `AccountsNotifier.addAccount`/`adjustAccount`'s signatures — both keep accepting a
  plain signed `int`, unchanged; only the screen's computation before the call
  changes.

## Definition of done

Four commands green. Widget tests: creating a `PAYABLE` account and typing `500000`
(no leading `-`) into the opening-amount field results in a stored `opening_amount`
of `-500000`; typing `-500000` under the same `PAYABLE` selection also results in
`-500000` (not `+500000` — the `.abs()`-first guard against double-negation); creating
a `HOLDING`/`RECEIVABLE` account and typing `500000` still stores `500000` unchanged
(no negation applied to non-`PAYABLE` groups). Adjust flow: opening the adjust form
for an existing `PAYABLE` account and typing a target of `300000` calls
`adjustAccount` with `targetAmount: -300000`; the same flow against an existing
`HOLDING`/`RECEIVABLE`/`PERSON` account passes the typed value through unchanged.
`git diff --stat app/drift_schemas/` empty — no schema change, this issue only
changes what value is computed before an already-shipped write path is called.
