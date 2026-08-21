# Toolchain

What has to exist on the machine before `FEAT01-foundation` can start, and the MCP server
that makes an assistant useful on a Flutter codebase.

## Installed — 2026-08-21

The SDK is on this machine and on the PATH. Verified by running it, not by finding the folder:

```
Flutter 3.47.1 • channel stable • revision 6655482ec0 (2026-08-19)
Tools • Dart 3.13.1 • DevTools 2.60.0
```

Installed at `C:/flutter`, with `C:/flutter/bin` on the **user** PATH. `bin/cache/dart-sdk`
is already populated, so there is no first-run SDK download waiting to surprise anyone. No
`fvm` — a single global SDK, which is fine for one developer on one project and would not be
for someone juggling several.

Version floor for everything below is **Dart 3.9+ / Flutter 3.35+**; what is installed clears
it comfortably, so nothing in these files is constrained by the toolchain being old.

**Two things that cost time here and will cost it again on another machine.** A shell — or a
Claude Code session — started *before* the PATH edit keeps the environment it launched with,
so `flutter` can be genuinely installed and genuinely absent from a running process at the
same time; the fix is to restart the process, not to re-edit PATH. And on Windows the runnable
entry points are `flutter.bat` and `dart.bat` — the extensionless files beside them are POSIX
shell scripts and will not execute.

*Superseded: this file said until 2026-08-20 that `dart`, `flutter` and `fvm` were all absent
and that `FEAT01` could not begin. That was true when written and is the reason `FEAT01`'s row
in `pm/tracker.yaml` was marked blocked in practice.*

## The Dart and Flutter MCP server — worth having

There is an official one, built and maintained by the Dart and Flutter teams at Google:
[docs.flutter.dev/ai/mcp-server](https://docs.flutter.dev/ai/mcp-server). It ships **with the
SDK** — `dart mcp-server` is a subcommand of the `dart` binary — which is why it could not be
added until the SDK was.

**Added and connected 2026-08-21**, server version `1.1.1`, registered in this project's local
config:

```bash
claude mcp add --transport stdio dart -- C:/flutter/bin/dart.bat mcp-server
```

The alternative is the **official Flutter plugin**, which bundles the MCP server together with
Flutter's agent skills and is what the docs recommend
([install agent skills](https://docs.flutter.dev/ai/agent-skills)). Verify either with `/mcp`.

**Register the absolute path, not bare `dart`.** The obvious form —
`claude mcp add --transport stdio dart -- dart mcp-server` — resolves `dart` through the PATH
of whatever process launches it, which fails in exactly the case described above: a session
started before the PATH edit. An absolute path works regardless of what any process thinks
PATH is.

**Expect the first connection attempt to fail, once.** The server builds a bundled executable
and resolves a helper package's dependencies on first invocation, and it prints pub's progress
— `Resolving dependencies…`, `Got dependencies in …` — **to stdout**, which is the JSON-RPC
transport. The client sees non-JSON on the stream and reports `CONNECTION_CLOSED`, or the
server answers an empty request with `-32700 Invalid JSON`. Neither message points at the real
cause. It is one-time: the build is cached, and the next start is clean. If it happens, warm
the server up by hand first —

```bash
dart mcp-server --version    # prints the version and exits, doing the build on the way
```

— and then reconnect. Worth knowing because both symptoms look like a broken install and
neither is.

**Why it is worth the setup step**, in terms of this project specifically:

- **Analyzer access.** It can read analysis errors and resolve symbols directly instead of
  parsing `flutter analyze` output — which matters here because `analysis_options.yaml` turns
  on `strict-casts` / `strict-inference` / `strict-raw-types`, so there will be real analyzer
  output to act on.
- **Runs tests and reads results.** `testing.md` puts the correctness surface of this app in
  DAO query tests; being able to run and read them closes the loop.
- **`pub_dev_search` and dependency management.** Useful precisely once, at `FEAT01`, when the
  `drift` / `riverpod` / `build_runner` versions get pinned for real — the versions in
  `riverpod.md` are shape, not verified fact.
- **Live app interaction** via DTD and Flutter Driver: hot reload, widget tree, runtime errors,
  screenshots, tapping and scrolling. This is the part that changes what "verified" can mean
  for a UI issue. Note it needs `flutter_driver` added to the project and enabled with a
  `--dart-define`, deliberately so it cannot end up in a production build.

**One caution.** Screenshot-and-tap capability makes it tempting to treat a driven app as
proof a use case works. It is evidence, not proof: the requirements this project is most
likely to break — NFR-4's zero refusals, FR-8's "a transfer is not spending" — are assertions
about behaviour and data, and belong in tests that fail loudly, not in a screenshot someone
looked at once.

## Other tooling decisions

- **`build_runner` is non-negotiable from the first commit**, because `drift_dev` is a builder.
  That is also the argument for using Riverpod's code generator: the cost is already paid
  (`riverpod.md`).
- **No CI configured, and none proposed yet.** This working copy is not a git repository yet
  (still true 2026-08-21). That is deliberate and sequenced, not an oversight: the owner is
  writing every `plan.md` first, then creating the repo with GitHub Issues and CI on top of it,
  then running implementation unattended. The four commands at the bottom of `testing.md` are
  exactly what that CI job should run, and are currently run by remembering to.
- **Add one more to that CI list: re-exporting diagram renders.** Sequence-diagram PNGs live in
  `pm/issues/<issue>/` and are committed (`drawio-general-guide.md`), so a `.drawio` edited
  without a re-export leaves a wrong picture in the repo — and for sequence diagrams the picture
  is the issue's scope.
- **`audit.py`** at the repo root checks documentation consistency and is unrelated to the
  Dart toolchain, but it should keep passing after code lands: it verifies that every use case
  is owned by exactly one issue, and that ids and traceability agree.
