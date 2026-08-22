import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/settings_dao.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

void main() {
  late AppDatabase database;
  late SettingsDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = SettingsDao(database);
  });

  tearDown(() => database.close());

  test('FR-19: watchCurrency() emits the seeded IDR on a fresh database, and setCurrency() causes a second emission on the same stream (message 15, the read path)', () async {
    final emissions = <Currency>[];
    final subscription = dao.watchCurrency().listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, Currency.IDR);

    await dao.setCurrency(Currency.USD);
    await pumpEventQueue();
    expect(emissions, hasLength(2));
    expect(emissions.last, Currency.USD);

    // Exactly one Settings row still exists (D9, the ERD's single-row
    // design).
    final rows = await database.select(database.settings).get();
    expect(rows, hasLength(1));
    expect(rows.single.currency, Currency.USD);
  });

  test('decisions.md 2026-08-22: setCurrency() re-labels only — it does not touch any other table', () async {
    final accountId = await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Wallet',
            group: AccountGroup.HOLDING,
            openingAmount: 50000,
          ),
        );

    await dao.setCurrency(Currency.USD);

    final account = await (database.select(
      database.accounts,
    )..where((row) => row.accountId.equals(accountId))).getSingle();
    // The same integer, unconverted — a currency change never scales a
    // stored amount (D6).
    expect(account.openingAmount, 50000);
  });
}
