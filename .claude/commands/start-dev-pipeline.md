---
description: Run the implementation backlog unattended — plan, code, review and close each issue, then sweep the repo and stop at findings.
---

You are the **orchestrator** for an unattended implementation run of this project.

## Read first, in this order

1. `pm/active.json` — where to start and what is already done.
2. `context/guide/orchestration.md` — the loop, the halt paths, the retry budget, the stop.
3. `context/index/lessons.md` — how this project actually goes wrong.
4. `pm/log.md` — the current-state block at the head only.
5. `pm/questions.md` and `pm/findings.md` — anything already open.

## Your job

**Select and dispatch. Nothing else.**

You do not write plans, code, reviews or diagrams. If you find yourself editing a `.dart`
file or a `plan.md`, the loop has collapsed into one agent and the context isolation that
makes this run survivable is gone.

### Phase 1 — the issue loop

```
select → feat-planner → flutter-coder → issue-qa → select → …
```

**select:** re-read `pm/tracker.yaml` every time — it is the source of truth for what is
done, never your memory of it. Take the next issue with `status: TODO`, every `depends_on`
`DONE`, and no halt recorded. Ties break by tracker order.

**Retry budget: two attempts per issue, then halt.** A third try on the same failure is a
loop burning budget, and a repeated failure is itself a finding.

**Halts are per-issue and never stop the run.** A planner halt (a decision it cannot cite),
a coder failing twice, or a second `issue-qa` REJECT — record it, then `select` again. The
backlog has two independent chains, so a halt on one leaves the other runnable. A halted
issue stays halted for the whole run.

Only `issue-qa` commits.

### Phase 2 — the sweep, once

When `select` finds nothing runnable, dispatch `repo-qa` **twice in parallel**: scope `APP`
and scope `TRAIL`. Both write to `pm/findings.md`.

### Then stop

**Do not re-enter phase 1.** Do not reopen a closed issue, create an issue for a finding, or
dispatch the coder at one. Findings are recorded, not fixed — a cross-cutting finding
usually needs a decision only the owner can make, and a run that repairs its own findings
loops indefinitely with each pass generating the next.

## Report at the end

In this order: issues closed; issues halted and why; anything still OPEN in
`pm/questions.md` and what it blocked; findings by severity from both scopes; CI status.

**Halts and findings are the useful output, not the failure.** A run that closes every issue
and reports nothing is the one to be suspicious of.
