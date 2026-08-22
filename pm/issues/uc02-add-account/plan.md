# UC02-add-account — Set up a place money lives

**Status:** DONE 2026-08-22. Planned under unattended mode (AUTO-CONFIRMED the same
day): halted at D10 (`pm/questions.md` **Q2**), then the owner answered **Option A** — this
issue is create-only, and account rename / edit / delete moves to the new tracked issue
`UC02B-edit-account`. Every decision below cites an already-confirmed artifact: D1–D9 cite
their diagrams, workbook rows, FRs and shipped code; D10 cites the owner's own Q2 answer as
recorded at `context/index/decisions.md` (2026-08-22, *Account CRUD splits from UC-02*) and
`pm/tracker.yaml`'s UC02B row. Built to D1's three files plus the one `app.dart` line;
46 tests green; no schema change (`drift_schema_v1.json` byte-identical). The as-built pass
corrected this diagram's isolate note only — messages 7–8 are UC-01's read path and were
correctly drawn ahead of the build order (D9).

**Traces to:** UC-02 (`docs/workbook.xlsx` → `UC FR`), FR-3, FR-4, FR-5.
**Depends on:** `UC14-choose-currency` — **DONE** 2026-08-22 in `pm/tracker.yaml`.
**Preflight:** passes. The one declared dependency is Done; `FEAT01-foundation`,
`UC13-categories` and `UC11-set-budget` are also Done. No other issue is active, and no
Done issue has written anything under `app/lib/src/accounts/` except
`accounts_table.dart` (FEAT01). The halt was a content halt, not a preflight failure;
the new `UC02B-edit-account` row depends on this issue, so there is no scope overlap.

---

## Goal

The owner can create an account — naming it, choosing which of FR-1's three groups it
belongs to, and entering what is in it today — and the row lands in the `Accounts` table
that `FEAT01` already shipped. This is the Accounts module's first DAO, first provider
and first screen, and it makes `Account` the fourth entity in the app with a real write
path after `Category`, `Budget_Group` and `Budget_Period`.

It is **not** the issue that lands the `Transactions` write path. See D4 — four confirmed
artifacts say so, and `pm/tracker.yaml`'s own row for this issue says the opposite. That
contradiction is recorded below rather than silently resolved.

---

## Scope: the sequence diagram, reconciled

`CLAUDE.md`: *a plan's scope IS whatever its sequence diagram shows.*
`docs/diagrams/seq-uc02-add-account.drawio`, render committed at
`pm/issues/uc02-add-account/seq-uc02-add-account.png`, rendered and looked at while
writing this plan (`lessons.md` §3, §4 — labels live on `<UserObject label="…">`
wrappers, so the labels below come from the render, not from a `mxCell value=` parse).

**Eight messages, one flow, no `alt`, no `opt`, no loop.**

| # | From → To | Message |
|---|---|---|
| 1 | Owner → `AccountFormScreen` | enter name, group (HOLDING / RECEIVABLE / PAYABLE), opening amount |
| 2 | `AccountFormScreen` → `AccountsNotifier` | `addAccount(name, group, openingAmount)` |
| 3 | `AccountsNotifier` → `AccountDao` | `insert(account)` |
| 4 | `AccountDao` → `AppDatabase` | insert account row |
| 5 | `AppDatabase` ⇢ `AccountDao` | new account id *(reply)* |
| 6 | `AccountDao` ⇢ `AccountsNotifier` | ok *(reply)* |
| 7 | `accountBalancesProvider` → `BalanceSheetScreen` | AccountBalance list (new account included) |
| 8 | `financialPositionProvider` → `BalanceSheetScreen` | FinancialPosition (updated four figures) |

Plus one note: *"AccountDao to AppDatabase messages cross the isolate boundary
(NativeDatabase.createInBackground, decided 2026-08-20)."*

**Lifeline check — every lifeline already exists on a class diagram** (the rule from
`ISSUE-008`, and the one that caught a real defect per `lessons.md` §10). All seven
non-actor lifelines are boxes on `docs/diagrams/class-accounts.drawio`, spelled
identically:

