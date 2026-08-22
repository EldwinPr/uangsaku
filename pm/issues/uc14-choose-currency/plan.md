# UC14-choose-currency — Choose the app currency

**Status:** DONE 2026-08-22 — built, reviewed, closed and committed. Halted 2026-08-21 at the planning gate; unhalted when the owner answered Q1. The as-built pass corrected three items on the sequence diagram (the `opt` guard, the Indonesian label, the isolate note).
an artifact the owner has already confirmed, and D9 — the one that halted this plan on
2026-08-21 — now cites the owner's own ruling on `pm/questions.md` Q1, recorded at
`context/index/decisions.md` (2026-08-22, *"Changing the currency changes the prefix and
nothing else"*).

**Three decisions changed while this plan sat halted, and are amended in place rather than
rewritten** (the FEAT01 D4 shape — what it used to say, what changed, why): **D1** and
**D7** against the two rulings UC-13 forced on DAO and provider shape, and **D9** from
`HALTED` to decided. **D5 and D6 were re-checked against the currency ruling and stand
exactly as written** — the ruling strengthens both rather than disturbing them; see the
confirmation notes under each. D2, D3, D4 and D8 are unchanged in substance, D8 gaining one
test that D9 now makes assertable.

Steps 1–11 run in order. Nothing is blocked.

**Traces to:** UC-14 (`docs/workbook.xlsx`, `UC FR`) — FR-19.
**Depends on:** `FEAT01-foundation` — **DONE 2026-08-21** (`pm/tracker.yaml`).
**Preflight: PASSES.** The one declared dependency is Done, and no other issue is active
(`pm/active.json` names this one). No scope overlap: `Settings` is the only table this
issue touches, it is the only module UC-14 owns (`map.yaml`, `entities.Settings`), and the
two other issues that could run in parallel — UC13 and UC11 — own `Categories`/
`Subcategories` and `BudgetGroups`/`BudgetPeriods` respectively.

## Goal

The settings module end to end. At the end, the owner
can open the app, see which currency the database is recording in, and change it between
`IDR` and `USD`; the change is written to the one `Settings` row and pushed back to the
screen as a new stream emission rather than as the write's return value. Existing amounts
are re-labelled, never converted, and the change is never refused.

Nothing in the accounts, transactions or budgeting modules is touched.

*(Written 2026-08-21, when this was to be the first screen, DAO and provider in the app.
It no longer is: UC-13 and UC-11 shipped while this issue was halted, and their toolchain
rulings now bind it — see D1 and D7. What survives unchanged is the reason it was
sequenced first.)* The reason this use case is scheduled ahead of the rest despite being
last in the workbook is that it is the smallest module in the project and still exercises
the whole
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
  initial setup]]*. **That guard text is stale and resolves to [[the chosen currency
  differs from the stored one]]** — the owner's ruling of 2026-08-22, D9. It is corrected
  on the diagram at the as-built pass (discrepancy 3 below), not here.
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

**Three as-built discrepancies on the diagram.** None blocks the work; all three are for
the close checklist's as-built pass, not for silent correction now. **They are recorded
here, not fixed here** — the main session owns `.drawio` edits:

1. The diagram's note reads *"NativeDatabase.createInBackground, decided 2026-08-20"*. The
   code opens the database through `drift_flutter`'s `driftDatabase()`, which calls
   `NativeDatabase.createBackgroundConnection` — the same isolate guarantee, verified in
   the package source (`decisions.md`, 2026-08-21, FEAT01 ruling 2). The boundary the note
   marks is real and in the right place; only the mechanism's name is one wrapper stale.
   Already filed repo-wide as **`pm/findings.md` F3** (twelve of the fourteen `seq-uc*`
   diagrams carry the same note), so UC-14's as-built pass records it against F3 rather
   than re-discovering it; fixing fourteen diagrams is not this issue's business.
2. Message 8 is labelled **`pilih IDR / USD`** — Indonesian. `context/general-rules.md`
   fixes this project's language as English and says so on provenance grounds. Every other
   label on the diagram is English.
