import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/budgeting/budget_dao.dart';
import 'package:uangsaku/src/budgeting/clock.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// A `Clock` fixed to one date, so month arithmetic is deterministic under
/// test (D5).
class _FixedClock extends Clock {
  _FixedClock(this._date);

  final DateTime _date;

  @override
  DateTime today() => _date;
}

void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  BudgetDao daoOn(DateTime today) =>
      BudgetDao(database, clock: _FixedClock(today));

  Future<int> insertGroup(BudgetDao dao, String name) async {
    await dao.insertGroup(name: name);
    final row = await (database.select(
      database.budgetGroups,
    )..where((row) => row.name.equals(name))).getSingle();
    return row.budgetGroupId;
  }

  group('FR-12 / FR-16: upsert', () {
    test('inserts a row for a group and a month with no row, and a second upsert for the same group and month updates it, leaving exactly one row', () async {
      final dao = daoOn(DateTime(2026, 8, 21));
      final groupId = await insertGroup(dao, 'Groceries');

      await dao.upsert(groupId: groupId, amount: 1000000);
      var periods = await dao.watchPeriods().first;
      expect(periods, hasLength(1));
      expect(periods.single.amount, 1000000);

      // Mid-month change proceeds — no lock (FR-16 rewritten 2026-08-20).
      await dao.upsert(groupId: groupId, amount: 1500000);
      periods = await dao.watchPeriods().first;
      expect(periods, hasLength(1));
      expect(periods.single.amount, 1500000);
    });
  });

  group('D5: a month on disk is a calendar month', () {
    test('a 31-day month (August)', () async {
      final dao = daoOn(DateTime(2026, 8, 21));
      final groupId = await insertGroup(dao, 'Groceries');
      await dao.upsert(groupId: groupId, amount: 1);

      final period = await dao.watchPeriods().first;
      expect(period.single.startsOn, DateTime(2026, 8, 1));
      expect(period.single.endsOn, DateTime(2026, 8, 31));
    });

    test('a 30-day month (September)', () async {
      final dao = daoOn(DateTime(2026, 9, 15));
      final groupId = await insertGroup(dao, 'Groceries');
      await dao.upsert(groupId: groupId, amount: 1);

      final period = await dao.watchPeriods().first;
      expect(period.single.startsOn, DateTime(2026, 9, 1));
      expect(period.single.endsOn, DateTime(2026, 9, 30));
    });

    test('February, a non-leap year', () async {
      final dao = daoOn(DateTime(2026, 2, 10));
      final groupId = await insertGroup(dao, 'Groceries');
      await dao.upsert(groupId: groupId, amount: 1);

      final period = await dao.watchPeriods().first;
      expect(period.single.startsOn, DateTime(2026, 2, 1));
      expect(period.single.endsOn, DateTime(2026, 2, 28));
    });

    test(
      'January — the previous month is December of the prior year',
      () async {
        final dao = daoOn(DateTime(2027, 1, 5));
        final groupId = await insertGroup(dao, 'Groceries');
        await dao.upsert(groupId: groupId, amount: 1);

        final current = await dao.watchPeriods().first;
        expect(current.single.startsOn, DateTime(2027, 1, 1));
        expect(current.single.endsOn, DateTime(2027, 1, 31));

        // No December row exists yet, but the query for it must resolve to
        // December of the *prior* year, not January's own prior month index.
        final previous = await dao.watchPeriods(monthsAgo: 1).first;
        expect(previous, isEmpty);
      },
    );
  });

  group('FR-15: the pre-fill data the notifier merges (D4)', () {
    test('a previous-month row and no current-month row — the previous amount is what a current-month query cannot see', () async {
      final dao = daoOn(DateTime(2027, 1, 10));
      final groupId = await insertGroup(dao, 'Groceries');

      // Write directly for December, the previous month, to set up the
      // scenario without going through upsert (which only ever targets
      // the current month, D6).
      await database
          .into(database.budgetPeriods)
          .insert(
            BudgetPeriodsCompanion.insert(
              budgetGroupId: groupId,
              startsOn: DateTime(2026, 12, 1),
              endsOn: DateTime(2026, 12, 31),
              amount: 500000,
            ),
          );

      final current = await dao.watchPeriods().first;
      expect(current, isEmpty);

      final previous = await dao.watchPeriods(monthsAgo: 1).first;
      expect(previous, hasLength(1));
      expect(previous.single.amount, 500000);
    });

    test('a current-month row exists — the current amount wins over the previous month (FR-16)', () async {
      final dao = daoOn(DateTime(2027, 1, 10));
      final groupId = await insertGroup(dao, 'Groceries');

      await database
          .into(database.budgetPeriods)
          .insert(
            BudgetPeriodsCompanion.insert(
              budgetGroupId: groupId,
              startsOn: DateTime(2026, 12, 1),
              endsOn: DateTime(2026, 12, 31),
              amount: 500000,
            ),
          );
      await dao.upsert(groupId: groupId, amount: 750000);

      final current = await dao.watchPeriods().first;
      expect(current, hasLength(1));
      expect(current.single.amount, 750000);

      final previous = await dao.watchPeriods(monthsAgo: 1).first;
      expect(previous, hasLength(1));
      expect(previous.single.amount, 500000);
    });

    test(
      'neither month has a row — both queries return nothing for the group',
      () async {
        final dao = daoOn(DateTime(2027, 1, 10));
        await insertGroup(dao, 'Groceries');

        expect(await dao.watchPeriods().first, isEmpty);
        expect(await dao.watchPeriods(monthsAgo: 1).first, isEmpty);
      },
    );
  });

  test('FR-14: writing this month leaves the previous month untouched, and nothing is carried forward to a month never written', () async {
    final dao = daoOn(DateTime(2026, 8, 21));
    final groupId = await insertGroup(dao, 'Groceries');

    await database
        .into(database.budgetPeriods)
        .insert(
          BudgetPeriodsCompanion.insert(
            budgetGroupId: groupId,
            startsOn: DateTime(2026, 7, 1),
            endsOn: DateTime(2026, 7, 31),
            amount: 200000,
          ),
        );

    await dao.upsert(groupId: groupId, amount: 300000);

    final july = await (database.select(
      database.budgetPeriods,
    )..where((row) => row.startsOn.equals(DateTime(2026, 7, 1)))).getSingle();
    expect(july.amount, 200000);

    final all = await database.select(database.budgetPeriods).get();
    expect(all, hasLength(2));

    final september = await (database.select(
      database.budgetPeriods,
    )..where((row) => row.startsOn.equals(DateTime(2026, 9, 1)))).get();
    expect(september, isEmpty);
  });

  test(
    'FR-18 / NFR-4: delete(periodId) removes the period and nothing else',
    () async {
      final dao = daoOn(DateTime(2026, 8, 21));
      final groupId = await insertGroup(dao, 'Groceries');
      await dao.upsert(groupId: groupId, amount: 100000);
      final period = await dao.watchPeriods().first;

      await dao.delete(periodId: period.single.budgetPeriodId);

      expect(await dao.watchPeriods().first, isEmpty);
      final group = await (database.select(
        database.budgetGroups,
      )..where((row) => row.budgetGroupId.equals(groupId))).getSingle();
      expect(group.name, 'Groceries');
    },
  );

  test('FR-18 / NFR-4: deleteGroup() on a group with periods and a tagged transaction succeeds, removes the group and its periods, and leaves the transaction with budgetGroupId null', () async {
    final dao = daoOn(DateTime(2026, 8, 21));
    final groupId = await insertGroup(dao, 'Groceries');
    await dao.upsert(groupId: groupId, amount: 100000);

    final transactionId = await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: TransactionKind.expense,
            amount: 50000,
            occurredOn: DateTime(2026, 8, 21),
            budgetGroupId: Value(groupId),
          ),
        );

    await dao.deleteGroup(groupId: groupId);

    final groups = await database.select(database.budgetGroups).get();
    expect(groups, isEmpty);

    final periods = await database.select(database.budgetPeriods).get();
    expect(periods, isEmpty);

    final transaction = await (database.select(
      database.transactions,
    )..where((row) => row.transactionId.equals(transactionId))).getSingle();
    expect(transaction.budgetGroupId, isNull);
    // The transaction itself survives — a group delete never destroys a
    // transaction (D7).
    expect(transaction.amount, 50000);
  });

  group('Empty and boundary states', () {
    test('no groups at all — watchGroups() emits an empty list', () async {
      final dao = daoOn(DateTime(2026, 8, 21));
      expect(await dao.watchGroups().first, isEmpty);
    });

    test('a group with no period in either month', () async {
      final dao = daoOn(DateTime(2026, 8, 21));
      await insertGroup(dao, 'Groceries');

      expect(await dao.watchPeriods().first, isEmpty);
      expect(await dao.watchPeriods(monthsAgo: 1).first, isEmpty);
    });

    test('a month with rows for some groups only', () async {
      final dao = daoOn(DateTime(2026, 8, 21));
      final withRow = await insertGroup(dao, 'Groceries');
      await insertGroup(dao, 'Transport');

      await dao.upsert(groupId: withRow, amount: 100000);

      final groups = await dao.watchGroups().first;
      expect(groups, hasLength(2));

      final periods = await dao.watchPeriods().first;
      expect(periods, hasLength(1));
      expect(periods.single.budgetGroupId, withRow);
    });
  });
}
