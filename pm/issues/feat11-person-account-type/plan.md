# FEAT11-person-account-type — A fourth account type that can owe or be owed, and inline account creation from Lend/Borrow/Repay

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request (manual-testing feedback,
round four), resolved via three follow-up answers: (1) `Person` is a new 4th
`AccountGroup` alongside `HOLDING`/`RECEIVABLE`/`PAYABLE`, additive — those three are
untouched, not replaced; (2) `RecordTransactionScreen`'s Repay flow shows an explicit
"who paid" toggle when the picked account is a `Person` (plain wording, not
"utang"/"piutang" jargon); (3) the Lend/Borrow/Repay person-picker becomes
autocomplete-with-inline-create (like the category picker, FEAT05), with a checkbox —
unchecked creates the flow's normal type (`Lend`→`RECEIVABLE`, `Borrow`→`PAYABLE`),
checked creates `Person`. No UC owns this, same class as FEAT01-10.

**Post-close fix, 2026-08-24, same day:** the owner reported the group `SegmentedButton`
overflowing with all four values shown ("the selection in create account the 4 side by
side its overflowing") — the raw `AccountGroup.name` (`"RECEIVABLE"`, `"HOLDING"`, etc.)
wrapped mid-word once a fourth segment narrowed each one's share of the row. Fixed with
short, localized labels (new `_groupLabel`, four new ARB keys) instead of the raw enum
name — the one place on this screen that wasn't already localized — plus
`showSelectedIcon: false` on both `SegmentedButton`s, since the selected segment's
check icon was still enough overhead to wrap even the shortest label ("Dompet"). Verified
live on a running emulator (adb screenshots, both the create and edit flows) before and
after the fix, not just by reading the diff. See `pm/log.md`'s 2026-08-24 entry for the
full account, including the two other things confirmed working correctly the same
session (the Repay direction toggle and the inline-create checkbox — both already
functioning as designed, the owner just hadn't triggered the conditions for either to
appear yet).

**Depends on:** `FEAT08-transaction-ux-and-name-block` — DONE (last issue that touched
`AccountGroup`/`AccountFormScreen`).

## Why this isn't a schema migration

`Accounts.group` is `textEnum<AccountGroup>()()` — a plain `TextColumn`, no `CHECK`
constraint (`accounts_table.dart`). Adding `PERSON` as a fourth legal value is a
Dart-enum-only change: no new column, no new table, nothing for
`dart run drift_dev make-migrations` to capture, no `schemaVersion` bump. Only
`dart run build_runner build` (regenerates the enum converter) is needed — confirm this
before writing code, don't invent a migration step that doesn't apply here.

## Decisions

**D1 — `AccountGroup` gains a fourth value, `PERSON`.** `accounts_table.dart`:

```dart
enum AccountGroup {
  HOLDING,
  RECEIVABLE,
  PAYABLE,

  /// A person whose balance can swing either way over time — some months
  /// they owe you, some months you owe them. Unlike RECEIVABLE/PAYABLE,
  /// which are fixed at creation, PERSON is bucketed into "owed to me" or
  /// "owed by me" (FR-1) by the SIGN of its current balance, re-evaluated
  /// on every read (D2). Owner's direct request, 2026-08-24.
  PERSON,
}
```

**D2 — `AccountDao.watchPosition()`'s SQL buckets `PERSON` by balance sign, not by a
fixed group.** `owed_to_me` becomes `SUM(RECEIVABLE balances) + SUM(PERSON balances
WHERE balance > 0)`; `owed_by_me` becomes `SUM(PAYABLE balances) + SUM(PERSON balances
WHERE balance < 0)` (kept signed-negative, matching `PAYABLE`'s existing convention —
`owedByMe` is already always ≤ 0 in `FinancialPosition`, `docs/enums.md`). `net` is
unchanged (`SUM(balance)` over every account regardless of group — a `PERSON`
account's balance was always counted there). One new bound variable
(`AccountGroup.PERSON.name`) added to the existing three; `spendable`'s `CASE WHEN`
is untouched (`PERSON` never contributes to it, same as `RECEIVABLE`/`PAYABLE` today).
`watchBalances()` is untouched — it already returns every account's raw group +
balance regardless of value, so a `PERSON` row just flows through as-is.
`watchDebtProgress()` is untouched — already keyed purely by `accountId`, no group
filter (`remaining: ABS(balance)` and `paid: SUM(repayment rows touching this
account)` both already work for any account regardless of group).

**D3 — `group_style.dart` gains a fourth color/icon: `colorScheme.tertiary` /
`Icons.sync_alt`.** Deliberately distinct from `RECEIVABLE`'s green and `PAYABLE`'s
red (`colorScheme.error`) — `PERSON` has no fixed direction, so it gets no fixed
directional color; `sync_alt` (bidirectional arrows) reads as "can flip," unlike
`RECEIVABLE`'s `call_received`/`PAYABLE`'s `call_made`, which are one-directional by
design.

**D4 — `AccountFormScreen`'s group picker needs no code change** — its
`SegmentedButton` already iterates `AccountGroup.values`, so `PERSON` appears there
automatically. Its description line (FEAT09 D3) does need a new case: new ARB key
`accountGroupDescriptionPerson` (*"A person whose balance can go either way — you
might owe them, or they might owe you, depending on what's happened."* / plain
Indonesian equivalent, no "utang"/"piutang" jargon per the owner's stated preference),
wired into `_groupDescription`'s `switch`. `HelpScreen`'s accounts section
(`FEAT10 D1`, iterates `AccountGroup.values`) picks up the same new case the same way
— its existing per-group `switch` gains one arm reusing this same key, not a new one.

**D5 — `AccountsScreen`'s debt-detail entry point extends to `PERSON` rows.** The
existing condition (`group == RECEIVABLE || group == PAYABLE`) gains `|| group ==
PERSON` — `DebtDetailScreen` itself needs **no** change (D2 already established it's
fully group-agnostic: keyed by `accountId`, no group branching anywhere in it).

**D6 — `personDebtChoices()` (`record_transaction_screen.dart`) extends to include
`PERSON`.** The existing filter (`RECEIVABLE || PAYABLE`) gains `|| PERSON` — this is
the pool every one of Lend/Borrow/Repay's person-pickers draws from.

**D7 — The Lend/Borrow/Repay person-picker becomes autocomplete-with-inline-create,
mirroring `_CategoryAutocompleteField`'s shape (FEAT05 D1/D2) but backed by
`Accounts`.** New private widget `_PersonAccountField` in
`record_transaction_screen.dart` (duplicated there, not shared with
`_CategoryAutocompleteField` — different backing data, same shape, matching FEAT05's
own precedent of not sharing across screens):
- Options: `personDebtChoices(accounts)` mapped to `(id, name)` records, same as the
  category field's option shape.
- Typing an existing name (case-insensitive) selects it, identical to the category
  field.
- Typing a name matching nothing shows a "Create '{name}'" suggestion **plus a
  checkbox**, new ARB key `createPersonCheckboxLabel` (*"New person, balance can go
  either way"* / plain Indonesian, no jargon) — unchecked, creating writes an account
  in the flow's contextual default group (`Lend` → `RECEIVABLE`, `Borrow` → `PAYABLE`,
  passed in by the parent as `defaultGroupWhenUnchecked`); checked, it writes `PERSON`
  regardless of context. The checkbox is **not shown at all in the `Repay` flow** —
  there is no sensible "normal" default there (you cannot repay a debt that was never
  established), so `Repay`'s inline-create always writes `PERSON`
  (`showCheckbox: false`, `defaultGroupWhenUnchecked: PERSON` effectively fixed).
  `openingAmount: 0` for every inline-created account — the transaction that triggered
  the creation is what establishes its first balance movement.
- Resolution after creation follows the exact `_pendingCreateName` /
  `didUpdateWidget` / `addPostFrameCallback` pattern `_CategoryAutocompleteField`
  already ships (FEAT05, the setState-during-build fix) — `AccountsNotifier.addAccount`
  returns nothing to the screen either (the read/write asymmetry), so the field
  resolves the same way: match the new name in the next `accountPickerProvider`
  emission.

**D8 — Repay direction: inferred from group when unambiguous, an explicit toggle when
it isn't.** `_Flow.repay`'s existing `debtIsSource = debt?.group ==
AccountGroup.RECEIVABLE` line stays **exactly as-is** for `RECEIVABLE`/`PAYABLE`
accounts — still fully unambiguous, no reason to touch a working rule. When the picked
account's group is `PERSON`, a new explicit radio/toggle appears (only then, not
always — showing it for `RECEIVABLE`/`PAYABLE` would be a redundant control asking a
question the group already answers), two new ARB keys `repayDirectionTheyPaidMe`
(*"They paid me"*) and `repayDirectionIPaidThem` (*"I paid them"*) — plain wording,
explicitly not "piutang"/"utang" (owner: *"i dont know the correct word so it's easy
to understand"*). Pre-selected from the account's **current balance sign** as a
starting suggestion only (positive balance → pre-select "They paid me"; negative or
zero → "I paid them") — never silently trusted, the owner can always change it before
saving (owner's explicit answer: ask, don't just infer). `debtIsSource` for a `PERSON`
account resolves from this toggle's state instead of the group check.

## Out of scope

- Any change to `RECEIVABLE`/`PAYABLE`'s existing behavior, color, icon, or SQL
  bucketing — those two stay exactly as they are today.
- Migrating any existing `RECEIVABLE`/`PAYABLE` account to `PERSON` — the owner's
  answer was additive, not a replacement; no bulk re-labeling tool.
- Inline-create for the Transfer flow's two account pickers, or for the wallet
  ("own account") side of Lend/Borrow/Repay — only the person/debt side gets the new
  widget, matching exactly what was asked.
- Any change to `AccountsScreen`'s row rendering beyond the debt-detail icon
  condition (D5) — a `PERSON` row still shows the raw `group.name` subtitle, same as
  every other group today (not a localization pass).
- A drift migration of any kind — see "Why this isn't a schema migration" above.

## Definition of done

Four commands green (`app/`: `dart run build_runner build
--delete-conflicting-outputs`, `dart format --set-exit-if-changed .`, `flutter
analyze`, `flutter test`). `git diff --stat app/drift_schemas/` empty — confirms D1
really didn't need a migration. Widget/DAO tests: `watchPosition()` — a `PERSON`
account with a positive balance lands in `owedToMe`, not `spendable` or `owedByMe`; one
with a negative balance lands in `owedByMe` (signed-negative, matching `PAYABLE`'s
convention); `net` includes it either way. `group_style_test.dart` gains the fourth
mapping. `AccountFormScreen` shows the `PERSON` description when that segment is
picked. `AccountsScreen` shows the debt-detail icon on a `PERSON` row.
`personDebtChoices()` includes `PERSON` accounts. `_PersonAccountField`: typing a new
name with the checkbox unchecked creates the flow's default group (assert both Lend→
RECEIVABLE and Borrow→PAYABLE); checked creates `PERSON`; the checkbox is absent in
the Repay flow and creation there always writes `PERSON`. Repay: selecting a
`RECEIVABLE`/`PAYABLE` account shows no direction toggle (unchanged from today);
selecting a `PERSON` account shows one, pre-selected from the account's current
balance sign, and the save honors whichever side the owner leaves it on.
