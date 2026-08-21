# ISSUE-004 — Remove the budget lock; budgets get full CRUD like everything else

**Status:** DONE 2026-08-20. Plan confirmed by the owner, who also ruled on the two
flagged calls: **delete the state diagram**, and **keep FR-10 as is**.
**Depends on:** ISSUE-001 (DONE), ISSUE-002 (DONE), ISSUE-003 (DONE — this issue
partially supersedes its output).

## The ruling

Owner, 2026-08-20: *"i guess let budget be full crud like other, it's about users
discipline anyways"* and *"from now on it's user responsibility no more guardrails or
whatever."*

Raised once and reaffirmed: the concern put to the owner was that FR-16's stated
rationale is **report fidelity**, not discipline — *"a report measured against a moving
target says nothing"* — so removing the lock means UC-12's "spent vs budget" comparison
becomes always satisfiable after the fact. The owner reaffirmed. Recorded here so the
cost is on file rather than rediscovered: **this is a known, accepted trade, not an
oversight.**

**Scope decision: plain full CRUD.** The middle option offered — full CRUD plus
recording that an amount was amended after the period started, so the report could still
distinguish a budget set in advance from one set retroactively — was not taken; "no more
guardrails or whatever" reads as not wanting the extra mechanism. Noted because it stays
available later as a **pure addition** (one nullable column, one line of UI) that
forecloses nothing and refuses nothing.

## What the audit actually found

`docs/fr-nfr.md` was swept end to end for anything that refuses, blocks, or enforces a
user action. **There is exactly one guardrail in the entire document: FR-16.** Everything
else that looked like a candidate is a correctness or data-shape rule, not a restriction
on the owner:

| Passage | Verdict |
|---|---|
| **FR-16** — the lock | **The guardrail.** Remove. |
| FR-18's "except a budget period once it has locked" + the exception paragraph | Dependent on FR-16. Remove. |
| NFR-4 — "the one deliberate exception is the FR-16 budget lock" | Dependent. Remove. |
| NFR-4 fit criterion — "exactly one user action is refused" | Dependent. Becomes **zero**. |
| FR-8 / FR-9 — transfers and lending "must not count as spending" | **Not a guardrail.** Classification correctness; refuses the owner nothing. Keep. |
| FR-12 — "a soft limit, not enforced; going over is recorded, not prevented" | **Not a guardrail** — it is the model the rest now follows. Keep. |
| NFR-1 — no account codes, no journal, no debit/credit, no period close | **Anti-guardrail.** Constrains the app, not the owner; removes ceremony. Keep. |
| NFR-2 — balances derived, never stored | Internal correctness. Keep. |
| FR-17 — unbudgeted spending shows under "Others" | Display rule. Keep. |
| FR-10 — categories are exactly two levels deep | **Judgment call, flagged.** It does restrict the owner (no third level), but it is a data-shape decision the owner stated and confirmed themselves, not a discipline mechanism. Left in place unless the owner says otherwise. |

**The pleasing consequence:** NFR-4's fit criterion is a *counter* — "exactly one user
action in the app is refused... a second refusal appearing anywhere is a violation." That
count goes to zero, which makes the NFR strictly easier to test than it is today:
**every user action succeeds.** The rule that a new refusal cannot be added quietly gets
stronger, not weaker.

## Changes, by file

**`docs/fr-nfr.md`**
1. FR-16 — rewrite. The lock is gone; a budget amount stays editable for the life of the
   period. Keep FR-14 (each month stands alone) — that is about carry-forward, not the
   lock, and is untouched.
2. FR-18 — drop "except a budget period once it has locked" from the headline; delete the
   2026-08-20 exception paragraph. FR-18 returns to unqualified full CRUD.
3. NFR-4 — delete the exception sentence; fit criterion becomes zero refusals.
4. §3 "Raised and closed" — the old ruling (*"budget stays, transaction editable"*) is
   superseded. Do not delete it; mark it superseded with the new date, per the
   append-don't-rewrite discipline.
5. §4 — **the open question raised earlier today dissolves.** "What state does a period
   enter when created after its own lock date?" has no referent once there is no lock;
   a period is always editable. Mark it resolved-by-dissolution rather than deleting it,
   so the reasoning survives.
6. §5 traceability — FR-16's row currently reads "promoted (step 3, the lock)". Update.

**`docs/statuses.md`**
- `locked` ceases to exist. `open` / `closed` survive only as "is this month over",
  a date comparison that now gates nothing.
- **Recommendation: `Budget_Period` moves to the "Entities with no lifecycle" section**,
  alongside `Account`'s settled flag — by that section's own words, *"a flag, not a
  lifecycle; no diagram."* A state that restricts nothing is not a lifecycle.

**`docs/diagrams/state-budget-period.drawio`** — **delete**, following from the above.
This is ISSUE-003's deliverable, built and closed yesterday. Flagged prominently because
deleting a just-built artifact deserves an explicit yes; a diagram is not a reason to
keep a rule, but it should not vanish silently either.

**`docs/diagrams/class-budgeting.drawio`** — remove `BudgetNotifier.isEditable()` (the
FR-16 lock check) and the `delete() — only while open` qualifier; remove the
`BudgetPeriodState` box and its arrow. **`Clock` survives** — still needed to know which
period is current — but it stops being the thing FR-16's testability argument rested on.
Re-verify the render after editing.

**`docs/workbook.xlsx`, UC-11** — `Deskripsi` step 3 is *"After the first week of the
month the amounts lock and cannot be changed - a hard lock, confirmed."* Rewrite step 3
and drop FR-16's quoted line from the header. UC-12 needs no change — its NFR-4
constraint line is already about overspending, not the lock. Delegate to
`workbook-xlsx-author`.

**`context/index/decisions.md`** — supersede the 2026-08-20 entry "A budget period is
deletable only while open". Its load-bearing argument was *"a budget you can delete is a
budget you can escape."* That argument was **correct and is now moot**: it only mattered
while there was a lock to escape. Write it as superseded-with-reason, not deleted — the
entry above it is the template for how to do that.

**`context/index/map.yaml`** — drop the `state_diagrams` block if the diagram goes.

**`pm/tracker.yaml`** — note on ISSUE-003 that its state-diagram output is superseded
by ISSUE-004. Do not flip it away from DONE; it was done correctly against the rules in
force at the time.

## Risk to check while doing it

`BudgetPeriodState` is referenced in `pm/issues/002-class-diagrams/plan.md`'s class list.
Update that plan too, or it becomes a stale design doc — the exact failure this project
deleted `class-budgeting-draft.drawio` to avoid this morning.

## Steps

1. ~~Confirm this plan.~~ Done — owner confirmed both flagged calls.
2. `docs/fr-nfr.md` (the six edits above).
3. `docs/statuses.md`, then delete the state diagram.
4. `class-budgeting.drawio`; validate, export, inspect the render, `grep -c '<!--'`.
5. Workbook UC-11.
6. `decisions.md`, `map.yaml`, ISSUE-002's plan.
7. Close per the `CLAUDE.md` checklist.

## Out of scope

- Recording budget amendments (the middle option, deliberately not taken — see above).
- The component diagram.
- Any other §4 open item: account-type naming, currency, what "a month" means, whether a
  transaction carries a note.
