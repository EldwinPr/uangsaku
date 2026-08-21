# Lessons

Failure patterns this project has actually hit, distilled from fourteen sessions of
`pm/log.md`. Each one happened **more than once**, or cost enough the first time to be
worth stating.

**Why this file exists.** `decisions.md` records *what was decided*; the conventions files
record *how to do a task*. Neither holds the cross-cutting shape of *how this project goes
wrong*, and that shape was only visible by reading the whole log at once — which is too
expensive for anyone to do routinely, and impossible for a subagent starting cold.

Read this before starting work. Every entry is short on purpose; the full narrative is in
[`pm/log-archive-2026-08.md`](../../pm/log-archive-2026-08.md).

---

## 1. A decision is not finished until every register that listed it as open is updated

**Hit six times, four of them in a single day.** The credit/debit naming collision sat in
`fr-nfr.md` §4 as "undecided, blocking schema and UI naming" for a full day after it was
closed by the schema decision. "What a month means" was still described as open in three
separate passages hours after the owner decided it. The workbook's Budgeting module
description still described a lifecycle that had been deleted. The ERD's `Budget_Period`
note still called the calendar-month question undecided.

**Two more surfaced on 2026-08-21, and both had survived over a day undetected** — found
only because an agent was sent into the workbook for an unrelated edit and told to look.
UC-11's `Output` still promised budgets were "editable during the first week and locked
thereafter", and UC-09's `Deskripsi` still justified itself with *"a budget is a commitment
made in advance, so it locks (FR-16)"*. Both rest on the lock ISSUE-004 removed on
2026-08-20 — the same reversal that had already been chased through nine other files that
day. **A sweep that catches nine of eleven feels complete and is not.**

**The mirror image is just as expensive.** The failure this project guards against is a
document claiming something is settled when it is not. Three of these four were the
reverse — a document claiming something was **open when it was settled** — which makes a
finished decision look like a blocker and invites re-arguing it from memory.

**Why no check catches it:** `audit.py` compares documents to each other, and every one of
these passages was internally consistent prose. This is a known limit, deliberately not
papered over with a fake check.

**The narrower form, which is the actual mechanism:** *a rationale attached to a decision
does not get re-read when the decision it justifies is reversed.* Five of the six were
rationales — the sentence explaining *why* a rule existed, sitting somewhere the rule
itself did not. When you reverse a decision, **grep for its reasoning, not just its
statement.** "lock", "locked", "lifecycle" would have found all of these in one pass.

