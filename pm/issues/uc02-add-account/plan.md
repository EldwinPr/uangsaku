# UC02-add-account — Set up a place money lives

**Status:** **HALTED 2026-08-22 — awaiting owner ruling.** Nine of the ten decisions
below are derived and cited and stand as written. **D10 cannot be derived from any
confirmed artifact**, and it changes what files this issue creates and whether it needs a
schema migration, so it is not deferrable to the close. The question is
`pm/questions.md` **Q2**. Everything already worked out is kept in place so the research
is not repeated when the ruling lands; on an answer this file becomes `AUTO-CONFIRMED`
(or `PROPOSED`, if the owner is present) with D10 filled in and the steps unchanged.

**Traces to:** UC-02 (`docs/workbook.xlsx` → `UC FR`), FR-3, FR-4, FR-5.
**Depends on:** `UC14-choose-currency` — **DONE** 2026-08-22 in `pm/tracker.yaml`.
**Preflight:** passes. The one declared dependency is Done; `FEAT01-foundation`,
`UC13-categories` and `UC11-set-budget` are also Done. No other issue is active, and no
Done issue has written anything under `app/lib/src/accounts/` except
`accounts_table.dart` (FEAT01). The halt is a content halt, not a preflight failure.

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
   says those are alternate flows of this very use case. That is the halt — see below.

---

## The halt

**One decision cannot be cited, and it is D10: does this issue build renaming, editing
and deleting an account?**

Two owner-confirmed artifacts disagree, and this is not a case where one is obviously
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

Question filed as **Q2** in `pm/questions.md`.

---

## Decisions

D1–D9 are derived and cited; they do not depend on the answer to D10 and are not expected
to change. D10 is the halt.

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

### D10 — **BLOCKED.** Whether account rename / edit / delete is in this issue

Cannot be cited; see *The halt* above and `pm/questions.md` **Q2**. What is already
derived and will not need re-deriving whichever way the ruling goes:

- If **out** — this issue is exactly D1's three files, and `Account`'s missing update and
  delete becomes its own tracked row with its own sequence diagram before FR-18 can be
  called satisfied.
- If **in** — add `renameAccount()` / `deleteAccount()` to `AccountsNotifier` and
  `update()` / `delete()` to `AccountDao`. `update()` is already on
  `class-accounts.drawio`; **`delete()` is not**, so the class diagram needs an edit
  (a finding to raise, not an invention). `seq-uc02-add-account.drawio` needs the alternate
  flows drawn. And the FK question above must be answered first, because on the current
  schema a delete of a referenced account **fails**, which NFR-4 forbids — so this branch
  carries a `schemaVersion 2` migration and a new snapshot, and this issue stops being
  a no-schema-change issue.

---

## Steps

Executable in order **once Q2 is answered and this file is re-marked.** Step 0 is the gate.

0. **Do not start.** `general-rules.md`'s planning gate is not satisfied by a `HALTED`
   plan. When the owner answers Q2: record the answer at its canonical home
   (`context/index/decisions.md` for a design ruling, `docs/fr-nfr.md` §4 if it changes a
   requirement), mark Q2 ANSWERED with a pointer, fill in D10, and set this status line.
1. `AccountDao` in `app/lib/src/accounts/account_dao.dart` — a plain class composing
   `AppDatabase` (D3), with `insert()` (D2). No `watch*` methods (D9).
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
   - **`pm/tracker.yaml`** — Done plus a one-line summary, **and correct this issue's own
     row**, whose `adjustment`-transaction claim D4 refutes. A tracker row nobody corrects
     is exactly `lessons.md` §1.
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
- **FR-18** — *deferred to D10.* If D10 lands **in**, this issue owes an edit test and a
  delete test on `Account`, the pair `testing.md` names for FR-18. If it lands **out**,
  FR-18 for `Account` is discharged by the issue that gets the alternate flows, and this
  file says so rather than leaving the requirement looking covered.

---

## Out of scope

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

1. **`pm/tracker.yaml`'s UC02 row is wrong about this issue's scope** and cites a source
   that does not support it. It says the opening amount is an `adjustment` transaction
   *"per ERD D1"*; ERD D1's own table assigns `Adjustment` to **UC-03**, `docs/enums.md`
   traces it to **FR-18, UC-03**, the workbook's UC-02 row lists **one** entity
   (`Account`), the sequence diagram writes only an account row, and `FEAT01` shipped
   `Accounts.opening_amount` as a real column. Four artifacts against one prose summary.
   `lessons.md` §1 — the register that carries a rationale is not the one that gets
   corrected when the rationale stops being true. Fix at close (step 9).
2. **No sequence diagram in the project covers account rename, edit or delete**, while
   FR-18 says no entity is create-only and no entity has an exception, and the workbook
   puts those flows in UC-02. This is the halt (Q2).
3. **`class-accounts.drawio` gives `AccountDao` an `update()` that no sequence diagram
   calls.** Consistent with the workbook's alternate flows and inconsistent with the
   diagrams. Part of the same question; resolves with Q2.

---

## Open questions — genuinely non-blocking

- **`pm/findings.md` F7, applied here.** Which non-refusing behaviour is wanted when an
  amount will not parse. It does not block, because D7 follows the shipped precedent and
  the answer changes one line on two screens whenever it comes.
- **`pm/findings.md` F8.** Whether a navigation host becomes its own issue before the next
  screen lands. It does not block, because D8 continues the pattern the previous three
  screen issues used; it does get worse by one screen each time it is deferred, and this
  issue makes it three dead screens out of four.
