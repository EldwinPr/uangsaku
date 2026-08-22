# UC10-debt-progress — See how much of a debt is paid

**Status:** DONE 2026-08-23 — planned under unattended mode (AUTO-CONFIRMED)
(`general-rules.md`, planning gate; `decisions.md` 2026-08-21). Every decision below
derives from an artifact the owner has already confirmed, cited per D-entry: the
sequence diagram, `class-accounts.drawio`, FR-11, `docs/enums.md`, `docs/statuses.md`,
`docs/workbook.xlsx`'s UC-10 row, ISSUE-001 D7/D8, dated entries in
`context/index/decisions.md`, and shipped code whose pattern prior rulings fixed.
Nothing here is chosen without a citation.

**Traces to:** UC-10
**Depends on:** UC02-add-account — **DONE** 2026-08-22 in `pm/tracker.yaml`.
**Preflight passes**: dependency satisfied, and no scope overlap with any active issue —
the other two Accounts-chain issues (`UC02B-edit-account`, `UC03-adjust-account`) are
HALTED on *their own* write-path rulings (Q3 delete semantics, Q4 adjustment encoding);
this issue's only writes are `settled`/`settled_at` on `Accounts` (D6/D7), which neither
halted issue touches, and its read of `Transactions` is the same sides-based join UC01
already shipped. `UC01-balance-sheet` is DONE and owns none of this issue's classes —
its plan explicitly left every one of them (see Out of scope there).

---

## Goal

The owner can open any debt — money owed to them (`RECEIVABLE`) or owed by them
(`PAYABLE`) — and see two derived figures: how much of it has been paid off, and how much
is left (FR-11). They can tick the debt done at any moment they choose; the app never
blocks that tick because the arithmetic disagrees, and never ticks it by itself
(NFR-4). Both figures are computed at read time from `Accounts` + `Transactions`
(NFR-2), and settling stamps the flag-plus-date ISSUE-001 D8 put on the schema — which
FEAT01 already shipped as columns, so nothing here changes the schema.

---

## Scope: the sequence diagram

`CLAUDE.md`: *a plan's scope IS whatever its sequence diagram shows.*
`docs/diagrams/seq-uc10-debt-progress.drawio`, render committed at
`pm/issues/uc10-debt-progress/seq-uc10-debt-progress.png`, looked at while writing this
plan (labels from the `<UserObject label="…">` wrappers, `lessons.md` §4).

**Seven messages, one read path, one write path inside an `opt`, no `alt`.**

| # | From → To | Message |
|---|---|---|
| 1 | Owner → `DebtDetailScreen` | opens a debt (money owed in either direction) |
| 2 | `debtProgressProvider` ⇢ `DebtDetailScreen` | paid / remaining (derived from UC-08 repayments, first emission) *(stream emission)* |
| — | **`opt [owner marks the debt settled (FR-11; NFR-4 - the owner's call, not blocked by the arithmetic and not ticked automatically)]`** | |
| 3 | `DebtDetailScreen` → `AccountsNotifier` | `markSettled(accountId)` |
| 4 | `AccountsNotifier` → `AccountDao` | `setSettled(accountId)` |
| 5 | `AccountDao` → `AppDatabase` | `setSettled(accountId)` |
| 6 | `AppDatabase` ⇢ `AccountDao` | row updated *(reply)* |
| — | *(end opt)* | |
| 7 | `debtProgressProvider` ⇢ `DebtDetailScreen` | paid / remaining (settled) *(stream emission)* |

Plus one note: *"DAO to AppDatabase crosses the isolate boundary
(NativeDatabase.createInBackground, 2026-08-20)"* — **stale**, see *Discrepancies for the
as-built pass* item 1.

**The `opt` guard needs no resolution, unlike UC14's.** UC14's guard named an app-side
predicate ("an existing currency is being changed") that no schema could express, which
is why Q1 existed. This guard names a *user action*: "if and when the owner taps mark
settled." There is nothing for code to evaluate — no branch, no confirmation dialog, no
refusal path. NFR-4 is satisfied by the control simply existing, always enabled, doing
what it says (D8). The guard's own text already carries the ruling: *"the owner's call,
not blocked by the arithmetic and not ticked automatically"* — so no automatic settlement
at zero either.

