# Functional & Non-Functional Requirements

Money tracker — personal mobile application.

**Source:** `input/2026-08-19-owner-scope-conversation/`
**Status:** confirmed by the owner 2026-08-19 and promoted to
`docs/workbook.xlsx` → UC FR as UC-01..UC-13. See §5 for the mapping.

Every FR below traces to something the owner actually said in that session.
Nothing here is inferred — where a need was named but not discussed, it sits in
§3 as an open item rather than being guessed into a requirement.

**Pipeline position:** the FR-list input route (`README.md` → "The input
layer"). This project models no existing business process, so there is no
as-is BPMN; requirements enter here and promote to the **UC FR** sheet of
`docs/workbook.xlsx` once confirmed. Nothing here is a use case yet.

Requirements are written as user-facing capabilities — what the owner can do,
not what the system contains.

---

## 1. Functional requirements

### Knowing where I stand

**FR-1 — I can see what I'm worth, with what I can actually spend kept
separate from what I am merely owed.**
The primary screen — not a report behind a menu — shows four distinct figures:
what I can spend now, what people owe me, what I owe, and the net. Spendable
and owed-to-me are never merged: money sitting with Budi is mine, but it cannot
buy lunch, and a single combined figure would say otherwise.
*(Owner: "it's not ballance ballance it's balance sheet"; "separate spendable
from owed to me".)*

*Consequence:* an account falls into one of three groups, not two — money I
hold and can spend (cash, bank, e-wallet), money owed to me (a person, a
receivable), and money I owe (credit card, loan). The first two are both
positive and both mine; only the first is reachable.

**FR-2 — I can see how much is in each place my money lives.**
Cash, bank, e-wallet, each with its own current amount.

### Setting up the places money lives

**FR-3 — I can add the places I keep money.**
Named by me, each starting from whatever is in it today.

**FR-4 — I can add the money I owe as one of those places.**
A credit card or a loan is set up the same way as a wallet — it just holds a
negative amount. *(Owner's answer: a credit card is a debt.)*

**FR-5 — I can add a person who owes me money.**
Set up the same way, so what Budi owes me is one number I can look at, and
lending him more adds to it.

### Recording what happened

**FR-6 — I can record spending in a few seconds.**
The common case — amount, what it was for, done — is the fastest path in the
app. *(Follows from the owner's rejection of accounting ceremony on usability
grounds; see NFR-1.)*

**FR-7 — I can record money coming in.**

**FR-8 — I can move money between my own places without it counting as
spending.**
Cash into the bank is not an expense, and must not appear as one.

**FR-9 — I can lend money, borrow money, and record repayments — in either
direction — without any of it counting as spending.**
Lending Budi 200k is not money spent; him paying it back is not income.

**FR-10 — I can tag what I record with a category, a subcategory, and a budget
group, and any of them can be left blank.**
Category and budget are independent axes: transportation can belong to travel
or to work. Categories are exactly two levels deep — category and subcategory,
no further nesting. *(Owner's verbatim example; confirmed optional; confirmed
two levels.)*

### Debts

**FR-11 — I can see how much of a debt is paid off and how much is left, and
mark it done.**
*(Owner: "just tick but also show how much is paid".)*

### Budgeting

Budgets are their own thing — not accounts, not categories. They behave like an
account in that they hold an amount that drains as it is used, but they are a
separate table alongside accounts and categories. *(Owner: "budget is another
table that acts like account, that's why we have account, budget,
category/sub".)*

**FR-12 — I can set a monthly amount for a budget group.**
A soft limit, not an enforced one — going over is recorded, not prevented.

**FR-13 — I can see how much of a budget is left this month**, draining as I
spend against it.

**FR-14 — Each month's budget stands alone; unspent money does not carry
forward.**
Accounts run continuously, budgets do not. *(Owner: "budget stops at that month
to keep the report faithful" — the reason is report fidelity, so a month's
numbers reflect that month and nothing else.)*

**FR-15 — Next month's budget is set automatically from this month's, and I can
change it.**
Automatic so it does not become a monthly chore that gets skipped; adjustable
because months differ.

**FR-16 — I can change a month's budget at any time, including after the month
has started.**
No lock. A budget period accepts create, edit and delete for its whole life,
exactly like every other entity (FR-18). *(Owner, 2026-08-20: "i guess let budget
be full crud like other, it's about users discipline anyways"; "from now on it's
user responsibility no more guardrails or whatever".)*

*Supersedes the original FR-16*, which locked a month's budget after the first
week and was the only hard refusal in the app. The owner reversed it deliberately,
on the ground that keeping to a budget is theirs to manage and not the app's to
enforce — the same reasoning already applied to skipped months in §4 ("it's users
commitment not app problem") and generalised as NFR-4.

*Accepted cost, raised before the change and reaffirmed:* the original rationale
was **report fidelity, not discipline** — "a report measured against a moving
target says nothing." Without the lock, UC-12's spent-vs-budget comparison is
always satisfiable after the fact, because nothing distinguishes an amount set in
advance from one raised later to match what was spent. The owner accepted this
knowingly. It is recorded here so it reads as a trade that was made, not an
oversight.

*Not foreclosed:* if that comparison is ever wanted back, the way to get it is to
**record** that an amount was amended after the period started and show it in the
report ("2M, amended from 1.5M on day 20") — an addition that refuses nothing and
so does not reintroduce a guardrail. Deliberately not built now.

FR-14 is untouched by this. Each month's budget still stands alone and unspent
money still does not carry forward — that is about carry-forward, not about the
lock.

**FR-17 — Spending with no budget group appears under "Others".**
The budget tag is optional (FR-10), so money would otherwise escape the budget
view entirely. "Others" keeps it visible and keeps the month's totals complete.

**FR-18 — I can create, view, edit, and delete everything I record.**
Full CRUD across transactions, accounts, budgets, categories and subcategories,
people, and debts. No entity is create-only, and **no entity has an exception**.

*Exception removed 2026-08-20.* For one day this requirement carried a carve-out:
a budget period was full-CRUD only until the lock fell at the end of the first
week, after which it became view-only. That existed solely to stop the FR-16 lock
being sidestepped — a budget you can delete is a budget you can escape, since
deleting and recreating at a new amount would have left the lock enforcing nothing.
The argument was sound while there was a lock to escape. With FR-16 rewritten there
is nothing left to protect, so the carve-out went with it rather than surviving as
an orphan rule nobody could justify.

### Currency

**FR-19 — I choose the currency my money is recorded in.**
One currency for the whole app — `IDR` or `USD` — chosen at setup. There is no
per-account currency, no conversion, and no exchange rate anywhere.
*(Owner, 2026-08-20: "one currency but user choose idr or usd just for now".)*

*I can change it later, and the app will not stop me.* Amounts cannot convert: a
50,000 recorded as rupiah becomes a 50,000 read as dollars. The app says so plainly at
the moment I would cause it, and then does as it is told — NFR-4's fit criterion is zero
refusals, and this is that rule applied rather than an exception to it.

*Consequence for storage:* every amount is an integer count of the chosen currency's
minor unit, never a floating-point number — `IDR` has exponent 0 (whole rupiah), `USD`
has exponent 2 (cents). This is NFR-2 doing the deciding: binary floating point cannot
represent 0.1 exactly, so error accumulates across sums, and a balance sheet whose net
stops matching the sum of its parts cannot be fixed by a better query when the error
lives in storage. Values and exponents are in `docs/enums.md`.

*Where the setting lives:* in the database, not in device preferences, so that it
travels with a backup export. A file of amounts whose currency is missing is a column
of ambiguous numbers.

*Multi-currency was asked for and withdrawn the same day* — the owner opened with
IDR/USD/CNY and pulled back when the cost was raised: a currency per account, a rate at
a point in time behind every total, FR-1's four figures no longer summable, and FR-13's
budget comparison splitting per currency. Nothing above forecloses it; because the
currency is stored with the data, a future per-account currency is an added column
rather than a reinterpretation of what is already recorded.

---

## 2. Non-functional requirements

Only two are grounded in the session. Both come from the same statement, and
both are constraints rather than preferences.

**NFR-1 — Usability outranks accounting correctness.**
The owner explicitly considered a chart of accounts and a formal balance sheet
and rejected them for costing usability. Accounting structure may be used
internally where it makes the numbers correct for free, but it may not surface:
no account codes, no journal, no debit/credit columns, no period close, and the
user is never asked to pick two sides of an entry.

*Fit criterion:* no screen exposes an account code, a journal, a debit/credit
column, or a period close, and no flow asks the user to pick two sides of an
entry. Walkable as a checklist against the finished screens — it does not
measure usability, it enumerates the specific things the owner rejected.

**NFR-2 — The numbers must agree with each other.**
Balances and the balance-sheet totals are derived from what was recorded, never
stored alongside it. The owner's reason for the two-account-type model was that
it makes balances easy to check; that only holds if there is exactly one source
for each number.

**NFR-3 — The data must support later reporting without restructuring.**
The owner's stated reason for giving budgets an account-like shape was that a
monthly report, a dashboard, or an AI integration all become easier. None of
those are in scope, but the shape of what is recorded should not have to change
to allow them.

**NFR-4 — The app assists; it does not police.**
Generalised from the owner's ruling above, and stated here because it settles a
whole class of future questions the same way. The app records what it is told
and helps the owner see the consequences; it does not block, nag, or enforce.
**There are no exceptions.** *(Owner, 2026-08-20: "from now on it's user
responsibility no more guardrails or whatever".)*

*Fit criterion:* **no user action in the app is refused.** Every action succeeds,
with a warning at most. Any refusal appearing anywhere is a violation of this NFR
until it is argued and added here, which is the point: the count is the test, so a
block cannot be added quietly.

*Strengthened 2026-08-20.* This criterion previously read "exactly one user action
is refused" and named the FR-16 budget lock as that one. Removing the lock took the
count from one to zero, which makes the test strictly sharper — there is no longer a
sanctioned exception for a new refusal to be argued as similar to.

---

## 3. Wanted, deliberately not now

Agreed as real, deferred by the owner. Not requirements yet — recorded so they
are not rediscovered as omissions.

- **Backup / export.** Owner: "backup for later."
- **OCR of receipts.** Owner asked, then deferred — same standing as backup, no
  commitment. Assistive shape if it ever lands: snap a receipt, the app
  proposes an amount and a date, typing stays the primary path. *One thing to
  know while it is deferred:* a browser-only stack forecloses it, because
  on-device text recognition (ML Kit, Vision) is not available there and the
  browser alternatives are slower and less accurate. Deferring OCR is fine;
  picking a stack that makes it impossible is a separate decision and should be
  a deliberate one.
- **Reviewing the past** — searching and filtering beyond the month view. Never
  raised; not invented. FR-13 and FR-14 already imply a per-month view exists.

*Raised and closed 2026-08-19 — **superseded 2026-08-20**, see below:* whether
FR-18 (edit anything) conflicts with FR-14/FR-16 (a month's report stays faithful).
Owner's ruling at the time: it does not. A budget is a commitment made in advance,
so it is locked; a transaction is a record of what happened, so it stays
correctable. Tidying one's own records is the owner's business, not the app's.
*(Owner: "budget stays, transaction editable. whether cleaning it or not depends on
the person. so budget just helps".)*

**Superseded 2026-08-20.** The owner extended the second half of their own reasoning
to cover the first: if tidying one's records is the owner's business, so is keeping
to one's budget. The commitment/record distinction was dropped and budgets became
fully editable like everything else — see the rewritten FR-16. Kept here rather than
deleted because the distinction it drew was a real one, and knowing it was
considered and then abandoned is worth more than a clean page.

## 4. Not decided

| Item | Blocks |
|---|---|
| **Where the data lives** — this phone only, or eventually synced | Narrowed, not closed. Phone-only for now, and the stack decision no longer waits on it: backup is an export file, not sync, so no backend is needed either way. What stays open is whether the data is ever anywhere else — and if it is, the backend lives outside the app in its own stack (owner's position), so the app gains a sync client rather than being restructured |

**Closed 2026-08-19 — the "credit/debit account" naming collision.** Recorded here
only because it sat in the table above as an open blocker until 2026-08-20, long after
it was actually settled and shipped. `Account` carries a `group` of `HOLDING` /
`RECEIVABLE` / `PAYABLE`, and the words "credit" and "debit" appear nowhere. It was
closed **by constraint rather than preference**: NFR-1's fit criterion forbids a
debit/credit column outright, so those terms were never available to choose. Decided
with the schema in `context/index/decisions.md`, and visible on `erd.drawio`.

**Dissolved 2026-08-20 — what state a budget period enters when created after its
own lock date.** Raised earlier the same day, while reviewing the state diagram: a
period created on day 20, or for a month already over, would compute as `locked` (or
`closed`) the instant it existed, because state is derived from the dates rather than
stored — so it would never pass through `open` and could never be edited or deleted.
This has **no referent once FR-16's lock is gone**: a period is always editable, so
there is no lock date to be created after. Recorded rather than deleted because the
underlying lesson outlives the question — *changing a value from stored to derived
silently rewrites every transition that assumed the value could be set independently
of the data it is now computed from.*

**Decided 2026-08-20 — one app-level currency, `IDR` or `USD`, and amounts are stored
as integer minor units.** Promoted to a requirement rather than left as a note, because
choosing it is something the owner does: see **FR-19**, and UC-14 in the workbook. The
owner asked for multi-currency first (IDR, USD, CNY) and withdrew it once the cost was
laid out — rates, per-account currency, and no summable balance sheet. `double` was then
proposed for amounts and rejected on NFR-2 grounds: floating-point error accumulates
across sums and cannot be queried away. Full reasoning in `context/index/decisions.md`.

**Decided 2026-08-21 — a transaction carries an optional free-text note.** One
nullable text column on `Transaction`. Recording it is never required, and nothing in
the app reads it to make a decision — it is the owner's own words about what a row was,
sitting next to the category rather than replacing it. This closes the last open item in
this section that blocked a schema decision.

Nullable rather than an empty string default, because "the owner wrote nothing" and "the
owner wrote an empty note" are the same fact and should have one representation. Nullable
rather than absent, because the column costs nothing today and adding it after the first
migration ships costs a second migration and a new snapshot — and FR-6's "what it was
for" is thin enough that category alone was never obviously all that was meant.

*Consequence.* `Transaction` gains a `note` row on `erd.drawio` (ISSUE-001 re-opened,
same as the `Budget_Period.state` drop), it belongs in FEAT01's first migration, and it
appears on the UC-04 record screen as an optional field. It is **not** searchable —
searching or filtering stays deferred outright (§3), and UC-09's own scope confirms the
exclusion rather than lifting it: its diagram amends the note like any other field and
draws no search. No FR changes: an optional field the
app never reads is not a new capability, it is the shape of FR-6's "what it was for".

**Decided 2026-08-20 — "a month" is a calendar month.** Budget periods run from the
first of the month to the last day of the month, and every report is bucketed the same
way. Owner's call, closing the last §4 item that blocked a schema decision.

The alternative was payday-to-payday — periods anchored to whenever income lands, which
is closer to how money is actually felt month to month. Rejected: it makes a period's
boundaries depend on a *transaction* rather than on the calendar, so a period cannot be
created until its opening payday exists, editing or deleting that transaction silently
moves the boundary, and FR-15's automatic next-period creation has nothing to fire on.
Calendar boundaries are knowable in advance and depend on nothing the owner can edit.

*Consequence — none of the existing artifacts change.* `Budget_Period` already carries
`starts_on` / `ends_on` as plain dates on the ERD, which is the shape this decision
wants; calendar was the assumption throughout, so this confirms what is drawn rather
than revising it. FR-13's "this month", FR-14's non-carry-forward, FR-15's automatic
next period, and FR-16's edit-any-time all now have a defined boundary instead of an
assumed one.

*Worth knowing for later:* this decision is the reason `starts_on` / `ends_on` are
stored per period rather than the period being identified by a bare `YYYY-MM`. Storing
the dates costs nothing today and is what a future payday-to-payday change would need;
the columns are already the general shape.

**Decided 2026-08-20 — skipped months are left alone.** If the app is not opened
for several months, the missed budget periods are **not** backfilled. Gaps in the
history are real and are shown as gaps. *(Owner: "leave it be, it's users commitment
not app problem.")* Consistent with NFR-4 — the app assists, it does not police, and
inventing budgets the owner never set would be the app deciding what their intent
had been. FR-15's auto-carry therefore creates the next period going forward, never
retroactively.

**Decided 2026-08-20 — `Budget_Period` has no stored `state` column.** It is derived
from `starts_on` / `ends_on` and today's date. Recorded with its reasoning in
`context/index/decisions.md`; the ERD was re-opened to drop the column.

**Decided 2026-08-19 — stack and platform.** **Flutter/Dart**, `drift` over
SQLite, no backend. *No longer provisional — see the 2026-08-21 note below.*
Carries a hard constraint: the app must stay light on old Android phones, which
is the one axis where this choice is worse than the native-Android alternative
it replaced. Reasoning, the alternatives weighed (React Native, SvelteKit +
Capacitor, native Kotlin), what is lost (OCR moves from first-party ML Kit to a
plugin; footprint and cold start both worsen), and the build requirements that
follow from the old-phone constraint are in `context/index/decisions.md`.

**Decided 2026-08-21 — both iOS and Android are targets.** *(Owner: "i want to
make it for ios and android.")* This settles the assumption the entry above was
provisional on, and settles it the way that entry predicted: Flutter was chosen
*because* iOS was assumed real, and it now is. The stack decision is closed.

Two things follow that are not obvious. The old-phone constraint is **not**
relaxed by this — a second platform makes it harder to honour, not easier. And
**iOS cannot be built on the owner's machine**, because Apple's toolchain is
macOS-only; the `ios/` folder is generated and versioned from the first commit,
but nothing builds or tests it until there is a Mac, and CI does not cover it.
"Works on Android" is therefore not evidence about iOS.

### Assumed but never actually stated

Recorded so they are confirmed rather than discovered missing during the ERD:

- A transaction has a **date**. Implied everywhere, stated nowhere.
- A transaction has a **free-text note**. Never mentioned; FR-6 says "amount,
  what it was for" and category may be all that was meant. *Confirmed 2026-08-21 —
  it exists, and it is optional. See §4.*
- The owner is the **only user**. Consistent with everything said; never said.

Deferred to the ERD, not an FR concern: whether a budget's identity is separate
from its monthly amount. Owner's position — "it depends on how you query it" —
is reasonable at this level; it becomes a real decision when the Entities sheet
and ERD are built, because trend reporting across months needs a stable handle
on "Food" that survives a rename or a typo.

## 5. Traceability

FR-1..FR-18 promoted 2026-08-19, FR-19 added 2026-08-20, all via Route 2 (FR → UC) of
`context/document-writer-only/workbook-conventions.md`. All 19 FRs are
accounted for: each either produces a UC row or is reclassified as a rule that
constrains one, which is the closure test for this route.

| FR | Workbook Kode | Status |
|---|---|---|
| FR-1 | UC-01 | promoted |
| FR-2 | UC-01 | promoted (same screen, same sitting) |
| FR-3 | UC-02 | promoted |
| FR-4 | UC-02 | promoted (one form serves all three account groups) |
| FR-5 | UC-02 | promoted (same) |
| FR-6 | UC-04 | promoted |
| FR-7 | UC-05 | promoted |
| FR-8 | UC-06 | promoted |
| FR-9 | UC-07, UC-08 | promoted — split on direction of the money, not on actor |
| FR-10 | UC-13 (defining the tags), UC-04/05 (applying them) | promoted |
| FR-11 | UC-10, UC-08 | promoted |
| FR-12 | UC-11 | promoted |
| FR-13 | UC-12 | promoted |
| FR-14 | — | **not a UC** — a system rule, no actor. Constrains UC-11, UC-12 |
| FR-15 | UC-11 | promoted (step 1, the automatic pre-fill) |
| FR-16 | UC-11 | promoted — **rewritten 2026-08-20**, the lock was removed; now a rule that budgets stay editable, constraining UC-11 rather than adding a step |
| FR-17 | — | **not a UC** — a system rule, no actor. Constrains UC-04, UC-12 |
| FR-18 | UC-09, UC-03 | promoted, narrowed — see below |
| FR-19 | UC-14 | promoted 2026-08-20 — the currency choice is an action with an actor, so it takes a row rather than sitting in a note |

**Where FR-18 landed.** Taken literally, "full CRUD across everything" is one
row per verb per entity — roughly 25 rows for a single-user app, most of them
noise. Owner's ruling (2026-08-19): a dedicated correction use case only for
transactions (UC-09), plus one for correcting what an account holds (UC-03).
For every other entity — accounts, budget groups, categories, subcategories,
people — edit and delete are alternate flows of the use case that creates it,
recorded in that row's `Deskripsi`. No entity is create-only, so FR-18 still
holds; it just doesn't get 25 rows.

**Where the NFRs went.** Nowhere, deliberately — the workbook defines no NFR
sheet, and `workbook-conventions.md` says to attach NFRs to the `Kode` they
constrain with a measurable fit criterion. NFR-1, NFR-2 and NFR-4 are policies,
not measurable predicates, so they stay here as the source of record and are
cited inline in the `Deskripsi` of every row they bear on. NFR-3 constrains the
shape of the data, not any single use case, and is a question for the ERD.

**Actor.** Every row names `Owner`. That is degenerate — one actor, one user —
but it passes admission test 1 honestly rather than by writing "the system".
