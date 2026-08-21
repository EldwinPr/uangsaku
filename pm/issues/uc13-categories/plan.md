# UC13-categories — Manage categories and subcategories

**Status:** DONE 2026-08-21 — built, reviewed and committed by `issue-qa`. One close step
is **outstanding and dispatched, not skipped**: the as-built edit to
`seq-uc13-categories.drawio` (the two findings below) belongs to `diagram-drawio-author`
and is recorded as `pm/findings.md` F2/F3.

Planned as **AUTO-CONFIRMED** 2026-08-21, under the unattended-mode rule in
`context/general-rules.md` (§Planning gate) and `context/index/decisions.md`
(2026-08-21, "The planning gate gets an unattended mode"). Every decision below cites the
already-confirmed artifact it is transcribed from. **Nothing here is a new choice** — the
two places where one could have been made (what happens to a transaction whose category is
deleted, and whether the delete warns) are argued down to a single representable outcome in
D6 and D7, with the citation for each elimination written out rather than implied.

Two items are recorded for the **as-built pass at close** and are deliberately *not* fixed
mid-flight: the sequence diagram elides the read path it depends on (see *Scope*, finding 1)
and its isolate note names a mechanism one wrapper stale (finding 2).

**Traces to:** UC-13 (`docs/workbook.xlsx`, `UC FR`, `Modul: Transactions`) — FR-10, FR-18.
**Depends on:** `FEAT01-foundation` — **DONE 2026-08-21** (`pm/tracker.yaml`).

**Preflight: PASSES, with one overlap named rather than glossed.** The single declared
dependency is Done. This issue owns `Categories` and `Subcategories` and no other table
(`context/index/map.yaml`, `entities.Category` / `entities.Subcategory`, both
`modul: Transactions`); the two other rows that depend only on FEAT01 own different tables —
UC14 owns `Settings`, UC11 owns `BudgetGroups` / `BudgetPeriods`. **The one file this plan
shares with another plan is `app/lib/src/app.dart`**: `UC14-choose-currency` is **HALTED**
(`pm/tracker.yaml`; `pm/questions.md` Q1) and its unbuilt D3 also re-points
`MaterialApp.home`. No work is in flight on it, both plans declare the change temporary, and
FR-1 gives the permanent primary screen to `UC01-balance-sheet`. See D3 and the first
non-blocking open question.

## Goal

At the end, the owner has the tagging vocabulary FR-10 describes: a screen showing every
category with its subcategories nested one level under it, and create / rename / delete on
both levels. `CategoryManagerScreen` watches `categoryTreeProvider`, which wraps
`CategoryDao.watchTree()`; every write goes `Screen → CategoriesNotifier → CategoryDao →
AppDatabase` and the changed tree comes back as a new stream emission, never as the write's
return value.

The schema does not change — `Categories` and `Subcategories` have existed since FEAT01, so
`schemaVersion` stays 1 and no new migration snapshot is produced. What lands is the second
DAO, the second Notifier and the second screen in the app.

**FR-10's "exactly two levels" is built by not building a third.** It is structural — two
tables, not a self-FK (ERD D6, `decisions.md` 2026-08-19) — so no code checks depth and
nothing ever refuses a nesting attempt, because no control offers one.

Nothing in the accounts, budgeting or settings modules is touched, and no amount is read,
written or displayed anywhere in this issue.

## Scope: the sequence diagram, reconciled

`docs/diagrams/seq-uc13-categories.drawio`, render committed at
`pm/issues/uc13-categories/seq-uc13-categories.png` and **read at full size while writing
this plan** (`lessons.md` §3/§4 — the labels live on `<UserObject label=…>` wrappers, so a
regex over `mxCell value=` returns nothing and would have been read as an unlabelled
skeleton). `CLAUDE.md` makes this diagram the scope boundary: nothing outside it is in
scope, nothing in it may be skipped.

**Six lifelines, and every one is already a class on a class diagram** — the hard rule in
`context/document-writer-only/sequence-conventions.md`, and the check that caught a real
defect once (`lessons.md` §10). All five non-actor lifelines are on
`docs/diagrams/class-transactions.drawio`:

