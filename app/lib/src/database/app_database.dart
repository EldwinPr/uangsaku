import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_table.dart';
import '../budgeting/budgeting_table.dart';
import '../settings/settings_table.dart';
import '../transactions/transactions_table.dart';

part 'app_database.g.dart';

/// The single drift database shared by all four modules (D9, `drift.md`).
///
/// All seven tables land at `schemaVersion = 1` (ISSUE-001 D3) — see
/// `docs/diagrams/erd.drawio` for the column-level source of truth.
///
/// No `daos: […]` entry: `CategoryDao` is a plain composition over this
/// class rather than a `@DriftAccessor`/`DatabaseAccessor` subtype (see
/// `category_dao.dart`'s doc comment for why), so there is no accessor for
/// drift to attach here.
@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    Categories,
    Subcategories,
    BudgetGroups,
    BudgetPeriods,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // The currency has to exist before any amount can be interpreted
        // (ISSUE-001 D6) — seed only a fresh database.
        if (details.wasCreated) {
          await into(settings)
              .insert(const SettingsCompanion(currency: Value(Currency.IDR)));
        }
      },
    );
  }
}

/// `NativeDatabase.createInBackground`, via `drift_flutter`'s cross-platform
/// helper — this is *not* concurrent access, drift still serialises
/// statements. It moves work off the isolate that draws the UI (`drift.md`).
QueryExecutor _openConnection() {
  return driftDatabase(name: 'app_database');
}

/// Plumbing every later issue needs — the single exception to "no providers
/// beyond `AppDatabase`'s" (ISSUE-001 D5). Not a `StreamProvider` or a
/// `Notifier`; a plain `Provider` is inherently kept alive, matching
/// `keepAlive: true` — it outlives every screen.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
