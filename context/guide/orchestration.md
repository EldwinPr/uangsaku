# Orchestration — the unattended run

How the backlog runs with nobody watching. The **main session is the orchestrator**; it
selects issues and dispatches, and does no planning, coding or reviewing itself. Three
agents do the work, each starting cold with only its brief — which is what keeps the
orchestrator's context small enough to survive the whole backlog.

## The two phases

```
PHASE 1 — the loop
  select ─→ feat-planner ─→ flutter-coder ─→ issue-qa ─→ select ─→ …
                                                          │
                                              nothing runnable
                                                          ↓
PHASE 2 — the sweep, once
  repo-qa (APP) ─┐
                 ├─→ pm/findings.md ─→ STOP
  repo-qa (TRAIL)┘
```

Phase 2 runs **once**, when phase 1 has nothing runnable left. Two `repo-qa` dispatches, in
parallel, different scopes. Then the run ends.

## The loop

**select** — the next issue in `pm/tracker.yaml` with `status: TODO`, every `depends_on`
`DONE`, and no halt recorded. Ties break by tracker order. If nothing is runnable, stop and
report.

**feat-planner** — writes `plan.md`. Returns `AUTO-CONFIRMED` or `HALTED`.

**flutter-coder** — writes the code, gets the four commands green.

**issue-qa** — reviews, reconciles, closes, commits, pushes. Returns PASS or REJECT.

## Halt paths

Three ways an issue stops, and none of them stops the run:

| Where | When | What the orchestrator does |
|---|---|---|
| planner | a decision cannot be cited to a confirmed artifact | question already appended to `pm/questions.md`; mark the issue halted, `select` again |
| coder | fails twice on the same issue | record why in `pm/questions.md`; mark halted, `select` again |
| qa | REJECT | send findings back to `flutter-coder` **once**; a second REJECT halts the issue |

**Retry budget is two attempts, then halt.** A third attempt on the same failure is not
persistence, it is a loop burning budget — and a repeated failure is itself a finding worth
reporting to the owner.

Halting is **per-issue**. The backlog has two independent chains:

```
FEAT01 ─┬─ UC14 ─ UC02 ─┬─ UC01 ─┐
        │               ├─ UC03  ├─ UC04 ─┬─ UC09
        │               └─ UC10  │        └─ UC12
        ├─ UC13 ─────────────────┘
        └─ UC11 ─────────────────────────── UC12
```

A halt on one leaves the other runnable. Keep going until nothing is.

## Rules for the orchestrator

- **`pm/tracker.yaml` is the source of truth for what is done — not your memory.** Re-read
  it at every `select`. Twenty issues is long enough for a remembered state to drift, and
  drift here silently affects everything after it.
- **Dispatch, don't do.** If you find yourself editing a `.dart` file or writing a `plan.md`,
  the loop has collapsed into one agent and the context isolation is gone.
- **Pass the decision, not just the task** (`lessons.md` §10). An agent cannot honour a
  constraint recorded in a file it was never told to read.
- **Check CI at the next `select`, not by blocking.** `issue-qa` pushes; the run continues.
  CI's only new information over the local commands is clean-checkout behaviour — real
  (`lessons.md` §5) but not worth minutes of waiting per issue. A red build is a finding for
  the next cycle.
- **Never mark a plan `CONFIRMED`,** never answer a question in `pm/questions.md`, never
  edit a `.drawio`. Those are the owner's, and the specialist agents'.

## Phase 2 — the final sweep

When `select` finds nothing runnable, dispatch `repo-qa` twice in parallel:

- **scope APP** — the code as a whole. Cross-issue coherence, the standing decisions swept
  across every file, NFR-4's refusal count, FR-18's coverage, and the four commands on a
  **clean checkout** rather than the working tree.
- **scope TRAIL** — the paper trail. `audit.py`, `map.yaml` completeness, every `plan.md`
  saying DONE, the as-built reconcile at whole-app scale, stale registers, renders.

Both write to `pm/findings.md`. **Neither fixes anything** — they have no `Write` or `Edit`
tool beyond that file.

Two scopes rather than one pass because they ask different questions of different artifacts,
and because per-issue review is structurally blind to both: `issue-qa` sees one diff against
one plan. Whether twenty issues add up to one coherent app, and whether the documentation
still describes what was built, are properties of the whole.

## The hard stop

**When phase 2 finishes, the run ends. Do not re-enter phase 1.**

Findings are recorded, not fixed. Do not reopen a closed issue, do not create an issue to
address a finding, do not dispatch `flutter-coder` at one. Owner's instruction, and the
reason is convergence: a cross-cutting finding often needs a decision only the owner can
make, and a run that repairs its own findings can loop indefinitely with each pass
generating the next.

The same applies to a halted issue. A halt means a question is waiting in
`pm/questions.md`; answering it is the owner's, so a halted issue stays halted for the
whole run.

## Starting a run

Point a session at `pm/active.json` and tell it to run the backlog. Everything else — where
to start, what has already been done, the halt rules — is in that file and in
`context/RULES.md`'s reading list.

## Ending a run

Report, in this order: issues closed; issues halted and why; anything still OPEN in
`pm/questions.md` and what it blocked; the findings count by severity from both scopes; CI
status.

**Halts and findings are the useful output, not the failure.** A halt is the pipeline
refusing to guess, which is exactly what the gate exists to produce. A run that closes
twenty issues and reports nothing is the one worth being suspicious of.
