import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uangsaku/src/accounts/accounts_providers.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/backup_file_system.dart';
import 'package:uangsaku/src/settings/settings_providers.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

/// A [BackupFileSystem] test double (D2): `documentsDirectory()` points at a
/// real, throwaway temp directory rather than the real
/// `getApplicationDocumentsDirectory()` — the same real `dart:io` file I/O
/// runs, just against a directory this test owns and cleans up. `share()`
/// and `pickSqliteFile()` never touch a platform channel; they only record
/// or return a canned value.
class _FakeBackupFileSystem extends BackupFileSystem {
  _FakeBackupFileSystem(this.dir);

  final Directory dir;
  File? sharedFile;
  File? pickResult;

  @override
  Future<Directory> documentsDirectory() async => dir;

  @override
  Future<void> share(File file) async {
    sharedFile = file;
  }

  @override
  Future<File?> pickSqliteFile() async => pickResult;
}

void main() {
  late Directory tempDir;
  late _FakeBackupFileSystem fileSystem;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('feat20-backup-test');
    fileSystem = _FakeBackupFileSystem(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  String dbPath() => p.join(tempDir.path, 'app_database.sqlite');

  /// A `ProviderContainer` whose `appDatabaseProvider` opens a real,
  /// file-backed `AppDatabase` at [dbPath] — not `NativeDatabase.memory()` —
  /// because backup/restore/delete operate on the file itself. `.overrideWith`
  /// (not `.overrideWithValue`) so `ref.invalidate(appDatabaseProvider)`
  /// inside the notifier actually reopens a fresh instance against the same
  /// file, exactly as it does against the real app-database path in
  /// production.
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase(File(dbPath())));
          // Mirrors the real appDatabaseProvider's own `ref.onDispose`
          // (app_database.dart) — otherwise a leftover open connection
          // holds a Windows file lock past `tearDown`'s directory delete.
          ref.onDispose(db.close);
          return db;
        }),
        databaseMaintenanceProvider.overrideWith(
          () => DatabaseMaintenanceNotifier(fileSystem: fileSystem),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'FEAT20 D3: backup() closes the database and shares the correct file path',
    () async {
      final c = container();
      // Reading it forces the database open, so there is something to close.
      c.read(appDatabaseProvider);

      await c.read(databaseMaintenanceProvider.notifier).backup();

      expect(fileSystem.sharedFile, isNotNull);
      expect(fileSystem.sharedFile!.path, dbPath());
    },
  );

  test('FEAT20 D3: backup -> deleteAll -> restore round-trip brings seeded data back', () async {
    final c = container();
    final firstDb = c.read(appDatabaseProvider);
    await firstDb
        .into(firstDb.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Wallet',
            group: AccountGroup.HOLDING,
            openingAmount: 12345,
          ),
        );

    // Close so the file on disk reflects the insert, then copy it to a
    // separate backup location directly via File.copy (DoD).
    await firstDb.close();
    final backupPath = p.join(tempDir.path, 'manual-backup.sqlite');
    await File(dbPath()).copy(backupPath);

    // Reopen (mirrors what `backup()` itself would have done next) before
    // handing the container to `deleteAll()`.
    c.invalidate(appDatabaseProvider);
    c.read(appDatabaseProvider);

    await c.read(databaseMaintenanceProvider.notifier).deleteAll();

    final afterDelete = c.read(appDatabaseProvider);
    expect(await afterDelete.select(afterDelete.accounts).get(), isEmpty);

    await c
        .read(databaseMaintenanceProvider.notifier)
        .restore(File(backupPath));

    final afterRestore = c.read(appDatabaseProvider);
    final rows = await afterRestore.select(afterRestore.accounts).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Wallet');
    expect(rows.single.openingAmount, 12345);
  });

  test('FEAT20 D3: deleteAll() on its own leaves a fresh, empty, reseeded Settings row', () async {
    final c = container();
    final firstDb = c.read(appDatabaseProvider);
    await firstDb
        .into(firstDb.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Wallet',
            group: AccountGroup.HOLDING,
            openingAmount: 5000,
          ),
        );

    await c.read(databaseMaintenanceProvider.notifier).deleteAll();

    final fresh = c.read(appDatabaseProvider);
    expect(await fresh.select(fresh.accounts).get(), isEmpty);

    final settingsRows = await fresh.select(fresh.settings).get();
    expect(settingsRows, hasLength(1));
    // The same seed `beforeOpen` gives a brand-new install (app_database.dart).
    expect(settingsRows.single.currency, Currency.IDR);
    expect(settingsRows.single.locale, AppLanguage.id);
    expect(settingsRows.single.themeMode, AppThemeMode.system);
    expect(settingsRows.single.seedColor, isNull);
  });

  test('FEAT20: backup()/deleteAll() do not deadlock with an active watched '
      'StreamProvider still subscribed (regression — discovered live, not by '
      'any earlier test in this file; see settings_providers.dart\'s '
      '_closeCurrentDatabase doc comment and testing.md)', () async {
    final c = container();
    // Mirrors AppShell's IndexedStack (FEAT02 D1): a screen's provider
    // stays subscribed to appDatabaseProvider even while a different tab
    // is showing. Closing `financialPositionProvider`'s underlying
    // AppDatabase while this subscription is still live is exactly the
    // scenario that hung forever before `_closeCurrentDatabase` reordered
    // invalidate() before close(). The assertion that matters here is the
    // absence of a hang (a regressed reordering times out, it does not
    // throw) — proven live on Android that the operation also completes
    // correctly end to end (Home's figures/Settings reset to fresh-install
    // defaults immediately after).
    //
    // This test does NOT also assert deleteAll()'s file-deletion succeeds
    // while `sub`/`sub2` keep a listener alive for the test's whole
    // lifetime: on Windows (this suite's host, not this app's Android/iOS
    // targets — CI runs Linux) that freshly-reopened connection holds an
    // exclusive OS-level lock on the file for as long as it stays open,
    // which — unlike the momentary races `_retryOnFileLock` exists for — is
    // indefinite in this specific artificial "listener never torn down"
    // setup, not a bug in `deleteAll()` itself. POSIX (Android/iOS, and this
    // suite's own Linux CI run) tolerates deleting/overwriting a file another
    // process still has open, which is exactly why the live Android
    // verification saw no such failure.
    final sub = c.listen(financialPositionProvider, (_, _) {});
    addTearDown(sub.close);

    await c
        .read(databaseMaintenanceProvider.notifier)
        .backup()
        .timeout(const Duration(seconds: 5));

    final sub2 = c.listen(financialPositionProvider, (_, _) {});
    addTearDown(sub2.close);
    final deleteAll = c
        .read(databaseMaintenanceProvider.notifier)
        .deleteAll()
        .timeout(const Duration(seconds: 5));
    if (Platform.isWindows) {
      // The lock described above is real on this host; only the no-hang
      // guarantee is being tested here. `catchError` still lets a genuine
      // `TimeoutException` (a real regression) propagate and fail the test.
      await deleteAll.catchError((Object e) {
        if (e is! FileSystemException) throw e;
      });
    } else {
      await deleteAll;
    }
  });
}
