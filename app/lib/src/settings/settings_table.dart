import 'package:drift/drift.dart';

/// The currency every amount in the app is recorded in — app-level, one
/// value for the whole database (FR-19, ISSUE-007 D1). No per-account and
/// no per-transaction currency, no exchange rate, no conversion.
///
/// The exponent turns a stored `int` back into a displayable figure —
/// `docs/enums.md`.
enum Currency {
  /// Exponent 0 — no minor unit in practice.
  IDR,

  /// Exponent 2 — cents.
  USD,
}

/// `Settings` — the single-row table holding the app's currency.
///
/// The currency has to exist before any amount can be interpreted, since
/// every amount column elsewhere is an `int` of minor units.
class Settings extends Table {
  IntColumn get settingsId => integer().autoIncrement()();

  TextColumn get currency => textEnum<Currency>()();
}
