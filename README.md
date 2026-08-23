# bpmn-to-erp

A documentation pipeline for taking a project from **client elicitation → BPMN → use
cases → data/behaviour models → working implementation**, with enough process
scaffolding around it that the trail from "a stakeholder said this" to "this artifact
exists" stays reconstructable months later.

Phase 1 (documentation) and Phase 2 (implementation) are both complete: the pipeline
produced a real app, **`uangsaku`**, a personal balance-sheet tracker in Flutter/Dart —
see [Current state](#current-state) below. Everything else here is either a convention
doc, a worked example, or project-management state describing how it got built.

## What this repo actually contains

| Path | What it is |
|---|---|
| `CLAUDE.md` | The procedure manual — hard gates, forbidden patterns, the issue-close checklist. |
| `context/RULES.md` | Session entry point: what to read first, in what order. |
| `context/general-rules.md` | Cross-cutting conventions (naming, planning gate, definition of done). |
| `context/document-writer-only/` | Per-artifact conventions: BPMN, ERD, class, state, workbook, plus the cross-cutting draw.io guide. |
| `context/document-writer-only/examples/` | Verified worked examples + `elements.drawio`, the living shape palette. |
| `context/guide/` | Component-diagram conventions; cross-model review workflow. |
| `context/index/` | `map.yaml` (UC/FEAT → code), `decisions.md` (durable architectural decisions), and `lessons.md` (the failure patterns this project has hit more than once). |
| `context/files/` | Published third-party specs the conventions are distilled from (OMG BPMN, UML). |
| `input/` | Raw client source material, one folder per intake event. The substrate everything else derives from. |
| `docs/` | The real client deliverables: `workbook.xlsx`, `fr-nfr.md`, `requests.md`, `enums.md`, `statuses.md`, and `diagrams/`. |
| `pm/` | Project state: `tracker.yaml` (the board), `active.json` (current issue), `log.md` (current state + append-only history), `log-archive-2026-08.md` (sessions 1-15 verbatim), `questions.md` (the unattended run's halt queue), `findings.md` (the repo-wide sweep's output — recorded, not auto-fixed). |
| `app/` | The Flutter app itself — `uangsaku`. `drift`/SQLite + Riverpod, `app/lib/src/{accounts,transactions,budgeting,settings}/` one folder per module. See `app/README.md`. |
| `audit.py` | The documentation consistency check (`context/index/map.yaml`, the workbook, the tracker, every sequence render) — CI's `docs` job runs it. Proves the artifacts agree with each other, not that any of them is right. |
| `.claude/agents/` | Specialist subagents for the artifacts that have repeatable, error-prone rules. |
| `.claude/skills/` | Tooling skills (`drawio`, `xlsx`, `doc-coauthoring`). |

## The pipeline

```
input/  ── raw client material: photos, scans, exports, emails, transcripts
      │        (append-only; never worked from directly)
      │
      ├─→ as-is BPMN ──→ gap discussion with client ──→ to-be BPMN (confirmed)
      │                                                        │
      │                                                        ▼
      │                                            docs/workbook.xlsx "UC BPMN" / "UC FR"
docs/requests.md ──(promotion, once confirmed)──→   docs/workbook.xlsx "UC Non-BPMN" / "UC Non-FR"
                                                             │
                                                             ▼
                                                    "Entities" sheet (deduped)
                                                             │
                                                             ▼
                                              ERD · class · state · component diagrams
                                                             │
                                                             ▼
                                        pm/tracker.yaml issue → plan.md → work → close
```

### The input layer

Requirements arrive in one of three already-formalised shapes — a **BPMN** process model, a
written **FR** list, or a raw **stakeholder request**. `input/` sits underneath all three: it is
the unclassified material they were formalised *from*, and it exists to make one guarantee hold —
**every downstream artifact can name the thing that justified it.**

Without it, the first arrow above has no artifact behind it, and the only surviving record of why
a rule exists is the rule itself. The failure is quiet: a diagram says the seat hold is ten
minutes, nobody can find who said ten, and a year later it gets re-decided from memory.

The discipline that keeps it from becoming a junk drawer is small:

- One folder per **intake event** (`input/YYYY-MM-DD-<slug>/`), grouped by when and from whom —
  never by file type.
- Every folder carries a `notes.md` recording source, date, contents, and what was extracted.
  Its `## Extracted` list doubles as the queue: **empty means not yet mined.**
- Append-only. A correction is a new intake event that supersedes the old one — the layer records
  what was actually said, including what later turned out to be wrong.
- Never worked from directly; material is extracted into `docs/requests.md` (or a BPMN, or an FR
  list) and classified there first.

Client material and published standards are kept apart on provenance: `input/` is what the client
gave us, `context/files/` is what a standards body published (the OMG BPMN and UML specs the
conventions are distilled from). Full rules in `input/README.md` and `context/files/README.md`.

### BPMN levels

This project uses a deliberate 3-level simplification (documented and cited in
`context/document-writer-only/bpmn-conventions.md`):

- **Level 1** — landscape + value chain in one diagram: one Pool, lanes for
  Managerial / Main / Supporting, every box a collapsed sub-process, no connecting arrows.
- **Level 2** — one diagram per Level-1 box, decomposing that box only.
- **Level 3+** — full operational BPMN. Same rule recursing: one diagram decomposes exactly
  one parent box, never several.

Say **"Level"**, not "Tier". Don't decompose a box that isn't complex enough to earn it.

### Use case derivation

One workbook row per **User task** — the point where a human looks at a screen. Service /
Business Rule / Send / Receive tasks that fire automatically off that user action fold into
the same UC's description as sub-steps. Manual tasks (no system involvement at all) never
become use cases. Full rule and the worked correction that produced it:
`context/document-writer-only/workbook-conventions.md`.

## Hard gates

These are non-negotiable and live in `CLAUDE.md`:

- No work starts before a `plan.md` exists for the active issue **and** the user has confirmed it.
  During an unattended run, `AUTO-CONFIRMED` substitutes — but only for a plan whose every
  decision cites an artifact the owner already approved. Anything else halts that issue and
  queues the question in `pm/questions.md`. The test is *"does this plan contain anything the
  owner has not already approved"*, which is the question a human signature was standing in
  for and the only one of the two that can be checked.
- A plan's scope *is* its sequence diagram — nothing outside it is in scope, nothing in it gets
  silently skipped.
- Every use case has an owning workbook row before it becomes a tracked issue.
- `docs/requests.md` is append-only capture, never a task queue — promote to the workbook first.
- `input/` is never worked from directly — extract and classify into `requests.md` (or a BPMN, or
  an FR list) first. Same rule, one layer earlier.
- A cited source must exist. If a conventions file or diagram cites a source document, that
  document — or a stub naming it and where it lives — is present in `input/` or `context/files/`.
- Preflight before implementation: declared dependencies Done in `pm/tracker.yaml`, no scope
  overlap with another active issue.

## Working on a `.drawio` file

The mandatory loop, every time, no exceptions (`context/document-writer-only/drawio-general-guide.md`):

1. Author/edit the XML.
2. Validate well-formedness:
   `python -c "import xml.dom.minidom as m; m.parse('PATH')"`
3. `grep -c '<!--' file.drawio` — XML comments are forbidden here and validation won't catch them.
4. Export and **actually look at the render**:
   `"C:\Program Files\draw.io\draw.io.exe" -x -f png -o out.png file.drawio`
5. Crop tight on any crowded region and re-inspect.
6. Fix and re-export until clean; delete throwaway PNGs.

Every non-trivial diagram built here so far needed at least one fix that was invisible from
reading the XML. Style strings come from `examples/elements.drawio` — this project's installed
shape library has repeatedly diverged from spec-plausible attribute names (gateway type is
`gwType=`, not `symbol=exclusiveGw`), and guessing has produced blank or wrong renders every
single time it was tried instead of checked.

## Subagents

Specialist agents exist for the artifacts that have repeatable, error-prone rules
(`bpmn-drawio-author`, `diagram-drawio-author`, `workbook-xlsx-author`, `feat-planner`,
`issue-qa`, `repo-qa`), and `.claude/agents/` still defines all of them. **In practice,
during the implementation run, only `flutter-coder` was actually dispatched** — the
owner directed mid-run (2026-08-22, then again 2026-08-23) that diagram authoring, QA,
review-and-close, and finally planning itself all move into the main orchestrator
session instead of being delegated, after background agents twice died on a session
limit. `context/guide/orchestration.md` still describes the original three-agent-split
design and is left as-is on the record (`pm/findings.md` F12) rather than rewritten,
because the shape it describes is not wrong, only superseded — `CLAUDE.md` and
`.claude/commands/start-dev-pipeline.md` carry the current instruction and win where the
two disagree.

| Agent | Use for | Actually dispatched this run? |
|---|---|---|
| `flutter-coder` | Dart/Flutter code under `app/` — never without a confirmed plan, never commits | **Yes** — every implementation issue |
| `feat-planner` | Writing and revising an issue's `plan.md` — never code | No — planning moved in-session |
| `bpmn-drawio-author` / `diagram-drawio-author` | Authoring `.drawio` files | No — diagram work moved in-session |
| `issue-qa` / `repo-qa` | Reviewing, closing, and the final repo-wide sweep | No — QA and the sweep moved in-session |
| `workbook-xlsx-author` | Deriving UCs, promoting requests, refreshing the Entities dedup | No — not needed once Phase 1 closed |

The planning gate itself is unchanged regardless of who does the work: no code before a
`plan.md` exists and is confirmed, a plan's scope is its sequence diagram, and closing an
issue means running the real four commands, not trusting a report.

**`/start-dev-pipeline`** starts the loop: select → plan → dispatch `flutter-coder` →
verify & close, all in the main session except the code itself. It runs in two phases —
the issue loop, then a repo-wide sweep — and **stops at findings.** Nothing found in the
sweep is fixed by the run, because a cross-cutting finding usually needs a decision only
the owner can make, and a run that repairs its own findings can loop indefinitely with
each pass generating the next. The sweep re-runs whenever more issues close after it —
this project's sweep ran three times across one implementation run.

## Environment notes

- **draw.io Desktop**: `C:\Program Files\draw.io\draw.io.exe`. CLI export prints
  `Unable to move the cache` / `Gpu Cache Creation failed` to stderr — harmless Electron noise,
  check the output file, not the log lines.
- **Workbook editing**: `openpyxl`. No live formulas — Google Sheets' `UNIQUE`/`ARRAYFORMULA`/
  `QUERY`/`FLATTEN` don't survive the `.xlsx` round trip, so the Entities dedup is refreshed
  manually or by script.
- **`ws.max_row` goes stale across separate save/reload cycles.** This has silently clobbered
  rows and blanked a header three separate times. Always reload and print the sheet after
  writing; clear an oversized range and `delete_rows()` down; rewrite headers last.
- **LibreOffice is not usable here** (`AF_UNIX` missing on this Windows Python build) — so the
  `xlsx` skill's `recalc.py` won't run. Don't assume it's available for adjacent tooling either.
- **`gh` is not authenticated in this environment.** For public-repo CI status without it,
  `curl -s "https://api.github.com/repos/<owner>/<repo>/actions/runs?per_page=N"` works
  unauthenticated; job-level detail via `.../jobs`; but the raw log-download endpoint
  refuses without repo-admin rights even on a public repo, and the web UI is a login wall
  for the same content. When a CI failure won't reproduce locally, the fastest path is
  asking whoever has the browser open to paste the failing step's output — see `pm/log.md`
  2026-08-24 for a case where four commits' worth of local reproduction (including a real
  Linux checkout via WSL, same package versions as CI) still didn't surface the bug, and
  the actual log did in one read.
