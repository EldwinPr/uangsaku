# UC11-set-budget — Set a monthly budget amount

**Status:** DONE 2026-08-22 — built, reviewed, closed and committed. The as-built pass
redrew `seq-uc11-set-budget.drawio` (five corrections, listed in `pm/log.md`) and removed
the phantom `BudgetNotifier → Clock` edge from `class-budgeting.drawio`; both renders were
re-exported and inspected.

Planned as AUTO-CONFIRMED 2026-08-22, under the unattended-mode rule in
`context/general-rules.md` (§Planning gate) and `context/index/decisions.md`
(2026-08-21, "The planning gate gets an unattended mode"). Every decision below cites the
already-confirmed artifact it is transcribed from. **Nothing here is a new choice** — the
four places where one could have been made (what FR-15's pre-fill means on disk, what a
month is on disk, what happens to a budget group's periods and to the transactions tagged
with it when the group is deleted, and which screen `app.dart` shows) are each argued down
to a single representable outcome, with the citation for every elimination written out
rather than implied.

Three items are recorded for the **as-built pass at close** and are deliberately *not*
fixed mid-flight — see *Scope*, findings 1–3. The main session owns diagram edits as of
2026-08-22 (`pm/active.json`).

**Traces to:** UC-11 (`docs/workbook.xlsx`, `UC FR`, *Set the Monthly Budget*,
`Modul: Budgeting`, `Entity/Objek Terkait: Budget_Group, Budget_Period`) — FR-12, FR-14,
FR-15, FR-16, FR-17 (only as the null FK, see *Out of scope*), FR-18, NFR-4.
**Depends on:** `FEAT01-foundation` — **DONE 2026-08-21** (`pm/tracker.yaml`).

**Preflight: PASSES, with every overlap named rather than glossed.**

- The single declared dependency is `DONE`.
- This issue owns `BudgetGroups` and `BudgetPeriods` (`context/index/map.yaml`,
  `entities.Budget_Group` / `entities.Budget_Period`, both `modul: Budgeting`). No other
  issue owns them. The re-scope that gave it budget group CRUD is
  `context/index/decisions.md`, 2026-08-21, and `pm/tracker.yaml`'s UC11 row.
- **Two files are shared with other plans, and neither has work in flight.**
  `app/lib/src/app.dart` — `UC14-choose-currency` is **HALTED** (`pm/questions.md` Q1) and
  its unbuilt D3 re-points `MaterialApp.home`; `UC13-categories` is DONE and its D3
  currently holds that slot and explicitly anticipates a later screen issue taking it. See
  D8. `app/lib/src/transactions/transactions_table.dart` is **read, never modified** — the
  group delete writes rows in `Transactions` (D7), which `UC04`/`UC09` will later own the
  screens for; both are TODO and blocked behind `UC14`, so nothing is in flight.
- No schema change, so no contention with any other issue's migration.

## Goal

At the end, the owner has the budget-setting surface UC-11 describes: `SetBudgetScreen`
lists every budget group with an amount for the calendar month containing today,
pre-filled from the previous month's amount where this month has no row yet (FR-15), and
the owner can change any amount, delete the month's period for a group, and create, rename
or delete a budget group. Every write goes
`SetBudgetScreen → BudgetNotifier → BudgetDao → AppDatabase`, and the updated view arrives
back on the read path as a new emission of `budgetProvider` — never as a write's return
value. Nothing is refused, nothing is locked, no control is disabled, and no status or
lifecycle is introduced anywhere. No table changes: `schemaVersion` stays 1.

## Scope: the sequence diagram, reconciled

`docs/diagrams/seq-uc11-set-budget.drawio` (render committed at
`pm/issues/uc11-set-budget/seq-uc11-set-budget.png`, inspected while writing this plan).
**This diagram is the scope** (`CLAUDE.md`). Labels live on `<UserObject label="…">`
wrappers; the fragment guards live on `mxCell value=` — both were read, and the render was
looked at (`lessons.md` §4, §3).

**Six lifelines, and every one is already a class on `docs/diagrams/class-budgeting.drawio`**
(`sequence-conventions.md`'s lifeline rule — checked one by one, and this is the check that
caught an invented call in a previous issue, `lessons.md` §10):

| Lifeline | On the class diagram | Where it lives in code |
|---|---|---|
| `Owner` | actor, not a class | — |
| `SetBudgetScreen` | yes — *UC-11 · ConsumerWidget · always saves — no lock, no refusal* | new, D1 |
| `BudgetNotifier` | yes — *Notifier, exposed as `budgetProvider`* | new, D1 |
| `BudgetDao` | yes — *period + consumption queries* | new, D1 |
| `Clock` | yes — *injected time source* | new, D1/D5 |
| `AppDatabase` | yes | exists (FEAT01) |

**No lifeline is missing from the class diagram, and this plan invents no class.**

### The messages, in order

