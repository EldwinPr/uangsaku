import '../database/app_database.dart';

/// `AccountDao` — writes for accounts, UC-02 slice only.
///
/// This issue implements `insert()` alone. The read methods the class
/// diagram draws (`watchPosition()`, `watchBalances()`, `watchDebtProgress()`)
/// are UC-01's and UC-10's and are deliberately absent; `update()` /
/// `setSettled()` belong to UC-02B / UC-10 (`plan.md` D9, D10) — `Account` is
/// create-only until those land (`pm/findings.md` F14).
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase`, the same shape `CategoryDao`,
/// `BudgetDao` and `SettingsDao` use (`context/index/decisions.md`
/// 2026-08-21, UC-13 ruling 1).
///
/// Writes **only** `Accounts`. No transaction row is ever written here —
/// the opening amount lives in `Accounts.openingAmount`, a column FEAT01
/// shipped (`plan.md` D4), for zero and non-zero opening amounts alike.
class AccountDao {
  AccountDao(this._db);

  final AppDatabase _db;

  /// Message 3 on `seq-uc02-add-account.drawio`: `insert(account)`.
  ///
  /// Returns the new account id (message 5) because drift's `insert()` gives
  /// it back for free; nobody in this issue consumes it — `AccountsNotifier`
  /// discards it and returns nothing to the screen (message 6 is `ok`; the
  /// write path never returns its result to the UI).
  Future<int> insert(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }
}
