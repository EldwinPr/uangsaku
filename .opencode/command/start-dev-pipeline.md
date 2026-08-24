---
description: Run the implementation backlog unattended — plan, code, review and close each issue in one lean pass, then sweep the repo and stop at findings.
---

You are the **orchestrator** for an implementation run of this project.

## Spawn economy — read this first

Every subagent dispatch front-loads its prompt *and* its mandatory reading list
(~30k tokens before any work happens), and it pays that cost again on every
dispatch because a fresh agent remembers nothing. Spawns are therefore rationed,
and each one is dispatched with a **brief** that removes most of the re-reading.

- Exactly **two** subagents exist in this loop: `feat-planner` and `flutter-coder`.
  Coding keeps its isolation because test/build output would flood this session;
  planning keeps its because plan quality is the gate for AUTO-CONFIRMED runs.
- **Everything else is yours, in this session**: verification, review-and-close,
  commits, diagram passes, the final sweep. There is no `issue-qa` or `repo-qa`
  agent anymore.
- Never re-dispatch the coder for trivia. Batch follow-ups into one pass per issue.
- **One dispatch per agent per issue** is the target. Two is the retry budget.

### The dispatch brief

You have already read the shared context. Do not make the agent read it again —
carry it in the prompt instead. Every dispatch opens with:

```
Issue: <id>   Plan: <path>   Diagram: <drawio path> + <render path>
Already read for you (do NOT re-read these — this brief supersedes the
"read before writing" list in your prompt, except where noted):
- CLAUDE.md gates that bind this issue: <the two or three that actually apply>
- Standing decisions in play: <only the ones this issue can violate>
- lessons.md entries in play: <ids + one line each>
- Tracker row: <verbatim, it is short>
- Diagram scope: <the lifelines/steps, as a list>
Still yours to read (do not skip): <plan.md in full for the coder; the workbook
row + FRs for the planner; the module class diagram; the conventions file for
whatever you actually touch — drift/riverpod/testing, not all of them>
Deliverable: <one sentence>
Out of scope: <verbatim from the plan>
```

Rules for the brief: quote, don't cite — a path costs the agent a file read, a
quoted line costs nothing. Name only conventions files the issue's code actually
touches. Keep it under ~60 lines; if it is longer than that, the issue is too big
and belongs back with the planner as a split.

## Read first — once per run, not per issue

1. `pm/active.json` — where to start and what is already done.
2. `pm/tracker.yaml` — the backlog. Re-read before each `select`; it is short.
3. `context/index/lessons.md` — how this project actually goes wrong.
4. `pm/log.md` — the current-state block at the head only.
5. `pm/questions.md` and `pm/findings.md` — anything already open.
6. `context/guide/orchestration.md` — **only if the loop below is unclear.** It is
   background, and **where it conflicts with this file, this file wins**: this file
   carries the owner's 2026-08-22 direction that QA and diagram work stay in the
   main session.

Everything else (`CLAUDE.md`, `general-rules.md`, conventions, the workbook) you
read when a specific step needs it — and once read, it goes into the briefs rather
than being re-read.

## Track the run with a todo list

Start the run by creating a todo list with the todo tool (`TodoWrite` in Claude Code, `todowrite` in opencode), and keep it visible — it is
how the owner follows an unattended run after the fact. If no todo tool is
available, print the same checklist as markdown at each transition instead.

- Seed it at run start: **one item per runnable issue** in tracker order, plus a
  final `Phase 2 — repo sweep (APP + TRAIL)` item and a `Final report` item.
- Per issue, the item text is `<issue-id>: plan → code → verify → close`.
- Exactly one item `in_progress` at a time. Mark it completed only after the
  commit is pushed — not after the coder reports done.
- An issue that halts is marked completed with `— HALTED: <reason>` appended to
  its text, so the list still reflects what happened. Never silently drop an item.
- New work discovered mid-run does **not** become a todo item; it becomes a
  finding. The list is the backlog you started with, plus the sweep.

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
`depends_on` DONE, and no halt recorded. Ties break by tracker order. Mark its todo
item `in_progress`.

If the next issue needs a diagram change first (e.g. UC02B-edit-account has no
sequence diagram yet), draw or amend it **yourself before dispatching feat-planner** —
the diagram is the plan's scope, and diagram work does not get its own spawn.

**feat-planner:** dispatch once, with the brief above. If it halts on an uncited
decision, record the halt in the plan + `pm/questions.md`, close out its todo item as
halted, then `select` again.

**flutter-coder:** dispatch only after the planner reports a CONFIRMED or
AUTO-CONFIRMED plan (the coder re-checks the gate itself). Same brief, plus the plan
path — the plan is the one document it must read in full.

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
   `docs/diagrams/renders.lock`. Code deviated from design → reject back to the coder
   (one batched pass, not a stream of corrections).
4. Close steps: `context/index/map.yaml`, `decisions.md` if anything durable,
   `pm/tracker.yaml` Done + summary, `pm/log.md` entry (+ head block),
   plan status → DONE, `pm/active.json` → next. Sweep stale registers by grepping
   the vocabulary of what changed. `python audit.py` green.
5. Commit with a message that says what changed and why, and push. **Then** mark the
   todo item completed.

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
CI status. Finish with the final todo list so the run is readable at a glance.

**Halts and findings are the useful output, not the failure.** A run that closes every
issue and reports nothing is the one to be suspicious of.
