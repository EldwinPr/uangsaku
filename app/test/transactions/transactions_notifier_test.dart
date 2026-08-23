import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transaction_dao.dart';
import 'package:uangsaku/src/transactions/transactions_providers.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// The six kind-pinning tests: calling each notifier method and reading the
/// row back must yield exactly the sides `docs/enums.md`'s kind table fixes
/// (plan DoD). The write goes through `TransactionsNotifier` →
/// `TransactionDao.insert()` — the real path, on a real in-memory database.
///
/// UC-09 adds the correction half (FR-18): [edit] and [delete] through the
/// notifier, read back on `TransactionDao.watchAll()`'s stream — the same
/// real path, no widget involved.
void main() {
  late AppDatabase database;
  late TransactionDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = TransactionDao(database);
  });

  tearDown(() => database.close());

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

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    return container;
  }

  final day = DateTime(2026, 8, 1);

  test("docs/enums.md kind table — expense: recordExpense writes from=wallet, to=null", () async {
    final ids = await seedAccounts();

    await container()
        .read(transactionsProvider.notifier)
        .recordExpense(
          amount: 15000,
          fromAccountId: ids['Cash'],
          note: 'lunch',
          date: day,
        );

    final row = await database.select(database.transactions).getSingle();
    expect(row.kind, TransactionKind.expense);
    expect(row.fromAccountId, ids['Cash']);
    expect(row.toAccountId, isNull);
    expect(row.amount, 15000);
    expect(row.occurredOn, day);
  });

  test("docs/enums.md kind table — income: recordIncome writes from=null, to=wallet", () async {
    final ids = await seedAccounts();

    await container()
        .read(transactionsProvider.notifier)
        .recordIncome(amount: 20000, toAccountId: ids['Cash'], date: day);

    final row = await database.select(database.transactions).getSingle();
    expect(row.kind, TransactionKind.income);
    expect(row.fromAccountId, isNull);
    expect(row.toAccountId, ids['Cash']);
  });

  test(
    "docs/enums.md kind table — transfer: transfer writes both wallets",
    () async {
      final ids = await seedAccounts();
      await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Savings',
              group: AccountGroup.HOLDING,
              openingAmount: 0,
            ),
          );
      final savings = (await database.select(database.accounts).get())
          .firstWhere((account) => account.name == 'Savings')
          .accountId;

      await container()
          .read(transactionsProvider.notifier)
          .transfer(
            amount: 30000,
            fromAccountId: ids['Cash'],
            toAccountId: savings,
            date: day,
          );

      final row = await database.select(database.transactions).getSingle();
      expect(row.kind, TransactionKind.transfer);
      expect(row.fromAccountId, ids['Cash']);
      expect(row.toAccountId, savings);
    },
  );

  test(
    "docs/enums.md kind table — lend: wallet → the person's RECEIVABLE account",
    () async {
      final ids = await seedAccounts();

      await container()
          .read(transactionsProvider.notifier)
          .lend(
            amount: 40000,
            personAccountId: ids['Budi'],
            fromAccountId: ids['Cash'],
            date: day,
          );

      final row = await database.select(database.transactions).getSingle();
      expect(row.kind, TransactionKind.lend);
      expect(row.fromAccountId, ids['Cash']);
      expect(row.toAccountId, ids['Budi']);
    },
  );

  test(
    'docs/enums.md kind table — borrow: the PAYABLE account → wallet',
    () async {
      final ids = await seedAccounts();

      await container()
          .read(transactionsProvider.notifier)
          .borrow(
            amount: 50000,
            debtAccountId: ids['Credit card'],
            toAccountId: ids['Cash'],
            date: day,
          );

      final row = await database.select(database.transactions).getSingle();
      expect(row.kind, TransactionKind.borrow);
      expect(row.fromAccountId, ids['Credit card']);
      expect(row.toAccountId, ids['Cash']);
    },
  );

  test("docs/enums.md kind table — repayment in both directions per seq-uc08's alt arms", () async {
    final ids = await seedAccounts();
    final notifier = container().read(transactionsProvider.notifier);

    // Arm 1 — they repaid: money leaves the person's RECEIVABLE account
    // and lands in the own wallet.
    await notifier.repay(
      amount: 5000,
      fromAccountId: ids['Budi'],
      toAccountId: ids['Cash'],
      date: day,
    );
    // Arm 2 — owner repaid: money leaves the wallet and lands on the
    // PAYABLE account.
    await notifier.repay(
      amount: 6000,
      fromAccountId: ids['Cash'],
      toAccountId: ids['Credit card'],
      date: day,
    );

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(2));
    expect(rows.every((row) => row.kind == TransactionKind.repayment), isTrue);
    expect(
      rows.map((row) => (row.fromAccountId, row.toAccountId)),
      containsAllInOrder([
        (ids['Budi'], ids['Cash']),
        (ids['Cash'], ids['Credit card']),
      ]),
    );
  });

  test('FR-18: edit() amends through UC04\'s path — kind stays fixed, the amended row arrives on the list stream', () async {
    final ids = await seedAccounts();
    final notifier = container().read(transactionsProvider.notifier);

    await notifier.recordExpense(
      amount: 15000,
      fromAccountId: ids['Cash'],
      note: 'lunch',
      date: day,
    );
    final before = await dao.watchAll().first;
    final id = before.single.transaction.transactionId;

    await notifier.edit(
      id: id,
      amount: 25000,
      fromAccountId: ids['Cash'],
      date: DateTime(2026, 8, 9),
      note: 'lunch, cheaper',
    );

    final after = await dao.watchAll().first;
    expect(after, hasLength(1));
    final amended = after.single;
    // Kind is not an edit parameter (UC-09 D4): the expense row stays an
    // expense, occupying exactly the sides docs/enums.md assigns it.
    expect(amended.transaction.kind, TransactionKind.expense);
    expect(amended.transaction.amount, 25000);
    expect(amended.transaction.occurredOn, DateTime(2026, 8, 9));
    expect(amended.transaction.fromAccountId, ids['Cash']);
    expect(amended.transaction.toAccountId, isNull);
    expect(amended.fromName, 'Cash');
    expect(amended.toName, isNull);
    expect(amended.transaction.note, 'lunch, cheaper');
  });

  test('FR-18: delete() removes the row; the next list-stream emission no longer carries it', () async {
    final ids = await seedAccounts();
    final notifier = container().read(transactionsProvider.notifier);

    await notifier.recordExpense(
      amount: 15000,
      fromAccountId: ids['Cash'],
      date: day,
    );
    final before = await dao.watchAll().first;
    expect(before, hasLength(1));

    await notifier.delete(id: before.single.transaction.transactionId);

    final after = await dao.watchAll().first;
    // Unconditional delete (UC-09 D5): gone, with nothing asked and nothing
    // refused.
    expect(after, isEmpty);
  });

  test('NFR-4: edit() proceeds under empty pickers — zero amount and blank tags write instead of refusing', () async {
    // No accounts, categories or groups seeded at all: every picker pool is
    // empty, so every side and tag stays null (UC-09 D7).
    final notifier = container().read(transactionsProvider.notifier);

    await notifier.recordExpense(amount: 15000, date: day);
    final before = await dao.watchAll().first;

    await notifier.edit(
      id: before.single.transaction.transactionId,
      amount: 0,
      date: day,
    );

    final after = await dao.watchAll().first;
    expect(after, hasLength(1));
    expect(after.single.transaction.amount, 0);
    expect(after.single.transaction.fromAccountId, isNull);
    expect(after.single.transaction.toAccountId, isNull);
    expect(after.single.transaction.categoryId, isNull);
    expect(after.single.transaction.budgetGroupId, isNull);
    expect(after.single.transaction.note, isNull);
  });
}
