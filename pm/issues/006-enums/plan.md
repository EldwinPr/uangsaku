# ISSUE-006 — `docs/enums.md`, the canonical enum vocabulary

**Status:** DONE 2026-08-20. Owner confirmed and asked for both halves - the file and
the values on the diagrams. All six steps completed; `audit.py` green.
**Depends on:** ISSUE-001 (DONE, the ERD names the columns), ISSUE-002 (DONE, the class
diagrams name the enum types).
**Traces to:** UC-01..UC-10, UC-12 (every UC that reads or writes a typed value).

## Goal

Create `docs/enums.md` — the canonical list of legal **enum values** per column, and the
peer of `docs/statuses.md`. Owner's request, 2026-08-20, replacing the deleted
`docs/rbac-entities.csv` (empty, and meaningless for a single-actor app).

**No new decisions.** Every value below was already decided and is already written
somewhere; this issue moves them to one place and cites where each came from. If drafting
it surfaces a value that was never actually decided, that is a finding to raise, not a
gap to fill in by inference.

## Why the file is needed — the gap is real and specific

`statuses.md` already draws the line this file sits on the other side of. It records
`Transaction.kind` as *"a classification, not a status"* and `Account.settled` as *"a
flag, not a lifecycle"* — correctly excluding both, and leaving them with nowhere to go.
The result today:

| Value set | Where it lives now | Problem |
|---|---|---|
| `Account.group` | `decisions.md` (2026-08-19), `fr-nfr.md` §4 | Fine, but not next to its sibling |
| `Transaction.kind` | **`pm/issues/001-erd/plan.md` only** | The seven kinds and their `from`/`to` semantics exist *only* in an issue plan. `general-rules.md`: a durable fact must not be left in the one-time record |
| `Account.settled` | `statuses.md` (as an exclusion) | A boolean, not an enum — belongs here as a stated non-member |
| "Others" budget bucket | ERD note, `class-budgeting.drawio` | Not an enum value at all — a NULL FK. Belongs here as a stated non-member |

The ERD shows `group` and `kind` as bare column names with no values, and
`class-transactions.drawio` says "the seven kinds (D1)" without listing them. A reader
has to open an issue plan to learn what a `kind` can be.

## Content to draft (all pre-decided, cited)

### `Account.group` — 3 values

`HOLDING` / `RECEIVABLE` / `PAYABLE`. From FR-1's three-way split (spendable, owed to me,
I owe). Decided 2026-08-19 with the schema; `decisions.md` records that it was closed
**by constraint** — NFR-1's fit criterion forbids a debit/credit column, so those words
were never available. Note that here: the naming is load-bearing, not cosmetic.

### `Transaction.kind` — 7 values

`expense` / `income` / `transfer` / `lend` / `borrow` / `repayment` / `adjustment`, with
the `from_account` / `to_account` table from ISSUE-001 D1 **promoted into this file**,
since that table is what makes the enum meaningful. Traces: FR-6, FR-7, FR-8, FR-9, and
UC-03 for `adjustment`.

Carry D1's consequence with it: *"is this spending?"* is `to_account_id IS NULL`, a
property of the data rather than a rule every future query must remember.

### Stated non-members

- `Account.settled` — boolean flag (D8, FR-11), not an enum. Two values, one move.
- The **"Others"** budget bucket — `budget_group_id IS NULL` (FR-17, D5). Deliberately
  not a row and not an enum value; recorded because it looks like one in the UI.
- `Budget_Period` — no status values at all, and `statuses.md` explains why. Cross-link
  rather than restate.

### The rule the file states for itself

Mirroring the test `statuses.md` ends on, so the pair is symmetrical: **a status says
what an entity may do next; an enum says what an entity is.** If a proposed value gates
behaviour it belongs in `statuses.md` and needs a state diagram; if it classifies, it
belongs here and needs none.

## Steps

1. Confirm this plan.
2. Write `docs/enums.md`.
3. Cross-link: `statuses.md`'s exclusions point here; `map.yaml` gains the file.
4. Fix the two artifacts that name an enum without its values — add the value list to
   `AccountGroup` and `TransactionKind` on the class diagrams **only if** it fits the
   existing box style; otherwise cite `docs/enums.md` on the diagram. Re-export and look.
5. `README.md` line 25 lists `docs/` contents and still names `rbac-entities.csv` (now
   deleted) and `nfr.md` (the file is `fr-nfr.md`) — correct both while here.
6. Close per the `CLAUDE.md` checklist; re-run `audit.py`.

## Out of scope

- Any new value. If a set looks incomplete, raise it rather than extending it.
- Currency and the transaction note (`fr-nfr.md` §4). Currency will likely add an enum
  or a column when decided; this file is where it will land, but the decision is not
  this issue's.
- Dart-level naming (`AccountGroup` vs `accountGroup`, how drift stores an enum). That
  is a coding-conventions question and no code exists yet.
