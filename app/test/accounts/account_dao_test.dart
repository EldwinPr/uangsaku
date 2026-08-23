import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_dao.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/budgeting/clock.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// A `Clock` fixed to one date, so `occurredOn` is deterministic under test
/// (UC-03 plan D7).
class _FixedClock extends Clock {
  _FixedClock(this._date);

  final DateTime _date;

  @override
  DateTime today() => _date;
}

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

  test('FR-18 / NFR-2: adjusting a fresh account to a higher target writes exactly one row and the derived balance now equals the target', () async {
    final accountId = await dao.insert(
      companion('Wallet', AccountGroup.HOLDING, 100000),
    );

    await dao.insertAdjustment(accountId: accountId, targetAmount: 150000);

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(1));

    final account = await (database.select(
      database.accounts,
    )..where((row) => row.accountId.equals(accountId))).getSingle();
    final movement = await database
        .customSelect(
          'SELECT SUM(amount) AS total FROM transactions WHERE to_account_id = ?',
          variables: [Variable.withInt(accountId)],
        )
        .getSingle();
    final derived =
        account.openingAmount + (movement.data['total'] as int? ?? 0);
    expect(derived, 150000);
  });

  test('D4: adjusting to the current amount still writes the zero-diff row — no branch skips it', () async {
    final accountId = await dao.insert(
      companion('Wallet', AccountGroup.HOLDING, 100000),
    );

    await dao.insertAdjustment(accountId: accountId, targetAmount: 100000);

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.amount, 0);
  });

  test('D1 / NFR-2: Accounts.openingAmount is unchanged after an adjustment — the correction is a recorded row, never an overwrite', () async {
    final accountId = await dao.insert(
      companion('Wallet', AccountGroup.HOLDING, 100000),
    );

    await dao.insertAdjustment(accountId: accountId, targetAmount: 150000);

    final account = await (database.select(
      database.accounts,
    )..where((row) => row.accountId.equals(accountId))).getSingle();
    expect(account.openingAmount, 100000);
  });

  test("docs/enums.md: an adjustment row's raw kind column holds the text 'adjustment', not an index", () async {
    final accountId = await dao.insert(
      companion('Wallet', AccountGroup.HOLDING, 100000),
    );

    await dao.insertAdjustment(accountId: accountId, targetAmount: 150000);

    final row = await database
        .customSelect('SELECT kind FROM transactions')
        .getSingle();
    expect(row.data['kind'], 'adjustment');
  });

  test('D3: the diff reflects prior movement, not just openingAmount — an account with a recorded income adjusts by the difference against the derived total', () async {
    final accountId = await dao.insert(
      companion('Wallet', AccountGroup.HOLDING, 100000),
    );
    // A prior movement into the account (an income-shaped row, written
    // directly since no TransactionDao is touched by this test — D3's
    // point is that AccountDao reads Transactions, not that it wrote this
    // one).
    await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: TransactionKind.income,
            amount: 20000,
            occurredOn: DateTime(2026, 1, 1),
            toAccountId: Value(accountId),
          ),
        );
    // Derived total is now 100000 (opening) + 20000 (income) = 120000.
    await dao.insertAdjustment(accountId: accountId, targetAmount: 150000);

    final adjustmentRow = await (database.select(
      database.transactions,
    )..where((row) => row.kind.equals('adjustment'))).getSingle();
    // diff = target(150000) - derived(120000) = 30000, not
    // target - openingAmount(100000) = 50000.
    expect(adjustmentRow.amount, 30000);
  });

  test(
    "D7: occurredOn on the adjustment row equals the injected Clock's date",
    () async {
      final clockedDao = AccountDao(
        database,
        clock: _FixedClock(DateTime(2026, 3, 15)),
      );
      final accountId = await clockedDao.insert(
        companion('Wallet', AccountGroup.HOLDING, 100000),
      );

      await clockedDao.insertAdjustment(
        accountId: accountId,
        targetAmount: 150000,
      );

      final row = await database.select(database.transactions).getSingle();
      expect(row.occurredOn, DateTime(2026, 3, 15));
    },
  );
}
