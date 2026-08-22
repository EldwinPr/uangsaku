# Questions

**The unattended run's halt queue.** When `feat-planner` hits a decision it cannot derive
from an already-confirmed artifact, it halts that issue and appends the question here
rather than choosing a default.

Append-only. Newest at the bottom. The owner answers, the answer goes to its **canonical
home** (`docs/fr-nfr.md` §4 for requirements, `context/index/decisions.md` for design),
and the entry here is marked ANSWERED with a pointer. This file is a queue, not a record —
`lessons.md` §1 is the reason the answer must land somewhere permanent as well: *a decision
is not finished until every register that listed it as open is updated.*

## What belongs here

A question **only** if proceeding would mean choosing something the owner has not already
decided. Before writing one, check that the answer is not already in:

- `docs/fr-nfr.md` — the requirements and their §4 open register
- `context/index/decisions.md` — every durable design decision, with reasoning
- `docs/enums.md` / `docs/statuses.md` — the legal values
- The use case's own sequence diagram and its module's class diagram
- `docs/workbook.xlsx` — the owning row's `Deskripsi`, `Input`, `Output`

**If a question can be answered by reading one of those, it is not a question — it is
research that was not done.** Halting is expensive: it blocks every dependent issue.

## What does not belong here

- Anything the sequence diagram already answers. The diagram **is** the scope.
- A naming preference with no downstream consequence. Follow the class diagram; if it is
  silent, follow the existing code's convention.
- A question about how to implement something already decided. That is
  `context/coding-conventions/`.

## Format

```
## Q{N} — {one-line question}          [OPEN | ANSWERED]
**Raised by:** {issue id}, {date}      **Blocks:** {issue ids, transitively}
**Why it cannot be derived:** which artifacts were checked and what each failed to say.
**Options, if any are visible:** with the cost of each — never a recommendation dressed
as the only path.
**Answer:** {owner's words} — recorded at {canonical home}.
```

Name the transitive blast radius, not just the direct dependent. When UC-13's missing
classes were open, the honest count was **four** issues downstream, not one — and that
number is what tells the owner how urgent an answer is.

---

*No open questions. Both items that stood here on 2026-08-21 — UC-13's budget group CRUD
and whether `note` appears on the transfer / lend-borrow / repayment screens — were
answered by the owner before the run began and are recorded in `context/index/decisions.md`.*

---

## Q1 — What makes the currency-change warning fire?          [ANSWERED]

**Raised by:** UC14-choose-currency, 2026-08-21
**Blocks:** UC14-choose-currency directly, and **seven issues transitively** — UC02-add-account,
then UC03-adjust-account, UC01-balance-sheet and UC10-debt-progress behind it, then
UC04-record-money-movement, then UC09-review-and-correct and UC12-budget-consumption. That is
eight of the eleven implementation rows. The other chain (UC13-categories, UC11-set-budget) is
unaffected and can still run.

`seq-uc14-choose-currency.drawio` guards its `opt` fragment (message 9, the warning) on
**[[an existing currency is being changed, not initial setup]]**. Nothing says how code
decides that, and the schema cannot express it.

**Why it cannot be derived:**

- `docs/fr-nfr.md` **FR-19** splits "chosen at setup" from "*I can change it later, and the app
  will not stop me*", and puts the warning at *"the moment I would cause it"* — the moment
  amounts would be re-labelled. It does not say how the app recognises that moment.
- The **workbook UC-14 row** repeats the same split — *"at first setup or any time after"* —
  and defines neither side.
- `docs/enums.md` and `docs/diagrams/class-settings.drawio` both say the change re-labels and
  the app warns and proceeds. Neither gives a trigger.
- `docs/diagrams/erd.drawio` and the built table (`app/lib/src/settings/settings_table.dart`):
  `Settings` is exactly `settings_id` + `currency`. **No "setup complete" marker, no
  timestamp** — the distinction the guard names is not readable from the database.
