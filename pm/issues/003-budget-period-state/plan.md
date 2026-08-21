# ISSUE-003 — `Budget_Period` state diagram

**Status:** DONE 2026-08-20 — then SUPERSEDED the same day by ISSUE-004, which removed
FR-16's lock and collapsed the lifecycle this issue existed to draw;
`state-budget-period.drawio` was deleted and `docs/statuses.md` now lists no status
values for any entity. Left DONE deliberately: the work was correct against the rules in
force when it was done. Q1 (state is derived, not stored) and Q2 (skipped months are not
backfilled) both survive; only the deletable-only-while-open ruling and the diagram
itself were undone. Original status line, for the record: "WRITTEN. Owner asked for
drafts of the state and class diagrams to understand the scope, rather than answering
Q1-Q3 first — a fair signal that those
questions needed the artifacts to make sense of them. Proceeding under stated
assumptions: Q1-Q3 are annotated ON the diagram as open questions rather than
resolved, and no transition depends on any of them. Nothing here is expensive to
revise once the owner has seen it."

**Depends on:** ISSUE-001 (DONE). `Budget_Period` exists because of D3.

## Goal

`docs/diagrams/state-budget-period.drawio` — the lifecycle of one budget period,
plus populating the (currently empty) `docs/statuses.md` with its legal values.
`state-conventions.md` requires the two stay in sync: that file is the vocabulary,
the diagram is which moves between those values are legal.

`fr-nfr.md` names this "the first thing in the app with a lifecycle" and predicts
it as the first state-diagram subject.

## Traceability of every transition

`state-conventions.md`'s hard rule: a transition goes on the diagram only if it
traces to something actually stated. Anything else is an open question, not an
arrow. Every proposed transition and its source:

| # | From → To | Trigger | Traces to |
|---|---|---|---|
| 1 | *(initial)* → `OPEN` | owner sets an amount for a group | FR-12 — "I can set a monthly amount for a budget group" |
| 2 | *(initial)* → `OPEN` | next period auto-created from the previous one | FR-15 — "Next month's budget is set automatically from this month's" |
| 3 | `OPEN` → `LOCKED` | first week of the period elapses | FR-16 — "A month's budget locks after the first week and cannot be changed after that" |
| 4 | `LOCKED` → `CLOSED` | period end reached | FR-14 + FR-16's note — "open → locked → closed at month end" |
| 5 | `CLOSED` → *(final)* | — | FR-14 — each month stands alone; nothing further happens to it |

Transitions deliberately **absent**, each for a stated reason:

- **`LOCKED` → `OPEN` (reopen).** Forbidden outright by FR-16 — a hard lock,
  confirmed, with the accepted cost written into the FR. Drawing it would
  contradict the requirement.
- **Any spending-related transition.** FR-12 makes a budget a soft limit: going
  over is recorded, not prevented. Overspending changes no state, so it is not an
  arrow — a point worth making explicitly on the diagram, since its absence is a
  design decision rather than an oversight.

## Three questions this issue surfaces — annotated on the diagram, not blocking

### Q1. Is `state` stored, or derived from the dates?

The ERD gives `Budget_Period` a `state` column. But D4 gave it `starts_on` and
`ends_on`, which means the state is fully computable: before `starts_on + 7 days`
it is open, after `ends_on` it is closed, otherwise locked.

That matters, and it is the same argument NFR-2 makes about balances. A stored
state can drift from the dates and needs something to actually write it — and on a
local-only app with no server, nothing runs while the app is closed, so a stored
state would only update when you next open the app. A derived state is correct the
moment you look at it, with no background job and nothing to go stale.

**Recommendation: derive it, and drop the `state` column from the ERD.** The state
diagram stays exactly as drawn either way — it documents the lifecycle, not the
storage. If you agree this is a schema change to ISSUE-001's output, and I would
re-open that diagram rather than let the two disagree.

### Q2. What happens to months you skipped?

FR-15 auto-creates next month's budget from this month's. Never stated: what
happens if the app is not opened for three months. Are the missed periods created
retroactively, so the history is continuous? Or does the next opening create only
the current month, leaving gaps?

This changes transition #2's trigger and it changes what UC-12's history looks
like. Not inventing an answer.

### Q3. Can a budget period be deleted? FR-18 and FR-16 disagree.

FR-18 says full CRUD across everything, budgets named explicitly. FR-16 says a
locked budget cannot be changed. §3's ruling settled *editing* ("budget stays,
transaction editable") but said nothing about deleting.

If deletion is allowed, it is a transition to a final state from any state, and it
needs drawing. If not, FR-18's scope needs narrowing in `fr-nfr.md`. Either is
fine; the current documents cannot both be true.

## Steps

1. ~~Confirm this plan and answer Q1-Q3.~~ Superseded: owner asked for a draft
   first. Q1-Q3 are drawn on the diagram as open questions.
2. Populate `docs/statuses.md` with `Budget_Period`'s legal values. **DONE.**
3. Draw `docs/diagrams/state-budget-period.drawio` — delegated to
   `diagram-drawio-author`. Flat states only, per conventions; no composite states.
4. Export to PNG, look at the full render.
5. `grep -c '<!--'` → 0.
6. If Q1 lands on "derive", re-open ISSUE-001's ERD to drop the `state` column.
7. Close per the `CLAUDE.md` checklist.

## Out of scope

- Any other entity's lifecycle. `state-conventions.md` is one diagram per stateful
  entity, and `Budget_Period` is currently the only one. `Account.settled` (D8) is
  a two-value flag, not a lifecycle worth a diagram.
- The class diagrams (ISSUE-002, blocked).
