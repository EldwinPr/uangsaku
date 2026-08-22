---
description: Run the implementation backlog unattended — plan, code, review and close each issue in one lean pass, then sweep the repo and stop at findings.
---

You are the **orchestrator** for an implementation run of this project.

## Spawn economy — read this first

Every subagent dispatch front-loads its prompt and mandatory reading (~30k tokens
before any work happens). Spawns are therefore rationed:

- Exactly **two** subagents exist in this loop: `feat-planner` and `flutter-coder`.
  Coding keeps its isolation because test/build output would flood this session;
  planning keeps its because plan quality is the gate for AUTO-CONFIRMED runs.
- **Everything else is yours, in this session**: verification, review-and-close,
  commits, diagram passes, the final sweep. There is no `issue-qa` or `repo-qa`
  agent anymore.
- Never re-dispatch the coder for trivia. Batch follow-ups into one pass per issue.

## Read first, in this order

1. `pm/active.json` — where to start and what is already done.
2. `context/guide/orchestration.md` — background on the loop design. **Where it
   conflicts with this file, this file wins**: it carries the owner's 2026-08-22
   direction that QA and diagram work stay in the main session.
3. `context/index/lessons.md` — how this project actually goes wrong.
4. `pm/log.md` — the current-state block at the head only.
5. `pm/questions.md` and `pm/findings.md` — anything already open.

## Your job

**Select → dispatch → verify → close. Nothing else.**

You do not write plans, widen plans, invent classes, or add features. You also do not
hand review-and-close to anyone — you run it yourself per issue (below).

### Phase 1 — the issue loop

```
select → feat-planner → flutter-coder → verify & close (you) → select → …
```

**select:** re-read `pm/tracker.yaml` every time — it is the source of truth for what
is done, never your memory of it. Take the next issue with `status: TODO`, every
`depends_on` DONE, and no halt recorded. Ties break by tracker order.

If the next issue needs a diagram change first (e.g. UC02B-edit-account has no
sequence diagram yet), draw or amend it **yourself before dispatching feat-planner** —
the diagram is the plan's scope, and diagram work does not get its own spawn.

**feat-planner:** dispatch with the issue id; its own prompt knows what to read. If it
halts on an uncited decision, record the halt in the plan + `pm/questions.md`, then
`select` again.

**flutter-coder:** dispatch only after the planner reports a CONFIRMED or
AUTO-CONFIRMED plan (the coder re-checks the gate itself). Give it the issue id and
let its prompt do the steering.

**verify & close — you, per issue**, following `CLAUDE.md`'s close checklist:

1. Re-run all four commands from `app/`: `dart run build_runner build
   --delete-conflicting-outputs`, `dart format --set-exit-if-changed .`,
   `flutter analyze` (must be clean), `flutter test`. A report of passing is not
   evidence of passing.
2. Read the full diff against the plan and its Out-of-scope list, checking the
   standing decisions: int minor units everywhere, spending = `to_account_id IS NULL`,
   no stored balance, enums as `.textEnum<T>()`, writes return nothing to screens,
   zero refusals (no disabled controls), class names match the class diagrams.
3. As-built reconcile of the sequence diagram. Design was wrong → fix the diagram
   yourself, re-export the PNG, **look at the render**, refresh
   `docs/diagrams/renders.lock`. Code deviated from design → reject back to the coder.
4. Close steps: `context/index/map.yaml`, `decisions.md` if anything durable,
   `pm/tracker.yaml` Done + summary, `pm/log.md` entry (+ head block),
   plan status → DONE, `pm/active.json` → next. Sweep stale registers by grepping
   the vocabulary of what changed. `python audit.py` green.
5. Commit with a message that says what changed and why, and push.

Not sure about something cross-module? Append it to `pm/findings.md` with
`Confidence: worth checking` and proceed — the sweep settles it later. A violation
you can name is a reject, however inconvenient.

**Retry budget: two attempts per issue, then halt.** A third try on the same failure
is a loop burning budget, and a repeated failure is itself a finding.

**Halts are per-issue and never stop the run.** The backlog has independent chains;
record the halt, move to the next runnable issue. A halted issue stays halted for the
whole run.

### Phase 2 — the sweep, once

When `select` finds nothing runnable, sweep the repo yourself — both scopes,
appending findings to `pm/findings.md` in its format:

- **APP:** apply step 2's standing-decision checklist across every module, not one
  diff. Count NFR-4 refusals (fit criterion zero). Check FR-18 full CRUD for every
  entity. Cross-issue coherence: same concern implemented two ways, duplicated
  helpers, naming drift. Verify the four commands on a clean checkout, not the
  working tree.
- **TRAIL:** `python audit.py` green; `map.yaml` complete; every `plan.md` DONE;
  tracker summaries real; durable decisions recorded in `decisions.md`; sequence
  diagrams still describe the code at whole-app scale; stale registers (grep the
  vocabulary, check tense); OPEN questions; any `lessons.md` failure recurring.

Severity is whether it is wrong, not how hard it is to fix. Find nothing → say so.

### Then stop

**Do not re-enter phase 1.** Do not reopen a closed issue, create an issue for a
finding, or fix a finding. Findings are recorded, not fixed — a cross-cutting finding
usually needs a decision only the owner can make, and a run that repairs its own
findings loops indefinitely with each pass generating the next.

## Report at the end

In this order: issues closed; issues halted and why; anything still OPEN in
`pm/questions.md` and what it blocked; findings by severity from both sweep scopes;
CI status.

**Halts and findings are the useful output, not the failure.** A run that closes every
issue and reports nothing is the one to be suspicious of.
