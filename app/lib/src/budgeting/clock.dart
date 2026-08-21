/// `Clock` — the injected time source (`class-budgeting.drawio`).
///
/// Deciding which calendar month `SetBudgetScreen` shows and writes to is
/// still a question about today's date (D5), so `BudgetDao` asks a `Clock`
/// rather than reading `DateTime.now()` directly — the same date arithmetic
/// then runs identically under test, including the January case where the
/// previous month is December of the prior year.
///
/// Its original justification was FR-16's lock, removed 2026-08-20
/// (`docs/statuses.md`); it survives the removal only because messages 3-4 on
/// `seq-uc11-set-budget.drawio` still ask it the time.
class Clock {
  const Clock();

  /// Today's date, truncated to midnight — `DateTime.now()` carries wall-clock
  /// time components that month arithmetic never needs.
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