| Lifeline | On `class-accounts.drawio` as | Owned by |
|---|---|---|
| Owner | actor, not a class | — |
| `AccountFormScreen` | `AccountFormScreen` — *UC-02, UC-03 · ConsumerWidget* | **this issue** |
| `AccountsNotifier` | `AccountsNotifier` — *Notifier, exposed as `accountsProvider`; `addAccount()` · `adjustAccount()` · `markSettled()`* | **this issue** (`addAccount()` only) |
| `AccountDao` | `AccountDao` — *`watchPosition()` `watchBalances()` `watchDebtProgress()` / `insert()` `update()` `setSettled()`* | **this issue** (`insert()` only) |
| `AppDatabase` | `AppDatabase` | FEAT01, shipped |
| `accountBalancesProvider` | `accountBalancesProvider` — *StreamProvider* | UC-01 (D9) |
| `financialPositionProvider` | `financialPositionProvider` — *StreamProvider · UC-01* | UC-01 (D9) |
| `BalanceSheetScreen` | `BalanceSheetScreen` — *UC-01 · ConsumerWidget* | UC-01 (D9) |

**No class is invented and none is missing.** Nothing in this issue needs a class the
diagrams do not have.

**Three discrepancies for the as-built pass — recorded, not fixed here** (the main
session owns diagram edits):

1. **The isolate note is stale**, on this diagram as on thirteen others. `FEAT01` used
   `drift_flutter`'s `driftDatabase()`, which calls `NativeDatabase.createBackgroundConnection`,
   not `createInBackground`. This is `pm/findings.md` **F3**, repo-wide; record against
   F3, do not fix fourteen diagrams from this issue.
2. **Messages 7 and 8 cannot fire at this issue's close**, because none of their
   producers exists until UC-01 (D9). The diagram is right about the architecture and
   ahead of the build order.
3. **The diagram draws no rename / edit / delete flow**, while the workbook's UC-02 row
   says those are alternate flows of this very use case. **Resolved by Q2** (see below):
   the diagram was a boundary, not an omission — the flows belong to `UC02B-edit-account`.

---

## The halt — resolved 2026-08-22 (Q2, Option A)

This issue halted 2026-08-22 because one decision could not be cited: **does this issue
build renaming, editing and deleting an account?** The owner answered
**`pm/questions.md` Q2: Option A — create-only**, recorded at
`context/index/decisions.md` (2026-08-22, *Account CRUD splits from UC-02*) with the
`UC02B-edit-account` row added to `pm/tracker.yaml`. What had blocked:

Two owner-confirmed artifacts disagreed, and this was not a case where one is obviously
stale prose:

- **`docs/workbook.xlsx`, UC-02 `Deskripsi`, verbatim:** *"Alternate flows: renaming an
  account, changing its details, or deleting it are alternate flows of this use case, not
  separate use cases (owner's decision, 2026-08-19: only transactions get their own
  correction use case). Correcting the amount an account holds is UC-03."*
- **`docs/diagrams/seq-uc02-add-account.drawio`** draws create and nothing else — eight
  messages, one flow, no `alt`.

And a stated requirement is on the workbook's side: **FR-18 — "Full CRUD across
transactions, accounts, budgets, categories and subcategories, people, and debts. No
entity is create-only, and no entity has an exception."** I checked every sequence
diagram in `docs/diagrams/` for an account rename, edit or delete. **There is none.**
`seq-uc03` writes an `adjustment` *transaction*; `seq-uc10` calls `setSettled()`. So on
the sequence-diagram-is-the-scope reading, **`Account` is the one entity in this project
that no issue ever gives update or delete** — which FR-18 forbids by name. `AccountDao`
on `class-accounts.drawio` even carries an `update()` no diagram calls.

**Why this cannot wait until after the issue ships.** It is not a labelling question; it
changes the deliverable and possibly the schema:

- `AccountFormScreen` is a create-only form under one answer and a create/edit/delete
  form under the other; `AccountsNotifier` gains two methods `class-accounts.drawio` does
  not list; `AccountDao` gains `delete()`, which is on no class diagram at all.
