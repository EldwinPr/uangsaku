# FEAT10-help-and-navigation — An in-app Help screen, inline hints on Home, and the app bar reorganized

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request (manual-testing feedback,
round three): *"make a guide since this is kind of complex"* — clarified via
follow-up to mean both a dedicated in-app Help screen (reached beside Settings) and
inline tooltips/hints, plus a standing app-bar rule stated in the same answer: the
Categories action stays visible only on Home and Transactions, while Settings and the
new Help action are visible on every tab. No UC owns this, same class as FEAT01-09.

**Depends on:** `FEAT08-transaction-ux-and-name-block` — DONE. Independent of
`FEAT09-visual-identity-and-figures` (no shared file — safe to build in parallel).

## Decisions

**D1 — A new `HelpScreen`, static content, no provider reads.** New file
`app/lib/src/settings/help_screen.dart` — a `StatelessWidget` (nothing here comes from
the database; a `ConsumerWidget` would claim a read dependency this screen doesn't
have), reached by `Navigator.push` from every tab (D3). Body: a `ListView` of
`ExpansionTile` sections, one per concept the app asks the owner to understand: **What
is an account** (the three groups — HOLDING/RECEIVABLE/PAYABLE, one sentence each, the
same wording `FEAT09` D5 puts under the picker, so the two never drift out of sync —
`FEAT09`'s three ARB keys are reused here verbatim, not duplicated under new keys),
**Recording money** (the six writable kinds, `FEAT09`'s six description keys reused the
same way, plus one line on `adjustment` since this screen is the only place that kind
is ever explained to the owner — a new `adjustmentDescription` key), **Budgets** (what
a budget group is, "Others" bucket, no lock — one paragraph), **Debts** (receivable vs
payable, "paid"/"remaining", the settle tick — one paragraph). New tracked class,
added to `class-settings.drawio` (Screen band, no provider edges — static content) and
exported/visually verified before the coder is dispatched.

**D2 — Inline hints: an info icon on each of `BalanceSheetScreen`'s seven cards (four
figures, three charts), not a separate mechanism from D1.** Each `_FigureCard` and
each `_ChartCard` (`balance_sheet_screen.dart`) gains a trailing `Icon(Icons.info_
outline, size: 16)` wrapped in a Flutter `Tooltip` (`message:` one of seven new ARB
keys, one sentence, e.g. *"What you can spend right now, across every HOLDING
account."*) — no new screen, no dialog, no state; `Tooltip` is a stock Flutter widget
that shows its message on long-press (mobile) or hover (desktop/web), nothing to wire.
`RecordTransactionScreen`'s kind picker and `AccountFormScreen`'s group picker do
**not** get a redundant tooltip — `FEAT09` D3/D4 already put a permanent description
under both, and a `Tooltip` on top of already-visible text would be noise, not help.

**D3 — App-bar actions reorganized across all five tabs: Settings and Help appear on
every tab; Categories appears only on Home and Transactions.** New file
`app/lib/src/settings/tab_app_bar_actions.dart`: `List<Widget> tabAppBarActions(
BuildContext context, {required bool showCategories})` returning, in order, the
Categories `IconButton` (only when `showCategories` is true) then the Settings
`IconButton` then the new Help `IconButton` — the exact three `IconButton`s
`BalanceSheetScreen` already builds inline today, lifted out so five screens share one
definition instead of five copies drifting apart. Not a tracked class (a plain
function returning widgets, the same bucket `group_style.dart`/`kind_style.dart` sit
in) — no diagram entry. Wired as each screen's `AppBar.actions`:
- `BalanceSheetScreen` (Home): `tabAppBarActions(context, showCategories: true)`,
  replacing its current inline three `IconButton`s verbatim (no behavior change, pure
  extraction).
- `TransactionListScreen`: `tabAppBarActions(context, showCategories: true)` — this
  screen currently has no `actions` at all; gains Categories, Settings and Help.
- `AccountsScreen`, `RecordTransactionScreen`: `tabAppBarActions(context,
  showCategories: false)` — currently no `actions`; gain Settings and Help only.
- `BudgetOverviewScreen`: keeps its existing "set budget" `IconButton` first, then
  appends `tabAppBarActions(context, showCategories: false)` — Settings and Help join
  the existing action, Categories stays absent here (never asked for on Budget).

**D4 — `_CategoryAutocompleteField`'s two per-file copies are untouched.** This issue
only moves *entry points* to `CategoryManagerScreen` (the app-bar icon), never the
category/subcategory picker widgets themselves.

## Out of scope

- Any color/design change — `FEAT09`.
- A first-launch walkthrough or dismissible onboarding flow — the owner picked the
  static Help screen plus inline tooltips, not a one-time tour.
- Editable or dynamic Help content (no settings-driven text, no localizable rich
  markdown renderer) — plain `Text`/`ExpansionTile`, the same widget vocabulary every
  other screen in this app already uses.
- Search within the Help screen — seven-ish sections is browsable without one.

## Definition of done

Four commands green. Widget tests: `HelpScreen` renders all four section headers and
expands to show its body text on tap; every tab's `AppBar` shows the right action set
(`Categories` present/absent per D3's table, `Settings` and `Help` present on all
five, `Help` navigates to `HelpScreen`); `BalanceSheetScreen`'s seven cards each carry
a `Tooltip` with non-empty `message`. `git diff --stat app/drift_schemas/` empty — no
schema change. `class-settings.drawio` gains `HelpScreen`; re-exported PNG visually
checked before commit.
