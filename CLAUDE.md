# CLAUDE.md

Pipeline rules for working in this repo. Read `context/RULES.md` first — it
tells you what to load. This file tells you what to *do*. `RULES.md` is the
entry point (session bootstrap: active issue, tracker, index); this file is
the procedure manual it hands off to — hard gates, forbidden patterns, and
the close checklist below apply regardless of which issue you're on.

## Context — read only when relevant, not up front

- Drafting BPMN, use cases, or the workbook → `context/document-writer-only/*.md`
- Authoring or fixing a `.drawio` file → delegate to the matching dedicated
  agent — `bpmn-drawio-author` for BPMN, `diagram-drawio-author` for
  everything else (ERD, class, state, component). Each already knows to read
  `context/document-writer-only/drawio-general-guide.md` (cross-cutting
  workflow and gotchas — mandatory export-and-visually-verify discipline,
  z-order, overlap pitfalls) plus its own `*-conventions.md`,
  `context/document-writer-only/examples/` for verified worked examples, and
  `elements.drawio`, the living shape-style reference palette — check the
  palette before guessing a style string, and re-derive the conventions doc
  from it if they ever disagree.
- Editing `docs/workbook.xlsx` (deriving UCs from a BPMN, promoting a
  confirmed request, refreshing the Entities dedup) → delegate to the
  `workbook-xlsx-author` agent, or read
  `context/document-writer-only/workbook-conventions.md` directly for the
  UC-derivation rule and the `openpyxl` editing gotchas.
- Need a second opinion / independent audit → `context/guide/cross-model-review.md`
- Documenting how modules communicate → `context/guide/component-conventions.md`
- Learned something durable while doing a task → write it directly into the
  relevant `context/document-writer-only/*.md` (or `context/general-rules.md`
  if it's cross-cutting) as part of finishing that task — not into a separate
  staging file first.
- Client handed over raw material (photos, scans, exports, emails, transcripts) →
  file it under `input/<YYYY-MM-DD-slug>/` with a `notes.md`; read `input/README.md`
  for the intake rule. Published third-party specs go to `context/files/` instead —
  the split is provenance, not format.
- Just testing/demoing the framework itself, not real client work → keep
  every artifact under `context/document-writer-only/examples/` and never
  touch `docs/workbook.xlsx`, `docs/requests.md`, or `pm/` — those hold the
  real project's tracked state, not scratch space for a demo. If it's
  unclear whether a request is a framework test or real work, ask before
  writing to any of those.

## Hard gates — never skip these

- No code before `plan.md` exists for the active issue and is user-confirmed.
- No implementation starts before preflight passes: declared dependencies are
  Done in `pm/tracker.yaml`, and no scope overlap with another active issue.
- A `plan.md`'s scope IS whatever its sequence diagram shows — nothing outside
  the diagram is in scope for that issue, and nothing in the diagram gets
  skipped without going back to the user first.
- Every use case has an owning entry in `docs/workbook.xlsx` before it becomes
  a tracked issue — no issue gets created from a bare request that hasn't
  been promoted.
- `docs/requests.md` is append-only capture, never a task queue — don't work
  a request directly; promote it to the workbook first.
- `input/` is never worked from directly either — extract and classify raw
  material into `requests.md` (or a BPMN, or an FR list) before anything
  downstream reads it. Same rule as `requests.md`, one layer earlier.
- Don't cite a source document that isn't in `input/` or `context/files/`. If
  the file can't be committed, commit a stub naming it and where it lives — a
  citation nobody can open is a claim, not a citation, and the rule behind it
  ends up re-argued from memory.

## Forbidden patterns

- Don't hand-edit column A on the workbook's Entities sheet — it's a deduped
  list; if it's stale, refresh the source instead of typing into it.
- Don't invent a transition on a state diagram that wasn't stated as a
  business rule during elicitation — if you can't point to why, it doesn't
  go on the diagram.
- Don't reuse a `Kode` across the workbook — check both UC sheets before
  assigning a new one.
- Don't treat a Google Sheets formula as portable to `.xlsx` — `UNIQUE`,
  `ARRAYFORMULA`, `QUERY`, `FLATTEN` don't survive the round trip; see the
  comment on the Entities sheet before assuming it's live.
- Don't hand-derive a `.drawio` style string from memory or general BPMN
  knowledge when `context/document-writer-only/examples/elements.drawio`
  exists — this project's installed shape library has repeatedly diverged
  from spec-plausible attribute names (e.g. gateway type is `gwType=`, not
  `symbol=exclusiveGw`); guessing has produced wrong or blank renders every
  time it was tried instead of checked.
- Don't finish a `.drawio` change without exporting it to PNG and actually
  looking at the render — a diagram that "should" be right per the XML has
  repeatedly turned out to have overlapping shapes, labels sitting on top of
  connectors, or crossing Message Flows once actually rendered.
- Don't leave XML comments (`<!-- -->`) in a `.drawio` file — well-formedness
  validation doesn't catch them, and simply knowing the rule hasn't stopped
  it from happening twice already; `grep -c '<!--'` the file before calling
  it done (see `context/document-writer-only/drawio-general-guide.md`).

## Terminology rule

When a diagram/document concept has multiple competing informal definitions
across sources, don't invent our own — adopt the version used by the
practitioner standard closest to our context (e.g. SAP/Signavio's Level
0/1/2+ numbering for process landscapes) and cite it in the relevant
conventions file. Keeps terminology defensible to a client or reviewer
instead of internally consistent but unrecognized outside this repo. This
project also standardizes on **"Level"**, not "Tier" — say Level 1/2/3 in
diagram page names and conversation.

## Close checklist

When an issue closes:

1. Reconcile the sequence diagram against what was actually built (as-built
   pass) — same as-is/to-be discipline the BPMN docs already use.
2. Update `context/index/map.yaml` with the new UC/FEAT -> code entry.
3. Update `context/index/decisions.md` if anything durable/architectural was
   decided along the way that isn't captured elsewhere.
4. `pm/tracker.yaml` -> status Done + one-line summary.
5. `pm/log.md` -> append a dated entry, tagged [STATUS]/[DECISION]/
   [DISCOVERY]/[TODO] as appropriate.
6. `pm/active.json` -> point at the next issue, or clear it.
