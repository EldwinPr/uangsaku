# Orchestration — the unattended run

How the backlog runs with nobody watching. The **main session is the orchestrator**; it
selects issues and dispatches, and does no planning, coding or reviewing itself. Three
agents do the work, each starting cold with only its brief — which is what keeps the
orchestrator's context small enough to survive the whole backlog.

## The loop

```
select ─→ feat-planner ─→ flutter-coder ─→ issue-qa ─→ select ─→ …
```

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

## Starting a run

Point a session at `pm/active.json` and tell it to run the backlog. Everything else — where
to start, what has already been done, the halt rules — is in that file and in
`context/RULES.md`'s reading list.

## Ending a run

Report, in this order: issues closed, issues halted and why, anything in `pm/questions.md`
awaiting a ruling, and CI status. **Halts are the useful output, not the failure** — they
are the pipeline refusing to guess, which is the behaviour the gate exists to produce.
