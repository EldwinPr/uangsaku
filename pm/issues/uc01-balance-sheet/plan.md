# UC01-balance-sheet — View financial position

**Status:** DONE 2026-08-22. Planned under unattended mode (AUTO-CONFIRMED): every
decision cites a confirmed artifact. — unattended mode (`general-rules.md`, planning gate;
`decisions.md` 2026-08-21). Every decision below derives from an artifact the owner has
already confirmed, cited per D-entry: the sequence diagram, `class-accounts.drawio`,
FR-1/FR-4, `docs/enums.md`, `docs/workbook.xlsx`'s UC-01 row, and dated entries in
`context/index/decisions.md`. Nothing here is chosen; everything is transcribed or
derived by an argument whose premises are all cited.

**Traces to:** UC-01
**Depends on:** UC02-add-account — **DONE** 2026-08-22 in `pm/tracker.yaml`. **Preflight
passes**: dependency satisfied, and no scope overlap with any active issue — the two other
Accounts-chain issues (`UC02B-edit-account`, `UC03-adjust-account`) are HALTED on
*write*-path rulings (delete semantics Q3, adjustment encoding Q4); this issue is read-only
and touches neither.

---

## Goal

The owner opens the app and its first screen is the balance sheet: four distinct figures —
what I can spend now, what people owe me, what I owe, and the net — plus each place money
lives with its own current amount (FR-1, FR-2). Every figure is derived at read time from
`Accounts` + `Transactions` by one SQL expression each, never stored (NFR-2), computed
inside the Accounts module via the app's first cross-module join (component-overview D1).
This issue also takes `MaterialApp.home` permanently: FR-1 makes this *the primary screen,
not a report behind a menu*, which is why `UC02-add-account`'s D8 held the spot only
temporarily. After this lands, the app finally shows the screen it exists for.

---

## Scope: the sequence diagram

`CLAUDE.md`: *a plan's scope IS whatever its sequence diagram shows.*
`docs/diagrams/seq-uc01-balance-sheet.drawio`, render committed at
`pm/issues/uc01-balance-sheet/seq-uc01-balance-sheet.png`, rendered and looked at while
writing this plan (labels come from the render's `<UserObject label="…">` wrappers,
`lessons.md` §4).

**Thirteen messages, two independent read paths, no write path, no `alt`, no `opt`.**

| # | From → To | Message |
|---|---|---|
| 1 | Owner → `BalanceSheetScreen` | open primary screen |
| 2 | `BalanceSheetScreen` → `financialPositionProvider` | `watch()` |
| 3 | `financialPositionProvider` → `AccountDao` | `watchPosition()` |
| 4 | `AccountDao` → `AppDatabase` | query accounts + transactions |
| 5 | `AppDatabase` ⇢ `AccountDao` | rows *(reply)* |
| 6 | `AccountDao` ⇢ `financialPositionProvider` | `Stream<FinancialPosition>` *(reply)* |
| 7 | `financialPositionProvider` ⇢ `BalanceSheetScreen` | FinancialPosition (spendable / owed to me / owed by me / net) |
| 8 | `BalanceSheetScreen` → `accountBalancesProvider` | `watch()` |
| 9 | `accountBalancesProvider` → `AccountDao` | `watchBalances()` |
| 10 | `AccountDao` → `AppDatabase` | query accounts + transactions |
| 11 | `AppDatabase` ⇢ `AccountDao` | rows *(reply)* |
| 12 | `AccountDao` ⇢ `accountBalancesProvider` | `Stream<AccountBalance>` *(reply)* |
| 13 | `accountBalancesProvider` ⇢ `BalanceSheetScreen` | AccountBalance list (per-account current amount) |

Plus one note: *"AccountDao to AppDatabase messages cross the isolate boundary
(NativeDatabase.createInBackground, decided 2026-08-20)"* — **stale**, see
*Discrepancies for the as-built pass* item 1.

**Lifeline check — every lifeline already exists on a class diagram** (the ISSUE-008 rule;
`lessons.md` §10). All six non-actor lifelines are boxes on
`docs/diagrams/class-accounts.drawio`, spelled identically:

