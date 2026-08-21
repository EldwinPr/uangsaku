# Log

Append-only. Newest entries at the bottom. Tag each: [STATUS] / [DECISION] /
[DISCOVERY] / [TODO].

**Read the header block below first — it is the current state of the project in one
screen.** Sessions 1-15 (2026-08-19 to 2026-08-21) are condensed into the timeline and
archived verbatim in [`pm/log-archive-2026-08.md`](log-archive-2026-08.md); the recurring
failure patterns extracted from them are in
[`context/index/lessons.md`](../context/index/lessons.md), which is the file worth reading
before starting work.

---

## Current state — 2026-08-21

**Phase.** Documentation complete; **implementation under way.** The app compiles and its
test suite is green (14 tests). **The first DAO, provider and screen exist** — UC-13's,
built 2026-08-21; UC14 was to have been first and is halted instead.

**Active issue.** `UC11-set-budget` — not planned yet, and **the only runnable row left.**
`UC14-choose-currency` is **HALTED** at the planning gate (`pm/questions.md` Q1 — the guard
on `seq-uc14`'s `opt` fragment cites no confirmed artifact), which blocks **seven** issues
behind it: UC02, UC03, UC01, UC10, UC04, UC09 and UC12. `UC13-categories` is **DONE
2026-08-21** — `CategoryDao`, `categoryTreeProvider`, `CategoriesNotifier`,
`CategoryManagerScreen`, no schema change, and `MaterialApp.home` now points at that screen
temporarily (UC-13 D3; FR-1 gives the spot to UC-01). `FEAT01-foundation` is
**DONE 2026-08-21**: all twelve steps, reviewed and committed by `issue-qa`. `app/` now
holds the seven ERD tables at `schemaVersion 1` (`app/lib/src/{accounts,transactions,
budgeting,settings}`), `AppDatabase` on a background isolate, the committed v1 schema
snapshot, one seeded `Settings` row at `IDR`, and four passing tests. Package `uangsaku`,
`applicationId com.eldwinpr.uangsaku`, android + ios.

**Pushed.** CI has run. The `app` job failed once on the scaffold and the guard was fixed
rather than the commit reverted — see the entry below.

**Orchestration.** Two phases, `context/guide/orchestration.md`. Phase 1 loops
`select → feat-planner → flutter-coder → issue-qa`. When nothing is runnable, phase 2 runs
`repo-qa` twice (APP and TRAIL) into `pm/findings.md` — **and the run stops there.** Findings
are recorded, never fixed by the run; halted issues stay halted.

**Stack.** Flutter/Dart, `drift` over SQLite, Riverpod, no backend, local-first, single
user. **Settled, no longer provisional** — the choice hinged on iOS being a real target
and it was confirmed 2026-08-21.

**Targets.** Android and iOS. Neither is runnable on this machine: no Android SDK
(UC-13 built the first UI without one — `flutter test` is headless, so this has cost
nothing yet; it is only needed to *launch* the app), and no Mac, so `app/ios/` is versioned but
never compiled. Web is not a fallback — the database opens through `drift_flutter`'s
`driftDatabase()`, whose native path is `NativeDatabase.createBackgroundConnection`; a web
build would need drift's wasm backend and its assets, so it would not be testing this app. `flutter test` is headless and works, which is where `testing.md` puts the
correctness surface.

**Layout.** The Dart package is `app/`, not the repository root. Every Flutter command
needs `working-directory: app`.

**Toolchain.** Flutter 3.47.1 / Dart 3.13.1 at `C:/flutter`, matching the CI pin. Dart MCP
server 1.1.1. *A session started before the PATH edit cannot see `flutter` — restart the
process, do not re-edit PATH.*

**CI.** `.github/workflows/ci.yml`, two jobs, **both live and doing real work on every
push.** `docs` runs `audit.py`. `app` runs pub get / format / analyze / test against `app/`,
with `build_runner` gated separately on the dependency actually being present. All five
now run against real code and were green at FEAT01's commit — **so a red `app` job means a
real regression**, not an artefact of the project being half-built.

**Audit.** `python audit.py` — green at 13 passed / 0 warnings / 0 failures. Proves the
artifacts agree with each other; proves nothing about whether they are right
(`lessons.md` §12).

**Open rulings:** none. Both items that stood here were answered 2026-08-21 — budget group
CRUD moved from UC-13 to UC-11, and `note` appears on every recording screen. Recorded in
`context/index/decisions.md`; `pm/questions.md` is the queue for any that arise during the
run.

**Open, non-blocking:** one `fr-nfr.md` §4 item — where the data lives, narrowed to
phone-only but not closed. **Four findings on file** (`pm/findings.md` F1–F4); F2 is the one
that is a real defect — `seq-uc13-categories.drawio` does not draw the read path the code
now has, and needs `diagram-drawio-author`.

**Unattended mode is live, and has now been exercised both ways.** `feat-planner` may mark
a plan `AUTO-CONFIRMED` when every decision in it cites an already-confirmed artifact, and
halts the issue to `pm/questions.md` when one cannot be cited. Both branches have fired on
real work: `UC13-categories` was `AUTO-CONFIRMED`, built and closed; `UC14-choose-currency`
**halted** on one uncitable guard. That the halt came first is the mode working as
specified — over-permission is the failure it is guarding against, not over-halting.

**Standing caveat, now mostly lifted.** `context/coding-conventions/` was written
provisional. FEAT01 verified versions, `analysis_options.yaml`, the database-open call and
the provider shapes; **UC-13 verified the half above the database** — a DAO, a
`StreamProvider`, a `Notifier`, a `ConsumerWidget` and widget tests all exist and pass, and
`drift.md`, `riverpod.md` and `testing.md` were each corrected in place where they lost
(the `DatabaseAccessor` DAO shape, `@riverpod` over drift row classes, and two
`flutter_test`/drift interactions). **Still unverified: a cross-module join and a
derived-figure query** — nothing yet asserts NFR-2's balances or budget totals against real
SQL. The README's banner is split to say exactly that, and no longer names UC14 as the issue
that tests this half (`lessons.md` §1).

---

## Timeline — sessions 1-15 (2026-08-19 → 2026-08-21)

Full entries in [`pm/log-archive-2026-08.md`](log-archive-2026-08.md). Canonical homes for
anything durable are named; this is an index, not a record.

| When | What happened | Where it lives now |
|---|---|---|
| 08-19 s1 | Repo surveyed — framework complete, all project state empty. First `fr-nfr.md` **discarded**: invented rather than elicited. Real elicitation held; "balances" turned out to mean **balance sheet**. 18 FRs, 4 NFRs. | `docs/fr-nfr.md`, `input/2026-08-19-owner-scope-conversation/` |
| 08-19 s2 | FRs promoted to the workbook (UC-01..UC-13). Sheets renamed `UC FR`/`UC Non-FR`. Stack chosen **Kotlin**, then **reversed to Flutter the same day** when iOS moved from "polite maybe" to assumed. ISSUE-001 ERD done. | `docs/workbook.xlsx`, `decisions.md`, `docs/diagrams/erd.drawio` |
| 08-20 | Riverpod chosen, unblocking ISSUE-002 (three class diagrams). ISSUE-003 state diagram drawn, then **deleted** by ISSUE-004 when the owner removed FR-16's budget lock — "no more guardrails". `statuses.md` now lists no values for any entity. | `decisions.md`, `docs/statuses.md`, `class-*.drawio` |
| 08-20 | ISSUE-005 component diagram — the last Phase 1 artifact. D1: modules join each other's tables rather than calling another module's DAO. `audit.py` written. Two OMG spec stubs added, closing a `CLAUDE.md` gate that was being violated unnoticed. | `component-overview.drawio`, `audit.py`, `context/files/` |
| 08-20 | "A month" = calendar month. ISSUE-006 `enums.md` — the seven transaction kinds had existed **only in a closed issue's plan**. ISSUE-007 currency: one app-level setting, amounts as `int` minor units, `Settings` becomes a fourth module. | `docs/enums.md`, `decisions.md` |
| 08-20 | Backlog drafted, then **re-cut to one issue per use case** (`UC{NN}-{slug}`, `FEAT{NN}`). ISSUE-008 sequence conventions — sequence diagrams are the only type authored as **Mermaid** and converted. ISSUE-009 `coding-conventions/`. | `pm/tracker.yaml`, `sequence-conventions.md`, `context/coding-conventions/` |
| 08-21 | `Transaction.note` added; ERD re-opened. **All 14 sequence diagrams drawn**, every lifeline script-checked against the class diagrams. Renders moved to `pm/issues/<issue>/` and committed, with `renders.lock` guarding staleness. Toolchain installed; repo under git; CI written. | `docs/diagrams/seq-uc*.drawio`, `renders.lock`, `.github/` |
| 08-21 | **FEAT01 planned.** iOS confirmed → the Flutter decision stops being provisional. The app moves to `app/`, which silently broke CI's probe. Log distilled into this file plus `lessons.md`. | this file, `lessons.md`, `feat01-foundation/plan.md` |

---

## 2026-08-21 — Log restructured for subagent use

**[DECISION]** `pm/log.md` split three ways. It had reached 1,462 lines — a cost no
subagent can pay, and one no human was paying either. Now:

- **`pm/log.md`** (this file) — a current-state block, a timeline index, and new entries
  from here on.
- **`pm/log-archive-2026-08.md`** — sessions 1-15 verbatim, unedited.
- **`context/index/lessons.md`** — the recurring failure patterns, deduplicated with
  their evidence.

**[DISCOVERY]** Reading all fourteen sessions at once showed what no single session could:
**the same failures recur, and the log was the only place that fact was visible.** Four
registers left stale in one day; three instances of a value changing from stored to
derived and silently invalidating what was built on it; four checks that passed while
looking at the wrong set. Individually each reads as a slip. Together they are a pattern
worth a file — which is the argument for `lessons.md` existing at all.

**[DECISION]** The archive is preserved **verbatim, including terms that later changed**
(`UC Non-BPMN`, `ISSUE-015`, the superseded Kotlin stack). The log is append-only and
those entries were accurate when written; rewriting closed history to match a later
renumber is the tidy-up that makes a record untrustworthy. `audit.py` already carries the
stale paths in `ALLOWED_DANGLING` with that reason.

**[STATUS]** Two subagents added — `feat-planner` (writes and revises `plan.md` files) and
`flutter-coder` (executes a confirmed plan). Neither may cross into the other's job: the
planner writes no code, and the coder may not widen a plan's scope. Details in
`.claude/agents/`.

## 2026-08-21 — Both open rulings closed; the gate gets an unattended mode

**[DECISION]** **Budget group CRUD moves from UC-13 to UC-11.** UC-13 promised it, but
`Budget_Group` is a Budgeting entity and no Transactions class supported it, so `seq-uc13`
had scoped it out with a note — meaning UC-13 as drawn did not deliver what the workbook
promised. Moving it to the module that owns the entity cost a workbook edit and two method
lists; adding a screen to Transactions would have cost a screen and blurred the one
boundary this system still has. *The general form, and the second time this project has hit
it: when a use case names work no class diagram supports, the question is which module owns
the entity — not which screen the workbook happened to mention it on.*

**[DECISION]** **The free-text `note` appears on every recording screen**, not just expense
and income. `note` was decided as a column on the entity, not on a kind; ERD D1 put all
seven kinds in one ledger table precisely so there would be one form and one insert path,
and a per-kind rule about which screens show which fields reintroduces exactly the
branching that removed. `seq-uc06/07/08` redrawn to match `seq-uc04/05`.

**[DECISION]** **The planning gate gets an unattended mode.** Owner: *"the plan writing is
part of the hands off."* `feat-planner` may mark a plan `AUTO-CONFIRMED` **only** when every
decision in it cites an artifact the owner already confirmed; anything else halts that issue
and queues the question in `pm/questions.md`. Halting is per-issue, so the two independent
chains do not block each other.

This narrows the gate rather than removing it. Read as ceremony, *"confirmed by the user"*
stops any unattended run at the first stub; read for its purpose — don't build on
unconfirmed assumptions — it permits a plan that is a transcription of decisions already
made. **The test moves from "did a human sign this" to "does this contain anything a human
has not already approved", which is the question the signature was standing in for and the
only one of the two that can be checked.** The accepted cost is real and worth watching:
the judgement of what counts as already-decided is now the agent's, so the planner is told
to halt on doubt rather than reason toward a default, and every D-entry must carry a
citation — *a citation that cannot be written is the signal that the decision is new.*

**[DISCOVERY]** **Two more stale registers, making six**, and both had survived over a day.
UC-11's `Output` still promised budgets were "editable during the first week and locked
thereafter"; UC-09's `Deskripsi` still justified itself with *"a budget is a commitment made
in advance, so it locks (FR-16)"*. Both rest on the lock ISSUE-004 removed on 2026-08-20 —
the same reversal already chased through nine other files that day. **A sweep that catches
nine of eleven feels complete and is not.** Found only because an agent was sent into the
workbook for an unrelated edit and told to look while it was there.

**[DISCOVERY]** The same pass produced the refinement that makes the fix repeatable:
*only claims still asserted in the present tense go stale.* UC-11's `Deskripsi` also
mentions the lock — as history, marked as history — and that is correct and must not be
edited, because deleting it would erase why `statuses.md` lists nothing. So grepping the
reversed decision's vocabulary ("lock", "lifecycle") finds candidates; **the tense tells you
which are defects.** Both written into `lessons.md` §1.

**[STATUS]** Applied by the two specialist agents. `workbook-xlsx-author`: UC-13 re-scoped,
UC-11 widened, `note` added to the Input of UC-04..UC-08, plus the two stale cells above.
`diagram-drawio-author`: `class-budgeting.drawio` gained group methods on `BudgetNotifier`
and `BudgetDao` (boxes grew, edges recomputed), `seq-uc11` rebuilt with the group-CRUD
fragments, `seq-uc13`'s out-of-scope note removed, `note` added to `seq-uc06/07/08`. All
renders re-exported, visually verified, and `renders.lock` refreshed. Audit green at 13/0/0.

**[TODO]** One possible future gap, raised by the diagram agent and not a defect today: the
group-list *read* path is not drawn on `seq-uc11`. `BudgetNotifier` re-emits only after its
own writes, so drawing a `watchGroups()` stream to the screen would need a dedicated
`StreamProvider` participant on `class-budgeting.drawio` first. Flagged rather than invented.

**[TODO]** `map.yaml` had `UC-13` under `Budget_Group`'s `ucs` and it is now removed. Note
that UC-13 correctly **stays** under the Transactions class diagram — categories and
subcategories are Transactions entities, and only the budget-group half moved.

## 2026-08-21 — The orchestration loop

**[DECISION]** **One new agent, not three.** The loop is
`select → feat-planner → flutter-coder → issue-qa → select`, with the **main session as
orchestrator** — it selects and dispatches and does no planning, coding or reviewing itself.
Owner's constraint: *"i dont want too many agents"*, and `issue-qa` carries review through
reconcile, close, commit and push rather than splitting into a reviewer and a closer.

**[DECISION]** **The coder no longer commits; QA does.** A commit made before review puts
unreviewed code in history, and the run's git log stops being a record of verified work.

**[DISCOVERY]** The reason a separate reviewer earns its keep at all is already on file:
`lessons.md` §10, where a delegated agent exported its own diagram, inspected it, and
reported a real UML notation error as "harmless, not a correctness issue." **A worker's
judgement of its own output is the weakest link in the chain.** The four verification
commands answer *"does this compile and pass its own tests"*; they cannot answer *"does this
match the plan and the diagrams"* — a `double` in a DTO, a `kind IN (...)` list where
`to_account_id IS NULL` belonged, or a disabled button all compile and pass.

**[DECISION]** The tension in bundling review with commit is named in the agent's own brief
rather than left implicit: **an agent that finishes by committing has a standing pull toward
passing.** Its instruction is that rejecting is the expected outcome, not the exception —
one round trip against every issue built on bad code. It may fix trivia only; anything
touching behaviour, naming or scope goes back to `flutter-coder`, because *a check that
repairs what it is checking has stopped being one.*

**[DECISION]** **Retry budget is two attempts, then halt** — a third try on the same failure
is a loop burning budget, and a repeated failure is itself a finding. Halts are per-issue;
the backlog has two independent chains, so one halt never stops the run. Recorded with the
dependency graph in `context/guide/orchestration.md`.

**[DECISION]** **CI is checked at the next `select`, not waited on.** Its only new
information over the local four commands is clean-checkout behaviour — genuinely real
(`lessons.md` §5's CRLF hash is exactly that class of bug) but not worth minutes per issue.

**[TODO]** The orchestrator's own failure mode is drift, not a crash: it holds loop state
across twenty issues, and a loosening notion of "done" would affect everything after it with
nothing reporting so. The defence written into the guide is that `pm/tracker.yaml` is re-read
at every `select` and is the source of truth — never what the orchestrator remembers.

## 2026-08-21 — Phase 2: the final sweep, and the hard stop

**[DECISION]** **The run has two phases, and ends at findings.** When the issue loop has
nothing runnable left, `repo-qa` is dispatched twice in parallel — scope `APP` over the code
as a whole, scope `TRAIL` over the paper trail — both writing to `pm/findings.md`. **Then the
run stops.** Owner's instruction: findings do not go back into the loop.

**[DECISION]** **`repo-qa` finds and records; it does not fix.** It has no `Write` or `Edit`
tool beyond `pm/findings.md`, which is enforcement rather than instruction. It may not reopen
a closed issue, create an issue for a finding, or dispatch the coder at one.

The reason is convergence. A cross-cutting finding usually needs a decision only the owner
can make, and **a run that repairs its own findings can loop indefinitely, each pass
generating the next.** Handing back a clear list beats handing back a repo quietly edited
toward one agent's judgement. The same logic keeps a halted issue halted for the whole run.

**[DECISION]** **One agent definition, dispatched twice**, rather than two. The owner has
twice asked for fewer agents and allowed two here; two *instances* satisfies that while
keeping the roster at seven. The scopes share their whole workflow — read wide, verify,
record, never fix — and differ only in what they read.

**[DISCOVERY]** The split is worth stating because it is the thing per-issue review
structurally cannot do: `issue-qa` sees **one diff against one plan**. Whether twenty issues
add up to one coherent app, and whether the documentation still describes what was built,
are properties of the whole and invisible from any single diff. Concretely, `APP` sweeps the
standing decisions across every file at once (one `double`, one `kind IN (...)`, one
disabled control anywhere), counts NFR-4's refusals app-wide, and runs the four commands on
a **clean checkout** rather than the working tree — the difference that produced this
project's CRLF bug (`lessons.md` §5). `TRAIL` re-runs the as-built reconcile at whole-app
scale, because a drift introduced by a *later* issue was never rechecked against an earlier
one's diagram.

**[DECISION]** `pm/findings.md` separates **defect / risk / improvement**, and severity is
*whether it is wrong*, not how hard it is to fix. Forty style observations bury two real
defects, and this file exists to decide what happens next. It is also explicitly distinct
from `pm/questions.md`: questions **blocked** work before it happened, findings are problems
in work **already done**, and a finding gates nothing.

**[TODO]** Resolving a finding is the owner's: promote it to a tracked issue with its own
plan, or mark it WONTFIX with a reason. *A defect resolved by a decision rather than a change
is still resolved* — record which. And if a finding is another occurrence of something
already in `lessons.md`, it belongs there as evidence; the pattern is worth more than the fix.

## 2026-08-21 — First CI failure: the guard was wrong, not the commit

**[STATUS]** The owner pushed, including `app/`, and CI's `app` job went red on
`Could not find package build_runner`. Reproduced locally step by step: `flutter pub get`
succeeds, `dart run build_runner build` fails, and **`dart format`, `flutter analyze` and
`flutter test` all pass on the bare scaffold** (exit 0, "No issues found!", counter smoke
test green).

**[DECISION]** **Fixed the guard rather than reverting the commit.** One probe was gating
all five steps, so `build_runner` ran on a project that has no builder dependency — that
dependency is FEAT01 step 2, which has not run. Now two probes: `exists` gates pub get /
format / analyze / test, `builders` gates `build_runner` on
`grep -qE '^[[:space:]]+build_runner:' app/pubspec.yaml`.

**[DISCOVERY]** **Fifth instance of `lessons.md` §5, and the second in this same CI job.**
The guard checked a **proxy** — does a pubspec exist — for what it actually cared about:
are there builders to run. Those two facts are identical in the steady state and diverge for
exactly as long as a scaffold exists before its dependencies do, which is precisely the
window this project was in. The previous instance of this defect in the same job was the
opposite failure (a probe that could never fire, reporting success having run nothing), which
makes the pair a nice illustration: *a proxy check fails in whichever direction the proxy and
the real subject happen to disagree, and being right once says nothing about the other
direction.*

**[STATUS]** **The advice this file was giving was right about the symptom and wrong about
the cause.** Four documents told the owner to keep `app/` untracked until FEAT01's four
commands were green, on the reasoning that committing it would activate the job and fail it.
Committing it did fail the job — but the correct response was to fix a guard that was
describing the wrong thing, not to keep a legitimate scaffold out of version control for a
week. All four corrected (`plan.md` step 1, `log.md`'s current-state block, `active.json`,
and this entry).

**[STATUS]** Net effect is better than before the failure: **CI now does real work on every
push** instead of passing trivially until FEAT01 lands. All five app steps are verified green
against the current scaffold, so from here a red `app` job means a real regression.

## 2026-08-21 — FEAT01-foundation DONE: the repo is a Dart project

**[STATUS]** **First code in history.** Twelve steps, reviewed by `issue-qa` before the
commit. What landed, against D2's file manifest — which stood in for the sequence diagram
this issue could not have, and which the as-built pass was run against:

- Seven table declarations in four module files, `schemaVersion = 1`. Column names read
  against `erd.drawio` one by one: they match, in `snake_case`, including
  `Transaction.note` nullable. Declaration names match the class diagrams exactly.
- **Every amount is an `IntColumn`** — `opening_amount`, `Transaction.amount`,
  `Budget_Period.amount`. No `RealColumn` anywhere, in tables or generated code (NFR-2).
- All three enums stored by text: the generated snapshot shows `EnumNameConverter`, not an
  index (`drift.md`).
- `AppDatabase` on a background isolate, one seeded `Settings` row at `IDR` guarded on
  `details.wasCreated`, nothing else seeded (D6).
- `appDatabaseProvider` and nothing else — no screens, no DAOs, no other providers (D5).
- v1 schema snapshot committed. **No generated migration test, and that is correct**:
  `drift_dev make-migrations` generates step tests *between* versions, and re-running it at
  close produced no files. Verified rather than taken on report.
- `app/test/widget_test.dart` deleted — the `flutter create` smoke test asserted against a
  `MyApp` that `main.dart` no longer defines. A consequence of a manifest file, not scope
  creep.

Four commands re-run by the reviewer, not trusted from the report: `build_runner` green,
`dart format` 0 changed of 9, `flutter analyze` "No issues found!", `flutter test` 4/4.
`.github/workflows/ci.yml` untouched (D8) and nothing renamed `moneytracker` → `uangsaku`
(D1).

**[DECISION]** **Three conventions corrections, per step 11**, all in
`context/index/decisions.md` in full: `constant_identifier_names: false` so the enum values
stay spelled as `docs/enums.md` spells them (under `.textEnum<T>()` those identifiers *are*
the stored text); `driftDatabase()` in place of a raw `NativeDatabase.createInBackground`;
and `appDatabaseProvider` as a plain `Provider` rather than `@riverpod`. `riverpod.md` also
gained the real resolved versions — `riverpod_annotation`/`riverpod_generator` are at major
**4**, where the file had guessed 3.

**[DISCOVERY]** **The background-isolate guarantee was checked in the package source, not
inferred.** `driftDatabase()` is a wrapper, and a wrapper is exactly the kind of claim that
gets accepted because it sounds right. `drift_flutter-0.3.1/lib/src/native.dart` calls
`NativeDatabase.createBackgroundConnection`, and `createInBackground` is itself a thin
wrapper on that same call — so the substitution keeps the one real boundary in this system
(ISSUE-005). Same for "a plain `Provider` is kept alive": `riverpod-3.4.2` defaults
`isAutoDispose: false`. Both were the coder's judgement calls and both survived being
checked; neither would have been safe to accept on the argument alone.

**[DISCOVERY]** **`--delete-conflicting-outputs` no longer exists.** `build_runner` 2.16
prints *"These options have been removed and were ignored"* and continues. Harmless — the
command still succeeds, in CI too — but `testing.md`, `plan.md` D7 and `ci.yml` all name
the flag. `testing.md` corrected at close; the CI file is left alone (D8) and the flag is a
no-op there.

**[DISCOVERY]** **Two more `lessons.md` §1 stale registers, both found by grepping the
vocabulary rather than the statement.** `docs/enums.md`'s closing line still said the one
open `fr-nfr.md` §4 item was *"whether a transaction carries a free-text note"* — decided
2026-08-21; the actual remaining item is where the data lives. And
`coding-conventions/README.md` still carried a blanket **provisional** banner over six
files, half of which this issue verified. Both corrected. **A half-true label is the §1
failure in its most durable form**: it is not wrong enough to be noticed and not right
enough to be trusted, so it survives sweeps. Added to `lessons.md` as evidence.

**[TODO]** The plan's **two open questions are still unanswered** and were not answered at
close, because they are the owner's: is `com.eldwinpr.uangsaku` the right application id,
and does the `moneytracker` / `uangsaku` split bother you. Neither blocked the work.
Neither is cheap forever — the application id is the one identifier here that is genuinely
expensive to change once an app is installed.

**[TODO]** One reviewer note filed in `pm/findings.md` (F1) rather than sent back: the
"all seven tables exist" test reads drift's declared `allTables`, not the SQLite schema.
It catches the failure that can actually happen and it is not worth a round trip, but it is
the shape `lessons.md` §5 warns about, and the final `repo-qa` sweep can judge it against
the whole suite.

**[STATUS]** **Next: `UC14-choose-currency`** — the first screen, the first DAO, the first
notifier, and the first issue to be `AUTO-CONFIRMED` rather than confirmed by the owner.
**Install the Android SDK before it if the app is to be launched**; `flutter test` is
headless and does not need it.

---

## 2026-08-21 — `UC13-categories` DONE: the first DAO, provider and screen

**[STATUS]** **`UC13-categories` is DONE**, reviewed and committed by `issue-qa`. What
landed: `CategoryDao` (`watchTree()` / `insert()` / `update()` / `delete()`),
`categoryTreeProvider` and `CategoriesNotifier` (exposed as `categoriesProvider`),
`CategoryManagerScreen`, and fourteen passing tests — the four verification commands were
**re-run at review rather than accepted from the coder's report** (`lessons.md` §10):
`build_runner` clean, `dart format` 14 files / 0 changed, `flutter analyze` *No issues
found!*, `flutter test` 14/14, `audit.py` 13/0/0. **No schema change:** `app_database.g.dart`
and `drift_schemas/app_database/drift_schema_v1.json` are byte-identical to FEAT01's, which
is what "`schemaVersion` stays 1" has to mean in practice.

**[DECISION]** **Two toolchain rulings, both durable, both in `context/index/decisions.md`,
and both re-derived from scratch at review instead of taken on trust.**

1. **A DAO whose class diagram gives it `update()` or `delete()` cannot be a
   `DatabaseAccessor`.** `DatabaseConnectionUser` already declares both names with generic
   `TableInfo` signatures, so the diagram's named-parameter versions are an
   `invalid_override` — reproduced in isolation with a throwaway `ProbeDao`, a straight
   analyzer error, unfixable from inside the method body. `CategoryDao` is therefore a plain
   class composing `AppDatabase`, and `@DriftDatabase` gains **no `daos: […]` entry**. The
   class diagram outranks the convention; `drift.md` corrected in place. This binds
   `AccountDao`, `TransactionDao` and `BudgetDao` too — all three are drawn with `delete()`.
2. **`riverpod_generator` cannot type a provider over a drift-generated row class.**
   `@riverpod Stream<Category>` fails with `InvalidTypeException`; the identical function
   returning `Stream<int>` builds — the swap isolates the generated `part`-file class as the
   cause. Both of this issue's providers are hand-written. **This is broader than the plan's
   D2 contingency**, which anticipated only the `categoriesNotifierProvider` naming
   mismatch. `riverpod.md` corrected.

**[DISCOVERY]** **Two `flutter_test` + drift interactions cost real debugging time and are
now in `testing.md`:** consuming a `watch()` stream's `.first` before a widget subscribes to
the same query starves the widget's subscription until `pumpAndSettle()` times out; and a
widget test that ever built something watching a drift stream must unmount and pump a real
`Duration` as the **last thing in the test body**, or `flutter_test` throws *"A Timer is
still pending"* (`addTearDown` runs too early). Reviewed specifically for `lessons.md` §5 —
whether the tests had been shaped around the quirk until they passed. They had not: both
workarounds are plumbing that runs *after* the assertions, and the assertions themselves are
real (D6 reads the transaction row back out of the database and asserts it survived with
both tags null; the NFR-4 test deletes a category through the UI and proves the tree
re-rendered without it).

**[DISCOVERY]** **`lessons.md` §1 sweep at close found two stale registers**, both the
half-true form. `map.yaml` still described `app/lib/src/app.dart` as "(placeholder screen)"
— it renders `CategoryManagerScreen` now. And this file's own current-state block still said
"there are no screens and no DAOs yet", named UC14 as the first UI issue and called
`AUTO-CONFIRMED` untested. All corrected above.

**[TODO]** **The as-built diagram pass is outstanding, not skipped** — `pm/findings.md` **F2**.
`seq-uc13-categories.drawio` draws four `categoryTreeProvider` emissions and no
`watchTree()` read path to produce them; the code has that path (authorised by the plan,
citing `class-transactions.drawio`). The code is right and the diagram is incomplete, so the
diagram is what changes — **`diagram-drawio-author`'s job**, authored as Mermaid and
converted, exported to PNG and *looked at*. `issue-qa` does not edit `.drawio` files and a
reviewer that repairs what it reviews has stopped being one. **F3** files the same
diagram's isolate note, which names `NativeDatabase.createInBackground` on all fourteen
sequence diagrams where the code uses `driftDatabase()` → `createBackgroundConnection` —
same guarantee, stale mechanism name, repo-wide and not UC-13's to fix. **F4** notes that
the NFR-4 test's rename-control assertion could pass vacuously.

**[TODO]** **The plan's three open questions are the owner's and stay unanswered.** The app
has no navigation host, so exactly one screen is reachable at a time and `home` is now
UC-13's; deleting a category blanks the tag on every transaction that used it **without
warning** (NFR-4 permits a warning, nothing requires one, and the owner has never been shown
that sentence); and category ordering is insertion order because no artifact states one.

**[STATUS]** **Next: `UC11-set-budget`** — the only remaining runnable row. **UC14's halt
has blocked seven issues** (UC02, UC03, UC01, UC10, UC04, UC09, UC12): everything on the
accounts chain sits behind UC14, and UC12 needs UC11 *and* UC04. UC14 stays halted for this
run — `pm/questions.md` Q1 is the owner's to answer. Also committed with this issue, as the
run's record of that halt and **not as UC-13 work**: UC14's written plan, its Q1, and the
`halted:` note on its tracker row.

**[TODO]** **Definition-of-done step 4 could not be performed and is filed as F5.** UC-13 is
the first issue tracing to a UC to reach DONE, and `docs/workbook.xlsx`'s `UC FR` sheet has
**no column for "implemented"** — nor does `workbook-conventions.md` describe one. Adding a
column to a client-facing sheet is `workbook-xlsx-author`'s call and `audit.py` asserts that
sheet's shape, so `issue-qa` recorded the gap instead of inventing a column. The workbook's
UC-13 text itself was checked and needs no correction: it is already re-titled *"Set Up
Categories and Subcategories"* and already says UC-11 owns budget groups.
