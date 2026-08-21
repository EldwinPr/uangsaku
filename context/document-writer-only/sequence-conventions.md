# Sequence Diagram Conventions

Working reference for the per-use-case sequence diagrams (`docs/diagrams/seq-uc{NN}-{slug}.drawio`)
that carry the scope of an implementation issue. Distilled from OMG UML 2.5.1
(`context/files/formal-17-12-05.pdf`, Clause 17 "Interactions"); own words, sections cited
inline. Not a copy of the spec — read the spec directly for edge cases.

**A note on the citations here.** The spec PDF is git-ignored and present only as a stub
(`context/files/formal-17-12-05.pdf.txt`), so the sub-clause numbers below were confirmed
against secondary references rather than read out of the document: Clause 17 is
"Interactions", with **17.2 Interactions**, **17.3 Lifelines**, **17.4 Messages**,
**17.6 Fragments** (CombinedFragment) and **17.7 Interaction Uses**; `StateInvariant` sits
at 17.2.3.5. Anyone holding the PDF should verify and correct these in place — per
`context/files/README.md`, a section number nobody can check is a claim, not a citation.

## Why this diagram carries more weight here than elsewhere

`CLAUDE.md` makes it the scope boundary: *"A plan.md's scope IS whatever its sequence
diagram shows — nothing outside the diagram is in scope for that issue, and nothing in the
diagram gets skipped without going back to the user first."* Every other diagram in this
project describes; this one **decides**. Two consequences that shape every rule below:

- **A message that isn't drawn is work that isn't authorised.** Under-drawing is not
  harmless brevity — it silently narrows the issue.
- **A lifeline that isn't a real class is a claim about code that doesn't exist.** See the
  hard rule below.

The close checklist's first step is an **as-built pass**: after the issue is done, reconcile
the diagram against what was actually built and correct it, the same as-is/to-be discipline
the BPMN conventions use. A sequence diagram that still shows the plan rather than the build
is worse than none, because it will be believed.

## One diagram per use case, not per issue

Named `seq-uc{NN}-{slug}.drawio`, matching the worked examples in
`examples/movie-booking demo/`. An issue covering several use cases carries several
diagrams, and the **union** of them is that issue's scope. This keeps a diagram reusable
when use cases are re-sliced across issues, which has already happened once to this backlog.

## Notation

### Lifelines (§17.3)

A named rectangle with a dashed vertical line beneath it representing the participant's
lifetime. The head carries the participant's name. Time flows **downward**; nothing else
about vertical position carries meaning, and horizontal position carries none at all.

Order lifelines left to right in the order the interaction first touches them — the actor
leftmost, then the screen, then inward toward the database. This makes the common case a
staircase rather than a zigzag, and a zigzag is a signal worth reading: it usually means
the call chain doubles back through a layer it already passed.

### Messages (§17.4)

Four kinds are used here, and only four:

| Kind | Arrow | Means |
|---|---|---|
| **Synchronous call** | solid line, filled arrowhead | The sender waits for the receiver to finish. In Dart, an `await`. |
| **Reply** | dashed line, arrowhead | The return of a call. Label it with what comes back, not with `return`. |
| **Asynchronous** | solid line, open arrowhead | The sender does not wait. Used here for a stream emission — see the read/write rule below. |
| **Found message** | starts from a filled dot, not a lifeline | The actor's first action. Use only for the trigger that starts the use case. |

Not used: create and destroy messages (nothing in this app has a lifetime worth drawing —
`statuses.md` records that no entity has a lifecycle), and `StateInvariant` (§17.2.3.5).

### Combined fragments (§17.6)

A labelled box around a region of the interaction. Only three operators are used here:

- **`alt`** — a real branch, two or more operands separated by a dashed line, each with a
  guard in square brackets. Every operand must be reachable, and the guards together must
  cover every case — an `alt` whose guards leave a gap is a hole in the issue's scope.
- **`opt`** — something that either happens or doesn't. Equivalent to an `alt` with one
  operand; prefer it over an `alt` with an empty second operand.
