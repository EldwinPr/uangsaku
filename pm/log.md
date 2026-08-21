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

**Phase.** Documentation complete; implementation not started. No Dart code exists.

**Active issue.** `FEAT01-foundation` — plan `CONFIRMED`, **step 1 done, steps 2-12 not
started.** `app/` holds the `flutter create` scaffold (`name: uangsaku`,
`applicationId com.eldwinpr.uangsaku`, android + ios) and is **deliberately untracked**:
no `build_runner` or `drift` yet, and CI's `app` job is guarded on `app/pubspec.yaml`, so
committing it before step 2 activates the job and fails it. `issue-qa` commits it once
step 10's four commands are green.

**Committed:** three commits on `main`, **none pushed** — so CI has not yet run against any
of them, including the `app`-job probe fix.

**Orchestration.** `select → feat-planner → flutter-coder → issue-qa → select`, main session
as orchestrator. Loop, halt paths and retry budget: `context/guide/orchestration.md`.

**Stack.** Flutter/Dart, `drift` over SQLite, Riverpod, no backend, local-first, single
user. **Settled, no longer provisional** — the choice hinged on iOS being a real target
and it was confirmed 2026-08-21.

**Targets.** Android and iOS. Neither is runnable on this machine: no Android SDK
(install before UC14, the first UI issue), and no Mac, so `app/ios/` is versioned but
never compiled. Web is not a fallback — `NativeDatabase.createInBackground` is
native-only. `flutter test` is headless and works, which is where `testing.md` puts the
correctness surface.

**Layout.** The Dart package is `app/`, not the repository root. Every Flutter command
needs `working-directory: app`.

**Toolchain.** Flutter 3.47.1 / Dart 3.13.1 at `C:/flutter`, matching the CI pin. Dart MCP
server 1.1.1. *A session started before the PATH edit cannot see `flutter` — restart the
process, do not re-edit PATH.*

**CI.** `.github/workflows/ci.yml`, two jobs. `docs` runs `audit.py` and works today.
`app` is guarded on `app/pubspec.yaml` and stays inert until FEAT01 lands one — **which
means the first push after FEAT01 is the first real CI run.** Get the four commands in
FEAT01 D7 green locally first.

**Audit.** `python audit.py` — green at 13 passed / 0 warnings / 0 failures. Proves the
artifacts agree with each other; proves nothing about whether they are right
(`lessons.md` §12).

**Open rulings:** none. Both items that stood here were answered 2026-08-21 — budget group
CRUD moved from UC-13 to UC-11, and `note` appears on every recording screen. Recorded in
`context/index/decisions.md`; `pm/questions.md` is the queue for any that arise during the
run.

**Open, non-blocking:** one `fr-nfr.md` §4 item — where the data lives, narrowed to
phone-only but not closed.

**Unattended mode is live.** `feat-planner` may mark a plan `AUTO-CONFIRMED` when every
decision in it cites an already-confirmed artifact, and halts the issue to
`pm/questions.md` when one cannot be cited. FEAT01 itself is `CONFIRMED` by the owner
directly, and **its step 1 is already done** — `flutter create` ran on 2026-08-21; the run
starts at step 2.

**Standing caveat.** `context/coding-conventions/` is **provisional**. No `pub get` has run
for this project, so no version number in `riverpod.md` or `drift.md` is verified. FEAT01
is expected to correct them and say so here.

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