1. `Owner → SetBudgetScreen` *opens the budget screen for a month*.
2. `BudgetNotifier → BudgetDao` *previous month's amounts, per budget group (FR-15)*.
3–4. `BudgetDao → Clock` *today()*, `Clock ⇢ BudgetDao` *today's date*.
5–6. `BudgetDao → AppDatabase` *query previous BudgetPeriod*, `AppDatabase ⇢ BudgetDao` *rows*.
7. `BudgetDao ⇢ BudgetNotifier` *previous amounts*.
8. `BudgetNotifier → SetBudgetScreen` *pre-filled amounts for the new month (FR-15, step 1)*.
9. `Owner → SetBudgetScreen` *changes the amount for a budget group*.
10–13. `setAmount(groupId, month, amount)` → `upsert(groupId, month, amount)` →
   `upsert(groupId, month, amount)` → *row saved*.
14. `BudgetNotifier → SetBudgetScreen` *amount updated (no lock, no refusal — FR-16
   rewritten 2026-08-20)*.
15–19. `opt` **[owner deletes the period instead (FR-16 rewritten, FR-18 — full CRUD, no
   lock)]** — `delete(periodId)` → `delete(periodId)` → `delete(periodId)` → *row deleted* →
   *period removed*.
20–25. `opt` **[owner adds a budget group (moved from UC-13 step 3, 2026-08-21)]** —
   *adds a budget group* → `addGroup(name)` → `insertGroup(name)` → `insert(name)` →
   *row inserted* → *group added*.
26–31. `alt` operand 1 **[owner renames a budget group (FR-18)]** — *renames a budget group*
   → `renameGroup(groupId, newName)` → `updateGroup(groupId, newName)` →
   `update(groupId, newName)` → *row updated* → *group renamed*.
32–37. `alt` operand 2 **[owner deletes a budget group (FR-18)]** — *deletes a budget group*
   → `deleteGroup(groupId)` → `deleteGroup(groupId)` → `delete(groupId)` → *row deleted* →
   *group deleted*.
38. The diagram's note: *DAO to AppDatabase crosses the isolate boundary*.

**Three things the message list settles, and they are the load-bearing ones:**

- **Every message from `BudgetNotifier` back to `SetBudgetScreen` is a solid message, not a
  dashed reply** (verified against the edge styles in the XML: messages 8, 14, 19, 25, 31,
  37 are solid; only 4, 6, 7, 13, 18, 24, 30, 36 are dashed). `setAmount()` and its four
  siblings get **no reply arrow** — the updated view arrives as a state emission, which is
  exactly `riverpod.md`'s read/write asymmetry and `sequence-conventions.md`'s drawing rule
  (ISSUE-008). D3.
- **Nothing is written between message 1 and message 9.** Opening the screen queries and
  pre-fills; the first write in the whole diagram is the `upsert` the owner's own action
  triggers. D4.
- **The screen never touches `BudgetDao` or `AppDatabase`.** Every message from
  `SetBudgetScreen` goes to `BudgetNotifier`, which the class diagram's own note requires:
  *"A screen never touches the DAO or the database — it watches a provider."*

### Three findings, for the as-built pass at close — not fixed now

1. **The read path's first message is not drawn.** Message 2 starts at `BudgetNotifier`
   with no preceding `SetBudgetScreen → BudgetNotifier watch()`. This is the same elision
   `seq-uc13-categories.drawio` carried as `pm/findings.md` **F2**, fixed on 2026-08-22 by
   adding the five read-path messages. `seq-uc11` needs one message of the same kind. The
   wiring is drawn on `class-budgeting.drawio` (`SetBudgetScreen → BudgetNotifier`), so
   building it is not widening scope — a notifier that emits to a screen six times must be
   watched by it — but the diagram should gain the message rather than the gap being
   silently filled (`general-rules.md`: state the tension, do not quietly apply the
   better-seeming answer).
2. **Message 2's label names only the fallback.** It reads *previous month's amounts, per
   budget group*, but the notifier must also read **this** month's rows, or an amount saved
   at message 13 could never be shown again and message 14's *amount updated* would be a
   lie that FR-16 (*"I can change a month's budget at any time"*) directly contradicts. The
   class diagram's DAO method is the general `watchPeriods()`, not a
   `watchPreviousPeriods()`. D4 builds both reads; the label should say so at close.
3. **The isolate note is one wrapper stale** — *NativeDatabase.createInBackground,
   2026-08-20*, where the code opens the database through `drift_flutter`'s
   `driftDatabase()`, which calls `NativeDatabase.createBackgroundConnection`
   (`decisions.md` 2026-08-21, FEAT01 ruling 2 — same guarantee, stale name). This is
   `pm/findings.md` **F3**, which is already recorded as covering thirteen diagrams, each
   to be corrected by its own issue's as-built pass. This is UC-11's one.

### One register that IS stale, found while writing this plan

`docs/workbook.xlsx`, `UC FR`, UC-11, `Deskripsi`, last paragraph, **present tense and
wrong**:

