# UC14-choose-currency — Choose the app currency

**Status:** **HALTED — awaiting owner ruling.** Everything below D1–D8 is derived from
already-confirmed artifacts and is ready to build. **D9 is not**: the sequence diagram's
`opt` guard names a distinction — *"an existing currency is being changed, not initial
setup"* — that no artifact defines and the schema cannot express. Three different, equally
plausible predicates satisfy it, they produce different behaviour, and none can be cited.
Under the unattended-mode rule in `context/general-rules.md` that halts the issue rather
than picking a default. The question is `Q1` in [`pm/questions.md`](../../questions.md).

**This plan is kept in place deliberately** so the derivation is not repeated when the
answer arrives. When Q1 is answered, D9 gets written from the answer, the status becomes
`AUTO-CONFIRMED` (or `PROPOSED` if the owner is present), and steps 1–11 run unchanged —
only step 6 depends on Q1.

**Traces to:** UC-14 (`docs/workbook.xlsx`, `UC FR`) — FR-19.
**Depends on:** `FEAT01-foundation` — **DONE 2026-08-21** (`pm/tracker.yaml`).
**Preflight: PASSES.** The one declared dependency is Done, and no other issue is active
(`pm/active.json` names this one). No scope overlap: `Settings` is the only table this
issue touches, it is the only module UC-14 owns (`map.yaml`, `entities.Settings`), and the
two other issues that could run in parallel — UC13 and UC11 — own `Categories`/
`Subcategories` and `BudgetGroups`/`BudgetPeriods` respectively.

## Goal

The first screen, the first DAO and the first Notifier in the app. At the end, the owner
can open the app, see which currency the database is recording in, and change it between
`IDR` and `USD`; the change is written to the one `Settings` row and pushed back to the
screen as a new stream emission rather than as the write's return value. Existing amounts
are re-labelled, never converted, and the change is never refused.

