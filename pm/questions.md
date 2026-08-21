# Questions

**The unattended run's halt queue.** When `feat-planner` hits a decision it cannot derive
from an already-confirmed artifact, it halts that issue and appends the question here
rather than choosing a default.

Append-only. Newest at the bottom. The owner answers, the answer goes to its **canonical
home** (`docs/fr-nfr.md` §4 for requirements, `context/index/decisions.md` for design),
and the entry here is marked ANSWERED with a pointer. This file is a queue, not a record —
`lessons.md` §1 is the reason the answer must land somewhere permanent as well: *a decision
is not finished until every register that listed it as open is updated.*

## What belongs here

A question **only** if proceeding would mean choosing something the owner has not already
decided. Before writing one, check that the answer is not already in:

- `docs/fr-nfr.md` — the requirements and their §4 open register
- `context/index/decisions.md` — every durable design decision, with reasoning
- `docs/enums.md` / `docs/statuses.md` — the legal values
- The use case's own sequence diagram and its module's class diagram
- `docs/workbook.xlsx` — the owning row's `Deskripsi`, `Input`, `Output`

**If a question can be answered by reading one of those, it is not a question — it is
research that was not done.** Halting is expensive: it blocks every dependent issue.

## What does not belong here

- Anything the sequence diagram already answers. The diagram **is** the scope.
- A naming preference with no downstream consequence. Follow the class diagram; if it is
  silent, follow the existing code's convention.
- A question about how to implement something already decided. That is
  `context/coding-conventions/`.

## Format

```
## Q{N} — {one-line question}          [OPEN | ANSWERED]
**Raised by:** {issue id}, {date}      **Blocks:** {issue ids, transitively}
**Why it cannot be derived:** which artifacts were checked and what each failed to say.
**Options, if any are visible:** with the cost of each — never a recommendation dressed
as the only path.
**Answer:** {owner's words} — recorded at {canonical home}.
```

Name the transitive blast radius, not just the direct dependent. When UC-13's missing
classes were open, the honest count was **four** issues downstream, not one — and that
number is what tells the owner how urgent an answer is.

---

*No open questions. Both items that stood here on 2026-08-21 — UC-13's budget group CRUD
and whether `note` appears on the transfer / lend-borrow / repayment screens — were
answered by the owner before the run began and are recorded in `context/index/decisions.md`.*
