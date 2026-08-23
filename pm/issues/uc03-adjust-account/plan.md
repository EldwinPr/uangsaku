# UC03-adjust-account — Correct what an account holds

**Status:** DONE 2026-08-23. Was CONFIRMED — Q4 answered (`pm/questions.md`, `context/index/
decisions.md` "Adjustment encodes as fixed side + signed amount"). Planned under
unattended mode 2026-08-23, halted on one decision, now resolved: **`to_account_id` is
always the corrected account, `from_account_id` is always `null`, `amount` carries the
signed diff** (Option B — negative for a downward correction). Every other decision below
already cited an already-confirmed artifact and stands unchanged; only step 1's column
values were waiting on Q4.

**Traces to:** UC-03 (`docs/workbook.xlsx` → `UC FR`), FR-18.
**Depends on:** `UC02-add-account` — **DONE** 2026-08-22 in `pm/tracker.yaml`.
**Preflight:** passes. The one declared dependency is Done; `FEAT01-foundation`,
`UC13-categories`, `UC11-set-budget`, `UC14-choose-currency` are Done. No other active
issue owns anything under `app/lib/src/accounts/` (`UC02B-edit-account` is HALTED behind
Q3 and depends *on* this issue's sibling, not on overlapping scope). The halt below is a
content halt, not a preflight failure.

---

## Goal

The owner can open an account whose derived amount no longer matches reality, enter what
it should actually be, and the system records the **difference as one visible
`adjustment` transaction** — written into `Transactions` through `AccountDao` — after
which the account's derived balance reads correctly from then on. Nothing is overwritten:
NFR-2 keeps every balance derived, so correcting is recording, not editing a stored
figure. This is the second use case on the write path into the ledger table, and the
first issue to write a `Transactions` row at all.

---

## Scope: the sequence diagram, reconciled

`CLAUDE.md`: *a plan's scope IS whatever its sequence diagram shows.*
`docs/diagrams/seq-uc03-adjust-account.drawio`, render committed at
`pm/issues/uc03-adjust-account/seq-uc03-adjust-account.png` and looked at while writing
this plan (`lessons.md` §3, §4 — labels live on `<UserObject label="…">` wrappers).

**Fifteen messages, one flow, no `alt`, no `opt`, no loop**, plus two notes:

| # | From → To | Message |
|---|---|---|
| 1 | Owner → `AccountFormScreen` | open account whose recorded amount no longer matches reality |
| 2 | `AccountFormScreen` → `accountBalancesProvider` | `watch(accountId)` |
| 3 | `accountBalancesProvider` → `AccountDao` | `watchBalances()` |
| 4 | `AccountDao` → `AppDatabase` | query account + transactions |
| 5 | `AppDatabase` ⇢ `AccountDao` | rows *(reply)* |
| 6 | `AccountDao` ⇢ `accountBalancesProvider` | `Stream<AccountBalance>` *(reply)* |
| 7 | `accountBalancesProvider` → `AccountFormScreen` | `AccountBalance` (current derived amount) |
| 8 | Owner → `AccountFormScreen` | enter what it should actually be |
| 9 | `AccountFormScreen` → `AccountsNotifier` | `adjustAccount(accountId, targetAmount)` |
| 10 | `AccountsNotifier` → `AccountDao` | `insert(kind=adjustment, account, diff)` |
| 11 | `AccountDao` → `AppDatabase` | insert adjustment transaction row |
| 12 | `AppDatabase` ⇢ `AccountDao` | ok *(reply)* |
| 13 | `AccountDao` ⇢ `AccountsNotifier` | ok *(reply)* |
| 14 | `accountBalancesProvider` → `AccountFormScreen` | `AccountBalance` (corrected amount) — stream emission |
| 15 | `financialPositionProvider` → `BalanceSheetScreen` | `FinancialPosition` (updated four figures) |

Notes: the isolate note (stale mechanism name — F3, repo-wide); and *"AccountDao writes
the adjustment row into Transactions itself — modules reach each other's tables directly
rather than calling another module's DAO (ISSUE-005 D1)."*

**Lifeline check — every lifeline already exists on a class diagram** (the `ISSUE-008`
rule that caught a real defect per `lessons.md` §10). All eight non-actor lifelines are
boxes on `docs/diagrams/class-accounts.drawio`, spelled identically:

| Lifeline | On `class-accounts.drawio` as | Owned by |
|---|---|---|
| Owner | actor, not a class | — |
| `AccountFormScreen` | `AccountFormScreen` — *UC-02, UC-03 · ConsumerWidget* | **this issue** (extends) |
| `AccountsNotifier` | *Notifier, exposed as `accountsProvider`; `addAccount()` · `adjustAccount()` · `markSettled()`* | **this issue** (`adjustAccount()`) |
| `AccountDao` | *watchPosition() watchBalances() watchDebtProgress() / insert() update() setSettled()* | **this issue** (gains the adjustment insert) |
| `accountBalancesProvider` | `accountBalancesProvider` — *StreamProvider* | UC-01 (D5) |
| `AppDatabase` | `AppDatabase` | FEAT01, shipped |
| `financialPositionProvider` | `financialPositionProvider` — *StreamProvider · UC-01* | UC-01 (D5) |
| `BalanceSheetScreen` | `BalanceSheetScreen` — *UC-01 · ConsumerWidget* | UC-01 (D5) |

No class is invented and none is missing.

**Three discrepancies for the as-built pass — recorded, not fixed here** (the main
session owns diagram edits):

1. **The isolate note is stale** — `driftDatabase()` /
   `createBackgroundConnection`, not `createInBackground`. This is `pm/findings.md`
   **F3**; **ten diagrams remain**, this is one of them, corrected at this issue's close.
2. **Messages 2–7, 14 and 15 cannot fire at this issue's close**: their producers
   (`accountBalancesProvider`, `financialPositionProvider`, `BalanceSheetScreen`,
   `AccountDao.watchBalances()`) are UC-01's classes and `UC01-balance-sheet` has not
   run. Same build-order artifact as UC02 plan D9 — the diagram is right about the
   architecture and ahead of the build order. Notably this means **the form cannot yet
   display message 7's current amount**; the adjust flow must not depend on it (D3).
3. **Message 10's label names `diff` as if it arrived as an argument.** Read with
   message 9 — which passes `targetAmount`, not `diff` — and with the absence of any
   read message between them, the label describes what the inserted row contains, not a
   value computed above the DAO. D3 resolves this reading, and Q4's answer confirms it:
   `diff` is exactly the signed `amount` the resolved encoding stores.

---

## Q4, now answered

**`context/index/decisions.md`, 2026-08-23 — "Adjustment encodes as fixed side + signed
amount":** `to_account_id` is always the corrected account, `from_account_id` is always
`null`, `amount` carries the signed diff (positive up, negative down). Chosen over
side-follows-sign because that option's downward correction would satisfy `to_account_id
IS NULL` and read as **spending** everywhere that predicate is checked, including UC-12's
"Others" — the opposite of the workbook's "visible, not silent" requirement. The chosen
encoding requires **no change to any already-shipped query**: UC-01, UC-09, UC-10 and
UC-12 were all built and tested encoding-independent (each cites `to_account_id IS NULL`
with no `kind` filter, pinned by a dual-encoding test), and the balance formula
`SUM(to_account_id contributions) − SUM(from_account_id contributions)` already handles a
signed `amount` correctly on the `to` side.

---

## Decisions

All citable. D1–D7 stand regardless of how Q4 is answered; only the row encoding
(step 1's column values) waits.

### D1 — Three existing files extended; no new module files; no schema change

*Cites:* `docs/diagrams/class-accounts.drawio` (every class this issue touches already
has a box); `context/index/map.yaml`'s one-directory-per-module layout; the shipped code
under `app/lib/src/accounts/`.

| File | Change |
|---|---|
| `app/lib/src/accounts/account_dao.dart` | gains the adjustment-insert method (D2, D3) |
| `app/lib/src/accounts/accounts_providers.dart` | `AccountsNotifier` gains `adjustAccount()` (D2) |
| `app/lib/src/accounts/account_form_screen.dart` | gains the adjust flow (D6) |

Plus tests under `app/test/accounts/`. **Nothing else.** No new screen — the class
diagram gives UC-03 no box that UC-02 did not already build, and the sequence diagram
reuses the `AccountFormScreen` lifeline. No schema change: the `Transactions` table has
existed since FEAT01 (`app/lib/src/transactions/transactions_table.dart`,
`schemaVersion 1`), so `drift_schema_v1.json` must be **byte-identical** at close — the
check every code issue since FEAT01 has run. One doc comment in `account_dao.dart`
becomes false and is updated in step 1: *"Writes only Accounts"* was UC-02's slice
statement, and this issue is exactly the slice that ends it.

### D2 — Names come from the diagrams verbatim, within Dart's rules

*Cites:* `context/coding-conventions/README.md` (*class names match the class diagrams
exactly*); sequence messages 9–10; `class-accounts.drawio`, which lists
`adjustAccount()` on `AccountsNotifier`.

`adjustAccount(accountId, targetAmount)` on `AccountsNotifier` is spelled by both
diagrams. For the DAO, message 10 reads `insert(kind=adjustment, …)`, but Dart has no
overloading and `insert(AccountsCompanion)` already exists from UC-02 — two `insert`s
cannot coexist. Following `pm/questions.md`'s own rule (naming with no downstream
consequence follows the diagram where it can and the code's convention where it cannot),
the method is **`insertAdjustment({required int accountId, required int targetAmount})`**
— the diagram's kind argument becomes the method's name, and the signature takes what
message 9 actually delivers.

### D3 — `AccountDao` computes `diff` itself, in SQL; nothing above the DAO needs the current balance

*Cites:* sequence messages 9→10 (the form passes `targetAmount`; no read message is drawn
between them); note 1 on the diagram (*AccountDao writes into Transactions itself,
ISSUE-005 D1*); `context/index/decisions.md` 2026-08-20 — *"SQLite does the whole thing
in one statement … Stitching in Dart is a second place for a number to come from"*, and
*"`AccountDao` and `BudgetDao` both legitimately read `Transactions`"*; NFR-2.

The current amount is `opening_amount` plus the signed sum of movements on that account —
one expression over tables `AccountDao` may read by standing decision. Computing `diff =
targetAmount − current` inside the DAO's INSERT (a single statement over `Accounts` +
`Transactions`) is therefore both what the diagram licenses (nothing else intervenes
between messages 9 and 11) and what D1's reasoning prefers. **It also decouples this
issue from UC-01**: the write path never touches `accountBalancesProvider`, so the
tracker's dependency (`UC03 depends on UC02` only) stays true and the feature works
before any balance screen exists. Discrepancy 3 above is this decision's reading; it is
stated rather than silent.

### D4 — The insert is unconditional; a zero-diff adjustment writes a zero-diff row

*Cites:* the sequence diagram drawing **no `alt` and no `opt`** around messages 9–13; the
workbook UC-03 `Deskripsi` (*"System records the difference as an adjustment"*, with no
exception stated); the UC02 plan's D4 precedent that a missing branch on a diagram is a
dissolved question, not an omission.

If the entered target equals the current amount, `diff` is 0 and the row is written with
amount 0. A guard that skips the insert when nothing changed would be a branch the
diagram does not draw, and skipping part of the diagram needs an owner ruling
(`CLAUDE.md`). Zero is a legitimate record under NFR-4's assist-not-police rule — the app
records what happened, including "you corrected it to what it already was".

### D5 — Messages 2–7, 14 and 15 are UC-01's classes; this issue builds none of them

*Cites:* `docs/diagrams/seq-uc01-balance-sheet.drawio`, which draws the construction of
exactly these (`watch()` → `watchBalances()` → query → `Stream<AccountBalance>`);
`class-accounts.drawio`, which labels `financialPositionProvider` and `BalanceSheetScreen`
*UC-01*; UC02 plan D9, the identical ruling made one issue earlier; `CLAUDE.md`'s
one-diagram-per-use-case rule — two issues cannot both own constructing the same class.

So: **no `accountBalancesProvider`, no `financialPositionProvider`, no `BalanceSheetScreen`,
no `AccountDao.watchBalances()` / `watchPosition()`** land here. Messages 14–15 appear on
this diagram as the *effect* of the write — the stream emissions
`sequence-conventions.md` requires instead of reply arrows to screens — and they start
firing when UC-01 builds their producers. At this issue's close they cannot fire
(discrepancy 2); the as-built pass records it.

### D6 — The adjust flow lives on `AccountFormScreen`; reachability cost goes to F8, not solved here

*Cites:* the sequence diagram reusing the `AccountFormScreen` lifeline for messages 1, 2,
7 and 8 (message 1 requires the owner can open an *existing* account's form);
`class-accounts.drawio` labelling that screen *UC-02, UC-03*; `pm/findings.md` **F8**;
UC14 D3 / UC02 D8, the established handling.

The form gains the adjust path the diagram draws: designate an existing account, see its
current derived amount, enter what it should be, save always enabled. What the diagram
does not draw is any navigation — no route, no list screen, no picker widget as a class —
and no class diagram has a navigation host. So this issue follows the shipped pattern:
build what the diagram shows, **record against F8** that reaching a specific account's
form remains unsolved app-wide (F8 already counts UC-03 among the five screen-building
issues compounding it), and invent no router. Whether navigation becomes its own issue is
F8's standing question for the owner; it does not block this file.

### D7 — Nothing refused, nothing disabled; the date comes from the injected `Clock`

*Cites:* **NFR-4** (fit criterion *zero refusals*; every action succeeds, warning at
most); the sequence diagram drawing no confirmation, no guard, no refusal branch;
`pm/findings.md` **F7**; `Transactions.occurredOn` being non-null
(`transactions_table.dart`); `decisions.md` 2026-08-19 (*inject the clock*) and the
shipped `app/lib/src/budgeting/clock.dart` from UC-11.

- The save control is **always enabled**, including with an empty target field. An
  unparseable amount follows the shipped precedent — `int.tryParse(...) ?? 0` — because
  refusing is forbidden and inventing different behaviour is nobody's call; appended to
  F7 at close as the **third** screen sharing the parse.
- The row's `occurredOn` is today, read through the existing injected `Clock`, not
  `DateTime.now()` — the same testability rule UC-11 shipped for exactly this reason.
- No confirmation dialog; the diagram draws none.

---

## Steps

Executable once Q4 is answered; step 1's column values are the only thing waiting on it.

1. `app/lib/src/accounts/account_dao.dart`: add `insertAdjustment({required int
   accountId, required int targetAmount})` (D2). Inside one statement/drift transaction:
   derive the account's current amount (`opening_amount` + signed movement sum over
   `Transactions`, D3), compute `diff = targetAmount − current`, and insert one
   `Transactions` row with `kind = TransactionKind.adjustment`, `occurredOn` from the
   injected `Clock` (D7), nullable `categoryId` / `subcategoryId` / `budgetGroupId` /
   `note` left unset, **`toAccountId = accountId` always, `fromAccountId` always `null`,
   `amount = diff`** (signed — negative for a downward correction; Q4's resolved
   encoding). Update the now-false "writes only Accounts" doc comment (D1).
   Returns nothing to callers beyond completion — message 13 is `ok`.
2. `app/lib/src/accounts/accounts_providers.dart`: add
   `Future<void> adjustAccount({required int accountId, required int targetAmount})` to
   `AccountsNotifier`, forwarding to the DAO and returning nothing to the screen (message
   9→13; the result arrives on the read path, D5).
3. `app/lib/src/accounts/account_form_screen.dart`: the adjust flow of messages 1, 7, 8 —
   designate an existing account, show its current derived amount when the read path
   exists (it does not yet; degrade gracefully, D5/D3), accept the target amount as a
   signed `int` minor unit, save always enabled (D6, D7).
4. Tests in `app/test/accounts/` (Definition of done below), each named for the
   requirement it defends.
5. Run the four commands from `app/` before committing — CI runs the same steps.
6. Verify `app/drift_schemas/drift_schema_v1.json` is **byte-identical**
   (`git diff --stat app/drift_schemas/` empty). If not, something touched the schema,
   which D1 forbids.
7. Correct any `context/coding-conventions/` file this contradicted, in place, and say so
   in `pm/log.md`. First issue ever to write a `Transactions` row.
8. Close per `CLAUDE.md`'s checklist, named individually (`lessons.md` §1):
   - **As-built pass on `seq-uc03-adjust-account.drawio`** — discrepancies 1–3 above;
     correct the isolate note (F3 narrows **ten → nine**), re-export the PNG to
     `pm/issues/uc03-adjust-account/`, look at the render (`lessons.md` §3), refresh
     `renders.lock` via `audit.py --record-renders`.
   - **`pm/questions.md`** — verify Q4 is ANSWERED with its canonical-home pointer.
   - **`pm/findings.md`** — append to **F7** (third screen with the parse) and **F8**
     (fourth screen in the orphan chain, adjust flow reachable only through whatever
     navigation exists by then).
   - **`pm/tracker.yaml`** — Done plus a one-line summary.
   - **`context/index/map.yaml`** — `UC-03 → app/lib/src/accounts/` entry.
   - **`docs/workbook.xlsx`** UC-03 marked implemented — noting F5 stands: the sheet
     still has no column to mark it in, so the tracker remains the real register.
   - **`context/index/decisions.md`** — only if the toolchain forced a durable ruling.
   - **`pm/log.md`** dated entry + current-state block; **`pm/active.json`** → next.

---

## Definition of done

*Cites:* FEAT01 D7 / UC-14 D8 / UC-02 — the same four commands, headless, from `app/`
(`flutter` at `C:/flutter/bin/flutter`; no Android SDK needed; nothing here launches the
app):

1. `dart run build_runner build` — succeeds.
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under the strict modes; a left warning is argued here.
4. `flutter test` — green, `NativeDatabase.memory()`, drift never mocked.

Plus `git diff --stat app/drift_schemas/` empty (step 6).

**Tests:**

- **DAO, FR-18 / NFR-2** — adjust a fresh account (known opening amount) to a higher
  target: exactly **one** `Transactions` row appears, and the account's derived balance
  (`opening_amount` + movements) now equals the target. The core promise of the use case.
- **DAO, D4** — adjusting to the current amount still writes the zero-diff row: no
  branch, one row with amount 0.
- **DAO, D1** — `Accounts.opening_amount` is **unchanged** after any adjustment; the
  correction is a recorded row, never an overwrite. This is NFR-2's "recorded as
  something rather than written over", made checkable.
- **DAO, `docs/enums.md`** — the row's raw `kind` column holds the text `'adjustment'`,
  not an index (the `.textEnum<T>()` rule survives the first ledger write).
- **DAO, D3** — the diff reflects prior movement: an account with a recorded income
  adjusts by the difference against the *derived* total, not against `opening_amount`.
- **DAO, D7** — `occurredOn` equals the injected `Clock`'s date, proving the clock is
  honoured on the ledger path.
- **Widget, NFR-4** — the save control is enabled with the target field empty, and
  pressing it proceeds; this is the zero-refusals criterion asserted directly.
- **Widget** — the screen renders and `adjustAccount` reaches the database via a
  `ProviderScope` override over an in-memory `AppDatabase`.

---

## Out of scope

- **Renaming, editing or deleting an account** — `UC02B-edit-account` (HALTED behind Q3).
  No `update()` on `AccountDao`, no `delete()` anywhere; the FK consequence stays Q3's.
- **Constructing the read path** — `accountBalancesProvider`, `financialPositionProvider`,
  `BalanceSheetScreen`, `AccountBalance`, `FinancialPosition`,
  `AccountDao.watchBalances()` / `watchPosition()`, and the cross-module SQL join behind
  them (D5). All UC-01; messages 2–7, 14, 15 are its read path shown as effect.
- **Editing or deleting any existing transaction, adjustment rows included** — UC-09.
  This issue only inserts.
- **`markSettled()` / `setSettled()` / the `settled` columns** — UC-10.
- **A `TransactionDao`.** Does not exist, and must not be created: the diagram's note and
  ISSUE-005 D1 route the write through `AccountDao` (`decisions.md`, log 2026-08-21).
- **Any schema change, migration or snapshot.** The `Transactions` table shipped in
  FEAT01; `schemaVersion` stays 1 (D1).
- **A navigation host, router or account-list screen** — on no class diagram; F8 (D6).
- **Deciding F7** — the unparseable-amount behaviour is the owner's call across three
  screens now (D7).
- **Fixing the stale isolate note on other diagrams** — F3, one per own as-built pass.
- **How UC-01/UC-12 queries classify adjustment rows** — determined by the Q4 answer,
  but their code is theirs.

## Open questions — genuinely non-blocking

- **Reachability (F8).** Until a navigator exists, the adjust flow is exercisable in
  tests but hard to reach in the running app, as with every screen since UC-13. Recorded,
  not solved (D6).