- **Deleting an account has an undecided data consequence and a possible refusal.**
  `Transactions.fromAccountId` and `toAccountId` reference `Accounts` with **no
  `onDelete`** (`app/lib/src/transactions/transactions_table.dart`), so SQLite's default
  `NO ACTION` makes deleting a referenced account **fail** — a refusal, which NFR-4's fit
  criterion (*zero* refusals) forbids outright. Making it not refuse means choosing what
  happens to those transactions, and every non-refusing option is a schema change:
  `ON DELETE SET NULL` or `CASCADE` both alter the table, which means `schemaVersion 2`,
  a migration and a new `drift_schemas/` snapshot. `lessons.md` §8 is explicit that this
  is never one edit. UC-11's precedent (null the tag so the money reappears under Others)
  does **not** transfer: `budget_group_id` is an optional tag, whereas the from/to account
  is the transaction's identity, and a transaction with neither side is not a record of
  anything.

Answering after UC-02 closes means either reopening a Done issue (`pm/findings.md` opens
by warning that a run which reopens closed issues churns without converging) or shipping
an `Account` that violates FR-18 with no issue in the backlog that would ever fix it.

**Blast radius — seven issues.** UC02-add-account itself, then `UC03-adjust-account`,
`UC01-balance-sheet` and `UC10-debt-progress` directly behind it, then
`UC04-record-money-movement`, then `UC09-review-and-correct` and `UC12-budget-consumption`.
That is the entire remaining backlog: the other chain (UC13, UC11, UC14) is already Done,
so nothing else can run while this is open.

Question filed as **Q2** in `pm/questions.md`; answered **Option A** the same day.

**What the ruling changes here, and what it does not.** The FR-18 gap is real and
accepted: until `UC02B-edit-account` lands, `Account` is create-only and FR-18 is
unsatisfied for it — filed as `pm/findings.md` **F14**, on the record, not an oversight.
The workbook's UC-02 `Deskripsi` still promises the alternate flows; correcting it is
UC02B's close business (its tracker row says so), not this issue's. The delete-FK
question — what happens to a deleted account's transactions — was **not** answered by
Q2; it moves to `UC02B-edit-account` with its own sequence-diagram prerequisite. None of
that touches this issue: it stays exactly D1's three files plus the `app.dart` line,
no schema change, no `AccountDao.delete()`.

---

## Decisions

D1–D9 are derived and cited and were unaffected by Q2. D10 records the ruling.

### D1 — Three new files, and nothing else

*Cites:* `docs/diagrams/class-accounts.drawio` (the four boxes this issue implements);
`context/index/map.yaml` `code:` (the one-directory-per-module layout FEAT01 fixed and
UC-13, UC-11 and UC-14 each followed); the sequence diagram's lifelines.

| File | Contains |
|---|---|
| `app/lib/src/accounts/account_dao.dart` | `AccountDao` — `insert()` only |
| `app/lib/src/accounts/accounts_providers.dart` | `AccountsNotifier`, exposed as `accountsProvider` |
| `app/lib/src/accounts/account_form_screen.dart` | `AccountFormScreen` |

Plus tests under `app/test/accounts/`, and one line changed in `app/lib/src/app.dart`
(D8). **No other file is touched.** `accounts_table.dart`, `app_database.dart`,
`pubspec.yaml`, `drift_schemas/` and every file under `transactions/`, `budgeting/` and
`settings/` are untouched — this issue has no schema change, so `drift_schema_v1.json`
must be **byte-identical** at close, the check UC-11 and UC-14 both ran.

The plural `accounts_providers.dart` matches
`app/lib/src/transactions/transactions_providers.dart` and
`app/lib/src/settings/settings_providers.dart`.

### D2 — Every name comes from the class diagram verbatim

*Cites:* `context/coding-conventions/README.md` §*The rule that outranks the rest* —
*"Class names in code must match the class diagrams exactly."*

`AccountFormScreen`, `AccountsNotifier`, `accountsProvider`, `AccountDao`, `AppDatabase`,
and the two method names the sequence diagram spells: `addAccount(name, group,
openingAmount)` on the Notifier (message 2) and `insert(account)` on the DAO (message 3).
Enum values are `AccountGroup.HOLDING` / `RECEIVABLE` / `PAYABLE`, SCREAMING_CASE exactly
as `docs/enums.md` and the shipped `accounts_table.dart` spell them —
`constant_identifier_names` is already disabled for this reason (FEAT01).

