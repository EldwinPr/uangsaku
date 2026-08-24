import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'settings_dao.dart';
import 'settings_table.dart';

/// The app's current currency (message 6 on `seq-uc14-choose-currency.drawio`
/// — `Stream<Currency>`, and message 15, its updated emission after a write).
///
/// **Kept alive — no `.autoDispose`.** Every amount displayed anywhere in the
/// app will eventually need the exponent this currency implies
/// (`docs/enums.md`), so this provider must not dispose when `CurrencyScreen`
/// closes. `riverpod.md` §Code generation names this exact provider as the
/// one that needs to say so explicitly.
///
/// Hand-written `StreamProvider`, not `@riverpod`: `riverpod_generator`
/// throws `InvalidTypeException` on any provider whose signature mentions a
/// drift-generated row class (`context/index/decisions.md` 2026-08-21, UC-13
/// ruling 2 — `Currency` is declared in `app_database.g.dart`, a `part of
/// 'app_database.dart'`). Declaring it without `.autoDispose` is the whole of
/// `keepAlive` for a hand-written provider — the same property
/// `appDatabaseProvider` verified (FEAT01 ruling 3).
final currencyProvider = StreamProvider<Currency>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SettingsDao(database).watchCurrency();
});

/// The app's current UI language (FEAT03 D2) — `MaterialApp.locale`
/// (`app.dart`) watches this to drive `AppLocalizations`. Kept alive for the
/// same reason [currencyProvider] is: every screen in the app needs it, not
/// just the settings screen that writes it.
///
/// Hand-written, not `@riverpod`, for the same reason as [currencyProvider]
/// — `AppLanguage` is declared in `settings_table.dart`, a drift-adjacent
/// enum type the generator has been unreliable with here
/// (`context/index/decisions.md` 2026-08-21, UC-13 ruling 2).
final languageProvider = StreamProvider<AppLanguage>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SettingsDao(database).watchLanguage();
});

/// The app's current theme mode preference (FEAT03 D2) — `MaterialApp`
/// (`app.dart`) maps this to Flutter's own `ThemeMode`. Kept alive, same
/// reasoning as [languageProvider].
final themeModeProvider = StreamProvider<AppThemeMode>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SettingsDao(database).watchThemeMode();
});

/// The app's current theme seed color, or `null` for the app's default seed
/// (FEAT03 D1). Kept alive, same reasoning as [languageProvider].
final seedColorProvider = StreamProvider<int?>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SettingsDao(database).watchSeedColor();
});

/// `SettingsNotifier` — the write side (message 10 → 11:
/// `setCurrency(chosen)`). Forwards to `SettingsDao` and returns nothing to
/// the screen — the re-labelled currency arrives on `currencyProvider`'s next
/// emission (message 15), never as this call's return value (`riverpod.md`,
/// the read/write asymmetry).
///
/// Hand-written `NotifierProvider`, not `@riverpod`, for the same reason as
/// `currencyProvider` above, and for a second reason on top of it:
/// `riverpod_generator` would name the generated provider
/// `settingsNotifierProvider`, not the class diagram's `settingsProvider`
/// (the `categoriesProvider` precedent, same ruling).
///
/// This screen reads exactly one drift stream (message 3), so the UC-11
/// multi-stream `Notifier<AsyncValue<...>>` shape does not apply here
/// (`context/index/decisions.md` 2026-08-22) — a plain `StreamProvider` over
/// `watchCurrency()` is the read shape, and `SettingsNotifier` needs no state
/// of its own.
class SettingsNotifier extends Notifier<void> {
  late SettingsDao _dao;

  @override
  void build() {
    _dao = SettingsDao(ref.watch(appDatabaseProvider));
  }

  /// Message 11: re-labels the app's currency (FR-19, D6 — no conversion, no
  /// other table touched).
  Future<void> setCurrency(Currency currency) {
    return _dao.setCurrency(currency);
  }

  /// FEAT03 D2: writes only the stored language.
  Future<void> setLanguage(AppLanguage language) {
    return _dao.setLanguage(language);
  }

  /// FEAT03 D2: writes only the stored theme mode.
  Future<void> setThemeMode(AppThemeMode themeMode) {
    return _dao.setThemeMode(themeMode);
  }

  /// FEAT03 D2: writes only the stored theme seed color. `null` resets to
  /// the app's default seed.
  Future<void> setSeedColor(int? seedColor) {
    return _dao.setSeedColor(seedColor);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, void>(
  SettingsNotifier.new,
);