- **`loop`** — a repetition, with the guard naming what it iterates over.

`par`, `break`, `critical`, `neg`, `assert`, `strict`, `seq`, `ignore` and `consider` exist
in the spec and are **not used in this project**. If one is genuinely needed, add it here
with the reason before drawing it.

**Guards go in square brackets** and must be checkable against a stated requirement, the
same discipline `state-conventions.md` applies to transitions: if you cannot point at the FR
or the decision that makes the branch real, it doesn't go on the diagram.

### Numbered steps

Every message carries a sequence number (1, 2, 3…) in a filled circle at its tail, as the
worked examples do. This is not UML — it is a house convention, and it earns its place
because the plan's prose refers to steps by number ("step 7 is where the isolate boundary is
crossed") without having to restate them.

## The hard rule: every lifeline is a real class from a class diagram

**A participant on a sequence diagram must be a class that already appears on
`docs/diagrams/class-{module}.drawio`, spelled identically — or the actor `Owner`.**

The class diagrams already fix this project's call chain:

```
Screen (ConsumerWidget) → Riverpod provider / Notifier → DAO → AppDatabase → drift table
```

so a sequence diagram is not free to invent a participant. If drawing one requires a class
that isn't on a class diagram, exactly one of two things is true, and both are findings to
raise rather than to paper over:

1. the class diagram is incomplete and needs the class added, or
2. the sequence is wrong and is inventing a layer.

Never resolve it by drawing the participant anyway. This is the rule that makes the two
artifact sets check each other instead of drifting; without it, a sequence diagram is just a
picture of an intention.

The actor is **`Owner`** — the `User` column of every workbook row, and the project's only
actor.

## Reads and writes are not symmetrical, and the diagram must show that

The single most likely way to draw one of these wrongly. From `class-accounts.drawio`'s own
note: *"Reads travel back the other way as streams… The screen never receives an answer from
the write it triggered — it sees the result arrive on the read path, the same as any other
change."*

So:

- **A write** is `Screen → Notifier → DAO → AppDatabase`, each a synchronous call. It does
  **not** get a reply arrow back to the screen carrying the result. Drawing one asserts a
  request/response shape the app does not have.
- **The result appears separately**: drift pushes the changed row into the watching stream,
  and the provider emits to the screen. Draw that as an **asynchronous** message from the
  `StreamProvider` to the `Screen`, not as a reply to the write.
- **A read** at screen build time is the stream's first emission, drawn the same way.

A diagram where every write has a tidy reply arrow back to the screen is the signature of
this mistake.

## The isolate boundary

`AppDatabase` runs on a background isolate (`NativeDatabase.createInBackground`, decided
2026-08-20). Every DAO → `AppDatabase` message therefore crosses a real memory boundary and
is message-passed, which is what the component diagram's dotted `isolate call` edges record.

**Do not draw it as an asynchronous message.** The DAO awaits the result, so the honest
notation is a synchronous call with a reply. Instead, put one note on the diagram saying the
DAO → `AppDatabase` messages cross the isolate. Drawing it async would misrepresent the
control flow to make a point about the deployment, and `component-overview.drawio` already
carries that point properly.

## What not to draw

- **No conditional logic that is really a query.** "If the account is a receivable" inside a
  DAO is a `WHERE` clause, not an `alt`. Fragments are for branches the *interaction* takes.
- **No refusals.** NFR-4's fit criterion is zero refusals, so an `alt` whose second operand
  is "system rejects the action" is a violation of the requirement, not a diagram detail. A
  warning that the owner can proceed past is drawn as a message, not a branch that ends.
- **No layers below the table.** SQLite itself, the file system, and drift's generated code
  are not participants.
- **Nothing already true of every diagram.** The provider-watches-DAO wiring exists on every
  screen; draw it once per diagram where it matters to the flow, not at every step.

## Authoring: Mermaid, not hand-written XML

**Author these in Mermaid and convert with the draw.io CLI**, unlike every other diagram type
in this project.

