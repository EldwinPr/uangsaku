# Log archive — 2026-08

**Closed 2026-08-21.** The full narrative record of sessions 1-15, from the first repo
survey through FEAT01 being planned. Preserved verbatim and unedited: entries were
accurate when written, and several deliberately record terms and ids that later changed
(`UC Non-BPMN`, `ISSUE-015`). Rewriting them to match a later renumber is exactly the
tidy-up that makes a record untrustworthy.

**You probably want one of these instead:**

- `pm/log.md` — the live log, and the current-state summary at its head.
- `context/index/lessons.md` — the recurring failure patterns distilled out of this file.
  That is the reusable residue; this is the evidence behind it.
- `context/index/decisions.md` — what was decided, and why.

Append-only. Newest entries at the bottom. Tag each: [STATUS] / [DECISION] /
[DISCOVERY] / [TODO].

---

## 2026-08-19 — Session 1

**[DISCOVERY]** Surveyed the repo as inherited. The framework is complete, but
every project-state file was empty: `pm/tracker.yaml`, `pm/active.json`,
`pm/log.md`, `docs/fr-nfr.md`, `docs/statuses.md`, `docs/rbac-entities.csv`,
`context/index/map.yaml`, `context/index/decisions.md` — all 0 bytes.
`docs/workbook.xlsx` had headers on all four sheets and zero rows. `input/` and
`context/files/` held only their READMEs. So: framework present, project state
untouched.

Also confirmed this directory is **not a git repository** — no `.git`, no undo.
Owner will `git init` later. Noted as risk, not acted on.

**[DECISION]** Project confirmed as a personal money tracker (mobile), tracked
in real project state rather than as a framework demo. Requirements enter via
the FR route rather than BPMN. See `context/index/decisions.md`.

**[STATUS]** Framework was archived and replaced with a flat 4/5-file system on
the basis of an external critique, then **fully reverted the same session** at
the owner's direction. All files restored to original locations; the three
subagents restored to `.claude/agents/`. Net structural change to the framework:
none. What survived is recorded as a decision entry, not as new files.

**[STATUS]** Wrote `docs/fr-nfr.md` — 15 FRs across recording / organising /
reviewing / retention, 9 NFRs, an explicit out-of-scope list, and an assumptions
table. Drafted from assumption, not elicitation; marked DRAFT throughout.
**Discarded the same session** — file emptied back to 0 bytes. The content was
invented rather than elicited and the FR shape was wrong. Requirements to be
established by actual conversation instead. The provenance concern recorded in
`context/index/decisions.md` is what this was; it should have blocked the draft
rather than being noted alongside it.

**[TODO]** Blocking, in order:
1. Confirm or reject the five assumptions in `docs/fr-nfr.md` §1.
2. Resolve the `OPEN DECISION` in §2 — are accounts in v1? Changes the entity
   model, so the ERD and workbook Entities sheet both depend on it.
3. Pick the domain language (Indonesian vs English) and record it in
   `context/general-rules.md`, which requires this before terms propagate.
4. Only then: promote confirmed FRs into `docs/workbook.xlsx` → UC Non-BPMN.
   This needs a `plan.md` first — it is an issue, unlike the FR capture above.

**[TODO]** Six open questions parked in `.mc.txt` at root, per owner's request
for a written question file. Stack choice is among them and remains open.

**[DISCOVERY]** `.gitignore` is inherited from the template and still carries
rules for OMG spec PDFs and other template-era paths. Will need revisiting once
a stack exists.

**[STATUS]** Elicitation session held. Owner gave six raw needs (accounts,
transactions, debts, balances, budget, people who owe me money) plus the
category/budget-group distinction, and answered three follow-ups. Key
correction: "balances" meant **balance sheet** — this is a net-worth tracker
that records spending, not a spending tracker. Recorded verbatim in
`input/2026-08-19-owner-scope-conversation/notes.md`.

**[DECISION]** Account model settled — two account types, two-sided
transactions, no chart of accounts. See `context/index/decisions.md`.

**[STATUS]** `docs/fr-nfr.md` rewritten from the session: 11 user-facing FRs,
2 NFRs. Every FR traces to something the owner said; items named but not
discussed (budget mechanics, spendable-vs-held, review, editing, backup) are
parked in §3 rather than invented.

**[TODO]** Next: confirm the FRs with the owner, then resolve §3 and §4 before
any promotion into `docs/workbook.xlsx` — which needs a `plan.md` first.

**[STATUS]** Budget elicited. Budget is a third table alongside accounts and
categories — behaves like an account (holds an amount, drains as used) but is
not one. Monthly, **no rollover** (owner's reason: keeps a month's report
faithful), allocation repeats automatically and stays editable. Categories
confirmed at exactly two levels. `docs/fr-nfr.md` now FR-1…FR-16, NFR-1…NFR-3.

**[DISCOVERY]** Raised and corrected in session: budgets must not appear on the
balance sheet as their own asset line — a budget is a claim on money already
counted, so listing it alongside cash inflates net worth by exactly the amount
budgeted. Budgets partition the spendable figure rather than adding to it.

**[TODO]** FR-16 (budget locks after week one) is tentative — owner said
"maybe". Decide hard lock vs warning, and the escape hatch for a legitimate
week-three change, before building. Likely the first state-diagram subject in
this project.

**[TODO]** Still unanswered after two askings: spendable-vs-held on the FR-1
screen. Changes what the primary screen reports.

**[DECISION]** Spendable vs. held resolved: the FR-1 screen keeps "what I can
spend" separate from "what I'm owed" rather than netting them into one figure.
Consequence — accounts group three ways (hold-and-spendable / owed-to-me /
owed-by-me), which refines the owner's original two-type proposal.

**[DECISION]** Remaining §3 items closed: unbudgeted spending shows under
"Others" (FR-17); FR-16 budget lock adopted as a **hard** lock, no longer
tentative; full CRUD on every entity (FR-18); backup/export deferred by owner.