### D3 — `AccountDao` is a plain class composing `AppDatabase`; the providers are hand-written

*Cites:* `context/index/decisions.md`, 2026-08-21 — *"UC-13: two rulings the real
toolchain forced above the database"*: a DAO drawn with `update()`/`delete()` cannot be a
`DatabaseAccessor`/`@DriftAccessor` (`invalid_override`), and `riverpod_generator` throws
`InvalidTypeException` on a provider typed over a drift-generated row class.

So: no `@DriftAccessor`, no `daos:` entry, `app_database.dart` untouched, no `@riverpod`.
Shipped shape to follow: `app/lib/src/settings/settings_dao.dart` (the simplest),
`app/lib/src/transactions/category_dao.dart`, `app/lib/src/budgeting/budget_dao.dart`.

### D4 — The opening amount is a column on `Accounts`. This issue writes **no** transaction and touches **no** Transactions table

*Cites, four artifacts in agreement:*

- **The sequence diagram**, messages 3–4: `insert(account)` → `insert account row`. There
  is no `TransactionDao` lifeline and no transaction insert anywhere on it. Contrast
  `seq-uc03-adjust-account.drawio`, which draws exactly that — *"insert(kind=adjustment,
  account, diff)"* → *"insert adjustment transaction row"*, with a note explaining that
  `AccountDao` writes into `Transactions` itself.
- **`docs/workbook.xlsx`, UC-02, `Entity/Objek Terkait`: `Account`.** One entity. UC-02's
  `Output` is *"New account created with its opening amount"*.
- **`docs/enums.md`**, the `Transaction.kind` table: `adjustment` traces to **FR-18,
  UC-03** — not to FR-3 or UC-02. `pm/issues/001-erd/plan.md` **D1**'s table says the same:
  *Adjustment (UC-03)*.
- **The shipped schema.** `app/lib/src/accounts/accounts_table.dart` has
  `IntColumn get openingAmount => integer()()`, landed by `FEAT01` at `schemaVersion 1`
  and closed. The opening amount already has a home.

**Two consequences worth stating, because both look like open questions and neither is.**

- *Which fields does the opening amount fill?* One: `Accounts.opening_amount`. There is no
  `from_account_id` / `to_account_id` question to answer, because no transaction row is
  written.
- *Does a zero opening amount write a transaction, or none?* The question dissolves — a
  zero opening amount is the integer `0` in a required column. **No branch, no condition,
  nothing conditional to build.** This is why the sequence diagram has no `alt`.

**This flatly contradicts `pm/tracker.yaml`'s row for this issue**, which reads: *"FR-3's
opening amount is an `adjustment` transaction per ERD D1, so this issue lands the
Transactions table and one write path."* ERD D1 does not say that — its own table assigns
`Adjustment` to UC-03 — so the row's claim is unsupported by the source it cites, and the
diagram, the workbook, `enums.md` and the shipped column all read the other way. Recorded
as a finding for the owner (see *Contradictions found*); not silently resolved, and not
edited by this plan.

### D5 — One form, three fields, nothing group-specific

*Cites:* the sequence diagram, message 1 — *"enter name, group (HOLDING / RECEIVABLE /
PAYABLE), opening amount"*; `docs/workbook.xlsx` UC-02 `Input` — *"Account name, which of
the three groups it belongs to …, and the amount in it today"*; UC-02 `Deskripsi` — *"One
form serves all three groups. A credit card or a loan is set up **exactly like a wallet**
… A person who owes money is set up the same way"*; FR-3, FR-4, FR-5; and the shipped
`Accounts` table, whose only owner-supplied columns are `name`, `group`, `openingAmount`.

**What differs between HOLDING, RECEIVABLE and PAYABLE at creation: only the enum value.**
There is **no** counterparty field and **no** due date — FR-5's person *is* the account
name (*"what Budi owes me is one number I can look at"*), and no column exists for either.
`settled` / `settledAt` are FR-11's and are set by UC-10's `markSettled()`, not by this
form; they take the table's default.

### D6 — The amount is stored exactly as entered, signed; the app applies no group-dependent sign

