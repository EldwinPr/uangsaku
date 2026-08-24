# FEAT12-accounts-split-and-nav-rename — Nav label rename, and the Accounts tab split into two collapsible sections with sums

**Status:** DONE 2026-08-24. Owner's direct request (manual-testing feedback, round
five): *"in nav change akun to ballance or saldo, in this page split akun and person,
both collapsable with sum next to it."* No UC owns this, same class as FEAT01-11.
Implemented directly (small, contained, verified live before this record was written —
same pragmatic shape as the FEAT09/FEAT11 post-close fixes) rather than planned first;
recorded here so the paper trail still exists per this repo's standing discipline.

## Decisions

**D1 — The bottom-nav label for the Accounts tab changes from "Akun"/"Accounts" to
"Saldo"/"Balance"** (`navAccounts`, `app_id.arb`/`app_en.arb`). The screen's own
`AppBar` title (`accountsSectionTitle`, "Akun"/"Accounts") is untouched — it still
names what the page shows now that D2 makes that literally true again (an "Akun"
section, plus a "Person"/"Orang" one), so the two labels reading differently at the
nav bar vs. the page itself is deliberate, not an oversight: the nav names the concept
(your balances), the page names its contents.

**D2 — `AccountsScreen`'s flat list becomes two collapsible sections**, split by
whether an account's group is `PERSON` or not: an "Akun"/"Accounts" section
(`HOLDING`/`RECEIVABLE`/`PAYABLE` — reusing `accountsSectionTitle`, the exact word
already used as this page's title, rather than a second key with the same meaning)
and a "Person"/"Orang" section (reusing `accountGroupLabelPerson`, FEAT11's label, for
the same reason). Both use Flutter's stock `ExpansionTile` (`initiallyExpanded: true`
— the split must not hide information the flat list already showed), each wrapped in
its own private `_AccountSection` widget (not a tracked class — same bucket as
`_FigureCard`/`_NavIconButton`, no diagram entry). Both sections always render, even
with zero accounts in them, the same "show zero rather than hide the section" shape
every other screen in this app already uses.

**D3 — Each section header shows a plain sum of its own accounts' balances next to
the title** (`formatMinorUnits`, FEAT09's money formatter — grouped, currency-aware).
This is a **display convenience for this list only**, not a fifth `FinancialPosition`
figure: it is computed here as a plain `fold` over what `accountBalancesProvider`
already derived, never touches `AccountDao.watchPosition()`'s SQL, and does not
change which of `BalanceSheetScreen`'s four figures any account counts toward
(`PERSON`'s sign-based bucketing there, FEAT11 D2, is completely untouched). Summing
`HOLDING`+`RECEIVABLE`+`PAYABLE` together in one number is exactly what FR-1 refuses
to do for the four home figures ("money sitting with Budi cannot buy lunch") — legitimate
here only because it is a labelled "here's what's in this list" total on a list the
owner explicitly asked to see grouped and summed, not a claim about spendable money.

## Out of scope

- Any change to `BalanceSheetScreen`'s four figures, `AccountDao.watchPosition()`, or
  any other FR-1 computation — this is `AccountsScreen`-local grouping only.
- A third section, per-group sub-splits (e.g. separating `RECEIVABLE` from `PAYABLE`
  within "Akun"), or a settings toggle for section order — not asked for.
- Persisting collapsed/expanded state across app restarts — Flutter's `ExpansionTile`
  keeps it for the widget's lifetime (this tab's `IndexedStack` slot), which is what
  was asked for ("collapsable"), nothing about surviving a restart.

## Definition of done

Four commands green. Verified **live** on a running emulator (adb screenshots, a
clean `flutter run` rebuild — not just a hot reload, which turned out to reflect a
stale build once in this same session) before considering this done: the nav label
reads "Saldo", the page shows two cards titled "Akun 90.000" and "Orang 0", and
tapping the "Akun" header collapses it while the sum stays visible next to the
collapsed header. Widget tests: both sections render with their own `ValueKey`s
(`accounts-section`, `person-section`); a `PERSON` account's balance never appears in
the Accounts section's sum and vice versa; an empty database shows both sections with
their own empty-state message rather than one shared placeholder or a hidden section.
`git diff --stat app/drift_schemas/` empty — no schema change, presentation only.
