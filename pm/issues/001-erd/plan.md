# ISSUE-001 — System ERD

**Status:** DONE 2026-08-19 — six entities, three modules, seven relationships, render
visually verified; the workbook Entities sheet was reconciled to the Budget split. Later
amended 2026-08-20: `Budget_Period.state` dropped when state became derived rather than
stored (see `context/index/decisions.md`). Original status line: "CONFIRMED by the user
2026-08-19 — planning gate satisfied, work started."
D1-D8 confirmed as written; owner separately re-confirmed that a debt is an Account,
not its own entity.
**Depends on:** nothing. `docs/workbook.xlsx` "UC FR" is populated (UC-01..UC-13)
and the Entities sheet is derived; that is the input this issue consumes.

## Goal

Draw the system-level ERD for the money tracker as
`docs/diagrams/erd.drawio`, Crow's Foot, entities grouped by owning `Modul`
(Accounts / Transactions / Budgeting), per
`context/document-writer-only/erd-conventions.md`.

## Scope

**In scope**

- All entities on the workbook's Entities sheet, plus the `Budget` split argued
  in D3 below.
- PK and FK rows on every table, plus the business columns that are already
  *known* from the FRs (an amount, a date, a type discriminator). Per
  erd-conventions' *PK/FK-only draft pass*, attributes that are not yet decided
  do not block this diagram.
- Relationships and cardinalities.
- Module grouping boxes, and readable routing for cross-module connectors
  (corridors + `jumpStyle=arc`, per erd-conventions and the two line-jump
  entries in `drawio-general-guide.md`).
- Refreshing the workbook's Entities sheet to match, since D3 changes the entity
  count. erd-conventions requires reconciling the two rather than letting them
  drift.

**Out of scope**

- The budget-month state diagram (open → locked → closed). It is the obvious
  next issue and `fr-nfr.md` already flags it, but it is not this one.
- Class diagrams, component diagram.
- Any Dart/Flutter code, migrations, or `drift` schema.
- The remaining `fr-nfr.md` §4 items that this issue does *not* need — currency,
  and whether a transaction carries a free-text note. Both are single columns
  addable later without touching a single relationship.

**Note on the sequence-diagram gate.** `CLAUDE.md` says a plan's scope *is*
whatever its sequence diagram shows. That gate is written for implementation
issues; this is a documentation issue producing a diagram, with no runtime
interaction to sequence. The scope statement above stands in its place. Flagging
rather than silently skipping.

## Schema decisions this issue must make

These are proposals. Confirming this plan confirms them; each is reversible on
the diagram but expensive once `drift` schema exists.

### D1 — One `Transaction` ledger table, with nullable `from_account` / `to_account`

Every kind of movement in UC-04..UC-09 is "money left one place and/or arrived at
another":

| Kind | from | to |
|---|---|---|
| Expense | wallet | *null* |
| Income | *null* | wallet |
| Transfer (FR-8) | wallet A | wallet B |
| Lend (FR-9) | wallet | the person's receivable account |
| Borrow (FR-9) | the liability account | wallet |
| Repayment (FR-9) | either side | the other |
| Adjustment (UC-03) | the account, or *null* | *null*, or the account |

Two consequences worth having. **"Is this spending?" becomes `to_account IS
NULL`** — so FR-8 and FR-9's "must not count as spending" is enforced by the
shape of the data rather than by a rule someone has to remember in every query.
And balances are one expression over one table (NFR-2).

This is internal double-entry in all but name. NFR-1 explicitly permits that:
*"accounting structure may be used internally where it makes the numbers correct
for free, but it may not surface."* The user still sees one amount and one form
(FR-6) and is never asked to pick two sides. It also matches erd-conventions'
ledger-not-snapshot rule.

A `kind` discriminator column is kept even though it is largely derivable from
the two accounts' groups — reporting and UC-09 both want to filter on it
directly, and erd-conventions endorses a `Type` discriminator on ledger tables.

### D2 — `Account.group` is the three FR-1 groups, and "credit"/"debit" appear nowhere

`HOLDING` (money I hold and can spend) / `RECEIVABLE` (owed to me) / `PAYABLE`
(I owe). FR-1's *Consequence* paragraph already names exactly these three.