**Lifeline check — every lifeline already exists on a class diagram** (the ISSUE-008
rule; `lessons.md` §10). All six non-actor lifelines are boxes on
`docs/diagrams/class-accounts.drawio`, spelled identically:

| Lifeline | On `class-accounts.drawio` as | Owned by |
|---|---|---|
| Owner | actor, not a class | — |
| `DebtDetailScreen` | `DebtDetailScreen` — *UC-10 · ConsumerWidget* | **this issue** |
| `debtProgressProvider` | `debtProgressProvider` — *StreamProvider.family · UC-10* | **this issue** |
| `AccountsNotifier` | `AccountsNotifier` — *Notifier, exposed as accountsProvider; addAccount() · adjustAccount() · markSettled()* | UC-02 shipped the class + `addAccount()`; **this issue adds `markSettled()`** |
| `AccountDao` | `AccountDao` — *watchPosition() watchBalances() watchDebtProgress() / insert() update() setSettled()* | UC-01 shipped the watches, UC-02 `insert()`; **this issue adds `watchDebtProgress()` + `setSettled()`** |
| `AppDatabase` | `AppDatabase` — *shared by all four modules* | FEAT01, shipped |

Result class `DebtProgress` (*query result · UC-10 paid / remaining*) is also a box on
the same diagram. **No class is invented and none is missing.**

**Three discrepancies for the as-built pass — recorded, not fixed here** (the main
session owns diagram edits):

1. **The isolate note is stale**, on this diagram as on fifteen others: FEAT01 opened
   the database with `drift_flutter`'s `driftDatabase()`, whose native path calls
   `NativeDatabase.createBackgroundConnection` (`decisions.md` 2026-08-21, FEAT01
   ruling 2). The guarantee is right; the mechanism name is wrong. `pm/findings.md`
   **F3** — record against F3, do not fix diagrams issue-by-issue.
