# FEAT01-foundation — Flutter scaffold, drift on a background isolate, first migration

**Status:** DONE 2026-08-21. All twelve steps complete; reviewed and closed by
`issue-qa`, which re-ran the four D7 commands itself (build_runner green, `dart format`
0 changed, `flutter analyze` "No issues found!", `flutter test` 4/4). The two open
questions at the foot of this file are the owner's and were **still unanswered at close**
— neither blocked the work, and neither is resolved by it.

*Previously:* CONFIRMED by the owner 2026-08-21. Step 1 already done (see Steps); the
unattended run starts at step 2. All nine decisions below are confirmed as written —
D1 and D4 were answered by the owner directly, the rest by confirming this plan.

**Traces to:** no use case (FEAT)
**Depends on:** ISSUE-007 (DONE), ISSUE-008 (DONE), ISSUE-009 (DONE) — preflight passes.

## Goal

Turn this repo from a documentation project into a Dart project that compiles, has a
database matching `docs/diagrams/erd.drawio`, and has a test proving the database opens.

Nothing a user can see. The deliverable is the substrate every use-case issue builds on:
the seven tables, `AppDatabase`, the first migration snapshot, and a green
`flutter test`. The first screen belongs to UC14, which is sequenced first among the use
cases precisely because it is the cheapest place to discover the architecture is wrong.

This is also the issue that **first tests `context/coding-conventions/` against a real
toolchain**. Those files are marked provisional — no `pub get` has ever run for this
project, so every version number in them is shape, not fact. Anything that fights the real
toolchain loses, gets corrected in the conventions file, and is recorded in `pm/log.md`.

## The gate this issue cannot satisfy the normal way

`CLAUDE.md`: *"A `plan.md`'s scope IS whatever its sequence diagram shows."* **FEAT01 has
no sequence diagram**, because it has no use case — no actor looks at a screen, so
`workbook-conventions.md`'s derivation rule produces nothing, which is why this row is
coded FEAT and not UC. Drawing one would mean inventing an actor to satisfy a rule.

D2 below replaces the missing diagram with an explicit file manifest, so the issue still
has a hard scope boundary. This is the one issue in the backlog that needs that
substitution; every other row traces to at least one UC and gets a real diagram.

## Decisions

### D1 — Package name `uangsaku`, application id `com.eldwinpr.uangsaku`

`flutter create` needs both and they are painful to change afterwards — the application id
in particular is the identity Android and the Play Store use, and changing it after
install means a different app, not an upgrade.

- **Dart package name: `uangsaku`.** Matches the GitHub repo (`EldwinPr/uangsaku`). Dart
  package names must be `lower_snake_case`, so this is legal as-is.
- **Android application id: `com.eldwinpr.uangsaku`,** derived from the GitHub account.

Note the split identity this repo already carries and does not resolve here: the directory
is `moneytracker`, the repo and package are `uangsaku`, and the class diagrams are titled
"moneytracker". **This issue does not rename anything** — it picks the name for new
artifacts and leaves existing ones alone. If the owner wants one name everywhere, that is
its own issue with its own audit, not a side effect of scaffolding.

### D2 — Scope is this file manifest, and nothing else

Standing in for the sequence diagram, per the section above. **All paths are relative to
`app/`** (D9). FEAT01 creates exactly:

```
app/pubspec.yaml                      app/analysis_options.yaml   app/build.yaml
app/lib/main.dart
app/lib/src/app.dart                  MaterialApp + ProviderScope; a placeholder screen
app/lib/src/database/app_database.dart    AppDatabase, isolate open, schemaVersion 1, seeding
app/lib/src/accounts/accounts_table.dart      Accounts
app/lib/src/transactions/transactions_table.dart  Transactions, Categories, Subcategories
app/lib/src/budgeting/budgeting_table.dart    BudgetGroups, BudgetPeriods
app/lib/src/settings/settings_table.dart      Settings
app/drift_schemas/                    generated schema snapshot, committed
app/test/database/app_database_test.dart
app/android/  app/ios/                platform folders (D4)
```

Plus one file outside `app/`, already done: `.github/workflows/ci.yml`, repointed at the
subdirectory (D9).

A file not on this list is out of scope. Adding one is a conversation, not a judgement
call.

### D3 — All seven tables land now, at `schemaVersion = 1`

The alternative — each use-case issue adds its own tables — was considered and rejected.
The ERD is already complete and confirmed, so incremental tables would mean writing seven
migrations to arrive at a schema we can already draw, and the schema snapshots
(`drift.md`) would record a history of our own indecision rather than of real change.