| Lifeline | On `class-accounts.drawio` as | Owned by |
|---|---|---|
| Owner | actor, not a class | — |
| `BalanceSheetScreen` | `BalanceSheetScreen` — *UC-01 · ConsumerWidget* | **this issue** |
| `financialPositionProvider` | `financialPositionProvider` — *StreamProvider · UC-01* | **this issue** |
| `accountBalancesProvider` | `accountBalancesProvider` — *StreamProvider* | **this issue** |
| `AccountDao` | `AccountDao` — *watchPosition() watchBalances() watchDebtProgress() / insert() update() setSettled()* | methods exist since FEAT01's tables; `insert()` shipped by UC-02; **this issue adds `watchPosition()` + `watchBalances()`** |
| `AppDatabase` | `AppDatabase` — *shared by all four modules* | FEAT01, shipped |

Result classes `FinancialPosition` (*query result · UC-01's four figures*) and
`AccountBalance` (*query result · one account + derived balance*) are also boxes on the
same diagram. **No class is invented and none is missing.**

**Two discrepancies for the as-built pass — recorded, not fixed here** (the main session
owns diagram edits):

1. **The isolate note is stale**, on this diagram as on the thirteen already tracked:
   FEAT01 opened the database with `drift_flutter`'s `driftDatabase()`, whose native path
   calls `NativeDatabase.createBackgroundConnection` (`decisions.md` 2026-08-21, FEAT01
   ruling 2). The background-isolate guarantee itself is unchanged, so the note is right
   about the architecture and wrong about the call. This is `pm/findings.md` **F3**;
   record against F3, do not fix fifteen diagrams from this issue.
2. **Nothing else.** Both read paths, both result types, and the reply-arrow discipline
   (streams instead of write-style replies) match what previous as-built passes
   established as the convention. The diagram needs no edit beyond F3's note.

---

## Decisions

### D1 — Two new files' worth of classes, in the Accounts module, and one line in `app.dart`

*Cites:* `docs/diagrams/class-accounts.drawio` (every box this issue implements lives in
its Accounts bands); `context/index/map.yaml` `code:` (one-directory-per-module, followed
by every issue since FEAT01); `pm/issues/uc02-add-account/plan.md` D1/D9 (the module's
file layout, and that UC-01 owns exactly these classes).

| File | Contains |
|---|---|
| `app/lib/src/accounts/account_dao.dart` | **extended**: `AccountDao` gains `watchPosition()` and `watchBalances()` beside the shipped `insert()` |
| `app/lib/src/accounts/accounts_providers.dart` | **extended**: gains `financialPositionProvider` and `accountBalancesProvider` beside the shipped `accountsProvider` |
| `app/lib/src/accounts/balance_sheet_screen.dart` | **new**: `BalanceSheetScreen` |
| `app/lib/src/accounts/account_dao.dart` (same file) | `FinancialPosition` and `AccountBalance`, the plain Dart result classes the diagram groups in the DAO's band |

Plus tests under `app/test/accounts/`, and one line changed in `app/lib/src/app.dart`
(D7). **No other file is touched.** No schema change (D6): `drift_schema_v1.json` must be
**byte-identical** at close, the check UC-11, UC-14 and UC-02 all ran.

### D2 — Every name comes from the class diagram verbatim

*Cites:* `context/coding-conventions/README.md` §*The rule that outranks the rest* —
class names match the class diagrams exactly.

`BalanceSheetScreen`, `financialPositionProvider`, `accountBalancesProvider`,
`AccountDao.watchPosition()`, `AccountDao.watchBalances()`, `FinancialPosition`,
`AccountBalance` — all as spelled above. `FinancialPosition` carries the four fields the
sequence diagram's message 7 names: `spendable`, `owedToMe`, `owedByMe`, `net` — the same
four figures FR-1 lists ("what I can spend now, what people owe me, what I owe, and the
net"). `AccountBalance` carries one account and its derived current amount, per its own
diagram label.

### D3 — The join is written inside `AccountDao`; no other module's DAO is called

*Cites:* `context/index/decisions.md` 2026-08-20 — *"Modules reach each other's data by
SQL join, not by calling another module's DAO"* (ISSUE-005 D1, owner-confirmed):
`AccountDao` writes one query joining `Accounts` and `Transactions` itself and does **not**
ask `TransactionDao` for rows to add up in Dart — stitching in Dart would be "a second
place for a number to come from", which NFR-2 forbids. Same decision, consequence section:
"`AccountDao` and `BudgetDao` both legitimately read `Transactions`." The rejected
alternative (`AccountsNotifier → TransactionDao`) is exactly the edge `lessons.md` §10
records catching once already.

Concretely: `watchPosition()` and `watchBalances()` are drift `watch()` queries over a
custom select joining `app/lib/src/accounts/accounts_table.dart`'s `Accounts` with
`app/lib/src/transactions/transactions_table.dart`'s `Transactions` on
`fromAccountId` / `toAccountId`. The `kind` discriminator appears in **no** predicate in
either query (D5 explains why it must not).

### D4 — The four figures and the per-account amount, one expression each

*Cites:* `docs/enums.md`, `Transaction.kind` closing paragraph — *"A balance is likewise
one expression over one table (NFR-2)"*; `docs/enums.md`, `Account.group` — *"The balance
sheet's four figures (UC-01) are three sums over this column plus their net"*; FR-1's
consequence paragraph (three groups, only the first reachable); NFR-2 (exactly one source
per number, nothing stored).

Each account's current amount (the `AccountBalance` value):

```
balance(a) = a.openingAmount
           + COALESCE(Σ t.amount WHERE t.toAccountId = a.accountId, 0)
           - COALESCE(Σ t.amount WHERE t.fromAccountId = a.accountId, 0)
```

The four figures are then purely a grouping of that one expression by `Account.group`
(`docs/enums.md`'s sentence, made literal):

```
spendable = Σ balance(a) WHERE a.group = HOLDING
owedToMe  = Σ balance(a) WHERE a.group = RECEIVABLE
owedByMe  = Σ balance(a) WHERE a.group = PAYABLE
net       = spendable + owedToMe + owedByMe
```

`net` is the plain sum of the three because `PAYABLE` balances are already negative: FR-4
says a credit card *"just holds a negative amount"*, and UC-02 D6 ruled the opening amount
is stored **signed as entered, with no group-based negation** — so a payable entered as
−500000 sits as −500000, borrows drive it further down (`borrow`: from the `PAYABLE`
account to the wallet), and the sum subtracts it without a special case. Amounts are `int`
minor units throughout, never a double (`docs/enums.md`, `Settings.currency`; NFR-2).

Both queries derive everything; nothing is written back anywhere (NFR-2), which is also
why this issue ships with `schemaVersion` still 1 (D6).

### D5 — Q4 does not block this issue: the figures cannot depend on how adjustments are sided

This is the check the run asked for explicitly, stated with citations rather than assumed.
`pm/questions.md` **Q4** (OPEN, blocking `UC03-adjust-account`) asks which sides of a
`kind=adjustment` row carry the account and whether the amount is signed. Its own options
table shows every candidate encoding produces the **same contribution to D4's expression**:

- **Option A** (side follows the sign, amount always `|diff|`): an increase arrives via
  `toAccountId` (+), a decrease leaves via `fromAccountId` (−) — net effect on
  `balance(a)` is `diff`.
- **Option B** (one fixed side, signed amount): always via `toAccountId`, the inflow term
  summing positives and negatives alike — net effect on `balance(a)` is again `diff`.

D4's expression references only *which side a row touches*, never `kind` and never the
`to_account_id IS NULL` spending predicate. That predicate classifies **spending**
(FR-8/FR-9, `docs/enums.md`) — and spending appears nowhere in this issue: FR-1's four
figures contain no spending total, the workbook's UC-01 `Output` is *"Four-figure
balance-sheet summary … plus per-account current amounts"*, and `seq-uc01` draws no query
that filters or buckets by kind. Even Q4's hypothetical "something else" (option C) cannot
move these numbers: a row touching neither side contributes zero to every balance under
any reading.

So whichever way the owner answers Q4, `watchPosition()` and `watchBalances()` need no
rewrite, no migration and no re-test. **No halt.** The converse risk runs the other way:
UC-03's eventual encoding must be checked against D4's expression, and that check belongs
to UC03's plan, not this one.

### D6 — Read-only issue; no schema change, no write path anywhere in it

*Cites:* the sequence diagram — thirteen messages, every solid arrow between lifelines 2–13
is a read or a stream emission; there is no `insert`, no `update`, no write message
anywhere on it; NFR-2 (nothing stored alongside the derived figures); `pm/tracker.yaml`'s
UC01 row (*"never merged … One query joining Accounts to Transactions with no stored
balance (NFR-2)"*).

`schemaVersion` stays 1, `drift_schemas/` untouched, no migration. The `Transactions`
table is **read** here for the first time in the app's history but never written — the
first write to it belongs to `seq-uc03`/`seq-uc04`.

### D7 — `BalanceSheetScreen` becomes `MaterialApp.home`, permanently, orphaning `AccountFormScreen`

*Cites:* FR-1 — *"The primary screen — not a report behind a menu"*; sequence diagram
message 1 (the owner reaches this screen by opening the app);
`pm/issues/uc02-add-account/plan.md` D8, verbatim: *"Explicitly temporary … Re-pointing
`home` is UC-01's business"*; the shipped doc comment on `app/lib/src/app.dart`, which
already says *"UC01's balance sheet takes this spot permanently once it lands (FR-1)"*.

Pointing `home:` at `BalanceSheetScreen` makes `AccountFormScreen` the fourth orphaned
screen after `CurrencyScreen`, `SetBudgetScreen` and `CategoryManagerScreen` — recorded
against `pm/findings.md` **F8** at close, **not fixed** (a navigation host is on no class
diagram and cannot be invented here). Unlike the previous three re-pointings, this one is
not temporary: FR-1 gives this screen the spot outright, and no planned issue draws a
screen meant to displace it.

### D8 — Provider shapes: two hand-written single-stream `StreamProvider`s; the multi-stream ruling does not bite

*Cites:* `docs/diagrams/class-accounts.drawio` labels both providers *StreamProvider*
(the diagram binds the shape as well as the name);
`context/index/decisions.md` 2026-08-21 (UC-13 rulings) — hand-written providers, never
`@riverpod`, because `riverpod_generator` throws `InvalidTypeException` on any provider
typed over a drift row class, and because codegen would rename them away from the class
diagram's spelling; `context/index/decisions.md` 2026-08-22 (UC-11 ruling) — read in full,
it bans a **`StreamNotifier` combining several drift streams into one state object**,
whose controller layer leaked subscriptions and hung `AppDatabase.close()`.

Neither provider here combines anything: `financialPositionProvider` wraps exactly one
drift stream (`watchPosition()`'s), `accountBalancesProvider` wraps exactly one
(`watchBalances()`'s) — the shape UC-11's probes proved closes cleanly, and the shape
`categoryTreeProvider` has shipped since UC-13. The screen reads two streams, but it does
so by watching two separate providers (messages 2 and 8 draw precisely that, twice), not
by merging them through a third object; no combining type exists on any diagram, and
inventing one would break D2. **No `StreamNotifier` is written anywhere in this issue.**
Checked deliberately against the 2026-08-22 ruling rather than assumed around it.

---

## Steps

Executable in order.

1. `FinancialPosition` and `AccountBalance` as plain Dart classes in
   `app/lib/src/accounts/account_dao.dart` — immutable, `int` minor-unit fields, free of
   Flutter imports (D2; the pure-Dart domain rule, `decisions.md` 2026-08-19 Flutter entry).
2. `AccountDao.watchPosition()` — one custom drift select computing D4's four figures in
   SQL (group sums + net), joined per D3, returned as a watched `Stream<FinancialPosition>`.
3. `AccountDao.watchBalances()` — one custom drift select returning
   `Stream<List<AccountBalance>>`, one row per account, D4's per-account expression (D3).
4. `financialPositionProvider` and `accountBalancesProvider` in
   `app/lib/src/accounts/accounts_providers.dart` — hand-written single-stream
   `StreamProvider.autoDispose`s over the two DAO watches (D8). `accountsProvider` and
   `AccountsNotifier` stay exactly as shipped.
5. `BalanceSheetScreen` in `app/lib/src/accounts/balance_sheet_screen.dart` — a
   `ConsumerWidget` watching both providers (messages 2, 8), showing the four figures
   distinctly — spendable never merged with owed-to-me (FR-1, workbook step 3) — and the
   per-account list beneath (FR-2, workbook step 4). Loading and empty states show zeros /
   placeholders; the screen offers no action that could be refused, so NFR-4 has nothing
   to bite on.
6. Point `app/lib/src/app.dart`'s `home` at `BalanceSheetScreen`; update the doc comment
   the way UC-14's and UC-02's did (D7).
7. Tests in `app/test/accounts/`, per Definition of done below.
8. Run the standard four commands from `app/` and the byte-identical snapshot check (D6).
   Fix, repeat until clean.
9. Correct any `context/coding-conventions/` file this issue contradicted, in place, and
   say so in `pm/log.md`. This is the first issue to write a cross-module join and the
   first to read the `Transactions` table.
10. Close per `CLAUDE.md`'s checklist. Named individually because `lessons.md` §1:
    - **As-built pass on `seq-uc01-balance-sheet.drawio`** — reconcile against what was
      built (discrepancy 1 above goes to `pm/findings.md` **F3**, recorded repo-wide, not
      fixed diagram-by-diagram). Whatever is edited, re-export the PNG into
      `pm/issues/uc01-balance-sheet/` and **look at the render** (`lessons.md` §3);
      refresh `docs/diagrams/renders.lock`.
    - **`pm/findings.md` F8** — append that UC-01 took `home` permanently and orphaned
      `AccountFormScreen` (fifth dead-screen event; first permanent occupant).
    - **`context/index/map.yaml`** — `UC-01 → app/lib/src/accounts/` entry under `code:`.
    - **`context/index/decisions.md`** — only if the toolchain forces a durable ruling,
      as at FEAT01/UC-13/UC-11. Not a formality; not an obligation.
    - **`pm/tracker.yaml`** — Done plus a one-line summary.
    - **`docs/workbook.xlsx`** UC-01 marked implemented (`general-rules.md`, done, step 4).
    - **`pm/log.md`** dated entry plus current-state block; **`pm/active.json`** → next
      issue. Note in the log that Q4 remains OPEN and blocks UC03 only — this issue's
      independence argument (D5) is why the run continued past it.

---

## Definition of done

*Cites:* FEAT01 D7, UC-14 D8, UC-02 DoD — the same headless four commands; no Android SDK,
no emulator, `flutter` at `C:/flutter/bin/flutter`, all run from `app/`:

1. `dart run build_runner build` — succeeds (no-op expected; nothing generated changes).
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under strict casts/inference/raw-types.
4. `flutter test` — green, on `NativeDatabase.memory()`, drift never mocked.

Plus: `git diff --stat app/drift_schemas/` is **empty** (D6).

**Tests, each named for the requirement it defends.** Fixtures insert `Accounts` and
`Transactions` rows directly through the in-memory database — test scaffolding, not a
write path:

- **FR-2 / D4** — an account with `openingAmount` X and no transactions yields
  `AccountBalance` = X. Opening amounts alone are the whole balance on a fresh database.
- **FR-2 / D4, the ledger half** — with transactions inserted directly (an income to the
  wallet, an expense from it), `balance = opening + income − expense` reads back exactly.
- **FR-1 / D4, never merged** — a HOLDING account at 100000 and a RECEIVABLE account at
  50000 yield `spendable` 100000 and `owedToMe` 50000 — **two figures, not one**; this is
  FR-1's "money sitting with Budi cannot buy lunch" asserted numerically.
- **Schema shape (ERD D1's payoff)** — inserting a `transfer` between two HOLDING accounts
  changes **neither** `spendable` nor `net`; inserting a `lend` moves the amount from
  `spendable` into `owedToMe` leaving `net` unchanged. Both fall out of D4's sides-based
  expression with no kind filter — the property the tests exist to pin.
- **FR-4 / D4** — a `PAYABLE` account entered at −500000 puts −500000 in `owedByMe`'s sum
  and drags `net` down by 500000; a `borrow` against it pushes `owedByMe` further negative.
- **D5, pinned** — a `kind=adjustment` row inserted under **each** of Q4's candidate
  encodings (A: one side + `|amount|`; B: fixed `to` side + signed amount) drives the same
  account to the same resulting balance through `watchBalances()`. This is D5 made
  checkable: whichever encoding UC-03 eventually writes, these figures were already
  correct and stay correct.
- **Empty database** — fresh DB yields zeros for all four figures and an empty list, not
  an error (COALESCE behaviour of D4).
- **Widget, FR-1** — the screen renders the four figures distinctly plus the account list,
  via `ProviderScope` overrides over an in-memory `AppDatabase`; messages 1/7/13 exercised.

---

## Out of scope

- **UC-10's debt progress.** `debtProgressProvider`, `DebtProgress`,
  `AccountDao.watchDebtProgress()`, `DebtDetailScreen`, `markSettled()`/`setSettled()`,
  the `settled` flag — separate lifelines on `class-accounts.drawio`, drawn on
  `seq-uc10`, owned by `UC10-debt-progress`. Only `watchPosition()` and `watchBalances()`
  leave `AccountDao`'s method list in this issue.
- **Any write to `Transactions` or `Accounts`.** Recording is `UC04-record-money-movement`;
  adjusting is `UC03-adjust-account` (HALTED on Q4); editing/deleting accounts is
  `UC02B-edit-account` (HALTED on Q3). This issue reads and never writes (D6).
- **Deciding Q4 or Q3.** Both sit with their owning issues; D5 shows UC-01 needs neither
  answer.
- **Spending totals, budget consumption, "Others".** `to_account_id IS NULL` as a
  spending predicate belongs to UC-12; no such figure is on FR-1's list or this diagram.
- **Currency display.** No `SettingsDao`/settings lifeline is drawn on `seq-uc01`, so the
  screen renders raw minor-unit integers: no prefix, no exponent formatting. Adding a
  settings read would widen the diagram `CLAUDE.md` makes absolute. See Open questions.
- **A navigation host, router or menu.** On no class diagram; `pm/findings.md` F8 (D7).
- **Fixing the stale isolate note on this or any other diagram ahead of the as-built
  pass.** F3, repo-wide.
- **Any schema change, migration or new snapshot.** `schemaVersion` stays 1 (D6).
- **Renaming the package / repo / diagram-title split** (`moneytracker` vs `uangsaku`) —
  left alone deliberately since FEAT01 D1.

---

## Contradictions and stale notes found while planning

1. **`pm/tracker.yaml`'s UC01 row says "One query"** — the diagram draws **two**
   (`watchPosition()` and `watchBalances()`, messages 3 and 9, two separate result
   streams). Understated rather than wrong — both are joins of the same two tables — and
   the row's substantive claims (no stored balance, first cross-module join, four figures
   never merged) all hold. Recorded here; the row gets its close-time summary rewrite at
   step 10 anyway. Left unedited now because a planner edits its own issue's placeholder,
   not the tracker.
2. **The isolate note on `seq-uc01-balance-sheet.drawio` is stale** — `createInBackground`
   vs the shipped `driftDatabase()` path. Already tracked repo-wide as F3; listed as
   discrepancy 1 under *Scope* so the as-built pass cannot miss it.
3. Nothing else. UC-02's D9 prediction — that messages 7–8 of `seq-uc02` become real when
   this issue lands — matches this plan exactly; no artifact contradicts another.

---

## Open questions — genuinely non-blocking

- **How the four figures render.** Raw minor-unit integers (D-out-of-scope: currency
  display) means USD's exponent-2 formatting and the currency prefix have no home yet, and
  whether "owed by me" displays as a positive magnitude under an "I owe" heading or as its
  stored negative is undecidable from any artifact. Neither affects what is computed or
  stored; the natural landing spots are a small display-formatting issue or UC-09's list
  work. Flagged so it is a known gap, not a surprise screenshot.
- **`pm/findings.md` F8**, one screen worse: `AccountFormScreen` joins the orphans. Does
  not block — D7 continues the exact pattern the last three screen issues used — but this
  is the first issue whose `home` replacement is *permanent*, which makes the next
  navigation ask likelier.