- `FEAT01` D6 seeds one `Settings` row at `Currency.IDR` on a fresh database, so a currency
  value exists from first launch. Read literally, "an existing currency is being changed" is
  true every time, and the guard's carve-out has nothing to attach to.
- `context/index/decisions.md` (2026-08-20, one app-level currency) and `docs/statuses.md`
  (no status values, deliberately) do not address it.
- NFR-4 does not choose either: all three options below warn and proceed, none refuses.

**Options, with their cost:**

- **A — warn when the chosen value differs from the stored one.** Free; the screen already
  holds the current value from message 7. Costs one wrong warning at first setup if the owner
  picks USD over the IDR seed — the exact case the guard says should *not* warn.
- **B — warn when any amount exists in the database.** Truthful to the warning's own wording.
  Costs `SettingsDao` a count over `Transactions` / `Accounts` / `BudgetPeriods`. That
  cross-module join is permitted (ISSUE-005 D1) but is **not drawn on this sequence diagram**,
  so choosing it widens the scope boundary `CLAUDE.md` makes absolute — the diagram would need
  a message added and re-rendered.
- **C — always warn on any selection.** Simplest. Drops the guard, i.e. skips part of the
  diagram, which `CLAUDE.md` forbids without this ruling.
- **D — add a "setup complete" column to `Settings`.** Makes the guard literally true, and
  costs `schemaVersion` 2, a new snapshot and migration, plus the ERD, `class-settings.drawio`
  and `map.yaml` going stale with it. `lessons.md` §8: the last "just one column" cost twelve
  artifacts. Raised before the work, not after.

