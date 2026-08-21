# bpmn-to-erp

A documentation pipeline for taking an ERP project from **client elicitation → BPMN →
use cases → data/behaviour models**, with enough process scaffolding around it that the
trail from "a stakeholder said this" to "this artifact exists" stays reconstructable
months later.

The repo is currently **Phase 1: documentation only**. No stack has been chosen and no
application code exists. Everything here is either a convention doc, a worked example,
or project-management state.

## What this repo actually contains

| Path | What it is |
|---|---|
| `CLAUDE.md` | The procedure manual — hard gates, forbidden patterns, the issue-close checklist. |
| `context/RULES.md` | Session entry point: what to read first, in what order. |
| `context/general-rules.md` | Cross-cutting conventions (naming, planning gate, definition of done). |
| `context/document-writer-only/` | Per-artifact conventions: BPMN, ERD, class, state, workbook, plus the cross-cutting draw.io guide. |
| `context/document-writer-only/examples/` | Verified worked examples + `elements.drawio`, the living shape palette. |
| `context/guide/` | Component-diagram conventions; cross-model review workflow. |
| `context/index/` | `map.yaml` (UC/FEAT → code) and `decisions.md` (durable architectural decisions). |
| `context/files/` | Published third-party specs the conventions are distilled from (OMG BPMN, UML). |
| `input/` | Raw client source material, one folder per intake event. The substrate everything else derives from. |
| `docs/` | The real client deliverables: `workbook.xlsx`, `fr-nfr.md`, `requests.md`, `enums.md`, `statuses.md`, and `diagrams/`. |
| `pm/` | Project state: `tracker.yaml` (the board), `active.json` (current issue), `log.md` (append-only history). |
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

Delegate rather than hand-authoring; each one already knows which conventions to load.

| Agent | Use for |
|---|---|
| `bpmn-drawio-author` | BPMN diagrams |
| `diagram-drawio-author` | Every other `.drawio`: ERD, class, state, component |
| `workbook-xlsx-author` | Deriving UCs, promoting requests, refreshing the Entities dedup |

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

1. Reconcile the sequence diagram against what was actually built (as-built pass).
2. `context/index/map.yaml` — add the UC/FEAT → code entry.
3. `context/index/decisions.md` — record anything durable decided along the way.
4. `pm/tracker.yaml` — status Done + one-line summary.
5. `pm/log.md` — append a dated entry, tagged `[STATUS]`/`[DECISION]`/`[DISCOVERY]`/`[TODO]`.
6. `pm/active.json` — point at the next issue, or clear it.

Skipping to step 6 is what makes old work unreconstructable. Don't.

## Current state

The conventions layer and the agent/skill tooling are built and validated against worked
examples (a retail store modeled Level 1→3, a food-stand collaboration diagram, a restaurant
BPMN + ERD + class diagrams + workbook). The client-facing artifacts are still scaffolding:
`docs/workbook.xlsx` holds headers only, and `pm/tracker.yaml`, `pm/active.json`, `pm/log.md`,
`context/index/*` are empty — no real issue has been run through the pipeline yet.
#   u a n g s a k u  
 