3. **The `opt` guard text itself.** It reads *"an existing currency is being changed, not
   initial setup"*, a predicate the schema cannot express and which the owner's 2026-08-22
   ruling has now resolved to **[[the chosen currency differs from the stored one]]**
   (D9). The fragment stays, message 9 stays inside it, message 10 stays outside it, and
   nothing is skipped — only the guard's text is corrected, and `decisions.md` 2026-08-22
   says explicitly that it is corrected *"at UC-14's as-built pass rather than
   reinterpreted silently"*. Code is written against the resolved predicate from step 6;
   the diagram catches up at close.

## Decisions

Each entry cites the confirmed artifact it comes from. **All nine are transcriptions** —
D1–D8 of the requirements, diagrams and conventions; D9 of the owner's ruling of
2026-08-22. Nothing below is a default chosen by the planner.

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

**Amended 2026-08-22.** This entry used to list `app/lib/src/database/app_database.dart`
as modified, "registering the DAO under `@DriftDatabase(daos: […])`, which is how drift
attaches one". **It is no longer modified at all.** `decisions.md` 2026-08-21 (UC-13
ruling 1) settles that a DAO is a plain class composing `AppDatabase`, never a
`@DriftAccessor`/`DatabaseAccessor` subtype — `DatabaseAccessor` already declares
`update()` and `delete()`, which the class diagrams give the DAOs themselves, and the
override is an outright analyzer error. The consequence stated in that ruling: **no
`daos: […]` entry**, because there is no accessor for drift to attach. `app_database.dart`'s
own doc comment already records this, and `CategoryDao` / `BudgetDao` shipped that way.
`SettingsDao` follows the same shape even though `watchCurrency()` / `setCurrency()` would
not themselves have collided — the ruling is stated for every DAO, not only the colliding
ones.

So the only modified file is `app/lib/src/app.dart` (D3).
`app/lib/src/settings/settings_table.dart` is **not** modified — the table and the
`Currency` enum already exist exactly as the class diagram draws them. The schema does not
change: `schemaVersion` stays 1 and no new migration snapshot is produced.

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

**Kept as written, with its cost now named (2026-08-22).** `home` currently points at
`SetBudgetScreen` (UC-11 D8), which itself displaced `CategoryManagerScreen`. Pointing it
here **orphans `SetBudgetScreen`** — no route, no reference from any live widget, exercised
only by its tests. That is not new and not a reason to deviate: it is `pm/findings.md`
**F8**, *"every screen issue orphans the previous screen"*, already filed against this exact
pattern and explicitly predicting UC-01/02/03/04/09/12 each doing the same. The alternative
— inventing a navigation host — needs a class no class diagram draws, which
`coding-conventions/README.md` forbids. So this issue continues the pattern knowingly, and
the close **records the new orphan against F8 rather than re-discovering it** (step 11). A
navigation host is its own issue, not a tidy-up here.

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

**Re-checked against the 2026-08-22 ruling and CONFIRMED unchanged.** The ruling strengthens
this decision rather than disturbing it, and says so in its own words: *"this is the reason
NFR-4's zero refusals costs nothing here. There is no data-loss scenario to protect the
owner from, so the notice is a message and never a branch that ends."* A cancel path would
exist to protect stored data; under the ruling no stored data is at risk — the integers do
not move — so the thing a cancel would protect does not exist. The shape stays: one operand,
acknowledged, proceeds, and message 10 fires either way.

**When it fires is D9, and D9 is now decided.**

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

