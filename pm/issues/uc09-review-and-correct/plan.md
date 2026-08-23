# UC09-review-and-correct — Review and correct what was recorded

**Status:** DONE 2026-08-23. Was AUTO-CONFIRMED (unattended mode, 2026-08-23). Every
D-entry below cites an artifact the owner has already confirmed — the sequence diagram,
the module class diagram, `docs/enums.md`, `docs/fr-nfr.md`, the workbook row,
`context/index/decisions.md`, or the shipped code those artifacts govern. Nothing here is
a new choice; the two OPEN questions in `pm/questions.md` are shown not to block (D6).

**Traces to:** UC-09 (`docs/workbook.xlsx` → UC FR, "Correct or Delete a Transaction")
**Depends on:** UC04-record-money-movement — **DONE** in `pm/tracker.yaml`. **Preflight
passes**: dependency satisfied; no scope overlap with any active issue (UC02B-edit-account
and UC03-adjust-account are HALTED and own account edit/delete and adjustment creation,
none of which appears on this issue's diagram).

## Goal

After this issue, the owner can open a list of everything ever recorded, pick any row on
it, and either amend its amount, account(s), date, category, subcategory, budget group
and note, or remove it outright — with every downstream figure (account amounts,
balance-sheet totals, budget consumption) re-deriving on their own screens' streams
because nothing was stored to fix up (NFR-2).

This closes FR-18 for `Transaction` — the one entity the owner gave a dedicated
correction use case (workbook UC-09 Deskripsi; `fr-nfr.md` §5 "Where FR-18 landed").
It delivers the last two unwritten methods the class diagram gives `TransactionDao`
(`update()` / `delete()` were named there from the start; UC04 shipped only `insert()`
and the two picker reads) and the first consumer of `watchAll()`.

## Scope — the sequence diagram

`docs/diagrams/seq-uc09-review-and-correct.drawio` is the scope (committed render in
this issue directory). Twelve messages, six lifelines, mapped to real classes — every
name verbatim from `docs/diagrams/class-transactions.drawio`:

| Lifeline | Class | File |
|---|---|---|
| Owner | actor | — |
| TransactionListScreen | `TransactionListScreen`, ConsumerWidget — **new** | `app/lib/src/transactions/transaction_list_screen.dart` |
| transactionListProvider | `transactionListProvider` — **new** | `app/lib/src/transactions/transactions_providers.dart` |
| TransactionsNotifier | `TransactionsNotifier` — **exists** (UC04); gains `edit()` / `delete()` | `app/lib/src/transactions/transactions_providers.dart` |
| TransactionDao | `TransactionDao` — **exists** (UC04); gains `watchAll()` / `update()` / `delete()` | `app/lib/src/transactions/transaction_dao.dart` |
| AppDatabase | `AppDatabase` — exists | `app/lib/src/database/app_database.dart` |

No new class is invented; every box above is already on the class diagram, which is why
no class-diagram change is proposed. The diagram's structure: open list (1), first
emission (2), select a row (3), then one `alt` with two arms — **amend** (4–7:
`edit(...)` → `update(id, fields)` → database, "row updated") or **delete** (8–11:
`delete(id)` → database, "row deleted") — then the re-derived emission (12).

## Decisions

### D1 — Scope is the diagram's twelve messages and nothing else

Messages 1–12 above. The diagram's three notes are part of the scope and bind the
implementation: the isolate-boundary note (corrected at as-built, step 7), the note that
the free-text **note field is editable like any other field but searching notes is not
in this use case**, and the note that account amounts, balance-sheet totals and budget
consumption **re-derive on their own screens' streams — out of scope here**. *(Source:
seq-uc09 messages 1–12 and notes 0–2; CLAUDE.md's diagram-is-scope gate.)*

### D2 — The read path: one stream, one hand-written `StreamProvider.autoDispose`

`transactionListProvider` wraps exactly one drift stream, `TransactionDao.watchAll()`:

- **`StreamProvider`, not a Notifier**: the class diagram types
  `transactionListProvider` as *"StreamProvider · UC-09"* and names `watchAll()` on
  `TransactionDao`. *(class-transactions.drawio)*
- **Single-stream, so the UC-11 ruling is not triggered**: `decisions.md` 2026-08-22
  bans combining shapes for screens reading **more than one** stream; this screen reads
  exactly one (the diagram draws one subscription feeding messages 2 and 12). A plain
  `Notifier` with hand-opened subscriptions is unnecessary machinery here.
- **Hand-written, not `@riverpod`**: `riverpod_generator` throws `InvalidTypeException`
  on any provider typed over a drift row class, and it would name the provider itself
  rather than the class diagram's `transactionListProvider`. Both rulings are on file
  from UC-13/UC-14 and are the standing exception for every read provider in this app.
  *(decisions.md 2026-08-21, UC-13 ruling 2; shipped `transactions_providers.dart`.)*

The diagram omits the two subscription calls themselves (Screen→provider `watch()`,
provider→DAO `watchAll()`); per the project's settled as-built practice they are added
to the diagram at close, as UC10/UC11/UC13 did for theirs — an emission (msg 2)
presupposes a subscription, so this adds nothing the diagram does not already imply.
*(Step 7; precedent recorded in the UC10/UC13 tracker summaries and findings F3's
history.)*

### D3 — What the list shows, and how account names arrive

Each row renders what the ledger row carries — kind, amount, date, category /
subcategory / budget-group tags, note — plus the **names** of its account side(s),
resolved by a join **inside `TransactionDao`** (a watched custom select joining
`Accounts`), never by calling `AccountDao` or stitching in Dart. This is the exact shape
ISSUE-005 D1 mandates for cross-module reads and that `AccountDao.watchBalances()` /
`watchDebtProgress()` already ship; the join lives in the module that owns
`Transactions`. *(decisions.md 2026-08-20, "Modules reach each other's data by SQL
join"; UC01/UC10 shipped precedents.)*

Ordering follows the existing code convention, since no artifact fixes a display order
and `pm/questions.md` excludes presentation preferences with no downstream consequence:
deterministic ascending `(occurredOn, transactionId)` — the same
order-for-determinism rationale already documented on `watchAccounts()` /
`watchBudgetGroups()` / `watchBalances()`. *(shipped `transaction_dao.dart` doc
comments; general-rules.md "explicit written rule outranks in-the-moment reasoning".)*

An **empty list is an empty list**, not an error state; loading renders a placeholder,
matching every shipped screen. An adjustment row displays whichever side its encoding
set (see D6) — the list reads columns, it does not interpret kinds.

### D4 — The amend arm: `edit()` verbatim, kind fixed, sides per `enums.md`

Message 4's signature is implemented exactly as drawn:
`edit(id, amount, account, date, category, subcategory, budgetGroup, note)` — forwarded
as `update(id, fields)` (msg 5), a `TransactionsCompanion` write of precisely those
fields. Three readings, each citable:

- **`kind` is not a parameter, so an existing row's kind never changes here.** The
  diagram omits it and the workbook's field list ("amount, account, date, category,
  subcategory, budget group") omits it. Retagging a row to a different kind is out of
  scope (see Out of scope). *(seq-uc09 msg 4; workbook UC-09 Deskripsi.)*
- **"account" denotes the account field(s) the row's kind actually occupies, per
  `docs/enums.md`'s kind table** — one side for expense/income/lend/borrow, both sides
  for transfer/repayment, whichever-is-set for adjustment. The `alt` guard applies the
  arm to *any* kind, so the singular noun compresses the per-kind presentation; writing
  only one side of a two-sided row would leave it contradicting `enums.md`'s table,
  which fixes **both** sides for every kind. Kind being fixed (point above) is what
  makes the mapping well-defined: the sides being edited are exactly those the table
  assigns to the row as it stands. *(seq-uc09 alt guard; docs/enums.md `Transaction.kind`
  table; workbook Deskripsi.)*
- **Blanks become nulls**, keeping "cleared" and "was never set" one fact — the
  convention UC04 shipped on the record form and the reason the nullable columns exist.
  *(shipped `record_transaction_screen.dart` D8 convention.)*

The amend surface is presented from `TransactionListScreen` (message 4 leaves it), not
from a new screen — the class diagram has no edit-screen box, and naming one would be
inventing a class. Whether that surface reuses `RecordTransactionScreen`'s widgets or
is a sheet/dialog inside the list screen is the coder's presentation call, bounded by:
kind is not offered as a choice, and every control obeys D7. *(class-transactions.drawio
screen band; seq-uc09 lifelines.)*

### D5 — The delete arm: unconditional, no confirmation dialog, no migration

`delete(id)` (msgs 8–11) runs **immediately and unconditionally**. There is no
confirmation step whose "no" could quietly become a refusal, no disabled state, no
guard:

- **The diagram draws none.** Messages 8–11 follow message 3 directly, with no `opt`
  fragment and no notice message. This project draws warnings when it means them —
  `seq-uc14` renders its currency-change notice as an explicit message. Absence here is
  therefore a boundary, not an omission. *(seq-uc09 vs seq-uc14; CLAUDE.md's
  nothing-skipped-nothing-added gate.)*
- **NFR-4 makes it mandatory besides**: the fit criterion is *zero* refusals, and a
  delete flow that can end in "cancelled" is the likeliest quiet violation the tracker
  row warns about. Deleting your own record is exactly the "tidying your own records is
  the owner's business" ruling. *(docs/fr-nfr.md NFR-4; decisions.md 2026-08-19 "The app
  assists, it does not police".)*
- **It can never fail on a foreign key, so no migration is needed and `schemaVersion`
  stays 1.** Verified against the shipped tables: `Transactions` references `Accounts`,
  `Categories`, `Subcategories` and `BudgetGroups`; **no table references
  `Transactions`** (`grep` for `references(Transactions` returns nothing across
  `app/lib/src`). Contrast the account-delete case (Q3/F14), where the direction is
  reversed and the failure mode is real. *(app/lib/src/transactions/
  transactions_table.dart, accounts_table.dart, budgeting_table.dart — checked
  2026-08-23.)*

### D6 — The two OPEN questions do not block this issue, cited through

Checked explicitly, per the run brief:

- **Q4 (adjustment side/sign encoding) — not needed.** This issue creates no adjustment
  (that is HALTED UC03's insert path) and re-encodes none: edit writes fields exactly as
  handed over (D4) and the list displays whichever sides a row carries (D3). Behaviour
  here is **identical under Q4's option A and option B**, the same property that let
  UC01 and UC10 proceed, pinned there by dual-encoding tests. No stored row is
  interpreted or migrated by this issue. *(pm/questions.md Q4; UC01/UC10 tracker
  summaries.)*
- **Q3 (transactions of a deleted account) — not touched.** UC09 deletes
  *transactions*; it never deletes or nulls an *account*. The FK direction that makes Q3
  expensive (accounts referenced BY transactions) is irrelevant to deleting a
  transaction row (D5). *(pm/questions.md Q3; transactions_table.dart.)*

So the issue proceeds while both questions stay OPEN; neither answer can force a rewrite
here, because nothing in `watchAll()` / `update()` / `delete()` branches on kind or sign.

### D7 — NFR-4 checked explicitly, and tested, not assumed

Every consequential control on this issue — the delete affordance, the amend/save
affordance — is **always enabled**; empty picker pools leave nulls and proceed, exactly
as the record form ships; an unparseable amount proceeds as 0 (F7 precedent) rather than
blocking the save. No dialog, snackbar-or-else, or state anywhere on this screen ends a
user action without having performed it. *(NFR-4 fit criterion; shipped
RecordTransactionScreen behaviour.)*

Per ISSUE-009's coding-conventions requirement, the two named requirements get explicit
tests in this issue: **FR-18's full CRUD** (insert via UC04's path, read on the list
stream, edit round-trips into the next emission, delete removes the row) and **NFR-4's
zero refusals** (delete and edit proceed under empty pickers, zero amounts and
already-blank tags; a widget test asserts the delete control is enabled and performs the
deletion with no gate). *(tracker ISSUE-009 summary; context/coding-conventions/.)*

### D8 — Reachability: F8's seventh orphan, honestly

No navigation host exists in the app and none appears on any class diagram, so
`TransactionListScreen` ships the way every screen issue before it did: exercised by its
tests, possibly unreachable at runtime. `home` stays `BalanceSheetScreen` **permanently**
(FR-1, UC01's ruling — this issue does not re-point it, breaking the F8 chain's
re-pointing pattern deliberately). Whether a navigation host becomes its own issue
remains the owner's open call (findings F8); this issue does not invent one. *(F8;
UC01 summary "home is BalanceSheetScreen permanently"; UC04/UC10 shipped-orphan
precedents.)*

### D9 — Registers this issue updates at close (so the decision is finished)

Beyond the standard close checklist: **map.yaml** gains the UC-09 entry (dao/providers/
screen/tests paths as in D-scope table); **seq-uc09** gets its as-built pass (step 7);
and **two stale passages are corrected**, found while planning: `fr-nfr.md` §4's
note-decision entry still says "*searching notes is UC-09's surface*", and
`transactions_table.dart`'s `note` doc comment repeats it — while this use case's own
diagram says searching notes is *not* in it and `fr-nfr.md` §3 keeps
searching/filtering deliberately-not-now. The diagram wins; both passages stop promising
UC-09 something its scope excludes. *(lessons.md §1 — a register that listed it as
included must stop doing so; seq-uc09 note 1.)*

## Steps

1. `TransactionDao.watchAll()` — watched custom select over `Transactions` joined to
   `Accounts` for both side names (D3), ordered `(occurredOn, transactionId)`
   ascending. Plain-class DAO shape (never a `DatabaseAccessor` — decisions.md
   2026-08-21, UC-13 ruling 1). Test in `app/test/transactions/transaction_dao_test.dart`.
2. `TransactionDao.update({required int id, ...fields})` and
   `TransactionDao.delete({required int id})` — companion write of exactly D4's fields;
   delete by primary key, unconditional (D5). Both return `Future<void>`; no result
   reaches any screen. Tests: update round-trip; delete of an existing row; **delete of
   a row referencing now-absent tag ids succeeds** (FK direction proof, D5).
3. `transactionListProvider` in `transactions_providers.dart` — hand-written
   `StreamProvider.autoDispose<List<...>>` over `watchAll()` (D2).
4. `TransactionsNotifier.edit({...})` / `.delete(id)` — forwarding methods returning
   nothing (the changed list arrives as stream re-emission, msg 12). The class diagram's
   method inventory (`edit() · delete()`) is now fully implemented.
5. `TransactionListScreen` in `app/lib/src/transactions/transaction_list_screen.dart` —
   watches `transactionListProvider`; renders rows per D3; selection opens the amend
   surface (kind fixed, sides per the row's kind, blanks-to-null) and the delete
   affordance per D5/D7. Loading/empty states as on every shipped screen.
6. Widget + notifier tests per D7: FR-18 CRUD round-trip through the stream; zero
   refusals (enabled controls, no gate, delete performs); empty-pool edit proceeds.
7. Run `dart run build_runner build --delete-conflicting-outputs` (if generation is
   needed), `dart format --set-exit-if-changed .`, `flutter analyze`,
   `flutter test` — all green before commit.
8. **As-built pass on `seq-uc09-review-and-correct.drawio`**: add the two read-path
   subscription messages (Screen→provider, provider→DAO) per D2; correct the isolate
   note to the FEAT01-ruling-2 mechanism (`driftDatabase()` →
   `createBackgroundConnection`) per F3; export to PNG and **look at the render**
   (lessons §3); commit alongside the corrected `renders.lock`.
9. Close per CLAUDE.md's checklist, including D9's register updates: map.yaml UC-09
   entry; the two stale "searching notes is UC-09's surface" passages corrected;
   workbook UC-09 row marked implemented; `pm/tracker.yaml` → DONE with summary;
   `pm/log.md` dated entry; F3 narrowed by one; F8's orphan count updated.

## Out of scope

- **Searching or filtering the list** (including note search) — excluded by the
  diagram's own note and `fr-nfr.md` §3's deliberate deferral; the stale passages
  promising it are *corrected*, not implemented (D9).
- **Changing a transaction's kind** — not a parameter of message 4 (D4); retagging a
  row across kinds is drawn nowhere.
- **Creating adjustments** — UC03's write path, HALTED pending Q4.
- **Any account create/rename/edit/delete** — HALTED UC02B, pending Q3; this issue
  neither causes nor fixes that gap (FR-18 stays unsatisfied for `Account` until then,
  per F14).
- **Re-derivation of account amounts, balance-sheet totals or budget consumption** —
  arrives on their own screens' streams by NFR-2; the diagram notes it out of scope.
- **A navigation host / making the screen reachable at runtime** — F8, owner's call.
- **Schema changes of any kind** — nothing references `Transactions` (D5);
  `schemaVersion` stays 1 and `drift_schema_v1.json` must remain byte-identical.
- **Pagination, indexes, query tuning** — nothing measured slow yet (NFR-2's own
  condition).
- **Editing `Budget_Group` or `Budget_Period` rows** — UC-11's shipped group CRUD and
  period forms; the list only *displays* a row's group tag.

## Open questions

None. The two candidates were checked and cited through (D6); nothing else in this
issue forced a choice that `fr-nfr.md`, `enums.md`, the sequence diagram, the class
diagram, the workbook row or `decisions.md` does not already answer.
