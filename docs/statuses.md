# Statuses

Canonical list of legal status **values** per entity — the vocabulary of what an
entity may do next.

The counterpart to [`enums.md`](enums.md), which holds the values that say what an
entity *is*. **A status gates behaviour; an enum classifies.** Everything excluded from
this file for being "a flag" or "a classification" has a home there — see the split
rule at the top of that file before proposing a value for either.

The other half of this information is the state diagram for each entity, which
says which **moves between these values are legal**. Per
`context/document-writer-only/state-conventions.md` the two must stay in sync:
every value here appears as a state on that entity's diagram, and vice versa.

**As of 2026-08-20 no entity in this project has a lifecycle, so there are no
state diagrams and this file lists no values.** That is a real finding, not an
empty stub — see below. The rule above stands for whenever one appears.

---

## Entities with no lifecycle

Recorded so their absence is a decision rather than an oversight.

- **`Budget_Period`** — **had one until 2026-08-20; no longer does.** It ran
  `open → locked → closed`, and the whole lifecycle hung off FR-16's lock. When the
  owner removed the lock ("from now on it's user responsibility no more guardrails or
  whatever"), `locked` ceased to exist and the remaining pair collapsed: `open` versus
  `closed` is now just "is this month over", derived from `starts_on` / `ends_on` and
  today's date, and it **gates nothing** — a period is fully editable and deletable
  either way. A value that restricts nothing is not a status; it is a date comparison
  the UI can make when it wants to label a period as current or past. Same standing as
  `Account.settled` below. `docs/diagrams/state-budget-period.drawio` was deleted with
  the rule it described.

  *Worth keeping in view:* the dates are still load-bearing. Dropping the lifecycle
  removed a lifecycle, not the `starts_on` / `ends_on` pair, which is what makes
  quarterly and yearly rollups a date-range sum rather than a new column (NFR-3, decided
  2026-08-20 and unaffected by any of this).

- **`Account`** — carries a `settled` flag (D8) for FR-11's "mark it done". Two
  values, one move, no intermediate stages. A flag, not a lifecycle; no diagram.
  Recorded as a stated non-member in [`enums.md`](enums.md) so it is not mistaken for
  a three-value enum later.
- **`Transaction`** — has a `kind` discriminator, which is a classification, not a
  status. A transaction is recorded, may be edited or deleted (UC-09), and has no
  intermediate states in between. Its seven legal values, and which account each side
  touches, are in [`enums.md`](enums.md).
- **`Category`, `Subcategory`, `Budget_Group`** — no status of any kind. Note that
  categories are user-created rows, not a fixed vocabulary, so they are not enum values
  either; `enums.md` records that explicitly.

---

## Why this file is empty, and why that is informative

Every entity here turned out to be either a flag, a classification, or nothing —
and the one genuine lifecycle disappeared the moment the rule enforcing it was
withdrawn. That is the expected shape for an app built on NFR-4 ("the app assists;
it does not police"): **statuses exist to gate behaviour, so an app that gates no
behaviour accumulates none.** If a status value is ever proposed here, the question
to ask first is what it forbids — if the answer is nothing, it is a derived label,
not a status, and it belongs in a query rather than in this file.