**Re-checked against the 2026-08-22 ruling and CONFIRMED, with one clarification the ruling
adds.** *Also cites:* `decisions.md` 2026-08-22 — *"the stored values are untouched: every
amount is an `int` of minor units and stays exactly the integer it was… IDR 250000 becomes
USD 250000 shown with a different prefix, not USD 15."* The clarification concerns the
**exponent**: `enums.md` gives IDR 0 and USD 2, and it would be an easy misreading to treat
a change of exponent as arithmetic on stored values. It is not. The ruling puts the exponent
on **rendering, not storage** — it changes how a stored `int` becomes text — so **no
exponent arithmetic runs at the moment of the change**, and none runs anywhere in this
issue, because nothing on `CurrencyScreen` renders an amount (see Out of scope; the
formatter is UC-01's). This issue writes one enum column and reads it back. Nothing else.

### D7 — `currencyProvider` is kept alive; `SettingsNotifier` is not special-cased

*Cites:* `riverpod.md` §Code generation — *"a provider whose state must outlive its screen
has to say so explicitly. **Expect to need that for the currency setting and almost nothing
else.**"*; `riverpod.md` §The two shapes; `decisions.md` 2026-08-21 (UC-13 ruling 2, and
FEAT01 ruling 3); `decisions.md` 2026-08-22 (UC-11, the multi-stream shape);
`class-settings.drawio` for both provider names.

**The substance is unchanged: `currencyProvider` outlives this screen.** Every amount
displayed anywhere in the app will eventually need the exponent, so it must not dispose when
`CurrencyScreen` closes — it is the one provider `riverpod.md` names for this.

**Amended 2026-08-22 — how that is expressed.** This entry used to say `currencyProvider` is
`@Riverpod(keepAlive: true)` and that `SettingsNotifier` is "an ordinary generated
`Notifier`". **Neither is buildable.** `decisions.md` 2026-08-21, UC-13 ruling 2:
`riverpod_generator` throws `InvalidTypeException` on any provider whose type mentions a
drift-generated row class, and hand-written providers are the shape every provider in this
app has shipped with. So both are **hand-written**: `currencyProvider` a plain
`StreamProvider<Currency>` declared **without `.autoDispose`**, which is how a hand-written
provider says "kept alive" — the same property FEAT01 ruling 3 verified for
`appDatabaseProvider` (`isAutoDispose` defaults to `false` in riverpod 3.4.2). The contrast
with the shipped `categoryTreeProvider` / `budgetProvider`, which *are* `.autoDispose`, is
deliberate: omitting it here is the whole of `keepAlive`. `SettingsNotifier` is a
hand-written `NotifierProvider` exposed as `settingsProvider`, which keeps the class
diagram's name exactly (the `categoriesProvider` precedent, same ruling).

**The UC-11 multi-stream ruling does not apply here — checked, not assumed.**
`decisions.md` 2026-08-22 replaces `StreamNotifier` with a hand-subscribing
`Notifier<AsyncValue<…>>` **for a screen that reads more than one drift stream**.
`CurrencyScreen` reads exactly one (message 3, `watchCurrency()`), and that same ruling
records that "a `StreamNotifierProvider` wrapping a *single* drift stream closes cleanly".
A plain `StreamProvider` over one stream is the read shape `riverpod.md` prescribes and the
one the class diagram draws. No third provider shape is introduced; `appDatabaseProvider` is
reused as-is.

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
- **The guard, widget** *(added 2026-08-22, once D9 made it assertable)* — choosing the
  currency **already stored** shows no notice and the stored value is unchanged; choosing
  the **other** currency shows the notice, and acknowledging it leaves the other currency
  stored. This is the test that pins D9's predicate, and it is deliberately paired with the
  NFR-4 test above so that "warns" and "never refuses" are asserted by different tests
  rather than one doing double duty.

FR-18's edit/delete test does not apply: `Settings` is a single seeded row with no create
and no delete on any artifact, and no screen offers either.

### D9 — The notice fires when the chosen currency differs from the stored one

*Cites:* the **owner's ruling of 2026-08-22** answering `pm/questions.md` Q1 — *"for q1 by
change currency it just changes the prefix thats all"* — recorded permanently at
`context/index/decisions.md`, 2026-08-22, *"Changing the currency changes the prefix and
nothing else"*. Also `enums.md` (IDR exponent 0, USD exponent 2) for what "the prefix"
covers, and the sequence diagram for the fragment this resolves.

**Revised 2026-08-22 — this entry previously read "OPEN. This is the halt."** and set out
three predicates (A: chosen ≠ stored; B: any amount exists; C: always warn) plus a fourth
option (a "setup complete" column), with the note that nothing in the confirmed artifact
set selected between them. That derivation is preserved in `pm/questions.md` Q1 and is not
repeated here. The owner's answer does not pick from the menu — **it dissolves the
question**, by settling what changing the currency *does*.

