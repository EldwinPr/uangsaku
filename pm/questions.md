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

---

## Q1 — What makes the currency-change warning fire?          [ANSWERED]

**Raised by:** UC14-choose-currency, 2026-08-21
**Blocks:** UC14-choose-currency directly, and **seven issues transitively** — UC02-add-account,
then UC03-adjust-account, UC01-balance-sheet and UC10-debt-progress behind it, then
UC04-record-money-movement, then UC09-review-and-correct and UC12-budget-consumption. That is
eight of the eleven implementation rows. The other chain (UC13-categories, UC11-set-budget) is
unaffected and can still run.

`seq-uc14-choose-currency.drawio` guards its `opt` fragment (message 9, the warning) on
**[[an existing currency is being changed, not initial setup]]**. Nothing says how code
decides that, and the schema cannot express it.

**Why it cannot be derived:**

- `docs/fr-nfr.md` **FR-19** splits "chosen at setup" from "*I can change it later, and the app
  will not stop me*", and puts the warning at *"the moment I would cause it"* — the moment
  amounts would be re-labelled. It does not say how the app recognises that moment.
- The **workbook UC-14 row** repeats the same split — *"at first setup or any time after"* —
  and defines neither side.
- `docs/enums.md` and `docs/diagrams/class-settings.drawio` both say the change re-labels and
  the app warns and proceeds. Neither gives a trigger.
- `docs/diagrams/erd.drawio` and the built table (`app/lib/src/settings/settings_table.dart`):
  `Settings` is exactly `settings_id` + `currency`. **No "setup complete" marker, no
  timestamp** — the distinction the guard names is not readable from the database.
- `FEAT01` D6 seeds one `Settings` row at `Currency.IDR` on a fresh database, so a currency
  value exists from first launch. Read literally, "an existing currency is being changed" is
  true every time, and the guard's carve-out has nothing to attach to.
- `context/index/decisions.md` (2026-08-20, one app-level currency) and `docs/statuses.md`
  (no status values, deliberately) do not address it.
- NFR-4 does not choose either: all three options below warn and proceed, none refuses.

**Options, with their cost:**

- **A — warn when the chosen value differs from the stored one.** Free; the screen already
  holds the current value from message 7. Costs one wrong warning at first setup if the owner
  picks USD over the IDR seed — the exact case the guard says should *not* warn.
- **B — warn when any amount exists in the database.** Truthful to the warning's own wording.
  Costs `SettingsDao` a count over `Transactions` / `Accounts` / `BudgetPeriods`. That
  cross-module join is permitted (ISSUE-005 D1) but is **not drawn on this sequence diagram**,
  so choosing it widens the scope boundary `CLAUDE.md` makes absolute — the diagram would need
  a message added and re-rendered.
- **C — always warn on any selection.** Simplest. Drops the guard, i.e. skips part of the
  diagram, which `CLAUDE.md` forbids without this ruling.
- **D — add a "setup complete" column to `Settings`.** Makes the guard literally true, and
  costs `schemaVersion` 2, a new snapshot and migration, plus the ERD, `class-settings.drawio`
  and `map.yaml` going stale with it. `lessons.md` §8: the last "just one column" cost twelve
  artifacts. Raised before the work, not after.

**Answer:** *"for q1 by change currency it just changes the prefix thats all"* — the owner,
2026-08-22. Recorded at `context/index/decisions.md` (2026-08-22, "Changing the currency
changes the prefix and nothing else").

**What it settles, and how the guard resolves.** The answer is about *what changing the
currency does*, and it dissolves the question rather than picking from the menu above.
Changing the currency re-labels: the stored `int` minor units are untouched, nothing is
converted, no other table is read or written, and no exponent arithmetic runs. Under that:

- **D is rejected** — a "setup complete" column would buy a distinction that changes nothing,
  at the cost of `schemaVersion` 2 and the artifacts `lessons.md` §8 predicts.
- **B is rejected** — counting amounts across three modules to decide the wording of a
  message about a prefix is a cross-module join bought for nothing, and it is not drawn on
  the diagram.
- **A is what the guard becomes:** the notice appears when the chosen currency differs from
  the stored one, which is exactly when the prefix changes. **A's only stated cost was a
  "wrong" warning at first setup if the owner picks USD over the IDR seed — the owner's
  answer removes it**, because in that case the prefix really does change and saying so is
  true, not spurious. The guard's "not initial setup" carve-out was written when the change
  was imagined to be consequential; it has no referent once the change is a prefix.

So `opt [the chosen currency differs from the stored one]`. **The diagram's guard text is
corrected at UC-14's as-built pass**, not silently reinterpreted — the fragment stays, one
message stays inside it, and nothing is skipped.
