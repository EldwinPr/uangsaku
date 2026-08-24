import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_dao.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/budgeting/clock.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// FEAT07's three new `AccountDao` queries (plan.md Definition of done):
/// `watchBalanceTrend`/`watchIncomeExpense`/`watchCategorySpending`. A
/// `Clock` fixed to one date makes "today"/"this month" deterministic under
/// test — same discipline `budget_dao_test.dart` established for `BudgetDao`.
class _FixedClock extends Clock {
  _FixedClock(this._date);

  final DateTime _date;

  @override
  DateTime today() => _date;
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  AccountDao daoOn(DateTime today) =>
      AccountDao(database, clock: _FixedClock(today));

  Future<int> insertAccount(
    String name,
    AccountGroup group,
    int openingAmount,
  ) => database
      .into(database.accounts)
      .insert(
        AccountsCompanion.insert(
          name: name,
          group: group,
          openingAmount: openingAmount,
        ),
      );

  Future<void> insertTransaction({
    required TransactionKind kind,
    required int amount,
    required DateTime occurredOn,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
  }) => database
      .into(database.transactions)
      .insert(
        TransactionsCompanion.insert(
          kind: kind,
          amount: amount,
          occurredOn: occurredOn,
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
          categoryId: Value(categoryId),
        ),
      );

  Future<int> insertCategory(String name) => database
      .into(database.categories)
      .insert(CategoriesCompanion.insert(name: name));

  group('FEAT07 D3: watchBalanceTrend', () {
    test('a point before the transaction shows the opening balance; today shows it applied', () async {
      final today = DateTime(2026, 8, 24);
      final dao = daoOn(today);
      final wallet = await insertAccount(
        'Wallet',
        AccountGroup.HOLDING,
        100000,
      );
      await insertTransaction(
        kind: TransactionKind.income,
        amount: 50000,
        occurredOn: DateTime(2026, 8, 20),
        toAccountId: wallet,
      );

      final points = await dao.watchBalanceTrend(days: 30).first;

      expect(points, hasLength(30));
      expect(points.last.date, today);
      expect(points.last.netBalance, 150000);
      final beforeTransaction = points.firstWhere(
        (p) => p.date == DateTime(2026, 8, 19),
      );
      expect(beforeTransaction.netBalance, 100000);
    });

    test('an empty database yields a flat zero line, not an error', () async {
      final dao = daoOn(DateTime(2026, 8, 24));
      final points = await dao.watchBalanceTrend(days: 7).first;
      expect(points, hasLength(7));
      expect(points.every((p) => p.netBalance == 0), isTrue);
    });
  });

  group('FEAT07 D4: watchIncomeExpense', () {
    test(
      'sums only this calendar month, income and expense separately',
      () async {
        final dao = daoOn(DateTime(2026, 8, 24));
        final wallet = await insertAccount('Wallet', AccountGroup.HOLDING, 0);
        await insertTransaction(
          kind: TransactionKind.income,
          amount: 200000,
          occurredOn: DateTime(2026, 8, 5),
          toAccountId: wallet,
        );
        await insertTransaction(
          kind: TransactionKind.expense,
          amount: 30000,
          occurredOn: DateTime(2026, 8, 6),
          fromAccountId: wallet,
        );
        // Last month — must not be counted.
        await insertTransaction(
          kind: TransactionKind.income,
          amount: 999999,
          occurredOn: DateTime(2026, 7, 31),
          toAccountId: wallet,
        );

        final summary = await dao.watchIncomeExpense().first;

        expect(summary.income, 200000);
        expect(summary.expense, 30000);
      },
    );

    test('an empty database yields zero/zero, not an error', () async {
      final dao = daoOn(DateTime(2026, 8, 24));
      final summary = await dao.watchIncomeExpense().first;
      expect(summary.income, 0);
      expect(summary.expense, 0);
    });
  });

  group('FEAT07 D5: watchCategorySpending', () {
    test(
      'groups by category and buckets a null category as uncategorized',
      () async {
        final dao = daoOn(DateTime(2026, 8, 24));
        final wallet = await insertAccount('Wallet', AccountGroup.HOLDING, 0);
        final food = await insertCategory('Food');
        await insertTransaction(
          kind: TransactionKind.expense,
          amount: 15000,
          occurredOn: DateTime(2026, 8, 10),
          fromAccountId: wallet,
          categoryId: food,
        );
        await insertTransaction(
          kind: TransactionKind.expense,
          amount: 5000,
          occurredOn: DateTime(2026, 8, 11),
          fromAccountId: wallet,
        );
        // An income row must never contribute to spending.
        await insertTransaction(
          kind: TransactionKind.income,
          amount: 999999,
          occurredOn: DateTime(2026, 8, 12),
          toAccountId: wallet,
        );

        final rows = await dao.watchCategorySpending().first;

        expect(rows, hasLength(2));
        final foodRow = rows.firstWhere((r) => r.categoryId == food);
        expect(foodRow.name, 'Food');
        expect(foodRow.amount, 15000);
        final uncategorized = rows.firstWhere((r) => r.categoryId == null);
        expect(uncategorized.name, isNull);
        expect(uncategorized.amount, 5000);
      },
    );

    test('no spending this month yields an empty list, not an error', () async {
      final dao = daoOn(DateTime(2026, 8, 24));
      expect(await dao.watchCategorySpending().first, isEmpty);
    });
  });
}
