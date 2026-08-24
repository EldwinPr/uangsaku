import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('FEAT01: the database opens', () async {
    // A trivial query only succeeds if the connection actually opened.
    await database.customSelect('SELECT 1').get();
  });

  test('FEAT03 D1: schemaVersion is 3 — Settings gained locale/themeMode/seedColor', () {
    expect(database.schemaVersion, 3);
  });

  test('FEAT01: all seven tables exist', () async {
    final tableNames = database.allTables
        .map((table) => table.actualTableName)
        .toSet();
    expect(tableNames, {
      'accounts',
      'transactions',
      'categories',
      'subcategories',
      'budget_groups',
      'budget_periods',
      'settings',
    });
  });

  test('ISSUE-001 D6 / FEAT03 D1: exactly one Settings row is seeded with '
      'Currency.IDR, AppLanguage.id, AppThemeMode.system and a null seedColor '
      'on a fresh database', () async {
    final rows = await database.select(database.settings).get();
    expect(rows, hasLength(1));
    expect(rows.single.currency, Currency.IDR);
    expect(rows.single.locale, AppLanguage.id);
    expect(rows.single.themeMode, AppThemeMode.system);
    expect(rows.single.seedColor, isNull);
  });
}
