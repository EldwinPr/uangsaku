import 'package:drift/drift.dart';

/// `Budget_Group` — a user-named bucket a budget period can be set against.
///
/// `budget_group_id IS NULL` on a `Transaction` is the "Others" bucket
/// (FR-17) — it is not a row here (`docs/enums.md`).
class BudgetGroups extends Table {
  IntColumn get budgetGroupId => integer().autoIncrement()();

  TextColumn get name => text()();
}

/// `Budget_Period` — a date-range budget against a `BudgetGroups` row.
///
/// `startsOn` / `endsOn` rather than a `YYYY-MM` key: a month is a calendar
/// month (decided 2026-08-20), and the date pair also makes quarterly and
/// yearly rollups a date-range sum rather than a new column (NFR-3). No
/// stored lifecycle state — FR-16's lock was removed 2026-08-20.
class BudgetPeriods extends Table {
  IntColumn get budgetPeriodId => integer().autoIncrement()();

  IntColumn get budgetGroupId =>
      integer().references(BudgetGroups, #budgetGroupId)();

  DateTimeColumn get startsOn => dateTime()();

  DateTimeColumn get endsOn => dateTime()();

  /// Minor units of `Settings.currency`. Never a `double` — NFR-2.
  IntColumn get amount => integer()();
}
