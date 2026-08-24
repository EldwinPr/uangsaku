# FEAT09-visual-identity-and-figures — A color/icon per type, redesigned figure cards, descriptions under pickers

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request (manual-testing feedback,
round three), clarified via follow-up: "stronger color per account/transaction type"
(not a broader re-theme); the four top figures on Home become cards with color, not
the `AccountsScreen` list (explicitly ruled out); the account-group picker in
`AccountFormScreen` and the transaction-kind picker in `RecordTransactionScreen` both
gain a description line below the selected value. No UC owns this, same class as
FEAT01-08.

**Post-close fix, 2026-08-24, same day:** the owner reported the shipped figure-card
`GridView` (`childAspectRatio: 1.6`) overflowing by up to 32px — a fixed aspect ratio
caps card height regardless of content, and `id`'s longer figure labels (or a larger
system font) push past it. Replaced with two `IntrinsicHeight` rows of two `Expanded`
cards, sized to actual content instead of a fixed ratio — cannot overflow regardless of
label length or font scale. Same message also asked for the amounts' missing thousands/
decimal separators ("i forgot also add . and ,") — added `money_format.dart`
(`formatMinorUnits`), a locale-aware `NumberFormat` (grouping + `Currency.exponent`
fraction digits) applied to the four figure cards only, not swept across the rest of
the app. See `pm/log.md`'s 2026-08-24 entry for the full account.

**Follow-up audit, 2026-08-24, same day:** the owner asked to check other screens for
the same overflow class. Grepped the whole app for `GridView`/`childAspectRatio` (none
elsewhere) and every `Row(` with a `Text` sibling not wrapped in `Expanded`/`Flexible`.
Found and fixed two more real instances of the same root cause (a fixed-size container
next to locale-length-dependent text, no give): `AppShell`'s bottom nav bar (`id`'s
"Transaksi"/"Anggaran" or a larger accessibility font could overflow the
`BottomAppBar` horizontally — each side wrapped in `Expanded`, each button in
`Flexible`, the label now ellipsizes instead of throwing) and `_ChartCard`'s title row
(the chart titles are long sentences — wrapped in `Expanded` with `maxLines: 1` +
ellipsis). Two new regression tests stress both fixes at once: `id` locale plus a 2x
`TextScaler`, asserting `tester.takeException()` is null. See `pm/log.md`'s 2026-08-24
entry for the full account.

**Depends on:** `FEAT08-transaction-ux-and-name-block` — DONE.

## Decisions

**D1 — One color (and one icon) per `AccountGroup`, one color per `TransactionKind`,
extracted once and reused everywhere they already appear or are about to.** New file
`app/lib/src/accounts/group_style.dart`: `Color accountGroupColor(BuildContext,
AccountGroup)` and `IconData accountGroupIcon(AccountGroup)` — `HOLDING` →
`colorScheme.primary` / `Icons.account_balance_wallet`, `RECEIVABLE` → a fixed green
(same literal `TransactionListScreen` already uses for income —
`Colors.green.shade700`/`shade300` light/dark) / `Icons.call_received`, `PAYABLE` →
`colorScheme.error` / `Icons.call_made`. New file
`app/lib/src/transactions/kind_style.dart`: `Color transactionKindColor(BuildContext,
TransactionKind)`, the exact mapping `TransactionListScreen._titleColor` already ships
(income green, expense `colorScheme.error`) extended to the other five kinds so every
kind now has one: `transfer` → `colorScheme.primary`, `lend`/`borrow` →
`colorScheme.tertiary`, `repayment` → `colorScheme.secondary`, `adjustment` →
`colorScheme.onSurfaceVariant` (neutral — a correction, not a real movement).
`TransactionListScreen._titleColor` is refactored to call this shared function instead
of its private inline `switch` — same output, one definition. Neither file is a new
tracked class (plain top-level functions, the same bucket private per-file widgets
already sit in) — no diagram entry for either.

**D2 — The four figures on `BalanceSheetScreen` (Home) become a 2×2 `GridView` of
colored cards, replacing the current `ListTile`-in-`Card` column.** `_FigureCard`
redesigned: a colored icon (from D1's `accountGroupColor`/`accountGroupIcon` — Home's
`spendable` figure maps to `HOLDING`'s color/icon, `owedToMe` to `RECEIVABLE`'s,
`owedByMe` to `PAYABLE`'s), a light tinted background (`color.withValues(alpha: 0.12)`
— never a solid fill, so text stays legible in both themes without a second contrast
check), larger amount typography (`headlineSmall`), and the label above it. `net` has
no `AccountGroup` counterpart — it keeps the current neutral card styling
(`colorScheme.primary` accent, `Icons.account_balance`), no tint. The existing
`ValueKey`s (`figure-spendable`, `figure-owed-to-me`, `figure-owed-by-me`, `figure-net`)
stay on the amount `Text` unchanged — every existing widget test that reads a figure by
key keeps passing untouched.

**D3 — `AccountFormScreen`'s group `SegmentedButton` gains a description line below
it, in both the create and edit flows.** Three new ARB keys
(`accountGroupDescriptionHolding`/`Receivable`/`Payable`), one `Text` widget below the
`SegmentedButton`, swapped by `_group`'s current value on every `setState` — plain
text, `bodySmall`, tinted with D1's `accountGroupColor` for the currently selected
group so the color system and the wording reinforce each other. Adjust mode is
untouched (it shows no group picker).

**D4 — `RecordTransactionScreen`'s kind `DropdownButtonFormField` gains the same
treatment.** Six new ARB keys (`kindDescriptionExpense`/`Income`/`Transfer`/`Lend`/
`Borrow`/`Repay` — `adjustment` has no entry here, this form never offers it), one
`Text` widget below the dropdown, swapped by `_flow`'s current value, tinted with D1's
`transactionKindColor`.

**D5 — Descriptions are plain, factual sentences, not marketing copy.** E.g. HOLDING:
*"Money you hold and can spend directly — a wallet, bank account, or e-wallet."*
RECEIVABLE: *"Money someone else owes you."* PAYABLE: *"Money you owe someone else."*
Expense: *"Money leaving one of your accounts, spent on something."* — the same
register `docs/enums.md` and the class diagrams already use.

## Out of scope

- `AccountsScreen`'s per-account list — explicitly confirmed to stay `ListTile` rows,
  not cards (owner: *"not account home screen the first 4 things"*).
- Any change to what a figure/chart computes — this issue is presentation only, no
  `AccountDao`/`TransactionDao` change.
- A broader re-theme (gradients, gone-further typography/spacing pass) — explicitly
  ruled out in favor of the narrower per-type color system.
- `SetBudgetScreen`/`BudgetOverviewScreen` — no per-budget-group color system was
  asked for.
- The in-app Help screen and any AppBar/navigation change — `FEAT10`.

## Definition of done

Four commands green. Widget tests: `BalanceSheetScreen`'s four figure cards still
expose their existing `ValueKey`s with the right values (no regression to the FR-1
test); a `HOLDING`/`RECEIVABLE`/`PAYABLE` figure card renders `accountGroupColor`'s
color somewhere in its subtree (e.g. the icon's `color` property); `group_style.dart`
and `kind_style.dart` each get a small unit test asserting the three/seven color-and-
icon mappings; `AccountFormScreen` shows the right description text for each group
selection (create and edit flows); `RecordTransactionScreen` shows the right
description text for each kind selection. `git diff --stat app/drift_schemas/` empty
— no schema change, this is presentation only.