**The guard resolves to `opt [the chosen currency differs from the stored one]`.**

**Why that follows from the ruling, in the ruling's own terms:**

- The change is a **re-label**. Stored `int` minor units are untouched, nothing is
  converted, no rate applies, no other table is read or written, and the exponent moves the
  *rendering*, not the storage (D6). So the moment worth announcing is exactly the moment
  the prefix changes — which is precisely `chosen != stored`.
- **The `opt`'s "not initial setup" carve-out has no referent.** It was written when the
  change was imagined to be consequential. `decisions.md` 2026-08-22 states this directly,
  and FEAT01 D6 is why it never had one anyway: a currency exists from first launch, so
  "an existing currency is being changed" is literally true every time.
- **The one cost the old option A carried is gone.** A was priced at "one wrong warning at
  first setup if the owner picks USD over the IDR seed". Under the ruling that warning is
  **true, not spurious** — the prefix really does change — so the cost was a cost of the
  old reading, not of the predicate.

**What the ruling rejects, recorded so it is not re-proposed:** a `Settings.setup_complete`
column (option D — `schemaVersion` 2, a new snapshot and migration, plus the ERD,
`class-settings.drawio` and `map.yaml` going stale with it, for a distinction that changes
nothing — `lessons.md` §8), and counting amounts across `Transactions` / `Accounts` /
`BudgetPeriods` (option B — a cross-module join bought for nothing, and not drawn on this
sequence diagram).

**Nothing on the diagram is skipped.** The `opt` fragment stays, message 9 stays inside it,
message 10 stays outside it and fires either way (D5). Only the guard's *text* is stale,
and it is corrected at the as-built pass, not reinterpreted silently — `decisions.md`
2026-08-22 says so explicitly. It is item 3 of the three as-built discrepancies under
*Scope*.

**What it costs to build: nothing.** The screen already holds the stored value from
message 7, so the predicate is a comparison in the widget. No new query, no new column, no
new message on the diagram, no schema change.

## Steps

Executable in this order. Q1 is answered (2026-08-22) and **no step is blocked** — the
two-pass split this section previously described is no longer needed.

1. Write `settings_dao.dart`: `SettingsDao` as a **plain class composing `AppDatabase`**
   (D1, amended) — *not* a `DatabaseAccessor`, no `@DriftAccessor`. `watchCurrency()`
   watches the single settings row and maps it to `Currency`; `setCurrency(Currency)`
   updates that row's `currency` column and returns `Future<void>`. Names per D2; the
   shipped `CategoryDao` / `BudgetDao` are the worked precedent for the shape.
2. **Do not touch `app_database.dart`.** There is no `daos: […]` entry to add (D1,
   amended), the schema does not change, `schemaVersion` stays 1 and no new migration
   snapshot is produced. This step is here rather than deleted so that a coder who expects
   to register the DAO finds the reason it is not registered; if `app_database.g.dart` or
   `drift_schemas/app_database/drift_schema_v1.json` changes at all in this issue, that is
   a signal something went wrong, not progress.
3. Write `settings_providers.dart`, both providers **hand-written**, not `@riverpod` (D7,
   amended): `currencyProvider` as a `StreamProvider<Currency>` over `watchCurrency()`
   declared **without `.autoDispose`** (that omission is the whole of `keepAlive`), and
   `SettingsNotifier` exposed as `settingsProvider` via a `NotifierProvider`, whose
   `setCurrency()` calls the DAO and returns nothing to the screen (D2, D7;
   `riverpod.md`).
4. Write `currency_screen.dart`: `CurrencyScreen` as a `ConsumerWidget` watching
   `currencyProvider`, rendering the two values with both always enabled (D4), and firing
   `ref.read(settingsProvider.notifier).setCurrency(chosen)` on selection — fire and
   forget, never rendering the write's return (D2, `riverpod.md`).