This closes the §4 naming collision, and closes it by constraint rather than by
preference: **NFR-1's fit criterion forbids a debit/credit column outright.** The
words were never available. FR-4 and FR-5 also confirm a credit card and a person
are both just accounts, so one table with a group discriminator is right — no
subtype tables.

### D3 — `Budget` splits into `Budget_Group` and `Budget_Period`

`fr-nfr.md` §4 deferred this decision *to the ERD* explicitly, so it comes due
here. Three separate requirements force the split:

- The doc's own argument: trend reporting across months needs a stable handle on
  "Food" that survives a rename or a typo.
- FR-14 — each month's budget stands alone, so the monthly amount is per-month
  data, not a property of the group.
- FR-16 — a month's budget has a lifecycle (open → locked → closed). A lifecycle
  needs a row to live on.

So `Budget_Group` holds identity (the name you tag a transaction with, FR-10) and
`Budget_Period` holds one month's amount and state. `Budget_Period` is also the
state-diagram subject for the next issue.

### D4 — `Budget_Period` carries explicit start and end dates, not a year-month key

Deliberate: this is neutral to §4's then-unresolved *what "a month" means*. Calendar
months and payday-to-payday both fit a start/end pair; a `YYYY-MM` column would
silently commit to calendar. This lets the ERD proceed without forcing a decision
that has not been made — the cheapest possible handling of an open question.

*Resolved 2026-08-20: a month is a calendar month.* The columns do not change, which
is the point — keeping the general shape cost nothing and is still exactly what a
payday-to-payday change would need.

### D5 — "Others" (FR-17) is not a row

It is the null `budget_group_id`, presented as "Others" in the UC-12 view. A real
row could be renamed or deleted by the user (FR-18) and would need a magic ID the
code special-cases. Null is already exactly what FR-10's "can be left blank"
produces.

### D6 — `Category` and `Subcategory` are two tables, not a self-referencing tree

FR-10 confirms *exactly* two levels. A self-FK would permit the deeper nesting the
requirement forbids, and erd-conventions flags self-referencing hierarchies as
ORM-awkward. Two tables make the constraint structural.

### D7 — No stored balance, anywhere

NFR-2. No `current_balance` on `Account`, no `spent` on `Budget_Period`. To be
annotated directly on the diagram so it survives as a visible design rule.

### D8 — Debt settlement is a status on `Account`, not its own entity

FR-11 / UC-10 needs "how much is paid, how much is left, mark it done." Paid and
remaining are derived from transactions (D7). "Mark it done" is a settled flag
plus date on the `RECEIVABLE`/`PAYABLE` account. A separate `Debt` entity would
duplicate what an account already is (FR-4, FR-5).

## Resulting entities — 6

`Account`, `Transaction`, `Category`, `Subcategory`, `Budget_Group`,
`Budget_Period`.

The Entities sheet currently lists 5 (with `Budget` undivided); D3 is why. Sheet
gets refreshed as part of this issue.

## Steps

1. Confirm this plan (planning gate).
2. Draft `docs/diagrams/erd.drawio` — delegated to the `diagram-drawio-author`
   agent, per `CLAUDE.md`.
3. Export to PNG and visually verify the render. Mandatory, non-negotiable, and
   the failure mode the guide warns about repeatedly.
4. Check no XML comments survive (`grep -c '<!--'`).
5. Refresh the workbook Entities sheet to the 6 entities, with owning modules.
6. Close per the `CLAUDE.md` checklist — `map.yaml`, `decisions.md` (D1, D2, D3
   are durable and architectural), tracker, log, `active.json`.

## Known gaps carried forward, not resolved here

- Currency and money storage (§4). Recommendation when it comes up: integer minor
  units, never a float. Not needed to draw relationships.
- Whether a transaction has a free-text note (§4).
- What "a month" means (§4) — sidestepped by D4, still open for FR-16's lock.
- `erd-conventions.md` says naming must follow `coding-conventions/*.md`; that
  directory does not exist yet (`general-rules.md` says it arrives at
  implementation). So this ERD sets naming rather than inheriting it, and the
  coding conventions should be written to match it, not the reverse.
