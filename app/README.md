# uangsaku

A personal balance-sheet tracker: accounts (wallets, debts owed to you, debts you owe),
money movement (expense/income/transfer/lend/borrow/repayment), balance corrections, and
a monthly budget per group. Flutter/Dart, `drift` over SQLite, Riverpod, no backend,
local-first, single user. Built by the pipeline documented at the repository root — see
the root `README.md`'s "Current state" for what's done and what's still open.

## Layout

```
lib/src/
  accounts/      Accounts table, AccountDao, AccountsNotifier, BalanceSheetScreen,
                 AccountFormScreen (create/adjust/edit), DebtDetailScreen
  transactions/  Transactions/Categories/Subcategories tables, TransactionDao,
                 RecordTransactionScreen, TransactionListScreen, CategoryManagerScreen
  budgeting/     BudgetGroups/BudgetPeriods tables, BudgetDao, SetBudgetScreen,
                 BudgetOverviewScreen
  settings/      Settings table (currency), CurrencyScreen
  database/      AppDatabase (drift, background isolate), the drift schema migrations
  app.dart       AppShell — the bottom-nav host wiring every screen together
```

Each module is Screen → Riverpod provider/Notifier → DAO → `AppDatabase` → drift table,
same chain everywhere. See `context/index/map.yaml` at the repo root for exactly which
file implements which use case, and `docs/diagrams/class-*.drawio` for the per-module
class diagrams this chain is drawn from.

## Running the tests

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

All headless — no emulator or device needed. **This is also the only verification that
has actually been run against this codebase**: no Android SDK and no Mac are available
in the environment this app was built in, so nobody has launched it on a real device or
emulator yet. If you have one, that's the next useful thing to do with this repo.

## Schema migrations

`schemaVersion` is currently `2` (`Accounts` gained `deleted`/`deleted_at` for
`UC02B-edit-account`'s soft delete). Any future schema change follows drift's **guided
migrations**, documented in `context/coding-conventions/drift.md`:

```
dart run drift_dev make-migrations   # capture the current schema
# change the schema, bump schemaVersion
dart run drift_dev make-migrations   # generate the step + new snapshot
# wire the generated step into MigrationStrategy.onUpgrade
```

Commit both schema snapshots (`drift_schemas/app_database/`) and the generated migration
test — they're what proves an upgrade preserves existing data, not just that a fresh
database can be created at the new version.
