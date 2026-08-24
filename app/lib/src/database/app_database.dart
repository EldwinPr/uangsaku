import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_table.dart';
import '../budgeting/budgeting_table.dart';
import '../settings/settings_table.dart';
import '../transactions/transactions_table.dart';
import 'app_database.steps.dart';

part 'app_database.g.dart';

/// The single drift database shared by all four modules (D9, `drift.md`).
///
/// All seven tables land at `schemaVersion = 1` (ISSUE-001 D3) — see
/// `docs/diagrams/erd.drawio` for the column-level source of truth.
/// `schemaVersion` is `2` as of UC02B D1: `Accounts` gained `deleted`/
/// `deleted_at`, this project's first guided migration (`drift.md`
/// "Migrations", `drift_schemas/app_database/`). `schemaVersion` is `3` as
/// of FEAT03 D1: `Settings` gained `locale`/`themeMode`/`seedColor`, the
/// second guided migration.
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        // UC02B D1: `Accounts` gains `deleted`/`deleted_at`, the same
        // guided-migration workflow drift.md's "Migrations" section
        // requires — never a hand-written branch.
        from1To2: (m, schema) async {
          await m.addColumn(schema.accounts, schema.accounts.deleted);
          await m.addColumn(schema.accounts, schema.accounts.deletedAt);
        },
        // FEAT03 D1: `Settings` gains `locale`/`themeMode`/`seedColor`.
        from2To3: (m, schema) async {
          await m.addColumn(schema.settings, schema.settings.locale);
          await m.addColumn(schema.settings, schema.settings.themeMode);
          await m.addColumn(schema.settings, schema.settings.seedColor);
        },
      ),
      beforeOpen: (details) async {
        // The currency has to exist before any amount can be interpreted
        // (ISSUE-001 D6) — seed only a fresh database. Language, theme mode
        // and seed color are seeded alongside it (FEAT03 D1).
        if (details.wasCreated) {
          await into(settings).insert(
            const SettingsCompanion(
              currency: Value(Currency.IDR),
              locale: Value(AppLanguage.id),
              themeMode: Value(AppThemeMode.system),
              seedColor: Value(null),
            ),
          );
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
