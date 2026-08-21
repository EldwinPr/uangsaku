# General Rules

Stable, rarely-edited conventions that apply regardless of task type. Lessons-learned get written directly into whichever `context/document-writer-only/*.md` conventions doc they concern (or here, if the lesson is cross-cutting and not about a specific diagram/artifact type) as part of finishing the task that surfaced them — not staged in a separate gotchas file first. A prior version of this project kept a standalone `gotchas.md`; in practice every entry there ended up duplicated into the relevant conventions doc anyway, so the staging step was dropped and the file emptied. Distilled from a prior project's `conventions.md` and `pm-system.md`, keeping only what isn't tied to a specific framework.

**Current scope**: this project is documentation-only right now (Phase 1 — BPMN, ERD, workbook, class/component/state diagrams, elicitation). No stack has been chosen and no code exists yet — `coding-conventions/` and coding-phase guides don't exist yet either; they'll be added when the project actually reaches implementation, not before.

## Naming: domain language

Domain/business terms — model names, field names, UI labels — match whatever language the client and the source documents (elicitation notes, workbook, BPMN diagrams) actually use. Pick one language per project at the start and record it here; don't translate domain terms mid-pipeline — a field named after the client's own term in the BPMN/workbook should keep that exact name in the schema, not get silently translated or normalized.

**This project: English.** Decided by the owner 2026-08-19, before any term
propagated past `docs/fr-nfr.md`. The reason is provenance, not preference —
the owner's own verbatim statements in `input/2026-08-19-owner-scope-conversation/`
and every requirement derived from them are already in English, so the rule
above ("match whatever language the source documents actually use") picks
English on its own. Use case names, entity names, and field names are English:
`Account`, `Transaction`, `Category`, `Subcategory`, `Budget`.

The Indonesian column headers in `docs/workbook.xlsx` (`Kode`, `Nama Use Case`,
`Entity yang dibutuhkan`) are **not** an exception to this. They are the
workbook template's own structure — the names of the pipeline's artifacts, not
domain terms — and they stay as they are. The rule governs what goes *in* the
cells, not what the columns are called.

Structural/technical terms (class names, framework conventions, code-level scaffolding) follow whatever the chosen stack's own convention is — that's `coding-conventions/` territory, not this file.

## Planning gate

A `plan.md` must exist under `pm/issues/{id}-{slug}/` and be reviewed/confirmed by the user before work starts on that issue — a documentation issue (drafting a diagram, filling the workbook) or, once this project reaches implementation, a code change. Don't bypass the plan to make a quick fix — if the fix changes what was planned, update `plan.md` first, then do the work against the updated plan. This keeps `plan.md` the actual source of truth instead of drifting from what was really done.

