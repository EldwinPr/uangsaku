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
}

final settingsProvider = NotifierProvider<SettingsNotifier, void>(
  SettingsNotifier.new,
);