*Cites:* FR-4 — *"it just holds a negative amount"*; the same sentence in UC-02's workbook
`Deskripsi`, attached to *"set up exactly like a wallet"*; the sequence diagram, messages
2→3, where `openingAmount` passes from the form to `insert(account)` with **no
transformation message between them**; and `Accounts.openingAmount` being a plain signed
`IntColumn` with no constraint and no default.

A `PAYABLE` account holds a negative amount because the owner enters a negative amount.
The form does not negate on the owner's behalf — that would be a group-specific behaviour
in a form the workbook calls identical across groups, and it would silently store a
different number from the one typed. The amount field therefore has to accept a leading
minus sign; refusing one would be a refusal (NFR-4).

Amounts are `int` minor units of `Settings.currency` throughout, never a `double`
(`docs/enums.md`; NFR-2), and this screen **does not convert or re-label anything** —
`decisions.md` 2026-08-22, *currency re-labels, never converts*.

### D7 — Nothing on this screen is disabled and nothing is refused

*Cites:* **NFR-4**, fit criterion — *"no user action in the app is refused. Every action
succeeds, with a warning at most … There are no exceptions"*; UC-14 D4, the same ruling
applied to that screen; FR-3/FR-4/FR-5, none of which makes any field mandatory.

- All three `AccountGroup` values are offerable at all times.
- The save control is **always enabled** — including with an empty name and an empty
  amount. A form that will not submit until a field is filled is a refusal, and under
  NFR-4 that is a requirements violation, not a UI choice.
- No confirmation that can end in "no". If a warning is ever wanted here, it is a message,
  not a branch — and the diagram draws none, so none is built.

**`pm/findings.md` F7 is noted, not solved.** UC-11's screen parses its amount with
`int.tryParse(...) ?? 0`, so an unparseable amount is silently saved as zero; this issue
introduces a second amount field with the same shape. The owner has not ruled on F7, and
inventing a validation rule here would either refuse (violating NFR-4) or invent a
behaviour nobody chose. So this issue **follows the shipped precedent** and the consistency
question goes back on F7 at close — one more screen affected, not a new finding.

### D8 — `AccountFormScreen` becomes `MaterialApp.home`, orphaning `CurrencyScreen`

*Cites:* the sequence diagram, message 1 (the owner must be able to reach this screen);
the diagram draws **no navigation lifeline** and no class diagram has one;
`context/coding-conventions/README.md` forbids naming a class the class diagrams lack;
`pm/findings.md` **F8**; UC-14 **D3**, which made this exact call and predicted this exact
consequence for UC-02.

`app/lib/src/app.dart` currently reads `home: const CurrencyScreen()`. Pointing it at
`AccountFormScreen` **orphans `CurrencyScreen`** — the third dead screen, after
`CategoryManagerScreen` and `SetBudgetScreen`, exactly as F8 predicts. **The cost is named
here rather than discovered at close, and it is recorded against F8, not fixed.** A
navigation host is on no class diagram and cannot be invented by this issue; whether it
becomes its own issue is the owner's call, and F8 already asks it.