> *Open (fr-nfr.md section 4): what "a month" means — calendar month or payday-to-payday —
> was never discussed; calendar was assumed throughout. Also deferred to the ERD: whether a
> budget's identity is separate from its monthly amount.*

Both were closed on 2026-08-20: a month is a calendar month
(`decisions.md`, `fr-nfr.md` §4) and the identity/amount split is `Budget_Group` +
`Budget_Period` on `erd.drawio` and in `budgeting_table.dart`. This is `lessons.md` §1's
mirror-image failure — *a document claiming something is open when it is settled* — and it
is exactly the register this issue closes, so step 12 fixes it at close. The rest of the
row's lock references were checked and are **history, marked as history** (*"this use case
previously carried the app's only lifecycle"*) — correct as written, and must not be edited
(`lessons.md` §1, the tense rule).

## Decisions

Each entry cites the confirmed artifact it is transcribed from. **None of them is a new
choice**; where a choice appeared to exist, the entry names what eliminated the
alternatives.

### D1 — The four new files, one modified file, two test files, and nothing else

*Cites:* `context/coding-conventions/dart-and-flutter.md` §Directory layout (one file per
class-diagram band, `<name>_dao.dart` / `<module>_providers.dart` / `<name>_screen.dart`,
package rooted at `app/`); `class-budgeting.drawio` for which classes exist;
`testing.md` §Conventions (tests mirror `lib/src/`); the file layout `UC13-categories`
actually shipped.

```
app/lib/src/budgeting/budget_dao.dart            BudgetDao — watchGroups(), watchPeriods(),
                                                 upsert(), delete(), insertGroup(),
                                                 updateGroup(), deleteGroup()
app/lib/src/budgeting/clock.dart                 Clock — injected time source
app/lib/src/budgeting/budgeting_providers.dart   BudgetNotifier, exposed as budgetProvider
app/lib/src/budgeting/set_budget_screen.dart     SetBudgetScreen (ConsumerWidget)

app/test/budgeting/budget_dao_test.dart
app/test/budgeting/set_budget_screen_test.dart
```

Modified, not created:

- `app/lib/src/app.dart` — `home`, and its doc comment (D8).

**Not modified, and this is deliberate:**

- `app/lib/src/budgeting/budgeting_table.dart` — `BudgetGroups` and `BudgetPeriods` already
  exist exactly as the ERD and the class diagram draw them, and drift already generates
  `BudgetGroup` / `BudgetPeriod` row classes and their companions.
- `app/lib/src/database/app_database.dart` — **no `daos: […]` entry**, because `BudgetDao`
  is a plain class composing `AppDatabase` (D2). The table list, `schemaVersion` and the
  `beforeOpen` seeding are untouched.
- `app/lib/src/transactions/transactions_table.dart` — read only; D7 writes rows in
  `Transactions`, it does not change the declaration.

A file outside this list is out of scope; adding one is a conversation, not a judgement
call (the shape `FEAT01` D2 and `UC13` D1 used).

### D2 — `BudgetDao` is a plain class composing `AppDatabase`, and every provider is hand-written

*Cites:* `context/index/decisions.md`, 2026-08-21, "UC-13: two rulings the real toolchain
forced above the database" — both rulings state in their own text that they bind
`AccountDao`, `TransactionDao` **and `BudgetDao`**; `context/coding-conventions/drift.md`
and `riverpod.md` as corrected by that issue; `coding-conventions/README.md` (class names in
code match the class diagrams exactly).

`class-budgeting.drawio` gives `BudgetDao` a `delete()` and an `upsert()`.
`DatabaseConnectionUser` — which `DatabaseAccessor` extends — already declares
`update<T,D>()` and `delete<T,D>()`, so a `DatabaseAccessor` subclass declaring `delete()`
with a named-parameter signature is a straight `invalid_override`. Verified empirically
twice already. `BudgetDao` therefore takes an `AppDatabase` in its constructor, exactly as
`CategoryDao` does. And `budgetProvider`'s type mentions drift-generated row classes
(`BudgetGroup`, `BudgetPeriod`), which `riverpod_generator` rejects with
`InvalidTypeException`, so it is hand-written. Neither is a new decision; both are already
recorded rulings being applied.

### D3 — `BudgetNotifier` is the screen's single source for both reading and writing

*Cites:* `seq-uc11-set-budget.drawio` — every `SetBudgetScreen` message targets
`BudgetNotifier`, and messages 8/14/19/25/31/37 are **solid** emissions from
`BudgetNotifier` to the screen, not dashed replies; `class-budgeting.drawio` — the note
*"A screen never touches the DAO or the database — it watches a provider"*, the
`SetBudgetScreen → BudgetNotifier` edge, *"exposed as `budgetProvider`"*, and the DAO's
`watchGroups()` / `watchPeriods()`; `riverpod.md` §"A write does not return the result to
the screen" and §"What may hold state".

