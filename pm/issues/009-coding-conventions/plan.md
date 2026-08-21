# ISSUE-009 — `context/coding-conventions/`

**Status:** DONE 2026-08-20. Written at the owner's direct instruction ("now you can gather
coding conventions... remember its flutter"), so the planning gate was satisfied by the
instruction; this plan records what was decided, alongside the work.
**Depends on:** ISSUE-002 (the class diagrams fix the architecture these conventions describe).
**Traces to:** no UC. Infrastructure for every implementation issue.

## Goal

The last prerequisite before `FEAT01-foundation` can be planned. `general-rules.md` says this
directory appears when the project reaches implementation; the owner asked for it slightly
early, so it is written and **explicitly marked provisional**.

## The honesty constraint that shaped everything

**No code exists and no Dart SDK is installed on this machine** (`dart`, `flutter`, `fvm` all
absent, checked 2026-08-20). So none of these rules have been executed, no `pub get` has run,
and no version number in them has been verified. Rather than write with false confidence, the
README says outright that anything fighting the real toolchain loses, and that `FEAT01` is
expected to correct these files as its first act.

Every rule is therefore either (a) quoted from an official source, or (b) derived from a
decision already in `decisions.md`. Nothing is invented from experience.

## Decisions

### D1 — `flutter_lints` plus strict analyzer modes, not `very_good_analysis`

`very_good_analysis` enables roughly 86% of available lints and is the stricter choice for a
team enforcing house style across contributors. This is a solo project, and what actually
prevents bugs here is `strict-casts` / `strict-inference` / `strict-raw-types`, which close
the implicit-`dynamic` holes. The rest is style, which `dart format` and one reader settle.
`unawaited_futures` is called out specifically: this app awaits database writes everywhere and
a dropped `Future` is how a write silently doesn't happen.

### D2 — Riverpod code generation (`@riverpod`)

Riverpod's own docs recommend it. The standard objection is that it drags in `build_runner`
and `.g.dart` files — **but this project pays that cost already**, because `drift_dev` is a
builder and `build_runner` is non-negotiable from the first commit. Adding a second generator
to a build that must run anyway is nearly free.

### D3 — Guided drift migrations, with snapshots and generated tests committed

`dart run drift_dev make-migrations` rather than hand-written `onUpgrade` branches. The
generated schema snapshots and migration tests are the only artifact that proves a migration
preserves data, and NFR-3 is a promise that tooling has to keep.

### D4 — The code-level restatement of rules already decided

Not new decisions; the point is that they now have a home a developer will actually read:

- Money is `IntColumn` minor units, never `double`, anywhere (NFR-2).
- No stored balance, ever — if a query is slow, index it, don't add a column (ERD D7).
- "Is this spending?" is `to_account_id IS NULL`, never a `kind IN (...)` list (ERD D1) —
  re-deriving it from `kind` per query is how FR-8/FR-9's guarantee gets lost.
- A write returns nothing to the screen; results arrive on the read path (Riverpod + NFR-2).
- Enums stored `.textEnum<T>()`, not by index, so reordering cannot reinterpret old rows.

### D5 — Two requirements get explicit tests

**NFR-4 (zero refusals)** and **FR-18 (full CRUD, no create-only entity)** are project rules
that erode quietly rather than failing loudly, so `testing.md` requires widget tests asserting
that consequential controls stay *enabled* — deleting an account with transactions, editing a
budget mid-month, changing currency after amounts exist. A disabled button is the likeliest
accidental violation in the app, because disabling one feels like good UI.

### D6 — The rule that outranks the rest

**Class names in code must match the class diagrams exactly.** Same rule
`sequence-conventions.md` applies to lifelines, pushed one artifact further down. A class the
diagrams don't have is a finding to raise, not something to write and move on from.

## The MCP question, answered

The owner asked whether a Dart/Flutter MCP server exists. **Yes, an official one**, built by
the Dart and Flutter teams, documented at `docs.flutter.dev/ai/mcp-server`. It **ships with the
SDK**, so it cannot be added until Flutter is installed — `dart mcp-server` is a subcommand of
a binary that isn't here. Recorded in `tooling.md` with both setup routes (the `claude mcp add`
command, and the official Flutter plugin that bundles the server plus agent skills), what it
gives this project specifically, and one caution: its screenshot-and-drive capability is
evidence a screen works, not proof a requirement holds.

## Consequence for the backlog

`FEAT01-foundation` no longer creates this directory. Its row now **depends on** ISSUE-009,
and says plainly that it is blocked in practice until Flutter is installed.

## Out of scope

- Any code, and any version pinning. The versions in `riverpod.md` are shape, not fact.
- CI. Flagged in `tooling.md` — this working copy is not even a git repository — and worth
  raising at `FEAT01`, since the four commands at the end of `testing.md` are exactly what a
  CI job would run.
- An integration-test tier. Argued against in `testing.md` for now: one user, one device, no
  network.