Explicitly temporary: **FR-1 gives the primary screen to UC-01** permanently (*"the
primary screen — not a report behind a menu"*), and `pm/tracker.yaml`'s UC01 row says so.
Re-pointing `home` is UC-01's business.

### D9 — Messages 7 and 8 are UC-01's classes; this issue builds none of them

*Cites:* `docs/diagrams/seq-uc01-balance-sheet.drawio`, which draws the **construction**
of exactly these — `watch()` → `watchPosition()` → *"query accounts + transactions"* →
`Stream<FinancialPosition>`, and the same chain for `watchBalances()`;
`class-accounts.drawio`, which labels `financialPositionProvider` and `BalanceSheetScreen`
*UC-01*; `pm/tracker.yaml`'s UC01 row (*"FR-1's four figures on the primary screen … one
query joining Accounts to Transactions"*); and `CLAUDE.md`'s one-diagram-per-use-case
rule, which makes UC-01's diagram UC-01's scope. Two diagrams cannot both own the
construction of the same class, and building them here would be the scope overlap
preflight forbids.

So this issue builds **no** `accountBalancesProvider`, **no** `financialPositionProvider`,
**no** `AccountDao.watchBalances()` or `watchPosition()`, and **no** `BalanceSheetScreen`.
Messages 7 and 8 appear on this diagram as the *effect* of the write — the read-path
emission that `sequence-conventions.md` requires instead of a reply arrow to the screen.

**Said plainly, because it is the one place this plan is honestly uncomfortable:** at this
issue's close, messages 7 and 8 **cannot happen**, because the classes that would send
them do not exist yet and `UC01-balance-sheet` is sequenced after this issue. This is a
build-order artifact of the tracker's own dependency (`UC01 depends_on UC02`), not a
scope cut, and the as-built pass records it.

### D10 — **RESOLVED (owner, 2026-08-22): rename / edit / delete is OUT.** This issue is create-only

*Cites:* **`pm/questions.md` Q2, ANSWERED — Option A**, the owner's ruling of
2026-08-22; recorded at `context/index/decisions.md` (2026-08-22, *Account CRUD splits
from UC-02*) and in `pm/tracker.yaml`'s corrected UC02 row (*"SCOPE SETTLED 2026-08-22
(pm/questions.md Q2): create only, as the diagram draws"*) plus the new
`UC02B-edit-account` row. The gap FR-18 leaves open is tracked as `pm/findings.md`
**F14**.

Consequences, all following from that ruling:

- This issue stays **exactly D1's three files** (`account_dao.dart`,
  `accounts_providers.dart`, `account_form_screen.dart`) **plus the one `app.dart` line**
  (D8). No schema change: `schemaVersion` stays 1, no migration, no new snapshot.
- **No `AccountDao.delete()` is written here**, and no `renameAccount()` /
  `deleteAccount()` on `AccountsNotifier`. The DAO's `insert()` remains its only method
  in this issue (D1, D2).
- The sequence diagram needed **no redrawing**: it already draws create and nothing else,
  which the ruling confirms was a boundary, not an omission. Discrepancy 3 under *Scope*
  closes with this ruling.
- **FR-18 for `Account` is discharged by `UC02B-edit-account`**, not by this issue.
  UC02B depends on this one in the tracker, needs its own sequence diagram before it can
  be planned (no diagram anywhere covers account rename/edit/delete), and carries the
  still-unanswered delete question about a deleted account's transactions — the FKs have
  no `onDelete`, so every non-refusing delete is a `schemaVersion 2` migration. That is
  UC02B's planning problem, deliberately not answered here.

---

## Steps

Executable in order. Q2 is answered and the file is re-marked, so the planning gate is
satisfied.

1. `AccountDao` in `app/lib/src/accounts/account_dao.dart` — a plain class composing
   `AppDatabase` (D3), with `insert()` (D2). No `watch*` methods (D9). No `update()` or
   `delete()` — those are UC02B's (D10).
2. `AccountsNotifier` in `app/lib/src/accounts/accounts_providers.dart`, exposed as
   `accountsProvider`, with `addAccount(name, group, openingAmount)` (D2), hand-written,
   no `@riverpod` (D3). It reads no stream, so `decisions.md`'s 2026-08-22
   `Notifier`-not-`StreamNotifier` ruling has **nothing to bite on here** — that ruling is
   about a screen reading more than one drift stream, and this screen reads none. Checked
   deliberately rather than assumed.
3. `AccountFormScreen` in `app/lib/src/accounts/account_form_screen.dart` — the three
   fields of D5, always-enabled controls (D7), amounts as signed `int` minor units (D6).
4. Point `app/lib/src/app.dart`'s `home` at `AccountFormScreen` and update the doc comment
   above it the way UC-14's names its own predecessor (D8).
5. Tests in `app/test/accounts/`, per the Definition of done below.
6. Run all four commands from `app/` (Definition of done). Fix, repeat until clean, and
   run them **before** the commit — CI runs the same steps on every push.
7. Verify `app/drift_schemas/drift_schema_v1.json` is **byte-identical** to its committed
   version. If it is not, something in this issue touched the schema, which D1 says it
   must not.
8. Correct any `context/coding-conventions/` file this issue contradicted, in place, and
   say so in `pm/log.md`. This is the first issue to write a form with multiple fields and
   the first to write into the Accounts module.