5. Point `app.dart`'s `home` at `CurrencyScreen`, removing FEAT01's placeholder (D3).
6. Implement the message-9 notice: shown when **the chosen currency differs from the
   stored one** (D9), as a dialog that is acknowledged and proceeds, with no cancel (D5).
   Message 10 — the `setCurrency()` call — sits outside the `opt` and therefore runs on
   every selection, including one that shows no notice. Its wording says the amounts are
   re-labelled, not converted (D6): the same integers, a different prefix.
7. Write the four tests in D8, each named for the requirement it defends.
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
    - **As-built pass** on `seq-uc14-choose-currency.drawio` — the **three** discrepancies
      listed under *Scope* above: (1) `createInBackground` vs
      `driftDatabase()` / `createBackgroundConnection`, which is **`pm/findings.md` F3**
      repo-wide and is recorded against F3 rather than fixed in fourteen diagrams here;
      (2) the Indonesian `pilih IDR / USD` label on message 8; (3) the `opt` guard text,
      corrected to *[[the chosen currency differs from the stored one]]* per D9 and
      `decisions.md` 2026-08-22. Re-export and look at the render; do not edit XML and call
      it done (`lessons.md` §3).
    - **`pm/findings.md` F8** — append that UC-14 re-pointed `home` and orphaned
      `SetBudgetScreen`, the fourth screen in the chain (D3). Recorded against the existing
      finding, not filed as a new one, and **not fixed**: a finding is not an issue.
    - **`context/index/map.yaml`** — a `UC-14 → app/lib/src/settings/` entry under `code:`,
      in the shape FEAT01's entry uses.
    - **`context/index/decisions.md`** — only if the toolchain forced a durable ruling, as
      it did three times in FEAT01. Not a formality; not an obligation either.
    - **`docs/workbook.xlsx`** UC-14 marked implemented (`general-rules.md`, definition of
      done, step 4).
    - **`pm/tracker.yaml`** → Done with a one-line summary; **`pm/log.md`** → a dated
      entry plus the current-state block at its head; **`pm/active.json`** → the next
      issue.
    - **`pm/questions.md`** → Q1 is **already** marked ANSWERED with its pointer to
      `decisions.md` (2026-08-22). Verify it, do not re-write it; `lessons.md` §1 is about
      registers left half-updated, and this one is the register that listed the halt.

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
  **Sharpened by the 2026-08-22 ruling, which makes the formatter the *only* place the
  currency has any effect at all** ("changes the prefix and nothing else") — that raises
  its importance to UC-01 and does not move it into this issue, since this issue builds no
  caller for it.
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
- **Editing the sequence diagram now.** The three discrepancies found above — including
  the `opt` guard text D9 resolves — are reconciled in the as-built pass at close (step 11),
  not mid-flight. The main session owns `.drawio` edits.
- **Fixing `pm/findings.md` F3 or F8.** F3 spans twelve diagrams this issue does not own;
  F8 needs a navigation host no class diagram draws. Both are *recorded* at close (step 11)
  and neither is fixed here.

## Open questions

**None blocking.** Q1 — *what makes the currency-change warning fire?* — was the halt, and
the owner answered it on 2026-08-22. It is decided in D9 and recorded at
`context/index/decisions.md`; `pm/questions.md` Q1 is marked ANSWERED.

**Not blocking:**

- The two questions FEAT01 left for the owner — whether `com.eldwinpr.uangsaku` is the
  right application id, and whether the `moneytracker` / `uangsaku` split should be
  resolved — are still unanswered and still do not gate anything here. This issue renames
  nothing.
- Whether the sequence diagram's `pilih` label should be corrected in this issue's
  as-built pass or left for a repo-wide sweep. Step 11 assumes the former, which is what
  `CLAUDE.md`'s close checklist says. The `createInBackground` note is no longer part of
  this question — it is F3 and is repo-wide by its own filing.
- **F8 is the standing one.** This issue makes the fourth screen-orphaning move and says so
  rather than solving it. Whether a navigation host becomes its own issue before UC-01, or
  after six more screens have each orphaned the last, is the owner's call and gates nothing
  here.
