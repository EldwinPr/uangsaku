import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'clock.dart';

/// `BudgetConsumption` — UC-12's per-group figure (`class-budgeting.drawio`:
/// *query result · amount / spent / remaining · includes the null-group
/// "Others" (D5)*).
///
/// [groupId] and [name] are both `null` for the "Others" row — the
/// `budget_group_id IS NULL` bucket on `Transactions` (FR-17). The string
/// "Others" is applied by the screen, never stored here (`plan.md` D4).
/// Every amount is an `int` counting minor units of `Settings.currency` —
/// never a `double` (NFR-2). Plain Dart, immutable, no Flutter import.
class BudgetConsumption {
  const BudgetConsumption({
    required this.groupId,
    required this.name,
    required this.amount,
    required this.spent,
  });

  /// `null` for Others.
  final int? groupId;

  /// `null` for Others — the "Others" label is the screen's, not the
  /// query's (D4).
  final String? name;

  /// The month's `BudgetPeriods` amount for this group, or 0 when no period
  /// row exists for the month — always 0 for Others, which can never have a
  /// period row (`BudgetPeriods.budgetGroupId` is `NOT NULL`) (D4).
  final int amount;

  /// Σ `Transactions.amount` WHERE `to_account_id IS NULL`, in-month,
  /// grouped by `budget_group_id` (`IS NULL` for Others) — never a `kind`
  /// filter (D2, `docs/enums.md`).
  final int spent;

  /// `amount - spent`, defined once so it cannot drift from the other two
  /// (D4). Negative is a legitimate value, rendered as-is — overspending is
  /// shown, never blocked (FR-12, NFR-4).
  int get remaining => amount - spent;
}