9. Close per `CLAUDE.md`'s checklist. Named individually because `lessons.md` §1 is about
   registers nobody remembers:
   - **As-built pass on `seq-uc02-add-account.drawio`** — the three discrepancies under
     *Scope*. The stale isolate note is `pm/findings.md` **F3** and is recorded there, not
     fixed in fourteen diagrams from here. Whatever is edited, re-export the PNG to
     `pm/issues/uc02-add-account/` and **look at the render** (`lessons.md` §3); refresh
     `docs/diagrams/renders.lock`.
   - **`pm/findings.md` F8** — append that UC-02 re-pointed `home` and orphaned
     `CurrencyScreen`, the fifth screen in the chain. Recorded, **not fixed**.
   - **`pm/findings.md` F7** — append that a second amount field now shares the same
     parse, so the owner's ruling covers two screens rather than one.
   - **`pm/tracker.yaml`** — Done plus a one-line summary. This issue's own row has
     **already been corrected** (2026-08-22, while planning): the wrong
     `adjustment`-transaction claim is gone and the Q2 scope ruling is recorded there, so
     only the status and summary change now.
   - **`context/index/map.yaml`** — a `UC-02 → app/lib/src/accounts/` entry under `code:`,
     in FEAT01's shape.
   - **`context/index/decisions.md`** — only if the toolchain forced a durable ruling, as
     it did at FEAT01, UC-13 and UC-11. Not a formality; not an obligation either.
   - **`docs/workbook.xlsx`** UC-02 marked implemented (`general-rules.md`, done, step 4).
   - **`pm/questions.md`** — verify Q2 is ANSWERED with its pointer.
   - **`pm/log.md`** — a dated entry plus the current-state block at its head;
     **`pm/active.json`** → the next issue.

---

## Definition of done

*Cites:* FEAT01 D7 and UC-14 D8 — the same four commands, for the same reason (no Android
SDK on this machine; `app/ios/` cannot be built without a Mac, `decisions.md` 2026-08-21).

**Headless only. Nothing here needs a running app, an emulator or an Android SDK** — if a
step seems to, that is a scope error, not a reason to install one. `flutter` is at
`C:/flutter/bin/flutter`. All four run from `app/`:

1. `dart run build_runner build` — succeeds.
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under `strict-casts` / `strict-inference` / `strict-raw-types`.
   A warning left in place is a decision and gets argued in this file, not ignored.
4. `flutter test` — green, against `NativeDatabase.memory()`, with drift never mocked.

Plus: `git diff --stat app/drift_schemas/` is **empty** (step 7).

**Tests, each named for the requirement it defends** (`context/coding-conventions/testing.md`):

- **DAO, FR-3** — `insert()` writes a row on a fresh in-memory database; reading it back
  gives the same `name`, `group` and `openingAmount`.
- **DAO, `docs/enums.md`** — an account inserted as `AccountGroup.PAYABLE` reads back as
  `PAYABLE`, and the raw `group` column holds the **text** `'PAYABLE'`, not an index. This
  is the assertion that the `.textEnum<T>()` rule survived the first Accounts write.
- **DAO, FR-4 / D6** — a negative `openingAmount` is stored and read back **unchanged and
  still negative**. This is D6 made checkable: the app applies no sign transformation.
- **DAO, FR-5** — three accounts, one per `AccountGroup`, coexist in one table with no
  subtype table and no extra columns (D5).
- **DAO, D4** — after inserting an account with a non-zero opening amount, the
  `Transactions` table is **still empty**. This is the single most valuable test in the
  issue: it pins the fact that UC-02 writes no ledger row, against a tracker row that says
  it does. Repeat with a **zero** opening amount and assert the same — one account row,
  zero transaction rows, no branch.
- **Widget, NFR-4** — the save control is **enabled** with every field empty, and pressing
  it proceeds rather than refusing; all three `AccountGroup` values are selectable. This is
  the zero-refusals criterion asserted directly.
- **Widget** — the screen renders and `addAccount` reaches the database, via a
  `ProviderScope` override over an in-memory `AppDatabase`.
- **FR-18** — *resolved by Q2 / D10.* The edit test and delete test on `Account` that
  `testing.md` names for FR-18 **belong to `UC02B-edit-account`**, not to this issue. This
  file writes no edit or delete code and asserts none. FR-18 for `Account` stays
  unsatisfied until UC02B lands — the gap is accepted on the record as
  `pm/findings.md` F14, so it must not be mistaken here for a covered requirement.

