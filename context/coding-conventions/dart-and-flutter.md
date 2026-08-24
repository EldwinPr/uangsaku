# Dart and Flutter

Language-level conventions. Source: [Effective Dart](https://dart.dev/effective-dart), which
is organised as four guides — **Style**, **Documentation**, **Usage**, **Design** — and grades
its rules **DO / DON'T / PREFER / AVOID / CONSIDER**. Read it rather than this file for
anything not covered here; this file records what applies to *this* project and what this
project decided where Effective Dart leaves a choice.

## Naming

Straight from the Style guide, repeated here because they are the ones that get argued about:

| Thing | Case | Example |
|---|---|---|
| Classes, enums, typedefs, extensions | `UpperCamelCase` | `AccountDao`, `TransactionKind` |
| Packages, directories, files | `lowercase_with_underscores` | `account_dao.dart` |
| Constants | `lowerCamelCase` — **not** `SCREAMING_CAPS` | `defaultCurrency` |
| Everything else | `lowerCamelCase` | `openingAmount` |
| Import prefixes | `lowercase_with_underscores` | `as drift_db` |

**Domain terms stay in English and stay spelled as the artifacts spell them**
(`general-rules.md`). `Account`, `Transaction`, `Category`, `Subcategory`, `Budget_Group`.
Note the one translation that *is* required: entity names are `Snake_Case` on the ERD and
`UpperCamelCase` in Dart, and a drift table declaration is plural (`Accounts`) while its
generated row class is singular (`Account`). That is drift's convention, not a rename, and
`pm/issues/002-class-diagrams/plan.md` records that the generated classes are deliberately
omitted from the diagrams.

## Imports

1. `dart:` first, 2. `package:` second, 3. relative last, each block sorted alphabetically,
exports in their own section. `dart format` does not do this — the `directives_ordering` lint
does, and it is enabled below.

## The analyzer

`analysis_options.yaml` at the project root:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore   # riverpod_generator, see riverpod.md

linter:
  rules:
    directives_ordering: true
    prefer_final_locals: true
    unawaited_futures: true
    avoid_print: true
    constant_identifier_names: false
```

**`constant_identifier_names: false`, added `FEAT01`.** `AccountGroup` (`HOLDING` /
`RECEIVABLE` / `PAYABLE`) and `Currency` (`IDR` / `USD`) are spelled exactly as `docs/enums.md`
and the class diagrams spell them — domain vocabulary outranks Effective Dart's lowerCamelCase
preference for constants here, per this file's own "Domain terms stay in English and stay
spelled as the artifacts spell them." `TransactionKind`'s values are already lowerCamelCase
and untouched by this. **Also note the `rules` block switched from list to map form** — YAML's
list syntax (`- rule_name`) can only enable rules from the included `flutter_lints` set, not
disable one; disabling `constant_identifier_names` needs the `rule_name: false` map form for
the whole block.

**Decision: `flutter_lints` plus the three strict analyzer modes, not `very_good_analysis`.**
`very_good_analysis` enables far more rules (~86% of all available lints) and is the stricter
choice for a team enforcing house style across many contributors. This is a solo project, and
the rules that actually prevent *bugs* here are the `strict-*` analyzer modes — they close the
implicit-`dynamic` holes that let a wrong type travel a long way before failing. The rest of
`very_good_analysis` is mostly style, which `dart format` and one reader already settle.
Revisit if a second person ever writes code here.

`unawaited_futures` earns its place specifically: this app awaits database writes everywhere,
and a dropped `Future` is exactly how a write silently doesn't happen.

## Formatting

`dart format` decides. It is not configurable and there is nothing to argue about — run it,
commit the result, and never hand-align anything.

## Documentation comments

`///`, not `//`, for anything public. Effective Dart's Documentation guide wants a single
sentence summary first, then a blank line, then detail.

**Comment the *why*, and cite the artifact.** This project's code exists to satisfy numbered
requirements, so a comment that says `// FR-8: a transfer is not an expense` is worth more
than one describing what the line does. Where a rule looks arbitrary, name its decision:
`// Amounts are int minor units, never double - NFR-2, see docs/enums.md`.

## Directory layout

Mirror the module structure the rest of the artifacts use, so `map.yaml` can point a use case
at a directory and be right:

**The Dart package is `app/`, not the repository root** (`decisions.md`, 2026-08-21). The
root is the documentation pipeline's namespace — `docs/`, `pm/`, `context/`, `input/`,
`audit.py` — and Flutter's names are generic enough (`lib`, `test`) that mixing the two in
one listing reads as clutter. Everything below is relative to `app/`.

```
app/
  pubspec.yaml
  analysis_options.yaml
  build.yaml
  android/  ios/             # both targets (decisions.md, 2026-08-21)
  test/                      # mirrors lib/src/, *_test.dart
  lib/
    main.dart
    src/
      app.dart                  # MaterialApp, routing, theme
      database/
        app_database.dart       # AppDatabase, the isolate open, migrations
      accounts/
        accounts_table.dart     # drift table declarations
        account_dao.dart
        accounts_providers.dart # StreamProviders + Notifier
        balance_sheet_screen.dart
        account_form_screen.dart
      transactions/
      budgeting/
      settings/
```

Four modules, matching the `Modules` sheet and the four class diagrams: `accounts`,
`transactions`, `budgeting`, `settings`. `AppDatabase` sits outside them because all four
share it — which is exactly what `component-overview.drawio` draws.

`map.yaml` entries therefore carry the prefix — `UC-02 → app/lib/src/accounts/` — and so
does anything run from CI, where every Flutter step needs `working-directory: app`. A
command run from the repository root will not find `pubspec.yaml`.

**One band of the class diagram per file kind.** The class diagrams are drawn as four vertical
bands (screen, provider, DAO, table); the file names above are those bands. A reader holding
`class-accounts.drawio` should be able to guess the filename.

## Flutter specifics

- **Widgets that read providers are `ConsumerWidget` / `ConsumerStatefulWidget`**, as the
  class diagrams already label them.
- **`const` constructors wherever possible.** The stack decision carries a hard constraint —
  the app must stay light on old Android phones — and `const` widgets are the cheapest
  rebuild-avoidance there is.
- **No business logic in a widget.** The class diagrams draw the screen calling a notifier and
  watching a provider; a screen that computes a balance itself contradicts the diagram *and*
  NFR-2's one-source rule.
- **No `print`.** `avoid_print` above; use `debugPrint` while developing and delete it.
- **A new/changed ARB key needs `flutter gen-l10n`, not just `dart run build_runner
  build`.** This project's `app/l10n.yaml` routes localization codegen through
  `flutter gen-l10n`; `build_runner` regenerates drift/riverpod code but does not
  regenerate `app_localizations*.dart` on its own. Skipping this step leaves
  `flutter analyze` failing with `undefined_getter` on the new key even though the ARB
  file itself is correct (discovered FEAT09, 2026-08-24). Run both after touching an
  ARB file, `gen-l10n` before `analyze`.
