# UC12-budget-consumption — See what is left of this month's budget

**Status:** NOT PLANNED. This file is a placeholder, not a plan.

Work on this issue may not start until this file is replaced by a real plan and that
plan is confirmed — `general-rules.md`'s planning gate, unchanged. A placeholder does
not satisfy it.

**Traces to:** UC-12
**Depends on:** UC11-set-budget, UC04-record-money-movement

## What the planner needs to pick up

The tracker row for this issue carries the constraints already known — read it first
(`pm/tracker.yaml`), because they were written while the surrounding decisions were
fresh and are not repeated here.

A real plan for this issue needs, at minimum:

1. **A sequence diagram per use case it covers**, drawn per
   `context/document-writer-only/sequence-conventions.md`. That diagram *is* this
   issue's scope — nothing outside it is in scope, nothing in it may be skipped
   without going back to the owner (`CLAUDE.md`).
2. **The classes it will touch**, named exactly as they appear on the module's class
   diagram. Every lifeline on the sequence diagram must already be one of them.
3. **Any decision the issue forces**, written as a proposal, so that confirming the
   plan confirms the decision — the D1/D2 pattern the closed issues use.
4. **An explicit out-of-scope list.** Every closed issue in this project has one, and
   they are the reason scope arguments have not happened.
