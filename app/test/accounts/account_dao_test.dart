import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_dao.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';

void main() {
  late AppDatabase database;
  late AccountDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = AccountDao(database);
  });

  tearDown(() => database.close());

  AccountsCompanion companion(
    String name,
    AccountGroup group,
    int openingAmount,
  ) => AccountsCompanion.insert(
    name: name,
    group: group,
    openingAmount: openingAmount,
  );

  test('FR-3: insert() writes a row whose name, group and openingAmount read back unchanged', () async {
    await dao.insert(companion('Wallet', AccountGroup.HOLDING, 250000));

    final row = await database.select(database.accounts).getSingle();
    expect(row.name, 'Wallet');
    expect(row.group, AccountGroup.HOLDING);
    expect(row.openingAmount, 250000);
  });

  test("docs/enums.md: an account inserted as PAYABLE reads back PAYABLE and the raw group column holds the text 'PAYABLE', not an index", () async {
    await dao.insert(companion('Credit card', AccountGroup.PAYABLE, 0));

    final row = await database.select(database.accounts).getSingle();
    expect(row.group, AccountGroup.PAYABLE);

    // The raw column value — `.textEnum<AccountGroup>()` must have stored
    // the enum's name as text; an index (2) would silently reinterpret
    // every existing row if the enum were ever reordered.
    final raw = await database
        .customSelect('SELECT "group" FROM accounts')
        .getSingle();
    expect(raw.data['group'], 'PAYABLE');
  });

  test('FR-4 / D6: a negative openingAmount is stored and read back unchanged and still negative', () async {
    // FR-4: a PAYABLE account "just holds a negative amount". The app
    // applies no sign transformation on the owner's behalf.
    await dao.insert(companion('Loan', AccountGroup.PAYABLE, -75000));

    final row = await database.select(database.accounts).getSingle();
    expect(row.openingAmount, -75000);
  });

  test('FR-5: three accounts, one per AccountGroup, coexist in one table with no subtype table and no extra columns', () async {
    await dao.insert(companion('Wallet', AccountGroup.HOLDING, 50000));
    await dao.insert(companion('Budi', AccountGroup.RECEIVABLE, 12000));
    await dao.insert(companion('Credit card', AccountGroup.PAYABLE, -3000));

    final rows = await database.select(database.accounts).get();
    expect(rows, hasLength(3));
    expect(rows.map((row) => row.group), {
      AccountGroup.HOLDING,
      AccountGroup.RECEIVABLE,
      AccountGroup.PAYABLE,
    });
  });

  test('D4: inserting an account with a non-zero opening amount leaves Transactions empty', () async {
    // UC-02 writes no ledger row ever — the opening amount is the
    // Accounts.openingAmount column itself (plan.md D4). `adjustment`
    // belongs to UC-03.
    await dao.insert(companion('Wallet', AccountGroup.HOLDING, 250000));

    expect(await database.select(database.accounts).get(), hasLength(1));
    expect(await database.select(database.transactions).get(), isEmpty);
  });

  test('D4: inserting an account with a zero opening amount also writes no transaction row', () async {
    // No branch: a zero opening amount is the integer 0 in a required
    // column, not a signal to write anything anywhere.
    await dao.insert(companion('Empty wallet', AccountGroup.HOLDING, 0));

    expect(await database.select(database.accounts).get(), hasLength(1));
    expect(await database.select(database.transactions).get(), isEmpty);
  });
}