Table declaration names come from the class diagrams and are not negotiable
(`coding-conventions/README.md`, "the rule that outranks the rest"): **`Accounts`,
`Transactions`, `Categories`, `Subcategories`, `BudgetGroups`, `BudgetPeriods`,
`Settings`.** Column names come from `erd.drawio` in `snake_case`, including
`Transaction.note` (added 2026-08-21). Three enums stored with `.textEnum<T>()`, never by
index: `AccountGroup`, `TransactionKind`, `Currency`.

**Consequence worth naming:** this makes FEAT01 the issue that fixes the schema. A column
wrong here is a migration later, in an app whose data cannot be regenerated. The seven
tables get read against the ERD before the generator runs, not after.

### D4 — Android and iOS; not web, not desktop

`flutter create --platforms=android,ios`. **Revised 2026-08-21** — this decision said
Android only, on the reasoning that Android was the stated target. The owner confirmed both
platforms, which also closed the assumption the whole Flutter choice rested on
(`decisions.md`, both entries that day).

Web and the three desktop platforms stay out. `web` is not merely unnecessary but actively
misleading: `NativeDatabase.createInBackground` is native-only, so a web build would need a
different drift backend and would not be testing this app (`tooling.md`).

**`app/ios/` will be generated, committed, and never built here.** Apple's toolchain is
macOS-only. Versioning it from the first commit beats letting it land as a large untracked
diff later, but it means neither this issue's definition of done (D7) nor CI says anything
about iOS. `flutter create --platforms=<other> .` adds a platform later if that changes.

### D5 — No screens, no DAOs, no providers

`app.dart` renders a placeholder with the app name and nothing else. The five DAOs and
every provider on the class diagrams belong to the use-case issues that need them; writing
them now would mean writing them against no screen and no test.

The `ProviderScope` wrapper and the `AppDatabase` provider are the exception — they are
plumbing every later issue needs and are meaningless to defer.

### D6 — Seed one `Settings` row, currency `IDR`

`beforeOpen`, guarded on `details.wasCreated` so it seeds only a fresh database
(`drift.md`). The currency has to exist before any amount can be interpreted — an amount
column is an `int` of minor units and is meaningless without the exponent.

**`IDR` is the seed default** (exponent 0). The owner is Indonesian, the app is named
`uangsaku`, and `enums.md`'s worked examples are in rupiah. UC14 changes it; this is only
what a fresh install starts with.

### D9 — The Dart package lives in `app/`

**Added 2026-08-21**, owner's call, before any code landed. The root belongs to the
documentation pipeline; Flutter's `lib/` and `test/` are generic enough that mixing them
into that listing reads as clutter. Full reasoning in `decisions.md`.

**This silently broke CI, which is why it is a decision and not a detail.** The `app` job
is guarded on `pubspec.yaml` existing so it passes trivially until this issue lands one.
Guarding on a root path that will now never exist means the job reports success having run
nothing — permanently, and without a red build to notice. *A guard that succeeds when it
cannot find its subject is worse than one that fails: a red build gets fixed, a green one
gets trusted.* Fixed the same day — the probe reads `app/pubspec.yaml` and every Flutter
step carries `working-directory: app`.

Consequences already applied: `dart-and-flutter.md`'s layout, D2's manifest above, and
`map.yaml`'s future entries (`app/lib/src/<module>/`). `audit.py` is unaffected — it reads
documentation paths, none of which moved.

### D7 — What "done" means with no runnable target

There is no Android SDK on this machine, so **the app cannot be launched** (`tooling.md`).
That is expected and does not block this issue. Done is:

1. `dart run build_runner build --delete-conflicting-outputs` — succeeds.
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean, under `strict-casts` / `strict-inference` /
   `strict-raw-types`. A warning left in place is a decision, and gets argued here rather
   than ignored.
4. `flutter test` — green, against `NativeDatabase.memory()`.

The test asserts the database opens, `schemaVersion` is 1, all seven tables exist, and
exactly one `Settings` row was seeded with `Currency.IDR`.

**Install the Android SDK before UC14**, the first UI issue — not as part of this one.

### D8 — This issue turns CI on

`.github/workflows/ci.yml`'s `app` job is guarded on `pubspec.yaml` existing and has been
passing trivially. Landing a `pubspec.yaml` activates all six steps on the next push.

So the four commands in D7 must pass **before** the commit, not after. A first red build
on the commit that starts implementation is avoidable and worth avoiding. Expect the CI
Flutter version pin (`3.47.1`) to be the first thing that bites if the local SDK ever
drifts — `tooling.md` says bump both together, never one.

## Steps