2. **The read path's subscription messages are not drawn.** Messages 2 and 7 draw the
   provider→screen emissions but not `DebtDetailScreen` → `debtProgressProvider`
   `watch(accountId)`, nor `debtProgressProvider` → `AccountDao.watchDebtProgress()`,
   nor the DAO→AppDatabase query/reply beneath them. Every closed issue's as-built pass
   established that these are drawn when they exist (UC13's close added five such
   messages; seq-uc11's corrected a missing `watch()`). Record for the as-built pass;
   adding them is a diagram edit, not a scope widening, because the class diagram's
   `StreamProvider.family` box and edge already bind screen → provider → DAO.
3. Nothing else. The write-path reply discipline matches convention: message 6 is a
   dashed reply into the DAO, and no reply arrow reaches the screen from any write —
   message 7 is a stream emission, the same shape seq-uc02 established.

---

## Decisions

### D1 — Three files' worth of change, in the Accounts module; `app.dart` untouched

*Cites:* `docs/diagrams/class-accounts.drawio` (every box lives in its Accounts bands);
`context/index/map.yaml` `code:` (one directory per module, followed since FEAT01);
`pm/issues/uc01-balance-sheet/plan.md` D1 (the module's file layout, and its Out-of-scope
entry naming exactly these classes as UC-10's).

| File | Contains |
|---|---|
| `app/lib/src/accounts/account_dao.dart` | **extended**: `DebtProgress` result class beside `FinancialPosition`/`AccountBalance`; `watchDebtProgress(accountId)` and `setSettled(accountId)` beside the shipped methods |
| `app/lib/src/accounts/accounts_providers.dart` | **extended**: gains `debtProgressProvider` beside the three shipped providers |
| `app/lib/src/accounts/debt_detail_screen.dart` | **new**: `DebtDetailScreen` |

Plus tests under `app/test/accounts/`. **`app/lib/src/app.dart` is NOT touched** — home
stays `BalanceSheetScreen` permanently (FR-1, UC-01 D7); `DebtDetailScreen` ships
unreachable like every screen before a navigation host exists (D9). No schema change
(D10): `drift_schema_v1.json` must be **byte-identical** at close, the check UC-11,
UC-14, UC-02 and UC-01 all ran.

### D2 — Every name comes from the class diagram verbatim

*Cites:* `context/coding-conventions/README.md` §*The rule that outranks the rest*.

`DebtDetailScreen`, `debtProgressProvider`, `AccountsNotifier.markSettled()`,
`AccountDao.watchDebtProgress()`, `AccountDao.setSettled()`, `DebtProgress`. The class
diagram labels `debtProgressProvider` *StreamProvider.family*, which binds the family
parameter too: the id of the account being viewed — matching `markSettled(accountId)` /
`setSettled(accountId)` / `watchDebtProgress(accountId)` on the sequence diagram and the
workbook's Input (*"The debt or person to look at"*). `DebtProgress` carries the fields
message 2 names — `paid` and `remaining`, both `int` minor units, never a double
(`docs/enums.md`; NFR-2) — plus `settled` (bool), which message 7's label
*"paid / remaining (settled)"* requires: the write returns nothing to the screen
(`riverpod.md`'s read/write asymmetry, standing rule), so the only way the screen learns
the tick landed is the stream re-emitting with `settled` true. All three fields are
named on cited artifacts; none is invented.

### D3 — The query is written inside `AccountDao`; no other module's DAO is called

*Cites:* `context/index/decisions.md` 2026-08-20 — *"Modules reach each other's data by
SQL join, not by calling another module's DAO"* (ISSUE-005 D1, owner-confirmed): one SQL
statement over `Accounts` + `Transactions`, no Dart-side stitching, `TransactionDao` not
imported. Same decision names `AccountDao` reading `Transactions` as legitimate, and its
consequence section lists UC-10 among the joins that create the Accounts↔Transactions
cycle.

Concretely: `watchDebtProgress()` is a drift watched custom select joining
`accounts_table.dart`'s `Accounts` with `transactions_table.dart`'s `Transactions`,
returning `Stream<DebtProgress>` — one stream, wrapped once by the provider (D9).

### D4 — paid and remaining, each one expression, both magnitudes

*Cites:* **workbook UC-10 step 2, verbatim:** *"System shows how much of it is paid off
and how much is left, **derived from the repayments recorded in UC-08**"*; **sequence
diagram message 2, verbatim:** *"paid / remaining (derived from UC-08 repayments,
first emission)"*; **`docs/diagrams/seq-uc08-repayment.drawio` note, verbatim:**
*"outstanding amount and paid-off progress (FR-11) are derived by summing transactions
against the debt account, not stored separately (NFR-2)"*; ISSUE-001 D7 (no stored
balance anywhere) and D8 (*"Paid and remaining are derived from transactions"*);
`docs/enums.md` — *"A balance is likewise one expression over one table (NFR-2)"*, and
the `Transaction.kind` row `repayment | either side | the other`.

With `balance(a)` = UC-01's already-shipped sides-based expression
(`openingAmount + Σto − Σfrom`):

```
paid      = COALESCE(Σ t.amount WHERE t.kind = 'repayment'
                       AND (t.from_account_id = a OR t.to_account_id = a), 0)
remaining = ABS(balance(a))
```

Two derivations, each citable rather than chosen:

- **`remaining` is the outstanding amount**, which `decisions.md` 2026-08-19 states
  outright: *"a debt is simply transactions against an owed-type account. Its balance
  *is* the outstanding amount."* It is `balance(a)` itself — the same expression UC01
  D4 shipped and its tests pin — shown as a magnitude because FR-11 asks "how much is
  left", a quantity, and PAYABLE balances store signed-negative (UC-02 D6: opening
  stored signed as entered, no group-based negation).