Unlike UC-13 — where `class-transactions.drawio` draws a separate `categoryTreeProvider`
for reads — **the Budgeting class diagram gives UC-11 exactly one provider**
(`budgetConsumptionProvider` is annotated *UC-12*). So `budgetProvider` carries the read as
well as the writes, which is what the sequence diagram draws.

What follows, and what does not:

- `BudgetNotifier`'s state is **the month's view derived from a live drift query**, not a
  cached copy of it. It is produced by combining `BudgetDao.watchGroups()` with
  `BudgetDao.watchPeriods(...)`, so after any write drift re-emits and the screen rebuilds —
  one source of truth, which is what `riverpod.md` protects and what NFR-2 requires.
  A write method returns nothing the screen renders.
- The **class name is `BudgetNotifier` and the provider is `budgetProvider`**, verbatim from
  the class diagram — that rule outranks anything the generator or a convention would prefer
  (`coding-conventions/README.md`; the `categoriesProvider` precedent).
- The riverpod **base class** (`StreamNotifier` versus `Notifier` plus an explicit
  subscription) is shape, not name, and the class diagram's annotation *"Notifier"* is
  distinguishing a notifier from the `StreamProvider` beside it, not naming a Dart
  superclass. Build it as a `StreamNotifier`; if the real toolchain fights that, the
  fallback is `Notifier` holding the same derived state with a subscription opened in
  `build()`, and the correction is written into `riverpod.md` as part of this issue —
  *anything that fights the real toolchain loses* (`coding-conventions/README.md`,
  `decisions.md` 2026-08-21).
- **No new package.** Combining two streams uses Dart core (`asyncExpand` or equivalent);
  adding `rxdart` is out of scope.

### D4 — FR-15's pre-fill is a value shown in the form, not a row written ahead of time

*Cites:* `seq-uc11-set-budget.drawio` — **no write message exists between message 1
(opens the screen) and message 9 (the owner changes an amount)**; message 8's own label,
*"pre-filled amounts for the new month (**FR-15, step 1**)"*, places FR-15's satisfaction at
the screen boundary; the first write on the diagram is `upsert`, under the owner's action.
`docs/workbook.xlsx` UC-11 `Input` calls the amounts *"pre-filled from the previous month"* —
an **Input**, i.e. what the form starts with — while `Output` says a group *"has an amount
for that month"*, i.e. after the owner acts. `fr-nfr.md` FR-16/NFR-4 and `lessons.md` §2
(*a derived value has no entry point of its own*) for the reading rule.

This is the subtle one, so both readings are named with what eliminates them:

| Reading | Status |
|---|---|
| Opening the screen **writes** next month's rows from this month's | **Excluded.** It is a write the diagram does not draw, and `CLAUDE.md` makes the diagram the scope boundary in both directions — nothing outside it is in scope. It would also make merely opening a screen mutate the database, which nothing in the artifact set asks for. |
| The screen **shows** the previous month's amount where this month has no row; a row exists only once the owner saves | **The only reading the diagram supports**, and the one message 8 labels as FR-15 step 1. |

Consequences, stated so they are not discovered later:

- A month the owner never opens or never saves has **no `BudgetPeriods` rows**, and UC-12
  will show nothing for it. That is consistent with *skipped months are left alone*
  (`decisions.md`, 2026-08-20 — gaps are real and are shown as gaps) and with FR-14.
- **The notifier reads both months.** For each group: if a row exists for the current month,
  its amount is what the screen shows and its `budgetPeriodId` is what message 15's
  `delete(periodId)` needs; otherwise the previous month's amount is shown as the pre-fill
  and there is no period id; if neither exists, the amount is blank. The
  current-row-wins ordering is forced by FR-16 — if the previous month's value always won,
  a saved change could never be seen or re-edited, and message 14 would be false. See
  finding 2.

### D5 — A month on disk is `starts_on` = the first day, `ends_on` = the last day, of the calendar month containing `Clock.today()`