1. ~~From the repository root:~~ **DONE 2026-08-21 by the owner. Do not re-run.**
   `flutter create --project-name uangsaku --org com.eldwinpr --platforms=android,ios app`

   Verified on disk: `app/pubspec.yaml` has `name: uangsaku`, `app/android/app/build.gradle.kts`
   has `applicationId = "com.eldwinpr.uangsaku"` and the matching `namespace`, and both
   `app/android/` and `app/ios/` exist. **`app/` is committed and pushed** (owner, 2026-08-21).

   *This plan previously said to keep `app/` untracked until step 10, because committing it
   would activate CI's `app` job and fail it on the missing `build_runner`. The owner
   committed it, CI failed exactly there, and the guard was fixed instead — `build_runner` is
   now gated on the dependency actually being present, so the scaffold builds green and CI
   does real work from now on rather than staying inert. The advice was right about the
   symptom and wrong about the cause.*

   Start at step 2.

   *Original step text, kept because its reasoning still applies to any re-scaffold:*

   Naming the target directory explicitly rather than `.` is deliberate — it makes the
   command independent of which directory the shell happens to be in. *This was run into
   `C:\Users\cg857` once already by a terminal opened in the wrong place, scattering
   twelve items across the home directory.*

   Putting the package in `app/` also removes a hazard the earlier root-level version of
   this step had to guard against: `flutter create` writes its own `.gitignore` and
   `README.md`, and at the root those would have collided with this repo's tuned
   `.gitignore` and its front-door README. Under `app/` they are simply the package's own
   files and are kept. Verify anyway — `git status` should show exactly one new untracked
   entry, `app/`, and nothing at the root.
2. Pin dependencies for real (`drift`, `drift_flutter`, `flutter_riverpod`,
   `riverpod_annotation`; dev: `build_runner`, `drift_dev`, `riverpod_generator`,
   `flutter_lints`). Use the Dart MCP server's `pub_dev_search` — this is the one moment
   `tooling.md` predicted it would be needed. **Correct `riverpod.md`'s version block to
   what actually resolved.**
3. `analysis_options.yaml`: `flutter_lints`, the three strict modes, and
   `invalid_annotation_target: ignore` (required by `riverpod_generator`, and there for no
   other reason). Exclude `**.g.dart`.
4. Write the seven table declarations against `erd.drawio`, one file per module. Every
   amount an `IntColumn`. **Read the ERD against the code before step 6, per D3.**
5. `app_database.dart`: `NativeDatabase.createInBackground`, `schemaVersion = 1`,
   `beforeOpen` seeding, and the `AppDatabase` Riverpod provider (`keepAlive: true` — it
   outlives every screen).
6. `build.yaml` with the drift schema output dir, then
   `dart run build_runner build --delete-conflicting-outputs`.
7. `dart run drift_dev make-migrations` — capture the v1 snapshot. **Commit the snapshots
   and the generated migration tests** (`drift.md`); they are the only artifact that proves
   a future migration preserves data.
8. `main.dart` + `app.dart`: `ProviderScope`, `MaterialApp`, placeholder screen.
9. The test in D7. Name it for what it defends, per `testing.md`.
10. Run all four D7 commands. Fix. Repeat until clean.
11. **Correct every conventions file this contradicted**, and say so in `pm/log.md`. The
    conventions are provisional until this issue runs; leaving a wrong one in place is the
    failure mode this issue exists to prevent.
12. Close per `CLAUDE.md`'s checklist — including `map.yaml`, which gains its first
    real entry (FEAT01 → `app/lib/src/database/`).

## Out of scope

- **Any screen, DAO, or provider beyond `AppDatabase`'s** — D5.
- **Renaming `moneytracker` → `uangsaku`** anywhere that already exists — D1.
- **Installing the Android SDK**, and anything needing a launched app — D7.
- **Anything iOS-specific.** `app/ios/` is generated and committed; it is not built,
  tested, signed, or covered by CI, and will not be until there is a Mac — D4.
- **Seed data beyond the one `Settings` row.** No demo accounts, no starter categories.
  UC13 creates categories; inventing a default vocabulary here would prejudge it.
- **`flutter_driver`.** `tooling.md` wants it behind a `--dart-define` so it cannot reach
  a production build; that belongs with the first UI issue that uses it.
- **Indexes and query tuning.** NFR-2 forbids stored balances and says to index if a query
  is slow — no query exists yet, so there is nothing to measure.
- **CI changes.** The workflow is already written and correct; this issue activates it, it
  does not edit it.

## Open questions for the owner

Neither blocks writing code, but both should be answered before this closes:

1. **Is `com.eldwinpr.uangsaku` the right application id?** It is the one identifier here
   that is genuinely expensive to change later.
2. **Does the `moneytracker` / `uangsaku` split bother you?** If one name should win
   everywhere, say so and it becomes its own issue rather than accumulating.

The two rulings already outstanding in `pm/active.json` — UC13's missing budget-group
classes, and whether `note` appears on the transfer / lend-borrow / repayment screens —
**do not gate this issue.** Both are about screens; FEAT01 builds none. `note` is a
nullable column on `Transactions` either way.
