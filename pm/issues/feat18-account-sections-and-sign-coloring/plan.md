# FEAT18-account-sections-and-sign-coloring — Four collapsible account-type sections with black/green/red coloring

**Status:** DONE 2026-08-25. Owner's direct request (manual-testing feedback,
round nine), explicitly framed as what was actually wanted from FEAT17: *"i need all
the account to have their each section, holding/saldo, hutang, piutang, and orang.
each collapsable... saldo black, piutang green, hutang red, orang depends is it - or
+. that was what i wanted for feat 17 with added color."* Clarified via one
`AskUserQuestion` round. No UC owns this, same class as FEAT01-17.

**Depends on:** `FEAT12-accounts-split-and-nav-rename` (the two-section split this
issue widens to four) and `FEAT17-positive-magnitude-display` (the `ABS()`-for-debts
convention this issue's coloring sits on top of, unchanged).

## Decisions

**D1 — `AccountsScreen`'s two sections (Akun, Person) become four: Holding,
Receivable, Payable, Person.** Today `_sections` splits `balances` into `accounts`
(every non-`PERSON` group merged into one "Akun"/"Accounts" section) and `people`.
This splits `accounts` into its three constituent groups, each its own
`_AccountSection`, so the screen shows four always-rendered (even empty) collapsible
sections in `AccountGroup.values` order: `HOLDING`, `RECEIVABLE`, `PAYABLE`, `PERSON`.
The page's own `AppBar` title (`accountsSectionTitle`, "Akun"/"Accounts") is
unchanged — it was never this-section-specific, it names the whole screen.

**D2 — Section headers reuse the existing group labels, no new ARB keys.** The four
headers are `accountGroupLabelHolding` ("Dompet"/"Holding"),
`accountGroupLabelReceivable` ("Piutang"/"Receivable"), `accountGroupLabelPayable`
("Utang"/"Payable"), `accountGroupLabelPerson` ("Orang"/"Person") — the exact same
strings `AccountFormScreen`'s group `SegmentedButton` already uses (FEAT11 post-close
fix), so the vocabulary agrees across the two screens instead of introducing a
second, slightly-different set of words for the same four groups. Each section's own
sum (`formatMinorUnits`) sits next to its header, same as today's two-section shape —
`accountsSum`/`peopleSum` become four per-group sums (`holdingSum`, `receivableSum`,
`payableSum`, `personSum`), each a plain fold over its own filtered list, nothing new
computed beyond what `accountBalancesProvider` already derives.

**D3 — New sign-aware color helper in `group_style.dart`, applied only on
`AccountsScreen`.** New plain function (not a tracked class — same bucket as
`accountGroupColor`/`accountGroupIcon`, per the established
untracked-style-helper convention):

```dart
Color accountRowColor(BuildContext context, AccountGroup group, int balance) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (group) {
    AccountGroup.HOLDING => colorScheme.onSurface,   // neutral/"black" (D2 clarified)
    AccountGroup.RECEIVABLE => accountGroupColor(context, AccountGroup.RECEIVABLE), // green
    AccountGroup.PAYABLE => accountGroupColor(context, AccountGroup.PAYABLE),       // red
    AccountGroup.PERSON => balance >= 0
        ? accountGroupColor(context, AccountGroup.RECEIVABLE)   // green, owed to me
        : accountGroupColor(context, AccountGroup.PAYABLE),     // red, owed by me
  };
}
```

Owner's clarified answer: `HOLDING` is *"black"* — the app's theme-neutral default
text color (`colorScheme.onSurface`), deliberately **not** `accountGroupColor`'s
existing `colorScheme.primary` for `HOLDING` (that mapping is untouched everywhere
else it's used — Home's figure cards, the account-type picker's description text —
this issue only adds a new, differently-scoped function, it does not change
`accountGroupColor` itself, confirmed via `AskUserQuestion`: *"AccountsScreen only"*).
`RECEIVABLE`/`PAYABLE` reuse `accountGroupColor`'s existing green/red exactly — those
were already right. `PERSON` is the new case: sign-dependent, reusing the same
green/red rather than its usual neutral `colorScheme.tertiary`, matching FEAT11's own
sign-based bucketing logic (`AccountDao.watchPosition()`: positive → owed-to-me
territory, negative → owed-by-me territory) now made visible as color, not just as
which `BalanceSheetScreen` figure the balance folds into.

Applied to **both** the section header's sum text and each row's balance text within
that section — a `HOLDING`/`RECEIVABLE`/`PAYABLE` section's header color is that
group's fixed color (its rows are all the same group, so header and rows always
agree); the `PERSON` section's header colors by the sign of `personSum` itself (the
section's own aggregate can legitimately mix positive and negative accounts, so its
header's color is independent from any one row's).

**D4 — Coloring layers on top of FEAT17's `ABS()` convention, unchanged.** A `PAYABLE`
row still shows `entry.balance.abs()` (FEAT17 D1), now additionally tinted red via
`accountRowColor`; a `PERSON` row still shows `entry.balance.abs()`, now tinted green
or red depending on the *original signed* balance (the color function receives the
un-absed `entry.balance`, only the displayed text is absed) — direction is
communicated by color, magnitude by the number, never a redundant minus sign.
`HOLDING` keeps showing its true signed balance (FEAT17 D1's carve-out, overdrawn is
real information) with the neutral `onSurface` color regardless of sign — a negative
`HOLDING` balance is not "debt-red," it is just a literal negative wallet balance.

## Out of scope

- Any change to `accountGroupColor()`/`accountGroupIcon()` themselves, or anywhere
  else they're already used (`BalanceSheetScreen`'s figure cards,
  `AccountFormScreen`'s group description text) — confirmed scoped to `AccountsScreen`
  only via `AskUserQuestion`.
- Any change to `AccountDao.watchPosition()`/`watchBalances()` or any other query —
  presentation only.
- The account-list row's trailing debt-details icon logic (`RECEIVABLE`/`PAYABLE`/
  `PERSON` get one, `HOLDING` doesn't) — unchanged, still correct under four sections.
- `FEAT19-payable-auto-negate` (the separate, unrelated change to how a `PAYABLE`
  opening/target amount is *entered* — a different file, `account_form_screen.dart`,
  tracked as its own issue).

## Definition of done

Four commands green. Widget tests: all four sections (`holding-section`,
`receivable-section`, `payable-section`, `person-section` — new `ValueKey`s replacing
`accounts-section`) render, each always present even with zero accounts in it; a
seeded `HOLDING` account's row and section-header text both paint
`colorScheme.onSurface`; a seeded `RECEIVABLE` account's row/header both paint the
same green `accountGroupColor` already ships for `RECEIVABLE`; a seeded `PAYABLE`
account's row/header both paint the same red `accountGroupColor` already ships for
`PAYABLE`; a `PERSON` account with a positive balance paints green, one with a
negative balance paints red, and the `PERSON` section header's color follows the
section's own signed sum's direction independent of any single row. `git diff --stat
app/drift_schemas/` empty — no schema change, no DAO/provider change, presentation
only.
