# Findings

**The unattended run's output.** After the last issue closes, two `repo-qa` sweeps run —
one over the app, one over the paper trail — and write what they find here. **Then the run
stops.** Nothing is fixed, no issue is reopened.

That stop is deliberate. A cross-cutting finding often needs a decision only the owner can
make, and a run that starts reopening closed issues churns without converging. **This file
is what the owner reads when they come back** — a clear list beats a repo quietly edited
toward one agent's judgement.

Distinct from its neighbours: `pm/questions.md` holds questions that **blocked** work before
it happened; this holds problems found in work **already done**. An entry here never gates
anything — it is a report, not a queue.

## Format

```
## F{N} — {one-line finding}                    [OPEN | ACCEPTED | FIXED | WONTFIX]
**Scope:** APP | TRAIL          **Severity:** defect | risk | improvement
**Where:** file:line, or the artifact
**Violates:** the rule, decision or requirement — by name
**What it is:** what is wrong, and what it causes. Not how to fix it.
**Confidence:** certain | likely | worth checking
```

**Severity is whether it is wrong, not how hard it is to fix.**

- **defect** — breaks a stated requirement or a recorded decision. A `double` holding money,
  a disabled control against NFR-4's zero refusals, a diagram that no longer matches code.
- **risk** — not wrong today, but a trap. A duplicated query that will drift, a convention
  that slipped partway through.
- **improvement** — better if changed, wrong in no sense.

Keep the three separate. Forty style notes bury two real defects, and this list exists to
decide what happens next.

## Resolving

The owner reads, then either promotes a finding to a tracked issue in `pm/tracker.yaml`
(where it gets a plan like any other work) or marks it `WONTFIX` with a reason. **A defect
resolved by a decision rather than a change is still resolved** — record which.

`lessons.md` applies here too: if a finding is another occurrence of a pattern already in
that file, add it there as evidence. The pattern is worth more than the individual fix.

---

*Phase 2 has not run yet. The entry below was filed during phase 1, by `issue-qa` at an
issue close, under the third option in its brief: not certain enough to reject, not certain
enough to wave through silently.*

## F1 — the "all seven tables exist" test reads drift's declared tables, not the database   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/test/database/app_database_test.dart`, the `FEAT01: all seven tables exist` test
**Violates:** nothing stated. It is the shape `lessons.md` §5 describes — a check whose subject
is not quite the thing it is named for.
**What it is:** the test asserts over `database.allTables`, which is generated from the
`@DriftDatabase(tables: [...])` annotation and never touches SQLite. It does catch the failure
that can realistically happen — a table declared but left out of the annotation — and a
sibling test does query real SQL, so the schema is proven to be created. But the assertion as
named ("the tables exist") would hold even if nothing had been created, and it is the pattern
that has produced four green-for-the-wrong-reason results on this project. `sqlite_master`
would answer the question the name asks.
**Confidence:** worth checking — whether this matters depends on what the rest of the suite
looks like once DAO tests exist, which is not visible from one issue's diff.

*F2 and F3 were filed at `UC13-categories`' close, by `issue-qa`, for the same reason as F1
— and because `issue-qa` may not edit a `.drawio` itself.*

