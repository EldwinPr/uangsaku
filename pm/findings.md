# Findings

**The unattended run's output.** After the last issue closes, two `repo-qa` sweeps run —
one over the app, one over the paper trail — and write what they find here. **Then the run
stops.** Nothing is fixed, no issue is reopened.

That stop is deliberate. A cross-cutting finding often needs a decision only the owner can
make, and a run that starts reopening closed issues churns without converging. **This file
is what the owner reads when they come back** — a clear list beats a repo quietly edited
toward one agent's judgement.

Distinct from its neighbours: `pm/questions.md` holds questions that **blocked** work before
it happened; this holds problems found in work **already done**. An entry here never gates
anything — it is a report, not a queue.

## Format

```
## F{N} — {one-line finding}                    [OPEN | ACCEPTED | FIXED | WONTFIX]
**Scope:** APP | TRAIL          **Severity:** defect | risk | improvement
**Where:** file:line, or the artifact
**Violates:** the rule, decision or requirement — by name
**What it is:** what is wrong, and what it causes. Not how to fix it.
**Confidence:** certain | likely | worth checking
```

**Severity is whether it is wrong, not how hard it is to fix.**

- **defect** — breaks a stated requirement or a recorded decision. A `double` holding money,
  a disabled control against NFR-4's zero refusals, a diagram that no longer matches code.
- **risk** — not wrong today, but a trap. A duplicated query that will drift, a convention
  that slipped partway through.
- **improvement** — better if changed, wrong in no sense.

Keep the three separate. Forty style notes bury two real defects, and this list exists to
decide what happens next.

## Resolving

The owner reads, then either promotes a finding to a tracked issue in `pm/tracker.yaml`
(where it gets a plan like any other work) or marks it `WONTFIX` with a reason. **A defect
resolved by a decision rather than a change is still resolved** — record which.

`lessons.md` applies here too: if a finding is another occurrence of a pattern already in
that file, add it there as evidence. The pattern is worth more than the individual fix.

---

*Phase 2 has not run yet. The entry below was filed during phase 1, by `issue-qa` at an
issue close, under the third option in its brief: not certain enough to reject, not certain
enough to wave through silently.*

## F1 — the "all seven tables exist" test reads drift's declared tables, not the database   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/test/database/app_database_test.dart`, the `FEAT01: all seven tables exist` test
**Violates:** nothing stated. It is the shape `lessons.md` §5 describes — a check whose subject
is not quite the thing it is named for.
**What it is:** the test asserts over `database.allTables`, which is generated from the
`@DriftDatabase(tables: [...])` annotation and never touches SQLite. It does catch the failure
that can realistically happen — a table declared but left out of the annotation — and a
sibling test does query real SQL, so the schema is proven to be created. But the assertion as
named ("the tables exist") would hold even if nothing had been created, and it is the pattern
that has produced four green-for-the-wrong-reason results on this project. `sqlite_master`
would answer the question the name asks.
**Confidence:** worth checking — whether this matters depends on what the rest of the suite
looks like once DAO tests exist, which is not visible from one issue's diff.

*F2 and F3 were filed at `UC13-categories`' close, by `issue-qa`, for the same reason as F1
— and because `issue-qa` may not edit a `.drawio` itself.*

