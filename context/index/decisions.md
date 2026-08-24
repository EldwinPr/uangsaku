# Decisions

Durable, architectural, or process decisions that aren't captured elsewhere.
One entry each, dated, with the reasoning — the alternative rejected matters
more than the option taken.

---

## 2026-08-19 — Project scope: this repo now tracks a personal money tracker

The `bpmn-to-erp` framework is retained as-is and applied to a real (non-ERP,
solo) project. Artifacts go to real project state — `docs/`, `pm/` — not to
`context/document-writer-only/examples/`. This is genuine work that also
exercises the pipeline, not a framework demo, so the demo carve-out in
`CLAUDE.md` does not apply.

## 2026-08-19 — Requirements enter via the FR route, not BPMN

This project has no existing business process to model as-is, so the BPMN
route is not used. Requirements are captured in `docs/fr-nfr.md` and promote
to the **UC FR** sheet, with `UC Non-FR` held for anything arriving later as a
raw request via `docs/requests.md`.

*Sheet naming (corrected 2026-08-19, same day):* the workbook shipped with the
framework's default `UC BPMN` / `UC Non-BPMN` pair, and the 13 promoted rows first
landed on `UC Non-BPMN` as `UC-N01..UC-N13`. That named this project's only real
output after a route it does not use, and pushed its main sheet into the `UC-N`
"not from the main route" prefix. Renamed to `UC FR` / `UC Non-FR` and recoded to
plain `UC-01..UC-13`. The rule is now in `workbook-conventions.md`: the sheet pair
is named for whichever route actually carries the project's requirements, and the
primary sheet always takes plain `UC-xx`.

*Consequence:* the BPMN conventions and `bpmn-drawio-author` go unexercised.
The ERD, class, state, and component conventions still apply downstream and
are unaffected — the workbook is reached by a different road, not skipped.

## 2026-08-19 — Considered and rejected: replacing the pipeline with a flat 4/5-file system

A critique from a comparable-but-more-mature project argued this framework
solves problems a solo side project doesn't have (multiple people, live
customer data, a codebase nobody remembers owning), and proposed replacing it
with `CLAUDE.md` / `STATE.md` / `DECISIONS.md` / `LOG.md` — optimising purely
for cold re-entry cost.

This was trialled: the framework was archived and the flat system written out.
**It was reverted the same day.**

*Why rejected:* the framework is already deliberately flexible, the flat
system's root-level markdown files were clutter duplicating directories that
already existed (`pm/log.md` for LOG, `context/index/decisions.md` for
DECISIONS, `docs/fr-nfr.md` for requirements), and proper documentation is
wanted here despite the project being solo.

*What was kept from the critique* — genuinely load-bearing and worth carrying:

- **`OPEN DECISION:` as a do-not-proceed marker.** More valuable solo, not
  less: there is nobody to ask, so a silent guess is never caught by anyone.
  Used in `docs/fr-nfr.md` §2.
- **Sources disagree → say so, don't silently pick.** Code, docs, and notes
  will contradict each other; on a solo project the same person wrote both
  sides months apart and won't recall which was right.
- **Stale docs are worse than none**, because an agent trusts them completely
  and the false premise isn't noticed until something is built on it.
- **The real risk here is over-production, not stalling** — an agent building
  faster than one person can read, leaving a codebase the owner has never
  actually read. The defense: if the one-line *why* can't be written, the
  decision wasn't made, and the code needs reading.

## 2026-08-19 — `docs/fr-nfr.md` is drafted from assumption, and says so

The FR/NFR draft has **no provenance** — `input/` is empty, no client material
or elicitation transcript exists, and the requirements were inferred rather
than elicited. This is precisely the failure `input/` exists to prevent, so it
is recorded rather than glossed: the document is marked DRAFT/unconfirmed and
its assumptions are tabled in §1 for rejection.

It must not be promoted to the workbook until confirmed. The hard gate already
prevents this, but the reason is worth stating: promoting an assumption makes
it indistinguishable from a requirement within a month.

## 2026-08-19 — Account model: two account types, two-sided transactions, no chart of accounts

Owner's proposal, adopted. Accounts carry a type — money I hold versus money I
owe — and a debt is simply transactions against an owed-type account. Its
balance *is* the outstanding amount.

*Why:* it answers three needs with one structure. Outstanding-and-paid (FR-11)
comes out as a derived balance rather than a field that can drift from reality.
The balance sheet (FR-1) becomes a sum over account types. And "what did I
spend" stops being a flag the user sets and becomes *transactions whose other
end is outside my own accounts* — which excludes transfers, lending, and
repayments automatically, rather than by remembering to tick something.

*Rejected:* a chart of accounts with numbered codes, journal entries,
debit/credit columns, equity accounts, and a formal balance-sheet statement.
Owner considered this explicitly and rejected it as costing usability. Agreed.
The internal structure is kept because it is free; the ceremony is dropped
because it is not. See NFR-1.

*Known cost, accepted:* without equity accounts the books do not self-balance,
so a mistyped amount cannot be detected by reconciliation — it simply stays
wrong until noticed. Acceptable with no auditor and one user; recorded so it is
not rediscovered later as a bug.

*Unresolved within this decision:* the owner's terms "credit account" and
"debit account" collide with debit/credit as entry directions and with credit
cards. The concept is the standard asset/liability split. Naming still open —
see `docs/fr-nfr.md` §4.

## 2026-08-19 — The app assists, it does not police

Owner's ruling, when asked whether fully editable transactions (FR-18) conflict
with the locked budget and the faithful-month requirement (FR-14, FR-16):
they do not.

The distinction is between a **commitment** and a **record**. A budget is set in
advance as a target, so allowing it to move afterwards would make it meaningless
— hence the hard lock. A transaction is a record of something that happened,
and records legitimately need correcting. Whether the owner tidies their own
history is the owner's business; there is no auditor and nobody else is misled.

*Generalised as NFR-4.* This settles a class of questions that will keep
recurring — whether to block a negative balance, warn on over-budget, refuse a
future-dated entry, and so on. Default answer: record it, show the consequence,
do not prevent it. ~~FR-16 is the single deliberate exception, and only because it
guards a target rather than a fact.~~

**Amended 2026-08-20 — there is no exception.** The owner removed the FR-16 lock,
taking NFR-4 from "one sanctioned refusal" to none. The commitment-versus-record
distinction this entry draws was the *reason* for that exception, and the owner
subsequently dissolved it. The entry is kept because the distinction is a real one
that was genuinely considered; it just no longer decides anything here. See
"No guardrails" at the end of this file.

## 2026-08-19 — Stack: native Android, Kotlin + Jetpack Compose + Room *(SUPERSEDED same day — see "Stack revisited: Flutter" below)*

**Decision.** Native Android. Kotlin, Jetpack Compose for UI, Room over SQLite
for storage. No backend. Local-first, single user, single device.

**Why not cross-platform.** Considered and rejected in this order:

- *React Native* — ships a JS runtime and a bridge to render a form and three
  list screens. Owner's objection ("react is heavy") is correct for this workload.
- *SvelteKit + Capacitor* — a WebView with native plugins bolted on. That shape
  earns its keep when a web app already exists and needs to ship as an app; here
  nothing exists yet, so it is cost without the thing that repays it. Owner:
  "will turn into pwa bloat... not saying it's bad but wrong use case."
- *Flutter/Dart* — the serious contender, and dismissing it early would have been
  wrong. It is neither of the above: AOT-compiled to native ARM, no JS runtime,
  no WebView. `drift` gives the same reactive-SQL story Room does, and ML Kit is
  reachable via plugin, so nothing in the requirements rules it out.

**What actually decided it: iOS is a "polite maybe."** Owner's sequence was
Android, then backup, then "if someone wants it, iOS" — clarified as genuinely
speculative, for an app being built for the owner's own use. Flutter's entire
premium buys iOS portability. Paying a permanent cost for an option nobody has
asked for is the wrong trade, and *this was the single hinge* — had iOS been on
the roadmap rather than hypothetical, Flutter would have won and was said so at
the time.