## F2 — `seq-uc13-categories.drawio` does not draw the read path the code has   [FIXED]
**Scope:** TRAIL          **Severity:** defect
**Where:** `docs/diagrams/seq-uc13-categories.drawio` (and its render at
`pm/issues/uc13-categories/seq-uc13-categories.png`)
**Violates:** `CLAUDE.md` close-checklist step 1 (the as-built reconcile) — a sequence
diagram that disagrees with the code it specifies.
**What it is:** messages 2, 8, 14 and 23 all show `categoryTreeProvider` emitting the tree,
but the diagram carries **no `categoryTreeProvider → CategoryDao.watchTree()` message and no
`CategoryDao ⇄ AppDatabase` query pair** — the four messages `seq-uc14-choose-currency`
draws for the identical chain. The code built that path (authorised by the plan, which cites
`class-transactions.drawio`'s `categoryTreeProvider → CategoryDao` edge and records the gap
rather than filling it silently). The code is right and the diagram is incomplete, so the
**diagram** is what needs to change: four messages added, re-exported to PNG, the render
**looked at** (`lessons.md` §3), and `pm/issues/uc13-categories/seq-uc13-categories.png` plus
`renders.lock` refreshed. `issue-qa` did not do it because sequence diagrams are authored as
Mermaid and converted by `diagram-drawio-author`, never as hand-written XML
(`sequence-conventions.md`), and because a reviewer that repairs what it reviews has stopped
being a reviewer. **Dispatch `diagram-drawio-author`.**
**Confidence:** certain — verified by extracting every label from the file at close; the six
lifelines and twenty-three messages are as the plan describes and the read path is absent.
**FIXED 2026-08-22**, in the main session rather than by `diagram-drawio-author` — the owner
directed mid-run that diagram work and QA stop going to subagents. Re-authored in Mermaid and
converted with the draw.io CLI per `sequence-conventions.md`; **not** hand-edited XML. The
read path is now **five** messages, not the four this entry predicted: `seq-uc14` also draws
`Screen → provider: watch()`, which the first draft omitted, so matching that chain honestly
needed the fifth. All twenty-three original messages and both fragment guards survive
unchanged; the diagram now numbers 1–28. The isolate note on **this** diagram was corrected
in the same pass (F3's scope drops from fourteen copies to thirteen). Render re-exported,
`grep -c '<!--'` = 0, `audit.py` 13/0/0, `renders.lock` refreshed via
`audit.py --record-renders`. **The PNG was looked at** at full-diagram zoom and at two tight
crops: the `opt` box's top border was checked to fall *below* message 13 rather than
enclosing it, and the note was checked pixel-wise at the right margin for clipping — the last
two pixel columns are blank, so it is complete.

## F3 — every sequence diagram's isolate note names a mechanism one wrapper stale   [OPEN]
**Scope:** TRAIL          **Severity:** risk
**Where:** twelve of the fourteen `docs/diagrams/seq-uc*.drawio` — the note reading *"DAO to
AppDatabase crosses the isolate boundary (NativeDatabase.createInBackground, 2026-08-20)"*
**Violates:** nothing stated; it is `lessons.md` §1's half-true label, in fourteen copies.
**What it is:** the code opens the database through `drift_flutter`'s `driftDatabase()`,
which calls `NativeDatabase.createBackgroundConnection` (`decisions.md` 2026-08-21, FEAT01
ruling 2, checked in the package source). **The boundary the note marks is real, is in the
right place, and the guarantee is unchanged** — only the mechanism's name is stale. Both the
UC-13 and UC-14 plans recorded it against their own diagram before noticing it is on all
fourteen, i.e. it is a repo-wide nit and not one issue's defect. Fixing it inside UC-13
would have meant editing thirteen diagrams UC-13 does not own, so it is filed instead.
**Confidence:** certain — `grep -rl createInBackground docs/diagrams/` returned all fourteen
when this was filed.
**Narrowed again 2026-08-22:** `seq-uc11-set-budget.drawio` corrected in UC-11's as-built
pass. **Twelve remain.**
**Narrowed 2026-08-22:** `seq-uc13-categories.drawio` was corrected as part of F2's as-built
pass, because UC-13 owns that diagram. **Thirteen remain**, and they stay filed rather than
fixed — the run does not repair findings, and each belongs to an issue that has not been
built yet, so each will be corrected by its own as-built pass at close. Anything still stale
when the backlog finishes is a real leftover; anything fixed before then costs nothing.

## F4 — the NFR-4 enabled-controls test can pass vacuously for the rename control   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/test/transactions/category_manager_screen_test.dart`, the `NFR-4: add, rename
and delete stay enabled…` test
**Violates:** nothing stated. It is the `lessons.md` §5 shape — a check that would stay green
if its subject vanished.
**What it is:** the test collects finders and asserts `onPressed` is non-null for each
matched element. Two of the three finders cannot be empty — `find.…(Icons.add).last` throws
on an empty match, and the delete finder is tapped with `.first` immediately afterwards, and
the delete is then proven by the row disappearing from the re-rendered tree, which is a real
end-to-end assertion. But the **edit** finder is only iterated: if the rename buttons ever
stopped rendering, that loop would run zero times and the test would still pass while its
name still claimed rename stays enabled. Not wrong today — the controls are all present and
the D7 test independently proves the subcategory row renders — so it is recorded rather than
sent back. A `findsNWidgets` count before the loop closes it.
**Confidence:** worth checking — whether it matters depends on how the other screens' NFR-4
tests end up written, which one issue's diff cannot show.

## F5 — the workbook has nowhere to mark a use case implemented   [OPEN]
**Scope:** TRAIL          **Severity:** risk
**Where:** `docs/workbook.xlsx`, sheet `UC FR` — columns are `Kode`, `Nama Use Case`, `User`,
`Modul`, `Input`, `Deskripsi`, `Output`, `Entity/Objek Terkait`
**Violates:** `context/general-rules.md`, Definition of "done" step 4 — *"the corresponding
workbook row marked as implemented, if the issue traces back to a UC."*
**What it is:** `UC13-categories` is the first issue on this project that traces to a UC and
reaches DONE, so step 4 applied for the first time — and there is **no column to write it
in**, nor any rule for one in `workbook-conventions.md`. `issue-qa` did not invent one:
adding a column to a client-facing workbook is a schema change that belongs to
`workbook-xlsx-author`, and `audit.py` asserts that sheet's shape. The consequence today is
mild (the tracker is the real implementation register and it is accurate) but it means a
step in the definition of done cannot be performed as written, and a step that silently
cannot be done is the shape `lessons.md` §5 warns about. Either add the column and a
convention for it, or amend step 4 to name the tracker — **one of the two, not neither.**
**Confidence:** certain that the column is absent; the right resolution is the owner's.

## F6 — the note on a Mermaid-generated sequence diagram overflows its own box   [FIXED]
**Scope:** TRAIL          **Severity:** defect
**Where:** `seq-uc13-categories.drawio` and `seq-uc11-set-budget.drawio` renders
**Violates:** `lessons.md` §3 — a render defect is only ever found by looking at the render.
**What it is:** a single-line `note over` whose text is long enough runs **past the right
edge of its own yellow rectangle** — the closing characters render outside the fill, on
white. Both isolate notes did this. It is a Mermaid layout quirk: the box is sized slightly
narrower than the text it holds.
**How it was found, and the check that missed it first:** the UC-13 render was checked at
close for *canvas clipping* — whether the rightmost pixel columns were blank — and passed,
because the text ends inside the canvas. That check was looking at the wrong set: nothing
was clipped, but the text had still escaped its container. It surfaced only when the same
note was drawn wider on UC-11 and looked at up close. **This is `lessons.md` §5 in a render
check rather than in a script** — a check that passes for the wrong reason. Added there as
evidence.
**Fixed 2026-08-22** on both diagrams by splitting each note across two lines with `<br/>`,
re-exporting, and re-checking by counting dark pixels to the right of the note's fill
rather than at the canvas edge: 0 on both.
**Confidence:** certain — measured, not eyeballed.

## F7 — a non-numeric budget amount is silently saved as zero   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/lib/src/budgeting/set_budget_screen.dart`, the save button's
`int.tryParse(_controller.text) ?? 0`
**Violates:** nothing stated. NFR-4 requires the save to proceed rather than refuse, and it
does — this is about *what* it proceeds to.
**What it is:** typing anything unparseable and pressing save writes a budget of **0**, with
no indication that the typed value was discarded. Zero is a legitimate budget, so nothing
downstream can tell an intended zero from a discarded "abc", and FR-15 will then pre-fill
next month from it. Refusing the save is not available (NFR-4's fit criterion is zero
refusals), so the question is which non-refusing behaviour is wanted — keep the previous
amount, treat empty as "no budget set" and delete the row, or write the zero and say so.
**That is the owner's call**, which is why this is filed rather than fixed.
**Confidence:** certain that it happens; worth checking whether it matters, since the same
parse will be needed by every amount field UC-04 introduces.