*Cites:* `context/index/decisions.md`, 2026-08-20, *"A month" means a calendar month* —
*"Budget periods run from the first of the month to the last day of the month"*, with
payday-to-payday rejected because a boundary deriving from an editable transaction is
unstable; `docs/fr-nfr.md` §4 (same decision, and *"this decision is the reason `starts_on` /
`ends_on` are stored per period rather than the period being identified by a bare
`YYYY-MM`"*); `erd.drawio` and `app/lib/src/budgeting/budgeting_table.dart`, whose own
comment repeats it; `seq-uc11` messages 3–4 (`BudgetDao` asks `Clock` for today before
querying) and `class-budgeting.drawio`'s `Clock` box.

- `startsOn` is the first day of the month at midnight; `endsOn` is the **last day** of the
  same month at midnight. Inclusive, because the column is named `ends_on` — a half-open
  upper bound would put a date belonging to the next month in a column that says otherwise.
- The month a period belongs to is therefore identified by `budgetGroupId` + `startsOn`,
  which is what `upsert(groupId, month, amount)` matches on.
- `Clock` supplies today, so month arithmetic is deterministic under test — including the
  January case, where the previous month is December of the prior year. `Clock` is
  constructor-injected into `BudgetDao` with a real-time default; **no `clockProvider` is
  created**, because no class diagram has one and DAO tests construct the DAO directly
  (`testing.md`: the DAO layer is where correctness lives). If the widget test turns out to
  need a clock override, that is a finding to raise, not a provider to invent
  (`coding-conventions/README.md`).
- `class-budgeting.drawio`'s note says `Clock` survives only because *"deciding which period
  is the current one is still a question about today's date"*, and to drop it if a later
  pass finds nothing asking it the time. **Messages 3–4 ask it the time**, so it stays. The
  note needs no change.

### D6 — `upsert` matches on group + month inside one transaction; no schema change

*Cites:* `seq-uc11-set-budget.drawio` messages 11–12, whose method name is literally
`upsert`; `budgeting_table.dart` as built (no unique index on `budgetGroupId` +
`startsOn`); `FEAT01` (schema at version 1, `drift_schema_v1.json` committed);
`lessons.md` §8 (*"just add one column" is never one edit*).

`upsert()` selects the row for that group and that month's `startsOn` and updates its
`amount` if one exists, otherwise inserts one — the whole thing in a single
`_db.transaction`, so two saves cannot race into two rows for one month.

**A `UNIQUE(budget_group_id, starts_on)` index would express that in the schema and is
deliberately not added**, and the cost is stated before the work rather than after
(`lessons.md` §7): it is a schema change, so it costs `schemaVersion` 2, a second committed
snapshot, a migration, and it makes `erd.drawio`, `class-budgeting.drawio`, `map.yaml` and
`enums.md`'s storage note stale with it. Nothing in the confirmed artifact set asks for the
constraint, and no other code path writes `BudgetPeriods`. Recorded here as a candidate for
a later issue rather than smuggled in.

### D7 — Deleting a budget group deletes its periods and blanks the budget tag on its transactions; both keep every transaction standing

*Cites:* NFR-4's fit criterion — **zero** refused user actions, strengthened 2026-08-20 from
one to zero (`fr-nfr.md` §2; `decisions.md`, "No guardrails"); FR-18 (*"no entity has an
exception"*); **FR-17** (*"Spending with no budget group appears under 'Others'"* — the tag
is optional and money must not escape the budget view); FR-10 (the budget tag *"can be left
blank"*); `app/lib/src/budgeting/budgeting_table.dart` — `BudgetPeriods.budgetGroupId` is
**NOT NULL**; `app/lib/src/transactions/transactions_table.dart` — `Transactions.budgetGroupId`
is **nullable**; `decisions.md` 2026-08-19 (*"Others" is the null `budget_group_id`, not a
row*); `UC13-categories` D6, the identical derivation one module over; `drift.md` §DAOs and
`decisions.md` 2026-08-20 (a module reaches another module's data directly).

Every alternative, with what eliminates it:

| Outcome | Status |
|---|---|
| Refuse the delete while periods or transactions reference the group | **Forbidden.** NFR-4's count is zero and there is no sanctioned exception left to argue similarity to. |
| Keep the periods, with no group | **Not representable.** `BudgetPeriods.budget_group_id` is NOT NULL. |
| Keep the periods pointing at a deleted group id | **Not representable as a design.** The ERD draws the FK; the rows would survive as amounts no query can attribute — the same objection UC-13 D6 raised against a dangling tag. |
| Cascade-delete the *transactions* tagged with the group | **Excluded.** Deleting a budget tag would destroy records FR-18 gives their own correction use case (UC-09) and silently change FR-1's four figures. The diagram deletes a *group*. |
| Leave the transactions' `budget_group_id` pointing at the deleted group | **Excluded by FR-17.** Those rows would be neither in a group nor in "Others", which is precisely the *money escaping the budget view* FR-17 exists to prevent. |
| **Delete the periods; null the tag on the transactions; keep the transactions** | **The only outcome left**, and it lands in a state FR-10 and FR-17 already declare legal — a transaction with no budget group is "Others", which is normal, not damaged. |

So `deleteGroup(groupId)` runs as one drift transaction, in explicit statement order so the
behaviour does not depend on `PRAGMA foreign_keys` (which is off and stays off — UC-13 D6,
and turning it on is out of scope):

1. `UPDATE Transactions SET budget_group_id = NULL WHERE budget_group_id = ?`
2. `DELETE FROM BudgetPeriods WHERE budget_group_id = ?`
3. `DELETE FROM BudgetGroups WHERE budget_group_id = ?`

The diagram draws this as one message (`delete(groupId)`) because it is one DAO call, the
same way UC-13's single `delete(id)` message covered its cascade.

`delete(periodId)` (messages 15–19) is one row and nothing references it.

### D8 — `SetBudgetScreen` becomes what `app.dart` shows, temporarily

*Cites:* `seq-uc11` message 1 (*the owner opens the budget screen*); `UC13-categories` D3,
which makes this derivation and **explicitly anticipates a later screen issue re-pointing
`home`**, naming the consequence as its first non-blocking open question;
`UC14-choose-currency` D3, the same derivation a third time; FR-1 (*"the primary screen —
not a report behind a menu"* is the balance sheet, i.e. `UC01`'s, which takes the slot
permanently); `coding-conventions/README.md` (a class the diagrams lack may not be written).

Message 1 requires the screen to be openable. The diagram draws **no navigation lifeline**,
and **no class diagram in this project has one**, so the only way to satisfy message 1
without inventing a class is for `MaterialApp.home` to be `SetBudgetScreen`. Forced
derivation, not preference — and not a re-decision of UC-13 D3, which already wrote down
that this would happen and to whom the slot permanently belongs.

**The cost, stated before the work (`lessons.md` §7):** `CategoryManagerScreen` becomes
unreachable in a running app until `UC01-balance-sheet` lands FR-1's primary screen and
whatever navigates from it. UC-13's own tests do not depend on `home`, so nothing breaks;
the screen simply has no route. This is already the owner's open question on file
(`pm/active.json`, UC-13: *"there is no navigation host so one screen is reachable at a
time"*) and it is repeated below rather than solved here by building a router nobody has
specified.

### D9 — Nothing on this screen is ever disabled, and nothing warns

*Cites:* NFR-4 and its fit criterion, **zero** refusals (`fr-nfr.md` §2); FR-18 (full CRUD,
no exception); FR-16 as rewritten (*no lock*, and `class-budgeting.drawio`'s own
`SetBudgetScreen` annotation, *"always saves — no lock, no refusal"*); FR-12 (*a soft limit,
not an enforced one*); `seq-uc11` (no `opt` fragment anywhere carries a warning, unlike
`seq-uc14`, which draws one explicitly); `testing.md` §"Two requirements that need explicit
tests"; `pm/findings.md` **F4**; `UC13-categories` D7, the same derivation.

- Every control — save, delete period, add group, rename group, delete group — is
  **enabled at all times**. A disabled button is a refusal by another name and is the
  likeliest accidental violation in the app.
- **No confirmation dialog and no warning banner.** The diagram draws neither, and UC-14's
  diagram shows this project draws a warning explicitly when it wants one. A warning is
  permitted by NFR-4, not required by it, and adding UI the diagram does not have is
  widening scope.
- **No status, no lifecycle, no lock, no "closed month".** `docs/statuses.md` lists no
  values for `Budget_Period` deliberately (ISSUE-003 → ISSUE-004), and
  `class-budgeting.drawio` no longer has `isEditable()`, `stateOf()` or `BudgetPeriodState`.
  Nothing in this issue may reintroduce any of them, in any form, including a computed
  "this month is over" that changes what a control does. `docs/statuses.md` and
  `docs/enums.md` are **not** edited by this issue.
- The delete control for a *period* is rendered only for a group that has a row this month,
  because message 15 needs a `periodId`. That is not a refusal — there is nothing to delete —
  and it must not be implemented as a disabled button.

### D10 — "Done" without a runnable app, and what the tests must assert

*Cites:* `context/coding-conventions/testing.md` (the layers, the two requirements needing
explicit tests, the conventions, and the two verified `flutter_test` + drift gotchas);
`tooling.md` and `.github/workflows` (the four commands CI runs); `decisions.md` 2026-08-21
(iOS cannot be built here); `FEAT01` D7 and `UC13` D8, the same substitution.

**There is no Android SDK and no Mac, so nothing can be launched or looked at.** Done is
therefore defined entirely by headless commands and by what the tests assert. Run from
`app/`:

1. `dart run build_runner build --delete-conflicting-outputs` — **green, and
   `app_database.g.dart` plus `app/drift_schemas/app_database/drift_schema_v1.json` must be
   byte-identical to what is committed**, because this issue changes no table (`git diff`
   proves it). `schemaVersion` stays 1.
2. `dart format --set-exit-if-changed .` — 0 files changed.
3. `flutter analyze` — "No issues found!".
4. `flutter test` — all green, the existing 14 included, none deleted or weakened.

And from the repository root: `python audit.py` — no new failures or warnings.

**`app/test/budgeting/budget_dao_test.dart` must assert, each test naming its requirement
in its description (`testing.md` §Conventions):**

- **FR-12 / FR-16** — `upsert` for a group and a month with no row inserts one; a second
  `upsert` for the same group and month **updates it and leaves exactly one row**, at any
  point in the month (no lock, mid-month change proceeds).
- **"A month" is a calendar month (D5)** — the inserted row's `startsOn` is the first day
  and `endsOn` the last day of the month containing the injected `Clock`'s today, tested
  with a 31-day month, a 30-day month and February.
- **FR-15** — with a previous-month row and no current-month row, the pre-filled amount for
  that group equals the previous month's; with a current-month row, the current amount wins
  (D4); with neither, the group appears with no amount. Include a **January** today, so the
  previous month is December of the prior year.
- **FR-14** — writing this month's amount leaves the previous month's row untouched, and
  nothing is carried forward: no row is created for a month the test never wrote.
- **FR-18 / NFR-4** — `delete(periodId)` removes the period and nothing else;
  `deleteGroup()` on a group that has periods **and** transactions tagged with it
  **succeeds**, removes the group and its periods, leaves every transaction row present,
  and leaves their `budgetGroupId` **NULL** (D7, FR-17). This is the single most valuable
  test in the issue.
- **Empty and boundary states** (`testing.md`) — no groups at all; a group with no period in
  either month; a month with rows for some groups only.
- Build the in-memory database fresh per test; no mocking of drift; do not consume a
  `watch()` stream's `.first` in a file that also builds a widget over the same query
  (`testing.md`, verified UC-13).

**`app/test/budgeting/set_budget_screen_test.dart` must assert:**

- The screen renders one row per budget group from `budgetProvider`, with the pre-filled
  amount visible (message 8).
- **NFR-4** — the save, delete-period, add-group, rename-group and delete-group controls are
  **enabled**. Guard against `pm/findings.md` **F4**: assert the finder matches the expected
  number of widgets *before* asserting each is enabled, so the test cannot pass by finding
  nothing.
- The screen must unmount and pump a real duration before the test body returns, or
  `flutter_test`'s teardown throws "A Timer is still pending" (`testing.md`, verified UC-13).

## Steps

In dependency order. Steps 1–7 are the build; 8–12 are the close.

1. `app/lib/src/budgeting/clock.dart` — `Clock`, the injected time source (D5). One method
   returning today's date.
2. `app/lib/src/budgeting/budget_dao.dart` — `BudgetDao`, a plain class composing
   `AppDatabase` (D2), taking a `Clock` with a real-time default (D5). Methods, named
   verbatim from `class-budgeting.drawio`: `watchGroups()`, `watchPeriods()`, `upsert()`,
   `delete()`, `insertGroup()`, `updateGroup()`, `deleteGroup()`. Month arithmetic per D5;
   `upsert` per D6; `deleteGroup` per D7, in one transaction, explicit statement order.
   **`watchConsumption()` is not written** — it is UC-12's (Out of scope).
3. `app/test/budgeting/budget_dao_test.dart` — every assertion in D10. Written against the
   DAO before the UI exists, because this is where the correctness surface is.
4. `app/lib/src/budgeting/budgeting_providers.dart` — `BudgetNotifier`, hand-written,
   exposed as `budgetProvider` (D2, D3). Read state per D4; write methods `setAmount()`,
   `delete()`, `addGroup()`, `renameGroup()`, `deleteGroup()`, named verbatim from the class
   diagram, each forwarding to `BudgetDao` and returning nothing the screen renders.
5. `app/lib/src/budgeting/set_budget_screen.dart` — `SetBudgetScreen`, a `ConsumerWidget`
   watching `budgetProvider`: one row per group with its amount field, a delete for the
   month's period where one exists, and add / rename / delete for groups (D9 governs every
   control).
6. `app/test/budgeting/set_budget_screen_test.dart` — per D10.
7. `app/lib/src/app.dart` — point `home` at `SetBudgetScreen` and rewrite the doc comment to
   say why and to keep UC-13's D3 history accurate (D8).
8. Run the five commands in D10. **If the toolchain fights any convention** — the
   `StreamNotifier` shape in particular (D3) — correct the relevant
   `context/coding-conventions/*.md` file in place, marked and dated, and record it in
   `pm/log.md`. *Anything that fights the real toolchain loses.*
9. **As-built pass on `docs/diagrams/seq-uc11-set-budget.drawio`** (main session, not a
   subagent — `pm/active.json`, 2026-08-22): add the missing
   `SetBudgetScreen → BudgetNotifier watch()` read-path message (finding 1), correct
   message 2's label to name both months (finding 2), and correct the isolate note to
   `drift_flutter`'s `driftDatabase()` → `NativeDatabase.createBackgroundConnection`
   (finding 3, `pm/findings.md` F3 — narrow F3's count by one). Export to PNG, **look at the
   render** (`lessons.md` §3), refresh `pm/issues/uc11-set-budget/seq-uc11-set-budget.png`
   and `docs/diagrams/renders.lock`.
10. `context/index/map.yaml` — add the `UC-11` entry (dao / providers / screen / tests), and
    correct the `entrypoint` comment, which currently says `home` *"is UC-13's screen since
    2026-08-21, temporarily"* (D8).
11. `context/index/decisions.md` — only if step 8 produced a durable ruling. D1–D10 here are
    transcriptions of existing decisions and do **not** need new entries.
12. **The stale registers, per `lessons.md` §1 — a decision is not finished until every
    register that listed it as open is updated:**
    - `docs/workbook.xlsx`, `UC FR`, UC-11 `Deskripsi` — delete the *"Open (fr-nfr.md
      section 4): what 'a month' means … Also deferred to the ERD …"* paragraph, both
      settled 2026-08-20 (see *Scope*). Leave every lock reference alone: they are history,
      marked as history. Delegate to `workbook-xlsx-author` or read
      `workbook-conventions.md` first.
    - Mark the UC-11 row implemented **if the workbook has a column for it** — `pm/findings.md`
      **F5** records that it does not. If it still does not, say so at close rather than
      inventing a column.
    - `context/coding-conventions/README.md` — if step 3's tests assert a real derived-figure
      query, the *"still unverified"* half of the banner narrows. Split the label rather than
      re-broadening it (`lessons.md` §1, the half-true-label rule).
13. `pm/tracker.yaml` → Done + summary; `pm/log.md` → dated entry plus the current-state
    block at its head; `pm/active.json` → **clear it, or record that nothing is runnable**
    (UC-12 needs UC-04, which is behind the halted UC-14) and go to phase 2.

## Out of scope

Itemised, because every closed issue in this project has this list and it is why scope
arguments have not happened here.

- **UC-12 entirely — budget consumption, spent, and remaining.** `BudgetOverviewScreen`,
  `budgetConsumptionProvider`, the `BudgetConsumption` query-result class and
  `BudgetDao.watchConsumption()` are all on `class-budgeting.drawio` and all annotated
  *UC-12*. None is written here. No lifeline on `seq-uc11` is any of them.
- **FR-17's "Others" as a visible bucket.** It surfaces in this issue only as the null
  `budget_group_id` D7 writes. The row labelled "Others" in a budget view belongs to UC-12
  (`docs/workbook.xlsx` UC-12 `Deskripsi`, step 3; `enums.md`).
- **Choosing which month to look at.** The screen shows the calendar month containing
  `Clock.today()` (D5) — `seq-uc11` draws no month-picker message and no navigation.
  Selecting a month is UC-12's stated `Input` (*"The month to look at"*). This is not a
  refusal: FR-16's *"at any time, including after the month has started"* is satisfied for
  the month being budgeted. Flagged below as an open question.
- **Any schema change.** No new column, no unique index (D6), no `PRAGMA foreign_keys`
  (D7), no `schemaVersion` bump, no new snapshot, no migration.
- **Currency formatting.** Amounts are `int` minor units (`enums.md`, FR-19) and are entered
  and shown as such. `seq-uc11` has no `Settings` lifeline and this issue does not read
  `Settings`. The currency surface is UC-14's, which is **HALTED** (`pm/questions.md` Q1).
- **Routing, navigation, an app shell or a menu.** D8 points `home` at this screen because
  message 1 requires it; nothing more. No class diagram has a navigation class.
- **Recording or tagging a transaction against a budget group** — UC-04/UC-05 (FR-10).
- **Categories and subcategories** — `UC13-categories`, DONE. Not touched.
- **Backfilling skipped months** — decided against, 2026-08-20 (*"leave it be, it's users
  commitment not app problem"*).
- **Recording that an amount was amended after the period started** ("2M, amended from 1.5M
  on day 20") — `fr-nfr.md` FR-16 names it as the way to get UC-12's comparison back and
  says **deliberately not built now**. It would need a schema change and its own issue.
- **Anything resembling the removed lock** — no `isEditable()`, no `stateOf()`, no
  `BudgetPeriodState`, no status column, no month-is-closed branch (D9, ISSUE-004,
  `docs/statuses.md`).

## Open questions

None of these blocks the work. Each is a consequence the owner should see, not a decision
this plan needed.

1. **Deleting a budget group is silent and takes its history with it.** Per D7 it deletes
   every period ever set for that group and untags every transaction that referenced it —
   those become "Others" (FR-17). Nothing warns, because NFR-4 permits a warning but the
   diagram draws none (D9). This is the budgeting twin of UC-13's *"deleting a category
   silently blanks the tag on every transaction that used it"*, already on file in
   `pm/active.json`.
2. **Only the current calendar month can be budgeted from this screen.** There is no month
   picker on the sequence diagram, so a past month's amount cannot be corrected until UC-12
   lands the month view. FR-16 is honoured for the month in hand; the gap is reachability,
   not refusal.
3. **The navigation host, again.** D8 makes `CategoryManagerScreen` unreachable in a running
   app. That is the third issue to re-point `home` at its own screen, which is the point at
   which "the app has no navigation host" stops being a note and starts being a queue.
   Still the owner's call; still not solved by inventing a router.
4. **`Clock` earned its keep, narrowly.** `class-budgeting.drawio`'s note says to drop it if
   nothing asks it the time. Messages 3–4 do (D5), so it stays — but it is asked by exactly
   one caller in the whole app, and if `UC01`/`UC12` turn out not to need it, the note's
   suggestion is still live.
