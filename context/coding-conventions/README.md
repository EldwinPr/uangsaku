# Coding Conventions

Stack conventions for this project: **Flutter / Dart, `drift` over SQLite, Riverpod, no
backend** (`context/index/decisions.md`, 2026-08-19).

`general-rules.md` says this directory appears when the project reaches implementation.
It has been written slightly ahead of that, at the owner's request, which is worth stating
plainly because it changes how much these files are worth:

> **These are provisional until `FEAT01-foundation` runs.** Every rule here is either
> quoted from an official source or derived from a decision already recorded in
> `decisions.md`. Nothing here has been checked against code, because no code exists yet:
> no `pub get` has run, no package version is verified, nothing has been compiled.
> **Anything that turns out to fight the real toolchain loses** — update the file as part
> of the issue that hits it, and say so in `pm/log.md`.
>
> *Narrowed 2026-08-21.* This note used to give two reasons, and one of them is gone: the
> SDK **is** now installed and on the PATH (Flutter 3.47.1 / Dart 3.13.1 — see
> [`tooling.md`](tooling.md)), and the Dart MCP server is connected. What remains unverified
> is everything downstream of actually building the project, which is still all of it.

## The files

| File | Covers |
|---|---|
| [`dart-and-flutter.md`](dart-and-flutter.md) | Effective Dart, the analyzer and lints, formatting, file and directory layout |
| [`riverpod.md`](riverpod.md) | Providers, notifiers, what may hold state, and the read/write asymmetry |
| [`drift.md`](drift.md) | Tables, DAOs, the background isolate, migrations, money storage |
| [`testing.md`](testing.md) | What gets a test, at which layer, and the two requirements that need one |
| [`tooling.md`](tooling.md) | The installed toolchain and its verified versions, the Dart/Flutter MCP server, and what CI should run |

## The rule that outranks the rest

**Class names in code must match the class diagrams exactly.** `docs/diagrams/class-*.drawio`
already name every class this app will have, and `sequence-conventions.md` requires every
lifeline to be one of them. If code wants a class the diagrams don't have, that is a finding
to raise — either the diagram is incomplete or the code is inventing a layer — and **not**
something to resolve by writing the class and moving on. Same rule the sequence diagrams get,
applied one artifact further down.

The whole point of the Phase 1 artifact set is that it stays true. A diagram that disagrees
with the code is worse than no diagram, because it will still be believed.

## Sources

Cited inline in each file. The four that matter:

- [Effective Dart](https://dart.dev/effective-dart) — the language's own style, documentation,
  usage and design guides.
- [drift documentation](https://drift.simonbinder.eu/) — schema, DAOs, migrations.
- [Riverpod documentation](https://riverpod.dev/) — providers and code generation.
- [Flutter documentation](https://docs.flutter.dev/) — tooling, testing, and the MCP server.

Unlike `document-writer-only/*.md`, these are **not** distilled from a committed spec, so
there is nothing in `context/files/` to cite by section. Links are the citation; if one rots,
replace it rather than leaving the claim unsourced.
