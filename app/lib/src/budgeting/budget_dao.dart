import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'clock.dart';

/// `BudgetDao` — period + consumption queries (UC-11; `watchConsumption()` is
/// UC-12's and is **not** written here, per the plan's `Out of scope`).
///
/// Reads `BudgetGroups, BudgetPeriods`; `deleteGroup()` also touches
/// `Transactions` to null out `budgetGroupId` on delete (D7, `drift.md`
/// §DAOs — a DAO may join another module's tables).
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
