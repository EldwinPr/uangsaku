# ISSUE-007 — Currency: one app-level setting, amounts as integer minor units

**Status:** DONE 2026-08-20. All ten steps complete; every render visually verified and
`audit.py` green. Amended twice while running (D5, D6) as the fourth module's consequences
surfaced — both amendments are recorded below rather than folded in silently.
**Depends on:** ISSUE-001 (DONE, the ERD owns the three amount columns), ISSUE-006
(DONE, `enums.md` is where the currency values land — it predicted this).
**Traces to:** UC-01, UC-02, UC-03, UC-04..UC-09, UC-11, UC-12, and a new UC-14.

## Goal

Close the last schema-blocking item in `fr-nfr.md` §4. One currency for the whole app,
chosen by the owner; every amount stored as an integer count of that currency's minor
unit.

## How the decision arrived, since the path matters

The owner first asked for **multi-currency** (IDR, USD, CNY, more later). Raised the
cost before acting: currency per account, a rate at a point in time for every total,
UC-01's four figures no longer summable, and UC-12's budget comparison splitting per
currency. The owner withdrew it in the same breath — *"if it's too much then one
currency but user choose idr or usd just for now"* — which is the right retreat: it
removes rates, conversion and per-account currency in one move.

The owner then proposed storing amounts as `double`. **Pushed back once, and the owner
accepted:** binary floating point cannot represent 0.1 exactly, so error accumulates
across sums — and NFR-2 ("the numbers must agree with each other") is precisely the
requirement that violates. A balance sheet whose net stops matching the sum of its parts
by a cent, with the error living in storage rather than in any query, is unfixable by
better querying.

*Multi-currency is not foreclosed.* It is a bigger change than a column, but nothing
here makes it harder later than it is today: the currency is stored with the data
(D3), so a future per-account currency is an added column rather than a reinterpretation
of existing rows.

## Decisions

### D1 — One app-level currency: `IDR` or `USD`

Not per account, not per transaction. Every amount in the database is in this currency.
Chosen at setup; `CNY` and others are added later by adding an enum value, which is a
one-line change plus a migration — the owner is also the developer here, so a
user-editable currency *table* would be ceremony for no gain.

**Changing it later is allowed, and warned about, not blocked.** Amounts cannot convert
— 50,000 IDR would silently become 50,000 USD. NFR-4's fit criterion is **zero
refusals**, so the app may not refuse the change; it states the consequence plainly at
the moment the owner would cause it and then does as it is told. This is the standing
rule applied, not an exception to it.

### D2 — Amounts are `int`, counting the currency's minor unit

All three amount columns — `Account.opening_amount`, `Transaction.amount`,
`Budget_Period.amount` — become integer minor units. The exponent comes from the
currency: `IDR` = 0 (whole rupiah; no practical minor unit), `USD` = 2 (cents). So
`19.99` USD stores as `1999`, and `50000` IDR stores as `50000`. Formatting for display
is a UI concern and the only place a decimal point exists.

Dart's `int` is 64-bit; no realistic amount overflows it. This is a storage decision:
free today, a migration once data exists.

### D3 — The currency setting lives in the database, in a one-row `Settings` table

New entity on the ERD. The alternative — device preferences (`SharedPreferences`) — is
lighter but wrong here: **backup is an export file** (`decisions.md`, 2026-08-19), and
if the currency does not travel with the amounts then an exported file is a column of
numbers whose meaning is missing. A restored backup would silently reinterpret every
amount.

It is drawn on the ERD rather than hidden as configuration because its value changes the
meaning of every amount in every other table. A dependency that strong being invisible
is exactly the failure the component diagram existed to expose.

*Flagged as a call made rather than asked:* this adds a seventh entity to a schema the
owner has already reviewed. Say so if it should instead be a device preference; nothing
else in this plan depends on which way it goes.

### D4 — This becomes FR-19 and UC-14, not a footnote

Choosing the currency is a user-facing capability with an actor, and no existing UC
covers it. This project's rule is that a capability enters as an FR and promotes to a
workbook row (`fr-nfr.md` §5, Route 2); leaving it as a note would create a capability
the app must have with no owning entry — which is the gate `CLAUDE.md` states outright.

### D6 — `Settings` appears on the component diagram, with no call edge

The component diagram's rule is one box per real module, and there are now four. But
`Settings` has no cross-module *call*: nothing invokes it, and it holds no FK. What it
has is a semantic dependency in the opposite direction — every other module's amount
columns are meaningless without its one value.

Drawn as: a `Settings` component with its own isolate-boundary edge to `AppDatabase`
(it is a table like any other), plus a note stating the interpretive coupling. **No
invented call edges** — `component-conventions.md` requires every edge to name a real
mechanism, and "the numbers mean nothing without this" is not a call. This is the same
judgement as leaving `Settings` unconnected on the ERD.

### D5 — `Settings` is a fourth module, and so it gets a fourth class diagram

*Amended into this plan after the work started, per `general-rules.md` ("if the fix
changes what was planned, update `plan.md` first, then do the work").*

Promoting UC-14 forced the question of which module owns it, and none of the three fit:
currency is not where money lives, not something that happened, and not a budget. It
became a fourth module, `Settings`. `class-diagram-conventions.md` is one-diagram-per-
module, so a fourth module means a fourth diagram — `docs/diagrams/class-settings.drawio`
— or the artifact set is inconsistent and UC-14 is the only use case in the project with
no class diagram. Drawing it is cheaper than arguing the exception.

*Flagged as scope this plan did not originally carry.* The alternative was to leave it
for its own issue and accept a red check in the meantime; that trades a small diagram
for a known-inconsistent artifact set, which is the worse of the two.

## Steps

1. `docs/fr-nfr.md` — add FR-19; move the currency row out of §4 into a dated decision;
   add the FR-19 → UC-14 row to §5.
2. `docs/enums.md` — add the `Currency` enum (`IDR`, `USD`) with its exponent, and the
   int-minor-unit rule as the reason the exponent exists. `enums.md` already flagged
   currency as the value that would land here.
3. `docs/workbook.xlsx` — promote UC-14 (delegated to `workbook-xlsx-author`).
4. `docs/diagrams/erd.drawio` — add the `Settings` entity; annotate the three amount
   columns as integer minor units (delegated to `diagram-drawio-author`).
5. `context/index/decisions.md` — the decision and the rejected alternatives.
6. `audit.py` — stop hard-coding `FR-1..FR-18`; derive the set from the document, so
   the next FR does not silently pass an outdated check.
7. Workbook Entities sheet + `map.yaml` — `Settings` is a new entity and a new module.
8. `docs/diagrams/class-settings.drawio` — the fourth class diagram (D5).
9. **D6 fallout — the fourth module makes three existing diagrams stale.**
   `component-overview.drawio` draws the system's modules and now shows three of four;
   the other three class diagrams each say `AppDatabase` is "shared by all three
   modules". Both are corrected in this issue rather than left for a later one — a
   diagram that is known-wrong is worse than one that is missing, because it is still
   believed.
10. Close per the `CLAUDE.md` checklist; `audit.py` green.

## Out of scope

- Multi-currency, rates, and conversion. Withdrawn by the owner; see above.
- Whether a transaction carries a free-text note — the other §4 item, still open, and
  genuinely a nullable column that can be added any time.
- Locale-aware formatting (thousands separators, symbol placement). A UI concern with
  no schema consequence; decide it when there is a screen.
- Any Dart code. No scaffold exists yet.