---

## Out of scope

- **Renaming, editing or deleting an account.** Resolved OUT of this issue by Q2 / D10.
  It is `UC02B-edit-account` in `pm/tracker.yaml`, TODO, with its own sequence-diagram
  prerequisite and its own open question about a deleted account's transactions. No
  `renameAccount()` / `deleteAccount()` on the notifier, no `update()` / `delete()` on
  the DAO, no edit UI, and no schema change for delete here.
- **UC-03's adjustment path.** `adjustAccount()`, `kind=adjustment`, and any write to
  `Transactions` (D4). `seq-uc03-adjust-account.drawio` owns that flow.
- **The `Transactions` table entirely.** No read, no write, no join. The tracker row for
  this issue says otherwise and is wrong (D4).
- **UC-01's balance sheet.** `financialPositionProvider`, `accountBalancesProvider`,
  `BalanceSheetScreen`, `FinancialPosition`, `AccountBalance`, `AccountDao.watchPosition()`
  and `watchBalances()`, and the cross-module SQL join behind them (D9).
- **UC-10's debt progress.** `debtProgressProvider`, `DebtProgress`,
  `AccountDao.watchDebtProgress()`, `AccountsNotifier.markSettled()`,
  `AccountDao.setSettled()`, and the `settled` / `settledAt` columns, which take their
  table defaults here.
- **A list of existing accounts.** The diagram shows no read on this screen; the form
  does not display what already exists.
- **A navigation host, router or menu.** On no class diagram; `pm/findings.md` F8 (D8).
- **Any schema change, migration or new snapshot.** `schemaVersion` stays 1 (D1).
- **Deciding `pm/findings.md` F7** — the unparseable-amount behaviour is the owner's call
  and covers UC-11's screen too (D7).
- **Fixing the stale isolate note across the other thirteen diagrams.** F3, repo-wide.
- **Renaming the package / repo / diagram-title split** (`moneytracker` vs `uangsaku`) —
  FEAT01 D1 left it alone deliberately and so does this.

---

## Contradictions found while planning — for the owner, not fixed here

1. **`pm/tracker.yaml`'s UC02 row was wrong about this issue's scope** and cited a source
   that does not support it. It said the opening amount is an `adjustment` transaction
   *"per ERD D1"*; ERD D1's own table assigns `Adjustment` to **UC-03**, `docs/enums.md`
   traces it to **FR-18, UC-03**, the workbook's UC-02 row lists **one** entity
   (`Account`), the sequence diagram writes only an account row, and `FEAT01` shipped
   `Accounts.opening_amount` as a real column. Four artifacts against one prose summary.
   `lessons.md` §1 — the register that carries a rationale is not the one that gets
   corrected when the rationale stops being true. **Already corrected 2026-08-22**, while
   planning this issue; recorded here because D4's reasoning is why it was wrong.
2. **No sequence diagram in the project covers account rename, edit or delete**, while
   FR-18 says no entity is create-only and no entity has an exception, and the workbook
   puts those flows in UC-02. **Resolved by Q2 (Option A)**: the flows move to
   `UC02B-edit-account`; until that lands, FR-18 is unsatisfied for `Account` by
   accepted decision, tracked as `pm/findings.md` F14.
3. **`class-accounts.drawio` gives `AccountDao` an `update()` that no sequence diagram
   calls.** Consistent with the workbook's alternate flows and inconsistent with the
   diagrams. Resolved with Q2: `update()` belongs to UC02B; this issue implements only
   `insert()`. The class diagram needs no edit for this issue.

---

## Open questions — genuinely non-blocking

- **`pm/findings.md` F7, applied here.** Which non-refusing behaviour is wanted when an
  amount will not parse. It does not block, because D7 follows the shipped precedent and
  the answer changes one line on two screens whenever it comes.
- **`pm/findings.md` F8.** Whether a navigation host becomes its own issue before the next
  screen lands. It does not block, because D8 continues the pattern the previous three
  screen issues used; it does get worse by one screen each time it is deferred, and this
  issue makes it three dead screens out of four.
