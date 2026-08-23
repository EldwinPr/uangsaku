import 'package:drift/drift.dart' show Value;
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

  test('UC02B D4: watchAccounts() excludes a soft-deleted account', () async {
    final ids = await seedAccounts();
    await (database.update(database.accounts)
          ..where((row) => row.accountId.equals(ids['Savings']!)))
        .write(const AccountsCompanion(deleted: Value(true)));

    final accounts = await dao.watchAccounts().first;

    expect(
      accounts.map((account) => account.name).toList(),
      isNot(contains('Savings')),
    );
    expect(accounts, hasLength(3));
  });

  test('D7: the person/debt picker surfaces only RECEIVABLE/PAYABLE rows', () {
    final accounts = [
      Account(
        accountId: 1,
        name: 'Cash',
        group: AccountGroup.HOLDING,
        openingAmount: 100000,
        settled: false,
        settledAt: null,
        deleted: false,
        deletedAt: null,
      ),
      Account(
        accountId: 2,
        name: 'Budi',
        group: AccountGroup.RECEIVABLE,
        openingAmount: 0,
        settled: false,
        settledAt: null,
        deleted: false,
        deletedAt: null,
      ),
      Account(
        accountId: 3,
        name: 'Credit card',
        group: AccountGroup.PAYABLE,
        openingAmount: -50000,
        settled: false,
        settledAt: null,
        deleted: false,
        deletedAt: null,
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

  test('UC-09 D3: watchAll() joins both side-account names inside the DAO and orders (occurredOn, transactionId) ascending', () async {
    final ids = await seedAccounts();

    // The later-dated row is inserted FIRST (lowest id), so the emission
    // order pins both ordering keys: date dominates, insertion id breaks
    // same-day ties.
    await dao.insert(
      kind: TransactionKind.transfer,
      amount: 30000,
      occurredOn: DateTime(2026, 8, 2),
      fromAccountId: ids['Cash'],
      toAccountId: ids['Savings'],
    );
    await dao.insert(
      kind: TransactionKind.expense,
      amount: 10000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
      note: 'lunch',
    );
    await dao.insert(
      kind: TransactionKind.income,
      amount: 20000,
      occurredOn: day,
      toAccountId: ids['Budi'],
    );

    final rows = await dao.watchAll().first;

    // Ordered by (occurredOn, transactionId): the two `day` rows first in
    // id order, then the later day.
    expect(rows.map((row) => row.transaction.amount).toList(), [
      10000,
      20000,
      30000,
    ]);

    // Side names arrive joined — one side for expense/income per
    // docs/enums.md's kind table, both for transfer; a null side reads as
    // a null name. The list reads columns, it does not interpret kinds.
    expect(rows[0].fromName, 'Cash');
    expect(rows[0].toName, isNull);
    expect(rows[1].fromName, isNull);
    expect(rows[1].toName, 'Budi');
    expect(rows[2].fromName, 'Cash');
    expect(rows[2].toName, 'Savings');
    expect(rows[0].transaction.note, 'lunch');
  });

  test(
    'FR-18: update() round-trips every editable field and never touches kind',
    () async {
      final ids = await seedAccounts();
      await database
          .into(database.categories)
          .insert(CategoriesCompanion.insert(name: 'Food'));
      await database
          .into(database.budgetGroups)
          .insert(BudgetGroupsCompanion.insert(name: 'Groceries'));
      final category = await database.select(database.categories).getSingle();
      final group = await database.select(database.budgetGroups).getSingle();

      await dao.insert(
        kind: TransactionKind.expense,
        amount: 10000,
        occurredOn: day,
        fromAccountId: ids['Cash'],
        categoryId: category.categoryId,
        budgetGroupId: group.budgetGroupId,
        note: 'lunch',
      );
      final original = await database.select(database.transactions).getSingle();

      final nextDay = DateTime(2026, 8, 9);
      await dao.update(
        id: original.transactionId,
        amount: 25000,
        occurredOn: nextDay,
        fromAccountId: ids['Savings'],
        toAccountId: null,
        categoryId: null,
        subcategoryId: null,
        budgetGroupId: null,
        note: 'amended note',
      );

      final amended = await database.select(database.transactions).getSingle();
      // Kind is not an update parameter (plan D4) — the row keeps its kind.
      expect(amended.kind, TransactionKind.expense);
      expect(amended.transactionId, original.transactionId);
      expect(amended.amount, 25000);
      expect(amended.occurredOn, nextDay);
      expect(amended.fromAccountId, ids['Savings']);
      // Blanks become nulls: the previously-set tags are now cleared, keeping
      // "cleared" and "was never set" one fact (UC04's D8 convention).
      expect(amended.categoryId, isNull);
      expect(amended.subcategoryId, isNull);
      expect(amended.budgetGroupId, isNull);
      expect(amended.note, 'amended note');
    },
  );

  test('FR-18: delete() removes an existing row', () async {
    final ids = await seedAccounts();

    await dao.insert(
      kind: TransactionKind.expense,
      amount: 10000,
      occurredOn: day,
      fromAccountId: ids['Cash'],
    );
    final row = await database.select(database.transactions).getSingle();

    await dao.delete(id: row.transactionId);

    final rows = await database.select(database.transactions).get();
    expect(rows, isEmpty);
  });

  test('D5 / NFR-4: delete() proceeds unconditionally — even a row referencing now-absent tag ids deletes successfully', () async {
    // FK-direction proof for UC-09 D5: nothing references Transactions, so
    // a ledger row can never be blocked by what it points at — not even
    // when its own side/tag references dangle. (drift does not enable
    // PRAGMA foreign_keys by default — see drift's columns.dart — which is
    // why a row referencing absent ids can exist here at all.)
    final id = await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: TransactionKind.expense,
            amount: 5000,
            occurredOn: day,
            fromAccountId: const Value(9999),
            toAccountId: const Value(8888),
            categoryId: const Value(7777),
            subcategoryId: const Value(6666),
            budgetGroupId: const Value(5555),
            note: const Value('dangling'),
          ),
        );

    await dao.delete(id: id);

    var rows = await database.select(database.transactions).get();
    expect(rows, isEmpty);

    // Deleting an already-absent id completes harmlessly — there is no
    // error to surface and nothing to refuse.
    await dao.delete(id: id);
    rows = await database.select(database.transactions).get();
    expect(rows, isEmpty);
  });
}
