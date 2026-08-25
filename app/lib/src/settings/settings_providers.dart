import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import 'backup_file_system.dart';
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

/// `DatabaseMaintenanceNotifier` — backup, restore and wipe the whole
/// database (`class-settings.drawio`, FEAT20). Matches [SettingsNotifier]'s
/// shape: same module, same always-mounted `SettingsScreen`, so this stays
/// `NotifierProvider<..., void>` without `.autoDispose` for the same reason
/// [currencyProvider] above stays kept alive.
///
/// Every plugin-dependent operation goes through the injected
/// [BackupFileSystem] (D2) rather than calling `share_plus`/`file_picker`
/// directly — the same testability shape `Clock` established for
/// `budgeting`. Plain `dart:io` `File` calls stay direct here, since they
/// work correctly under `flutter test` with no mocking needed.
class DatabaseMaintenanceNotifier extends Notifier<void> {
  DatabaseMaintenanceNotifier({this.fileSystem = const BackupFileSystem()});

  final BackupFileSystem fileSystem;

  @override
  void build() {}

  /// Invalidates [appDatabaseProvider] **before** closing the outgoing
  /// instance — load-bearing order, discovered live (not caught by any
  /// isolated `ProviderContainer` test, `testing.md` FEAT20 entry): `AppShell`'s
  /// `IndexedStack` (FEAT02 D1) keeps every tab's `ref.watch(appDatabaseProvider)`
  /// dependents subscribed permanently, and drift's `close()`
  /// (`StreamQueryStore.close()`) waits for every one of those active query
  /// streams to unsubscribe before it resolves. Closing first therefore
  /// deadlocks forever — nothing ever prompts those dependents to
  /// unsubscribe. Invalidating first triggers Riverpod's eager rebuild of
  /// every still-listened dependent (a new `AppDatabase` opens, every screen's
  /// `StreamProvider` re-subscribes against it, and only then do their
  /// subscriptions on the outgoing instance actually cancel) — which is what
  /// finally lets `close()` complete. Verified live on a running emulator:
  /// closing-then-invalidating hangs indefinitely with zero errors on either
  /// the Dart or platform side; invalidating-then-closing completes
  /// immediately, no delay needed.
  Future<AppDatabase> _closeCurrentDatabase() async {
    final current = ref.read(appDatabaseProvider);
    ref.invalidate(appDatabaseProvider);
    await current.close();
    return current;
  }

  /// Closes the live database, hands its file to the OS share sheet. No
  /// result comes back to the screen — the caller fires and forgets, same as
  /// every other write in this app.
  Future<void> backup() async {
    await _closeCurrentDatabase();
    final file = await _databaseFile();
    await fileSystem.share(file);
  }

  /// Lets the owner pick a candidate file to restore from — `null` means the
  /// picker was cancelled (not a refusal, NFR-4). Validation of the picked
  /// file's SQLite header is the screen's job (D4), not this notifier's.
  Future<File?> pickRestoreCandidate() => fileSystem.pickSqliteFile();

  /// Closes the live database, removes any sidecar files, overwrites the
  /// main database file with [source]. Every currently mounted screen already
  /// rebuilt against a fresh `AppDatabase` the moment [_closeCurrentDatabase]
  /// invalidated the provider (before this method even touches the file) —
  /// by the time the restored bytes land, the next read each screen's
  /// `StreamProvider` issues picks them up automatically, since every
  /// DAO-backed provider already `ref.watch`es [appDatabaseProvider]. Verified
  /// live: the freshly reopened `AppDatabase` recreates its file at the same
  /// path the instant it's invalidated (drift creates the file if missing),
  /// so overwriting it after that point — not before — is what actually lands
  /// the restored bytes where the live connection reads from.
  Future<void> restore(File source) async {
    await _closeCurrentDatabase();
    final target = await _databaseFile();
    await _deleteSidecarFiles(target.path);
    await _retryOnFileLock(() => source.copy(target.path));
  }

  /// Closes the live database and deletes its file outright, along with any
  /// sidecar files. `beforeOpen`'s `wasCreated` branch (`app_database.dart`)
  /// reseeds a fresh `Settings` row the moment the freshly invalidated
  /// provider's dependents reopen it — exactly a brand-new install's shape,
  /// no new seeding code needed here. Verified live: `Home`'s figures and
  /// `Settings`' theme both reset to their fresh-install defaults immediately
  /// after this completes.
  Future<void> deleteAll() async {
    await _closeCurrentDatabase();
    final target = await _databaseFile();
    await _deleteSidecarFiles(target.path);
    if (await target.exists()) {
      await _retryOnFileLock(target.delete);
    }
  }

  /// The same path `drift_flutter`'s `driftDatabase(name: 'app_database')`
  /// resolves internally (D1, `BackupFileSystem.documentsDirectory()`'s doc
  /// comment) — `<application documents dir>/app_database.sqlite`.
  Future<File> _databaseFile() async {
    final dir = await fileSystem.documentsDirectory();
    return File(p.join(dir.path, 'app_database.sqlite'));
  }

  /// Best-effort housekeeping: a stale sidecar from a prior session can
  /// never desync against a freshly restored or freshly deleted main file,
  /// even though this app's own connection has never opted into WAL mode.
  Future<void> _deleteSidecarFiles(String mainPath) async {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('$mainPath$suffix');
      if (await f.exists()) await _retryOnFileLock(f.delete);
    }
  }

  /// [_closeCurrentDatabase] invalidates before its outgoing instance
  /// finishes closing (its own doc comment) — a still-listened screen's
  /// `StreamProvider` can rebuild and reopen a *new* `AppDatabase` against
  /// this same path moments before [restore]/[deleteAll] gets to mutate the
  /// file, briefly holding an OS-level lock on it. On Android/iOS this is
  /// harmless (POSIX lets a file be unlinked/overwritten while another
  /// process still holds it open); on Windows the OS refuses the operation
  /// outright until that fresh connection's handle is released, which is
  /// milliseconds away, not a real contention. A handful of short retries
  /// rides out that window on every platform rather than papering over it
  /// with a platform check — caught by this file's own regression test
  /// (`database_maintenance_notifier_test.dart`, "do not deadlock with an
  /// active watched StreamProvider"), which reproduces the race by keeping a
  /// listener subscribed exactly the way a mounted screen would.
  Future<T> _retryOnFileLock<T>(Future<T> Function() action) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await action();
      } on FileSystemException catch (_) {
        if (attempt >= 4) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }
}

final databaseMaintenanceProvider =
    NotifierProvider<DatabaseMaintenanceNotifier, void>(
      DatabaseMaintenanceNotifier.new,
    );