- **`paid` sums repayment-kind rows touching the account.** Two confirmed artifacts name
  repayments as the source of "paid" in this use case specifically — the workbook's step
  2 and message 2's own label — and the third (seq-uc08's note) says "summing
  transactions", which a kind-filtered sum satisfies. The filter is also what makes the
  figure honest: a repayment against a debt account always moves that account toward
  zero (it is the only kind that does so between a debt account and a wallet), so the
  sum needs no direction case per group.

Both figures stay derived, never written back (NFR-2); nothing here creates a third
stored value alongside `opening_amount` and the ledger — the exact thing `enums.md`'s
stated-non-members entry forbids (*"the third value would be a stored duplicate of a
derivable number, which NFR-2 forbids"*).

### D5 — Q4 does not block this issue — and D4 is what makes that true

This is the check the run asked for explicitly, stated with citations. `pm/questions.md`
**Q4** (OPEN, blocking `UC03-adjust-account`) asks which sides of a `kind=adjustment`
row carry the account and whether the amount is signed. Testing each figure:

- **`remaining` cannot depend on Q4.** It is `ABS(balance(a))` (D4), and balance
  references only *which side a row touches*, never `kind`. Q4's own options table shows
  option A (side follows sign) and option B (fixed `to` side, signed amount) both give a
  net contribution of `diff` to `balance(a)` — this is precisely UC-01 plan D5's
  argument, already pinned by UC-01's dual-encoding test, applied to the same expression.
  Option C (something else) cannot move it either: a row touching neither side
  contributes zero under any reading.
- **`paid` cannot depend on Q4.** It sums only `kind = 'repayment'` rows, and the
  repayment row of `enums.md`'s table — `repayment | either side | the other` — is fixed
  independently of Q4, which concerns the `adjustment` row alone.
- **The converse proves the point:** had `paid` been defined over *all* transactions
  touching the account (no kind filter), Q4 option A would make a downward correction
  count as paid — a cash-count fix would display as money repaid. D4's repayment filter
  is not an extra rule bolted on; it is the citable derivation (two artifacts name
  repayments) that simultaneously removes the only channel by which Q4 could reach this
  screen.

So whichever way the owner answers Q4, `watchDebtProgress()` needs no rewrite, no
migration and no re-test. **No halt.** As at UC-01, the converse risk runs the other
way: UC-03's eventual encoding must be checked against D4's balance expression, and that
check belongs to UC03's plan.

### D6 — `setSettled` writes flag plus date; the date comes through the injected clock

*Cites:* **ISSUE-001 D8, verbatim:** *"'Mark it done' is a settled flag **plus date**
on the `RECEIVABLE`/`PAYABLE` account"* — and FEAT01 shipped exactly those columns
(`accounts_table.dart`: `settled` bool default false, `settled_at` nullable); leaving
`settled_at` permanently null would strand a column the confirmed ERD decision put
there. `context/index/decisions.md` 2026-08-19 records the standing discipline —
*"inject the clock rather than calling the system clock directly"* — and the shipped
code's concrete form of it is `BudgetDao({this._clock = const Clock()})`
(`budget_dao.dart`), the existing-code convention `pm/questions.md` names as the
tie-breaker when the diagrams are silent on implementation. `Clock` itself is a plain
const utility (`clock.dart`); modules are *"an organising convention and nothing more"*
(`decisions.md` 2026-08-20), and importing it costs nothing the component diagram
doesn't already declare.

So: `setSettled(accountId)` runs one update — `settled = true`, `settled_at = clock
now` — and returns `Future<void>`. Per `docs/enums.md`'s stated non-members entry, the
flag has *"two values, one move"*: false→true only. **There is no un-settle method** —
not on this diagram, not on any class diagram, and inventing one would break D2. If the
owner ticks twice, the second write is harmless (idempotent update, refreshed date),
which NFR-4 prefers to any guard.

### D7 — Read-only plus one flagged write; no kind predicate beyond `repayment`, no spending predicate

*Cites:* the sequence diagram — messages 2–7 contain exactly one write (`setSettled`)
and one read (`watchDebtProgress`); ISSUE-001 D7 (no stored balance, figures derived);
`docs/enums.md`'s property paragraph — the `to_account_id IS NULL` spending predicate
belongs to FR-8/FR-9/FR-12 figures, none of which appear here; UC-01 D5/D4 precedent for
keeping `kind` out of balance arithmetic.

`watchDebtProgress()` filters on `kind = 'repayment'` **only inside the `paid` sum**
(D4's citation-backed definition); the balance half of the query uses no `kind` filter
and no spending predicate, exactly as UC-01's shipped queries do. `schemaVersion` stays
1; `Transactions` is read, never written — the first write to it still belongs to
UC-03/UC-04.

### D8 — One hand-written single-stream `StreamProvider.autoDispose.family`; the multi-stream ruling does not bite

*Cites:* `docs/diagrams/class-accounts.drawio` labels `debtProgressProvider`
***StreamProvider.family* · UC-10** — the diagram binds the shape as well as the name;
`context/index/decisions.md` 2026-08-21 (UC-13 rulings) — hand-written providers, never
`@riverpod`: `riverpod_generator` throws `InvalidTypeException` on providers typed over
drift row classes and would rename away from the diagram's spelling;
`context/index/decisions.md` 2026-08-22 (UC-11 ruling) bans combining several drift
streams into one state object — not triggered: this provider wraps exactly one drift
stream (`watchDebtProgress()`'s), the shape UC-11's probes proved closes cleanly and
every shipped provider uses. Family-over-int is the standard Riverpod form; no generated
types involved.

### D9 — `home` is untouched; `DebtDetailScreen` ships unreachable, continuing F8

*Cites:* FR-1 via UC-01 plan D7 — `MaterialApp.home` is `BalanceSheetScreen`
*permanently*; `pm/findings.md` **F8** — no navigation host exists, so every new screen
is reachable only by tests until the owner rules on navigation; message 1 (*"opens a
debt"*) draws the owner arriving, but the route by which they arrive is on no class
diagram and cannot be invented here (`lessons.md` §10's rule about inventing layers).

`DebtDetailScreen` is therefore the fifth built-but-unreachable screen, and the first
that was **never reachable at any point** — the previous four were orphaned after
holding `home`. Recorded against F8 at close (step 10), not fixed: a navigation host is
the owner's open call, already queued in F8.

### D10 — No schema change anywhere in this issue

*Cites:* the shipped table — `Accounts.settled` and `Accounts.settledAt` exist since
FEAT01's v1 schema (`accounts_table.dart`); `docs/statuses.md` records `Account.settled`
as *"a flag, not a lifecycle; no diagram"* — so no state machine, no status value, and
no migration accompanies the tick. `schemaVersion` stays 1; `drift_schemas/` untouched.

---

## Steps

Executable in order.

1. `DebtProgress` as a plain Dart class in `app/lib/src/accounts/account_dao.dart` —
   immutable, `int` minor-unit fields for `paid`/`remaining`, `bool settled`, free of
   Flutter imports (D2; the pure-Dart domain rule, `decisions.md` 2026-08-19 Flutter
   entry).
2. Give `AccountDao` the optional injected clock, mirroring the shipped `BudgetDao`
   constructor pattern (`{Clock clock = const Clock()}`) (D6).
3. `AccountDao.setSettled(accountId)` — one update setting `settled = true` and
   stamping `settled_at`; returns `Future<void>`; no result ever reaches the screen
   (D6, D7).
4. `AccountDao.watchDebtProgress(accountId)` — one watched custom select computing D4's
   two expressions in SQL (repayment-sum + ABS(balance)), joined per D3, returned as
   `Stream<DebtProgress>`; enum literal bound as a variable holding the stored text,
   the way the shipped queries handle `AccountGroup` values.
5. `debtProgressProvider` in `app/lib/src/accounts/accounts_providers.dart` —
   hand-written `StreamProvider.autoDispose.family<DebtProgress, int>` over the DAO
   watch (D8). Existing providers and `AccountsNotifier`'s shape stay as shipped.
6. `AccountsNotifier.markSettled(accountId)` — forwards to `_dao.setSettled(...)`,
   returns nothing meaningful to the caller (read/write asymmetry, D2).
7. `DebtDetailScreen` in `app/lib/src/accounts/debt_detail_screen.dart` — a
   `ConsumerWidget` watching `debtProgressProvider(parameter)` (messages 2, 7): shows
   paid and remaining as two distinct figures, and a settle control that is **always
   enabled** and fires `markSettled(accountId)` directly — no confirmation gate, no
   arithmetic check, no disabled state (NFR-4 zero refusals; the opt guard's own text).
   After the tick, the next emission shows the settled state (message 7); the screen
   offers no action the app could refuse, so NFR-4 has nothing else to bite on. Loading
   and empty states render zeros/placeholders, never errors.
8. Tests in `app/test/accounts/`, per Definition of done below.
9. Run the standard four commands from `app/` and the byte-identical snapshot check
   (D10). Fix, repeat until clean.
10. Correct any `context/coding-conventions/` file this issue contradicted, in place,
    and say so in `pm/log.md`.
11. Close per `CLAUDE.md`'s checklist. Named individually because `lessons.md` §1:
    - **As-built pass on `seq-uc10-debt-progress.drawio`** — reconcile against what was
      built. Discrepancy 1 goes to `pm/findings.md` **F3** (recorded repo-wide);
      discrepancy 2 — add the missing read-path subscription messages
      (screen→provider `watch`, provider→DAO `watchDebtProgress`, DAO→AppDatabase
      query + reply) following the shapes UC-13's and UC-11's as-built passes drew.
      Whatever is edited, re-export the PNG into `pm/issues/uc10-debt-progress/` and
      **look at the render** (`lessons.md` §3); refresh `docs/diagrams/renders.lock`.
    - **`pm/findings.md` F8** — append that `DebtDetailScreen` joined the orphans
      (fifth dead screen; first never-reachable one), `home` unchanged.
    - **`context/index/map.yaml`** — `UC-10 → app/lib/src/accounts/` entry under
      `code:`.
    - **`context/index/decisions.md`** — only if the toolchain forces a durable ruling,
      as at FEAT01/UC-13/UC-11. Not a formality; not an obligation.
    - **`pm/tracker.yaml`** — Done plus a one-line summary.
    - **`docs/workbook.xlsx`** UC-10 marked implemented (`general-rules.md`, done,
      step 4).
    - **`pm/log.md`** dated entry plus current-state block; **`pm/active.json`** → next
      issue. Note in the log that Q3 and Q4 remain OPEN and block UC02B/UC03 only —
      D5 is why this run continued past them.

---

## Definition of done

*Cites:* FEAT01 D7, UC-14 D8, UC-02 DoD, UC-01 DoD — the same headless four commands;
no Android SDK, no emulator, `flutter` at `C:/flutter/bin/flutter`, all run from `app/`:

1. `dart run build_runner build` — succeeds (no-op expected).
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under strict casts/inference/raw-types.
4. `flutter test` — green, on `NativeDatabase.memory()`, drift never mocked.

Plus: `git diff --stat app/drift_schemas/` is **empty** (D10).

**Tests, each named for the requirement it defends.** Fixtures insert `Accounts` and
`Transactions` rows directly through the in-memory database — test scaffolding, not a
write path:

- **FR-11 / D4, RECEIVABLE** — an account opened at 500000 with a repayment of 200000
  touching it yields `paid` 200000 and `remaining` 300000.
- **FR-11 / D4, PAYABLE, signed storage** — an account entered at −500000, borrowed
  500000 against (via its `from` side), then repaid 400000 (via its `to` side) yields
  `paid` 400000 and `remaining` 600000 — magnitudes despite negative storage, per D4.
- **D4's repayment filter, pinned** — inserting an additional `lend` of 100000 into the
  receivable raises `remaining` by 100000 and leaves `paid` untouched; the two figures
  move independently, which is what "derived from the repayments" asserts numerically.
- **D5, pinned** — a downward `kind=adjustment` correction inserted under **each** of
  Q4's candidate encodings (A: `from` side + `|amount|`; B: fixed `to` side + signed
  amount) drives `remaining` to the same value and leaves `paid` unchanged under both.
  This is D5 made checkable: whichever encoding UC-03 eventually writes, this screen was
  already correct and stays correct.
- **FR-11 / D6, the tick** — `setSettled` flips `settled` and stamps `settled_at`;
  `watchDebtProgress()` re-emits with `settled: true` (message 7). Calling it twice
  succeeds and keeps the stream healthy (no refusal path; NFR-4).
- **Empty ledger** — a fresh account with no transactions yields `paid` 0 and
  `remaining` = |openingAmount| (COALESCE behaviour of D4).
- **Widget / NFR-4** — the screen renders both figures and the settle control enabled
  with no dialog on tap; tapping drives notifier → DAO → emission, updating the display
  (messages 3–7 exercised) via `ProviderScope` overrides over an in-memory
  `AppDatabase`.

---

## Out of scope

- **Navigation to `DebtDetailScreen`.** No route exists; `home` stays
  `BalanceSheetScreen` permanently (D9). A navigation host is the owner's open call,
  queued in `pm/findings.md` F8.
- **Recording repayments, lends, borrows.** UC-08's recording flow belongs to
  `UC04-record-money-movement`; this issue only reads the rows (D7).
- **Automatic settlement.** The guard text says *"not ticked automatically"* — reaching
  `remaining == 0` must not set the flag (D8/NFR-4).
- **Un-settling, editing or deleting the account.** One move on the flag
  (`enums.md` stated non-members); account CRUD is `UC02B-edit-account` (HALTED on Q3).
  `AccountDao.update()` sits unused on the class diagram and stays unused here.
- **Deciding Q3 or Q4.** Both sit with their owning issues; D5 shows UC-10 needs
  neither answer.
- **Spending totals, budget consumption, "Others".** No such figure is on this diagram;
  `to_account_id IS NULL` belongs to UC-12.
- **Currency display.** No settings lifeline is drawn on `seq-uc10`, so the screen
  renders raw minor-unit integers — the same known gap UC-01 recorded.
- **A progress percentage.** On no artifact: FR-11, the workbook Output, and the diagram
  all say paid / remaining amounts. A ratio would be a derived number nobody asked for.
- **Any schema change, migration or new snapshot.** `schemaVersion` stays 1 (D10).
- **Fixing the stale isolate note ahead of the as-built pass.** F3, repo-wide.

---

## Contradictions and stale notes found while planning

1. **The tracker row, workbook row and diagram all agree** — paid/remaining for one
   RECEIVABLE/PAYABLE account plus the manual tick; nothing contradicts. The one
   wording nuance: workbook step 2 and message 2 say "derived from the repayments",
   while ISSUE-001 D7 and seq-uc08's note say "derived from transactions" — resolved by
   D4 (a kind-filtered sum **is** derived by summing transactions), not by editing any
   artifact.
2. **The isolate note on `seq-uc10-debt-progress.drawio` is stale** — already tracked
   repo-wide as F3; listed as discrepancy 1 under *Scope* so the as-built pass cannot
   miss it. In this render the note's text also runs tight against the canvas edge
   (legible, not clipped) — worth a glance when F3's batch fix touches this file.
3. Nothing else. UC-01's Out-of-scope list predicted this issue's exact class set; the
   class diagram's method lists match what remains to build, method for method.

---

## Open questions — genuinely non-blocking

- **How the owner reaches a debt.** Message 1 has no route until F8's navigation ruling
  lands. Does not block — the screen, provider and DAO are fully exercisable by tests,
  the pattern of all five screen issues so far.
- **What the screen titles itself with.** The family parameter is an id; no drawn
  message fetches the account's *name*, so the header may show a bare id unless the
  coder reuses an existing provider. Display-only, no data consequence; noted so it is
  a known gap, not a surprise screenshot.
- **Currency prefix/formatting** — shared with UC-01; natural landing spot is the same
  future display-formatting work.