```bash
drawio -x -f xml -o docs/diagrams/seq-uc02-add-account.drawio seq.mmd   # then delete the .mmd
```

The reasons, in order of weight:

1. **Layout is most of the work in a sequence diagram** — vertical ordering, spacing, and
   fragment boxes that must enclose exactly the right messages. Mermaid's parser computes all
   of it; hand-positioning it in XML is where this project's diagram defects have
   historically come from.
2. **The three worked examples are already Mermaid-generated.** Their XML carries
   `mermaidId` / `mermaidBaseStyle` / `mermaidBaseValue` attributes and `<UserObject>`
   wrappers, which is what draw.io's Mermaid import produces. Hand-authoring a fourth would
   produce a file that does not match the three that already exist.
3. `.claude/skills/drawio/SKILL.md` recommends Mermaid for every type it handles well, and
   reserves hand-written XML for BPMN, where Mermaid has no equivalent.

**Accepted consequence: sequence diagrams look different from the rest of this project's
diagrams.** The Mermaid import brings its own palette — purple `#9370DB` lifelines, Trebuchet
MS, `light-dark()` theme functions — where the hand-authored ERD, class and component
diagrams are plain black on white. This is a deliberate trade: internal consistency within the
diagram type, plus reliable layout, beats palette uniformity across types. Do **not** hand-fix
the styles after conversion; the next regeneration would undo it, and a file that is
regenerated differently than it is stored is worse than one that looks slightly foreign.

## draw.io shapes

Verified by reading the three worked examples in `examples/movie-booking demo/` and rendering
them — **not** from memory and not from `search_shapes`. Note that `examples/elements.drawio`,
this project's palette reference, currently contains **no** sequence-diagram shapes; these
strings are the reference until it does.

You normally do not type these, because Mermaid emits them. They are here so a render defect
can be diagnosed, and so a targeted fix does not have to be guessed.

| Element | style |
|---|---|
| Lifeline (object) | `html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;` |
| Lifeline (actor) | as above plus `participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;` |
| Synchronous call | `endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;strokeWidth=1.5;` |
| Reply | the same plus `dashed=1;fixDash=1;dashPattern=3 3;` |
| Combined fragment box | `html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;height=20;width=50;` |
| Operand separator (inside an `alt`) | `shape=line;dashed=1;fixDash=1;dashPattern=2 2;` |
| Step number | `ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;` |

`lifelineMirror=1` is why the worked examples repeat the participant headers at the bottom of
the diagram — useful on a tall diagram, and left on.

**Labels live on `<UserObject label="…">` wrappers, not on `mxCell value=`,** in any
Mermaid-generated file. A script that reads `mxCell` values will report a fully-labelled
diagram as having none. This cost a wrong conclusion once already while writing this file.

## Worked examples

`examples/movie-booking demo/` holds three, and they are this file's regression suite in the
sense `general-rules.md` means: a proposed rule change must still reproduce them.

- `movie-booking-seq-uc01-browse-showtimes.drawio` — the simple case: 6 lifelines, 5 calls,
  5 replies, no fragments.
- `movie-booking-seq-uc02-select-seats.drawio` — an `alt` with two guarded operands
  (`[semua kursi tersedia]` / `[kursi sudah diambil pelanggan lain]`).
- `movie-booking-seq-uc03-submit-payment.drawio` — the fullest: 8 lifelines including an
  external `Payment Gateway`, 17 numbered steps, an `alt` on `[approved]` / `[declined]`.

They predate this project's own conventions and follow an EBC-ish View/Controller naming that
**this project does not use** — the owner rejected EBC for the class diagrams. Read them for
notation, layout and style strings; do not copy their participant naming.

## Pairs with the class diagrams

`class-diagram-conventions.md` fixes *what* the classes are and how they depend on each
other; this file fixes *when* they call each other, for one use case. The two must agree in
both directions: every lifeline here is a class there, and a call drawn here that the class
diagram shows no dependency for is a defect in one of the two. Checking that pair is part of
the close checklist's as-built pass, not an optional extra.