- **WSL2 (`wsl -d Ubuntu`) is available for reproducing CI's Linux environment**, but its
  system Python has no `pip`/`ensurepip` (Debian's split packaging) and no passwordless
  `sudo`. Bootstrap without either: `python3 -m venv --without-pip .venv`, then
  `.venv/bin/python get-pip.py` (fetched via `curl`) to get `pip` inside the venv, then
  `.venv/bin/pip install <package>`. Clone the repo into WSL's native filesystem
  (`~/somewhere`, not `/mnt/c/...`) for a real ext4 checkout — `/mnt/c` is still NTFS
  underneath and won't reproduce filesystem-order-dependent bugs.

## Conventions worth knowing before you touch anything

- **Domain language follows the client.** Terms from elicitation notes, the workbook, and the
  BPMN diagrams keep their exact spelling downstream — no silent translation or normalization
  mid-pipeline. (The workbook's column headers are Indonesian for this reason.)
- **Contested terminology gets borrowed, not invented.** Where sources disagree on a concept,
  adopt the practitioner standard closest to our context (SAP/Signavio for process architecture)
  and cite it in the relevant conventions file — defensible to a reviewer beats internally tidy.
- **Lessons learned go straight into the relevant conventions doc** as part of finishing the task
  that surfaced them. There's no staging file; a previous `gotchas.md` was emptied because every
  entry ended up duplicated into a conventions doc anyway.
- **`pm/` records what happened; `context/` records what is true.** Durable facts belong in
  `context/`, not buried in an issue's `plan.md`.
- **Demo vs. real work.** Framework tests and demos live entirely under
  `context/document-writer-only/examples/` and never touch `docs/workbook.xlsx`,
  `docs/requests.md`, or `pm/`. If it's unclear which one a request is, ask first.

## Closing an issue

Run by the main session now, not a dispatched `issue-qa` (see Subagents above) — but the
checklist itself is unchanged:

1. Re-run the four commands (`build_runner`, `dart format`, `flutter analyze`,
   `flutter test`) — a coder's report of passing is not evidence of passing.
2. Read the full diff against the plan and its Out-of-scope list.
3. Reconcile the sequence diagram against what was actually built (as-built pass) —
   export to PNG and look at the render.
4. `context/index/map.yaml` — add the UC/FEAT → code entry.
5. `context/index/decisions.md` — record anything durable decided along the way.
6. `pm/tracker.yaml` — status Done + one-line summary.
7. `pm/log.md` — append a dated entry, tagged `[STATUS]`/`[DECISION]`/`[DISCOVERY]`/`[TODO]`.
8. `pm/active.json` — point at the next issue, or clear it.
9. Commit and push.

Skipping to step 8 is what makes old work unreconstructable. Don't.

## Current state

*Updated 2026-08-24.*

**Both phases are complete.** Phase 1 (documentation) closed on 2026-08-21: the ERD,
four class diagrams, the component diagram, `enums.md`, the currency decision, sequence
conventions, `context/coding-conventions/`, and all fourteen per-use-case sequence
diagrams, every one rendered and visually verified.

Phase 2 (implementation) is now also complete — **every tracker issue is DONE**, 22 of
22, including one issue added mid-run by direct owner request. `python audit.py` is
green at 14/0/0 and runs in CI, alongside a Flutter `analyze`/`format`/`test` job; both
are currently green on `main`.

The app is **`uangsaku`**: a personal balance-sheet tracker in Flutter/Dart with `drift`
over SQLite and Riverpod, targeting Android and iOS, no backend. It lives in `app/` —
see `app/README.md` for what's actually there. **128 tests pass**, headless
(`flutter test`); nothing in this environment can launch an emulator or a device build
(no Android SDK, no Mac), so that test count is the verification surface here, not a
substitute for actually running it.

**What it does.** Track accounts — wallets, debts owed to you, debts you owe — record six
kinds of money movement through one form (expense, income, transfer, lend, borrow,
repayment), correct a wrong balance after the fact, rename/regroup/soft-delete an
account, review and amend or delete anything you recorded, set a monthly budget per
group and watch it drain as you spend. Every screen is reachable from a bottom
navigation bar (`AppShell`, `app/lib/src/app.dart`) plus in-context taps — an account row
opens edit, a debt account gets a details icon, budget/category/currency settings sit
behind app-bar actions. Navigation was added last, by direct owner request, once
everything else was built and there was finally something to click through.

**What's still open, by design, not oversight.** `pm/findings.md` carries eight standing
findings that need an owner ruling rather than a code fix — the one worth reading first
is a non-numeric amount silently saving as zero on four screens. Two things were left
deliberately unbuilt: undeleting a soft-deleted account, and a dedicated entry point into
the balance-correction flow from the new navigation shell — neither was ever asked for.
None of it blocks anything; the backlog that was planned is finished.

The head of `pm/log.md` carries the current state in one screen, with the full
session-by-session history underneath it.
