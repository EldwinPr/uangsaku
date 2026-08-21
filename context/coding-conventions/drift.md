# drift

The database layer. `drift` over SQLite, no backend, chosen 2026-08-19 (`decisions.md`).
Source: [drift documentation](https://drift.simonbinder.eu/).

## Opening the database

**On a background isolate, always:**

```dart
AppDatabase() : super(driftDatabase(name: 'app_database'));
```

**Corrected `FEAT01`, 2026-08-21** — this file previously showed
`NativeDatabase.createInBackground(_dbFile())` directly. That still works, but the `drift_flutter`
package (pinned alongside `drift`/`drift_dev`, `tooling.md`) wraps it: `driftDatabase()` calls
`NativeDatabase.createBackgroundConnection` internally, so the background-isolate guarantee below
is unchanged, and it additionally resolves a platform-appropriate file location via
`path_provider` instead of a hand-written `_dbFile()` helper. Use it rather than the raw
`NativeDatabase` call.

Decided 2026-08-20. The reason, restated because the shorthand for it is wrong: this is **not**
concurrent access — drift still serialises statements, and nothing here makes writes parallel
or introduces a race. It moves the work off the isolate that draws the UI, so a query that
scans the whole `Transactions` table does not stall the screen. `UC-01`'s balance sheet and
`UC-12`'s budget consumption both do exactly that scan, on the screens opened most often, and
the cost grows with every month of use.

This is also the only real boundary in the system — `component-overview.drawio` draws every
DAO → `AppDatabase` edge as an isolate call for this reason.

## Tables and generated classes

- Table declarations are plural (`Accounts`), the generated row class singular (`Account`),
  plus a generated `AccountsCompanion` for writes. **Only the declaration you write appears on
  the class diagrams** — drawing generator output would have doubled every diagram
  (`002-class-diagrams/plan.md`, decision 1).
- Column names match the ERD exactly: `opening_amount`, `from_account_id`, `budget_group_id`.
  drift maps `snake_case` columns to `camelCase` Dart getters, which is the same ERD-to-Dart
  translation `dart-and-flutter.md` describes for entity names.
- Enums are stored with `.textEnum<T>()` rather than by index, so a value's meaning does not
  depend on declaration order. `TransactionKind` has seven values and `Account.group` three;
  reordering an index-stored enum would silently reinterpret every existing row.

## Money

**Every amount is `IntColumn`, counting the currency's minor unit. Never `RealColumn`, never
`double`, anywhere, including in query results and DTOs.**

`IDR` has exponent 0 (whole rupiah), `USD` exponent 2 (cents), read from `Settings.currency`.
Formatting to a human-readable string happens in the widget layer and nowhere else — the
decimal point exists only on screen.

The reason is NFR-2, and it is worth keeping the failure in mind rather than the rule: binary
floating point cannot represent 0.1 exactly, so error accumulates across sums, and a balance
sheet whose net stops matching the sum of its parts **cannot be fixed by a better query**,
because the error is in storage. Full argument in `decisions.md` (2026-08-20) and
`docs/enums.md`.

## DAOs

One per concern, not one per table, following the class diagrams: `AccountDao`,
`TransactionDao`, `CategoryDao`, `BudgetDao`, `SettingsDao`. `CategoryDao` exists separately
from `TransactionDao` deliberately — UC-13 is category CRUD against two tables that
`TransactionDao` does not otherwise own.

- **Reads return streams** (`watchBalances()`, `watchAll()`), because Riverpod's
  `StreamProvider` consumes them directly.
- **Writes return `Future<void>`** unless the caller genuinely needs the new id.
- **A DAO may join another module's tables.** This is ISSUE-005 D1, confirmed by the owner:
  `AccountDao` joins `Transactions` to derive a balance rather than calling `TransactionDao`.
  The accepted cost is that table ownership is enforced by nothing — so **a schema change to
  `Transactions` means checking all four modules**, not one.
- **No stored balance, ever** (ERD D7). Every figure is computed from the ledger. If a query
  is slow, index it or rewrite it; do not add a column.

## The ledger shape

All seven transaction kinds live in one table with a `kind` discriminator and nullable
`from_account_id` / `to_account_id` (ERD D1). Two consequences that belong in code review:

- **"Is this spending?" is `to_account_id IS NULL`.** Do not write a `kind IN (...)` list to
  answer it — FR-8 and FR-9's "must not count as spending" is enforced by the shape of the
  data, and re-deriving it from `kind` in each query is how that guarantee gets lost.
- **One write path.** `TransactionDao` has a single insert used by all five recording use
  cases; the kinds differ in which accounts they set, not in which method they call.

## Migrations

Use drift's **guided migrations** — `dart run drift_dev make-migrations` — rather than
hand-written `onUpgrade` branches. The workflow, from drift's docs:

1. Configure the database path in `build.yaml`.
2. `dart run drift_dev make-migrations` to capture the current schema.
3. Change the schema, bump `schemaVersion`, run it again.
4. Write the migration using the generated step-by-step helper.
5. Run the generated tests.

**Commit the schema snapshots and the generated migration tests.** They are what makes a
future schema change safe, and they are the only artifact that proves a migration preserves
data. NFR-3 ("the data must support later reporting without restructuring") is a promise this
tooling has to keep.

`beforeOpen` is for pragmas and seeding defaults, using `details.wasCreated` to seed only on a
fresh database. The one thing this app must seed is the `Settings` row — the currency has to
exist before any amount can be interpreted.

## Testing

`NativeDatabase.memory()` for tests. Details in [`testing.md`](testing.md).
