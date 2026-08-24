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

/// The app's UI language (FEAT03 D1) — a real toggle, not a one-way rewrite.
/// Every user-facing string in the app has a form in both.
enum AppLanguage {
  /// English.
  en,

  /// Bahasa Indonesia — the app's home market and the default (FEAT03 D1).
  id,
}

/// The app's theme brightness preference (FEAT03 D1). A project-owned enum,
/// not Flutter's own `ThemeMode` — this file imports only
/// `package:drift/drift.dart`, never `material.dart` (same reasoning
/// `AccountGroup`/`TransactionKind` already establish). Mapped to Flutter's
/// `ThemeMode` in the widget layer only.
enum AppThemeMode {
  /// Follows the platform brightness.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// `Settings` — the single-row table holding the app's currency, language,
/// theme mode and theme seed color.
///
/// The currency has to exist before any amount can be interpreted, since
/// every amount column elsewhere is an `int` of minor units.
///
/// `schemaVersion` 2->3 (FEAT03 D1): `locale`, `themeMode` and `seedColor`
/// added via a guided migration (`app_database.steps.dart`'s `from2To3`).
class Settings extends Table {
  IntColumn get settingsId => integer().autoIncrement()();

  TextColumn get currency => textEnum<Currency>()();

  /// FEAT03 D1 — defaults to `AppLanguage.id`, the app's home market.
  TextColumn get locale =>
      textEnum<AppLanguage>().withDefault(const Constant('id'))();

  /// FEAT03 D1 — defaults to `AppThemeMode.system`.
  TextColumn get themeMode =>
      textEnum<AppThemeMode>().withDefault(const Constant('system'))();

  /// An ARGB32 int (`Color.toARGB32()`). `null` means "use the app's default
  /// seed" (FEAT03 D1) — nullable, so no SQL-level default is needed.
  IntColumn get seedColor => integer().nullable()();
}