**The distinction that makes the grep usable**, drawn while fixing the 2026-08-21 pair:
*only claims still asserted in the present tense go stale.* UC-11's `Deskripsi` also
mentions the lock — "this use case previously carried the app's only lifecycle (open →
locked → closed); removing the lock collapsed it" — and that is **correct as written and
must not be edited.** It is history, marked as history. This project deliberately keeps
superseded reasoning on file (the Kotlin stack entry, ISSUE-003's whole plan), because a
record of what changed is what makes a reversal auditable. Deleting it would erase the
reason `statuses.md` lists nothing. So the grep finds candidates; the tense tells you which
are defects.

## 2. Changing how a value is *obtained* silently invalidates everything built on it

**Hit three times.**

- **Stored → derived.** `Budget_Period.state` became derived from `starts_on`/`ends_on`.
  The states were checked and were unchanged — correctly. What went unchecked was the
  *entry* into the lifecycle: a period created after its own lock date computes as
  `locked` from the first instant and never passes through `open`. **A derived value has
  no entry point of its own.**
- **Removing a gate removes the status, not just the enforcement.** Deleting FR-16's lock
  did not merely drop `locked` — it collapsed the entire lifecycle, because `open` vs
  `closed` is then just "is this month over", a date comparison that gates nothing.
- **Deriving from editable data.** Payday-to-payday months were rejected because a
  period's boundary would derive from an *editable transaction*, and FR-18 makes every
  transaction editable.

Both of the first two were caught by **re-reading the artifact**, not by any check.

## 3. Look at the render — validation cannot see it

**Six or more defects on this project passed XML validation and the no-comments check and
were caught only by exporting to PNG and looking.** Connectors striking through table
rows; a connector running through an annotation; a group box's dashed border cutting
through its own note's last two lines; `AppDatabase` drawing the component icon twice
(a notation error in UML — two components fused — not a cosmetic one); an edge label wide
enough to cover its own connector, so the render read as two floating boxes with a caption
between them.

Three sub-rules earned separately:

- **Crop tight *and* look at the full diagram.** One defect was invisible in the agent's
  close-up crops and only visible at full-diagram zoom.
- **A render defect gets fixed or escalated — never classified as harmless by the person
  who drew it.** A delegated agent inspected the double-icon defect and reported it as
  "harmless, not a correctness issue". It was a notation error.
- **A fix can make it worse.** Moving a note off a connector's vertical riser put it
  directly on the connector's horizontal band. Re-export after every fix, without
  exception.

## 4. Rendering an artifact catches what parsing it does not

Extracting labels with a regex over `mxCell value=` returned nothing from the worked
sequence examples, and this was very nearly written into a conventions file as "the
examples are unlabelled skeletons, unusable as a regression suite." Rendering one to PNG
immediately contradicted it — they are fully labelled. In a Mermaid-generated file the
labels live on `<UserObject label="…">` wrappers and `mxCell` carries no value at all.

Same lesson as §3, arriving from the opposite direction: **the artifact is the source of
truth, not your parse of it.**

## 5. A check looking at the wrong set passes for the wrong reason

**Hit four times, and this is the most dangerous pattern here** — every instance produced
a *green* result, which is why none of them announced itself.

- `audit.py` hard-coded `FR-1..FR-18`, so it would have **silently stopped checking the
  moment FR-19 existed.** Now derives the range from the document and reports gaps.
- An `ALLOWED_DANGLING` exemption still excused `seq-uc02-add-account.drawio` long after
  the file was drawn. **An exemption that has quietly stopped applying disables a real
  check without saying so** — the same defect as one that never applied. The audit now
  warns when an exemption's file comes back.
- `renders.lock` first hashed **raw bytes**. With `core.autocrlf=true` on Windows, a
  checkout rewrites LF to CRLF while git stores LF — every render would have read stale on
  CI and fresh locally. *Any content hash compared across machines has to say which
  normalisation it means, or it is comparing environments instead of content.*
- CI's `app` job probed for `pubspec.yaml` at the repository root after the package moved
  to `app/`. It would not have failed — it would have **reported success having run
  nothing**, permanently.

**The general form:** *a guard that succeeds when it cannot find its subject is worse than
one that fails.* A red build gets fixed; a green one gets trusted. Any check written
against a literal count, a hard-coded path, or an exemption list needs to fail loudly when
its subject moves.

## 6. Parse and validate in memory, then write — never the reverse

A non-greedy `.*?(?:</mxCell>|/>)` regex over `erd.drawio` matched a row cell's inner
`<mxGeometry … />` instead of its own closing tag, cutting three cells in half. The script
**wrote before validating**, so the damage landed on disk; recovery needed draw.io's
`.$erd.drawio.bkp` and a re-application of an unrelated fix made earlier.

**A regex over XML that stops at the first `/>` will happily cut through nested elements.**

## 7. Raise the cost before doing the work, not after

The owner opened with multi-currency and withdrew it in the next message, once the cost
was laid out: a currency per account, a rate behind every total, FR-1's four figures no
longer summable, a cross-currency transfer needing two amounts. **Raising it first cost
one exchange. Discovering it after the ERD was redrawn would have cost the ERD.**

Same shape produced the `int`-minor-units decision — the owner proposed `double`, one
pushback landed, and the reason it was worth a pushback rather than a note is that the
failure is *unfixable at the query layer* because the error lives in storage.

## 8. "Just add one column" is never one edit

Promoting currency to FR-19 forced UC-14, which forced the question of which module owns
it — and none of the three did. `Settings` became a fourth module, which under
one-diagram-per-module forced a fourth class diagram, which made the component diagram and
all three existing class diagrams stale.

Final tally for one column: workbook (three sheets), ERD, a new class diagram, three
existing class diagrams, the component diagram, `enums.md`, `map.yaml`, `fr-nfr.md`,
`decisions.md`. **Use this as the cost estimate for the next schema-shaped request.**

The plan was amended twice mid-flight (D5, D6) rather than quietly widened — which is the
correct handling and is what `general-rules.md` requires.

## 9. A per-module view cannot show a cross-module cycle

Three class diagrams, each correct about its own module, hid the fact that `Accounts` and
`Transactions` depend on each other in **both** directions — `Accounts` joins
`Transactions` for balances, `Transactions` reads `Accounts` for the record screen's
picker. Putting all three on one page exposed it immediately.

This is the strongest argument on file for the coarse diagram existing on a project where
its stated purpose (a real process or network boundary) nearly did not apply.

## 10. Delegated verification still needs verifying

Two separate incidents. A drafting agent reported a real notation error as harmless (§3).
And an agent drew `AccountsNotifier → TransactionDao`, then reported the missing edge as a
class-diagram gap — when ISSUE-005 D1 already rejects that call outright. The agent had
not been given the file the decision lives in.

**The check that caught the second one was the lifeline rule** — every lifeline must
already exist on a class diagram. That rule made two artifact sets check each other, which
is a per-module class diagram's blind spot.

**When delegating: pass the decision, not just the task.** An agent cannot honour a
constraint recorded in a file it was never told to read.

## 11. A stale plan is read as current

ISSUE-001, 002, 003 and 005 all carried tracker rows saying `DONE` while their `plan.md`
status lines still read "CONFIRMED… work started", "UNBLOCKED… Drawing", or "WRITTEN".
`RULES.md` tells a new session to open the active plan directly, so anyone doing that
would have been told the work was in progress.

Now a checked condition rather than a remembered one. Related: **closing an issue that
supersedes an earlier one means updating the earlier issue's plan too**, not just the
tracker row.

## 12. The audit proves consistency, never correctness

A clean `audit.py` run means the artifacts do not contradict each other or point at things
that do not exist. It **cannot** tell you that an FR matches what the owner meant, that the
ERD's cardinalities are right, or that a diagram renders sensibly.

Do not read a green audit as a green design. The mandatory export-and-look step remains the
only check on render quality, and §3's double-icon defect is what happens when that step is
delegated and its result taken on trust.
