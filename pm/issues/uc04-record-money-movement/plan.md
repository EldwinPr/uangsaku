# UC04-record-money-movement — Record money movement - all five recording use cases

**Status:** DONE 2026-08-23 under unattended mode (AUTO-CONFIRMED) (`general-rules.md`
planning gate; `context/index/decisions.md` 2026-08-21). Every decision below
derives from an artifact the owner has already confirmed, cited per D-entry:
the five sequence diagrams, `class-transactions.drawio`,
`component-overview.drawio`, `docs/enums.md`, `docs/fr-nfr.md`, the workbook's
UC-04..UC-08 rows, ISSUE-001/ISSUE-005 D1, dated entries in
`context/index/decisions.md`, and shipped code whose pattern prior rulings
fixed. Nothing here is chosen without a citation. The one candidate blocker —
Q4's adjustment encoding — is tested in D6 and **does not bite**, with
citations; no halt.

**Traces to:** UC-04, UC-05, UC-06, UC-07, UC-08
**Depends on:** UC01-balance-sheet (**DONE** 2026-08-22), UC13-categories
(**DONE** 2026-08-21) per `pm/tracker.yaml`.
**Preflight passes**: both dependencies Done; no scope overlap with any active
issue — `UC02B-edit-account` and `UC03-adjust-account` are HALTED on their own
write-path rulings (Q3, Q4) and own no class this issue touches (D6 shows Q4
does not reach this issue's writes); `UC09-review-and-correct` and
`UC12-budget-consumption` are downstream TODO rows that own classes this issue
deliberately does not build (Out of scope).

---

## Goal

The owner can record every movement of money — an expense (UC-04), income
(UC-05), a transfer between their own accounts (UC-06), lending or borrowing
(UC-07), a repayment (UC-08) — on **one form** that writes **one ledger table**
through **one insert path**. Each recording takes seconds on the common path
(FR-6): amount first, tags optional (FR-10), note optional everywhere
(`decisions.md` 2026-08-21). The rows written make FR-8's and FR-9's "never
counts as spending" true by shape rather than by rule: every kind this issue
writes except `expense` carries a non-null `to_account_id`, so the spending
predicate `to_account_id IS NULL` can never match them. This is the
Transactions module's first write path: until it lands, nothing can be
recorded and UC-12 has nothing to consume.

---

## Scope: the union of five sequence diagrams

`CLAUDE.md`: *a plan's scope IS whatever its sequence diagram shows.* This
issue is **the deliberate exception to one-issue-per-UC** (tracker row,
argued there): its scope is not one diagram but the **union of five**, all of
which exist under `docs/diagrams/` — none is missing. Per
`sequence-conventions.md` via the tracker note, the union is the boundary.
Renders for all five are committed in this folder and were looked at while
writing this plan (labels read from the `<UserObject label="…">` wrappers,
`lessons.md` §4).

All five share one lifeline set. **Lifeline check — every lifeline already
exists on a class diagram** (the ISSUE-008 rule; `lessons.md` §10), spelled
identically on `docs/diagrams/class-transactions.drawio`:

| Lifeline | On `class-transactions.drawio` as | Owned by |
|---|---|---|
| Owner | actor, not a class | — |
| `RecordTransactionScreen` | *UC-04 to UC-08 · ConsumerWidget · one form for all seven kinds* | **this issue** |
| `TransactionsNotifier` | *Notifier, exposed as transactionsProvider · recordExpense() · recordIncome() · transfer() · lend() · borrow() · repay() · edit() · delete()* | **this issue builds the six record methods**; `edit()`/`delete()` are UC-09's (Out of scope) |
| `TransactionDao` | *one write path for all seven kinds · watchAll() · insert() · update() · delete()* | **this issue adds `insert()` + two picker reads (D7)**; `watchAll()`/`update()`/`delete()` are UC-09's |
| `AppDatabase` | *the single drift database, shared by all four modules* | FEAT01, shipped |
| `transactionListProvider` | *StreamProvider · UC-09* | UC09-review-and-correct — **not built here** (D9) |
| `TransactionListScreen` | *UC-09 · ConsumerWidget* | UC09-review-and-correct — **not built here** (D9) |

No class is invented and none is missing.

### The five diagrams

**`seq-uc04-record-expense.drawio`** — 7 messages. 1 owner enters amount and
what it was for → 2 inside `opt [owner tags it - category / subcategory /
budget group, any may be blank - FR-10]` choose tags → 3
`recordExpense(amount, fromAccountId, categoryId, subcategoryId,
budgetGroupId, note, date)` → 4 `insert(kind: expense, fromAccountId,
toAccountId: null, amount, categoryId, subcategoryId, budgetGroupId, note,
date)` → 5 insert row / 6 row inserted (dashed reply into the DAO only) → 7
stream emission to `TransactionListScreen`. Notes: int minor units (FR-19,
NFR-2); isolate boundary *(stale mechanism name — discrepancy 1)*.

**`seq-uc05-record-income.drawio`** — same shape: `recordIncome(amount,
toAccountId, …)` → `insert(kind: income, fromAccountId: null, toAccountId,
…)`; emission notes *"receiving account's derived balance rises"*.

**`seq-uc06-move-money.drawio`** — 1 pick source account and destination
account → 2 enter amount and date → 3 `transfer(fromAccountId, toAccountId,
amount, note, date)` → 4 `insert(kind: transfer, fromAccountId, toAccountId,
amount, note, date)` → 5–6 insert row / row inserted → 7 emission (*"both
accounts' derived balances move, spendable total and net worth unchanged"*).
Note: *"to_account_id is not null, so this never counts as spending (FR-8) -
a property of the row, not a branch."* **No tag fragment** — the workbook's
UC-06 Input offers only a note as optional, consistent with this diagram.

**`seq-uc07-lend-borrow.drawio`** — 1 pick the person or debt and the
direction → 2 enter amount and which own account it moved through →
`alt [direction = I lent - FR-9]`: 3 `lend(personAccountId, fromAccountId,
amount, note, date)` → 4 `insert(kind: lend, fromAccountId: own wallet,
toAccountId: person's RECEIVABLE account, …)` · `[direction = I borrowed -
FR-9]`: `borrow(debtAccountId, toAccountId, amount, note, date)` →
`insert(kind: borrow, fromAccountId: PAYABLE account, toAccountId: own
wallet, …)` → insert row / row inserted → emission (*"owed-to-me or
owed-by-me account and the spendable account both move; neither expense nor
income change"*). Note: *"lending the same person again adds to the single
RECEIVABLE/PAYABLE account already held against them (FR-5) - no new account
created."*

**`seq-uc08-repayment.drawio`** — same `alt` shape on direction: `repay(…)`
→ `insert(kind: repayment, fromAccountId: person's RECEIVABLE account,
toAccountId: own wallet, …)` / `insert(kind: repayment, fromAccountId: own
wallet, toAccountId: PAYABLE account, …)`. Emission: *"outstanding amount on
that debt reduces."* Note: outstanding/paid-off progress (FR-11) is derived
by summing transactions, not stored (NFR-2) — that read path already shipped
in UC-10 and is untouched here.

### Discrepancies for the as-built pass — recorded, not fixed here

The main session owns diagram edits.

1. **The isolate note is stale on all five diagrams** — they name
   `NativeDatabase.createInBackground`; FEAT01 opened the database with
   `drift_flutter`'s `driftDatabase()`, whose native path calls
   `NativeDatabase.createBackgroundConnection` (`decisions.md` 2026-08-21,
   FEAT01 ruling 2). The guarantee is right; the mechanism name is wrong.
   Already tracked repo-wide as `pm/findings.md` **F3** — record these five
   against F3 at close, do not fix issue-by-issue.
2. **The read-path subscription messages are not drawn**, on this union as on
   every diagram before it: no screen→provider `watch()` messages, no
   provider→DAO query/reply beneath them. Every closed issue's as-built pass
   established these get drawn when they exist (UC13's close added five;
   seq-uc11's corrected a missing `watch()`; seq-uc10's added its set). The
   class diagram binds screen → provider → DAO by edge, so adding them is a
   diagram edit, not scope widening.
3. **`class-transactions.drawio`'s `TransactionDao` method list is incomplete
   relative to `component-overview.drawio`.** The component diagram assigns
   Transactions two cross-module reads for exactly this use-case range —
   *"reads: Accounts — account picker (UC-04..UC-08)"* and *"reads:
   BudgetGroups — budget picker (UC-04..UC-08)"* — but the class diagram's
   `TransactionDao` box lists only `watchAll() · insert() · update() ·
   delete()`. D7 lands those reads as DAO methods; the box's method list
   should gain them at this issue's as-built pass (proposed names there),
   with the render re-exported and inspected (`lessons.md` §3).
4. **The tracker row's summary is imprecise about kinds.** It says *"Expense,
   income, transfer, lend and borrow"*, but the workbook rows and diagrams
   give UC-07 = lend **or** borrow (one use case, both directions, drawn as
   one `alt`) and UC-08 = **repayment**. The union covers **six kinds across
   five use cases**, not five kinds. No artifact contradicts another — the
   row's own `traces_to` and the diagrams agree — so this is wording, noted
   for the closer rewriting the summary at step 11.

---

## Decisions

### D1 — Five use cases land as one issue, one screen, one write path

*Cites:* ISSUE-001 D1 (`decisions.md` 2026-08-19): all seven kinds live in
one ledger table *"precisely so there would be one insert path, not five"*;
`class-transactions.drawio`: `RecordTransactionScreen` is *"one form for all
seven kinds"*, `TransactionDao` is *"one write path for all seven kinds"*;
the tracker row itself, which argues the exception; `docs/fr-nfr.md`
promotion table (FR-9 → UC-07 **and** UC-08, split on direction of the money,
not on actor); NFR-1 (no ceremony on the common path) and FR-6 ("a few
seconds"), which are properties of the whole form. Splitting would mean one
real issue and four wrappers churning the same file — the exact branching ERD
D1 removed.

### D2 — Three files' worth of change, all in the Transactions module

*Cites:* `class-transactions.drawio` band layout; `map.yaml` `code:` layout
(one directory per module, followed since FEAT01); the module's existing
file set (`app/lib/src/transactions/`, shipped by FEAT01 + UC13).

| File | Contains |
|---|---|
| `app/lib/src/transactions/transaction_dao.dart` | **new**: `TransactionDao` — plain class composing `AppDatabase` (D4); `insert(...)` (D3/D5); two watched picker reads (D7) |
| `app/lib/src/transactions/transactions_providers.dart` | **extended**: gains `TransactionsNotifier` exposed as `transactionsProvider` beside the shipped category providers |
| `app/lib/src/transactions/record_transaction_screen.dart` | **new**: `RecordTransactionScreen` |

Plus tests under `app/test/transactions/`. **`app/lib/src/app.dart` is NOT
touched** — home stays `BalanceSheetScreen` permanently (FR-1, UC-01);
`RecordTransactionScreen` ships unreachable like every screen since navigation
was deferred (D10). No schema change anywhere (D11).

### D3 — Every name comes from the class diagram and the diagrams' signatures verbatim

*Cites:* `context/coding-conventions/README.md` §*The rule that outranks the
rest*; the five sequence diagrams' message labels.

`RecordTransactionScreen`, `TransactionsNotifier`, `transactionsProvider`,
`TransactionDao`, `TransactionDao.insert()`. Notifier methods exactly as the
diagrams call them: `recordExpense(...)`, `recordIncome(...)`,
`transfer(...)`, `lend(...)`, `borrow(...)`, `repay(...)`. **Not built**:
`edit()`/`delete()` on the notifier and `watchAll()`/`update()`/`delete()` on
the DAO are drawn on the class diagram but called by **no sequence diagram in
this union** — they are UC-09's surface (`transactionListProvider` and
`TransactionListScreen` are labelled *UC-09* on the class diagram itself), so
building them here would exceed the diagrams' scope. Parameter names follow
the signatures verbatim, including the nullable-by-default tags and `note`
and `date`.

Amounts are `int` minor units, never a double (note on seq-uc04/uc05 verbatim;
FR-19, NFR-2). **Direction lives entirely in the sides; amounts are stored
non-negative magnitudes** — every row of `docs/enums.md`'s kind table fixes
which side each kind touches (`expense | the wallet | null`, etc.), and Q4's
own options table describes that as how *"every other kind"* works. A negative
amount typed by the owner is recorded as entered, not negated (D9 — the app
does not police).

### D4 — `TransactionDao` is a plain class composing `AppDatabase`, not a `DatabaseAccessor`

*Cites:* `context/index/decisions.md` 2026-08-21 (UC-13 ruling 1), which
reproduced the `invalid_override` failure and states the general rule
verbatim: *"`AccountDao`, `TransactionDao` and `BudgetDao` all draw
`delete()` too, so this is the shape for all of them, not a one-off."*
`class-transactions.drawio` gives `TransactionDao` a `delete()`. Consequence,
already established: **no `daos: […]` entry on `@DriftDatabase`**, no change
to generated code, `CategoryDao`'s shipped shape is the pattern.

### D5 — One `insert()` for all six kinds; the sides come from `enums.md`'s table, not from branches

*Cites:* ISSUE-001 D1; `docs/enums.md` `Transaction.kind` table (seven rows,
each fixing `from_account_id`/`to_account_id`, promoted out of the ERD plan
into this canonical home); the five diagrams' `insert(kind: …)` messages,
which differ only in the kind and the sides.

`TransactionDao.insert()` takes the kind and the row's fields and writes one
`Transactions` row; the caller (notifier method) supplies the sides its kind
requires — expense from-only, income to-only, transfer/lend/borrow/repayment
both. The enum is bound as text per `.textEnum<TransactionKind>()` (shipped
table declaration). **The spending predicate appears nowhere in this issue.**
"is this spending?" is `to_account_id IS NULL`, a property of the rows once
written (seq-uc06's note verbatim: *"a property of the row, not a branch"*):
every kind written here except `expense` sets `to_account_id`, so transfers
and lending can never count as spending without any code remembering to
exclude them. Nothing in this issue reads spending back — that figure belongs
to UC-01 (shipped, sides-based, no kind predicate) and UC-12.

### D6 — Q4 tested and does not bite — no halt

This is the check the run asked for, stated with citations. `pm/questions.md`
**Q4** (OPEN, blocking `UC03-adjust-account`) asks which sides of a
`kind=adjustment` row carry the account and whether the amount is signed.

- **This issue never writes an adjustment.** All five diagrams' insert
  messages name exactly: `expense`, `income`, `transfer`, `lend`, `borrow`,
  `repayment` (quoted in Scope above). `docs/enums.md` assigns `adjustment` to
  **FR-18, UC-03** alone, and Q4's own statement of scope is *"which sides of
  an **adjustment** transaction carry the account"* — the other six rows'
  sides are fixed independently of it.
- **This issue reads nothing back into any figure.** Its only outputs are
  inserted rows; the screens that derive figures from `Transactions` (UC-01's
  four figures, UC-10's paid/remaining, UC-12's Others) were built or will be
  built elsewhere, and the shipped ones are already pinned encoding-independent
  by UC-01's and UC-10's dual-encoding tests.

So whichever way the owner answers Q4, this issue's write path needs no
rewrite, no migration and no re-test. **No halt.** As at UC-10, the converse
check belongs to UC-03's plan: the eventual encoding must be validated against
the readers, not against this issue.

### D7 — The pickers: categories reuse UC-13's provider; accounts and budget groups are watched reads inside `TransactionDao`

*Cites:* `component-overview.drawio` — two edges **from Transactions**,
labelled *"reads: Accounts — account picker (UC-04..UC-08)"* and *"reads:
BudgetGroups — budget picker (UC-04..UC-08)"*, drawn and confirmed at
ISSUE-005 with the mechanism note *"Modules reach each other's data by SQL
join on the shared database — no module calls another module's DAO"*
(ISSUE-005 D1, `decisions.md` 2026-08-20); `class-transactions.drawio`'s edge
`RecordTransactionScreen → categoryTreeProvider` (the categories/subcategories
picker source, shipped in UC-13); the seq-uc07/uc08 labels *"person's
RECEIVABLE account"* / *"PAYABLE account"* with `docs/enums.md`'s
`AccountGroup` table.

Three pickers, each citable:

- **Category / subcategory** — `categoryTreeProvider`, already shipped; the
  class-diagram edge binds the screen to it directly.
- **Accounts (paying/receiving/source/destination)** — the Transactions
  module writes its **own** watched select over the `Accounts` table inside
  `TransactionDao`, per the component diagram's confirmed mechanism. It does
  **not** import `AccountDao` (forbidden by name) and does not watch
  `accountBalancesProvider` (that would couple the form to balance derivation
  it does not need, and the component diagram prescribes the SQL route for
  this dependency). Proposed name `watchAccounts()`, following the shipped
  naming family `watchPosition()/watchBalances()/watchTree()`; the method is
  new to the class diagram — flagged as discrepancy 3, to be drawn on
  `class-transactions.drawio` at the as-built pass.
- **Budget groups (optional tag)** — same reasoning, own watched select over
  `BudgetGroups` inside `TransactionDao`; proposed name `watchBudgetGroups()`,
  same flag.
- **Person/debt** — not a fourth source: the accounts list filtered to
  `RECEIVABLE`/`PAYABLE` groups, because a person and a debt *are* accounts
  (`enums.md`, *"no separate Debit entity... the owner re-confirmed that a
  debt is an account"*). The form creates **no** account — seq-uc07's note
  verbatim: lending the same person again *"adds to the single
  RECEIVABLE/PAYABLE account already held against them (FR-5) - no new
  account created"*; creating accounts is UC-02's/UC02B's territory.

The screen watches these streams as ordinary providers in its build — the
shipped multi-provider precedent is `BalanceSheetScreen`, which watches
`financialPositionProvider` and `accountBalancesProvider` together. The UC-11
ruling (`decisions.md` 2026-08-22, banning a combining `StreamNotifier`)
does not bite: nothing merges streams into one state object; each picker
watches its own stream.

### D8 — Tags and note: optional everywhere, blank means null

*Cites:* FR-10 (*"any of them can be left blank"*, quoted in the workbook
rows and the `opt` guard on seq-uc04/uc05); `decisions.md` 2026-08-21 (*"the
free-text note appears on every recording screen"* — expense, income,
transfer, lend, borrow and repayment); the shipped column (`note` nullable,
FEAT01); FR-17 via ISSUE-001 D5 ("Others" is the null `budget_group_id`, not
a row).

All three tag columns and `note` are nullable and default to blank; blank is
stored as null, keeping "wrote nothing" and "wrote empty" one fact with one
representation (`decisions.md` 2026-08-21 cost paragraph). UC-06's flow offers
no tag pickers — its diagram draws none and its workbook Input promises none;
the columns simply stay null on its rows. Blank budget group reading as
"Others" happens at read time (UC-12), never by writing a sentinel row.

### D9 — Write-path discipline: save always enabled, nothing returned, zero refusals

*Cites:* NFR-4 (fit criterion: **zero** refusals; `decisions.md` 2026-08-20
"No guardrails"); `riverpod.md`'s read/write asymmetry (a write returns
nothing to the screen — results arrive on the read path); ISSUE-001's accepted
cost (a mistyped amount cannot be detected by reconciliation — *"acceptable
with no auditor and one user"*).

The save control is always enabled and always writes what the form holds —
no validation gate refuses zero, negative, over-budget, future-dated, or
same-account transfers. Optional fields left blank store null (D8). The
notifier methods forward to the DAO and return `Future<void>`; no result
value ever reaches the screen. What the owner sees afterwards arrives as
stream re-emissions — and the screens that would show them (`BalanceSheet`'s
figures recompute automatically; the transaction list is UC-09's) sit outside
or downstream of this issue.

### D10 — `home` is untouched; `RecordTransactionScreen` ships unreachable, continuing F8

*Cites:* FR-1 via UC-01 — `MaterialApp.home` is `BalanceSheetScreen`
*permanently*; `pm/findings.md` **F8** — no navigation host exists, so every
new screen is reachable only by tests until the owner rules on navigation;
message 1 of each diagram (*"enter amount…"*) draws the owner arriving, but
the route by which they arrive is on no class diagram and cannot be invented
here (`lessons.md` §10).

`RecordTransactionScreen` is therefore F8's sixth orphan. Recorded at close
(step 11), not fixed.

### D11 — No schema change anywhere in this issue

*Cites:* the shipped table — `Transactions` exists complete since FEAT01's v1
schema (`transactions_table.dart`: every column these inserts need, including
`note` and both `@ReferenceName`-disambiguated account FKs); FEAT01 D3 (all
seven tables landed at `schemaVersion = 1`). `schemaVersion` stays 1;
`drift_schemas/app_database/drift_schema_v1.json` must be **byte-identical**
at close — the check UC-14, UC-02, UC-01, UC-10 and UC-11 all ran.

---

## Steps

Executable in order.

1. `TransactionDao` in `app/lib/src/transactions/transaction_dao.dart` — a
   plain class composing `AppDatabase` (constructor injection, mirroring
   shipped `AccountDao`/`CategoryDao`), **not** a `DatabaseAccessor` (D4).
2. `TransactionDao.insert({required TransactionKind kind, required int
   amount, required DateTime occurredOn, int? fromAccountId, int?
   toAccountId, int? categoryId, int? subcategoryId, int? budgetGroupId,
   String? note})` — one write path for every kind (D3/D5), returning
   `Future<void>` (D9). Sides are passed in by the caller; the DAO validates
   nothing and refuses nothing.
3. `TransactionDao.watchAccounts()` and `TransactionDao.watchBudgetGroups()`
   — two watched selects over the `Accounts` and `BudgetGroups` tables,
   returned as drift streams of the generated row classes (D7).
4. Extend `app/lib/src/transactions/transactions_providers.dart` with
   `TransactionsNotifier` (plain `Notifier<void>`, hand-written, exposed as
   `transactionsProvider` — same shape and same two generator-dodging reasons
   as the shipped `CategoriesNotifier`/`AccountsNotifier`) with the six
   methods `recordExpense`, `recordIncome`, `transfer`, `lend`, `borrow`,
   `repay`, each forwarding to `insert()` with the sides its kind requires
   per `enums.md`'s table (D3/D5). Also expose the two picker streams as
   hand-written `StreamProvider.autoDispose`s over the DAO watches (D7),
   unless the coder finds the shipped providers already cover a picker —
   `categoryTreeProvider` covers the category picker as-is.
5. `RecordTransactionScreen` in `app/lib/src/transactions/
   record_transaction_screen.dart` — a `ConsumerWidget`: one form covering
   all six writable kinds (kind/direction switch carrying the `alt`
   fragments of seq-uc07/uc08), amount field in minor units, account/group/
   person pickers fed by D7's streams, three optional tag pickers where the
   diagram draws them (UC-04/UC-05 flows; absent on UC-06's), optional note
   on every flow (D8), date field pre-filled from today. Save is always
   enabled and calls the matching notifier method directly — no dialog, no
   gate, no disabled state (D9). Loading and empty picker states render
   placeholders, never errors.
6. Tests in `app/test/transactions/`, per Definition of done below.
7. Run the standard four commands from `app/` plus the byte-identical
   snapshot check (D11). Fix, repeat until clean.
8. Correct any `context/coding-conventions/` file this issue contradicted, in
   place, and say so in `pm/log.md`.
9. Close per `CLAUDE.md`'s checklist. Named individually because `lessons.md`
   §1:
   - **As-built pass on all five diagrams** — reconcile against what was
     built. Discrepancy 1 goes to `pm/findings.md` **F3**; discrepancy 2 —
     add the missing read-path subscription messages to each diagram,
     following the shapes UC-13/UC-11/UC-10 drew; discrepancy 3 — add
     `watchAccounts()`/`watchBudgetGroups()` to `TransactionDao`'s box on
     `class-transactions.drawio` (render re-exported and **looked at**,
     `lessons.md` §3; refresh `docs/diagrams/renders.lock`).
   - **`pm/findings.md` F8** — append that `RecordTransactionScreen` joined
     the orphans (sixth dead screen), `home` unchanged.
   - **`context/index/map.yaml`** — UC-04..UC-08 → `app/lib/src/transactions/`
     entries under `code:`.
   - **`context/index/decisions.md`** — only if the toolchain forces a
     durable ruling, as at FEAT01/UC-13/UC-11. Not a formality; not an
     obligation.
   - **`pm/tracker.yaml`** — Done plus a summary that names the scope
     correctly: **six kinds (expense, income, transfer, lend, borrow,
     repayment) across five use cases** (discrepancy 4).
   - **`docs/workbook.xlsx`** — UC-04..UC-08 marked implemented
     (`general-rules.md`, done, step 4).
   - **`pm/log.md`** dated entry plus current-state block; **`pm/active.json`**
     → next issue (`UC09-review-and-correct` unblocks when this closes; Q3/Q4
     remain OPEN and block UC02B/UC03 only — D6 is why this run continued
     past Q4).

---

## Definition of done

*Cites:* FEAT01 D7 and the identical DoD of UC-14/UC-02/UC-01/UC-10/UC-11 —
headless four commands, no Android SDK, `flutter` at `C:/flutter/bin/flutter`,
all run from `app/`:

1. `dart run build_runner build` — succeeds (no-op expected).
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under strict casts/inference/raw-types.
4. `flutter test` — green, on `NativeDatabase.memory()`, drift never mocked.

Plus: `git diff --stat app/drift_schemas/` is **empty** (D11).

**Tests, each named for the requirement it defends.** Fixtures insert
`Accounts` (one `HOLDING`, one `RECEIVABLE`, one `PAYABLE`) and, where a
picker needs one, `BudgetGroups`/`Categories` rows through the in-memory
database — test scaffolding, not a write path:

- **`docs/enums.md` kind table, pinned per kind** — calling each of the six
  notifier methods and reading the row back yields exactly the sides the
  table fixes: expense `from`=wallet/`to`=null; income `from`=null/`to`=wallet;
  transfer both wallets; lend wallet→RECEIVABLE; borrow PAYABLE→wallet;
  repayment in both directions per the `alt` arms. Six tests, one per kind.
- **FR-8/FR-9 by shape, pinned** — after inserting one row of each of
  transfer, lend, borrow, repayment (both directions), **no** such row
  satisfies `to_account_id IS NULL`; only the expense row does. This is the
  property the tracker row calls the correctness test, made checkable.
- **FR-10 / D8, blanks** — saving with every optional field left blank stores
  nulls in `category_id`, `subcategory_id`, `budget_group_id` and `note`;
  a filled note round-trips verbatim.
- **FR-19/NFR-2** — an amount stored is the exact `int` minor units entered;
  the column rejects no value and converts nothing.
- **D9 / NFR-4, widget test** — the form renders with save enabled, tapping
  save drives notifier → DAO → row (read back via a direct query), and no
  dialog or refusal path fires, including for a zero amount and a
  same-source-and-destination transfer.
- **D7, pickers** — `watchAccounts()` emits the seeded accounts with their
  groups; the person/debt picker surfaces only `RECEIVABLE`/`PAYABLE` rows;
  `watchBudgetGroups()` emits the seeded groups.

---

## Out of scope

- **Everything UC-09 owns**: `transactionListProvider`, `TransactionListScreen`,
  the transaction list display, and `TransactionsNotifier.edit()/delete()` +
  `TransactionDao.watchAll()/update()/delete()` — drawn on the class diagram,
  called by no diagram in this union (D3). Editing/deleting recorded rows is
  UC09-review-and-correct, the next issue down this chain.
- **The `adjustment` kind.** UC03-adjust-account, HALTED on Q4; D6 shows the
  halt does not reach here.
- **Navigation to the form.** No route exists; `home` stays
  `BalanceSheetScreen` permanently (D10). Queued in F8.
- **Creating accounts, persons or budget groups.** The pickers consume
  existing rows only; creation is UC-02/UC02B (accounts/persons) and UC-11
  (groups). seq-uc07's FR-5 note forbids the form minting a second account
  per person.
- **Spending totals, budget consumption, "Others".** No such figure is on any
  of the five diagrams; `to_account_id IS NULL` belongs to its readers
  (UC-12, and UC-01's already-shipped figures).
- **Currency display formatting.** No settings lifeline is drawn on any of
  the five diagrams; the amount field renders raw minor-unit integers — the
  same known gap UC-01 and UC-10 recorded.
- **Any schema change, migration or new snapshot.** `schemaVersion` stays 1
  (D11).
- **Fixing the stale isolate notes ahead of the as-built pass.** F3,
  repo-wide.

---

## Contradictions and stale notes found while planning

1. **The tracker summary understates the kinds.** It says the issue covers
   "expense, income, transfer, lend and borrow"; the workbook rows and the
   diagrams cover six kinds — UC-07 is lend-or-borrow in one `alt`, UC-08 is
   repayment. Recorded as discrepancy 4 for the closer; nothing was edited
   (tracker summaries belong to the closing pass).
2. **The isolate notes on all five diagrams are stale** (`F3`) — discrepancy
   1, listed so the as-built pass cannot miss it.
3. **`class-transactions.drawio`'s `TransactionDao` lacks the two picker
   reads** the component diagram assigns to UC-04..UC-08 — discrepancy 3.
   This is the one place the plan proposes a diagram change (adding methods
   to a drawn box, UC-11's "boxes existed, methods were missing" pattern),
   raised openly rather than quietly stepped over (`lessons.md` §10).
4. Nothing else. The five diagrams, the workbook rows, `docs/enums.md`'s kind
   table and the class diagram agree with each other and with the shipped
   schema, column for column.

---

## Open questions — genuinely non-blocking

- **What the form saves when the database holds no accounts at all.** With
  accounts present, each side-picker preselects its first matching row, so a
  save always produces a row whose sides satisfy `enums.md`'s kind table
  without refusing anything (D9). With **zero** accounts, a fresh install
  before UC-02's screen has ever been used, there is nothing to preselect and
  no artifact says what an expense with neither side even means (such a row is
  outside every kind's fixed shape). Display-level and reversible; suggested
  handling is to let the save proceed and leave the sides null, but it cannot
  be cited, so it is flagged here rather than decided. Does not block — every
  realistic test seeds accounts, as all six prior issues did.
- **Which widget arrangement carries the kind/direction switch** (single
  selector vs segmented tabs). Pure presentation; the artifacts fix that
  there is **one** form (D1), not how its kind switch looks.
- **Currency prefix/formatting** — shared with UC-01/UC-10; natural landing
  spot is the same future display-formatting work.
