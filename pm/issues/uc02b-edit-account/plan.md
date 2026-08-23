# UC02B-edit-account — Rename, edit and delete an account

**Status:** DONE 2026-08-24. Was CONFIRMED — Q3 answered (`pm/questions.md`, `context/index/
decisions.md` "Deleting an account is a soft delete"). Written in the main session, not
by `feat-planner`, per the owner's 2026-08-23 direction that planning and diagram work
happen in-session. Every decision below cites an already-confirmed artifact — the
sequence diagram (drawn this session), the class diagram (amended this session), the ERD
(amended this session), or the shipped UC-02/UC-03/UC-10/UC-11 code these artifacts
govern.

**Traces to:** UC-02 (`docs/workbook.xlsx` → `UC FR`, "alternate flows… renaming an
account, changing its details, or deleting it"), FR-18.
**Depends on:** `UC02-add-account` — **DONE**.
**Preflight:** passes. The one declared dependency is Done. **UC03-adjust-account is
being built in parallel by a separate `flutter-coder` dispatch and touches the same three
files** (`account_dao.dart`, `accounts_providers.dart`, `account_form_screen.dart`) —
this is a real scope overlap, so `flutter-coder` for **this** issue must not be dispatched
until UC03's coder run has finished, been reviewed and committed. This is a preflight
condition on *dispatch order*, not on the plan itself.

---

## Goal

The owner can open an existing account, rename it and/or change which of the three
groups it belongs to, or delete it outright — and every one of those actions always
succeeds (NFR-4). Deleting is a **soft delete**: the account row survives with a
`deleted` flag, so every transaction that ever referenced it keeps a real row to resolve
against, and its history stays visible on UC-09's list. This closes FR-18 for `Account` —
the one entity `pm/findings.md` F14 named as create-only until this issue landed.

---

## Scope: the sequence diagram

`CLAUDE.md`: *a plan's scope IS whatever its sequence diagram shows.*
`docs/diagrams/seq-uc02b-edit-account.drawio`, drawn this session (Mermaid → XML per
`sequence-conventions.md`), render committed at
`pm/issues/uc02b-edit-account/seq-uc02b-edit-account.png` and looked at before this plan
was written — no overlaps, the `alt` box encloses exactly messages 9–18, both notes are
legible.

**Twenty messages, one `alt` with two arms, plus two notes:**

| # | From → To | Message |
|---|---|---|
| 1 | Owner → `AccountFormScreen` | opens an existing account to rename, edit its group, or delete it |
| 2 | `AccountFormScreen` → `accountBalancesProvider` | `watch()` |
| 3 | `accountBalancesProvider` → `AccountDao` | `watchBalances()` |
| 4 | `AccountDao` → `AppDatabase` | query accounts + transactions |
| 5 | `AppDatabase` ⇢ `AccountDao` | rows *(reply)* |
| 6 | `AccountDao` ⇢ `accountBalancesProvider` | `Stream<List<AccountBalance>>` *(reply)* |
| 7 | `accountBalancesProvider` → `AccountFormScreen` | `AccountBalance` (current name, group) |
| 8 | Owner → `AccountFormScreen` | edits the name and/or group, or chooses delete |
| **alt** | **[owner saves a rename or group change]** | |
| 9 | `AccountFormScreen` → `AccountsNotifier` | `editAccount(accountId, name, group)` |
| 10 | `AccountsNotifier` → `AccountDao` | `update(accountId, name, group)` |
| 11 | `AccountDao` → `AppDatabase` | update account row |
| 12 | `AppDatabase` ⇢ `AccountDao` | ok *(reply)* |
| 13 | `AccountDao` ⇢ `AccountsNotifier` | ok *(reply)* |
| **else** | **[owner deletes the account]** | |
| 14 | `AccountFormScreen` → `AccountsNotifier` | `deleteAccount(accountId)` |
| 15 | `AccountsNotifier` → `AccountDao` | `delete(accountId)` |
| 16 | `AccountDao` → `AppDatabase` | set `deleted`, `deleted_at` (soft delete) |
| 17 | `AppDatabase` ⇢ `AccountDao` | ok *(reply)* |
| 18 | `AccountDao` ⇢ `AccountsNotifier` | ok *(reply)* |
| 19 | `accountBalancesProvider` → `AccountFormScreen` | `AccountBalance[]` (re-derived) — stream emission |
| 20 | `financialPositionProvider` → `BalanceSheetScreen` | `FinancialPosition` (updated four figures) — stream emission |

Notes: the isolate-boundary note (correct mechanism from the start — `driftDatabase()` →
`createBackgroundConnection`, drawn fresh this session, not carried over stale); and
*"`delete()` is a soft delete — it sets `deleted`/`deleted_at`, never `DELETE FROM
Accounts` (Q3, `decisions.md` 2026-08-23); a deleted account's transactions keep
referencing a real row, so UC-09's list still displays its history."*

**Lifeline check — every lifeline already exists on `class-accounts.drawio`, amended this
session:**

| Lifeline | On `class-accounts.drawio` as | Owned by |
|---|---|---|
| Owner | actor, not a class | — |
| `AccountFormScreen` | *UC-02, UC-02B, UC-03 · ConsumerWidget* | UC-02 (extends, this issue) |
| `AccountsNotifier` | *addAccount() · adjustAccount() · markSettled() · editAccount() · deleteAccount()* | UC-02/UC-03 (extends: `editAccount()` · `deleteAccount()`, **this issue**) |
| `accountBalancesProvider` | `accountBalancesProvider` — *StreamProvider* | UC-01 (reused, unchanged) |
| `AccountDao` | *watchPosition() watchBalances() watchDebtProgress() / insert() update() setSettled() delete()* | UC-02/UC-01/UC-10 (extends: `update()` — listed since UC-01 but never implemented, `delete()` — **this issue**) |
| `AppDatabase` | `AppDatabase` | FEAT01, shipped |
| `financialPositionProvider` | `financialPositionProvider` — *StreamProvider · UC-01* | UC-01 (reused, unchanged) |
| `BalanceSheetScreen` | `BalanceSheetScreen` — *UC-01 · ConsumerWidget* | UC-01 (reused, unchanged) |

No class is invented and none is missing. `update()` was drawn on `AccountDao` from
FEAT01/UC-02's plan onward but never implemented — this is the issue `pm/tracker.yaml`'s
row named as the reason: *"class-accounts.drawio also needs `AccountDao` to gain a
`delete()` — it currently has an `update()` that no diagram calls."* Both are implemented
here.

---

## Decisions

### D1 — Schema change: `Accounts` gains `deleted`/`deleted_at`; `schemaVersion` becomes 2

*Cites:* `context/index/decisions.md` 2026-08-23 "Deleting an account is a soft delete";
`docs/diagrams/erd.drawio` (`Account` table, rows `deleted`/`deleted_at`, amended this
session); `docs/statuses.md` precedent for `settled`/`settled_at` — the identical
two-column shape.

```dart
BoolColumn get deleted => boolean().withDefault(const Constant(false))();
DateTimeColumn get deletedAt => dateTime().nullable()();
```

**This is the project's first schema change since FEAT01.** Follow `drift.md`'s guided
migrations exactly, not a hand-written `onUpgrade` branch: `dart run drift_dev
make-migrations` before the column exists (captures `v1`), add the two columns and bump
`schemaVersion` to `2`, run `make-migrations` again (generates the `v1 → v2` step and the
`v2` snapshot), then run the generated migration tests. Commit both schema snapshots
(`app/drift_schemas/app_database/drift_schema_v1.json` **unchanged**,
`drift_schema_v2.json` **new**) and the generated migration test file — `drift.md`:
*"they are the only artifact that proves a migration preserves data."*

**Not a lifecycle** (`docs/statuses.md`): a one-way flag flipped by exactly one action,
the same reasoning that kept `settled` off the statuses register. No state diagram.

### D2 — `delete()` is unconditional and can never fail — it writes, never removes a row

*Cites:* `context/index/decisions.md` 2026-08-23 (Q3 answered, Option "soft delete/
disable" over cascade/set-null/refuse); NFR-4's zero-refusals fit criterion; the sequence
diagram drawing no confirmation, no guard.

`AccountDao.delete({required int accountId})` is `UPDATE Accounts SET deleted = true,
deleted_at = ? WHERE account_id = ?` (the `Clock`-stamped time, D5) — **never** `DELETE
FROM Accounts`. It cannot violate a foreign key because no row is removed, so it cannot
fail and needs no guard. Deleting an already-deleted account is idempotent — it writes
the same flag again with a fresh timestamp, harmlessly (the diagram draws no state check,
and NFR-4 forbids inventing one).

### D3 — `update()` edits `name` and `group` only — never `opening_amount`

*Cites:* the workbook UC-02 row (*"Correcting the amount an account holds is UC-03"*);
message 9's signature `editAccount(accountId, name, group)`; `enums.md`'s `AccountGroup`
values (unchanged by this issue — no new group, no validation on which groups are
selectable, matching UC-02's "all three always selectable").

`AccountDao.update({required int accountId, required String name, required
AccountGroup group})` is a `TransactionsCompanion`-style targeted write of exactly two
columns. `opening_amount` is never a parameter — UC-03 owns correcting what an account
holds, via a recorded `adjustment` transaction, never a direct field edit (NFR-2's
"recorded, not overwritten" already applies to `opening_amount` the same way it applies
to a derived balance: the entered starting figure is not this issue's to touch).

### D4 — What deleting an account changes in already-shipped queries

*Cites:* `context/index/decisions.md` 2026-08-23, the "Consequences for existing shipped
queries" paragraph — recorded there so this plan can cite rather than re-derive.

- **`AccountDao.watchPosition()`, `watchBalances()`** (UC-01) gain `WHERE NOT deleted`. A
  deleted account stops contributing to FR-1's four figures and stops appearing in the
  balance-sheet list. This is a **behavior change to shipped code**, made here because
  the column does not exist before this issue and the queries are wrong the moment it
  does — not scope creep, and not optional.
- **`watchDebtProgress()` (UC-10) is deliberately NOT filtered** — corrected at review
  from this D4's first draft, which had proposed the same `WHERE NOT deleted` as the two
  above. Unlike those two, which aggregate *across* accounts and simply drop a deleted
  one from the sum, `watchDebtProgress(accountId)` is keyed to one already-selected
  account via `.watchSingle()`, which throws on zero rows. Filtering it would turn "the
  account you're viewing was deleted" into a crash instead of a still-resolvable
  historical figure — the same "history keeps displaying" principle behind the
  `watchAll()` bullet below.
- **`TransactionDao.watchAccounts()`** (UC-04/UC-05's picker, reused by UC-09's edit
  sheet) gains `WHERE NOT deleted` — a deleted account cannot be chosen for a *new* or
  *amended* transaction side.
- **`TransactionDao.watchAll()`** (UC-09's list) is **untouched** — a transaction already
  pointing at a deleted account must keep rendering its stored side name, which is
  exactly why Q3 rejected set-null. `fromName`/`toName` resolve from the `Accounts` row
  regardless of its `deleted` flag; only the picker for *new* selections filters.
- **`BudgetDao`** is untouched — it never references `Accounts`.
- **No un-delete is drawn anywhere.** Reactivating a deleted account is a future
  question if the owner asks for it; this issue does not invent a path for it.

### D5 — The date comes from the injected `Clock`; nothing refused, nothing disabled

*Cites:* **NFR-4**; the sequence diagram drawing no confirmation on either arm of the
`alt`; `pm/findings.md` **F7**; `decisions.md` 2026-08-19 (*inject the clock*) and the
shipped `app/lib/src/budgeting/clock.dart`, already used by UC-10's `setSettled()`.

- Both the save (rename/edit) and the delete controls are **always enabled** — no
  confirmation dialog on delete (the diagram draws none, and NFR-4's zero-refusals
  forbids a "cancel" that quietly becomes a refusal), no disabled state ever.
- An empty name field is legal and saves as `''` — nothing on the diagram or in `enums.md`
  makes a non-empty name a rule, and inventing one here would be inventing a refusal.
- `deletedAt` is stamped from the injected `Clock`, not `DateTime.now()` — the same
  testability rule UC-10 shipped for `settledAt`.

### D6 — Presentation stays on `AccountFormScreen`; the coder's call within bounds

*Cites:* the sequence diagram reusing the `AccountFormScreen` lifeline for messages 1, 7
and 8; `class-accounts.drawio` labelling that screen *UC-02, UC-02B, UC-03*; UC-03 plan
D6, the identical precedent one issue earlier — this screen already branches on whether
`accountId` is given, and now needs a third mode alongside "create" and "adjust".

The screen gains whatever discriminator distinguishes "edit/delete an existing account"
from UC-03's "adjust an existing account's amount" (both take a non-null `accountId`) —
a `mode` parameter, a second constructor, or a separate route are all legitimate; the
diagram fixes the messages, not the widget's internal shape. Bounded by: `opening_amount`
is never editable here (D3), `kind` is not offered (not applicable to this issue), every
control obeys D5.

Reachability is unchanged from every prior screen issue — no navigation host exists on
any class diagram (`pm/findings.md` **F8**); this issue neither builds one nor is blocked
by its absence.

### D7 — `pm/questions.md` Q3, now answered, does not need re-litigating here

Q3 is the reason this issue could not be planned earlier. It is fully answered
(`decisions.md` 2026-08-23) and every consequence of the answer is D1–D4 above. Nothing
in this plan re-opens it.

---

## Steps

1. **Schema migration (D1).** `app/lib/src/accounts/accounts_table.dart`: add `deleted`/
   `deletedAt`. `app_database.dart`: `schemaVersion` → `2`, `MigrationStrategy.onUpgrade`
   via drift's generated step helper. Run `dart run drift_dev make-migrations` before and
   after per D1's sequence. Commit `drift_schema_v1.json` unchanged,
   `drift_schema_v2.json` new, the generated migration test.
2. **`AccountDao`** (`app/lib/src/accounts/account_dao.dart`): add `update({required int
   accountId, required String name, required AccountGroup group})` (D3) and
   `delete({required int accountId})` (D2, soft, `Clock`-stamped `deletedAt`, D5). Add
   `WHERE NOT deleted` to `watchPosition()` and `watchBalances()` only — `not`
   `watchDebtProgress()` (D4, corrected). Update the class's doc comment inventory to
   match (`update()` was previously documented as unimplemented; that sentence is now
   false).
3. **`AccountsNotifier`** (`app/lib/src/accounts/accounts_providers.dart`): add
   `editAccount({required int accountId, required String name, required AccountGroup
   group})` and `deleteAccount({required int accountId})`, forwarding to the DAO and
   returning nothing (messages 9→13, 14→18 — the read path re-emits instead, D6's
   read/write asymmetry precedent).
4. **`TransactionDao.watchAccounts()`** (`app/lib/src/transactions/transaction_dao.dart`):
   add `WHERE NOT deleted` (D4). This is the one file outside `app/lib/src/accounts/`
   this issue touches — declared here so the preflight's file list is complete.
5. **`AccountFormScreen`** (`app/lib/src/accounts/account_form_screen.dart`): the
   edit/delete flow (D6) — rename field, group selector, delete control, all always
   enabled (D5). `opening_amount` field does not appear in this mode (D3).
6. **Tests** under `app/test/accounts/`, per Definition of done below, plus the generated
   migration test from step 1.
7. Run the four commands from `app/`. Verify the migration test passes and both schema
   snapshots are committed.
8. Close per `CLAUDE.md`'s checklist:
   - **As-built pass on `seq-uc02b-edit-account.drawio`** — drawn correctly from the
     start this session (current isolate note, no read-path gaps to fill), so this step
     is a confirmation pass, not a fix: re-check the render still matches the shipped
     code's exact method names and signatures; refresh `renders.lock` only if the
     `.drawio` changed.
   - **`pm/findings.md` F8** — `AccountFormScreen`'s edit/delete mode is not a new
     screen, so it does not add a new orphan by itself; note this explicitly rather than
     leaving F8 silent about it.
   - **`pm/findings.md` F14** — mark it resolved: `Account` is no longer create-only,
     FR-18 is now satisfied for every entity.
   - **`pm/tracker.yaml`** → Done plus a one-line summary.
   - **`context/index/map.yaml`** → `UC-02B → app/lib/src/accounts/` entry (the
     class-diagram/ERD `ucs` lists gain `UC-02B` where this session did not already add
     it at plan time — check both).
   - **`docs/workbook.xlsx`** — F5 stands (no column to mark implemented in); the
     tracker remains the real register.
   - **`pm/log.md`** dated entry + current-state block refresh; **`pm/active.json`** →
     next (nothing runnable — this and UC03 close out the backlog).

---

## Definition of done

*Cites:* the same four commands every prior code issue has run, headless, from `app/`.

1. `dart run build_runner build` — succeeds.
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean.
4. `flutter test` — green, `NativeDatabase.memory()`.

Plus: `drift_schema_v1.json` byte-identical to before this issue; `drift_schema_v2.json`
present and generated (not hand-written); the generated migration test passes.

**Tests:**

- **DAO, D3** — `update()` changes `name`/`group` and leaves `opening_amount` untouched.
- **DAO, D2** — `delete()` sets `deleted = true` and a `Clock`-stamped `deletedAt`; the
  row still exists (`SELECT` by id still returns it).
- **DAO, D2** — deleting an already-deleted account is idempotent, no error.
- **DAO, D4** — after deleting an account with existing transactions,
  `watchPosition()`/`watchBalances()` no longer include it, but a direct query for the
  transaction rows still resolves `from_account_id`/`to_account_id` to the (deleted)
  account. This is FR-18's "delete" proven not to be a `DELETE FROM Accounts` in
  disguise.
- **DAO, D4** — `TransactionDao.watchAccounts()` excludes a deleted account from its
  results.
- **Migration** — the generated `v1 → v2` migration test, run and green (proves the
  upgrade path over real data, not just a fresh `v2` database).
- **Widget, NFR-4 (D5)** — the delete control is enabled with no confirmation dialog, and
  tapping it performs the deletion immediately.
- **Widget, D3** — the edit form has no `opening_amount` field.

---

## Out of scope

- **Correcting `opening_amount`** — UC-03's `adjustAccount()`, unchanged by this issue.
- **Un-deleting an account** — not drawn anywhere; a future question if raised (D4).
- **A navigation host** — F8, owner's standing question, not this issue's to solve (D6).
- **Deleting or editing a transaction** — UC-09, already shipped.
- **Any change to `Categories`, `Subcategories`, `BudgetGroups`, `BudgetPeriods`, or
  `Settings`** — this issue touches only `Accounts` and the one `WHERE NOT deleted`
  clause on `TransactionDao.watchAccounts()` (D4, step 4).
- **Changing which three groups exist, or how `AccountGroup` is stored** — unrelated to
  Q3/Q4, `enums.md` unchanged.

## Open questions

None. Q3 is answered and every consequence is D1–D4 above.