## F2 — `seq-uc13-categories.drawio` does not draw the read path the code has   [FIXED]
**Scope:** TRAIL          **Severity:** defect
**Where:** `docs/diagrams/seq-uc13-categories.drawio` (and its render at
`pm/issues/uc13-categories/seq-uc13-categories.png`)
**Violates:** `CLAUDE.md` close-checklist step 1 (the as-built reconcile) — a sequence
diagram that disagrees with the code it specifies.
**What it is:** messages 2, 8, 14 and 23 all show `categoryTreeProvider` emitting the tree,
but the diagram carries **no `categoryTreeProvider → CategoryDao.watchTree()` message and no
`CategoryDao ⇄ AppDatabase` query pair** — the four messages `seq-uc14-choose-currency`
draws for the identical chain. The code built that path (authorised by the plan, which cites
`class-transactions.drawio`'s `categoryTreeProvider → CategoryDao` edge and records the gap
rather than filling it silently). The code is right and the diagram is incomplete, so the
**diagram** is what needs to change: four messages added, re-exported to PNG, the render
**looked at** (`lessons.md` §3), and `pm/issues/uc13-categories/seq-uc13-categories.png` plus
`renders.lock` refreshed. `issue-qa` did not do it because sequence diagrams are authored as
Mermaid and converted by `diagram-drawio-author`, never as hand-written XML
(`sequence-conventions.md`), and because a reviewer that repairs what it reviews has stopped
being a reviewer. **Dispatch `diagram-drawio-author`.**
**Confidence:** certain — verified by extracting every label from the file at close; the six
lifelines and twenty-three messages are as the plan describes and the read path is absent.
**FIXED 2026-08-22**, in the main session rather than by `diagram-drawio-author` — the owner
directed mid-run that diagram work and QA stop going to subagents. Re-authored in Mermaid and
converted with the draw.io CLI per `sequence-conventions.md`; **not** hand-edited XML. The
read path is now **five** messages, not the four this entry predicted: `seq-uc14` also draws
`Screen → provider: watch()`, which the first draft omitted, so matching that chain honestly
needed the fifth. All twenty-three original messages and both fragment guards survive
unchanged; the diagram now numbers 1–28. The isolate note on **this** diagram was corrected
in the same pass (F3's scope drops from fourteen copies to thirteen). Render re-exported,
`grep -c '<!--'` = 0, `audit.py` 13/0/0, `renders.lock` refreshed via
`audit.py --record-renders`. **The PNG was looked at** at full-diagram zoom and at two tight
crops: the `opt` box's top border was checked to fall *below* message 13 rather than
enclosing it, and the note was checked pixel-wise at the right margin for clipping — the last
two pixel columns are blank, so it is complete.

## F3 — every sequence diagram's isolate note names a mechanism one wrapper stale   [OPEN]
**Scope:** TRAIL          **Severity:** risk
**Where:** eleven of the fourteen `docs/diagrams/seq-uc*.drawio` — the note reading *"DAO to
AppDatabase crosses the isolate boundary (NativeDatabase.createInBackground, 2026-08-20)"*
**Violates:** nothing stated; it is `lessons.md` §1's half-true label, in fourteen copies.
**What it is:** the code opens the database through `drift_flutter`'s `driftDatabase()`,
which calls `NativeDatabase.createBackgroundConnection` (`decisions.md` 2026-08-21, FEAT01
ruling 2, checked in the package source). **The boundary the note marks is real, is in the
right place, and the guarantee is unchanged** — only the mechanism's name is stale. Both the
UC-13 and UC-14 plans recorded it against their own diagram before noticing it is on all
fourteen, i.e. it is a repo-wide nit and not one issue's defect. Fixing it inside UC-13
would have meant editing thirteen diagrams UC-13 does not own, so it is filed instead.
**Confidence:** certain — `grep -rl createInBackground docs/diagrams/` returned all fourteen
when this was filed.
**Narrowed 2026-08-22:** `seq-uc13-categories.drawio` corrected as part of F2's as-built
pass, because UC-13 owns that diagram.
**Narrowed again 2026-08-22:** `seq-uc11-set-budget.drawio` in UC-11's as-built pass, then
`seq-uc14-choose-currency.drawio` in UC-14's, then `seq-uc02-add-account.drawio` and
`seq-uc01-balance-sheet.drawio` at their closes, then `seq-uc10-debt-progress.drawio` in
UC-10's.
**Nine remain**, one per unbuilt issue, each to be corrected by its own as-built pass at
close. They stay filed rather than fixed — the run does not repair findings, and each
belongs to an issue that has not been built yet. Anything still stale when the backlog
finishes is a real leftover; anything fixed before then costs nothing.

## F4 — the NFR-4 enabled-controls test can pass vacuously for the rename control   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/test/transactions/category_manager_screen_test.dart`, the `NFR-4: add, rename
and delete stay enabled…` test
**Violates:** nothing stated. It is the `lessons.md` §5 shape — a check that would stay green
if its subject vanished.
**What it is:** the test collects finders and asserts `onPressed` is non-null for each
matched element. Two of the three finders cannot be empty — `find.…(Icons.add).last` throws
on an empty match, and the delete finder is tapped with `.first` immediately afterwards, and
the delete is then proven by the row disappearing from the re-rendered tree, which is a real
end-to-end assertion. But the **edit** finder is only iterated: if the rename buttons ever
stopped rendering, that loop would run zero times and the test would still pass while its
name still claimed rename stays enabled. Not wrong today — the controls are all present and
the D7 test independently proves the subcategory row renders — so it is recorded rather than
sent back. A `findsNWidgets` count before the loop closes it.
**Confidence:** worth checking — whether it matters depends on how the other screens' NFR-4
tests end up written, which one issue's diff cannot show.

## F5 — the workbook has nowhere to mark a use case implemented   [OPEN]
**Scope:** TRAIL          **Severity:** risk
**Where:** `docs/workbook.xlsx`, sheet `UC FR` — columns are `Kode`, `Nama Use Case`, `User`,
`Modul`, `Input`, `Deskripsi`, `Output`, `Entity/Objek Terkait`
**Violates:** `context/general-rules.md`, Definition of "done" step 4 — *"the corresponding
workbook row marked as implemented, if the issue traces back to a UC."*
**What it is:** `UC13-categories` is the first issue on this project that traces to a UC and
reaches DONE, so step 4 applied for the first time — and there is **no column to write it
in**, nor any rule for one in `workbook-conventions.md`. `issue-qa` did not invent one:
adding a column to a client-facing workbook is a schema change that belongs to
`workbook-xlsx-author`, and `audit.py` asserts that sheet's shape. The consequence today is
mild (the tracker is the real implementation register and it is accurate) but it means a
step in the definition of done cannot be performed as written, and a step that silently
cannot be done is the shape `lessons.md` §5 warns about. Either add the column and a
convention for it, or amend step 4 to name the tracker — **one of the two, not neither.**
**Confidence:** certain that the column is absent; the right resolution is the owner's.

## F6 — the note on a Mermaid-generated sequence diagram overflows its own box   [FIXED]
**Scope:** TRAIL          **Severity:** defect
**Where:** `seq-uc13-categories.drawio` and `seq-uc11-set-budget.drawio` renders
**Violates:** `lessons.md` §3 — a render defect is only ever found by looking at the render.
**What it is:** a single-line `note over` whose text is long enough runs **past the right
edge of its own yellow rectangle** — the closing characters render outside the fill, on
white. Both isolate notes did this. It is a Mermaid layout quirk: the box is sized slightly
narrower than the text it holds.
**How it was found, and the check that missed it first:** the UC-13 render was checked at
close for *canvas clipping* — whether the rightmost pixel columns were blank — and passed,
because the text ends inside the canvas. That check was looking at the wrong set: nothing
was clipped, but the text had still escaped its container. It surfaced only when the same
note was drawn wider on UC-11 and looked at up close. **This is `lessons.md` §5 in a render
check rather than in a script** — a check that passes for the wrong reason. Added there as
evidence.
**Fixed 2026-08-22** on both diagrams by splitting each note across two lines with `<br/>`,
re-exporting, and re-checking by counting dark pixels to the right of the note's fill
rather than at the canvas edge: 0 on both.
**Confidence:** certain — measured, not eyeballed.

## F7 — a non-numeric budget amount is silently saved as zero   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/lib/src/budgeting/set_budget_screen.dart`, the save button's
`int.tryParse(_controller.text) ?? 0`
**Violates:** nothing stated. NFR-4 requires the save to proceed rather than refuse, and it
does — this is about *what* it proceeds to.
**What it is:** typing anything unparseable and pressing save writes a budget of **0**, with
no indication that the typed value was discarded. Zero is a legitimate budget, so nothing
downstream can tell an intended zero from a discarded "abc", and FR-15 will then pre-fill
next month from it. Refusing the save is not available (NFR-4's fit criterion is zero
refusals), so the question is which non-refusing behaviour is wanted — keep the previous
amount, treat empty as "no budget set" and delete the row, or write the zero and say so.
**That is the owner's call**, which is why this is filed rather than fixed.
**Confidence:** certain that it happens; worth checking whether it matters, since the same
parse will be needed by every amount field UC-04 introduces.
**Confirmed again 2026-08-22, UC02:** `AccountFormScreen` ships the same
`int.tryParse(...) ?? 0` (plan D7, following the shipped precedent deliberately rather than
inventing a validation rule NFR-4 would forbid). **The owner's ruling now covers two
screens**, and UC04's record form will make it the third unless it lands first.

---

*Phase 2 of the unattended run begins here. Findings F8–F13 come from the two end-of-run
sweeps — scope APP over the code as a whole, scope TRAIL over the paper trail — run in the
main session on 2026-08-22 rather than by `repo-qa` subagents, per the owner's direction.
Both sweeps ask questions per-issue review is structurally blind to: `issue-qa` sees one
diff against one plan, and whether three issues add up to one coherent app, or whether the
documentation still describes what was built, are properties of the whole.*

## F8 — every screen issue orphans the previous screen; UC-13's is now unreachable   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/lib/src/app.dart` — `home: const SetBudgetScreen()`
**Violates:** nothing stated. It is the accumulating cost of a decision each issue made
correctly in isolation.
**What it is:** this app has no navigation host, so `MaterialApp.home` is the only way to
reach a screen. UC-13 D3 pointed `home` at `CategoryManagerScreen`; UC-11 D8 re-pointed it
at `SetBudgetScreen`, exactly as UC-13 D3 said a later screen issue would. The consequence
is that **`CategoryManagerScreen` is now unreachable in the running app** — no route, no
reference from any live widget, exercised only by its tests. UC-13's delivered feature
cannot be used. Both issues documented this honestly and neither did anything wrong; the
problem is only visible across them. It compounds: UC-01, UC-02, UC-03, UC-04, UC-09 and
UC-12 each build a screen, and on the current pattern each one orphans the last, so the app
converges on one reachable screen and five dead ones. **The owner's call is whether a
navigation host becomes its own issue before the next screen lands** — it is on no class
diagram, so no issue can invent one without a ruling.
**Confirmed again 2026-08-22:** UC-14 D3 re-pointed `home` at `CurrencyScreen`, so
**`SetBudgetScreen` is now orphaned too** — two dead screens, one reachable, exactly as this
entry predicted. UC-14's plan named the cost in advance rather than rediscovering it, which
is the right handling, but it does not stop the count rising.
**Confirmed again 2026-08-22, UC02:** `home` re-pointed at `AccountFormScreen`, orphaning
`CurrencyScreen` — **three dead screens, one reachable**, five screen-building issues still
queued (UC01, UC03, UC04, UC09, UC12). The pattern is now three-for-three; the navigation
question is not going away and each remaining issue adds a screen to it.
**Confirmed again 2026-08-22, UC01 — with a difference:** `home` is now
`BalanceSheetScreen` **permanently** (FR-1: the primary screen, not a report behind a menu;
no planned issue draws a screen meant to displace it). `AccountFormScreen` is the **fourth
orphan**, after CategoryManager, SetBudget and Currency. The re-pointings are over; what
remains is four built features with no route, reachable only by tests.
**Confirmed again 2026-08-22, UC10 — a new form of the same:** `DebtDetailScreen` never
gets a route at all — it is reachable from nothing from birth, being a family-keyed detail
screen with no list screen to navigate from and no navigation host to host either. **Fifth
orphan**, and unlike the other four it was never reachable at any point. Remaining screen
issues (UC04's record form, UC09's list, UC12's consumption view) will each add another
unless the navigation ruling lands first — and UC09's list would have been the natural
host for this one.
**Confidence:** certain — `grep` for `CategoryManagerScreen` outside its own file and tests
returns only doc comments; the same is true of `SetBudgetScreen`, `CurrencyScreen`,
`AccountFormScreen` and now `DebtDetailScreen`.

## F9 — the app carries a codegen toolchain that three issues have proved it cannot use   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/pubspec.yaml` (`riverpod_annotation ^4.0.6` as a **runtime** dependency,
`riverpod_generator ^4.0.8` as a dev dependency) and `app/analysis_options.yaml:18`
(`invalid_annotation_target: ignore`)
**Violates:** nothing stated. FEAT01 D3 added the lint suppression saying it is required by
`riverpod_generator` "and there for no other reason."
**What it is:** **not one `@riverpod` annotation exists in this app**, and by recorded
decision none can: `riverpod_generator` throws `InvalidTypeException` on any provider typed
over a drift-generated row class (`decisions.md` 2026-08-21), and every read provider in
this app carries drift rows. All four providers are hand-written. So a runtime dependency, a
dev dependency and a lint suppression all persist to support a generator with nothing to
generate. Three costs, none fatal: `riverpod_annotation` ships in the built app for nothing;
the suppressed lint is a real check switched off app-wide for a reason that no longer
applies; and the next issue reading `pubspec.yaml` will reasonably assume `@riverpod` is the
house style and rediscover the failure. **Removing them is a decision, not a cleanup** —
if the owner expects a future non-drift provider, keeping them is defensible, but then the
`riverpod.md` note should say that is why.
**Confidence:** certain — no import of `riverpod_annotation` anywhere in `lib/` or `test/`.

## F10 — codegen and the five commands verified reproducible on a clean checkout   [ACCEPTED]
**Scope:** APP          **Severity:** improvement
**Where:** the whole `app/` package, at `9cad36d`
**Violates:** nothing — this is the sweep's negative result, recorded because a clean
checkout is the only thing phase 2 checks that no per-issue review does (`lessons.md` §5:
`renders.lock` once hashed raw bytes and would have read stale on CI and fresh locally).
**What it is:** cloned the repository to a fresh directory and ran the full sequence.
`flutter pub get` resolved; `dart format --set-exit-if-changed` 20 files 0 changed;
`flutter analyze` `No issues found!`; `flutter test` **31 passed**; `python audit.py`
13/0/0. `dart run build_runner build` wrote 42 outputs from cold and the regenerated
`app_database.g.dart` is **byte-identical** to the committed one (169,324 bytes, raw
comparison, not normalised). So the committed generated code is exactly what the generator
produces, and nothing in the working tree was load-bearing. `git status` does briefly show
the file as modified after a cold build — a stat-cache refresh, not a content change, since
`git diff` is empty and the raw bytes match.
**Confidence:** certain — measured on a clean clone, not on the working tree.

## F11 — `decisions.md` still calls open the very question `lessons.md` §1 was written about   [OPEN]
**Scope:** TRAIL          **Severity:** defect
**Where:** `context/index/decisions.md:107` — *"Naming still open — see `docs/fr-nfr.md` §4."*
**Violates:** `lessons.md` §1 — *a decision is not finished until every register that listed
it as open is updated*, in its mirror-image form: a document claiming something is **open
when it is settled.**
**What it is:** the credit/debit account naming collision. `decisions.md` sends the reader to
`fr-nfr.md` §4 to find it unresolved; **§4 records it as `Closed 2026-08-19`** — settled by
constraint, not preference, since NFR-1's fit criterion forbids a debit/credit column
outright, and `Account.group` has shipped as `HOLDING`/`RECEIVABLE`/`PAYABLE` since FEAT01.
So the pointer resolves to its own refutation, and a reader who trusts the first document
believes a shipped schema decision is still up for argument.
**Why it is worth its own entry:** this is *the* example `lessons.md` §1 opens with — it
"sat in `fr-nfr.md` §4 as 'undecided, blocking schema and UI naming' for a full day after it
was closed." That sweep fixed `fr-nfr.md` and **missed the mirror sentence in
`decisions.md`**, which has now outlived the fix by three days and a shipped schema. A
pattern already distilled into a lessons file recurred in the document the lesson is about.
The fix is one sentence, but the entry is the evidence.
**Confidence:** certain — both passages read end to end, and `erd.drawio` plus
`app/lib/src/accounts/accounts_table.dart` confirm which one is true.

## F12 — the orchestration guide describes a process this run stopped following   [OPEN]
**Scope:** TRAIL          **Severity:** risk
**Where:** `context/guide/orchestration.md` (lines 4, 12, 17–22, 35, 81, 93),
`CLAUDE.md` lines 33–34, `.claude/commands/start-dev-pipeline.md` line 17
**Violates:** `lessons.md` §1, prospectively — these are live present-tense instructions,
not history.
**What it is:** all three state that the main session **"does no planning, coding or
reviewing itself"**, that the loop is `select → feat-planner → flutter-coder → issue-qa`,
and that phase 2 is **"dispatch `repo-qa` twice in parallel."** On 2026-08-22 the owner
directed mid-run that **diagram work and QA stop going to subagents**, after two background
agents died on a session limit. From that point the main session did UC-11's review and
close, both as-built diagram passes, and both phase-2 sweeps itself; only planning and
coding still dispatched. **So the run that these documents describe is not the run that
happened**, and the next session bootstrapping from them will re-adopt a shape the owner
has already replaced. Recorded in `pm/log.md` under 2026-08-22 as an execution decision
rather than promoted to `decisions.md`, on the grounds that it might not outlive the run —
**it now has**, which is the trigger for promoting it.
**What it does not mean:** nothing here says the three-agent split was wrong. The isolation
argument for it is intact and the `issue-qa`/`repo-qa` agent definitions are unchanged and
still usable. The question for the owner is only which shape the documents should describe.
**Confidence:** certain.

## F13 — UC-11's workbook row still called two of its own decisions open   [FIXED]
**Scope:** TRAIL          **Severity:** defect
**Where:** `docs/workbook.xlsx`, sheet `UC FR`, row 12 (`UC-11`), the `Deskripsi` cell's
closing paragraph
**Violates:** `lessons.md` §1's mirror-image form.
**What it is:** the row ended *"Open (fr-nfr.md section 4): what 'a month' means — calendar
month or payday-to-payday — was never discussed… Also deferred to the ERD: whether a
budget's identity is separate from its monthly amount."* **Both were decided 2026-08-20,
and UC-11 was built on both** — the calendar month is what `BudgetDao._monthStart()`
computes, and the Budget_Group / Budget_Period split is what the code's two tables are. The
owning row of a use case described its own shipped foundations as unsettled.
**How it was missed:** UC-11's planner found it and wrote *"step 12 fixes it at close"*. The
close then ran without it. **It was not a sweep discovery but a skipped close step**, caught
one phase later — recorded that way rather than as a clean find, because the interesting
fact is that a correctly-identified close item can still fall out of a checklist.
**Fixed 2026-08-22:** the paragraph now records both decisions with the reasoning that
settled them and points at `decisions.md`. **The neighbouring paragraph that also mentions
the lock was deliberately left alone** — it is marked as history ("this use case previously
carried the app's only lifecycle"), and `lessons.md` §1 is explicit that only claims still
asserted in the present tense go stale. Verified after save that the history sentence
survives and the open-claim is gone.
**Confidence:** certain — reloaded and re-read the cell after writing.

---

*F14 was filed during phase 1 at the Q2 ruling (2026-08-22): the answer creates a known,
accepted gap rather than an accident, and is recorded here so the backlog can look
complete without FR-18 being satisfied.*

## F14 — `Account` is create-only until UC02B lands; FR-18 is unsatisfied for it   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `pm/tracker.yaml`, row `UC02B-edit-account`; `docs/fr-nfr.md` FR-18
**Violates:** FR-18 — *"Full CRUD across transactions, accounts, budgets, categories and
subcategories … No entity is create-only, and no entity has an exception."*
**What it is:** the owner's Q2 ruling (2026-08-22, Option A) makes `UC02-add-account`
create-only and moves account rename / edit / delete to `UC02B-edit-account`. Until that
lands, `Account` is the one entity in the project with no update or delete path — exactly
what FR-18 forbids by name. The gap is accepted and tracked, not an oversight, and FR-18
was deliberately not amended: the requirement stays whole, and this entry is what stops the
backlog looking complete while it exists.
**Blocks nothing in the run** — every remaining issue depends on UC02, not UC02B — but
FR-18 must not be reported satisfied while this is OPEN.
**Confidence:** certain — the ruling and its cost were stated by the owner before UC-02
was built (`context/index/decisions.md`, 2026-08-22).
