import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/record_transaction_screen.dart';
import 'package:uangsaku/src/transactions/transaction_dao.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

void main() {
  late AppDatabase database;
  late TransactionDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = TransactionDao(database);
  });

  tearDown(() => database.close());

  /// One account per group plus a second wallet for transfers. Autoincrement
  /// makes the ids deterministic, but they are read back by name anyway.
  Future<Map<String, int>> seedAccounts() async {
    await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Cash',
            group: AccountGroup.HOLDING,
            openingAmount: 100000,
          ),
        );
    await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Savings',
            group: AccountGroup.HOLDING,
            openingAmount: 0,
          ),
        );
    await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Budi',
            group: AccountGroup.RECEIVABLE,
            openingAmount: 0,
          ),
        );
    await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Credit card',
            group: AccountGroup.PAYABLE,
            openingAmount: -50000,
          ),
        );

    final accounts = await database.select(database.accounts).get();
    return {for (final account in accounts) account.name: account.accountId};
  }

  final day = DateTime(2026, 8, 1);

  test('FR-8 / FR-9: transfer, lend, borrow and repayment rows never satisfy to_account_id IS NULL — only the expense row does', () async {
    // The correctness property the whole ledger shape exists for:
    // "is this spending?" is `to_account_id IS NULL`, a property of the
    // row, not a branch — so no query anywhere needs to remember that a
    // transfer or a loan is not spending.
    final ids = await seedAccounts();

    await dao.insert(
      kind: TransactionKind.expense,
      amount: 10000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
    );
    await dao.insert(
      kind: TransactionKind.transfer,
      amount: 20000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
      toAccountId: ids['Savings'],
    );
    await dao.insert(
      kind: TransactionKind.lend,
      amount: 30000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
      toAccountId: ids['Budi'],
    );
    await dao.insert(
      kind: TransactionKind.borrow,
      amount: 40000,
      occurredOn: day,
      fromAccountId: ids['Credit card'],
      toAccountId: ids['Cash'],
    );
    // Repayment in both directions per the alt arms of seq-uc08.
    await dao.insert(
      kind: TransactionKind.repayment,
      amount: 5000,
      occurredOn: day,
      fromAccountId: ids['Budi'],
      toAccountId: ids['Cash'],
    );
    await dao.insert(
      kind: TransactionKind.repayment,
      amount: 6000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
      toAccountId: ids['Credit card'],
    );

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(6));

    for (final row in rows) {
      if (row.kind == TransactionKind.expense) {
        expect(row.toAccountId, isNull);
      } else {
        expect(row.toAccountId, isNotNull);
      }
    }

    // The same property straight against storage, via the predicate
    // itself — exactly one row qualifies as spending, and it is the
    // expense.
    final spending = await database
        .customSelect(
          'SELECT kind FROM transactions WHERE to_account_id IS NULL',
        )
        .get();
    expect(spending, hasLength(1));
    expect(spending.single.data['kind'], 'expense');
  });

  test('FR-10 / D8: blanks store nulls in category_id, subcategory_id, budget_group_id and note; a filled note round-trips verbatim', () async {
    final ids = await seedAccounts();

    await dao.insert(
      kind: TransactionKind.expense,
      amount: 12000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
    );

    final blank = await database.select(database.transactions).getSingle();
    expect(blank.categoryId, isNull);
    expect(blank.subcategoryId, isNull);
    expect(blank.budgetGroupId, isNull);
    expect(blank.note, isNull);

    const noteText = 'Budi paid back Rp50.000 at the station   ';
    await dao.insert(
      kind: TransactionKind.income,
      amount: 50000,
      occurredOn: day,
      toAccountId: ids['Cash'],
      categoryId: 7,
      subcategoryId: 9,
      budgetGroupId: 3,
      note: noteText,
    );

    final filled = (await database.select(database.transactions).get())
        .firstWhere((row) => row.kind == TransactionKind.income);
    expect(filled.note, noteText);
    expect(filled.categoryId, 7);
    expect(filled.subcategoryId, 9);
    expect(filled.budgetGroupId, 3);
  });

  test('FR-19 / NFR-2: amounts store the exact int minor units entered — nothing converts, rounds or negates', () async {
    final ids = await seedAccounts();

    const amounts = [1999, 123456789012345678, -250];
    for (final amount in amounts) {
      await dao.insert(
        kind: TransactionKind.expense,
        amount: amount,
        occurredOn: day,
        fromAccountId: ids['Cash'],
      );
    }

    final rows = await database.select(database.transactions).get();
    expect(rows.map((row) => row.amount), amounts);
  });

  test(
    'D7: watchAccounts() emits the seeded accounts with their groups',
    () async {
      await seedAccounts();

      final accounts = await dao.watchAccounts().first;

      expect(accounts.map((account) => account.name).toList(), [
        'Cash',
        'Savings',
        'Budi',
        'Credit card',
      ]);
      expect(accounts.map((account) => account.group).toList(), [
        AccountGroup.HOLDING,
        AccountGroup.HOLDING,
        AccountGroup.RECEIVABLE,
        AccountGroup.PAYABLE,
      ]);
    },
  );

  test('D7: the person/debt picker surfaces only RECEIVABLE/PAYABLE rows', () {
    final accounts = [
      Account(
        accountId: 1,
        name: 'Cash',
        group: AccountGroup.HOLDING,
        openingAmount: 100000,
        settled: false,
        settledAt: null,
      ),
      Account(
        accountId: 2,
        name: 'Budi',
        group: AccountGroup.RECEIVABLE,
        openingAmount: 0,
        settled: false,
        settledAt: null,
      ),
      Account(
        accountId: 3,
        name: 'Credit card',
        group: AccountGroup.PAYABLE,
        openingAmount: -50000,
        settled: false,
        settledAt: null,
      ),
    ];

    final choices = personDebtChoices(accounts);

    expect(choices.map((account) => account.name), ['Budi', 'Credit card']);
  });

  test('D7: watchBudgetGroups() emits the seeded groups', () async {
    await database
        .into(database.budgetGroups)
        .insert(BudgetGroupsCompanion.insert(name: 'Groceries'));
    await database
        .into(database.budgetGroups)
        .insert(BudgetGroupsCompanion.insert(name: 'Transport'));

    final groups = await dao.watchBudgetGroups().first;

    expect(groups.map((group) => group.name).toList(), [
      'Groceries',
      'Transport',
    ]);
  });
}
