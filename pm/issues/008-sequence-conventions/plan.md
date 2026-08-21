# ISSUE-008 — `sequence-conventions.md`

**Status:** DONE 2026-08-20. Written at the owner's direct instruction ("now can you get
informations on sequance diagram and write down the conventions?"), so the planning gate
was satisfied by the instruction rather than by a separate confirmation round; this plan
is the record of what was decided, written alongside the work rather than before it.
**Depends on:** ISSUE-002 (class diagrams — they fix the call chain every lifeline must
come from).
**Traces to:** no UC. Infrastructure for planning ISSUE-008..014.

*Renumbered from ISSUE-015 on 2026-08-20.* It was numbered 015 because ISSUE-008..014 were
the implementation backlog at the time; those rows were replaced by UC-coded ids the same
day, leaving 008..014 free and this issue stranded seven numbers out. Entries in `pm/log.md`
written before the renumber still say ISSUE-015 -- the log is append-only, so they stand,
and the renumber is recorded there as its own entry.

## Goal

`context/document-writer-only/sequence-conventions.md` — the last missing diagram-type
convention, and the one that gates planning any implementation issue, because `CLAUDE.md`
makes the sequence diagram the scope boundary of an implementation plan.

## Research done, and what it changed

- **Read all three worked examples** in `examples/movie-booking demo/` and rendered one to
  PNG. Style strings in the conventions file are taken from those files, not from memory.
- **Discovered they are Mermaid-generated**, not hand-authored: their XML carries
  `mermaidId` / `mermaidBaseStyle` / `mermaidBaseValue` attributes and `<UserObject>`
  wrappers. This decided D1 below.
- **Checked `examples/elements.drawio`** — it contains **no** sequence shapes at all, so
  the palette could not serve as the style reference here. Noted in the file; the palette
  should gain them (TODO below).
- **Verified the UML clause numbering** against secondary sources rather than asserting it,
  since the spec PDF is a stub: Clause 17 "Interactions", 17.2 Interactions, 17.3
  Lifelines, 17.4 Messages, 17.6 Fragments, 17.7 Interaction Uses. The file says plainly
  that these were confirmed indirectly and should be corrected by anyone holding the PDF.

## Decisions

### D1 — Authored as Mermaid, converted with the draw.io CLI

The only diagram type in this project not hand-written as XML. Layout *is* the work in a
sequence diagram, Mermaid's parser does it reliably, the three existing examples are
already Mermaid-generated, and `.claude/skills/drawio/SKILL.md` recommends exactly this.

**Accepted cost:** the Mermaid import brings its own palette (purple `#9370DB`, Trebuchet
MS, `light-dark()`), so sequence diagrams will not look like the plain black-on-white ERD,
class and component diagrams. Rejected the alternative of hand-fixing styles after each
conversion: the next regeneration undoes it, and a file that regenerates differently than
it is stored is worse than one that looks foreign.

### D2 — Every lifeline must be a class that already exists on a class diagram

The hard rule of the file. The class diagrams already fix the chain
`Screen → provider/Notifier → DAO → AppDatabase → table`, so a sequence diagram may not
invent a participant. If one is needed that isn't drawn, either the class diagram is
incomplete or the sequence is wrong — both are findings to raise, never to draw past.
This is what makes the two artifact sets check each other.

### D3 — Reads and writes are drawn asymmetrically

Taken from `class-accounts.drawio`'s own note. A write gets **no** reply arrow back to the
screen; the result arrives separately as a stream emission from the `StreamProvider`, drawn
as an asynchronous message. A diagram where every write has a tidy reply is the signature of
getting this wrong, and it would misrepresent the Riverpod/drift architecture as
request/response.

### D4 — Three combined-fragment operators only

`alt`, `opt`, `loop`. The other nine in the spec are listed as not used, with instructions to
add one here with a reason before drawing it. Also: **no `alt` operand may be a refusal** —
NFR-4's fit criterion is zero refusals, so that shape is a requirements violation rather than
a notation choice.

### D5 — One diagram per use case, not per issue

`seq-uc{NN}-{slug}.drawio`, matching the examples. An issue's scope is the union of its use
cases' diagrams. Keeps diagrams reusable when use cases are re-sliced across issues, which
has already happened once to this backlog.

## Also done

- `.claude/agents/diagram-drawio-author.md` — scope extended to sequence diagrams, with the
  Mermaid exception and a pointer to the two rules most easily got wrong (D2, D3).
- `audit.py` — `sequence-conventions.md` removed from `PLANNED_NOT_WRITTEN` (that set is a
  promise, not an exemption), `context/coding-conventions/` added in its place, and the
  illustrative filename in the file's CLI example added to `ALLOWED_DANGLING`.

## Out of scope

- Drawing any actual sequence diagram. The first are drawn when ISSUE-008 and ISSUE-009 are
  planned.
- `context/coding-conventions/` — the other prerequisite for planning ISSUE-008, still to do.
- Adding sequence shapes to `examples/elements.drawio` (TODO below).

## TODO left behind

- `examples/elements.drawio` has no sequence shapes. Lower priority than it looks, since
  Mermaid emits the styles rather than an author typing them, but the palette is supposed to
  be the reference and currently isn't for this type.
- The UML sub-clause numbers should be verified against the actual PDF by anyone who has it.