Secondary, in Kotlin's favour once portability stopped counting: lighter install
(no bundled engine — though Compose bundles its own runtime, so the gap is
narrower than native-vs-framework folklore claims), lower idle memory (no second
managed heap alongside ART), and faster cold start (no engine init before first
frame). Cold start matters disproportionately here because the app is opened to
record one expense and closed. Runtime throughput and battery are a wash — the
workload is small SQLite aggregates a few times a day.

Third: ML Kit is first-party on Android, so the OCR deferred in `fr-nfr.md` §3
stays genuinely deferred rather than quietly dying behind a plugin dependency.

**Why Room specifically — this is NFR-2 enforcement, not preference.** Balances
are derived and never stored, so every screen is an aggregate query. A Room DAO
returning a `Flow`, collected by Compose, means the UI re-derives whenever
transactions change and **there is no balance field in the schema to write to**.
"Exactly one source per number" stops being a discipline someone maintains and
becomes the only thing the code can express. UC-09 (correct or delete a
transaction) then costs nothing: delete the row, everything recomputes. NFR-3
(later reporting without restructuring) wants real SQL for the same reason.

**Accepted cost, and the cheap hedge.** iOS later means rewriting the UI layer.
That is the correct price for a maybe. The hedge is free if taken from the start:
keep the domain and data layer free of Android imports — no `Context`, no Android
types in entities or derivation logic. That leaves Kotlin Multiplatform available
later, sharing schema and calculations while only screens are rewritten. Do not
adopt KMP now; just do not write it out.

**Backup is an export, not sync.** Matches the owner's stated sequence. The app
writes a JSON dump or the SQLite file itself through the Storage Access Framework;
the owner saves it wherever they like. No server, no accounts, no conflict
resolution. This satisfies the backup deferred in §3 without touching the still-open
§4 question of where the data lives.

**If sync ever happens, the backend is not in the app.** Owner's own position, and
it is the right architecture: the app stays local-first and never learns about a
server. Sync would be a separate service in its own stack, and the app would gain
a sync client — an addition, not a rewrite. This is what keeps §4 genuinely open
instead of pretending to be.

*Consequence for FR-16:* the budget lock ("after the first week") is the only
time-dependent behaviour in the app, and it depends on the still-undecided meaning
of "a month" (§4). Inject the clock rather than calling the system clock directly,
or the lock cannot be tested without changing the device date.

## 2026-08-19 — Stack revisited: Flutter + Dart (supersedes the Kotlin entry above)

**Decision.** Flutter/Dart, `drift` over SQLite, no backend. Local-first, single
user. Supersedes the Kotlin + Compose + Room decision recorded earlier the same
day. The earlier entry is left intact rather than edited — it names the exact
assumption that changed, which is the only reason this reversal is cheap to audit.

**Provisional, and why that matters.** Owner: *"still not sure to be honest, okay
for now just assume will be used in ios."* This rests on an **assumption, not a
confirmed requirement** — the premise is that iOS is in scope. That is a deliberate
placeholder so downstream work (ERD, class diagrams) can proceed, not a settled
fact. If iOS is later dropped for good, this entry should be re-opened, because
the Kotlin case above becomes correct again on its own terms.

**What changed.** Exactly one thing, and it is the hinge the earlier entry named in
advance: iOS moved from *"polite maybe"* to an assumed target. That entry stated
outright that Flutter would win if iOS were real rather than hypothetical. It is now
assumed real, so the earlier reasoning applies unchanged and points the other way.
No new argument was needed — the premise flipped, and the recorded logic did the rest.

A second factor, raised by the owner after the first decision and never weighed in
it: **the owner has never built a mobile app and has no existing stack.** Flutter is
faster to a first working screen — hot reload is the tightest feedback loop in mobile
development, and there is one widget model to learn rather than a UI toolkit plus the
Android platform plus Gradle. This was acknowledged as a gap in the earlier entry and
is recorded here as a genuine contributing factor, not a rationalisation after the fact.

**Hard constraint carried over: must not be heavy on old Android phones.** Owner's
explicit requirement, and it is the one place where this choice is objectively worse
than the superseded one — Flutter carries its engine and runs a second managed heap.
Non-negotiable consequences, to be treated as build requirements rather than advice:

- Ship **per-ABI split APKs or an App Bundle**, never a universal APK. This is the
  single largest install-size lever available.
- **Test on an actual low-end device**, not just an emulator. Cold start and memory
  pressure are the two figures that matter, and neither shows up honestly on a fast
  emulator.
- Keep the dependency list short. Every plugin is engine weight the owner did not
  ask for, on a device that cannot absorb it.
- Cold start is the metric to watch — the app is opened to record one expense and
  closed, so startup *is* the user experience. If it degrades on the target device,
  that is a stack-level regression and this decision should be re-opened, not
  papered over.

**What carries over unchanged from the superseded entry:**

