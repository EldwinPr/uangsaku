// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/database/app_database.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('UC02B: v1->v2 migration preserves existing accounts and defaults '
      'deleted to false with deletedAt null', () async {
    // One pre-existing account (v1 has no deleted/deletedAt columns yet)
    // must survive the migration unchanged, with the two new columns
    // defaulting exactly as D1 specifies.
    final oldAccountsData = [
      const v1.AccountsData(
        accountId: 1,
        name: 'Wallet',
        group: 'HOLDING',
        openingAmount: 10000,
        settled: 0,
      ),
    ];
    final expectedNewAccountsData = [
      const v2.AccountsData(
        accountId: 1,
        name: 'Wallet',
        group: 'HOLDING',
        openingAmount: 10000,
        settled: 0,
        deleted: 0,
      ),
    ];

    final oldCategoriesData = <v1.CategoriesData>[];
    final expectedNewCategoriesData = <v2.CategoriesData>[];

    final oldSubcategoriesData = <v1.SubcategoriesData>[];
    final expectedNewSubcategoriesData = <v2.SubcategoriesData>[];

    final oldBudgetGroupsData = <v1.BudgetGroupsData>[];
    final expectedNewBudgetGroupsData = <v2.BudgetGroupsData>[];

    final oldTransactionsData = <v1.TransactionsData>[];
    final expectedNewTransactionsData = <v2.TransactionsData>[];

    final oldBudgetPeriodsData = <v1.BudgetPeriodsData>[];
    final expectedNewBudgetPeriodsData = <v2.BudgetPeriodsData>[];

    final oldSettingsData = <v1.SettingsData>[];
    final expectedNewSettingsData = <v2.SettingsData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.accounts, oldAccountsData);
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.subcategories, oldSubcategoriesData);
        batch.insertAll(oldDb.budgetGroups, oldBudgetGroupsData);
        batch.insertAll(oldDb.transactions, oldTransactionsData);
        batch.insertAll(oldDb.budgetPeriods, oldBudgetPeriodsData);
        batch.insertAll(oldDb.settings, oldSettingsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewAccountsData,
          await newDb.select(newDb.accounts).get(),
        );
        expect(
          expectedNewCategoriesData,
          await newDb.select(newDb.categories).get(),
        );
        expect(
          expectedNewSubcategoriesData,
          await newDb.select(newDb.subcategories).get(),
        );
        expect(
          expectedNewBudgetGroupsData,
          await newDb.select(newDb.budgetGroups).get(),
        );
        expect(
          expectedNewTransactionsData,
          await newDb.select(newDb.transactions).get(),
        );
        expect(
          expectedNewBudgetPeriodsData,
          await newDb.select(newDb.budgetPeriods).get(),
        );
        expect(
          expectedNewSettingsData,
          await newDb.select(newDb.settings).get(),
        );
      },
    );
  });
}