**Answer:** *"for q1 by change currency it just changes the prefix thats all"* — the owner,
2026-08-22. Recorded at `context/index/decisions.md` (2026-08-22, "Changing the currency
changes the prefix and nothing else").

**What it settles, and how the guard resolves.** The answer is about *what changing the
currency does*, and it dissolves the question rather than picking from the menu above.
Changing the currency re-labels: the stored `int` minor units are untouched, nothing is
converted, no other table is read or written, and no exponent arithmetic runs. Under that:

- **D is rejected** — a "setup complete" column would buy a distinction that changes nothing,
  at the cost of `schemaVersion` 2 and the artifacts `lessons.md` §8 predicts.
- **B is rejected** — counting amounts across three modules to decide the wording of a
  message about a prefix is a cross-module join bought for nothing, and it is not drawn on
  the diagram.
- **A is what the guard becomes:** the notice appears when the chosen currency differs from
  the stored one, which is exactly when the prefix changes. **A's only stated cost was a
  "wrong" warning at first setup if the owner picks USD over the IDR seed — the owner's
  answer removes it**, because in that case the prefix really does change and saying so is
  true, not spurious. The guard's "not initial setup" carve-out was written when the change
  was imagined to be consequential; it has no referent once the change is a prefix.

So `opt [the chosen currency differs from the stored one]`. **The diagram's guard text is
corrected at UC-14's as-built pass**, not silently reinterpreted — the fragment stays, one
message stays inside it, and nothing is skipped.

---

## Q2 — Does UC-02 build renaming, editing and deleting an account — and what happens to the transactions of a deleted account?          [ANSWERED]

**Raised by:** UC02-add-account, 2026-08-22
**Blocks:** UC02-add-account directly, and **six issues transitively** —
`UC03-adjust-account`, `UC01-balance-sheet` and `UC10-debt-progress` behind it, then
`UC04-record-money-movement`, then `UC09-review-and-correct` and `UC12-budget-consumption`.
That is **the entire remaining backlog**: the other chain (UC13, UC11, UC14) is already
Done, so unlike Q1 there is nothing else the run can continue on.

Two confirmed artifacts disagree about UC-02's scope, and a stated requirement sides with
one of them.

- **`docs/workbook.xlsx`, UC-02 `Deskripsi`, verbatim:** *"Alternate flows: renaming an
  account, changing its details, or deleting it are alternate flows of this use case, not
  separate use cases (owner's decision, 2026-08-19: only transactions get their own
  correction use case). Correcting the amount an account holds is UC-03."*
- **`docs/diagrams/seq-uc02-add-account.drawio`** draws create and nothing else — eight
  messages, one flow, no `alt` and no `opt`. `CLAUDE.md` makes that diagram the scope.

**Why it cannot be derived:**

- **`docs/fr-nfr.md` FR-18** — *"Full CRUD across transactions, accounts, budgets,
  categories and subcategories, people, and debts. No entity is create-only, and **no
  entity has an exception**."* This sides with the workbook, and sharply: on the
  diagram-is-the-scope reading, `Account` becomes the one entity in the project that no
  issue ever gives update or delete.
- **Every sequence diagram in `docs/diagrams/` was checked.** None draws an account
  rename, edit or delete. `seq-uc03` writes an `adjustment` **transaction**, not an account
  update; `seq-uc10` calls `setSettled()`. `seq-uc11` and `seq-uc13` *do* draw rename and
  delete for their own entities, so the project's convention is that this gets drawn when
  it is in scope — which makes its absence here readable either way: an omission, or a
  boundary.
- **`docs/diagrams/class-accounts.drawio`** gives `AccountDao` an `update()` that no
  sequence diagram calls, and gives it **no `delete()` at all**. So the class diagram
  half-anticipates the answer and cannot supply it.
- **`context/index/decisions.md`**, **`docs/enums.md`**, **`docs/statuses.md`** — silent.
  `statuses.md` deliberately lists no values for any entity, so nothing gates a delete.
- **NFR-4 does not choose between the two, but it does forbid one implementation.**
  `Transactions.fromAccountId` and `toAccountId` reference `Accounts` with **no
  `onDelete`** (`app/lib/src/transactions/transactions_table.dart`), so SQLite's default
  `NO ACTION` makes deleting a referenced account **fail**. A failure is a refusal, and
  NFR-4's fit criterion is *zero* refusals. **So "add a delete button" is not a one-line
  answer** — it forces a second ruling about what happens to those transactions.
- **UC-11's precedent does not transfer.** Deleting a budget group nulls `budget_group_id`
  so the money reappears under Others (FR-17). `budget_group_id` is an optional tag;
  `from_account_id` / `to_account_id` are the transaction's identity, and a transaction
  with neither side is not a record of anything.

**Why it cannot wait until after UC-02 ships:** it changes the deliverable
(`AccountFormScreen` is a create-only form or a create/edit/delete one), it adds methods to
`AccountsNotifier` and a `delete()` that is on no class diagram, and every non-refusing
delete is a **schema change** — `ON DELETE SET NULL` or `CASCADE` both alter the table,
which means `schemaVersion` 2, a migration and a new `drift_schemas/` snapshot.
`lessons.md` §8 is the cost estimate. Answering later means reopening a Done issue, which
`pm/findings.md` opens by warning against.

**Options, with their cost:**

- **A — UC-02 is create-only; account update/delete becomes its own tracked issue** with
  its own sequence diagram, before FR-18 can be called satisfied. Cost: UC-02 unblocks
  immediately at three files and no schema change; FR-18 stays visibly unsatisfied for
  `Account` until that issue lands, and the workbook's UC-02 `Deskripsi` needs correcting
  so it stops promising flows UC-02 does not deliver.
- **B — UC-02 carries the alternate flows, as the workbook says.** Cost: the sequence
  diagram must be redrawn with them (a diagram edit before coding, which the main session
  owns), `class-accounts.drawio` gains `AccountDao.delete()`, and the delete question below
  must be answered in the same breath — so UC-02 becomes a schema-migration issue, not the
  no-schema-change issue every use-case issue since FEAT01 has been.
- **C — rename and edit are in, delete is out for now.** Cost: cheapest of the three
  (renaming touches no FK and needs no migration) and it is a partial FR-18 exception,
  which FR-18 says by name it does not have.

**And, whichever of the above:** if an account can be deleted, what happens to a
transaction that references it — the reference is nulled, the transactions are deleted with
it, or something else? Each is a different migration, and doing nothing is a refusal.

**Answer:** *(pending)*

**Answer (Q2):** **Option A — UC-02 is create-only; account update/delete becomes its own
tracked issue.** Owner's ruling, 2026-08-22, choosing from the options above. Recorded at
`context/index/decisions.md` (2026-08-22, "Account CRUD splits from UC-02").

**What it settles.** UC-02 builds exactly what `seq-uc02-add-account.drawio` draws — create,
eight messages, no `alt`. **The schema does not change**: `schemaVersion` stays 1, no
migration, no new snapshot. UC-03, UC-01, UC-10, UC-04, UC-09 and UC-12 all unblock
immediately.

**What it defers, deliberately and on the record.** `UC02B-edit-account` is added to
`pm/tracker.yaml` as TODO with a NOT PLANNED placeholder. It needs its own sequence diagram
before it can be planned, and it carries the second half of this question — **what happens to
the transactions of a deleted account** — which is still unanswered and is not UC-02's to
answer. `from_account_id`/`to_account_id` are a transaction's identity, not an optional tag,
so UC-11's null-the-tag precedent does not transfer.

**The cost the owner accepted:** **FR-18 is not satisfied for `Account` until that issue
lands**, and `Account` is until then the one entity in the project that is create-only. That
is a known gap on the record rather than an accident, and it is filed as `pm/findings.md`
**F14** so it cannot be mistaken for an oversight when the backlog next looks complete.

---

## Q3 — What happens to the transactions of a deleted account?          [OPEN]

**Raised by:** UC02B-edit-account, 2026-08-22 (deferred here by the Q2 ruling, which
recorded that the question "is not UC-02's to answer")
**Blocks:** UC02B-edit-account directly. Nothing else depends on it — UC03, UC01 and UC10
are runnable behind it — but FR-18 stays unsatisfied for `Account` while it stands (F14),
and UC02B is the issue that discharges that gap.

`UC02B-edit-account` cannot be planned, and its sequence diagram cannot even be drawn,
until this is answered: every non-refusing delete is a schema change, and which schema
change it is decides what the delete flow looks like.

**Why it cannot be derived:**

- **The shipped schema refuses deletes outright.** `Transactions.from_account_id` and
  `to_account_id` reference `Accounts` with no `onDelete`
  (`app/lib/src/transactions/transactions_table.dart`), so SQLite's default `NO ACTION`
  makes deleting a referenced account FAIL. A failure is a refusal; NFR-4's fit criterion
  is *zero* refusals. So "just add a delete button" is not on the menu.
- **Every escape is a migration.** `ON DELETE SET NULL`, `ON DELETE CASCADE`, or a
  hand-written pre-delete all alter the table or its constraints: `schemaVersion 2`, a
  migration, a new `drift_schemas/` snapshot (`lessons.md` §8 is the cost estimate for
  anything schema-shaped).
- **UC-11's precedent does not transfer** (`decisions.md` 2026-08-22): deleting a budget
  group nulls `budget_group_id` because that column is an optional *tag*. A transaction's
  from/to account is its *identity* — a transaction with neither side records nothing.
- `docs/statuses.md` lists no status values, so nothing gates a delete; `docs/enums.md`,
  FR-18 and the workbook are silent on the data consequence.

**Options, with their cost:**

- **A — CASCADE: deleting an account deletes its transactions.** The money history goes
  with the account. No null states to interpret; FR-1's figures stay correct. Cost:
  irreversible data loss from one tap in an app whose data cannot be regenerated.
- **B — SET NULL: the transactions survive without an account side.** Cost: a transaction
  row whose from/to is NULL contradicts the ERD's identity argument above, and every
  balance query has to decide what such a row contributes.
- **C — refuse the delete while transactions exist** (a guardrail). Cheapest — no
  migration at all — but it is a refusal, which NFR-4 forbids by name ("no exceptions"),
  so choosing C means amending NFR-4 as well.
- **D — something else the owner names.** The options above are shapes, not a menu that
  closes the space.