- **No backend.** Local-first, single user, single device.
- **Backup is an export file**, not sync. If sync ever happens the backend lives
  outside the app in its own stack (owner's position); the app gains a sync client
  rather than being restructured.
- **NFR-2 enforcement is still the storage story, and `drift` provides it.** DAOs
  return reactive streams, the UI re-derives on change, and no balance field exists
  in the schema to write to. "Exactly one source per number" remains a property of
  the code rather than a discipline someone maintains, and UC-09 stays cheap.
  `drift` is the direct analogue of Room here; this requirement did not weaken.
- **FR-16's clock must be injected.** Still the only time-dependent behaviour, still
  blocked on what "a month" means (`fr-nfr.md` §4).
  *(Both halves have since expired: FR-16's lock was removed 2026-08-20, so the clock's
  original justification went with it — it survives only because deciding which period
  is current still asks the date; and "a month" was answered the same day, calendar.)*

**What is genuinely lost, recorded so it is not rediscovered as a surprise:**

- **OCR moves from first-party to plugin.** ML Kit was a Google library on the target
  platform under the old decision; under this one it is reached through a Flutter
  plugin. The OCR deferred in `fr-nfr.md` §3 is still open, but now carries a
  maintainer dependency it did not have before.
- **Footprint and cold start get worse**, permanently. This is the cost of the iOS
  assumption, and it collides directly with the old-phone constraint above. That
  tension is the thing to watch on this project, not a rounding error.

**Replaces the KMP hedge.** The old entry's "keep the domain layer free of Android
imports" TODO is void — Flutter covers iOS directly. The analogous discipline still
applies and is worth keeping for the same reason: **keep entities and derivation
logic in pure Dart, free of Flutter widget imports**, so the domain stays testable
without a widget harness and portable if the UI layer is ever replaced.

**Deliberately not decided here: state management.** *(RESOLVED 2026-08-20 —
Riverpod. See "State management: Riverpod" at the end of this file.)* Flutter has no
official answer (Provider, Riverpod, Bloc, plain setState) and it is a known place
for a first-time Flutter developer to stall. Not choosing now is intentional — it is
a UI-layer decision, it does not touch the schema or the ERD, and it should be made
against a real screen rather than in the abstract.

## 2026-08-19 — Schema shape (ISSUE-001, ERD)

Full reasoning in `pm/issues/001-erd/plan.md` (D1-D8). The three that are durable
and would be expensive to reverse:

**One `Transaction` ledger table with nullable `from_account_id` / `to_account_id`.**
Every movement in UC-04..UC-09 is "money left somewhere and/or arrived somewhere",
so expense/income/transfer/lend/borrow/repayment/adjustment are all one table with
a `kind` discriminator. Two consequences worth the choice: **"is this spending?"
becomes `to_account_id IS NULL`**, so FR-8 and FR-9's "must not count as spending"
is enforced by the shape of the data rather than by a rule every future query has
to remember; and a balance is one expression over one table. This is internal
double-entry without the name, which NFR-1 explicitly permits ("accounting
structure may be used internally... but it may not surface") — the user still sees
one amount, one form, and is never asked to pick two sides.

**`Account.group` is `HOLDING` / `RECEIVABLE` / `PAYABLE`, and "credit"/"debit"
appear nowhere.** This closes the `fr-nfr.md` §4 naming collision by constraint
rather than preference: NFR-1's fit criterion forbids a debit/credit column
outright, so those words were never available. FR-4 and FR-5 make a credit card
and a person both ordinary accounts, so one table with a discriminator is right —
no subtype tables, and no separate `Debt` entity (owner re-confirmed: a debt is an
account).

**`Budget` splits into `Budget_Group` + `Budget_Period`.** `fr-nfr.md` §4 deferred
this to the ERD by name. Three requirements force it independently: trend reporting
needs a stable handle on "Food" that survives a rename; FR-14 makes the amount
per-month data rather than a property of the group; FR-16 gives a month a lifecycle,
and a lifecycle needs a row to live on. `Budget_Period` carries explicit start/end
dates rather than a `YYYY-MM` key, which kept §4's then-unresolved "what a month means"
open instead of silently committing to calendar months. *(Answered 2026-08-20: calendar
month. The columns do not change — the start/end pair is also what a payday-to-payday
model would have needed, so holding the question open cost nothing.)*

*Also settled:* "Others" (FR-17) is the null `budget_group_id`, not a row that could
be renamed or deleted; `Category`/`Subcategory` are two tables rather than a self-FK,
making FR-10's "exactly two levels" structural; and no balance is stored anywhere
(NFR-2), annotated directly on the diagram.

## 2026-08-19 — RESOLVED 2026-08-20: `Budget_Period.state` is derived, not stored

Recorded here rather than in `docs/fr-nfr.md` §4 because it is not a requirements
question — no requirement cares, and no answer changes what the app does. It is a
schema decision, and it is open.

The ERD gives `Budget_Period` a `state` column. D4 also gave it `starts_on` and
`ends_on`, which makes the state fully computable: before `starts_on` + 7 days it is
open, after `ends_on` it is closed, otherwise locked.

**Recommendation: derive it and drop the column.** Two reasons, the second stronger
than the first. It is the same argument NFR-2 already makes about balances — one
source per fact, so nothing can disagree with anything else. And more concretely, a
stored state needs something to write it; on a local-only app with no backend,
nothing runs while the app is closed, so a stored state would sit stale until the
next launch and would be wrong exactly when the user opens the app expecting it to
be right.

The state diagram (`docs/diagrams/state-budget-period.drawio`) is unaffected either
way — it documents the lifecycle, not the storage. If this lands on "derive",
ISSUE-001's ERD gets re-opened to drop the column rather than letting the two
artifacts disagree.

### Resolved 2026-08-20 — derived, and the column is dropped

Owner: *"maybe just active month, that way it's easier if we want to make a yearly
or quarterly report."*

The reasoning arrives from a different direction than the recommendation above and
lands in the same place, which is worth recording because the owner's angle is the
stronger one. A three-value enum answers only "what is this period's status right
now" — it cannot be aggregated. The `starts_on` / `ends_on` pair can: any report
that sums a date range gets quarterly and yearly rollups for free, and neither
needs a new column or a migration. That is **NFR-3** ("the data must support later
reporting without restructuring") satisfied by removing something rather than
adding it.

So `Budget_Period` keeps `starts_on`, `ends_on`, `amount` and drops `state`. The
lifecycle in `docs/diagrams/state-budget-period.drawio` is unchanged and still
correct — it documents how a period behaves over time, not how that behaviour is
stored. "Which month is active" is whichever period today falls inside.

*Deliberately not added: a stored `is_active` flag.* It would reintroduce exactly
the staleness this decision removes — something would have to write it, nothing
runs while the app is closed, and it could disagree with the dates it is supposed
to summarise. Today's date already answers the question.

*Consequence:* ISSUE-001's ERD was re-opened to drop the column rather than letting
the two artifacts disagree — per `erd-conventions.md`, the ERD is the design of
record and anything downstream is a consumer of it.

## 2026-08-20 — A budget period is deletable only while open *(SUPERSEDED same day — see "No guardrails" below)*

Owner: *"full crud first week (or before the month starts), after that view only."*

Resolves a contradiction, not a gap. FR-18 promised full CRUD over budgets; FR-16
said a locked budget cannot change; §3's earlier ruling had settled *editing* and
never mentioned deleting.

The reason deletion mattered more than it appears: **a budget you can delete is a
budget you can escape.** Leaving deletion available after the lock would let the
owner delete and recreate a period at a new amount, which sidesteps FR-16 entirely
and leaves the lock enforcing nothing. The lock only means something if the exit is
closed too.

So the editable window runs from creation — which may be before the period starts —
until the lock at the end of the first week, and covers create, edit, and delete.
After that the period is view-only. This adds one transition to the state diagram:
`OPEN` -> final state, on owner deletion, available from `OPEN` only. `fr-nfr.md`
FR-18 was amended to carry the exception rather than leaving the two documents in
conflict.

## 2026-08-20 — State management: Riverpod (unblocks ISSUE-002)

Closes the "deliberately not decided" note in the Flutter stack entry above. Chosen
after walking the owner — first mobile project, no Flutter background — through the
four realistic candidates.

**The deciding fact is that this app has an unusually small state-management
problem.** Most Flutter state-management tooling exists to manage an in-memory *copy*
of data that really lives behind a network boundary, where the copy can go stale or
disagree with the server. This app has no server (local-first, `drift`), and drift
DAOs return **reactive streams** that re-emit whenever an underlying row changes. The
database already does the notifying. What is left to manage is only what never
touches the database — selected tab, in-progress form input, spinners.

**Riverpod fits that shape with the least machinery.** Its `StreamProvider` consumes
a drift stream directly, with no adapter code between the two halves. Providers are
declared outside the widget tree, so logic stays testable in a plain Dart test with
no widget harness — which is the same discipline the Flutter stack entry above
already requires ("keep entities and derivation logic in pure Dart, free of Flutter
widget imports").

**Why not the others:**

- **Bloc** — would have us hand-writing event and state classes to wrap streams that
  were already fine. On the ISSUE-002 diagrams that is roughly three to four extra
  boxes per screen area, which buries the dependency chain the diagrams exist to
  show under generated ceremony. Its real strength is a large team needing every
  action to be a searchable named type; that is not this project.
- **Plain `setState` + `StreamBuilder`** — genuinely workable here, and rejected for
  a structural reason rather than a stylistic one: the screen must hold the DAO to
  get a stream, which collapses the middle layer and contradicts the confirmed rule
  that the screen never touches the DAO.
- **Provider** — same idea as Riverpod with the sharp edge still attached: lookup is
  by type at runtime, so a wiring mistake is a crash when the screen opens rather
  than a compile error. Riverpod is that library's own author's rewrite to fix
  exactly this.

**Second reason, specific to this owner:** for a first mobile project, Riverpod's
failure mode is a compile error, while Provider's and `setState`'s is an app that
runs and shows a stale number or a blank screen. Debugging the latter without prior
Flutter instinct is the expensive kind of stuck.

**Known cost, recorded so it is not a surprise.** Riverpod's own documentation has
several generations of syntax in circulation and that is a real source of beginner
confusion — Bloc's docs are more consistent. **This project pins the current
`Notifier` / `AsyncNotifier` style** so the question is not re-litigated per screen.

**Consequence for the class diagrams (ISSUE-002).** The middle layer was drafted as
`*ViewModel`. Under Riverpod it splits into two honest halves rather than being
renamed: `StreamProvider` objects carry reads, `Notifier` classes carry writes. The
chain, the arrow direction, and the "screen never touches the DAO" rule are all
unchanged.

## 2026-08-20 — No guardrails: the budget lock is removed (supersedes both entries above)

Owner: *"i guess let budget be full crud like other, it's about users discipline
anyways"*, then *"from now on it's user responsibility no more guardrails or whatever."*

**What changed.** FR-16 locked a month's budget after the first week and was the only
hard refusal in the app. It is gone. A budget period now accepts create, edit and
delete for its whole life, exactly like every other entity. FR-18's carve-out goes with
it, and NFR-4 loses its one sanctioned exception.

**Why the owner is right on their own terms.** NFR-4 ("the app assists; it does not
police") was generalised from the owner's own ruling, and they had already applied it to
skipped months — *"it's users commitment not app problem."* The budget lock was the one
place the app did police, justified as protecting *a target set in advance* rather than
*a record of what happened*. The owner dissolved that distinction: if tidying your own
records is your business, so is keeping to your own budget. There is no third party here
— one user, no auditor, no one else misled.

**The cost, raised before the change and reaffirmed.** This is the part worth keeping,
because the change is easy to misread as being about discipline when the original rule
was not. **FR-16's stated rationale was report fidelity** — *"a budget that can be raised
in week three is not a budget, and a report measured against a moving target says
nothing."* Removing it means UC-12's spent-vs-budget comparison is always satisfiable
after the fact: nothing in the data distinguishes an amount set in advance from one
raised later to match what was spent. What was lost is not restraint, it is a
**measurement**. The owner accepted that knowingly.

**Rejected, but only for now: recording amendments.** The offered middle path was full
CRUD *plus* a record that an amount was changed after the period started, so the report
could show "2M, amended from 1.5M on day 20". That keeps every action succeeding — it
refuses nothing, so it is not a guardrail — while giving the comparison its meaning back.
The owner declined the extra mechanism. Recorded because it stays available as a **pure
addition** (one nullable column, one line of UI) and nothing in this decision forecloses
it. If the budget report is ever found to be saying nothing, this is the fix, not
reinstating a lock.

**What it cost structurally, which is more than it looks.** `locked` ceased to exist,
and `open` / `closed` collapsed into "is this month over" — a date comparison that gates
nothing. `Budget_Period` therefore stopped having a lifecycle at all, and
`docs/diagrams/state-budget-period.drawio` was deleted the day after it was built. That
is the correct outcome, not waste: **a diagram is not a reason to keep a rule.** The
generalisable form, now visible twice on this project in two days — first when state went
from stored to derived, now when the lock went away — is that **status values exist to
gate behaviour, so removing the gate removes the status, not just the enforcement.**
`docs/statuses.md` now lists no values for any entity, and says why.

**NFR-4's fit criterion got stronger, not weaker.** It is a counter: it previously read
"exactly one user action is refused" and named this lock. It now reads **zero**. There is
no longer a sanctioned exception that a future refusal can be argued as similar to, which
makes the test sharper than it was while the lock existed.

**Not touched, deliberately:** FR-10's two-level category depth. It does restrict the
owner — no third level — but it is a data-shape decision the owner stated and confirmed
themselves, not a mechanism for enforcing behaviour. Owner confirmed keeping it when the
audit surfaced it. Recorded so the distinction is on file: **this project's "no
guardrails" rule is about refusing user actions, not about the absence of all structure.**

---

## 2026-08-20 — drift runs the database on a background isolate

The database is opened with drift's `NativeDatabase.createInBackground`, so SQLite
runs on a separate isolate rather than on the isolate that draws the UI. Owner's
call, made while planning ISSUE-005 (the component diagram) after the question
surfaced there undecided.

**What it is, precisely — the framing to keep.** This is *not* concurrent database
access. drift still serialises statements; it does not let two queries run at once,
and nothing about this makes writes parallel or introduces a race. What changes is
**where the work happens**: on the plain setup, a query executes on the UI isolate
and the screen cannot draw until it returns; on a background isolate the query runs
elsewhere and the UI stays responsive while it does. The benefit is a free UI thread,
not throughput. Written down because "concurrency" is the natural shorthand for it
and would mislead anyone who later reasons about locking or write ordering from it.

**Why it was decided rather than left open.** It follows directly from the hard
constraint already attached to the Flutter decision — the app must stay light on old
Android phones. Most queries in this app are trivially small, but UC-01's
`FinancialPosition` and UC-12's `BudgetConsumption` both scan and join the whole
`Transactions` table, and that table only grows. Those are exactly the two queries
behind the primary screen (FR-1), so the cost of getting this wrong lands on the
screen the owner opens most often, and it worsens with every month of use rather
than being visible on day one.

**What it costs:** a little startup time and a little memory — the wrong direction
for the old-phone constraint, but a fixed cost, unlike the query cost it removes,
which grows. Reversible in one line at setup if it ever measures badly.

**Consequence for ISSUE-005.** This is the only edge in the entire system that
crosses a real boundary. There is no backend, no queue and no HTTP call anywhere
(backup is an export file, not sync), so every other edge on the component diagram is
one process talking to itself. An isolate boundary is real — code cannot call across
it, it passes messages — so `component-conventions.md`'s solid-vs-dashed vocabulary
finally distinguishes something on this project instead of being decorative. The
module -> `AppDatabase` edges are drawn as boundary-crossing; module -> module edges
stay solid.

---

## 2026-08-20 — Modules reach each other's data by SQL join, not by calling another module's DAO

ISSUE-005 D1, confirmed by the owner. When the `Accounts` module needs transaction rows
to derive a balance, it writes one query joining `Accounts` and `Transactions` itself.
It does **not** ask `TransactionDao` for the rows and add them up in Dart.

**Rejected alternative — one owner per table.** Each module's DAO would be the only code
touching its own tables, and cross-module data would arrive by a call into the owning
module. It is the more defensible boundary, and it is what "module" normally implies.
Rejected because UC-01's four figures and UC-12's budget consumption would each become
several queries stitched together in Dart, where SQLite does the whole thing in one
statement — and because NFR-2 wants exactly one source per number, computed in one
place. Stitching in Dart is a second place for a number to come from.

**What it costs, stated plainly because the diagram now says it out loud.** These
modules are an organising convention and nothing more. Nothing enforces table ownership
— not the compiler, not a package boundary, not even a within-DAO habit, since
`AccountDao` and `BudgetDao` both legitimately read `Transactions`. Anyone changing the
`Transactions` schema has to check three modules, not one. That is an acceptable trade
for a solo app with one developer, and would not be for a team.

**The cycle this surfaced, which nothing else in the repo showed.** `Accounts` and
`Transactions` depend on each other in both directions: `Accounts` joins `Transactions`
to derive balances (UC-01, UC-02, UC-10), and `Transactions` reads `Accounts` for the
record screen's account picker (UC-04..UC-08, FR-10). The three per-module class
diagrams each draw one module in isolation, so none of them could show this; it only
became visible when the modules were put on one page. Harmless in a single process, but
it means the two can never be separated without breaking one of the two reads. Drawn as
two distinct edges rather than one bidirectional arrow, so the reason for each direction
stays legible.

*The general point, which is the reusable part:* **a per-module diagram cannot show a
cross-module cycle, however carefully it is drawn.** Three correct diagrams hid a fact
that one coarser diagram exposed immediately. That is the argument for the component
diagram existing on a project where its stated purpose — distinguishing real boundaries
from organizational ones — nearly did not apply.

---

## 2026-08-20 — "A month" means a calendar month

Budget periods run first-to-last of the calendar month, and every report buckets the
same way. Owner's call. This was the last item in `fr-nfr.md` §4 that blocked a schema
decision; the other two (currency, transaction note) are single columns.

**Rejected: payday-to-payday.** It is arguably the truer model of how a salaried
person experiences a month, and it was the reason the question was flagged rather than
assumed. It loses on three counts, all of which are about a period's boundary being
derived from editable data. A period could not be created until its opening payday
transaction existed. Editing or deleting that transaction would silently move a period
boundary — and under FR-18 every transaction is editable, so that is not a hypothetical.
And FR-15's automatic creation of next month's budget would have nothing to fire on,
because "next month" would not exist until the owner got paid.

*The general form, which this project has now hit three times:* **deriving a value from
editable data means every edit silently rewrites everything built on that value.** Same
shape as `Budget_Period.state` going from stored to derived (2026-08-20), and as the
FR-16 lock removal collapsing the lifecycle. Calendar boundaries depend on nothing the
owner can edit, which is the whole argument.

**Nothing in the existing artifacts changes.** Calendar was assumed throughout, and
`Budget_Period` already carries `starts_on` / `ends_on` as plain dates on the ERD —
the general shape rather than a bare `YYYY-MM` key. That was not luck worth repeating
silently: those columns are exactly what a future payday-to-payday change would need,
so the cheap option stayed open at no cost.

---

## 2026-08-20 — One app-level currency, and amounts stored as integer minor units

`IDR` or `USD`, chosen by the owner at setup, applying to the entire database. Amounts
in all three amount columns are `int`, counting that currency's minor unit. FR-19,
UC-14; the setting lives in a one-row `Settings` table, which is a fourth module.

**Multi-currency was asked for first, and withdrawn the same day.** The owner opened
with IDR/USD/CNY and "add later". The cost was raised before anything was written: a
currency per account, a rate at a point in time behind every total, FR-1's four figures
no longer summable into a net, UC-12's budget comparison splitting per currency, and a
transfer between two currencies needing two amounts rather than one. The owner pulled
back to a single currency in the same message. Recorded because the retreat was the
right call and the reasoning should not have to be rebuilt if it is raised again.

*Not foreclosed, and deliberately so:* because the currency is stored **with the data**
rather than in device preferences, a future per-account currency is an added column, not
a reinterpretation of rows already written.

**`double` was proposed for amounts and rejected on NFR-2 grounds.** The owner's
suggestion ("that way we can use double") was pushed back on once, and accepted. Binary
floating point cannot represent 0.1 exactly, so error accumulates across sums — and NFR-2
("the numbers must agree with each other") is exactly the requirement that breaks. The
failure is nasty because it is unfixable at the query layer: a balance sheet whose net
stops matching the sum of its parts by a cent has its error in storage. Integer minor
units are exact, and `IDR` needs no fractional part at all.

*The general form worth keeping:* **when a requirement says numbers must agree, that is a
storage decision, not a formatting one.** Display is where a decimal point exists; the
database should hold the smallest indivisible unit and nothing else.

**Changing the currency later re-labels, it does not convert — and is not blocked.**
50,000 recorded as rupiah reads as 50,000 dollars. NFR-4's fit criterion is zero
refusals, so the app warns plainly at the moment the owner would cause it and then
complies. This is the standing rule applied rather than an exception argued.

**Why `Settings` is in the database and on the ERD.** Backup is an export file
(2026-08-19), so a currency living in device preferences would not travel with the
amounts, and a restored backup would silently reinterpret every figure in it. It is
drawn on the ERD despite having no foreign key to anything because its single value
changes the meaning of `Account.opening_amount`, `Transaction.amount` and
`Budget_Period.amount` — **a coupling with no referential trace is exactly the kind the
component diagram was built to make visible**, and hiding it as configuration would
repeat that lesson in a new place.

**Consequence: a fourth module.** Currency belongs to none of Accounts, Transactions or
Budgeting — it is not where money lives, not something that happened, and not a budget.
`Settings` joins them on the `Modules` sheet, which under the one-diagram-per-module rule
also means a fourth class diagram (`class-settings.drawio`). The alternative, forcing it
into Accounts because it touches `opening_amount`, would have misstated ownership on
every artifact that keys off `Modul`.

## 2026-08-21 — iOS is confirmed as a real target, and the Flutter premise is now settled

**Decision.** iOS and Android are both targets. Owner, asked which platforms the project
should generate: *"i want to make it for ios and android."* `FEAT01` scaffolds with
`--platforms=android,ios`.

**This closes an open assumption rather than making a new choice**, which is the only
reason it deserves an entry at all. The Flutter entry above (2026-08-19) was recorded as
**provisional**, resting on *"okay for now just assume will be used in ios"*, and it said
plainly that if iOS were later dropped for good the entry should be re-opened because the
superseded Kotlin case would become correct again on its own terms.

It is not dropped. The premise the whole stack decision hinged on is now a stated
requirement, so:

- **The Flutter decision stops being provisional.** No new argument was needed in either
  direction — the earlier entry named this exact hinge in advance and the confirmation
  simply lands on the side it predicted.
- **The Kotlin entry above is now permanently superseded**, not conditionally. Its own
  reasoning ruled itself out for a real iOS target; that condition is met.
- **`fr-nfr.md` §4's caveat on the stack is retired.** Updated the same day.

**What does not change.** The hard constraint carried over from the Kotlin entry —
*must not be heavy on old Android phones* — survives intact and is not softened by iOS
being real. Per-ABI splits or an App Bundle, and testing on an actual low-end device,
remain build requirements rather than advice. Adding a second platform makes that
constraint harder to honour, not easier.

**Accepted cost, stated plainly: iOS cannot be built on this machine.** Apple's toolchain
is macOS-only, so `ios/` will exist under version control and go unexercised until there
is a Mac. This is deliberate — generating it now keeps the iOS configuration versioned
from the first commit instead of arriving as a large untracked diff months later — but it
means **"builds on Android" is not evidence the iOS target is healthy**, and nothing in CI
checks it. An iOS build job needs a `macos-latest` runner, which is billed well above
Linux; not configured, and not worth configuring before a Mac exists.

Nothing in the data layer is affected. `NativeDatabase.createInBackground` is SQLite,
which ships with both platforms, so the ERD, the class diagrams and every DAO are
platform-neutral as drawn.

## 2026-08-21 — The Flutter project lives in `app/`, not at the repository root

**Decision.** The Dart package is created at `app/`, leaving `docs/`, `pm/`, `context/`,
`input/` and `audit.py` at the root. Owner's call, made before any code landed.

**Why it is worth recording.** The repo is a documentation pipeline that has now grown a
codebase, and the root is already the documentation's namespace. Dropping `lib/`, `test/`,
`android/`, `ios/`, `pubspec.yaml` and `analysis_options.yaml` beside `docs/` and `pm/`
would mix two vocabularies in one listing, and Flutter's names are generic enough
(`lib`, `test`) that the collision reads as clutter rather than structure.

**The trap this creates, and why it is written down rather than remembered.**
`.github/workflows/ci.yml`'s `app` job is guarded on `pubspec.yaml` existing — a guard
written when the project was going to be at the root, so that the job passed trivially
until `FEAT01` landed instead of failing red for months. With the package at `app/`, that
probe **never fires**, and the job goes green having run nothing at all, permanently and
silently.

*The general form worth keeping:* **a guard that reports success when it cannot find its
subject is worse than one that fails.** A red build gets fixed; a green one that checked
nothing gets trusted. The probe now points at `app/pubspec.yaml` and every Flutter step
carries `working-directory: app`.

**Consequences applied the same day:** `dart-and-flutter.md`'s directory layout gains the
`app/` prefix; `FEAT01`'s D2 file manifest is rewritten against it; `map.yaml`'s future
UC → code entries are `app/lib/src/<module>/`. `audit.py` is unaffected — it reads
documentation paths, none of which moved.

## 2026-08-21 — Budget group CRUD belongs to UC-11, not UC-13

**Decision.** Creating, renaming and deleting a **budget group** moves from UC-13 ("Set Up
Categories and Budget Groups", Transactions) to UC-11 ("Set a monthly budget amount",
Budgeting). UC-13 is re-scoped to categories and subcategories only.

**The gap that forced it.** The fourteen sequence diagrams were drawn against the class
diagrams, and `seq-uc13` could not draw step 3: `class-budgeting.drawio` had the
`BudgetGroups` table but no screen, notifier method or DAO method for managing a group,
and the screen that would have done it (`CategoryManagerScreen`) lives in Transactions.
Rather than invent a participant, the diagram scoped the step out with a note — correct
per `sequence-conventions.md`, but it meant **UC-13 as drawn did not deliver what the
workbook promised.**

**Why moving it beats adding the classes to Transactions.** `Budget_Group` is a Budgeting
entity. ISSUE-005 D1 permits a module to reach another's data by SQL join, so a
Transactions screen writing `BudgetGroups` would have been *allowed* — but D1 argues its
case in terms of reads, and its own text concedes that table ownership is enforced by
nothing. Putting group CRUD in the module that owns the entity keeps the one boundary this
system still has legible, and costs a workbook edit rather than a new screen.

**What it costs.** `BudgetNotifier` and `BudgetDao` gain group methods — the class *boxes*
already existed, only the methods were missing, which is why this reads as smaller than the
alternative. `seq-uc11` gains the interaction, `seq-uc13` loses its out-of-scope note, and
both workbook rows are rewritten.

**The general form, and this project has now hit it twice** (the first was UC-03's
adjustment writing through `AccountDao`): *when a use case names work no class diagram
supports, the question is which module owns the entity — not which screen the workbook
happened to mention it on.* A workbook row groups things by what the owner sets up in one
sitting; a class diagram groups them by what owns the data. They disagree sometimes, and
the entity wins.

## 2026-08-21 — The free-text note appears on every recording screen

**Decision.** `Transaction.note` is offered on all of them — expense, income, transfer,
lend, borrow and repayment — not only expense and income.

**The question existed because the diagrams disagreed.** `seq-uc04` and `seq-uc05` carried
`note` in the recording signature; `seq-uc06`, `seq-uc07` and `seq-uc08` did not. The
column exists on `Transaction` either way, so this was never a schema question — only
whether three screens offer the field.

**Why all of them.** `note` was decided as a column on the **entity**, not on a kind
(2026-08-21). ERD D1 put all seven kinds in one ledger table precisely so there would be
one insert path and one form; a per-kind rule about which screens show which fields
reintroduces exactly the branching that decision removed. *"Lent Budi 500k for his
motorbike"* is the clearest case for a note in the whole app, and it sits on one of the
three screens that lacked it.

**The cost, stated because it is real:** FR-6 wants the recording path to be the fastest in
the app, and every field on a form is friction. Accepted on the grounds that the field is
optional and empty by default — a nullable column, so "wrote nothing" and "wrote an empty
note" stay one fact with one representation.

## 2026-08-21 — The planning gate gets an unattended mode, with a hard halt condition

**Decision.** For the unattended implementation run, `feat-planner` may mark a plan
`AUTO-CONFIRMED` and `flutter-coder` may act on it — **but only when every decision in that
plan is derived from an artifact the owner has already confirmed.** A plan that must make a
genuinely new choice **halts the issue** and queues the question in `pm/questions.md`.

Owner's call: *"the plan writing is part of the hands off."*

**What this changes and what it deliberately does not.** The gate reads *"a `plan.md` must
exist and be reviewed/confirmed by the user before work starts."* Read as ceremony, that
blocks any unattended run at the first stub. Read for its purpose — **do not build on
unconfirmed assumptions** — it says something narrower, and the narrower reading is the one
worth keeping.

A plan whose every D-entry traces to a confirmed FR, the sequence diagram, a class diagram,
`decisions.md` or `enums.md` is a **transcription of decisions already made**. Nothing in
it is unconfirmed; asking a human to click yes adds a signature, not a check. A plan that
must choose — a name, a boundary, a trade-off nobody has ruled on — is the case the gate
was written for, and it still stops.

**So the gate is not weakened; it is made specific.** The test moves from *"did a human
approve this document"* to *"does this document contain anything a human has not already
approved."* The second is the question the first was standing in for, and unlike the first
it can be checked.

**The halt is per-issue, not per-run.** A halted issue blocks only what depends on it. The
backlog has two independent chains (UC14 → UC02 → UC01/UC03/UC10, and UC13/UC11 → UC04 →
UC09/UC12), so a halt on one leaves the other runnable. The run continues wherever
dependencies are still satisfied and reports every halt at the end.

**Accepted cost, and it is the real one.** *The judgement of what counts as "already
decided" is now the agent's.* An agent that is wrong in the permissive direction will
self-confirm a plan containing a genuine choice, and no human sees it before code is
written against it. That is the failure this mode makes possible and attention should go
there — not to the plans that halt, which are the mode working. This is why the planner is
instructed to halt on doubt rather than to reason its way to a default, and why every
`AUTO-CONFIRMED` plan must cite, per D-entry, the artifact it derives from: **a citation
that cannot be written is the signal that the decision is new.**

**Not a precedent for attended work.** When the owner is present, the gate is unchanged.
This mode exists because the owner deliberately removed themselves to test how the pipeline
holds up unattended — plan quality being the variable under test — and a mode that only
applies while nobody is watching should be recorded as exactly that.

## 2026-08-21 — FEAT01: three rulings the real toolchain forced

The scaffold issue was the first to run `pub get`, `build_runner`, the analyzer and the
test suite against `context/coding-conventions/`, which had been written provisionally.
Three things in it lost to the toolchain or to the vocabulary, and all three are durable.

**1. `constant_identifier_names` is off, project-wide.** `docs/enums.md` and the class
diagrams spell `AccountGroup` as `HOLDING` / `RECEIVABLE` / `PAYABLE` and `Currency` as
`IDR` / `USD`. Under `.textEnum<T>()` those identifiers are **the literal text stored in
every row**, so renaming them to Effective Dart's `lowerCamelCase` would either change the
stored vocabulary or split it from the documents that define it. `coding-conventions/README.md`'s
own rule — domain terms stay spelled as the artifacts spell them — outranks the lint here.
`TransactionKind`'s seven values were already `lowerCamelCase` and are unaffected, which is
the shape to expect: **the exception is the vocabulary, not the language.** Recorded rather
than left as an inline `ignore` because it applies wherever a documented enum lands, and
because disabling a whole rule is a decision that should be findable. *Reviewed at close:
the narrower fix is a per-file `ignore_for_file`; the project-wide form was kept because
the same two enums are read from four modules and a per-file pragma would have to be
repeated in each, but this is the one ruling here that a later pass may legitimately
narrow.*

**2. The database is opened with `drift_flutter`'s `driftDatabase()`, not a raw
`NativeDatabase.createInBackground`.** Verified at close by reading `drift_flutter-0.3.1`:
its default native path calls `NativeDatabase.createBackgroundConnection`, and
`createInBackground` is itself a thin wrapper around that same call. **The background
isolate — the only real boundary in this system (ISSUE-005) — is therefore unchanged**,
and what is gained is a `path_provider`-resolved database file instead of a hand-written
path helper. `drift.md` updated. The substitution is only safe because the guarantee was
checked in the package source rather than inferred from the package's description.

**3. `appDatabaseProvider` is a plain hand-written `Provider`, not `@riverpod`.** The
conventions allow two provider shapes — `StreamProvider` for reads, `Notifier` for writes —
and this is neither; it is plumbing (FEAT01 D5). A plain `Provider` in `riverpod` 3.4.2
defaults to `isAutoDispose: false` (verified in `providers/provider.dart`), so it is kept
alive without the annotation, which is exactly what "outlives every screen" asked for. It
also keeps one generator per `part` file: `AppDatabase` already owns `app_database.g.dart`
via `@DriftDatabase`.

## 2026-08-21 — UC-13: two rulings the real toolchain forced above the database

The categories issue was the first to write a DAO, a provider and a screen. Both rulings
below were verified by `issue-qa` re-running the failing shape against the analyzer and the
generator, not accepted from the coder's report (`lessons.md` §10), and both bind every DAO
and provider written after this one.

**1. A DAO whose class diagram gives it `update()` or `delete()` cannot be a
`DatabaseAccessor`.** `drift.md` showed every DAO as `@DriftAccessor` /
`DatabaseAccessor<AppDatabase>`, registered through `@DriftDatabase(… daos: […])`.
`DatabaseAccessor` extends `DatabaseConnectionUser`, which already declares
`update<Tbl, R>(TableInfo<Tbl, R>)` and `delete<T, D>(TableInfo<T, D>)`; a subclass method
of either name with a named-parameter signature is a straight `invalid_override` analyzer
error, reproduced in isolation at close. `class-transactions.drawio` names `CategoryDao`'s
own methods `update()` and `delete()`, and the class diagram outranks the convention
(`coding-conventions/README.md`), so **`CategoryDao` is a plain class composing
`AppDatabase`** and calls `_db.update(table)` / `_db.delete(table)` on a different object
than `this`. Consequence: **no `daos: […]` entry on `@DriftDatabase`** — there is no
accessor for drift to attach — and no change to the generated code or to
`drift_schemas/app_database/drift_schema_v1.json`, both verified byte-identical at close.
`AccountDao`, `TransactionDao` and `BudgetDao` all draw `delete()` too, so this is the
shape for all of them, not a one-off.

**2. `riverpod_generator` cannot build any provider whose type mentions a drift-generated
row class.** `@riverpod` on a bare top-level function returning `Stream<Category>` fails
with `InvalidTypeException: The type is invalid and cannot be converted to code`; the
identical function returning `Stream<int>` builds. Reproduced at close by swapping only the
type, which isolates the generated `part`-file class as the cause. So **`categoryTreeProvider`
and `categoriesProvider` are both hand-written**, and this is broader than UC-13 D2's
anticipated contingency (which was only that codegen would name the notifier's provider
`categoriesNotifierProvider` rather than the `categoriesProvider` the class diagram names —
also true, and also resolved in the class diagram's favour, the `appDatabaseProvider`
precedent). Codegen stays the default for everything that does not touch a row class;
in practice that will be very little, since every read provider in this app carries drift
rows. `riverpod.md` corrected in place.

## 2026-08-22 — UC-11: a `Notifier`, not a `StreamNotifier`, for a screen that reads more than one stream

**Decided by the toolchain, recorded because it binds every multi-stream screen after this
one.** `SetBudgetScreen` needs three drift queries at once — the groups, this month's
periods, and last month's for FR-15's pre-fill — which is the first screen in this app to
read more than one.

The obvious shape, and the one UC-11 D3 proposed first, is a `StreamNotifier` returning a
hand-rolled `combineLatest3` over the three drift streams. **It does not release its
subscriptions.** When the provider's `autoDispose` fired, the combining `StreamController`'s
`onCancel` never ran, so the three underlying drift subscriptions stayed open and
`AppDatabase.close()` hung indefinitely in a widget test after the unmount-and-pump that
`testing.md` prescribes. Isolated with three probes: a `StreamNotifierProvider` wrapping a
*single* drift stream closes cleanly; the same three-way merge watched through a bare
`ProviderContainer` emits the right value every time; only the
`StreamController`-wrapped-`Stream`-under-`StreamNotifier` combination leaves cancellation
unrun. So it is not `Notifier`, not auto-dispose in general (`categoryTreeProvider` is also
`autoDispose` and closes cleanly), and not the merge logic.

**The shape that works, and the default from here:** a plain
`Notifier<AsyncValue<T>>` whose `build()` opens each drift subscription by hand and
cancels them in `ref.onDispose`. That ties cancellation to the provider element's own
disposal with no controller layer in between.

This is the third consecutive issue in which the real toolchain overruled a convention
written before any code existed (FEAT01's `driftDatabase()`, UC-13's two, now this).
`riverpod.md` corrected in place. It does **not** disturb the read/write split: the screen
still never receives a write's result, and `budgetProvider` is still the single source
`class-budgeting.drawio` draws.

## 2026-08-22 — UC-11 as-built: `BudgetNotifier` does not depend on `Clock`

`class-budgeting.drawio` carried an edge `BudgetNotifier → Clock` alongside
`BudgetDao → Clock`. **The code has only the second, and the edge was removed at close.**

Two confirmed artifacts already said so and the class diagram was the lone outlier:
UC-11 D5 injects `Clock` into `BudgetDao`, and `seq-uc11-set-budget.drawio` only ever shows
`BudgetDao` asking `today()`. In the built code the notifier names its months
*relatively* — `watchPeriods()` and `watchPeriods(monthsAgo: 1)` — and the DAO turns
`monthsAgo` into dates, so the notifier has no reason to know today's date and does not
receive a `Clock`.

Recorded because a dependency drawn on a class diagram is a claim about code, and
`class-budgeting.drawio` is the diagram UC-12 will build `BudgetOverviewScreen` and
`budgetConsumptionProvider` from. The diagram's own note already says to drop `Clock`
"if a later pass finds nothing actually asking it the time" — `BudgetDao` does ask, so
`Clock` itself stays; only the second edge was wrong.

## 2026-08-22 — Changing the currency changes the prefix and nothing else

Owner's ruling, answering `pm/questions.md` Q1 — the halt that blocked eight of the eleven
implementation rows: *"for q1 by change currency it just changes the prefix thats all"*.

**What it means.** `Settings.currency` selects how an amount is *displayed*. The stored
values are untouched: every amount is an `int` of minor units and stays exactly the integer
it was. Nothing is converted, no rate is applied, no other table is read or written, and no
exponent arithmetic runs at the moment of the change. IDR 250000 becomes USD 250000 shown
with a different prefix, not USD 15.

**The exponent still applies to rendering, not to storage.** `enums.md` gives IDR exponent 0
and USD exponent 2, which is how a stored `int` becomes text. Changing the currency changes
which exponent the formatter uses, so the same integer renders differently — that *is* the
re-labelling FR-19 warns about, and it is a display concern, not a migration.

**What it rejects.** A "setup complete" marker on `Settings` (`schemaVersion` 2 for a
distinction that changes nothing), and counting existing amounts across Transactions /
Accounts / BudgetPeriods to decide the message's wording (a cross-module join bought for
nothing, and not drawn on `seq-uc14-choose-currency.drawio`).

**The consequence for the sequence diagram's guard.** `seq-uc14`'s `opt` fragment reads
*"an existing currency is being changed, not initial setup"* — a predicate the schema cannot
express, since FEAT01 seeds a currency at first launch so "an existing currency" is always
true. It resolves to **the chosen currency differs from the stored one**, because that is
exactly when the prefix changes. The carve-out for initial setup was written when the change
was imagined to be consequential; it has no referent once the change is a prefix, and
warning on a genuine first-setup switch from the IDR seed to USD is *true* rather than
spurious. The guard text is corrected on the diagram at UC-14's as-built pass rather than
reinterpreted silently.

**Still true, and worth keeping in view:** this is the reason NFR-4's zero refusals costs
nothing here. There is no data-loss scenario to protect the owner from, so the notice is a
message and never a branch that ends.

## 2026-08-22 — Account CRUD splits from UC-02, and the schema does not change

Owner's ruling answering `pm/questions.md` Q2. The workbook calls renaming, editing and
deleting an account *"alternate flows of this use case"*; `seq-uc02-add-account.drawio`
draws create and nothing else. **The diagram wins for UC-02, and the rest becomes its own
issue** — `UC02B-edit-account`, TODO, with its own sequence diagram still to be drawn.

**Why the split rather than widening UC-02.** Deleting is the expensive half.
`Transactions.from_account_id` and `to_account_id` reference `Accounts` with **no
`onDelete`**, so SQLite's default `NO ACTION` makes deleting a referenced account fail — and
a failure is a refusal, which NFR-4's fit criterion forbids outright. Every non-refusing fix
alters the table: `ON DELETE SET NULL` or `CASCADE` both mean `schemaVersion` 2, a migration
and a new snapshot, in an app whose data cannot be regenerated. Buying that inside an issue
whose diagram draws only create would have been the widening `general-rules.md` forbids.

**What is still open, and belongs to `UC02B-edit-account`:** what happens to the transactions
of a deleted account. **UC-11's precedent does not transfer.** Deleting a budget group nulls
`budget_group_id` and the money reappears under "Others" (FR-17) because that column is an
optional *tag*. A transaction's from/to account is its *identity* — a transaction with
neither side is not a record of anything — so the same move is not available and the answer
has to be made rather than derived.

**The accepted cost, stated so it is not rediscovered as a bug:** **FR-18 says "no entity is
create-only, and no entity has an exception", and `Account` was exactly that exception until
`UC02B-edit-account` landed.** Filed as `pm/findings.md` F14, **fixed 2026-08-24** —
`AccountDao` gained `update()`/`delete()` (the latter a soft delete, see the 2026-08-23 entry
below), so `Account` now has full CRUD like every other entity and FR-18 was never amended.

## 2026-08-23 — Deleting an account is a soft delete; Q3 answered

Owner's ruling, answering `pm/questions.md` Q3 ("soft delete/disable"), unblocking
`UC02B-edit-account`. Chosen over the three shapes the question posed: **A (cascade)**
destroys history irreversibly in an app whose data cannot be regenerated; **B (set null)**
contradicts the from/to columns' role as a transaction's *identity*, not an optional tag
(UC-11's null-the-tag precedent explicitly does not transfer here — see the 2026-08-22
entry above); **C (refuse)** is a refusal, which NFR-4 forbids by name.

**The shape:** `Accounts` gains `deleted` (`BoolColumn`, default `false`) and `deletedAt`
(`DateTimeColumn`, nullable) — the identical two-column shape UC-10 already shipped for
`settled`/`settledAt` (`Clock`-stamped, set together, never separately). `schemaVersion`
becomes 2; a migration and a new `drift_schemas/` snapshot are required (`lessons.md` §8's
cost, paid deliberately rather than avoided).

**What "delete" means now:** `UC02B`'s delete control writes `deleted = true,
deletedAt = Clock.now()` — a `Future<void>` update, never a `DELETE FROM Accounts`. It
always succeeds (NFR-4): there is no FK to violate, because the account row is never
removed. Every transaction that referenced the account keeps referencing a real row, so
its name and history keep resolving exactly as before.

**Consequences for existing shipped queries — recorded so `UC02B`'s plan can cite them
rather than re-deriving:**
- **FR-1 (`AccountDao.watchPosition()`/`watchBalances()`) and FR-11
  (`watchDebtProgress()`) must filter `WHERE NOT deleted`.** A deleted account's balance
  stops contributing to the four figures and stops appearing in the balance-sheet list —
  "deleted" has to mean gone from the owner's view of their money, not merely
  unselectable. This is a **behavior change to shipped UC-01/UC-10 queries**, made by
  `UC02B` as part of landing the column, not scope creep — the column does not exist
  without this issue and the queries are wrong the moment it does.
- **`TransactionDao.watchAccounts()` (the record-form/edit-sheet picker, UC-04/UC-09)
  must filter `WHERE NOT deleted`** — a deleted account cannot be chosen for a *new* or
  *amended* transaction side. `TransactionDao.watchAll()` (UC-09's list) does **not**
  filter — a transaction already pointing at a deleted account still needs its stored
  side name to render, which is exactly why B (set null) was rejected.
- **`BudgetDao` is untouched** — it never references `Accounts`.
- **No un-delete is drawn anywhere** and none is implied by this ruling; reactivating a
  deleted account is a future question if the owner ever asks for it, not answered here.

**Not a lifecycle** (`docs/statuses.md`): a one-way flag flipped by exactly one action, the
same reasoning that kept `settled` off the statuses register. No state diagram.

## 2026-08-23 — Adjustment encodes as fixed side + signed amount; Q4 answered

Q4 was left to my judgment ("pick whatever you see fit") rather than the owner naming a
side. **Chosen: Option B** — `to_account_id` is always the account being corrected,
`from_account_id` stays `null` always, and `amount` carries the signed diff (positive for
an upward correction, negative for a downward one). `docs/enums.md`'s kind-table hedge
(*"the account, or null | null, or the account"*) resolves to the first branch, always.

**Why B over A (side-follows-sign, magnitude-only amount):** A's cost is not
symmetric with B's. A's downward-correction row satisfies `to_account_id IS NULL` and
therefore reads as **spending** everywhere that predicate is checked — including UC-12's
"Others" bucket, exactly the workbook's own warning that an adjustment must be *"recorded
and visible rather than silent"* turned against itself: it would be visible as the wrong
thing. B's cost — introducing the ledger's one negative-amount kind — is contained and
already proven harmless: **UC-01, UC-09, UC-10 and UC-12 were all built and tested
encoding-independent** (each cites `to_account_id IS NULL` with no `kind` filter, pinned
by a dual-encoding test asserting identical output under both options), so B requires
**no change to any shipped query** — the balance formula `SUM(to_account_id contributions)
- SUM(from_account_id contributions)` already handles a signed `amount` correctly, since a
negative contribution on the `to` side subtracts exactly as an equivalent `from`-side
magnitude would.

**Consequence for `UC03-adjust-account`'s plan:** the write is `insert(kind: adjustment,
toAccountId: theAccount, amount: signedDiff)`, `fromAccountId` always `null`. No existing
DAO method changes shape — `TransactionDao.insert()` already accepts a signed `int`
(nothing in its signature or body assumes non-negative). `docs/enums.md`'s adjustment row
should be tightened from the hedge to this resolved rule.

## 2026-08-24 — Account-name collision hard-blocks; the one counted NFR-4 exception (FEAT08 D3/D4)

`FEAT08-transaction-ux-and-name-block` plan D3 replaces FEAT06 D3's warn-and-proceed
duplicate-account-name notice with a real refusal: `AccountFormScreen`'s create and edit
saves do not call `accountsProvider.notifier`'s write and do not pop when the typed name
case-insensitively collides with another non-deleted account's name (`_nameCollides()`,
unchanged from FEAT06). The screen stays open with the name still typed in.

**Why this is allowed to be a refusal at all**, when NFR-4's fit criterion
(`docs/fr-nfr.md`) is otherwise zero: asked directly whether duplicate account names
should warn-and-proceed or hard-block, the owner answered *"Hard block for real"*
(2026-08-24). `docs/fr-nfr.md`'s NFR-4 section now names this as the sole counted
exception, mirroring how the old FR-16 budget lock was once "the one" sanctioned
exception before its removal took the count to zero on 2026-08-20 — the count returns to
one, scoped to this single field only.

**Scope, restated so it is not generalized by accident:** this is `Account.name`
uniqueness only. No other field on any screen (category names, budget group names,
transaction contents, anything else) gains a refusal from this decision — every other
screen's zero-refusals discipline (delete, save-with-empty-fields, same-account transfer,
etc.) is untouched.

## 2026-08-24 — A fourth `Account.group`, `PERSON`, whose direction is re-evaluated on read (FEAT11)

`AccountGroup` gains a fourth value, `PERSON`, alongside the existing `HOLDING`/
`RECEIVABLE`/`PAYABLE`. Owner's direct request: `RECEIVABLE`/`PAYABLE` commit a
person's direction at account-creation time, which is right for a credit card but
wrong for an actual person who might owe the owner this month and be owed next month.

**Not a fifth figure.** FR-1's four figures stay four. `PERSON` folds into the
existing `owedToMe`/`owedByMe` split by the **sign of its current balance**, decided
fresh on every read in `AccountDao.watchPosition()` — positive → `owedToMe`, negative
(signed, matching `PAYABLE`'s existing convention) → `owedByMe`. Nothing is stored
about which side a `PERSON` account is currently on; NFR-2's "derived, never stored"
rule extends to this bucketing decision the same as everything else.

**Additive, not a replacement.** `RECEIVABLE` and `PAYABLE` are unchanged and keep
existing — the owner was explicit this is a fourth option, not a migration of
existing accounts. A credit card that will only ever be `PAYABLE` gains nothing from
becoming a `PERSON`; the new value exists for the case the owner doesn't want to
commit to a direction upfront.

**Not a schema migration.** `Accounts.group` is `textEnum<AccountGroup>()()`, a plain
`TextColumn` with no `CHECK` constraint — adding a fourth legal Dart-side value needed
no `schemaVersion` bump, no `drift_dev make-migrations`, nothing in
`app/drift_schemas/`. Worth recording because every schema-touching issue up to this
one *did* need that dance (FEAT03's Settings columns, UC02B's soft-delete flags); this
one looked similar at a glance and genuinely wasn't.

**Repayment direction, resolved case by case.** `RecordTransactionScreen`'s `Repay`
flow already infers direction from `RECEIVABLE` vs `PAYABLE` with no user prompt —
unambiguous, left exactly as it was. For a `PERSON` account the same trick doesn't
work, since its direction isn't fixed; asked directly, the owner chose an explicit
toggle ("they paid me" / "I paid them" — plain wording, not "utang"/"piutang" jargon,
per the owner: *"i dont know the correct word so it's easy to understand"*) over
inferring silently from the current balance, though the current balance still seeds
which side the toggle starts on.

**Inline account creation reuses FEAT05's pattern, not a new one.** The Lend/Borrow/
Repay person-picker becomes autocomplete-with-inline-create, the same shape
`_CategoryAutocompleteField` already established — a checkbox decides the created
group (unchecked: the flow's contextual default, `RECEIVABLE` for Lend/`PAYABLE` for
Borrow; checked: `PERSON`). Repay shows no checkbox at all — there is no sensible
"normal" default for inline-creating someone you're repaying before ever having lent
to or borrowed from them, so that path always creates `PERSON`.
