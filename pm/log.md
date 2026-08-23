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

## Current state — 2026-08-24

**Phase.** **The entire backlog, including one owner-requested addition, is DONE.** The
app compiles and its test suite is green (**128 tests**). Nine screens built end to end,
and — since `FEAT02-navigation-host` — **all reachable except one deliberately unrouted
flow** (UC-03's adjust mode). `home` is `AppShell`: a four-tab `NavigationBar`
(Balance Sheet, Record, Transactions, Budget) with every other screen reached from
within a tab. `pm/findings.md` F8 (no navigation) is fixed.

**Active issue.** None. The owner answered both outstanding questions 2026-08-23 (Q3:
soft delete; Q4: fixed side + signed amount for adjustments), unhalting the last two
issues; both are now DONE — `UC03-adjust-account` on 2026-08-23, `UC02B-edit-account` on
2026-08-24 (the project's first schema change: `schemaVersion` 1→2, drift guided
migrations, `Accounts.deleted`/`deleted_at`). CI was found broken after that (a real
`_slugdir` bug in `audit.py`, fixed and confirmed green). The owner then asked directly
for a navigation host so the app could actually be tried, closed the same day as
`FEAT02-navigation-host`. This run has closed UC02, UC01, UC10, UC04, UC09, UC12, UC03,
UC02B and FEAT02; before them FEAT01, UC13, UC11, UC14. **Nothing is runnable.**

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

**Audit.** `python audit.py` — green at 14 passed / 0 warnings / 0 failures (taught the
B-suffix issue scheme on 2026-08-22 after Q2 created UC02B as a second issue tracing to
UC-02). Proves the artifacts agree with each other; proves nothing about whether they are
right (`lessons.md` §12).

**Open rulings:** none. Q3 and Q4 both answered 2026-08-23 (`decisions.md`); F14 (Account
create-only) resolved 2026-08-24 at `UC02B`'s close. `pm/questions.md` has nothing open.

**Open, non-blocking:** one `fr-nfr.md` §4 item — where the data lives, narrowed to
phone-only but not closed. **Fifteen findings on file** (`pm/findings.md` F1–F15).
**Eight are resolved**: F2, F3, F6, F8, F13, F14 fixed and F10 accepted (the
clean-checkout verification, recorded as a negative result). F3 fixed 2026-08-23 — every
sequence diagram in the repo now names the correct isolate mechanism. F14 fixed
2026-08-24 — `Account` has full CRUD, FR-18 satisfied for every entity. **F8 fixed
2026-08-24** — `FEAT02-navigation-host`, the owner's direct request, gave every screen
but one a real route.
**Eight stand, recorded and not fixed** (F1, F4, F5, F7, F9, F11, F12, F15) — the ones
that need an owner ruling are **F7** (a non-numeric amount is silently saved as zero,
five live instances across four screens), **F9** (a codegen toolchain the app has proved
it cannot use, still carried as a runtime dependency and a suppressed lint), **F11**
(`decisions.md` still calls open the very question `lessons.md` §1 was written about),
**F12** (the orchestration guide describes a process this run stopped following) and
**F15** (a copy-pasted date formatter).

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

**[TODO → DONE 2026-08-22]** **The as-built diagram pass was outstanding, not skipped** — `pm/findings.md` **F2**, now FIXED; see the 2026-08-22 entry at the foot of this log.
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

---

## 2026-08-22 — UC-13's as-built diagram pass, done in the main session

**[STATUS]** **`pm/findings.md` F2 is FIXED.** `docs/diagrams/seq-uc13-categories.drawio`
now draws the read path the code has had since `8b6bc0a`. Re-authored in Mermaid and
converted with the draw.io CLI per `sequence-conventions.md` — not hand-edited XML. All
twenty-three original messages and both fragment guards survive unchanged; the diagram now
numbers 1–28. Render re-exported to `pm/issues/uc13-categories/seq-uc13-categories.png`,
`renders.lock` refreshed with `audit.py --record-renders`, `grep -c '<!--'` = 0, audit
green at 13/0/0.

**[DISCOVERY]** **The read path is five messages, not the four F2 predicted.** F2 was
written from the four `CategoryDao ⇄ AppDatabase` / `watchTree()` messages that were
obviously missing, but `seq-uc14-choose-currency` also draws `Screen → provider: watch()`
as the first step of the identical chain. A first draft that copied only F2's four left the
provider emitting a stream nobody subscribed to. *A finding's own count is an estimate made
before the work; the artifact it points at is what settles the number.* The neighbouring
diagram, not the finding text, is what caught this.

**[DECISION]** **Diagram work and QA no longer go to subagents** — the owner's call
mid-run, after two background agents died on a session limit. `context/guide/orchestration.md`
still describes the three-agent loop, and planning and coding still dispatch; the change is
that the main session does the as-built diagram passes and the review-and-close itself.
Recorded here rather than in `decisions.md` because it is how this run is being executed,
not a durable property of the project — if it outlives the run, promote it.

**[STATUS]** **F3 narrowed from fourteen sequence diagrams to thirteen.** UC-13's copy of
the stale isolate note (`NativeDatabase.createInBackground`, where the code calls
`createBackgroundConnection` through `drift_flutter`'s `driftDatabase()`) was corrected in
the same pass, because UC-13 owns that diagram. The other thirteen stay filed and unfixed —
each belongs to an issue not yet built, and each will be corrected by its own as-built pass.

**[TODO]** Phase 1 has one runnable row left, `UC11-set-budget`, and its plan is not
written. UC14 stays halted for the run (`pm/questions.md` Q1), blocking seven issues.

---

## 2026-08-22 — UC11-set-budget DONE; phase 1 ends with nothing runnable

**[STATUS]** **`UC11-set-budget` is DONE**, reviewed and closed in the main session rather
than by `issue-qa` (the owner's mid-run direction). `BudgetDao`, `BudgetNotifier` exposed as
`budgetProvider`, `Clock`, `SetBudgetScreen`, plus the budget group create/rename/delete
re-scoped here from UC-13 on 2026-08-21. All five verification commands re-run rather than
taken on report: `build_runner` wrote 0 outputs, `dart format` 20 files 0 changed,
`flutter analyze` clean, `flutter test` **31 passed**, `audit.py` 13/0/0. No schema change —
`app_database.g.dart` and `drift_schemas/app_database/drift_schema_v1.json` are both
byte-identical, so `schemaVersion` stays 1.

**[DECISION]** **FR-15's pre-fill is a form value, not a row written ahead.** Confirmed in
the built code: `upsert()` is reachable only from the save button, so nothing is written
between the screen opening and the owner saving, and a month never visited holds no row. A
current-month row wins over the pre-fill. This was the one place UC-11 could have quietly
become a writer of rows nobody asked for — `lessons.md` §2's shape exactly — and the plan
argued it down to a single representable outcome before any code was written.

**[DECISION]** **A screen reading more than one drift stream uses a plain
`Notifier<AsyncValue<…>>` with hand-opened subscriptions, not a `StreamNotifier`.** The
`StreamNotifier` + `combineLatest3` shape never released its subscriptions on auto-dispose
and hung `AppDatabase.close()`. Isolated with three probes. Recorded in `decisions.md` and
`riverpod.md` — **the third consecutive issue in which the real toolchain overruled a
convention written before any code existed.**

**[DISCOVERY]** **The as-built pass found five defects on `seq-uc11-set-budget.drawio`,
three more than the planner had recorded.** The planner caught a missing `watch()` message
and a read path that named only the previous month. Reading the code against the diagram
added three: `setAmount`/`upsert` were drawn taking a `month` parameter the code derives
from `Clock` instead; **every stream emission to the screen was drawn with a filled
arrowhead**, i.e. as a synchronous call, where `sequence-conventions.md` requires an
asynchronous message and where `seq-uc13` correctly uses one; and the `deleteGroup` path
showed a bare `delete(groupId)`, hiding the tag-blanking that is the whole substance of D7.
The diagram was regenerated from Mermaid with all five corrected. *The planner reads the
diagram against the artifacts; only the as-built pass reads it against the code, and that is
where notation errors surface.*

**[DISCOVERY]** **`class-budgeting.drawio` carried a `BudgetNotifier → Clock` edge the code
does not have**, removed at close with an XML parser rather than a regex (`lessons.md` §6).
Two confirmed artifacts already agreed against it — D5 injects `Clock` into `BudgetDao`, and
the sequence diagram only ever shows `BudgetDao` asking the time. The notifier names its
months relatively (`monthsAgo`) and never needs a date. Recorded in `decisions.md` because
UC-12 builds from that diagram.

**[DISCOVERY]** **F6: a long `note over` renders outside its own box**, on both
`seq-uc13-categories` and `seq-uc11-set-budget`. Found on UC-11 and only then recognised on
UC-13, where the close check had asked whether the note was *clipped at the canvas edge* —
it was not — and passed without ever asking whether the text had escaped its container.
**A visual check has a subject too, and "I looked at it" does not say what you looked for.**
Both fixed by splitting the note across two lines; verified by counting dark pixels to the
right of the note's own fill, 0 on both. Added to `lessons.md` §5 as its fifth instance and
its first non-script one.

**[TODO]** **F7, for the owner:** a non-numeric budget amount is silently saved as **0**.
NFR-4 forbids refusing the save, so the question is which non-refusing behaviour is wanted —
keep the previous amount, treat empty as "no budget" and delete the row, or write the zero
and say so. The same parse will be needed by every amount field UC-04 introduces.

**[STATUS]** **Phase 1 is over: no row in `pm/tracker.yaml` is runnable.** UC02, UC03, UC01,
UC10, UC04, UC09 and UC12 are all behind `UC14-choose-currency`, halted at the planning gate
since 2026-08-21 (`pm/questions.md` Q1). A halted issue stays halted for the whole run, so
the run proceeds to phase 2 — the two `repo-qa` sweeps — and then stops.

---

## 2026-08-22 — Phase 2: the two end-of-run sweeps, and the run stops

**[STATUS]** **Phase 1 ended with three issues closed of eleven.** `select` was re-run
against `pm/tracker.yaml` and confirmed nothing is runnable: `UC14-choose-currency` is
halted, and UC02, UC03, UC01, UC10, UC04, UC09 and UC12 all sit behind it. Both sweeps were
run **in the main session**, not by `repo-qa` subagents, per the owner's 2026-08-22
direction — scope APP over the code as a whole, scope TRAIL over the paper trail. Six
findings, F8–F13.

**[DISCOVERY]** **Scope APP — the clean-checkout run is the one thing worth doing twice.**
Cloned the repo to a fresh directory at `9cad36d` and ran the full sequence there rather
than in the working tree: `pub get` resolved, format 20 files 0 changed, analyze clean,
**31 tests passed**, `audit.py` 13/0/0, and `build_runner` wrote 42 outputs from cold
producing an `app_database.g.dart` **byte-identical** to the committed one. So nothing in
the working tree was load-bearing and the committed generated code is exactly what the
generator makes. Recorded as F10 — *a negative result is worth writing down when the check
is one nothing else performs* (`lessons.md` §5).

**[DISCOVERY]** **F8 — the screens are orphaning each other, and only a whole-app view
shows it.** This app has no navigation host, so `MaterialApp.home` is the only route to a
screen. UC-13 pointed it at `CategoryManagerScreen`; UC-11 re-pointed it at
`SetBudgetScreen`, exactly as UC-13 D3 said a later issue would. **UC-13's screen is now
unreachable in the running app** — its feature is built, tested and unusable. Both issues
were individually correct and `issue-qa` could not have seen this: it reviews one diff
against one plan. Six more screens are queued behind the same pattern. **A navigation host
is on no class diagram, so no issue can invent one without an owner ruling.**

**[DISCOVERY]** **F9 — the app still carries the codegen toolchain three issues proved it
cannot use.** `riverpod_annotation` is a *runtime* dependency, `riverpod_generator` a dev
one, and `invalid_annotation_target: ignore` switches off a real lint app-wide — all to
support `@riverpod`, of which **there is not one occurrence**, and by recorded decision
there cannot be while every read provider carries a drift row class.

**[DISCOVERY]** **F11 — `lessons.md` §1 recurred inside the document the lesson is about.**
`decisions.md` still says the credit/debit naming collision is "still open — see
`fr-nfr.md` §4"; §4 records it `Closed 2026-08-19`. The 2026-08-20 sweep fixed one register
and missed its mirror, and the stale sentence has now outlived the fix by three days and a
shipped schema. *A file that documents a failure mode is not immune to it.* Added to
`lessons.md` §1 as its ninth instance, with F13 as the tenth.

**[TODO]** **F13 was a skipped close step, not a sweep discovery, and that is the point.**
UC-11's workbook row still called a calendar month and the Budget_Group/Budget_Period split
open, in the same week UC-11 was built on both. **UC-11's own planner found it and wrote
"step 12 fixes it at close"; the close then ran without it.** Fixed during this sweep, with
the neighbouring lock paragraph deliberately left alone because it is marked as history.
*A correctly-identified close item can still fall out of a checklist* — worth watching
whether this repeats before it earns a `lessons.md` entry of its own.

**[DECISION]** **The run stops here.** Findings are recorded, not fixed. No closed issue is
reopened, no issue is created for a finding, and the halted UC-14 stays halted. What the
owner picks up: `pm/questions.md` Q1 (which unblocks seven issues), and the five findings
above that need a ruling rather than a change.

---

## 2026-08-22 — Q1 answered, UC-14 unhalted and DONE; the run resumes

**[DECISION]** **The owner answered Q1: changing the currency "just changes the prefix thats
all".** Recorded at `context/index/decisions.md`. It unhalted UC-14 and the seven issues
behind it — eight of eleven implementation rows freed by one sentence, which is the number
`pm/questions.md` asks for precisely so the cost of *not* answering is visible.

**The answer dissolved the question rather than picking from its menu.** Q1 offered four
options for what makes the warning fire. The ruling made two of them incoherent — a
"setup complete" column and a cross-module count of existing amounts are both work bought to
qualify a message about a prefix — and it removed the only objection to the third: option A
would have warned on a first-ever IDR→USD switch, which the guard called wrong, but if the
change is a prefix then saying so is **true**. So `opt [the chosen currency differs from the
stored one]`. *A halt is worth its cost when the answer reshapes the options instead of
selecting one.*

**[STATUS]** **`UC14-choose-currency` is DONE.** 37 tests green, no schema change
(`drift_schema_v1.json` byte-identical). Two tests carry the ruling: choosing the
already-stored currency shows **no** dialog, and an `Account`'s `opening_amount` is unchanged
after a currency change — the re-labels-never-converts rule made checkable rather than
merely asserted in prose.

**[DISCOVERY]** **The plan was a day stale and the planner caught it.** UC-14 was planned
before UC-13 and UC-11 shipped, so **D1 and D7 had to be amended** when the halt lifted: D1
registered the DAO under `@DriftDatabase(daos: […])` and D7 used `@Riverpod(keepAlive: true)`
with a generated `Notifier` — neither is buildable under the rulings those two issues forced.
Both were amended in place with what they used to say. *A halted plan keeps ageing while it
waits, and the rest of the repo does not stop moving; re-checking every decision against what
shipped during the halt is part of lifting it, not an optional courtesy.*

**[STATUS]** **F8 confirmed a second time, as predicted.** UC-14 took `MaterialApp.home`, so
`SetBudgetScreen` is now orphaned alongside `CategoryManagerScreen` — two dead screens, one
reachable. UC-14's plan named the cost in advance instead of rediscovering it, which is the
right handling and does not stop the count rising. **Five screens still queued.** F3 narrowed
to eleven diagrams as UC-14 corrected its own isolate note.

**[TODO]** Next: `UC02-add-account`, which lands the `Transactions` table's first write path
as well as `Accounts` — FR-3's opening amount is an `adjustment` transaction per ERD D1, a
dependency the issue's name hides.

---

## 2026-08-22 — UC02-add-account closes; Q2 answered; audit learns the B-suffix scheme

**[DECISION]** **The owner answered Q2: Option A — UC-02 is create-only.** Account rename,
edit and delete become `UC02B-edit-account`, a second tracked issue sharing the UC-02 code
under a B suffix (a shape the tracker's ID scheme did not anticipate; the workbook calls
those flows alternate flows of UC-02, but seq-uc02 draws create only, and CLAUDE.md makes
the diagram the scope). Recorded at `context/index/decisions.md` (2026-08-22, *Account CRUD
splits from UC-02*); F14 filed so FR-18's gap for Account is visibly tracked rather than
accidental. The delete-FK question — what happens to a deleted account's transactions —
travels with UC02B unanswered.

**[STATUS]** **`UC02-add-account` is DONE.** `AccountDao` (insert only),
`AccountsNotifier`/`accountsProvider`, `AccountFormScreen`; home re-pointed from
`CurrencyScreen`. 46 tests green, no schema change (`drift_schema_v1.json`
byte-identical). The issue's own tracker row had claimed this issue would land the
Transactions write path — four artifacts refute it, and tests now pin the truth: inserting
an account writes **no** transaction row, zero or non-zero opening amount alike. The
superseding [TODO] above ("lands the Transactions table's first write path") is wrong as
written and stands as history; seq-uc03 owns that write path. As-built pass corrected the
diagram's isolate note (F3 narrows to ten) and confirmed messages 7-8 are UC-01's read
path, correctly drawn ahead of build order (plan D9). F8 confirmed a third time:
`CurrencyScreen` joins two other dead screens. F7 now covers two screens.

**[DISCOVERY]** **audit.py assumed one implementation issue per use case, and Q2 broke
it.** Three failures on the Q2 commit: the one-owner rule, an id-must-map-1:1 rule that read
UC02B as implying "UC-02B", and a last-wins dict comprehension that silently reassigned
seq-uc02's render to the UC02B folder. All three were the checker lagging a legitimate
owner ruling, not defects in the artifacts; audit.py now knows B-suffixed issues share a
UC, keeps the render with the primary owner, and reports the split as information. CI ran
red exactly once, on the intermediate commit, and green from the fix onward.

**[TODO]** Next: `UC02B-edit-account` sits first in tracker order but is blocked twice — no
sequence diagram covers account rename/edit/delete anywhere, and the deleted-account
transactions ruling is unanswered. If those do not clear, the run proceeds to
UC03-adjust-account, which has both its diagram and its scope already settled.

---

## 2026-08-22 — UC01-balance-sheet closes; the primary screen exists

**[STATUS]** **`UC01-balance-sheet` is DONE.** The four FR-1 figures and the per-account
list, via the app's first cross-module SQL join - written inside `AccountDao` against the
`Transactions` table, never calling another module's DAO (component-overview D1). 56 tests
green, no schema change, read-only issue (seq-uc01 draws no write path). The figures are
sides-based sums over `Account.group`: **no `kind` predicate and no
`to_account_id IS NULL` anywhere**, so the four figures are provably independent of how Q4
settles adjustment encoding - a test drives one account to the same balance under both
candidate encodings, which is what let this issue be AUTO-CONFIRMED while UC03 halts on the
same question. `home` is `BalanceSheetScreen` **permanently** (FR-1); AccountFormScreen is
F8's fourth orphan, and the era of temporary re-pointings is over.

**[DISCOVERY]** **Regenerating a Mermaid-authored diagram from scratch silently dropped the
step-number circles.** The as-built note edit on seq-uc02/seq-uc01 was done by re-authoring
the .mmd and re-running the CLI; the first regeneration lost every numbered circle because
`autonumber` was never in any committed source (the .mmd files are deleted after conversion,
so the numbers lived only in the generated XML). Caught by looking at the render against the
previous one, restored with `autonumber`, re-exported, re-checked. *The conversion source is
not persisted anywhere, so "re-author in Mermaid" really means re-derive it from the XML -
and anything not carried over by hand is silently gone.*

**[TODO]** Next: `UC10-debt-progress` - FR-11's paid/remaining for one RECEIVABLE or PAYABLE
account plus markSettled(). After it: UC04, then UC09 and UC12. UC02B and UC03 stay halted
on Q3/Q4 for the rest of the run unless the owner answers.

---

## 2026-08-23 — UC10-debt-progress closes; the repayment filter keeps Q4 out

**[STATUS]** **`UC10-debt-progress` is DONE.** FR-11's two figures plus the settle tick:
`watchDebtProgress()` and `setSettled()` in `AccountDao`, `markSettled()` returning nothing,
`debtProgressProvider` as a hand-written autoDispose.family, `DebtDetailScreen`. 63 tests
green, no schema change, settle always proceeds (NFR-4 - idempotent update rather than any
guard). The planning question this issue could have inherited from Q4 dissolved by citation:
**paid sums only `kind='repayment'` rows**, and enums.md fixes that row independently of how
Q4 settles adjustment encoding - so a dual-encoding test pins paid unchanged under both,
and remaining is UC-01's sides-based balance shown via ABS. AUTO-CONFIRMED where UC03
halts: same open question, different exposure.

**[DISCOVERY]** **Repayment direction is group-dependent in this schema.** Off a RECEIVABLE
the repayment sits on the from side (balance falls toward zero); into a PAYABLE it sits on
the to side. The DAO's "touches either side" predicate handles both; the first test fixtures
had it backwards and failed loudly against a correct query. Worth remembering when UC-04's
repayment form lands.

**[STATUS]** As-built pass on seq-uc10 added the read-path subscription messages the code
has and the diagram lacked (the F2 precedent), corrected the isolate note (F3 narrows to
nine), renumbered to 12 messages with autonumber, render inspected at full size.
DebtDetailScreen ships unreachable from birth - F8's fifth orphan and the first never
reachable at any point; UC09's list would have been its natural host.

**[TODO]** Next: `UC04-record-money-movement` - five use cases, one form, one write path;
both dependencies Done. After it UC09 and UC12 unblock.

---

## 2026-08-23 — UC04-record-money-movement closes; the ledger gets its first write path

**[STATUS]** **`UC04-record-money-movement` is DONE.** Six writable kinds across five use
cases through ONE insert: `TransactionDao.insert()` is the Transactions table's first write
path, sides per enums.md's kind table, amount an exact int magnitude, no validation and no
refusal anywhere (NFR-4). The tracker row's own summary undercounted ("five kinds") - the
workbook gives UC-07 lend OR borrow and UC-08 repayment separately; corrected at close,
which is the same failure shape the UC02 row had (a wrong summary propagating into briefs -
the planner's dispatch brief repeated it). 77 tests green, no schema change. The screen
ships unreachable (F8's sixth orphan); class-transactions' TransactionDao box gained
watchAccounts()/watchBudgetGroups(); all five recording diagrams' isolate notes corrected
(F3 narrows to four), renders inspected at full size.

**[DISCOVERY]** **The .mmd sources do not exist for any committed sequence diagram, so
"re-author in Mermaid" means reconstructing the edge graph from the XML.** For the five
recording diagrams this was done by extracting every UserObject label plus every mxCell
edge source/target pair rather than trusting the label order - fragment membership and
edge directions are not recoverable from labels alone. All five reconstructions rendered
identical structure to their predecessors with only the isolate note changed. The
autonumber loss from UC01's pass would have happened five times here without that care.

**[TODO]** Next: `UC09-review-and-correct`. After it, only UC12 remains runnable; UC02B
and UC03 stay halted on Q3/Q4 unless the owner answers.

---

## 2026-08-23 — UC09-review-and-correct closes; FR-18 lands for Transaction

**[STATUS]** **`UC09-review-and-correct` is DONE.** `TransactionDao` gained the two
methods `class-transactions.drawio` named for it from the start: `watchAll()` (a two-sided
`LEFT JOIN` against `Accounts` for both side names, in-module join per ISSUE-005 D1) and
`update()`/`delete()`. Delete is immediate and unconditional — no table references
`Transactions`, so it can never fail a foreign key, and NFR-4's zero refusals forbids a
confirmation dialog whose "no" could become a quiet refusal. `kind` is never a parameter of
`edit()` — retagging a row across kinds stays out of scope. `transactionListProvider` is a
single-stream hand-written `StreamProvider.autoDispose` (the UC-11 combining-shape ruling
isn't triggered — one stream, not several). Both OPEN questions (Q3, Q4) were checked and
cited through as not blocking (D6): neither this issue's read nor its writes branch on
either question's answer. 89 tests green, no schema change (`drift_schema_v1.json`
byte-identical). `TransactionListScreen` ships unreachable — F8's seventh orphan — and
`home` deliberately stays `BalanceSheetScreen` rather than re-pointing again (D8, FR-1
settled that permanently at UC-01's close).

**[STATUS]** As-built pass on `seq-uc09-review-and-correct.drawio` had already landed the
two read-path subscription messages and the corrected isolate note before this review;
render re-inspected at full size, clean. F3 narrows to three: `seq-uc03`, `seq-uc12`,
`seq-uc02b`. `renders.lock` was stale against the as-built source (hash mismatch) and was
refreshed via `audit.py --record-renders`.

**[STATUS]** D9's two stale "searching notes is UC-09's surface" passages corrected —
`docs/fr-nfr.md`'s note-decision entry and `transactions_table.dart`'s `note` column doc
comment both now say search/filtering stays deferred outright (fr-nfr.md §3), not promised
to a later UC-09 surface.

**[TODO]** Only `UC12-budget-consumption` remains runnable. `UC02B-edit-account` (Q3) and
`UC03-adjust-account` (Q4) stay HALTED pending the owner.

---

## 2026-08-23 — UC12-budget-consumption closes; only the two halted issues remain

**[STATUS]** **`UC12-budget-consumption` is DONE — the last runnable issue in this run.**
`BudgetDao.watchConsumption()` is one watched `customSelect` joining `BudgetGroups`,
`BudgetPeriods` and `Transactions` directly (ISSUE-005 D1). `spent` = `SUM(amount) WHERE
to_account_id IS NULL`, in-month, grouped by `budget_group_id` — **no `kind` filter**, the
same spending predicate UC-01/UC-10 already use, which is why neither OPEN question (Q3,
Q4) touches this figure. The "Others" row (`budget_group_id IS NULL`) is always present via
`UNION ALL`; its label is applied by the screen, never stored. No carry-forward (FR-14): a
group's `amount` is 0 when the month has no `BudgetPeriods` row. `BudgetOverviewScreen` has
zero controls, so there is nothing to refuse — overspending renders as a negative
`remaining` rather than blocking (FR-12, NFR-4). 104 tests green, no schema change
(`drift_schema_v1.json` byte-identical). Ships unreachable — F8's **eighth** orphan; `home`
stays `BalanceSheetScreen`, not re-pointed. One SQL-dialect snag handled in scope: SQLite
rejects an expression directly in `ORDER BY` on a compound `UNION ALL` select, fixed by
wrapping the union in a subquery — no schema or scope change.

**[STATUS]** As-built pass added the elided `BudgetOverviewScreen → budgetConsumptionProvider`
`watch()` subscription and corrected the stale isolate note; render re-inspected, clean.
F3 narrows to two, and both are now on issues HALTED at the planning gate rather than TODO:
`seq-uc03-adjust-account.drawio` (drawn, stale, blocked behind Q4) and `seq-uc02b` (not yet
drawn — UC02B is blocked on its own diagram per Q3). Neither will move until the owner
answers.

**[STATUS]** Per the owner's mid-run direction (2026-08-23): planning and diagram authoring
now happen in the main orchestrator session rather than via `feat-planner`/diagram-author
subagents, extending the 2026-08-22 direction that already moved QA and diagram work
in-session (F12). `flutter-coder` remains the one dispatched subagent.

**[TODO]** Nothing is runnable. `UC02B-edit-account` (Q3) and `UC03-adjust-account` (Q4)
stay HALTED pending the owner. **Phase 2 — the repo-wide APP + TRAIL sweep — is next.**

---

## 2026-08-23 — Owner answers Q3 and Q4; UC03-adjust-account closes, UC02B-edit-account dispatched

**[DECISION]** **Q3 answered: deleting an account is a soft delete.** `Accounts` gains
`deleted`/`deleted_at` (identical shape to UC-10's `settled`/`settledAt`); `delete()`
writes the flag and never removes the row, so every transaction that ever referenced the
account keeps a real row to resolve. Chosen over cascade (irreversible data loss) and
set-null (contradicts the from/to columns' role as a transaction's identity) and refuse
(a refusal, forbidden by NFR-4). `docs/diagrams/erd.drawio` and `class-accounts.drawio`
amended in the main session (not delegated — see the owner's mid-run direction below);
`docs/diagrams/seq-uc02b-edit-account.drawio` drawn fresh via Mermaid, rendered and
visually verified (reordering the lifelines from the first draft to put `AccountsNotifier`
ahead of the read-path classes, avoiding a zigzag the first ordering produced). Full
reasoning in `context/index/decisions.md`.

**[DECISION]** **Q4 answered, left to my judgment ("pick whatever you see fit"):
adjustment encodes as a fixed side + signed amount.** `to_account_id` is always the
corrected account, `from_account_id` always `null`, `amount` carries the signed diff —
`adjustment` becomes the ledger's one negative-amount kind. Chosen over side-follows-sign
because that option's downward correction would satisfy `to_account_id IS NULL` and read
as spending in UC-12's Others bucket; the chosen encoding needed **no change to any
shipped query**, since UC-01/UC-09/UC-10/UC-12 were all built and tested
encoding-independent already. `docs/enums.md`'s kind table tightened from its two-sided
hedge to the resolved rule.

**[STATUS]** **`UC03-adjust-account` is DONE.** `AccountDao.insertAdjustment()` is the
Accounts module's first write into `Transactions` (ISSUE-005 D1's licence read the other
direction), deriving `diff = targetAmount − current` itself inside one drift transaction
— nothing above the DAO reads the current balance. Unconditional: a zero-diff correction
still writes a row. `AccountFormScreen` extended with an adjust flow selected by a
non-null `accountId`, reusing UC-02's screen rather than building a new one. 112 tests
green, no schema change. As-built pass corrected the stale isolate note — **F3 is now
fully clear**, every sequence diagram names the correct mechanism.

**[DISCOVERY]** `pm/findings.md` F7 (the non-numeric-amount-saves-as-zero pattern) had
its own "this was the last one" claim falsified within the same day it was written: the
phase-2 sweep declared the field count closed at four screens while UC03 was still
HALTED, and UC03 unhalted an hour later, adding a fifth live instance (a second
controller on an already-counted file). Recorded as evidence that a finding's closing
claim is only as good as the backlog state it was checked against.

**[STATUS]** `UC02B-edit-account`'s plan is CONFIRMED and its sequence diagram, ERD and
class-diagram groundwork are done, but its `flutter-coder` dispatch was **held** until
UC03's closed — the two issues share three files under `app/lib/src/accounts/`
(`account_dao.dart`, `accounts_providers.dart`, `account_form_screen.dart`), and coding
them in parallel would have been exactly the scope overlap the preflight gate exists to
catch. Dispatched immediately after this close.

**[DECISION]** Per the owner's direction mid-run: planning and diagram authoring now
happen in the main orchestrator session rather than via `feat-planner`/diagram-author
subagents — this extends the 2026-08-22 direction that already moved QA and diagram work
in-session (F12). `flutter-coder` remains the one dispatched subagent. Also fixed a real
bug in `audit.py` surfaced by drawing `seq-uc02b-edit-account.drawio`: the render-owner
lookup sliced every `seq-uc{NN}...` filename's first two digits, which silently collided
a B-suffixed diagram with its primary issue instead of the suffixed one — exactly the gap
the script's own comment anticipated but never implemented. Fixed to check the filename's
letter suffix against tracker issue ids directly.

**[TODO]** `UC02B-edit-account` is the only remaining runnable work — a schema change
(`schemaVersion` → 2 via drift's guided migrations, the project's first), `AccountDao`
gains `update()`/`delete()`, three shipped queries gain `WHERE NOT deleted`. After it
closes, nothing is runnable and phase 2 (the repo-wide sweep) runs again to catch
anything the two newly-closed issues changed underneath it.

---

## 2026-08-24 — UC02B-edit-account closes; the entire runnable backlog is done

**[STATUS]** **`UC02B-edit-account` is DONE — the last runnable issue.** The `flutter-coder`
dispatch hit a connection error mid-response (not a content failure) after most of the
work was done; resumed from its own transcript rather than restarted, and finished
cleanly. Closes FR-18 for `Account` (`pm/findings.md` F14): the one entity that was
create-only until now has full CRUD.

**This is the project's first schema change since FEAT01** — `schemaVersion` 1 → 2,
`Accounts` gains `deleted`/`deletedAt` (identical shape to UC-10's `settled`/`settledAt`).
Built exactly as `drift.md`'s "Migrations" section prescribes: `dart run drift_dev
make-migrations` twice, the generated `stepByStep` helper wired into `onUpgrade`, never a
hand-written branch. `drift_schema_v1.json` byte-identical; `drift_schema_v2.json` new.
The generated migration test was filled in with a real data-integrity fixture (one
pre-existing account) rather than left as the empty TODO template — proves the upgrade
preserves the row and defaults the new columns correctly, not just that a fresh v2
database can be created.

**`AccountDao.delete()` is a soft delete** — writes `deleted = true, deleted_at = Clock.
now()`, never `DELETE FROM Accounts`, so it can never fail a foreign key and needs no
guard. `watchPosition()`/`watchBalances()` (UC-01) and `TransactionDao.watchAccounts()`
(UC-04/UC-09's picker) gain `WHERE NOT deleted`; `TransactionDao.watchAll()` (UC-09's
list) stays unfiltered so a deleted account's history keeps displaying — exactly why Q3
rejected set-null. `update()` edits only `name`/`group`, never `opening_amount` (stays
UC-03's). `AccountFormScreen` gained an `AccountFormMode {create, adjust, edit}`
discriminator for its third flow.

**[DISCOVERY]** **Caught at review, before close: my own plan's D4 had a real bug.**
D4 said `watchDebtProgress()` should also gain `WHERE NOT deleted`, generalizing from
`watchPosition()`/`watchBalances()` without noticing the difference in shape —
`watchDebtProgress(accountId)` is a `.watchSingle()` family query keyed to one
already-selected account, not a list aggregate. Filtering it would have turned "the
account you're viewing was deleted" into a `StateError` crash (zero rows) instead of a
still-resolvable historical figure, the first time anyone actually deleted a debt account
while its detail screen was subscribed. Reachability (F8) makes this unlikely to have
been hit soon, but it was a real defect in a planning decision I wrote myself, not
something surfaced by the coder — fixed directly during review rather than re-dispatching
for one line. Worth remembering: a "the same filter as its neighbors" generalization
needs checking against each query's actual cardinality contract, not just its subject
table.

**[STATUS]** 122 tests green, `flutter analyze` clean, `audit.py` 14/0/0. `pm/findings.md`
F8 confirmed final for this run — eight built screens, one reachable; F14 closed.

**[TODO]** **Nothing is runnable.** The entire backlog planned at run start (FEAT01
through UC02B) is DONE. **Phase 2 — the repo-wide APP + TRAIL sweep — runs again**, since
two issues (UC03, UC02B) closed since the last sweep touched anything. Then the run stops.

---

## 2026-08-24 — CI's `docs` job was red for four commits; fixed a real `_slugdir` bug

**[DISCOVERY]** The owner flagged CI as broken. `docs` (runs `audit.py`) had failed on
every commit since `6e7b15b` (2026-08-23) — four commits in a row — while `app` stayed
green and every local `python audit.py` run, including a fresh Windows clone and a real
Linux checkout reproduced in WSL, passed cleanly. The owner pasted the actual failing
step's output, which local reproduction alone could not surface: `FAIL sequence render
missing or unrecorded: seq-uc02-add-account.drawio -> pm/issues/uc02b-edit-account/
seq-uc02-add-account.png` — a render genuinely present at the correct path, failing
because `audit.py`'s `_slugdir()` resolved the wrong directory.

**Root cause:** `_slugdir()` matched a tracker id to its `pm/issues/` folder with
`base.lower().startswith(prefix)` over an unsorted `glob.glob()`. That was safe as long
as each UC-prefix matched exactly one directory; once `uc02b-edit-account/` started
existing alongside `uc02-add-account/`, both satisfied `startswith('uc02')`, and which one
won depended on `glob.glob`'s filesystem-dependent enumeration order — alphabetical on
this project's Windows dev machine (and, coincidentally, every WSL/Linux test run
attempted afterward), not guaranteed on GitHub Actions' runner. Fixed to match the exact
first hyphen-separated token instead of a prefix, and to sort the glob so the fallback is
deterministic everywhere. Recorded in `context/index/lessons.md` §5 as a sixth instance —
notably one where thorough local reproduction (including a real Linux checkout) still
failed to surface the bug, because reproducing it needed the actual adverse enumeration
order, not just the same platform family.

**[TODO]** Verify the next CI run on `main` is green after this pushes.

---

## 2026-08-24 — FEAT02-navigation-host closes; F8 resolved, the app is now click-through-able

**[STATUS]** **`FEAT02-navigation-host` is DONE** — owner's direct request in this
session ("add a navigation host so I can actually try it"), resolving `pm/findings.md`
F8, which had tracked the app's total lack of routing since UC-11's close. `AppShell`
(`app/lib/src/app.dart`) is now `home`: a Material 3 `NavigationBar` with four primary
tabs (Balance Sheet, Record, Transactions, Budget) over an `IndexedStack`, so switching
tabs never rebuilds a tab's provider subscriptions from scratch. Contextual entry points
wired inside `BalanceSheetScreen` (FAB → create account, row tap → edit account,
RECEIVABLE/PAYABLE row icon → debt detail, two app-bar actions → categories/currency)
and `BudgetOverviewScreen` (app-bar action → set budget). No UC owns this — infrastructure,
the same class as FEAT01 — and no screen's own business logic, DAO, or provider changed.

**[DISCOVERY]** `IndexedStack` keeps every tab mounted simultaneously, which meant every
`FloatingActionButton` in the app (five of them, once a pushed screen sits on top of a
mounted tab) shared Flutter's implicit default hero tag and crashed at runtime with
"multiple heroes share the same tag" — an architecture consequence of the brief, not a
business-logic bug, fixed with an explicit unique `heroTag` on each.

**[STATUS]** 128 tests green, `flutter analyze` clean, no schema change, `audit.py`
14/0/0. All nine screens are now reachable except UC-03's adjust flow, deliberately left
without an entry point (not asked for).

**[TODO]** Nothing is runnable. This is genuinely the end of the run — every tracker
issue, including this owner-requested addition, is DONE.