**Unattended mode** (added 2026-08-21, owner's call — see `context/index/decisions.md`).
During an unattended run the `feat-planner` agent may mark a plan `AUTO-CONFIRMED` and
`flutter-coder` may act on it, **but only when every decision in that plan derives from an
artifact the owner has already confirmed** — a stated FR, the sequence diagram, a class
diagram, `decisions.md`, or `enums.md`. Each D-entry must cite the artifact it comes from.

If a plan needs a decision that cannot be cited, the issue **halts** and the question goes
to `pm/questions.md`. Halting is per-issue: the run continues on any issue whose
dependencies are still satisfied.

This narrows the gate rather than removing it. Its purpose is *don't build on unconfirmed
assumptions*, and the test becomes "does this plan contain anything the owner has not
already approved" instead of "did a human sign it" — the question the signature was
standing in for, and the only one of the two that can be checked. **A citation that cannot
be written is the signal that the decision is new.** When the owner is present, the gate is
unchanged.

## Definition of "done"

An issue is not done until all of the following happened, in order:

1. Verification passed — for a documentation issue, that means the diagram/sheet/doc was actually reviewed against its relevant `context/document-writer-only/*.md` convention and (where the convention requires it, e.g. BPMN to-be, state diagrams) confirmed with the client. Once this project has code, this step also covers the stack's test suite and linter/formatter — that part doesn't apply yet.
2. `pm/issues/{id}-{slug}/plan.md` status updated to `done`.
3. `pm/tracker.yaml` row updated to done, with a short summary.
4. The corresponding workbook row (`docs/workbook.xlsx`, whichever UC sheet owns it — `UC FR` / `UC Non-FR` on this project) marked as implemented, if the issue traces back to a UC.
5. `pm/log.md` gets an appended entry — what was asked, what was done, files touched — not just a status flip. Append-only, don't rewrite past entries.
6. `pm/active.json` moves to the next issue.

Skipping straight to step 6 (moving on without the trail) is what makes old work unreconstructable later — don't do it even under time pressure.

## Terminology rule

When a diagram/document concept has multiple competing informal definitions across sources (e.g. "BPMN Level 0" meaning either a single context diagram or a full landscape depending on source), don't invent our own definition — find the version used by a recognized practitioner standard closest to our context (SAP/Signavio for process architecture, since ERP clients are more likely to have encountered that vocabulary than an academic alternative) and cite it explicitly in the relevant conventions file. This keeps our terminology defensible/citable to a client or reviewer, rather than internally consistent but unrecognizable outside this repo.

## Working discipline

Cross-cutting lessons about *how to work in this repo*, distinct from the artifact-specific
conventions in `document-writer-only/`. Each one is here because it actually went wrong.

**A new rule must reproduce the existing worked example before it may claim to replace or
generalise an older one.** The examples in `document-writer-only/examples/` are the regression
suite for the conventions, not decoration. Adding an abstraction and asserting that an existing
rule is "a specialisation" of it is a claim with a cheap test: run the new rule against the
worked example and check it yields the same output. This was skipped once — an added use-case
"admission test" was declared a generalisation of the one-UC-per-User-task rule, when the two
in fact do opposite things, and the restaurant demo (5 User tasks → 5 UCs) would have falsified
the claim immediately.

**An explicit written rule outranks in-the-moment reasoning.** When analysis points somewhere
other than what a conventions file already says, the written rule wins by default: state the
tension, propose the change, and let the user decide. Don't silently apply the better-seeming
answer, and don't defend it after the fact — a framework whose rules bend to whoever is holding
it produces different answers on different days, which is the one thing it exists to prevent.

**Walk every branch of a process model to a terminal state before calling it done.** For each
path, including every failure branch, ask what the actor does next. A branch that stops with no
continuation, a decision whose input is never produced, or a step that proceeds regardless of a
result it was supposed to depend on are all modelling bugs and all invisible if only the happy
path is read. Three separate rounds of correction on the movie-booking BPMN were exactly this
class of error, not notation errors.

**A surprising derivation result means "check the rule" first, "check the input" second.** When
a pipeline yields far less (or more) than expected, the first hypothesis is that the rule being
applied is wrong; the scope of the input is the second. Reaching for the input explanation first
turns into defending a broken rule.

**Read the reference material before recommending an architecture, not after.** A recommendation
assembled from memory and then checked is a recommendation that has already anchored. In this
repo that means the relevant `document-writer-only/*.md` and the example files before drafting a
diagram — and, for anything touching an external tool or API, that tool's own current reference
before proposing a design around it.

**In a design conversation, recommend in prose.** Working through a design with the user is
discussion, not a form: give the recommendation and the reasoning as text and let them react.
Reserve structured multiple-choice prompts for a genuine fork where work cannot continue. Equally
— when the user restates their framing a second time, stop re-deriving it and build on their
version; continued "correcting" of a model they have already explained twice is not analysis.

## Two kinds of documentation, kept separate

- **Project management** (`pm/`) — what's active, what's done, what's next. Append/status-only; doesn't explain *how* the system works, only *what happened*.
- **Context** (`context/`) — durable knowledge about the system itself: conventions, where things live, why decisions were made. Updated as the system evolves, not tied to any one issue.

When an issue's implementation surfaces a new durable fact (a schema change, a new resource, an RBAC change), update the *context* file as part of closing the issue (e.g. `context/index/map.yaml` gets a new entry) — don't leave it only in the issue's `plan.md`/`pm/log.md`, since those record the one-time event, not the resulting permanent state.