/// `BudgetDao` — period + consumption queries (UC-11, UC-12).
///
/// Reads `BudgetGroups`, `BudgetPeriods` and, for `watchConsumption()`,
/// `Transactions`; `deleteGroup()` also touches `Transactions` to null out
/// `budgetGroupId` on delete (D7, `drift.md` §DAOs — a DAO may join another
/// module's tables).
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase` instead, the same shape `CategoryDao` uses
/// (UC-13 D5, `context/index/decisions.md` 2026-08-21, "UC-13: two rulings
/// the real toolchain forced above the database" — both rulings bind
/// `BudgetDao` by name). `DatabaseAccessor` extends `DatabaseConnectionUser`,
/// which already declares `update<T, D>()` / `delete<T, D>()`, and this
/// class diagram gives `BudgetDao` its own `delete()`, an incompatible
/// (named-parameter) override that a `DatabaseAccessor` subclass cannot
/// declare.
class BudgetDao {
  BudgetDao(this._db, {this._clock = const Clock()});

  final AppDatabase _db;
  final Clock _clock;

  /// Every budget group, one emission per change.
  Stream<List<BudgetGroup>> watchGroups() =>
      _db.select(_db.budgetGroups).watch();

  /// Periods for the calendar month `monthsAgo` months before `Clock.today()`
  /// (D5) — `monthsAgo: 0` is the current month, `monthsAgo: 1` the previous
  /// one (FR-15). The general read; there is no separate
  /// `watchPreviousPeriods()`.
  Stream<List<BudgetPeriod>> watchPeriods({int monthsAgo = 0}) {
    final startsOn = _monthStart(monthsAgo: monthsAgo);
    return (_db.select(
      _db.budgetPeriods,
    )..where((row) => row.startsOn.equals(startsOn))).watch();
  }

  /// Message 2/3 on `seq-uc12-budget-consumption.drawio`: one watched
  /// `customSelect` returning one row per budget group plus exactly one
  /// "Others" row, for the calendar month `monthsAgo` months before
  /// `Clock.today()` (D5, same vocabulary as [watchPeriods]).
  ///
  /// Joins `BudgetGroups`, `BudgetPeriods` and `Transactions` directly
  /// (ISSUE-005 D1 — never `TransactionDao`), the same shape
  /// `AccountDao.watchPosition()` / `watchBalances()` ship. A group's
  /// `amount` comes from its `BudgetPeriods` row for this month, matched on
  /// `startsOn` exactly as [watchPeriods] matches it, and is 0 when no such
  /// row exists — **no pre-fill from the previous month** (FR-14, FR-15 is
  /// UC-11's setting affordance only). `spent` sums `Transactions.amount`
  /// where `toAccountId IS NULL` (D2 — never a `kind` filter) and
  /// `occurredOn` falls within the month's `[startsOn, endsOn]` bounds,
  /// grouped by `budgetGroupId`.
  ///
  /// The `UNION ALL` branch adds the Others row — `budgetGroupId IS NULL`
  /// — unconditionally, even when nothing is untagged (D3, FR-17). Ordered
  /// by `budgetGroupId` ascending with Others last (`group_id IS NULL`
  /// sorts non-null groups first); the diagram draws no ordering, so this
  /// is the neutral choice `watchBalances()` already established.
  Stream<List<BudgetConsumption>> watchConsumption({int monthsAgo = 0}) {
    final startsOn = _monthStart(monthsAgo: monthsAgo);
    final endsOn = _monthEnd(monthsAgo: monthsAgo);

    return _db
        .customSelect(
          '''
          SELECT * FROM (
            SELECT
              budget_groups.budget_group_id AS group_id,
              budget_groups.name            AS group_name,
              COALESCE(period.amount, 0)    AS amount,
              COALESCE((SELECT SUM(t.amount) FROM transactions t
                        WHERE t.budget_group_id = budget_groups.budget_group_id
                          AND t.to_account_id IS NULL
                          AND t.occurred_on >= ?
                          AND t.occurred_on <= ?), 0) AS spent
            FROM budget_groups
            LEFT JOIN budget_periods period
              ON period.budget_group_id = budget_groups.budget_group_id
              AND period.starts_on = ?
            UNION ALL
            SELECT
              NULL AS group_id,
              NULL AS group_name,
              0    AS amount,
              COALESCE((SELECT SUM(t.amount) FROM transactions t
                        WHERE t.budget_group_id IS NULL
                          AND t.to_account_id IS NULL
                          AND t.occurred_on >= ?
                          AND t.occurred_on <= ?), 0) AS spent
          )
          ORDER BY group_id IS NULL, group_id
          ''',
          variables: [
            Variable.withDateTime(startsOn),
            Variable.withDateTime(endsOn),
            Variable.withDateTime(startsOn),
            Variable.withDateTime(startsOn),
            Variable.withDateTime(endsOn),
          ],
          readsFrom: {_db.budgetGroups, _db.budgetPeriods, _db.transactions},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              BudgetConsumption(
                groupId: row.readNullable<int>('group_id'),
                name: row.readNullable<String>('group_name'),
                amount: row.read<int>('amount'),
                spent: row.read<int>('spent'),
              ),
          ],
        );
  }

  /// Inserts or updates the **current** month's amount for [groupId] (D6) —
  /// matches on group + `startsOn` inside one transaction, so two saves
  /// cannot race into two rows for one month. FR-16: no lock, proceeds at
  /// any point in the month.
  Future<void> upsert({required int groupId, required int amount}) async {
    final startsOn = _monthStart(monthsAgo: 0);
    final endsOn = _monthEnd(monthsAgo: 0);

    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.budgetPeriods)..where(
                (row) =>
                    row.budgetGroupId.equals(groupId) &
                    row.startsOn.equals(startsOn),
              ))
              .getSingleOrNull();

      if (existing == null) {
        await _db
            .into(_db.budgetPeriods)
            .insert(
              BudgetPeriodsCompanion.insert(
                budgetGroupId: groupId,
                startsOn: startsOn,
                endsOn: endsOn,
                amount: amount,
              ),
            );
      } else {
        await (_db.update(_db.budgetPeriods)..where(
              (row) => row.budgetPeriodId.equals(existing.budgetPeriodId),
            ))
            .write(BudgetPeriodsCompanion(amount: Value(amount)));
      }
    });
  }

  /// Deletes one period row and nothing else (FR-18, FR-16 rewritten — no
  /// lock, no refusal).
  Future<void> delete({required int periodId}) async {
    await (_db.delete(
      _db.budgetPeriods,
    )..where((row) => row.budgetPeriodId.equals(periodId))).go();
  }

  /// Adds a budget group (FR-18, moved from UC-13 step 3).
  Future<void> insertGroup({required String name}) async {
    await _db
        .into(_db.budgetGroups)
        .insert(BudgetGroupsCompanion.insert(name: name));
  }

  /// Renames a budget group (FR-18).
  Future<void> updateGroup({required int groupId, required String name}) async {
    await (_db.update(_db.budgetGroups)
          ..where((row) => row.budgetGroupId.equals(groupId)))
        .write(BudgetGroupsCompanion(name: Value(name)));
  }

  /// Deletes a budget group, its periods, and blanks the tag on every
  /// transaction that referenced it — every transaction stays standing
  /// (D7): NFR-4 forbids refusing the delete, `BudgetPeriods.budgetGroupId`
  /// is NOT NULL so a period cannot survive without a group, and FR-17 keeps
  /// the untagged transactions visible under "Others" rather than let them
  /// escape the budget view. One transaction, explicit statement order,
  /// independent of `PRAGMA foreign_keys` (which is off).
  Future<void> deleteGroup({required int groupId}) async {
    await _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((row) => row.budgetGroupId.equals(groupId)))
          .write(const TransactionsCompanion(budgetGroupId: Value(null)));
      await (_db.delete(
        _db.budgetPeriods,
      )..where((row) => row.budgetGroupId.equals(groupId))).go();
      await (_db.delete(
        _db.budgetGroups,
      )..where((row) => row.budgetGroupId.equals(groupId))).go();
    });
  }

  /// The first day, at midnight, of the calendar month `monthsAgo` months
  /// before `Clock.today()`'s month (D5).
  DateTime _monthStart({required int monthsAgo}) {
    final today = _clock.today();
    final totalMonths = today.year * 12 + (today.month - 1) - monthsAgo;
    return DateTime(totalMonths ~/ 12, totalMonths % 12 + 1, 1);
  }

  /// The last day, at midnight, of the same month `_monthStart` returns —
  /// inclusive, because the column is named `ends_on` (D5).
  DateTime _monthEnd({required int monthsAgo}) {
    final start = _monthStart(monthsAgo: monthsAgo);
    return DateTime(start.year, start.month + 1, 0);
  }
}