**[DISCOVERY]** Latent tension recorded in `docs/fr-nfr.md` §3 — FR-18 (edit
anything) versus FR-14/FR-16 (a month's report stays faithful). Editing a past
transaction silently rewrites a report that was already true. Not resolved.

**[TODO]** Owner asked whether OCR of receipts is possible. Answered: yes, but
it rules out a browser-only stack, so it must be decided *before* the stack, not
after. Not yet recorded as a requirement.

**[DECISION]** OCR deferred to the same standing as backup — no commitment.
Recorded with the caveat that a browser-only stack would foreclose it, so the
stack choice should acknowledge that rather than make it by accident.

**[STATUS]** Requirements pass complete for this session: 18 FRs, 3 NFRs, 2
deferred items, 1 recorded tension (FR-18 vs FR-14/16), 4 items in §4 still
undecided. `docs/fr-nfr.md` is ready for owner review.

**[TODO]** Next, in order: (1) owner confirms `docs/fr-nfr.md`; (2) resolve §4
— account-type naming, domain language, currency; (3) stack choice; (4) promote
confirmed FRs into `docs/workbook.xlsx` UC Non-BPMN — which is an issue and
needs `pm/issues/{id}-{slug}/plan.md` first, per the hard gate.

**[DECISION]** FR-18 vs FR-14/16 closed by the owner — not a conflict. Budget
is a commitment (locked); a transaction is a record (correctable). Generalised
to NFR-4, "the app assists, it does not police", and recorded in
`context/index/decisions.md` as the default answer for future
block-or-allow questions.

**[STATUS]** Session 1 closed. Requirements phase complete: 18 FRs, 4 NFRs, 2
deferred, all traced to `input/2026-08-19-owner-scope-conversation/`. Assessed
as sufficient to move on, with three gaps recorded in `docs/fr-nfr.md` §4 —
the meaning of "a month", where the data lives, and three things assumed but
never stated (transaction date, transaction note, single user).

`.mc.txt` rewritten to live questions only; answered ones dropped rather than
left to go stale. `pm/active.json` populated — no issue open, next action
recorded.

**[TODO]** Untouched and still correct to be empty: `docs/workbook.xlsx`,
`docs/requests.md`, `pm/tracker.yaml`, `context/index/map.yaml`,
`docs/statuses.md`, `docs/rbac-entities.csv`, `context/files/`.

---

## 2026-08-19 — Session 2

**[STATUS]** `docs/fr-nfr.md` confirmed by the owner and promoted into
`docs/workbook.xlsx` via Route 2 (FR -> UC). 13 rows, UC-01
through UC-13, all with actor `Owner`. `Modules` sheet populated (3 rows) and
`Entities` sheet derived (5 entities). Traceability table in `fr-nfr.md` section 5
now maps every FR to its Kode or records why it produced none.

**[DECISION]** Domain language is **English**, recorded in
`context/general-rules.md`. The owner's verbatim source material is English, so
the existing rule ("match the language the source documents use") picks it
without a preference call. The workbook's Indonesian column headers are template
structure, not domain terms, and are explicitly not an exception.

**[DECISION]** FR-18 ("full CRUD across everything") is narrowed rather than
expanded. A literal reading gives ~25 rows, one per verb per entity. Owner's
ruling: a dedicated correction use case for transactions only (UC-09), plus
UC-03 for correcting what an account holds. Everywhere else, edit and delete
are alternate flows of the creating use case and are stated in its `Deskripsi`.

**[DECISION]** Three modules — Accounts, Transactions, Budgeting. The owner's
position was that a small single-user app has no use for modules, and that is
fair on its own terms; `Modul` was still populated because the `Entities` sheet
requires exactly one owning module per entity, and that single-writer rule is
what keeps the schema decomposable later. No Reporting module: the two viewing
use cases (UC-01, UC-12) sit with the data they read, so no module is empty.

**[DECISION]** FR-14 and FR-17 produce no UC row. Both fail admission test 1 —
no actor, nobody sets out to perform them. They are system rules and are
recorded as constraints inside the rows they bind (UC-04, UC-11, UC-12).
The four NFRs likewise get no rows: the workbook defines no NFR sheet, and
NFR-1/2/4 are policies rather than measurable fit criteria, so `fr-nfr.md`
stays their source of record and they are cited inline.

**[DISCOVERY]** Two pre-existing workbook defects found and fixed while in the
file, both instances of the `ws.max_row` staleness already documented in
`workbook-conventions.md`: the primary UC sheet carried 6 blank trailing rows, and the
`Entities` sheet was missing its `Modul` column entirely (it had
Entity/Owner/ERD, not Entity/Modul/Owner/ERD). Header cells were rewritten
explicitly as the last step of the rebuild, per the same convention.

**[TODO]** Next, in order: (1) resolve the remaining `fr-nfr.md` section 4 items —
account-type naming, currency, what "a month" means, where the data lives;
(2) stack choice; (3) the ERD, where the deferred budget-identity question and
the entity `Modul` assignments get tested against a real schema. UC-11 is
flagged as the likely first state-diagram subject (budget month: open ->
locked -> closed).

**[DECISION]** UC sheets renamed `UC BPMN` -> **`UC FR`** and `UC Non-BPMN` ->
**`UC Non-FR`**, and the 13 rows moved onto `UC FR` and recoded from
`UC-N01..UC-N13` to plain **`UC-01..UC-13`** (owner's call, same session).

The first fill-in took the framework's sheet names literally and put every row
on `UC Non-BPMN`, because that is where Route 2 lands on a BPMN project. On a
project with no BPMN that is backwards twice over: it names this project's only
real output after a route it does not use, and it pushes the main sheet into the
`UC-N` prefix, whose whole job is to mark rows as *not* from the main route. The
split the two sheets actually encode is "the route carrying this project's
requirements" vs "everything else" — which here is FR vs not-FR.

Generalised into `workbook-conventions.md` rather than patched locally: the sheet
pair is named for whichever route carries the project's requirements
(`UC BPMN`/`UC Non-BPMN` or `UC FR`/`UC Non-FR`), the primary sheet always takes
plain `UC-xx`, and the second always takes `UC-Nxx`. Pick one pair per project.
The `examples/` demos are BPMN projects and keep the original pair, so the
regression suite still holds. `README.md`, `general-rules.md`,
`context/index/decisions.md`, and `.claude/agents/workbook-xlsx-author.md` updated
to match; the agent is now told to read `wb.sheetnames` rather than assume a pair.

Cross-references inside `Deskripsi` cells were recoded with the row codes, so
UC-02's pointer to UC-03, UC-05's to UC-08, UC-10's to UC-08 and UC-13's to UC-11
all still resolve. Verified: zero `UC-N` strings left anywhere in the workbook.

Older log entries above still say `UC Non-BPMN`. Left alone deliberately — the log
is append-only and those entries were accurate when written.

**[DECISION]** Stack chosen: **native Android — Kotlin + Jetpack Compose + Room
over SQLite, no backend.** Full reasoning in `context/index/decisions.md`.

Cross-platform rejected in three steps. React Native and Capacitor were ruled out
by the owner on runtime weight and on being the wrong shape for a project with no
existing web app. Flutter was the real contender and was not dismissed on those
grounds — it is AOT-compiled with no JS runtime or WebView, `drift` matches Room's
reactive-SQL story, and ML Kit is plugin-reachable, so nothing in the requirements
excluded it. It came down to one question: whether iOS is a roadmap item or a
hypothetical. Owner: **"polite maybe."** Flutter's whole premium buys portability,
so a maybe does not justify it. Secondary wins for Kotlin once portability stopped
counting: smaller install, no second managed heap beside ART, no engine init before
first frame — and cold start matters disproportionately for an app opened to record
one expense and closed.

**[DECISION]** Backup is an **export file via the Storage Access Framework**, not
sync — which is why the stack no longer waits on the unresolved "where the data
lives" question. If sync ever happens the backend sits outside the app in its own
stack (owner's position), so the app gains a sync client rather than being
restructured.

**[DECISION]** NFR-1 and NFR-4 given measurable fit criteria, closing the gap
flagged earlier the same session. NFR-1: no screen exposes an account code, journal,
debit/credit column, or period close, and no flow asks the user to pick two sides —
a walkable checklist rather than a fake usability metric. NFR-4: exactly one user
action is refused (the FR-16 budget lock); the count is the test, so a second block
cannot be added quietly. NFR-2 already passed the bar; NFR-3 cannot be tested until
a schema exists.

**[DISCOVERY]** Room is not a preference, it is NFR-2 enforcement. A DAO returning
a `Flow` collected by Compose means no balance field exists in the schema to write
to — "exactly one source per number" becomes the only thing the code can express,
and UC-09 costs nothing because deleting a row recomputes everything.

**[TODO]** Keep the domain and data layer free of Android imports (no `Context`, no
Android types in entities or derivation logic). Costs nothing now, keeps Kotlin
Multiplatform available if the polite maybe ever becomes real. Do not adopt KMP now.

**[TODO]** FR-16's budget lock is the only time-dependent behaviour in the app.
Inject the clock; do not call the system clock directly, or the lock cannot be
tested without changing the device date. Still blocked on what "a month" means (§4).

**[TODO]** Remaining `fr-nfr.md` §4 items: account-type naming ("credit/debit
account" collision), currency, what "a month" means, whether a transaction carries
a free-text note. Then the ERD.

**[DECISION]** Stack reversed the same day: **Flutter/Dart + `drift`**, superseding
the Kotlin + Compose + Room decision recorded hours earlier. Owner set iOS as a
working assumption ("still not sure to be honest, okay for now just assume will be
used in ios"), which is precisely the hinge the Kotlin entry had named in advance —
it said outright that Flutter wins if iOS is real rather than hypothetical. The
premise flipped and the recorded logic did the rest; no new argument was needed.
Contributing factor, raised by the owner and absent from the first decision: they
have never built a mobile app and have no existing stack, and Flutter reaches a first
working screen faster.

The Kotlin entry in `context/index/decisions.md` was **left intact and marked
superseded**, not edited away. It names the exact assumption that changed, which is
what makes this reversal auditable instead of just confusing.

**[DECISION]** Recorded as **provisional**. The iOS premise is an assumption, not a
confirmed requirement — deliberately placeholdered so the ERD and class diagrams can
proceed. If iOS is dropped for good, re-open it: the Kotlin case becomes correct again
on its own terms.

**[TODO]** Hard constraint from the owner: **must not be heavy on old Android phones** —
and this is the one axis where Flutter is objectively worse than what it replaced.
Treat as build requirements, not advice: per-ABI split APKs or an App Bundle (never a
universal APK), test on a real low-end device rather than an emulator, keep the plugin
list short. Cold start is the metric — the app is opened to record one expense and
closed, so startup *is* the user experience. If it degrades on the target device that
is a stack-level regression and the decision re-opens.

**[DISCOVERY]** Two things genuinely lost, recorded so they are not rediscovered as
omissions: OCR (`fr-nfr.md` §3) moves from a first-party Google library on Android to a
Flutter plugin, gaining a maintainer dependency; and footprint plus cold start both get
permanently worse, which collides head-on with the old-phone constraint above. That
tension is the thing to watch on this project.

**[TODO]** The earlier "keep the domain layer free of Android imports" KMP hedge is
**void** — Flutter covers iOS directly. Replaced by the analogous discipline: keep
entities and derivation logic in pure Dart, free of Flutter widget imports, so the
domain stays testable without a widget harness.

**[TODO]** Flutter state management (Provider / Riverpod / Bloc / setState) left
deliberately undecided — a UI-layer choice that touches neither the schema nor the ERD,
and a known place for a first-time Flutter developer to stall. Decide it against a real
screen, not in the abstract.

**[STATUS]** ISSUE-001 (System ERD) **DONE**. `docs/diagrams/erd.drawio` — 6
entities in 3 module groups, 7 Crow's Foot relationships, all five design
annotations placed. Workbook reconciled: the `Budget` split meant deciding per use
case which half each one touches, so UC-11/UC-12/UC-09 reference both
`Budget_Group` and `Budget_Period` while UC-04/UC-05/UC-13 reference only the
group. Entities sheet now 6 rows with `ERD` = true.

**[DISCOVERY]** The export-and-look rule earned its keep three times on one
diagram, which is worth recording because the cost of skipping it would have been
a wrong artifact that passed every automated check. The agent caught two connectors
exiting mid-row and striking through `category_id`/`budget_group_id`. I then caught,
at full-diagram zoom, a third: the `Budget_Group` -> `Transaction` connector running
straight through the FR-8/FR-9 annotation — invisible in the agent's close-up crops,
which is exactly the failure mode `drawio-general-guide.md` warns about. **And my
own first fix made it worse** — moving the note down put it directly on the
connector's horizontal band instead of its vertical riser. Only the second attempt
(narrowing the note to a column that stops short of the riser at x~708) was clean.
Every one of these states passed XML validation and the no-comments check.

**[TODO]** `docs/diagrams/.$erd.drawio.bkp` is a draw.io editor backup left behind
by opening the file in the desktop app. Not deleted here — flagging rather than
removing someone's backup unasked. It should not be committed; a `.gitignore` entry
for `.$*.bkp` would stop it recurring.

**[DECISION]** ISSUE-002 class diagrams: drift-generated classes (row classes and
companions) are **omitted** from the diagrams. They are real classes, so
`class-diagram-conventions.md`'s "one box = one real class" arguably admits them,
but drawing ~12 boxes of generator output would roughly double each diagram to show
code nobody authored. Only the table declarations that are actually written get a
box, with a note that the rest is generated from them.

**[STATUS]** ISSUE-002 **BLOCKED** on the state-management choice. Owner chose to
wait rather than draw a provisional ViewModel layer. Recorded as blocked rather than
descoped: the ViewModel is the middle link of the drift table -> DAO -> ViewModel ->
Screen chain that is the entire point of these diagrams, so drawing the outer two
layers with a hole in the middle is not a smaller useful version.

**[TODO]** Unblocking ISSUE-002 needs one decision — Riverpod / Bloc / plain
setState. It requires no code first. The budget-month state diagram
(`Budget_Period` open -> locked -> closed) is unblocked and independent of it.

**[STATUS]** ISSUE-003 diagram drawn: `docs/diagrams/state-budget-period.drawio`
(OPEN -> LOCKED -> CLOSED, four transitions, all traceable). `docs/statuses.md`
populated, including why the other five entities have no lifecycle so their absence
reads as a decision. Render independently verified. Issue stays open, not closed:
Q1-Q3 are annotated on the diagram rather than answered, and Q1 would change the ERD.

**[STATUS]** `docs/diagrams/class-budgeting-draft.drawio` drawn as a **teaching
explainer, not ISSUE-002's deliverable** — the owner said they do not understand the
class system yet and asked to see one. Four labeled bands (Screen / ViewModel / DAO /
drift tables) using the owner's own vocabulary rather than a named pattern; EBC
explicitly avoided per their earlier rejection. ISSUE-002 remains BLOCKED.

**[DISCOVERY]** Rough edge in the draft, from my spec rather than the agent: `Clock`
and `BudgetConsumption` were placed in the "DAO (data access)" band because that is
where I put them in the brief, but neither is data access — `Clock` is an injected
dependency and `BudgetConsumption` is a result type. The bands are a teaching device,
not an architecture, so it renders fine; worth fixing if this draft is ever promoted
into the real ISSUE-002 deliverable.

## 2026-08-20

**[DECISION]** All three ISSUE-003 open questions answered by the owner.

*Q1 - `Budget_Period.state` is derived, not stored; the ERD column is dropped.* The
owner reached this from a different direction than the recommendation on file, and
the owner's angle is the stronger one: a three-value enum answers only "what is this
right now" and cannot be aggregated, while the `starts_on`/`ends_on` pair makes
quarterly and yearly reports a date-range sum with no new column and no migration.
That is NFR-3 satisfied by removing something rather than adding it. Deliberately did
NOT add a stored `is_active` flag in its place - it would reintroduce exactly the
staleness the decision removes.

*Q2 - skipped months are not backfilled.* Gaps in the history are real and shown as
gaps. Owner: "it's users commitment not app problem." Squarely NFR-4.

*Q3 - a budget period is deletable only while open.* Resolves a contradiction rather
than a gap: FR-18 promised full CRUD over budgets, FR-16 said a locked budget cannot
change, and section 3 had only ever settled *editing*. The load-bearing insight is
that deletion had to be closed off too - a budget you can delete after it locks is a
budget you can escape, because deleting and recreating at a new amount sidesteps
FR-16 and leaves the lock enforcing nothing. FR-18 amended in `fr-nfr.md` to carry
the exception rather than leaving two documents in conflict.

**[DISCOVERY]** Broke `erd.drawio` while dropping the `state` column: a non-greedy
`.*?(?:</mxCell>|/>)` regex matched the row cell's inner `<mxGeometry ... />` instead
of its own closing tag, cutting three cells in half and leaving orphaned tags. Worse,
the script **wrote the file before validating it**, so the damage landed on disk.
Recovered from draw.io's `.$erd.drawio.bkp`, re-applied the 22:10 annotation fix, and
redid the removal with each cell matched to its own closing tag - validating before
writing this time. **Rule for any future .drawio surgery: parse-and-validate the
result in memory, and only then write.** A regex over XML that stops at the first
`/>` will happily cut through nested elements.

**[DISCOVERY]** The replacement ERD note then overflowed `grp_budgeting` (box bottom
y=480, note y=360 h=160), so the group box's dashed border struck through its last
two lines - the same line-through-text defect twice in one session, from opposite
causes. Moved below the box. Full-render inspection has now caught five defects on
this project that passed XML validation and the comment check.

**[TODO]** `pm/tracker.yaml` ISSUE-003 can close once the state diagram carries the
new OPEN -> deleted transition and the resolved annotations.

**[STATUS]** ISSUE-003 **DONE**. `docs/diagrams/state-budget-period.drawio` carries
the OPEN -> deleted transition and the resolved annotations; render independently
verified (two arrows into the final state arrive from different directions and read
as distinct). `docs/statuses.md`, `context/index/map.yaml`, `context/index/decisions.md`
and `docs/fr-nfr.md` all reconciled. PNGs re-exported for all three diagrams.

**[DISCOVERY]** Open questions were initially recorded only in `pm/` (issue plan,
tracker, log, active.json) and not in `docs/fr-nfr.md` section 4, the canonical
"Not decided" register. Caught only because the owner asked where they lived. The
rule is already written in `general-rules.md` - `pm/` records what happened, `docs/`
and `context/` hold what is true about the system - and an open question filed only
in an issue plan disappears when that issue closes, which is precisely wrong for a
question that outlives it. Q2 and Q3 would have vanished with ISSUE-003. Corrected:
requirements-level questions go to `fr-nfr.md` section 4, design-level ones to
`decisions.md`.

**[DECISION]** State management is **Riverpod**, unblocking ISSUE-002. Asked as a
prose walkthrough rather than a pick-list, because the owner said this is their first
mobile project and wanted to understand the choice, not just make it. The deciding
argument is that this app has an unusually *small* state-management problem: drift
DAOs already return reactive streams, so the database does the notifying, and most of
what the big libraries exist for (managing a stale in-memory copy of server data)
does not apply with no server. Riverpod's `StreamProvider` consumes a drift stream
with no adapter layer. Bloc was rejected as ceremony that would bury the dependency
chain the diagrams exist to show; plain `setState` because it collapses the middle
layer and puts the screen in direct contact with the DAO; Provider because it is the
same design with runtime rather than compile-time wiring errors. Full reasoning and
the known cost (Riverpod's multi-generation docs; we pin `Notifier`/`AsyncNotifier`)
in `context/index/decisions.md`.

**[STATUS]** ISSUE-002 **DONE**. `docs/diagrams/class-accounts.drawio`,
`class-transactions.drawio`, `class-budgeting.drawio`. Plan rewritten first (the
gate), then drawn. The Riverpod choice split the drafted `*ViewModel` middle layer
into two honest halves - `StreamProvider` objects for reads, `Notifier` classes for
writes - leaving the chain and arrow direction unchanged. Added one class not in the
original draft, `CategoryDao`, so UC-13's category CRUD does not make `TransactionDao`
the write path for two unrelated concerns; recorded in the plan.

**[DISCOVERY]** The `Transaction` naming risk carried since the plan was written is
**cleared, with no rename and no ERD change**. Checked against the drift docs rather
than reasoned from memory: drift runs transactions through a *method*,
`transaction(() async {...})`, so there is no public drift class named `Transaction`
for a generated row class to collide with. The conflict drift's FAQ documents is the
reverse case - your own imported `Transaction` shadowing the generated one - which
cannot arise here. If a third-party `Transaction` is ever imported, the documented fix
is modular code generation, not a rename.

**[DISCOVERY]** `jumpStyle=arc` renders nothing unless the jumping edge comes **later
in document order** than the edge it crosses. Z-order follows document order and the
arc belongs to the jumping edge, so an edge underneath gets painted straight over and
the result is indistinguishable from the bare crossing the jump was added to fix. Cost
a full validate/export/inspect cycle spent assuming the style string was wrong when the
style was always correct and only the cell position was not. Written into
`drawio-general-guide.md` next to the existing line-jump rules. This is the sixth defect
on this project caught only by looking at the render.

**[DISCOVERY]** A DAO fanned in from four providers has no clean straight-line layout
unless the DAO box is tall enough to give each incoming edge its own entry height.
Making the DAO box span the vertical range of its callers turns four jogging edges into
four straight ones and removes the corridor-merging problem entirely - but leaves a
large empty box, so the box then has to carry its method list to look deliberate rather
than oversized. Applied on all three diagrams.

**[DECISION]** Standardised the tail of the chain as **DAO -> AppDatabase -> tables**
on all three diagrams, rather than the DAO pointing at both the database and each table
directly. Truthful (`@DriftDatabase(tables: [...])` is exactly this relationship), and
it routes without forcing long edges across the query-result column. The first Accounts
draft had the redundant direct edge and it was removed for consistency.

**[TODO]** `docs/diagrams/class-budgeting-draft.drawio` is now **stale** - it predates
the Riverpod decision, still shows a `BudgetViewModel`, and carries a note saying state
management is undecided. Flagged as superseded in `context/index/map.yaml` but not
deleted, since it is a teaching artifact the owner may still want. Decide whether to
delete it or update it; leaving a stale design doc in place is the failure mode
`decisions.md` already warns about.

**[TODO]** Step 4 of the `general-rules.md` done-definition (mark the owning workbook
row implemented) had no target: `docs/workbook.xlsx` has no implemented/status column
on `UC FR`. Not invented one - adding a column is a workbook-structure change, not an
issue-close action. Worth deciding whether that step applies to documentation issues at
all, or whether the workbook needs the column.

**[STATUS]** Deleted `docs/diagrams/class-budgeting-draft.drawio` and its PNG at the
owner's instruction, closing the TODO raised above. `context/index/map.yaml` no longer
carries an `explainers` section. The real per-module diagram supersedes it.

**[DISCOVERY]** Reviewed `state-budget-period.drawio` for anything else it needed and
found one genuine gap - **created by ISSUE-003's own decision, and missed when that
issue closed.** Under a stored-state model the initial transition `created -> OPEN` was
unconditionally true, because the state was written at insert time. Once Q1 made state
*derived* from `starts_on` / `ends_on` / today, that stopped holding: a period created
after its own lock date - manually on day 20, or for a month already over - computes as
`locked` or `closed` the moment it exists. It never passes through `open`, so it can
never be edited or deleted. The diagram still claimed otherwise.

This is the general shape worth remembering: **changing a value from stored to derived
silently rewrites every transition that assumed the value could be set independently of
the data it is now computed from.** The lifecycle was checked for the *states* being
unchanged (Q1's note says as much) and that was correct; what went unchecked was whether
the *entry* into that lifecycle still held. A derived value has no entry point of its
own - it is whatever the dates say from the first instant.

No arrow drawn either way: `state-conventions.md`'s hard rule requires a stated business
rule behind every transition, and there is none for this. Annotated on the diagram under
a new "Open question - NOT decided" heading and recorded in `docs/fr-nfr.md` section 4,
so it outlives any issue. Render re-verified after the edit.

Everything else on that diagram checked out and was deliberately left alone: shape styles
match `state-conventions.md` exactly (`umlState`, `ellipse;fillColor=strokeColor`,
`shape=endState`), all five transitions trace to a stated FR, and the two arrows into the
final state are legitimate - closure and deletion both genuinely end the lifecycle, even
though only one destroys the row.

**[DECISION]** **No guardrails.** Owner removed FR-16's budget lock - *"i guess let
budget be full crud like other, it's about users discipline anyways"*, then *"from now
on it's user responsibility no more guardrails or whatever."* Raised the cost once
before acting and the owner reaffirmed, so it proceeded as their call. Full reasoning
in `context/index/decisions.md`; ISSUE-004 opened, planned, confirmed and closed.

The cost is worth restating because the change is easy to misread: **FR-16's rationale
was report fidelity, not discipline** - *"a report measured against a moving target says
nothing."* What removing it costs is not restraint, it is a **measurement**: UC-12's
spent-vs-budget comparison is now always satisfiable after the fact, since nothing
distinguishes an amount set in advance from one raised later to match what was spent.
The owner accepted that knowingly.

**[DISCOVERY]** Audited `docs/fr-nfr.md` end to end for anything that refuses, blocks
or enforces. **Exactly one guardrail existed in the whole document - FR-16** - plus
three passages dependent on it (FR-18's carve-out, NFR-4's exception sentence, NFR-4's
fit criterion). Everything else that looked like a candidate was something else on
inspection: FR-8/FR-9's "must not count as spending" is classification correctness,
FR-12's soft limit is already the non-guardrail model, and NFR-1's prohibitions
constrain *the app* rather than the owner - they are anti-guardrails, removing ceremony.
The useful distinction that came out of it, now recorded in `decisions.md`: **this
project's "no guardrails" rule is about refusing user actions, not about the absence of
all structure.** That is why FR-10's two-level category depth was flagged but kept -
it restricts the owner, but it is data shape the owner chose, not a mechanism enforcing
their behaviour. Owner confirmed keeping it.

**[DISCOVERY]** NFR-4's fit criterion is a **counter** - it read "exactly one user
action in the app is refused... a second refusal appearing anywhere is a violation."
Removing the lock took it from one to zero, which makes the test *sharper*, not looser:
there is no longer a sanctioned exception that a future refusal can be argued as similar
to. A fit criterion written as a count degrades gracefully when the thing it counts is
removed, which is a good argument for writing them that way.

**[DISCOVERY]** **Status values exist to gate behaviour, so removing the gate removes
the status - not just the enforcement.** `Budget_Period` ran open -> locked -> closed.
Deleting the lock did not simply drop `locked`; it collapsed the whole lifecycle,
because `open` versus `closed` is then just "is this month over", a date comparison that
restricts nothing. By `statuses.md`'s own precedent for `Account.settled` - *"a flag,
not a lifecycle; no diagram"* - `Budget_Period` moved to the no-lifecycle section, and
`docs/statuses.md` now lists **no status values for any entity in the project**. That is
the expected shape for an app built on NFR-4 and is written into the file itself: an app
that gates no behaviour accumulates no statuses. The test proposed there for any future
proposal - *ask what the value forbids; if nothing, it is a derived label belonging in a
query, not a status* - is the reusable part.

This is the second time in two days that a change to how a value is *obtained* silently
invalidated things built on it (the first: stored -> derived rewriting the entry
transition). Both were caught by re-reading the artifact rather than by any check.

**[STATUS]** ISSUE-004 **DONE**. Files touched: `docs/fr-nfr.md` (FR-16 rewritten,
FR-18 carve-out removed, NFR-4 tightened, section 3 ruling marked superseded, section 4
question marked dissolved, section 5 traceability updated), `docs/statuses.md`
(rewritten - no entity has a lifecycle), `docs/diagrams/state-budget-period.drawio`
(**deleted** with owner's explicit yes), `docs/diagrams/class-budgeting.drawio`
(`isEditable()`, `stateOf()`, `BudgetPeriodState` box and its edge all removed; the two
notes resting on the lock rewritten; render re-verified), `docs/workbook.xlsx` UC-11
`Deskripsi`, `context/index/decisions.md` (two entries marked superseded, one new),
`context/index/map.yaml`, `pm/issues/002-class-diagrams/plan.md` (kept current rather
than left stale), `pm/tracker.yaml`.

**[TODO]** Superseded-artifact hygiene held up this time - ISSUE-002's plan was updated
in the same pass rather than left to rot, which is the failure that got
`class-budgeting-draft.drawio` deleted this morning. Worth making explicit in the close
checklist: **closing an issue that supersedes an earlier one means updating the earlier
issue's plan too**, not just the tracker row. `CLAUDE.md`'s checklist does not currently
say this.

**[DISCOVERY]** Readiness check before moving on surfaced a **stale blocker**: §4 of
`fr-nfr.md` still listed the "credit/debit account" naming collision as undecided and
blocking "schema and UI naming". It was actually closed on 2026-08-19 with the schema
decision - `Account.group` is `HOLDING` / `RECEIVABLE` / `PAYABLE`, the words never
appear - recorded in `decisions.md` and shipped on the ERD the same day. The §4 row was
simply never removed. Corrected, and moved down as a "Closed 2026-08-19" note rather
than deleted, so the reason (closed *by constraint* - NFR-1 forbade the column, so those
terms were never available) stays on file.

Worth noting the shape, because it is the mirror image of the failure this project keeps
guarding against. The usual worry is a doc claiming something is settled when it is not;
this was a doc claiming something was **open when it was settled**, which is just as
expensive - it makes a finished decision look like a blocker and invites re-arguing it
from memory. **A decision recorded in `decisions.md` is not finished until the register
that listed it as open is also updated.**

---

## 2026-08-20 — ISSUE-005, the system component diagram

**Asked:** "can you help me finish the documentation, either component (if needed) or
sequence."

**[DECISION]** **Sequence diagrams are not due yet; the component diagram was the last
Phase 1 artifact.** `CLAUDE.md`'s sequence-diagram gate binds *implementation* issues —
ISSUE-001's plan already recorded that a documentation issue has no runtime interaction
to sequence and that its scope statement stands in place of the diagram. There is no
`sequence-conventions.md`, `map.yaml` tracks no sequence diagram, and no code exists.
Per-UC sequence diagrams arrive with the first implementation issue.

**[DECISION]** **The component diagram was worth drawing, but not for the reason its own
conventions file gives.** `component-conventions.md` justifies the diagram entirely on
making a real process/network boundary visible against an organizational one — and this
app has no backend, no queue and no HTTP, so on that argument the diagram would have
been four boxes and seven solid lines. It earns its place on a different ground: the
three class diagrams each draw one module in isolation, and nothing in the repo showed
what crosses between them. Recorded in the plan so the reasoning does not have to be
reconstructed if someone later asks why this exists.

**[DECISION]** **drift runs the database on a background isolate**
(`NativeDatabase.createInBackground`). Owner's call. Worth restating in the terms the
`decisions.md` entry uses, because the natural shorthand for it is wrong: **this is not
concurrent database access.** drift still serialises statements; nothing here makes
writes parallel or introduces a race. What changes is *where* the work runs — off the
UI isolate, so the screen stays responsive. Anyone reasoning about locking or write
ordering from the word "concurrency" would reason wrongly. Decided on its merits (UC-01
and UC-12 both scan and join the whole `Transactions` table, behind the screen the owner
opens most often, and that cost grows every month), not as a side effect of the diagram.

**[DECISION]** **D1 — modules reach each other's data by SQL join on the shared
database, not by calling another module's DAO.** Owner confirmed. The alternative (one
owner per table) is the more defensible boundary and was rejected because it turns UC-01
into several queries stitched together in Dart, which is a second place for a number to
come from and so runs against NFR-2. Accepted cost, now written on the diagram itself:
table ownership is enforced by nothing at all, and a `Transactions` schema change means
checking three modules.

**[DISCOVERY]** **A per-module diagram cannot show a cross-module cycle, however
carefully it is drawn.** Putting the three modules on one page immediately exposed that
`Accounts` and `Transactions` depend on each other in **both** directions — `Accounts`
joins `Transactions` to derive balances (UC-01, UC-02, UC-10), `Transactions` reads
`Accounts` for the record screen's account picker (UC-04..UC-08). Three correct class
diagrams hid it, because each was correct about its own module. Harmless in one process,
but the two can never be separated without breaking one of the two reads. Drawn as two
distinct edges, not one bidirectional arrow, so each direction's reason stays legible.
This is the strongest argument on file for the coarse diagram existing on a project
where its stated purpose nearly did not apply.

**[DISCOVERY]** **The conventions file's boundary vocabulary was incomplete, and use
found it.** Its table had three mechanisms — direct call, queue job, HTTP call — all of
which assume a real boundary is either a network hop or a worker hop. An isolate is
neither, and is a real boundary: isolates do not share memory, so every call across the
line is serialised and message-passed. Added as a fourth mechanism (`dashPattern=1 3`,
labeled `isolate call: message-passed`), with the general form written into the file:
"boundary" means anything that stops a direct in-process call from being possible.
Also fixed a line in the worked example that had gone stale the moment the fourth
mechanism was added — it told the reader not to invent "a fourth edge type."

**[DISCOVERY]** **The delegated agent's own render check passed something it should have
failed.** `diagram-drawio-author` exported, inspected, and reported one quirk as
"harmless, not a correctness issue": the `AppDatabase` box drawing draw.io's component
icon twice. In UML a box with two component icons reads as two components fused into
one, which is a notation error, not a cosmetic one. Root cause was the box being sized
100x320 while its three siblings were 80x220, to fit a subtitle. Fixed by normalising
the box and moving the subtitle to its own caption label below it; re-exported and
re-checked. **The export-and-look rule held; what nearly failed was accepting a
subordinate's judgement that a visible anomaly did not matter.** The rule is worth
stating as: a render defect gets fixed or escalated, never classified as harmless by
the person who drew it.

**[STATUS]** ISSUE-005 **DONE**. Phase 1 documentation is complete — ERD, three class
diagrams, the workbook (UC-01..UC-13), `fr-nfr.md`, and now the component diagram. No
state diagrams and no BPMN, both by design and both explained at their canonical homes.
Files touched: `docs/diagrams/component-overview.drawio` (new, 4 components, 7 edges,
render verified, 0 XML comments), `docs/diagrams/component-overview.png`,
`context/guide/component-conventions.md` (fourth edge mechanism + stale-wording fix),
`context/document-writer-only/examples/elements.drawio` (gained `shape=component` and
`shape=requiredInterface`, neither previously present), `context/index/map.yaml`,
`context/index/decisions.md` (two new entries), `pm/issues/005-component-diagram/plan.md`
(new), `pm/tracker.yaml`, `pm/active.json`.

**[TODO]** Nothing is queued. The natural next step is the first implementation issue —
whose plan *would* need a sequence diagram. Before code, three `fr-nfr.md` §4 items
still bear on the schema: currency, **what "a month" means** (calendar vs
payday-to-payday — it blocks FR-13/14/15/16 and every report, and calendar has only ever
been assumed), and whether a transaction carries a free-text note.

**[TODO]** Two process questions carried from ISSUE-004 are still open and both were
touched again today: the workbook "mark the row implemented" step was skipped a second
time (the `UC FR` sheet has no such column), and the generated PNGs are committed while
`drawio-general-guide.md` line 60 still says the project keeps only `.drawio` sources.
The `docs/diagrams/` convention and that line have now disagreed across five issues —
one of them should give.

---

## 2026-08-20 — "A month" decided, and a documentation audit

**Asked:** "calendar month, can you run checks to make sure current documentation is
enough."

**[DECISION]** **"A month" is a calendar month.** Owner's call, closing the last
`fr-nfr.md` §4 item that blocked a schema decision. Payday-to-payday was the
alternative and is arguably truer to how a salaried person experiences a month; it lost
because a period's boundary would then be derived from an *editable transaction* — a
period could not exist before its opening payday, editing that payday would silently
move the boundary (and FR-18 makes every transaction editable), and FR-15's automatic
next-period creation would have nothing to fire on. **Same failure shape this project
has now hit three times: deriving a value from editable data silently rewrites
everything built on it.** Nothing in the artifacts changed — `Budget_Period` already
carried `starts_on` / `ends_on` as plain dates rather than a bare `YYYY-MM` key, which
is both what calendar months want and what a future payday-to-payday change would need.

**[DISCOVERY]** Wrote `audit.py` — a repeatable consistency check over the whole paper
trail — rather than reading files and asserting they looked fine. It checks diagram
well-formedness and the no-XML-comments rule, that every file path named in any `.md` or
`.yaml` exists, that cited specs resolve to a file or a stub, workbook internals (unique
`Kode`, no empty required columns, every `Modul` and entity resolving), entity agreement
across the ERD / workbook / `map.yaml`, that every UC reaches a class diagram *in its own
module*, FR traceability closure both ways, and tracker/plan agreement. **Result: 13
passed, 0 failures, after four fixes.** What it deliberately cannot check is whether any
document is *right* — only that they do not contradict each other.

**[DISCOVERY]** **A `CLAUDE.md` hard gate was being violated and nobody had noticed.**
Three conventions files (`bpmn-conventions.md`, `state-conventions.md`,
`component-conventions.md`) cite two OMG specs by clause and section number. Neither
spec is in `context/files/`, and **neither had the stub** that `.gitignore`,
`context/files/README.md` and `CLAUDE.md` all independently require. Every one of those
section numbers was therefore a claim, not a citation — the exact failure the rule was
written to prevent, sitting inside the layer that exists to prevent it. Both stubs
written (`formal-11-01-03.pdf.txt`, `formal-17-12-05.pdf.txt`) with title, version, OMG
document number and where to obtain each. The audit now enforces this permanently.
`context/files/README.md`'s citation table was also stale — it credited the UML spec to
`state-conventions.md` alone, missing `component-conventions.md`, which cites it as of
today. Fixed.

**[DISCOVERY]** **The ISSUE-004 TODO about stale plan status lines was real, and had
already happened four times.** ISSUE-001, ISSUE-002, ISSUE-003 and ISSUE-005 all carried
tracker rows saying DONE while their `plan.md` status lines still read "CONFIRMED...
work started", "UNBLOCKED... Drawing", or "WRITTEN". Anyone opening a plan directly —
which is what `RULES.md` tells a new session to do — would have been told the work was
in progress. All four rewritten to DONE, each preserving its original status line
verbatim where the earlier wording carried information. This is now a checked condition
rather than a remembered one.

**[STATUS]** Three of the audit's four initial path failures were **false positives in
the checker, not defects in the docs**: `bpmn-as-is.drawio` is a generic filename in a
conventions file rather than a claim a file exists, and `state-budget-period.drawio` and
`class-budgeting-draft.drawio` are deliberately deleted diagrams cited only by the
documents that record their deletion — which is correct practice, not rot. The checker
now carries them in an `ALLOWED_DANGLING` map with a written reason each, so the
distinction is encoded rather than re-derived.

**[CORRECTION]** The previous entry's TODO claimed the generated PNGs "are committed"
while `drawio-general-guide.md` says sources only, and called it a five-issue
disagreement. **That was wrong on both counts.** `.gitignore` excludes
`docs/diagrams/*.png`, so the PNGs are not tracked and the convention is already
self-consistent; and this working copy is not a git repository at all, so nothing has
been committed either way. The remaining TODO from that pair — whether the workbook
"mark the row implemented" step applies to documentation issues — still stands: the
`UC FR` sheet has no such column, and the step has now been skipped on all five issues.

**[TODO]** `docs/rbac-entities.csv` is **empty (0 bytes)** and nothing references it.
It is a leftover of the ERP framework this repo was distilled from; a single-user app
where every workbook row names the same actor has no roles to record. Left in place
rather than deleted — it is the owner's call — but it should either be deleted or given
a one-line header saying why it stays empty, so the next reader does not treat it as an
unfilled obligation.

**[TODO]** What the audit cannot tell you, stated plainly so a clean run is not
over-read: it does not check that any FR matches what the owner meant, that the ERD's
cardinalities are right, or that a diagram renders sensibly. Those need eyes. The
mandatory export-and-look step remains the only check on render quality, and today's
`AppDatabase` double-icon defect is what happens when it is delegated and its result
taken on trust.

---

## 2026-08-20 -- ISSUE-006, `docs/enums.md`

**Asked:** "delete rbac, what we actually need here is enum types", then "write both,
its nice to easily see enums" -- the file *and* the values on the diagrams.

**[STATUS]** `docs/rbac-entities.csv` deleted. It was 0 bytes and referenced by nothing:
an artifact of the ERP framework this repo was distilled from, in an app where every
workbook row names the same single actor. `audit.py` carries it in `ALLOWED_DANGLING`
with the reason, so the documents that record the deletion do not read as broken links.

**[DISCOVERY]** **The gap the owner named was bigger than a missing file.**
`statuses.md` had correctly excluded `Transaction.kind` as *"a classification, not a
status"* and `Account.settled` as *"a flag, not a lifecycle"* -- and there was nowhere
for either to go. The consequence: **the seven transaction kinds and their
`from_account` / `to_account` semantics existed only in `pm/issues/001-erd/plan.md`**,
a one-time record of a closed issue. The ERD showed `kind` as a bare column and
`class-transactions.drawio` said "the seven kinds (D1)" without naming them, so learning
what a transaction could be meant opening a closed issue's plan. That is precisely the
failure `general-rules.md` warns about ("don't leave it only in the issue's plan.md"),
and it survived five issues because every individual artifact was correct on its own.

**[DECISION]** **The split rule, now stated at the top of both files:** *a status says
what an entity may do next; an enum says what an entity is.* A status gates behaviour,
so it needs a state diagram and, under NFR-4, an argument in `fr-nfr.md` before it may
exist at all. An enum classifies, so it needs neither. This makes the pair symmetrical
and gives any future value a single question to answer. `statuses.md` lists zero values
and `enums.md` lists ten -- the expected shape for an app that gates no behaviour but
classifies freely.

**[DECISION]** Recorded four **stated non-members** in `enums.md`, each because it has a
plausible-sounding wrong version that would cost a migration: `Account.settled` is a
boolean (and a "partially settled" third value would store a number FR-11 already
derives, which NFR-2 forbids); "Others" is `budget_group_id IS NULL`, deliberately not a
row that could be renamed or budgeted against; `Budget_Period` has no statuses; and
categories are user-created rows, not a fixed vocabulary.

**[DISCOVERY]** **Three passages still described "what a month means" as open, hours
after it was decided.** `decisions.md` twice (the injected-clock note -- where *both*
halves had expired, since FR-16's lock is also gone -- and the D3 entry) and ISSUE-001's
D4. This is the second occurrence of this exact failure mode, and it is worth naming as
a pattern rather than a slip: **a decision is not finished until every register that
listed it as open is updated.** The first occurrence (the credit/debit naming collision,
found earlier the same day) is what prompted that sentence being written down; it then
happened again within hours, which suggests the rule needs a check rather than a memory.
`audit.py` cannot catch this one -- it compares documents to each other, and all three
passages were internally consistent. Left as a known limit rather than a fake check.

**[STATUS]** ISSUE-006 **DONE**. Files touched: `docs/enums.md` (new),
`docs/statuses.md` (cross-linked both ways), `docs/rbac-entities.csv` (deleted),
`docs/diagrams/class-transactions.drawio` (`TransactionKind` now lists all seven values,
box grown 70->85 to fit two lines, 15px clearance to `Categories` confirmed on the
render), `docs/diagrams/class-accounts.drawio` (`AccountGroup` uppercased to match canon,
enums.md pointer added), both PNGs, `context/index/map.yaml` (`vocabulary:` entry),
`context/index/decisions.md` (two stale passages annotated), `pm/issues/001-erd/plan.md`
(D4 annotated), `README.md` (the `docs/` listing named the deleted CSV and called
`fr-nfr.md` "nfr.md"), `audit.py`, `pm/tracker.yaml`, `pm/active.json`.

**[STATUS]** **Phase 1 is complete.** `fr-nfr.md`, the workbook (UC-01..UC-13), the ERD,
three class diagrams, the component diagram, `enums.md` and `statuses.md`. `audit.py`
green at 13 passed / 0 warnings / 0 failures.

**[TODO]** `docs/diagrams/.$erd.drawio.bkp` is a draw.io auto-backup from 2026-08-19
sitting in the diagrams folder, matched by no convention and not covered by
`.gitignore`. Left in place pending the owner's word -- flagged rather than deleted.

**[TODO]** Two `fr-nfr.md` section 4 items remain and both are schema-relevant before any
migration: **currency** (one or many; if many, whether the set is an enum or a table --
`enums.md` flags where it would land) and **whether a transaction carries a free-text
note**. Neither blocks starting work on Accounts or Transactions.

---

## 2026-08-20 -- ISSUE-007, currency

**Asked:** "multi currency, for now just idr usd cny add later", then -- once the cost was
laid out -- "okay if it's too much then one currency but user choose idr or usd just for
now, that way we can use double", then "yes int minor units, go ahead".

**[DECISION]** **One app-level currency, `IDR` or `USD`, chosen at setup.** The owner
opened with multi-currency and withdrew it in the next message once the cost was raised
before any work started: a currency per account, a rate at a point in time behind every
total, FR-1's four figures no longer summable into a net, UC-12's comparison splitting
per currency, and a cross-currency transfer needing two amounts instead of one. Raising
it first cost one exchange; discovering it after the ERD was redrawn would have cost the
ERD. **Not foreclosed** -- because the currency is stored with the data, a future
per-account currency is an added column, not a reinterpretation of existing rows.

**[DECISION]** **Amounts are `int` minor units, not `double`.** The owner proposed
`double` as the reason single-currency was attractive. Pushed back once and the owner
accepted. Binary floating point cannot represent 0.1 exactly, so error accumulates across
sums -- and NFR-2 ("the numbers must agree with each other") is exactly what breaks. The
reason it is worth a pushback rather than a note: the failure is **unfixable at the query
layer**, because the error lives in storage. `IDR` has exponent 0, `USD` exponent 2, and
display is the only place a decimal point exists. The general form, now in
`decisions.md`: **when a requirement says numbers must agree, that is a storage decision,
not a formatting one.**

**[DECISION]** The setting lives **in the database**, not in device preferences. Backup
is an export file, so a currency in preferences would not travel with the amounts and a
restored backup would silently reinterpret every figure in it.

**[DISCOVERY]** **One column became six artifacts.** Promoting the capability to FR-19
forced UC-14, which forced the question of which module owns it -- and none of the three
did. `Settings` became a fourth module, which under one-diagram-per-module forced a
fourth class diagram, which made the component diagram (three module boxes) and all three
existing class diagrams ("shared by all three modules") stale. Final tally: workbook
(three sheets), ERD, `class-settings.drawio` (new), three existing class diagrams, the
component diagram, `enums.md`, `map.yaml`, `fr-nfr.md`, `decisions.md`. **The plan was
amended twice mid-flight (D5, D6) rather than quietly widened**, per `general-rules.md`.
Worth remembering as a cost estimate for the next schema-shaped request: the artifact set
is interconnected enough that "just add a setting" is never one edit.

**[DECISION]** `Settings` is drawn on both the ERD and the component diagram **with no
relationship line and no call edge** -- it has no foreign key and nothing invokes it. Its
coupling is interpretive: its single value decides what the integer in every amount column
means. Both diagrams carry a note saying exactly that, because **a dependency with no
referential trace is the kind the component diagram exists to make visible**, and hiding
it as configuration would have repeated that lesson in a new place.

**[DISCOVERY]** Two more stale passages, making **four in one day**: the workbook's
Budgeting module description still described the `open -> locked -> closed` lifecycle
deleted by ISSUE-004, and the ERD's `Budget_Period` note still called the calendar-month
question undecided. The pattern is now clear enough to name: **every one of the four was a
rationale attached to a decision, and rationales do not get re-read when the decision they
justify is reversed.** `audit.py` cannot catch these -- each was internally consistent
prose. This is a limit of the check, not a gap to paper over with a fake one.

**[DISCOVERY]** `audit.py` hard-coded `FR-1..FR-18`, so it would have **silently stopped
checking the moment FR-19 existed** -- a check that passes because it is looking at the
wrong set is worse than no check. It now derives the range from the document and reports
numbering gaps. Worth watching for elsewhere: any check written against a literal count.

**[STATUS]** ISSUE-007 **DONE**. All renders visually verified; one real defect caught by
looking rather than by validation -- the `Settings -> AppDatabase` edge label was wide
enough to cover its own connector, so the render read as two floating boxes with a caption
between them. Also clarified `drawio-general-guide.md`'s PNG rule, which two separate
agents in a row read as "delete the companion PNG": the rule is about version control, not
the working directory, and the companion `<name>.png` beside each source stays.

**[TODO]** One `fr-nfr.md` section 4 item still bears on the schema: whether a transaction
carries a free-text note. "Where the data lives" remains narrowed and non-blocking.

**[TODO]** Next is implementation, and three things gate it: there is no
`sequence-conventions.md` (every other diagram type has one, and `CLAUDE.md` makes the
sequence diagram the scope boundary of an implementation plan); `diagram-drawio-author`'s
scope list does not mention sequence diagrams; and `context/coding-conventions/` does not
exist yet. Suggested first slice is UC-02 + UC-01, noting it spans two modules -- FR-3's
opening amount is an `adjustment` transaction, so the Accounts slice pulls in the
Transactions table on day one.

---

## 2026-08-20 -- Implementation backlog drafted (ISSUE-008..014)

**Asked:** "lets just focus on issue making first, then we can fill in coding conventions
and sequence."

**[STATUS]** Seven implementation issues written to `pm/tracker.yaml`, all **TODO**,
covering all 14 use cases exactly once: 008 scaffold + UC-14, 009 accounts + ledger,
010 balance sheet + debt progress, 011 categories, 012 recording all seven kinds,
013 review/correct, 014 budgeting. No plan exists for any of them and none may start
until its own plan is written and confirmed -- writing the backlog is not planning it.

**[DECISION]** **Sliced vertically, not by layer.** Each issue leaves the app usable
rather than leaving one layer built across every module. The clearest case is ISSUE-008:
rather than a bare skeleton, it delivers UC-14 -- the smallest module in the project,
which happens to exercise the entire Screen -> provider -> DAO -> AppDatabase -> table
chain. If the architecture drawn on the class diagrams is wrong, that is the cheapest
possible place to find out.

**[DISCOVERY]** **ISSUE-009 spans two modules and does not look like it.** "Accounts"
sounds self-contained, but FR-3's opening amount is an `adjustment` transaction per ERD
D1, so the Transactions table and one write path land there rather than in ISSUE-012.
Called out on the tracker row itself, because the mistake it prevents -- planning 009 as
an Accounts-only slice and discovering the dependency mid-build -- is exactly what the
sequence-diagram-as-scope-boundary rule exists to catch, and 009's plan will be written
before anyone re-reads this log.

**[DISCOVERY]** ISSUE-011 (categories) has no dependency on the 009/010 chain, so it can
run in parallel. Ordered ahead of 012 anyway so the record form is built once with its
pickers rather than twice.

**[DECISION]** `audit.py` gained a real distinction rather than a silencer: **a TODO
issue has no plan by definition**, since the gate requires a plan before work starts, not
before an issue is written down. Anything past TODO with no plan is still a failure. Same
for file references -- planned-but-unwritten files (the seven plans, and
`sequence-conventions.md`) are now a separate set from deleted-or-never-real ones, and the
audit **warns when a planned file appears** so the set cannot rot into a permanent excuse
list. Also fixed a message that had started lying: it read "14 tracker issues: all have
plans" when seven deliberately do not.

**[TODO]** Before ISSUE-008 can be *planned* (not before the backlog stands):
`context/document-writer-only/sequence-conventions.md` and `context/coding-conventions/`,
neither of which exists. `CLAUDE.md` makes the sequence diagram the scope boundary of an
implementation plan, so 008's plan cannot be written to standard without it. Three worked
sequence diagrams to distil from and validate against are already in
`context/document-writer-only/examples/movie-booking demo/`. `diagram-drawio-author`'s
scope list also needs sequence diagrams added to it.

---

## 2026-08-20 -- ISSUE-015, sequence diagram conventions

**Asked:** "now can you get informations on sequance diagram and write down the conventions?"

**[STATUS]** `context/document-writer-only/sequence-conventions.md` written -- the last
missing diagram-type convention, and the one gating every implementation plan, since
`CLAUDE.md` makes the sequence diagram the scope boundary of an issue. Sourced from UML
2.5.1 Clause 17 "Interactions" plus the three worked examples, which were read and rendered
rather than recalled.

**[DISCOVERY]** **The worked examples are Mermaid-generated, not hand-authored.** Their XML
carries `mermaidId` / `mermaidBaseStyle` / `mermaidBaseValue` attributes and `<UserObject>`
wrappers -- the signature of draw.io's Mermaid import. That decided the authoring rule:
sequence diagrams are the **only** diagram type in this project authored as Mermaid and
converted with the CLI, rather than hand-written as XML. Layout is the hard part of a
sequence diagram, Mermaid's parser does it reliably, and hand-authoring a fourth diagram
would produce a file unlike the three that already exist.

*Accepted cost, recorded in the file:* Mermaid's import palette (purple `#9370DB`, Trebuchet
MS, `light-dark()`) does not match the plain black-on-white of the hand-authored diagrams.
Rejected hand-fixing styles after conversion -- the next regeneration undoes it, and a file
that regenerates differently than it is stored is worse than one that looks foreign.

**[DECISION]** **The hard rule: every lifeline must be a class that already appears on a
class diagram**, spelled identically, or the actor `Owner`. If a diagram needs a participant
that isn't drawn, either the class diagram is incomplete or the sequence is inventing a
layer -- both findings to raise, never to draw past. This is what makes the two artifact sets
check each other rather than drift.

**[DECISION]** **Reads and writes are drawn asymmetrically**, taken from
`class-accounts.drawio`'s own note. A write gets no reply arrow back to the screen; the
result arrives separately as a stream emission, drawn asynchronously. A diagram where every
write has a tidy reply arrow is the signature of getting this wrong, and it would
misrepresent the Riverpod/drift architecture as request/response. Flagged in the file as the
single most likely way to draw one of these incorrectly.

**[DECISION]** Only `alt`, `opt` and `loop` are used of the spec's twelve combined-fragment
operators. And **no `alt` operand may be a refusal** -- under NFR-4's zero-refusals fit
criterion that shape is a requirements violation, not a notation choice. Worth noting how
often that NFR now reaches into unrelated decisions; it is doing real work.

**[DISCOVERY]** **A parsing mistake nearly became a wrong conclusion in the file itself.**
Extracting labels with a regex over `mxCell value=` returned nothing, and I reported to the
owner that the examples were unlabelled skeletons unusable as a regression suite. Rendering
one to PNG immediately contradicted that -- they are fully labelled. In a Mermaid-generated
file the labels live on `<UserObject label="...">` wrappers, and `mxCell` carries no value at
all. **Rendering the artifact caught what parsing it did not**, which is the same lesson the
export-and-look rule already encodes, arriving from a new direction. The gotcha is now
written into the conventions file so the next reader does not repeat it.

**[DISCOVERY]** `examples/elements.drawio` -- the palette that `CLAUDE.md` says to check
before guessing a style string -- contains **no sequence shapes at all**. The style table in
the new file therefore comes from the worked examples instead, and says so. Left as a TODO
rather than silently patched.

**[STATUS]** Also done: `diagram-drawio-author`'s scope extended to sequence diagrams,
including the Mermaid exception and pointers to the two rules above. `audit.py`:
`sequence-conventions.md` removed from `PLANNED_NOT_WRITTEN` now that it exists -- that set
is a promise, not a permanent exemption, and the audit warns when an entry appears --
`context/coding-conventions/` added in its place, and the illustrative filename in the new
file's CLI example added to `ALLOWED_DANGLING`. Audit green at 12/0/0.

**[TODO]** The UML sub-clause numbers (17.2 Interactions, 17.3 Lifelines, 17.4 Messages,
17.6 Fragments, 17.7 Interaction Uses) were confirmed against secondary references, not read
out of the spec, because the PDF is git-ignored and present only as a stub. The file says so
in place. Anyone holding the PDF should verify and correct them.

**[TODO]** One prerequisite left before ISSUE-008 can be planned:
`context/coding-conventions/`. Recommend writing it lean, as part of ISSUE-008 rather than
speculatively ahead of any code.

---

## 2026-08-20 -- Backlog re-cut to one issue per use case

**Asked:** "can you turn the issues into use case based?", then "then make the issue codes
to UC01-xxx".

**[DECISION]** **Seven vertical slices became eleven UC-coded issues.** The reasoning given
before doing it, and the reason it is better rather than merely different: the workbook is
the spine of this pipeline, `map.yaml` indexes by use case, and the close checklist marks a
workbook row implemented -- so a 1:1 chain beats a union at every step. The decisive
argument is the scope gate: `CLAUDE.md` makes a plan's scope its sequence diagram, and
`sequence-conventions.md` draws one diagram per use case. **One UC = one diagram = one plan
scope** is the tightest available reading of that rule; a multi-UC issue makes scope "the
union of these four diagrams," which is loosest exactly where the gate is meant to bite.

**[DECISION]** **ID scheme: `UC{NN}-{slug}` for use-case work, `FEAT{NN}` for work with no
use case.** FEAT is not invented here -- `context/index/map.yaml` has said "UC/FEAT" since
it was written. `FEAT01-foundation` is the only one: a Flutter scaffold has no actor and no
workbook row, and labelling it honestly beats attaching it to whichever use case happens to
be built first.

*The one hazard, recorded on the tracker itself:* the workbook Kode is `UC-01` and the issue
implementing it is `UC01-balance-sheet`. A single hyphen separates them. `traces_to` always
carries the workbook form, and the audit now checks that an id matches the use case it
claims.

**[DECISION]** **Two exceptions to 1:1, both argued rather than assumed.** `FEAT01` (above),
and `UC04-record-money-movement`, which carries UC-04 through UC-08. Expense, income,
transfer, lend and borrow are one form and one write path *by schema decision* -- ERD D1 put
all seven kinds in one ledger table precisely so there would be one insert path. Splitting
them yields either one real issue and four wrappers, or five issues churning the same file.
FR-6's "fastest path in the app" is likewise a property of the whole form.

**[DISCOVERY]** **Re-slicing did not remove the UC02 hazard, and it was worth checking
whether it would.** "Add an account" still lands the Transactions table, because FR-3's
opening amount is an `adjustment` transaction. The dependency lives in the schema, not in
the slicing -- resplitting only moves which row has to carry the warning. Stated on the row
so planning UC02 cannot miss it.

**[STATUS]** `audit.py` gained a check that enforces what the new scheme claims: every
workbook use case owned by **exactly one** implementation issue, no issue claiming a UC that
does not exist, and every id matching its own `traces_to`. A use case with no issue is
unbuilt work nobody has noticed; one claimed twice is two issues editing the same screen.
Now: *all 14 use cases owned by exactly one of 11 implementation issues.* Green at 13/0/0.

**[STATUS]** The seven `ISSUE-008..014` rows are gone. Nothing was lost -- no plan.md was
ever written for any of them, so they were tracker rows only. The completed documentation
issues keep their `ISSUE-NNN` ids; renaming closed history would break every reference in
this log and in `decisions.md` for no gain, and the two schemes coexisting is legible
because the code says which kind of work it is.

---

## 2026-08-20 -- Issue folders created, and ISSUE-015 renumbered to ISSUE-008

**Asked:** "coding later, now make the issue folder and fix the numbering for 015".

**[STATUS]** Created all eleven backlog issue folders under `pm/issues/`, each holding a
`plan.md` **placeholder explicitly marked NOT PLANNED**. The placeholder is not a plan and
says so in its second line: it names what the issue traces to and depends on, points at the
tracker row for the constraints already captured, and lists the four things a real plan for
this project must contain (a sequence diagram per use case, the classes it touches named as
the class diagram spells them, any forced decision written as a proposal, and an explicit
out-of-scope list). The planning gate is unchanged -- a placeholder does not satisfy it.

**[DECISION]** `audit.py` was made **stub-aware** rather than left to be fooled by them.
Creating eleven files named `plan.md` would otherwise have flipped the count from "11 still
TODO and unplanned" to "19 planned" overnight, which is exactly the kind of number that
looks like progress and is not. It now recognises the NOT PLANNED marker, excludes stubs
from the planned count, and **fails if an issue past TODO still has a placeholder** -- the
case where a stub would actually be dangerous.

**[STATUS]** **ISSUE-015 renumbered to ISSUE-008.** It was numbered 015 only because
ISSUE-008..014 were the implementation backlog when it was written; those rows became
UC-coded ids hours later, freeing 008..014 and leaving the sequence-conventions issue
stranded seven numbers past the end. Folder renamed, tracker id and plan path updated, and
the renumber recorded at the top of the plan itself.

*Entries earlier in this log still say ISSUE-015, and they stay that way* -- this log is
append-only, and rewriting closed entries to match a later renumber is exactly the kind of
tidy-up that makes a record untrustworthy. The old path
`pm/issues/015-sequence-conventions/plan.md` is registered in the audit's `ALLOWED_DANGLING`
with that reason, so the reference resolves as deliberate rather than broken.

**[DECISION]** While renumbering, moved a real prerequisite out of a comment and into data:
`FEAT01-foundation` now declares `depends_on: [ISSUE-007, ISSUE-008]`. The sequence
conventions genuinely gate planning FEAT01, and the audit already enforces that a
non-TODO issue's dependencies are DONE -- a constraint written only in a comment enforces
nothing.

**[DISCOVERY]** Small, but it cost a warning: adding the renumber note above the `**Status:**`
line pushed that line past the 400-character window the tracker/plan consistency check reads,
so a correctly-marked DONE plan reported as stale. Fixed by putting the status back first
where every other plan has it, rather than by widening the window -- **the check was right
about the shape of the document, and the document was wrong.**

---

## 2026-08-20 -- ISSUE-009, context/coding-conventions/

**Asked:** "now you can gather coding conventions... remember its flutter. if you can find an
mcp for dart flutter that would be better."

**[STATUS]** Six files written under `context/coding-conventions/`: `README.md`,
`dart-and-flutter.md`, `riverpod.md`, `drift.md`, `testing.md`, `tooling.md`. This was the last
prerequisite before `FEAT01-foundation` can be planned.

**[DISCOVERY]** **Nothing is installed.** `dart`, `flutter` and `fvm` are all absent from this
machine, and none of the usual install directories exist. That is a real blocker on FEAT01 --
recorded on its tracker row rather than left to be discovered mid-plan -- and it also settles
the MCP question.

**[DECISION]** **The MCP answer is yes, and it is the official one.** The Dart and Flutter MCP
server is built by the Dart and Flutter teams at Google and **ships with the SDK**, so it
cannot be added until Flutter is installed: `dart mcp-server` is a subcommand of a binary that
is not here. Two setup routes are recorded in `tooling.md` -- the `claude mcp add` command, or
the official Flutter plugin which bundles the server plus Flutter's agent skills. What it buys
this project specifically: analyzer access (which matters because strict-casts /
strict-inference / strict-raw-types are on), running the DAO query tests where this app's
correctness actually lives, `pub_dev_search` for the one moment at FEAT01 when versions get
pinned for real, and live app interaction via DTD.

*Caution written into the file:* the screenshot-and-drive capability makes it tempting to treat
a driven app as proof a use case works. It is evidence, not proof -- the requirements most
likely to break here (NFR-4's zero refusals, FR-8's "a transfer is not spending") are
assertions about behaviour and data, and belong in tests that fail loudly.

**[DECISION]** **Written as explicitly provisional, and the README says so in a block quote.**
No code exists, no `pub get` has ever run, and no version number in these files is verified.
Every rule is either quoted from an official source (Effective Dart, drift, Riverpod, Flutter
docs) or derived from a decision already in `decisions.md`; nothing is invented from
experience. FEAT01 is named as the issue expected to correct them. That is the honest position
given the owner asked for these ahead of the point `general-rules.md` expects them.

**[DECISION]** `flutter_lints` + `strict-casts` / `strict-inference` / `strict-raw-types`,
**not** `very_good_analysis`. The stricter package enables ~86% of available lints, which is
right for a team enforcing house style across contributors; here the rules that prevent actual
bugs are the strict analyzer modes, and the rest is style that `dart format` and one reader
already settle. `unawaited_futures` called out on its own merits: this app awaits database
writes everywhere, and a dropped `Future` is exactly how a write silently does not happen.

**[DECISION]** Riverpod **code generation** (`@riverpod`). The usual objection -- it drags in
`build_runner` and `.g.dart` files -- **does not apply here, because the cost is already
paid**: `drift_dev` is a builder, so `build_runner` is non-negotiable from the first commit. A
second generator on a build that must run anyway is nearly free, and it removes what would
otherwise be the most-edited, least-interesting code in the repo.

**[DECISION]** drift **guided migrations** (`make-migrations`), with schema snapshots and the
generated migration tests committed. They are the only artifact that proves a migration
preserves data, and NFR-3 is a promise the tooling has to keep. `beforeOpen` seeds the
`Settings` row, since the currency must exist before any amount can be interpreted.

**[DISCOVERY]** Writing these surfaced how much of the code layer is just *restating decisions
already made*, in a place a developer will actually read: money is `int` minor units and never
a `double`; no stored balance ever; "is this spending?" is `to_account_id IS NULL` and never a
`kind IN (...)` list; a write returns nothing to the screen. **The one genuinely new rule is
that enums must be stored `.textEnum<T>()` rather than by index** -- with seven
`TransactionKind` values and three `Account.group` values, index storage means reordering a
Dart enum silently reinterprets every existing row. That is a data-loss bug with no error
message, and it was written down nowhere before today.

**[DECISION]** The rule placed above all others in the README: **class names in code must match
the class diagrams exactly.** The same rule `sequence-conventions.md` gives lifelines, pushed
one artifact down. A class the diagrams do not have is a finding to raise, never something to
write and move past -- otherwise the Phase 1 artifact set stops being true, and a diagram that
disagrees with code is worse than no diagram because it is still believed.

**[STATUS]** `FEAT01-foundation` no longer creates this directory; its row now depends on
ISSUE-009 and states that it is blocked in practice until Flutter is installed. `audit.py`'s
`PLANNED_NOT_WRITTEN` set is now **empty**, which is its intended resting state -- both entries
it held (sequence conventions, coding conventions) were promises that have since been kept.
Green at 13/0/0.

**[TODO]** No CI, and this working copy is not a git repository. The four commands at the end
of `testing.md` -- `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test`,
`build_runner build` -- are exactly what a CI job would run, and are currently run by
remembering to. Worth raising at FEAT01.

## 2026-08-21

**[DECISION]** `Transaction` carries an optional free-text **note** — one nullable text
column. Owner's call, closing the last `fr-nfr.md` §4 item that blocked a schema decision.
Nullable rather than defaulted-empty because "wrote nothing" and "wrote an empty note" are
one fact and deserve one representation; present rather than omitted because adding it after
FEAT01's first migration ships costs a second migration and a snapshot. Not searchable — that
is UC-09's surface. No FR text changes: an optional field the app never reads is the shape of
FR-6's "what it was for", not a new capability.

**[STATUS]** *Resolved same day — see the closing entry below.* `erd.drawio` had not been updated yet — `Transaction` needs a tenth row, `note`,
which re-opens ISSUE-001 the same way the `Budget_Period.state` drop did. Must land before
FEAT01's migration is written.

**[STATUS]** Owner's sequencing, recorded so it is not re-argued: **all documentation first**
— every backlog issue gets its `plan.md` and sequence diagram written — *then* the git repo is
created, with GitHub Issues and CI on top of it, *then* implementation runs fully automated
end to end. The intent is to see how the pipeline holds up when it is run without
intervention, so plan quality is the variable being tested, not a formality.

**[STATUS]** `erd.drawio` updated — `Transaction` now carries a tenth row, `note`. ISSUE-001
re-opened and closed again the same way the `Budget_Period.state` drop did. Nullability is
shown the way this file already shows it: a side annotation, matching how `budget_group_id`'s
optionality is documented, because the table rows themselves carry no NULL marker and
inventing one would have made this file disagree with itself. Table and the Transactions
group box both grew 30px; one existing note moved down to clear it; render visually verified,
no edges rerouted. Still outstanding for FEAT01: the `note` column belongs in the first
migration.

**[STATUS]** All fourteen per-use-case sequence diagrams drawn — `docs/diagrams/seq-uc01..uc14`,
one per UC as `sequence-conventions.md` requires (per use case, not per issue, so they survive
the backlog being re-sliced). Authored in Mermaid and converted with the draw.io CLI; every file
is well-formed, carries zero XML comments, and was exported to PNG and looked at. Every lifeline
on all fourteen was cross-checked against the four class diagrams by script: all present, spelled
identically. No participant was invented.

**[DECISION]** UC-03's adjustment writes through `AccountDao`, not `TransactionDao`. The first
draft drew `AccountsNotifier -> TransactionDao` and reported the missing edge as a class-diagram
gap; it is the opposite — ISSUE-005 D1 ("modules reach each other's data by SQL join, not by
calling another module's DAO") already rejects that call, and its own text concedes that nothing
enforces table ownership. So `AccountDao` writes the `adjustment` row into `Transactions` itself,
and the diagram carries a note citing D1 so the next reader does not re-raise it. Worth noting
that D1 argues its case in terms of *reads*; UC-03 is a *write*, one step past what it literally
covers. Treated as applying D1 rather than making a new decision, and flagged to the owner as
such.

**[DISCOVERY]** The two artifact sets checked each other exactly as intended. The lifeline rule
caught a call that contradicted a decision recorded in a file the drafting agent had not been
given, which is the failure mode a per-module class diagram cannot catch on its own — the same
lesson ISSUE-005 recorded about cross-module cycles, in a new place.

**[TODO]** Two open items from the sequence pass, both needing an owner ruling:
1. **UC-13 step 3 — budget group CRUD has no supporting class.** `class-budgeting.drawio` has the
   `BudgetGroups` table but no screen, notifier or DAO method for creating, renaming or deleting a
   group, and `CategoryManagerScreen` lives in the Transactions module. The workbook puts budget
   group setup squarely in UC-13. `seq-uc13` carries a note scoping it out rather than inventing a
   participant — correct per the conventions, but it means UC-13's issue as drawn does not deliver
   what the workbook says it does. Either a class diagram gains the missing classes or UC-13 is
   re-sliced.
2. **Does the `note` field appear on transfers, lend/borrow and repayments?** `seq-uc04` and
   `seq-uc05` carry `note` in the recording signature; `seq-uc06`, `seq-uc07` and `seq-uc08` do
   not. The 2026-08-21 decision puts `note` on `Transaction`, the entity — not on a kind — so the
   column exists for all of them regardless; the open question is whether those three screens
   offer the field. The workbook's Input for UC-06 does not mention one.

**[DECISION]** **Sequence-diagram renders** now live with the issue that owns them —
`pm/issues/<issue>/seq-uc{NN}-{slug}.png` — rather than beside their `.drawio`. Owner's call.
Fourteen PNGs moved, with `uc04-record-money-movement` holding five since its scope is the union
of UC-04 through UC-08. Effect: a sequence diagram's render sits next to the `plan.md` whose
scope it defines, which is where someone reading the plan actually needs it.

The ERD, the four class diagrams and the component diagram **stay in `docs/diagrams/`**, still
gitignored. They were moved to their originating issues first and moved back the same day: they
are cited repo-wide, so filing them under the issue that happened to produce them buries a
document everything else points at. **The line is ownership, not diagram type** — a sequence
diagram belongs to exactly one issue and defines its scope; the other three describe the system
as a whole and belong to no issue. All `.drawio` sources stay in `docs/diagrams/` either way.

**[DISCOVERY]** This inverts a rule that was already written down twice, so both places were
amended rather than left to be rediscovered. `drawio-general-guide.md` item 7 previously said the
companion PNG always sits beside its source and is gitignored; it now carries the split, and
warns that `-o` must be pointed at the issue folder when exporting a sequence diagram because
the CLI defaults to writing beside the source. `.gitignore`'s diagram block said "only the
.drawio source is tracked", which is no longer true of the fourteen sequence renders — they are
**committed**, which is the real change: a sequence diagram edited without re-exporting now
leaves a wrong picture in the repo where a reader will believe it, and it is the one diagram
type whose picture defines an issue's scope. Previously that mistake was invisible because no
render was committed at all.

**[STATUS]** Toolchain is in. Flutter 3.47.1 / Dart 3.13.1, both stable, installed at
`C:/flutter` with `C:/flutter/bin` on the user PATH — verified by running it, not by finding the
folder. Dart MCP server 1.1.1 connected. `FEAT01`'s tracker row no longer says blocked; what
gates it now is the pipeline's own rule — its `plan.md` is still a NOT PLANNED placeholder, and
no code starts before that exists and is confirmed.

**[DISCOVERY]** Two things cost time getting there, both written into
`context/coding-conventions/tooling.md` because neither symptom points at its cause. First, a
process started *before* a PATH edit keeps the environment it launched with — so `flutter` was
genuinely installed and genuinely missing from a running session at the same time, and I read
the stale environment and reported it as not installed. The fix is restarting the process, not
re-editing PATH. Second, `dart mcp-server` builds a bundled executable and resolves a helper
package on first launch, printing pub's progress **to stdout** — which is the JSON-RPC
transport. That surfaces as `CONNECTION_CLOSED`, or as the server answering an empty request
with `-32700 Invalid JSON`. Both look like a broken install; neither is. It is one-time, and
warming it up with `dart mcp-server --version` first avoids it. The registration should use the
absolute path to `dart.bat` rather than bare `dart`, so it does not depend on the launching
process's PATH at all.

**[DECISION]** `context/coding-conventions/README.md`'s provisional warning narrowed rather than
lifted. It used to rest on two reasons — no code, and no SDK. The SDK reason is gone; the rest
stands, and it is the larger half: no `pub get` has run, no package version in `riverpod.md` or
`drift.md` is verified, nothing has been compiled. `FEAT01` is still expected to correct these
files and say so here.

**[STATUS]** Under git — `EldwinPr/uangsaku` on GitHub, `main`, two commits, working tree clean
and in sync with origin. 169 files tracked. The `.gitignore` split written earlier the same day
was verified against a real repo rather than assumed: 14 sequence renders tracked under
`pm/issues/`, 0 PNGs tracked from `docs/diagrams/`. Named `uangsaku` — the app id and Dart
package name should follow it and be settled before `FEAT01` runs `flutter create`, since
renaming those afterwards is a multi-file change across the Android and iOS projects.

**[TODO]** CI is now possible and is not configured. The job is already specified in two places:
the four commands at the bottom of `testing.md` (`flutter analyze`, `dart format
--set-exit-if-changed`, `flutter test`, `build_runner build`), plus `python audit.py`, plus the
diagram re-export check noted in `tooling.md`. Worth standing up before the unattended run
rather than after — an unattended run with no CI has nothing checking it but itself.

**[STATUS]** CI written — `.github/workflows/ci.yml`, two jobs. `docs` runs `python audit.py`
and works today. `app` runs the four commands from `testing.md` with `build_runner` **first**,
since generated code has to exist before `analyze`, `format` and `test` read it; running it last
only checks the previous commit's output. Every `app` step is guarded on `pubspec.yaml` existing,
so it passes trivially until FEAT01 rather than failing red for months. Flutter pinned to 3.47.1
to match the developer machine — bump both together or neither.

**[DECISION]** Sequence renders are now checked for staleness, not just presence.
`docs/diagrams/renders.lock` records the hash of the `.drawio` each committed PNG was exported
from; `audit.py` fails when they drift, and `python audit.py --record-renders` rewrites the lock
**after** a re-export. The mechanism exists because these renders are committed and each one is
an issue's scope, so a wrong picture is worse than a missing one — and neither git nor a file
timestamp can detect it, because timestamps do not survive a clone. Proven in both directions:
edited a diagram and the audit failed, reverted and it passed.

**[DISCOVERY]** Building that check surfaced a defect that would have made it useless, and the
general form is worth more than the fix. The first version hashed raw bytes. This repo is
developed on Windows with `core.autocrlf=true`, so a checkout rewrites LF to CRLF in the working
tree while git stores LF — every render would have read as stale on CI and fresh locally. The
hash now normalises line endings, so it describes the diagram rather than the machine it was
checked out on. *Any content hash compared across machines has to say which normalisation it
means, or it is comparing environments instead of content.*

**[DISCOVERY]** `flutter doctor`: **there is no runnable target on this machine.** No Android SDK
(the actual gap — Android is the target platform), Visual Studio Build Tools present but
incomplete so Windows desktop will not build, and **web is not a fallback** because
`NativeDatabase.createInBackground` is native-only — a web build would need a different drift
backend and would not be testing the app this project decided to build. What still works is the
half that matters for now: `flutter test` is headless on the Dart VM and needs none of it, and
`testing.md` deliberately puts this app's correctness surface in DAO tests against in-memory
SQLite. So FEAT01 and every use-case issue can be built and tested today; what waits is launching
the app and looking at it. Install the Android SDK **before the first UI issue**, not before
FEAT01. Written up in `tooling.md`.

**[DECISION]** `audit.py` grew a symmetric exemption check. `ALLOWED_DANGLING` still exempted
`seq-uc02-add-account.drawio` as "an illustrative filename, not a claim that the file exists"
long after the file was drawn — an exemption that has quietly stopped applying disables a real
check without saying so, which is the same defect as one that never applied. The stale entry is
gone and the audit now warns when any exemption's file comes back.

**[TODO]** Not yet committed at the time of writing: `.github/`, `docs/diagrams/renders.lock`,
and the modified `audit.py` / conventions files. CI fails without the lock file, so committing
the workflow without it would produce a red build on the first push.

## 2026-08-21 — FEAT01 planned; iOS confirmed; the app moves to `app/`

**[STATUS]** `FEAT01-foundation` has a real `plan.md` and is the active issue. It was a
NOT PLANNED placeholder this morning; it is now nine decisions, twelve steps and an
out-of-scope list. Ten of the eleven implementation issues remain unplanned.

**[DECISION]** **iOS is confirmed as a real target** — *"i want to make it for ios and
android."* This is not a new choice so much as the closing of an old one. The 2026-08-19
Flutter entry was explicitly **provisional**, resting on *"okay for now just assume will be
used in ios"*, and it said that if iOS were ever dropped the Kotlin + Compose case became
correct again on its own terms. It is not dropped. The premise is now a requirement, the
stack decision is closed, and the Kotlin entry is permanently rather than conditionally
superseded. *No new argument was needed in either direction: the earlier entry named this
hinge in advance and the confirmation landed on the side it predicted.*

**[DECISION]** **The Dart package lives in `app/`, not the repository root.** The root is
the documentation pipeline's namespace, and Flutter's `lib/` and `test/` are generic enough
that mixing the two in one listing reads as clutter rather than structure.

**[DISCOVERY]** That move silently broke CI, and the general form is worth more than the
fix. The `app` job is guarded on `pubspec.yaml` existing so that it passes trivially until
FEAT01 lands one, rather than failing red for months. Guarding on a **root** path that will
now never exist does not make the job fail — it makes it report success having run nothing,
permanently, with no red build to notice. *A guard that succeeds when it cannot find its
subject is worse than one that fails: a red build gets fixed, a green one gets trusted.*
The probe now reads `app/pubspec.yaml` and every Flutter step carries
`working-directory: app`. This is the second time in two days that a check turned out to be
describing its environment rather than its subject — the renders hash was the first.

**[DISCOVERY]** `flutter create` was run once in `C:\Users\cg857` from a terminal opened in
the wrong directory, scattering twelve items across the home directory. All removed after
verifying every one was generated output — same timestamp, and `.idea/` held only Dart SDK
config, `lib/` only `main.dart`. Two things made the cleanup safe and are worth keeping:
`flutter create` **skips** a `.gitignore` or `README.md` that already exists rather than
overwriting it, and it does not `git init`. The step in the plan now names the target
directory explicitly (`… android,ios app`) instead of `.`, so the command no longer depends
on where the shell happens to be.

**[DISCOVERY]** The PATH trap in `tooling.md` reproduced exactly as written: this session
cannot see `flutter` or `dart` because it started before the PATH edit, while the SDK is
genuinely installed at `C:/flutter` and answers on its absolute path — Flutter 3.47.1 /
Dart 3.13.1, matching the CI pin.

**[TODO]** Nothing is committed. `flutter create` has not been re-run; `app/` exists and is
empty. The four verification commands in FEAT01 D7 must pass **before** the first push,
because landing `app/pubspec.yaml` is what activates the CI job.

**[TODO]** Still open and unaffected by today: UC-13's missing budget-group classes, and
whether `note` appears on the transfer / lend-borrow / repayment screens. Neither gates
FEAT01 — both are about screens, and FEAT01 builds none.
