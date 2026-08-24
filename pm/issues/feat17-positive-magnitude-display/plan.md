# FEAT17-positive-magnitude-display — Debt figures show as a positive magnitude; net gets a red tint when negative

**Status:** DONE 2026-08-24. Owner's direct request (manual-testing feedback,
round eight), after the "net total looks wrong on Beranda" report turned out to be a
display convention, not a calculation bug: *"turns out it was because of -, if
possible all positive, so payable looks negative but stored in positive, check if
it's like that or not."* Confirmed by reading the code (not guessed): storage is
already correctly signed everywhere (`PAYABLE`/negative-`PERSON` balances are
genuinely negative internally, and every downstream figure is arithmetically correct)
— the bug is purely that two display spots print the raw signed number instead of
following the magnitude convention `DebtDetailScreen.remaining` already established
(`ABS(balance)`, `decisions.md`/UC-02 D6). Clarified via one `AskUserQuestion` round.
No UC owns this, same class as FEAT01-16.

**Depends on:** none — display-only change to two already-shipped screens
(`BalanceSheetScreen`, `AccountsScreen`); no DAO, provider, or class-diagram change.

## Decisions

**D1 — `AccountsScreen`'s per-row balance switches from an unformatted raw `int` to
`formatMinorUnits`, and shows a positive magnitude for every non-`HOLDING` account.**
`accounts_screen.dart`'s `_accountRows` currently renders `Text('${entry.balance}')`
— no grouping/decimal separators at all (a plain bug, independent of sign) and the
raw signed value. Fixed to: `HOLDING` accounts keep their signed balance (spendable
can legitimately go negative if overdrawn — real information, same reasoning
`BalanceSheetScreen`'s `spendable` figure already keeps); `RECEIVABLE`/`PAYABLE`/
`PERSON` accounts show `entry.balance.abs()` through `formatMinorUnits` — matching
`DebtDetailScreen.remaining`'s existing `ABS(balance)` convention exactly. This is a
no-op for `RECEIVABLE` (already non-negative in practice) and for a `PERSON` account
currently owed to the owner; it only changes what a `PAYABLE` account or a
currently-owed-by-me `PERSON` account displays. The two section headers'
(`accountsSum`/`peopleSum`) signed sums are untouched — they are legitimately a mixed
net-of-the-section figure (the same reasoning `net` gets, D3), not a single account's
debt amount.

**D2 — `BalanceSheetScreen`'s "I owe" figure card shows `position.owedByMe.abs()`.**
Today it passes the raw (negative-signed) `position.owedByMe` straight into
`_FigureCard`, so a card already labeled "I owe" also carries a redundant minus sign.
Fixed to pass `position.owedByMe.abs()` — the label plus `PAYABLE`'s existing
color/icon (`group_style.dart`) already say the direction; the number itself should
read as a plain amount, the same convention D1 applies to the account list. `spendable`
and `owedToMe` are unchanged — `owedToMe` is already non-negative by construction
(`RECEIVABLE` plus positive-`PERSON` only), and `spendable` deliberately stays signed
(D1's HOLDING reasoning).

**D3 — `net` keeps its literal sign, but its card recolors to `colorScheme.error` (with
the matching light tint) when negative.** A negative net worth is real, meaningful
information — unlike "owed by me," which is always a magnitude by definition, "net"
genuinely can be negative and should say so plainly. `_FigureCard`'s existing
`color`/`tinted` parameters already support this without any new plumbing:
`BalanceSheetScreen._figuresGrid` computes `final netColor = position.net < 0 ?
colorScheme.error : colorScheme.primary;` and passes `color: netColor, tinted:
position.net < 0` (still no tint when non-negative, preserving today's neutral
look for a healthy or zero net) — `formatMinorUnits` keeps rendering the raw signed
value, so a negative net still shows its `-`, just visually flagged red the same way
every other tinted card on this screen already flags its own color.

## Out of scope

- Any change to `AccountDao.watchPosition()`, `watchBalances()`, `watchDebtProgress()`,
  or any other query — every figure was already arithmetically correct; this issue is
  presentation only.
- `DebtDetailScreen` — already correct (`ABS(balance)`), not touched.
- `AccountsScreen`'s two section-header sums (D1's note) — legitimately signed,
  unchanged.
- Any new ARB key, icon, or class — purely value/color changes to two already-tracked
  screens; no class-diagram edit needed.

## Definition of done

Four commands green. Widget tests: `AccountsScreen` — a seeded `PAYABLE` account with
a negative derived balance renders its row balance as a positive, `formatMinorUnits`-
grouped string (no literal `-` in the rendered text, no raw unformatted int); a seeded
`HOLDING` account with a negative balance still renders signed (a literal `-` present);
a `PERSON` account currently owed by the owner (negative balance) also renders
positive. `BalanceSheetScreen` — a `FinancialPosition` with a negative `owedByMe`
renders that card's value with no literal `-`; a negative `net` still renders with a
literal `-` AND the net card's icon/text paints `colorScheme.error` rather than
`colorScheme.primary`; a non-negative `net` keeps today's `colorScheme.primary`,
untinted card. `git diff --stat app/drift_schemas/` empty — no schema change,
presentation only.
