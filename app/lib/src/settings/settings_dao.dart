import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'settings_table.dart';

/// `SettingsDao` — the one settings row (UC-14).
///
/// Reads and writes `Settings` only. `setCurrency()` re-labels the app's
/// currency; it never touches `Account.opening_amount`, `Transaction.amount`
/// or `Budget_Period.amount`, and no exponent arithmetic runs here — the
/// exponent (`docs/enums.md`) is a rendering concern, not a storage one (D6).
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase`, the same shape `CategoryDao` and
/// `BudgetDao` use (`context/index/decisions.md` 2026-08-21, UC-13 ruling 1).
/// `DatabaseAccessor` extends `DatabaseConnectionUser`, which already
/// declares `update<T, D>()` / `delete<T, D>()`, so no DAO in this app
/// extends it — `SettingsDao` follows the same shape even though its own
/// method names would not themselves have collided (D1, amended).
class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  /// The app's current currency, one emission per change to the single
  /// `Settings` row (message 6).
  Stream<Currency> watchCurrency() {
    return _db.select(_db.settings).watchSingle().map((row) => row.currency);
  }

  /// Re-labels the app's currency. Writes the `currency` column of the one
  /// `Settings` row and nothing else — no conversion, no other table read or
  /// written (FR-19, D6, `context/index/decisions.md` 2026-08-22).
  Future<void> setCurrency(Currency currency) async {
    await _db
        .update(_db.settings)
        .write(SettingsCompanion(currency: Value(currency)));
  }
}