| Lifeline | On `class-transactions.drawio` as | Band |
|---|---|---|
| `Owner` | the actor (the only one in this project) | — |
| `CategoryManagerScreen` | `CategoryManagerScreen` · UC-13 · `ConsumerWidget` | Screen |
| `categoryTreeProvider` | `categoryTreeProvider` · `StreamProvider` · category + subcategory tree | Provider |
| `CategoriesNotifier` | `CategoriesNotifier` · Notifier, exposed as `categoriesProvider` · UC-13 · `add()` · `rename()` · `remove()` | Provider |
| `CategoryDao` | `CategoryDao` · categories + subcategories · `watchTree()` · `insert()` · `update()` · `delete()` | DAO |
| `AppDatabase` | `AppDatabase` · the single drift database shared by all four modules | Database |

**No lifeline is missing and none is invented.** Nothing in this issue needs a class the
diagrams do not have — which is exactly the check that failed for this issue's *previous*
scope and produced the re-scope (`decisions.md`, 2026-08-21, "Budget group CRUD belongs to
UC-11, not UC-13"): `CategoryManagerScreen` had no budget-group counterpart on any diagram.
The diagram as it now stands draws no budget group at all.

**The twenty-three messages, and what each commits this issue to:**

- **1** `Owner → CategoryManagerScreen` *opens category and subcategory setup* — the screen
  has to be openable (D3).
- **2** `categoryTreeProvider ⇢ CategoryManagerScreen` *category / subcategory tree (first
  emission)* — the screen renders a watched stream and holds no list of its own.
- **3–8** the create-a-category path: `Owner → Screen` *adds a category* → `Screen →
  CategoriesNotifier` *add(name)* → `→ CategoryDao` *insert(name)* → `→ AppDatabase`
  *insert(name)* → *row inserted* → **8** `categoryTreeProvider ⇢ Screen` *tree updated (new
  category)*. Note **8 comes from the provider, not from the notifier**: the result arrives
  on the read path (`riverpod.md`, "the rule that is easiest to get wrong").
- **9–14** the `opt` fragment, guarded *[[owner adds a subcategory under a category (FR-10 —
  exactly two levels, no further nesting)]]* — the same chain with `add(categoryId, subName)`
  / `insert(categoryId, subName)`, ending in **14** *tree updated (new subcategory)*. The
  guard is a plain "if the owner does this", not a precondition anything evaluates: adding a
  subcategory is optional because a category may stand alone.
- **15–18** the first `alt` operand, *[[owner renames a category or subcategory (FR-18)]]* —
  `rename(id, newName)` → `update(id, newName)` → `update(id, newName)` → *row updated*.
- **19–22** the second operand, *[[owner deletes a category or subcategory (FR-18)]]* —
  `remove(id)` → `delete(id)` → `delete(id)` → *row deleted*.
- **23** `categoryTreeProvider ⇢ Screen` *tree updated* — **outside the `alt`**, so both
  operands land on the same single re-emission. There is no reply arrow from
  `CategoriesNotifier` back to the screen anywhere on the diagram.
- The diagram's note: *DAO to AppDatabase crosses the isolate boundary.*

**Both `alt` operands name "a category **or** subcategory" and use one method name for
both.** That is the source of D5's parameter shape: the ERD has two tables, so a bare `id`
cannot say which one is meant.

### Two findings, for the as-built pass at close — not fixed now

1. **The read path is not drawn.** Messages 2, 8, 14 and 23 all show `categoryTreeProvider`
   emitting a tree, but the diagram contains **no `categoryTreeProvider → CategoryDao
   watchTree()` message and no `CategoryDao ⇄ AppDatabase` query pair** — the four messages
   `seq-uc14-choose-currency.drawio` draws explicitly for the same chain. The wiring is
   therefore *implied by four emissions that cannot happen without it*, and it is drawn on
   `class-transactions.drawio` as the `categoryTreeProvider → CategoryDao` edge with
   `watchTree()` on the DAO box. Building it is not widening scope — a provider that emits
   four times must be watching something — but **the diagram should gain those messages in
   the as-built pass**, and this plan records the gap rather than silently filling it
   (`lessons.md` §11, and `general-rules.md`: state the tension, do not quietly apply the
   better-seeming answer).
2. **The isolate note is one wrapper stale.** It reads *"NativeDatabase.createInBackground,
   2026-08-20"*; the code opens the database through `drift_flutter`'s `driftDatabase()`,
   which calls `NativeDatabase.createBackgroundConnection` — the same isolate guarantee,
   verified in the package source (`decisions.md` 2026-08-21, FEAT01 ruling 2). The boundary
   the note marks is real and in the right place; only the mechanism's name is stale. Same
   finding `UC14`'s plan recorded against its own diagram, so it is a repo-wide diagram
   nit, not a UC-13 defect.

**One register checked and found *not* stale**, recorded because the tracker warned it might
be: `docs/workbook.xlsx` UC-13 is already re-titled *"Set Up Categories and Subcategories"*,
and its `Deskripsi` mentions budget groups only to say UC-11 owns them, citing the owner's
2026-08-21 ruling. `Entity/Objek Terkait` is `Category, Subcategory`. Nothing to correct.

## Decisions

Each entry cites the confirmed artifact it is transcribed from. **None of them is a new
choice**; where a choice appeared to exist, the entry names what eliminated the
alternatives.

### D1 — The three new files, two modified files, two test files, and nothing else

*Cites:* `context/coding-conventions/dart-and-flutter.md` §Directory layout (one file per
class-diagram band; `<name>_dao.dart`, `<module>_providers.dart`, `<name>_screen.dart`;
package rooted at `app/`); `class-transactions.drawio` for which classes exist;
`testing.md` §Conventions (tests mirror `lib/src/`).

```
app/lib/src/transactions/category_dao.dart               CategoryDao — watchTree(), insert(), update(), delete()
app/lib/src/transactions/transactions_providers.dart     categoryTreeProvider (StreamProvider),
                                                         CategoriesNotifier (exposed as categoriesProvider)
app/lib/src/transactions/category_manager_screen.dart    CategoryManagerScreen (ConsumerWidget)

app/test/transactions/category_dao_test.dart
app/test/transactions/category_manager_screen_test.dart
```

Modified, not created:

- `app/lib/src/database/app_database.dart` — register the accessor under
  `@DriftDatabase(… daos: […])`, which is how drift attaches one. **The table list, the
  `schemaVersion` and the `beforeOpen` seeding are untouched.**
- `app/lib/src/app.dart` — `home` (D3).

**`app/lib/src/transactions/transactions_table.dart` is not modified.** `Categories` and
`Subcategories` already exist exactly as the class diagram draws them, and the generated row
classes are already `Category` and `Subcategory` (checked in `app_database.g.dart`, so no
`@DataClassName` annotation is needed). A file outside this list is out of scope; adding one
is a conversation, not a judgement call — the shape FEAT01 D2 used.

### D2 — Class, method and provider names come from the class diagram verbatim

*Cites:* `context/coding-conventions/README.md`, "the rule that outranks the rest" — *class
names in code must match the class diagrams exactly*; `class-transactions.drawio`.

`CategoryDao` with exactly `watchTree()`, `insert()`, `update()`, `delete()`.
`CategoriesNotifier` with exactly `add()`, `rename()`, `remove()`, exposed as
`categoriesProvider`. `categoryTreeProvider` as a `StreamProvider`. `CategoryManagerScreen`
as a `ConsumerWidget`. **No extra public method on any of them** — a method the class diagram
does not draw is a diagram change, not a code decision.

`watchTree()` returns a stream; the writes return `Future<void>` (`drift.md` §DAOs — *writes
return `Future<void>` unless the caller genuinely needs the new id*, and no message on the
sequence diagram carries an id back to the screen).

**One toolchain contingency, decided in advance so it is not decided at the keyboard.**
`riverpod.md` prefers `@riverpod` code generation, and `riverpod_generator` derives the
provider's name from the class's. If it yields `categoriesNotifierProvider` rather than the
`categoriesProvider` the class diagram names, **the class diagram wins**: the notifier is
then exposed by a hand-written `NotifierProvider` named `categoriesProvider`, the same
precedent FEAT01 set for `appDatabaseProvider` (`decisions.md` 2026-08-21, ruling 3), and
`riverpod.md` is corrected in place with the reason (step 9). *Anything that fights the real
toolchain loses* — `coding-conventions/README.md`.

### D3 — `CategoryManagerScreen` is what `app.dart` shows, temporarily

*Cites:* the sequence diagram, message 1 (the owner opens this screen); FEAT01 D2/D5 —
`app.dart` renders a placeholder and the first real screen belongs to a use-case issue;
`coding-conventions/README.md` (a class the diagrams lack may not be written); FR-1 (*"the
primary screen — not a report behind a menu"* is the balance sheet, i.e. UC01's).

Message 1 requires the screen to be openable. The diagram draws **no navigation lifeline** —
no home shell, no menu, no route table — and **no class diagram in the project has one**. So
the only way to satisfy message 1 without inventing a class is for `MaterialApp.home` to be
`CategoryManagerScreen`, replacing FEAT01's placeholder. Forced derivation, not preference —
the identical derivation `UC14`'s D3 made for `CurrencyScreen`.

**The cost, stated before the work rather than after (`lessons.md` §7):** this app has no
navigation host, so exactly one screen is reachable at a time. When UC14 is unhalted it will
re-point `home` at `CurrencyScreen` and this screen becomes unreachable in a running app
until `UC01-balance-sheet` lands FR-1's primary screen and whatever gets to it. That is a
real consequence and it is flagged as the first non-blocking open question below rather than
being solved here by building a router nobody has specified.

### D4 — The tree is Dart collections over drift's generated row classes

*Cites:* `class-transactions.drawio` (`categoryTreeProvider` · *category + subcategory
tree*, and the note *"drift also generates a row class … Omitted here by decision — only
hand-written classes get a box"*); `coding-conventions/README.md` (no class the diagrams
lack); FR-10 (two levels).

`watchTree()` returns `Stream<Map<Category, List<Subcategory>>>`, where `Category` and
`Subcategory` are drift's generated row classes (both already generated under those exact
names). A category with no subcategories appears with an empty list, so the screen can show
it and offer a subcategory under it.

**A `CategoryNode` / `CategoryTree` holder class is explicitly not written.** It would be a
hand-written class no class diagram has, which `README.md`'s outranking rule makes a finding
to raise, not a step to take. If the code genuinely cannot express the tree without one,
**that is a finding for `pm/findings.md` and a diagram question — not a class to add and
move on from.**

Implementation shape (mechanics, not a decision — `pm/questions.md`, "what does not belong
here"): one query joining `Categories` to `Subcategories` with a left outer join, folded
into the map, watched once. Two independently watched streams would be two sources for one
render.

**Ordering: none is imposed beyond the primary key.** No artifact states an order — not
FR-10, not the workbook row, not the diagram — so this plan does not invent one; rows come
back in `category_id` / `subcategory_id` order, which is the order the owner created them in
and is deterministic enough to assert in a test. Alphabetical ordering would be a display
rule nobody has asked for; see the second non-blocking open question.

### D5 — One method name per verb, with the parameter that says which table

*Cites:* the sequence diagram — message 5 `insert(name)` **and** message 12
`insert(categoryId, subName)` are the same method at two arities, and both `alt` operands
apply `update` / `delete` to *"a category **or** subcategory"*; `erd.drawio` and
`transactions_table.dart` (two tables, each with its own autoincrementing key, so a bare
`id` does not identify a row); `dart-and-flutter.md` §Naming (Dart has no overloading; named
parameters, `lowerCamelCase`).

- `insert({int? categoryId, required String name})` — `categoryId == null` inserts a
  category, otherwise a subcategory under that category. This is exactly the two arities the
  diagram draws.
- `update({required int id, required bool isSubcategory, required String name})`.
- `delete({required int id, required bool isSubcategory})`.
- `CategoriesNotifier.add()` / `rename()` / `remove()` take the same parameters and forward
  them.

The discriminator is a named `bool`, **not a new enum type** — an enum would be a type the
class diagrams do not have (D4's rule), and Effective Dart's objection is to *positional*
booleans, which these are not. The screen always knows which level a node is, because the
tree it renders is keyed by category with subcategories nested under it (D4).

### D6 — Deleting a category deletes its subcategories; deleting either leaves the transactions standing and blanks their tags

*Cites:* NFR-4's fit criterion — **zero** refused user actions, strengthened 2026-08-20 from
one to zero (`fr-nfr.md` §2; `decisions.md`, "No guardrails"); FR-18 (full CRUD, *"no entity
has an exception"*); FR-10 (*"I can tag what I record with a category, a subcategory, and a
budget group, **and any of them can be left blank**"*); `erd.drawio` and
`transactions_table.dart` — `Transactions.category_id` and `Transactions.subcategory_id` are
**nullable** FKs while `Subcategories.category_id` is **not null**; `testing.md` §Two
requirements ("deleting an account that has transactions" must proceed).

This is the one place in the issue where an outcome could have been invented, so every
alternative is named with what eliminates it:

| Outcome | Status |
|---|---|
| Refuse the delete while anything references it | **Forbidden.** NFR-4's count is zero and there is no longer a sanctioned exception to argue similarity to. |
| Leave `Transactions.category_id` pointing at a deleted row | **Not representable as a design.** The ERD draws the FK; a dangling id makes the tag unreadable. |
| Cascade-delete the referencing transactions | **Excluded.** Deleting a *tag* would silently change FR-1's four figures and destroy records FR-18 gives their own correction use case (UC-09). The diagram deletes one thing and re-emits **the tree** — no transaction is touched anywhere on it. |
| Re-parent orphaned subcategories somewhere | **Nowhere to put them.** `Subcategories.category_id` is NOT NULL, and this project has already ruled that the analogous catch-all is *the null FK, not a row* (`decisions.md` 2026-08-19: *"Others" is the null `budget_group_id`, not a row that could be renamed or deleted*). |
| **Delete the children; null the tags; keep the transactions** | **The only outcome left**, and it lands in a state FR-10 already declares legal — a transaction with a blank category is normal, not damaged. |

So `delete()` runs as one drift transaction:

- **subcategory** — set `subcategory_id = NULL` on transactions referencing it, then delete
  the row.
- **category** — set `category_id = NULL` and `subcategory_id = NULL` on transactions
  referencing the category or any of its subcategories, delete the subcategories, then
  delete the category.

Both statement orders are written explicitly rather than left to SQLite's FK actions, so the
behaviour does not depend on whether `PRAGMA foreign_keys` is on — it is not set anywhere in
`app_database.dart` today, and turning it on is a database-wide change no artifact asks for
(out of scope, below). `CategoryDao`'s `@DriftAccessor` therefore lists `Transactions`
alongside `Categories` and `Subcategories`; all three are the same module's tables, and
`drift.md` §DAOs permits a DAO to reach another module's tables in any case.

**In practice this path deletes nothing but tags for now**: no insert path for
`Transactions` exists until `UC04-record-money-movement`, so the only rows exercising it are
the ones the D8 tests insert directly. That is a reason to test it, not a reason to leave it
undecided — `lessons.md` §2 is what happens when the behaviour behind a value is settled
late.

### D7 — Nothing on this screen warns, and nothing on it is ever disabled

*Cites:* the sequence diagram — the only `opt` fragment on it guards *adding a subcategory*,
and the delete operand (19–22) carries **no warning fragment, no confirmation and no second
operand**, in a project whose author demonstrably draws an `opt` warning when one is wanted
(`seq-uc14-choose-currency.drawio`, message 9); NFR-4 (*warning at most* — permitted, never
required); `riverpod.md` §No refusals (*a notifier method does not have an early return that
silently declines … a screen does not disable a control*); `testing.md` (*a disabled button
is the likeliest accidental violation in the whole app*).

Every control on `CategoryManagerScreen` — add, rename, delete, at both levels — is enabled
at all times, including for a category that has subcategories and for one that transactions
reference. There is no confirmation dialog, no "cannot delete, in use" message, no greyed
row, and no empty-state that hides the add control.

**FR-10's two levels are enforced by absence, not refusal.** A subcategory row offers rename
and delete and *no* "add subcategory" control, so a third level is never attempted and
therefore never refused. This is the distinction `decisions.md` draws explicitly when it
kept FR-10 through ISSUE-004: *this project's "no guardrails" rule is about refusing user
actions, not about the absence of all structure.*

### D8 — "Done" without a runnable app, and what the tests must assert

*Cites:* FEAT01 D7 (the same four commands, the same reason — no Android SDK on this
machine); `tooling.md`; `testing.md` §Layers, §Two requirements that need explicit tests,
§Running; `decisions.md` 2026-08-21 (`app/ios/` cannot be built, no Mac).

**The app cannot be launched or looked at, and nothing in this definition of done requires
it.** `flutter test` is headless and needs no Android SDK, and `testing.md` puts the
correctness surface there. If a step ever seems to need a running app, that is a scope error,
not a reason to install an SDK.

Done is all four green, run from `app/`:

1. `dart run build_runner build` — succeeds. (`--delete-conflicting-outputs` was removed in
   `build_runner` 2.16 and is now ignored with a warning — `testing.md`, corrected at
   FEAT01.)
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under `strict-casts` / `strict-inference` / `strict-raw-types`.
   A warning left in place is a decision, and gets argued here rather than ignored.
4. `flutter test` — green, against `NativeDatabase.memory()`, a fresh database per test, no
   mocking of drift.

Tests to add, each **named for the requirement it defends** (`testing.md` §Conventions):

*`category_dao_test.dart`* —

- `watchTree()` emits an empty map on a fresh database (the empty state is a real screen on
  day one).
- Inserting a category produces an emission containing it with an **empty** subcategory list;
  inserting a subcategory produces a further emission with it nested under its parent —
  **the same stream, a second emission.** This is the assertion that proves messages 8/14/23
  work, and it is the most valuable test in the issue because the whole architecture rests
  on the read path.
- **FR-10:** a subcategory is reachable only under its category, and `Subcategories` has no
  column that could point at another subcategory. Structural, asserted once.
- **FR-18:** a category and a subcategory are each renamed and each deleted — the explicit
  per-entity edit/delete test `testing.md` requires so nothing quietly ends up create-only.
- **D6:** deleting a category also removes its subcategories; a transaction tagged with that
  category **still exists** afterwards with `category_id` and `subcategory_id` null.
  Deleting a subcategory nulls only `subcategory_id` and leaves `category_id` intact.

*`category_manager_screen_test.dart`* —

- The screen renders whatever `categoryTreeProvider` is overridden to emit, via a
  `ProviderScope` override over an in-memory database.
- **NFR-4:** with a category that has subcategories and with transactions referencing it, the
  add, rename and delete controls are **enabled**, and delete proceeds. No disabled control
  anywhere on the screen.
- A subcategory row offers **no** control that would create a third level (D7).

## Steps

In dependency order.

1. Write `category_dao.dart`: `CategoryDao` as a drift `DatabaseAccessor` over `AppDatabase`
   with `@DriftAccessor(tables: [Categories, Subcategories, Transactions])`. `watchTree()`
   per D4; `insert()`, `update()`, `delete()` per D5, with `delete()`'s statement order per
   D6, wrapped in one drift transaction.
2. Register the accessor on `AppDatabase` (`@DriftDatabase(… daos: [CategoryDao])`) and
   re-run the generator. **This is the only edit to `app_database.dart`** — the schema does
   not change, `schemaVersion` stays 1, and no new snapshot is produced (`drift.md`
   §Migrations: snapshots record real change, not our own re-runs).
3. Write `transactions_providers.dart`: `categoryTreeProvider` as a `StreamProvider` over
   `watchTree()`, and `CategoriesNotifier` exposed as `categoriesProvider`, whose `add()`,
   `rename()` and `remove()` call the DAO and **return nothing to the screen** (D2, and
   `riverpod.md`'s read/write asymmetry). Default `autoDispose` is correct here — this
   provider's state does not outlive its screen, unlike the currency.
4. Write `category_manager_screen.dart`: `CategoryManagerScreen` as a `ConsumerWidget`
   watching `categoryTreeProvider`, rendering categories with subcategories nested one level
   under, every control always enabled (D7), each action firing
   `ref.read(categoriesProvider.notifier).…` and never rendering its return value.
5. Point `app.dart`'s `home` at `CategoryManagerScreen`, removing FEAT01's placeholder (D3).
6. Write the tests in D8, each named for the requirement it defends.
7. Run all four D8 commands from `app/`. Fix, repeat until clean. Run them **before** the
   commit, not after — CI runs all five steps on every push since FEAT01 landed
   (`testing.md`), and a first red build on this commit is avoidable.
8. `python audit.py` from the repository root — it was green at 13/0/0 before this issue and
   must still be. It proves consistency, never correctness (`lessons.md` §12).
9. **Correct every conventions file this contradicted.** This is the first issue to write a
   DAO, a Notifier, a screen and a widget test — the half of `context/coding-conventions/`
   its README still marks unverified. Anything that fights the real toolchain loses, gets
   corrected in place, and is recorded in `pm/log.md`. D2's provider-naming contingency is
   the likeliest.
10. **Split the README's provisional banner again rather than re-broadening it.** After this
    issue the DAO, provider, screen and widget-test claims are verified; the cross-module
    join and the derived-figure queries are still not. `lessons.md` §1: *a half-true label is
    the most durable version of this failure*, and that banner has already been caught being
    half true once. Note that `README.md` names **UC14** as the issue that tests this half —
    UC14 is halted and UC13 got there first, so that sentence goes stale with this issue and
    is part of this step.
11. Close per `CLAUDE.md`'s checklist. Named explicitly because `lessons.md` §1 is about
    registers nobody remembers to update:
    - **As-built pass** on `seq-uc13-categories.drawio`, covering **both findings above** —
      the missing `watchTree()` read path and the stale isolate-note mechanism. Re-export to
      PNG and **look at the render**; do not edit XML and call it done (`lessons.md` §3), and
      re-export after every fix because a fix can make it worse. Refresh the committed copy
      at `pm/issues/uc13-categories/seq-uc13-categories.png` and `renders.lock`.
    - **`context/index/map.yaml`** — a `UC-13 → app/lib/src/transactions/` entry under
      `code:`, in the shape FEAT01's entry uses.
    - **`context/index/decisions.md`** — only if the toolchain forced a durable ruling, as it
      did three times in FEAT01. Not a formality, and not an obligation either.
    - **`docs/workbook.xlsx`** UC-13 marked implemented (`general-rules.md`, definition of
      done, step 4). Its text needs no other edit — checked, see *Scope*.
    - **`pm/tracker.yaml`** → Done with a one-line summary; **`pm/log.md`** → a dated entry
      plus the current-state block at its head; **`pm/active.json`** → the next issue
      (`UC11-set-budget` is the only remaining row whose dependencies are satisfied while
      UC14 stays halted).
    - **This file** → status `done`, so a tracker row saying DONE never sits above a plan
      still claiming work is in progress (`lessons.md` §11).

## Out of scope

- **Budget groups, entirely.** Creating, renaming, deleting or setting an amount for a
  `Budget_Group` moved to `UC11-set-budget` on 2026-08-21 (`decisions.md`; `pm/tracker.yaml`,
  both rows). `BudgetGroups` is not read or written here, `class-budgeting.drawio` is not
  touched, and no budget group appears on `seq-uc13`. If a step here seems to need one, that
  is the re-scope being undone by accident.
- **Applying a category to a transaction.** FR-10's tags are *offered* by the record form,
  which is `UC04-record-money-movement`'s (`fr-nfr.md` §5: UC-13 defines the tags, UC-04/05
  apply them). This issue builds no picker and touches no record screen.
- **Every other module and DAO.** No `AccountDao`, `TransactionDao`, `BudgetDao` or
  `SettingsDao`; no screen but `CategoryManagerScreen`. `CategoryDao` reads and writes
  `Transactions` only for D6's tag-blanking, and only for the rows the deleted tag points at.
- **Any currency display or amount formatting.** Nothing on this screen shows money. The
  currency chain is `UC14`'s and it is halted (`pm/questions.md` Q1); this issue neither
  depends on it nor pre-empts it.
- **Routing, navigation, a settings hub, or an app shell.** D3 points `home` at this screen
  and introduces nothing else. The permanent primary screen is UC01's, per FR-1.
- **Any schema change.** `Categories` and `Subcategories` land as FEAT01 built them.
  `schemaVersion` stays 1, no new snapshot, no migration — and if something here seems to
  need a column, `lessons.md` §8 is the cost estimate to bring back first (the last "just one
  column" touched twelve artifacts).
- **Turning `PRAGMA foreign_keys` on.** It is off today and no artifact asks for it. D6's
  deletes are explicit and behave identically either way; flipping it is a database-wide
  change affecting all seven tables and could turn some future write into a *refusal*, which
  is an NFR-4 question and deserves its own issue.
- **Reordering, sorting, searching, filtering, merging or bulk-editing categories.** None is
  on the diagram, in FR-10/FR-18, or in the workbook row. *Reviewing the past* — searching
  and filtering — is explicitly deferred in `fr-nfr.md` §3.
- **A colour, an icon, an "archived" flag or any other category attribute.** `Category` is
  `category_id` + `name` on the ERD. Anything more is a schema change and a new FR.
- **Seeding a starter vocabulary.** FEAT01 deliberately seeded no categories precisely so as
  not to prejudge this issue (FEAT01, Out of scope). This issue does not seed one either:
  no FR asks for it, and inventing one would be the app deciding what the owner's categories
  are — the same reasoning `decisions.md` used to refuse backfilling skipped budget months.
- **Fixing `pm/findings.md` F1** (the table-existence test reads drift's declared
  `allTables` rather than the SQLite schema). Recorded, not fixed; a finding is not an issue,
  per the run's own rule.
- **Editing any `.drawio` now.** The two findings above are reconciled in the as-built pass
  at close (step 11), not mid-flight.
- **Installing the Android SDK, launching the app, or any visual check of the screen** (D8),
  and **anything iOS** — `app/ios/` stays versioned and uncompiled until there is a Mac.

## Open questions

**None blocks this issue.** Both are consequences worth the owner's attention, and both have
a defined default that this plan states rather than leaves to the coder.

1. **The app has no navigation host, so exactly one screen is reachable at a time.** D3
   points `home` at `CategoryManagerScreen` because message 1 requires the screen to be
   openable and no navigation class exists on any diagram. When `UC14` is unhalted its D3
   re-points `home` at `CurrencyScreen` and this screen becomes unreachable in a running app
   until `UC01-balance-sheet` lands FR-1's primary screen. **If the owner wants a shell,
   drawer or route table sooner, it needs a class on a class diagram before it can be
   written** (`coding-conventions/README.md`) — i.e. its own issue, not a step here.
2. **Deleting a category blanks the tag on every transaction that used it, without warning.**
   D6 derives this and D7 derives the silence, both from confirmed artifacts, and no other
   outcome is representable. But the owner has never been shown that sentence. If a warning
   *is* wanted ("30 transactions will lose this tag — continue"), NFR-4 permits it, it is
   cheap, and it costs an `opt` fragment on `seq-uc13` plus a dialog — an addition that
   refuses nothing. Raised now rather than after the work (`lessons.md` §7).
3. **Category ordering is insertion order** (D4), because no artifact states one.
   Alphabetical is a one-line change to a single `orderBy` if the owner prefers it.

The two rulings still outstanding in `pm/active.json` — the application id, and the
`moneytracker` / `uangsaku` split — **do not gate this issue**, which renames nothing and
creates no platform artifact. `pm/questions.md` **Q1** (the currency-change warning) does not
gate it either: UC-13 sits on the other chain and touches no `Settings` row.