Nothing in the accounts, transactions or budgeting modules is touched. The reason this
use case is built first despite being last in the workbook is that it is the smallest
module in the project and still exercises the whole
`Screen → provider → DAO → AppDatabase → table` chain the four class diagrams draw — so if
that architecture is wrong, this is the cheapest place to find out (`pm/tracker.yaml`,
this issue's row). It is also the issue `context/coding-conventions/README.md` names as
the one that tests the still-unverified half of the conventions.

## Scope: the sequence diagram, reconciled

`docs/diagrams/seq-uc14-choose-currency.drawio`, rendered at
`pm/issues/uc14-choose-currency/seq-uc14-choose-currency.png` (read at full size while
writing this plan, per `lessons.md` §3/§4 — the labels live on `<UserObject label=…>`
wrappers, not on `mxCell value=`). `CLAUDE.md` makes this diagram the scope boundary:
nothing outside it is in scope, nothing in it may be skipped.

**Six lifelines, and every one is already a class on a class diagram** — the hard rule in
`sequence-conventions.md`. All five non-actor lifelines are on
`docs/diagrams/class-settings.drawio`:

| Lifeline | On the class diagram as | Band |
|---|---|---|
| `Owner` | the actor (the only one in this project) | — |
| `CurrencyScreen` | `CurrencyScreen` · UC-14 · `ConsumerWidget` | Screen |
| `currencyProvider` | `currencyProvider` · `StreamProvider` · the current currency | Provider |
| `SettingsNotifier` | `SettingsNotifier` · Notifier, exposed as `settingsProvider` · `setCurrency()` | Provider |
| `SettingsDao` | `SettingsDao` · the one settings row · `watchCurrency()`, `setCurrency()` | DAO |
| `AppDatabase` | `AppDatabase` · shared by all four modules | Database |

**No lifeline is missing and none is invented.** Nothing here needs a class the diagrams
do not have.

**The fifteen messages, and what each one commits this issue to:**

- **1** `Owner → CurrencyScreen` *open currency setting* — the screen has to be reachable
  (D3).
- **2** `CurrencyScreen → currencyProvider` *watch()* — the screen is a `ConsumerWidget`
  watching a provider, not holding state.
- **3** `currencyProvider → SettingsDao` *watchCurrency()*.
- **4–5** `SettingsDao ⇄ AppDatabase` *query settings row* / *row* — **the isolate
  boundary**, per the diagram's own note.
- **6** `SettingsDao ⇢ currencyProvider` *Stream\<Currency\>*.
- **7** `currencyProvider ⇢ CurrencyScreen` *Currency (first emission)* — the screen
  renders the stream, nothing else.
- **8** `Owner → CurrencyScreen` *pilih IDR / USD* — the choice, two values only.
- **9** the `opt` fragment — *warning: existing amounts are re-labelled, not converted
  (FR-19, NFR-4 zero refusals)*, guarded on *[[an existing currency is being changed, not
  initial setup]]*. **This guard is what halts the issue — see D9.**
- **10** `CurrencyScreen → SettingsNotifier` *setCurrency(chosen)* — **unconditional**: it
  sits outside the `opt` box, so the write happens whether or not the warning was shown.
  There is no second operand, no cancel path, and no return arrow to the owner. The
  warning is a message, not a branch that ends (`pm/tracker.yaml`, this issue's row).
- **11** `SettingsNotifier → SettingsDao` *setCurrency(chosen)*.
- **12–13** `SettingsDao ⇄ AppDatabase` *update settings row* / *ok*.
- **14** `SettingsDao ⇢ SettingsNotifier` *ok*.
- **15** `currencyProvider ⇢ CurrencyScreen` *Currency (updated emission)* — **the result
  arrives on the read path.** Note there is deliberately no reply from `SettingsNotifier`
  back to `CurrencyScreen`: the screen updates because drift pushes the changed row into
  the stream it is already watching (`sequence-conventions.md`; `riverpod.md`, "the rule
  that is easiest to get wrong").

**Two as-built discrepancies found on the diagram.** Neither blocks the work; both are for
the close checklist's as-built pass, not for silent correction now:

1. The diagram's note reads *"NativeDatabase.createInBackground, decided 2026-08-20"*. The
   code opens the database through `drift_flutter`'s `driftDatabase()`, which calls
   `NativeDatabase.createBackgroundConnection` — the same isolate guarantee, verified in
   the package source (`decisions.md`, 2026-08-21, FEAT01 ruling 2). The boundary the note
   marks is real and in the right place; only the mechanism's name is one wrapper stale.
2. Message 8 is labelled **`pilih IDR / USD`** — Indonesian. `context/general-rules.md`
   fixes this project's language as English and says so on provenance grounds. Every other
   label on the diagram is English.

## Decisions

Each entry cites the confirmed artifact it comes from. **D1–D8 are transcriptions; D9 is
not, and that is why this plan is halted.**

### D1 — The three new files, and nothing else

*Cites:* `context/coding-conventions/dart-and-flutter.md` §Directory layout (which fixes
one file per class-diagram band and names `<module>_dao.dart`,
`<module>_providers.dart`, `<name>_screen.dart`); `decisions.md` 2026-08-21 (the package
lives in `app/`); `class-settings.drawio` for which classes exist.

```
app/lib/src/settings/settings_dao.dart          SettingsDao — watchCurrency(), setCurrency()
app/lib/src/settings/settings_providers.dart    currencyProvider (StreamProvider),
                                                SettingsNotifier (exposed as settingsProvider)
app/lib/src/settings/currency_screen.dart       CurrencyScreen (ConsumerWidget)
```

Modified, not created: `app/lib/src/app.dart` (D3), `app/lib/src/database/app_database.dart`
(registering the DAO under `@DriftDatabase(daos: […])`, which is how drift attaches one).
`app/lib/src/settings/settings_table.dart` is **not** modified — the table and the
`Currency` enum already exist exactly as the class diagram draws them.

Tests, mirroring `lib/src/` per `testing.md` §Conventions:
`app/test/settings/settings_dao_test.dart`, `app/test/settings/currency_screen_test.dart`.

A file outside this list is out of scope. Adding one is a conversation, not a judgement
call (the shape FEAT01 D2 used).

### D2 — Class and method names come from the class diagram verbatim

*Cites:* `context/coding-conventions/README.md`, "the rule that outranks the rest";
`class-settings.drawio`.

`SettingsDao` with exactly `watchCurrency()` and `setCurrency()`. `SettingsNotifier` with
exactly `setCurrency()`, exposed as `settingsProvider`. `currencyProvider` as a
`StreamProvider`. `CurrencyScreen` as a `ConsumerWidget`. No extra public method on any of
them: a method the class diagram does not draw is a diagram change, not a code decision.

`watchCurrency()` returns `Stream<Currency>` (message 6 names the type). `setCurrency()`
returns `Future<void>` — `drift.md` §DAOs, "writes return `Future<void>` unless the caller
genuinely needs the new id", and message 14's reply is an acknowledgement, not a value the
screen renders.

### D3 — `CurrencyScreen` becomes what `app.dart` shows, replacing FEAT01's placeholder

*Cites:* FEAT01 D2 (`app.dart` renders "a placeholder screen") and FEAT01 D5 / its Goal
("the first screen belongs to UC14"); the sequence diagram, message 1.

Message 1 requires the owner to be able to open this screen. The diagram draws **no
navigation lifeline** — no home shell, no settings menu, no route table — and no class
diagram has one. So the only way to satisfy message 1 without inventing a class the
diagrams lack (forbidden by `coding-conventions/README.md`) is for `MaterialApp.home` to
be `CurrencyScreen`. This is a forced derivation, not a preference.

It is explicitly temporary. `UC01-balance-sheet` lands FR-1's four figures on **"the
primary screen"** (`pm/tracker.yaml`, UC01's row), and re-pointing `home` is that issue's
business. This issue introduces no router and no navigation structure.

### D4 — The screen offers exactly two values, both always enabled

*Cites:* `docs/enums.md` §`Settings.currency` (two values, `IDR` and `USD`, and adding a
third is "an enum value plus a migration", i.e. not a user-facing option); FR-19 ("one
currency for the whole app — `IDR` or `USD`"); NFR-4's fit criterion of zero refusals.

Both options are selectable at all times, including the one currently in force. Nothing on
this screen is ever disabled, greyed, or hidden — `riverpod.md` §No refusals: *"a screen
does not disable a control to prevent an action"*, and `testing.md` calls a disabled button
the likeliest accidental violation in the app.

The concrete widget used to present two mutually-exclusive values is presentation, not a
decision needing an artifact (`pm/questions.md`, "what does not belong here"). The
constraint that binds is the paragraph above.

### D5 — The warning is a dialog that continues; there is no cancel

*Cites:* the sequence diagram — message 10 sits **outside** the `opt` box, the `opt` has
one operand, and nothing returns the owner to the screen unchanged; `riverpod.md` §No
refusals ("the app **warns and proceeds**. The warning is a dialog that continues, never a
block"); FR-19 ("the app says so plainly at the moment I would cause it, and then does as
it is told"); NFR-4.

The warning states that existing amounts are re-labelled and not converted — 50,000
recorded as IDR reads as 50,000 USD (`enums.md`, the class diagram's own note). It is
acknowledged and the write proceeds. Adding a "Cancel" that abandons the change would be a
second operand the diagram does not draw.

**What is *not* decided here is when it fires.** That is D9.

### D6 — Nothing is converted, and no other table is read or written

*Cites:* FR-19 ("there is no per-account currency, no conversion, and no exchange rate
anywhere"); `decisions.md` 2026-08-20 (one app-level currency); `enums.md` ("changing the
value re-labels, it does not convert"); the sequence diagram, whose only database messages
are *query settings row* and *update settings row*.

`setCurrency()` writes one column of one row. It does not touch `Account.opening_amount`,
`Transaction.amount` or `Budget_Period.amount`, and it does not scale, migrate or rewrite
any stored integer. `lessons.md` §2 is the reason this is stated rather than assumed:
changing how a value is obtained silently invalidates what is built on it — here the
invalidation is deliberate, confirmed, and the exact thing the warning exists to announce.

### D7 — `currencyProvider` is kept alive; `SettingsNotifier` is not special-cased

*Cites:* `riverpod.md` §Code generation — *"a provider whose state must outlive its screen
has to say so explicitly (`@Riverpod(keepAlive: true)`). **Expect to need that for the
currency setting and almost nothing else.**"*; `riverpod.md` §The two shapes.

`currencyProvider` is `@Riverpod(keepAlive: true)` — every amount displayed anywhere in
the app will eventually need the exponent, so it must not dispose when this screen closes.
`SettingsNotifier` is an ordinary generated `Notifier` exposed as `settingsProvider`, the
write shape the conventions allow. No third provider shape is introduced; the existing
hand-written `appDatabaseProvider` is reused as-is (`decisions.md` 2026-08-21, FEAT01
ruling 3).

### D8 — "Done" without a runnable app, and what the tests must assert

*Cites:* FEAT01 D7 (the same four commands, and the same reason — no Android SDK on this
machine); `testing.md` §Layers, §Two requirements that need explicit tests, §Running;
`decisions.md` 2026-08-21 (`app/ios/` cannot be built, no Mac).

**The app still cannot be launched or looked at.** `flutter test` is headless and needs no
Android SDK, and `testing.md` puts the correctness surface there. Nothing in this issue's
definition of done requires a running app, an emulator, or an installed Android SDK — if a
step ever seems to, that is a scope error, not a reason to install one.

Done is all four green, run from `app/`:

1. `dart run build_runner build` — succeeds. (`--delete-conflicting-outputs` was removed in
   `build_runner` 2.16 and is now ignored with a warning — `testing.md`, corrected at
   FEAT01.)
2. `dart format --set-exit-if-changed .` — clean.
3. `flutter analyze` — clean under `strict-casts` / `strict-inference` / `strict-raw-types`.
   A warning left in place is a decision and gets argued here, not ignored.
4. `flutter test` — green, against `NativeDatabase.memory()`, no mocking of drift.

Tests to add, each named for the requirement it defends (`testing.md`):

- **DAO** — `watchCurrency()` emits the seeded `Currency.IDR` on a fresh in-memory
  database; `setCurrency(Currency.USD)` causes a second emission on the *same* stream
  (this is the assertion that proves message 15 — the read path — actually works, and it
  is the single most valuable test in this issue because the whole architecture rests on
  it); the `Settings` table still holds exactly one row afterwards.
- **NFR-4, widget** — with amounts already in the database (rows inserted directly, not
  through a UI this issue does not build), the screen's currency controls are **enabled**,
  choosing the other currency proceeds, and the stored value changes. This is the test
  `testing.md` names explicitly: *"changing the currency after amounts exist"*.
- **Widget** — the screen renders whatever `currencyProvider` is overridden to emit, via a
  `ProviderContainer`/`ProviderScope` override over an in-memory database.

FR-18's edit/delete test does not apply: `Settings` is a single seeded row with no create
and no delete on any artifact, and no screen offers either.

### D9 — **OPEN. This is the halt.** What makes the warning in message 9 fire?

*No citation exists.* The `opt` guard reads *[[an existing currency is being changed, not
initial setup]]*, and nothing in the confirmed artifact set says how code decides that.

**What was checked, and what each failed to say:**

- **`docs/fr-nfr.md` FR-19** distinguishes "chosen at setup" from "*I can change it later,
  and the app will not stop me*", and attaches the warning to *"the moment I would cause
  it"* — the moment existing amounts would be re-labelled. It does not say how the app
  recognises that moment.
- **The workbook UC-14 row** repeats the same split — *"Owner opens the currency setting,
  at first setup or any time after"* — without defining either side.
- **`docs/enums.md`** and **`class-settings.drawio`** both say changing the value
  re-labels and the app warns and proceeds. Neither gives a trigger.
- **`docs/diagrams/erd.drawio`** and the built table
  (`app/lib/src/settings/settings_table.dart`): `Settings` has exactly two columns,
  `settings_id` and `currency`. **There is no "setup complete" marker and no timestamp**,
  so the distinction the guard names cannot be read from the database at all.
- **FEAT01 D6** seeds one `Settings` row at `Currency.IDR` on a fresh database. So a
  currency value *always exists* from first launch — which means "an existing currency is
  being changed" is, read literally, true on every launch, and the guard's own carve-out
  has nothing to attach to.
- **`decisions.md`** (2026-08-20, one app-level currency) and **`docs/statuses.md`** (no
  status values for any entity, deliberately) — neither addresses it.

**Three predicates fit the guard, they behave differently, and nothing selects between
them:**

| | Predicate | Cost / consequence |
|---|---|---|
| **A** | `chosen != currently stored` | Free — the screen already holds the current value from message 7. Warns once at first setup if the owner picks USD over the IDR seed, which the guard says it should not. |
| **B** | any amount exists in the database | Truthful to the warning's own words, but needs `SettingsDao` to count rows in `Transactions` / `Accounts` / `BudgetPeriods`. That join is permitted (ISSUE-005 D1) but is **not on this sequence diagram** — adding it means widening the scope boundary `CLAUDE.md` makes absolute. |
| **C** | always warn on any selection | Simplest; drops the `opt` guard entirely, i.e. skips part of the diagram, which `CLAUDE.md` forbids without going back to the owner. |

All three obey NFR-4 — none refuses anything — so the fit criterion does not choose either.
A fourth option, adding a "setup done" column, is a schema change: `schemaVersion` 2, a new
snapshot and migration, plus the ERD, the class diagram and `map.yaml` going stale with it
(`lessons.md` §8 — the last "just one column" cost twelve artifacts). Raised here rather
than after the work, per `lessons.md` §7.

**This is why the issue is halted rather than planned around a default.** Q1 in
`pm/questions.md`.

## Steps

Executable in this order once Q1 is answered. **Step 6 is the only one that depends on the
answer**; 1–5 and 7–11 are already fully determined and could run first if the owner
prefers to unblock the chain in two passes.

1. Write `settings_dao.dart`: `SettingsDao` as a drift `DatabaseAccessor` over
   `AppDatabase` with `@DriftAccessor(tables: [Settings])`. `watchCurrency()` watches the
   single settings row and maps it to `Currency`; `setCurrency(Currency)` updates that
   row's `currency` column and returns `Future<void>`. Names per D2.
2. Register the accessor on `AppDatabase` (`@DriftDatabase(… daos: [SettingsDao])`) and
   re-run the generator. This is the only edit to `app_database.dart` — the schema does
   not change, so `schemaVersion` stays 1 and no new migration snapshot is produced.
3. Write `settings_providers.dart`: `currencyProvider` as a `@Riverpod(keepAlive: true)`
   `StreamProvider` over `watchCurrency()`, and `SettingsNotifier` (exposed as
   `settingsProvider`) whose `setCurrency()` calls the DAO and returns nothing to the
   screen (D2, D7; `riverpod.md`).
4. Write `currency_screen.dart`: `CurrencyScreen` as a `ConsumerWidget` watching
   `currencyProvider`, rendering the two values with both always enabled (D4), and firing
   `ref.read(settingsProvider.notifier).setCurrency(chosen)` on selection — fire and
   forget, never rendering the write's return (D2, `riverpod.md`).
5. Point `app.dart`'s `home` at `CurrencyScreen`, removing FEAT01's placeholder (D3).
6. **Blocked on Q1.** Implement the message-9 warning with the predicate the owner rules
   on, as a dialog that is acknowledged and proceeds (D5).
7. Write the three tests in D8, each named for the requirement it defends.
8. Run all four D8 commands from `app/`. Fix, repeat until clean. Run them **before** the
   commit, not after — CI runs all five steps on every push since FEAT01 landed
   (`testing.md`), and a first red build on this commit is avoidable.
9. **Correct every conventions file this contradicted.** This issue is the first to write a
   DAO, a Notifier, a screen and a widget test, and `context/coding-conventions/README.md`
   names it by id as the issue that tests the unverified half. Anything that fights the
   real toolchain loses; the file gets corrected in place and `pm/log.md` says so.
10. **Split the README's provisional banner again** rather than deleting it whole. After
    this issue, the DAO, provider, screen and widget-test claims are verified; anything
    still untested (the cross-module join, the derived-figure queries) is not.
    `lessons.md` §1: *a half-true label is the most durable version of this failure* — and
    that banner has already been caught being half true once.
11. Close per `CLAUDE.md`'s checklist. Named explicitly because `lessons.md` §1 is about
    registers nobody remembers to update:
    - **As-built pass** on `seq-uc14-choose-currency.drawio` — including the two
      discrepancies listed under *Scope* above (`createInBackground` vs
      `driftDatabase()`/`createBackgroundConnection`, and the Indonesian `pilih` label).
      Re-export and look at the render; do not edit XML and call it done (`lessons.md` §3).
    - **`context/index/map.yaml`** — a `UC-14 → app/lib/src/settings/` entry under `code:`,
      in the shape FEAT01's entry uses.
    - **`context/index/decisions.md`** — only if the toolchain forced a durable ruling, as
      it did three times in FEAT01. Not a formality; not an obligation either.
    - **`docs/workbook.xlsx`** UC-14 marked implemented (`general-rules.md`, definition of
      done, step 4).
    - **`pm/tracker.yaml`** → Done with a one-line summary; **`pm/log.md`** → a dated
      entry plus the current-state block at its head; **`pm/active.json`** → the next
      issue.
    - **`pm/questions.md`** → Q1 marked ANSWERED with a pointer to where the answer landed
      permanently.

## Out of scope

- **Every other module.** No `AccountDao`, `TransactionDao`, `CategoryDao` or `BudgetDao`,
  no accounts/transactions/budgeting provider, no screen but `CurrencyScreen`. Those
  tables exist since FEAT01 and this issue neither reads nor writes them (D6).
- **Converting, rescaling or migrating stored amounts.** FR-19 forbids conversion outright.
  A currency change re-labels; that is the whole point and the reason the warning exists.
- **Formatting amounts for display using the exponent.** `enums.md` makes the exponent the
  point of the enum, but the first screen that *renders money* is UC-01's balance sheet.
  Nothing on `CurrencyScreen` displays an amount, so a shared formatter here would be
  written against no caller. It belongs to UC01; flagging it so it is not forgotten.
- **A third currency.** `CNY` was asked about and is an enum value plus a migration
  (`enums.md`), deliberately a code change and not a user-editable table.
- **Per-account or per-transaction currency.** Asked for and withdrawn 2026-08-20 with the
  cost on the table (`decisions.md`); not foreclosed, but it is a schema change and its
  own issue.
- **Routing, navigation, a settings hub, or an app shell.** D3 points `home` at this screen
  and introduces nothing else. The primary screen is UC01's.
- **Making `home` permanent.** UC01 re-points it; this issue does not build an abstraction
  to make that easy.
- **Any `Settings` row beyond the seeded one** — no create, no delete, no second row. The
  table is single-row by design on the ERD and the class diagram.
- **Theme, locale, language switching, or any other setting.** `Settings` has exactly two
  columns. A second setting is a schema change and needs its own FR.
- **Installing the Android SDK, launching the app, or any visual check of the screen.**
  D8. If the owner wants the screen looked at, that is an SDK install and a separate
  session, not a step here.
- **Anything iOS.** `app/ios/` stays versioned and uncompiled until there is a Mac
  (`decisions.md`, 2026-08-21).
- **Fixing `pm/findings.md` F1** (the table-existence test reads drift's declared
  `allTables` rather than the SQLite schema). Recorded, not fixed; a finding is not an
  issue, per the run's own rule.
- **Editing the sequence diagram now.** The two discrepancies found above are reconciled in
  the as-built pass at close (step 11), not mid-flight.

## Open questions

**Blocking — this issue cannot be built past step 5 until it is answered:**

- **Q1 — what makes the currency-change warning fire?** Full statement, options and costs
  in `pm/questions.md`. Summarised in D9 above.

**Not blocking:**

- The two questions FEAT01 left for the owner — whether `com.eldwinpr.uangsaku` is the
  right application id, and whether the `moneytracker` / `uangsaku` split should be
  resolved — are still unanswered and still do not gate anything here. This issue renames
  nothing.
- Whether the sequence diagram's `pilih` label and its `createInBackground` note should be
  corrected as part of this issue's as-built pass or left for the repo-wide sweep. Step 11
  assumes the former, which is what `CLAUDE.md`'s close checklist says; raising it only
  because the diagram is otherwise confirmed and untouched.
