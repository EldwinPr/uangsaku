# Coding Conventions

Stack conventions for this project: **Flutter / Dart, `drift` over SQLite, Riverpod, no
backend** (`context/index/decisions.md`, 2026-08-19).

`general-rules.md` says this directory appears when the project reaches implementation.
It has been written slightly ahead of that, at the owner's request, which is worth stating
plainly because it changes how much these files are worth:

> **Half of this is now verified, half is still shape.** These files were written ahead of
> any code. **`FEAT01-foundation` ran on 2026-08-21 and tested the database half against a
> real toolchain**: package versions, `analysis_options.yaml`, the table and enum rules, the
> money rule, how the database is opened, and the provider shapes are **checked, and the
> three files that lost were corrected in place** (`riverpod.md`, `drift.md`,
> `dart-and-flutter.md` — each correction is marked and dated where it sits).
>
> **`UC13-categories` ran on 2026-08-21 and tested the DAO/provider/screen/widget-test half
> against the real toolchain.** A DAO, a `StreamProvider`, a `Notifier`, a `ConsumerWidget`
> screen and a widget test all now exist and pass. `drift.md` and `riverpod.md` are each
> corrected in place, marked and dated where the toolchain disagreed. Note the sentence this
> replaces used to name `UC14-choose-currency` as the issue that would test this half —
> `UC14` is halted (`pm/questions.md` Q1) and `UC13` got there first, so that pointer is
> corrected here rather than left stale (`lessons.md` §1).
>
> **Still unverified: a cross-module join and a derived-figure query**, the two claims
> `drift.md`'s "DAOs" section and `testing.md`'s "What is actually worth testing here" make
> that no issue has yet exercised — `UC13`'s `CategoryDao` does touch a second module's table
> (`Transactions`, for D6's tag-blanking), but nothing here yet asserts NFR-2's derived
> figures (a balance, a budget consumption total) against a real query.
>
> **Anything that turns out to fight the real toolchain loses** — update the file as part of
> the issue that hits it, and say so in `pm/log.md`. *Do not re-broaden this note to a
> blanket "provisional": a label that is half true is read as false everywhere and stops
> being read at all (`lessons.md` §1).*

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
