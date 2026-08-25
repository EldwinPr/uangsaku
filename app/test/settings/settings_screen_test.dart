import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/settings_providers.dart';
import 'package:uangsaku/src/settings/settings_screen.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

/// FEAT20 D6/DoD: a test double that skips real close/copy/delete file I/O
/// — the Data section's widget tests are about *which dialog shows and
/// which method gets called*, not about `DatabaseMaintenanceNotifier`'s own
/// file behavior (already covered by `database_maintenance_notifier_test.dart`).
class _RecordingDatabaseMaintenanceNotifier
    extends DatabaseMaintenanceNotifier {
  _RecordingDatabaseMaintenanceNotifier({this.pickResult});

  File? pickResult;
  bool backupCalled = false;
  bool restoreCalled = false;
  File? restoredFile;
  bool deleteAllCalled = false;

  @override
  Future<void> backup() async {
    backupCalled = true;
  }

  @override
  Future<File?> pickRestoreCandidate() async => pickResult;

  @override
  Future<void> restore(File source) async {
    restoreCalled = true;
    restoredFile = source;
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalled = true;
  }
}

/// FEAT03's screen test: `SettingsScreen` (was `CurrencyScreen`, D3) folds
/// currency, language, theme mode and theme color into one hub. The
/// currency section's behavior is unchanged from UC-14.
void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          ...extraOverrides,
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump. The
  // test body has to flush it itself before returning, or `flutter_test`'s
  // own teardown throws "A Timer is still pending" (`testing.md`, verified
  // UC13/UC11).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'UC-14: the currency section renders whatever currencyProvider emits (message 7)',
    (tester) async {
      await pumpScreen(tester);

      expect(find.text('IDR'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      final segmentedButton = tester.widget<SegmentedButton<Currency>>(
        find.byType(SegmentedButton<Currency>),
      );
      expect(segmentedButton.selected, {Currency.IDR});

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'NFR-4: both currency controls stay enabled, including the one already stored, and choosing the other proceeds',
    (tester) async {
      // Amounts already exist — NFR-4 names this scenario explicitly:
      // "changing the currency after amounts exist" must not be refused.
      await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Wallet',
              group: AccountGroup.HOLDING,
              openingAmount: 50000,
            ),
          );

      await pumpScreen(tester);

      final button = find.byType(SegmentedButton<Currency>);
      // F4: assert the finder matches before inspecting it, so this cannot
      // pass vacuously.
      expect(button, findsOneWidget);
      final segmentedButton = tester.widget<SegmentedButton<Currency>>(button);
      expect(segmentedButton.segments, hasLength(2));
      for (final segment in segmentedButton.segments) {
        expect(segment.enabled, isTrue);
      }
      expect(segmentedButton.onSelectionChanged, isNotNull);

      // Choosing USD (the other currency) proceeds — acknowledge the
      // notice, which has no cancel (D5).
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final stored = await database.select(database.settings).getSingle();
      expect(stored.currency, Currency.USD);

      // The stored amount is unchanged — a currency change re-labels only
      // (D6).
      final account = await database.select(database.accounts).getSingle();
      expect(account.openingAmount, 50000);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'D9: choosing the currency already stored shows no notice, and the stored value is unchanged',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('IDR'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final stored = await database.select(database.settings).getSingle();
      expect(stored.currency, Currency.IDR);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'D9: choosing the other currency shows the notice, and acknowledging it leaves the other currency stored',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('re-labelled'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final stored = await database.select(database.settings).getSingle();
      expect(stored.currency, Currency.USD);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT03 D2/D3: the language section renders both options enabled and writes only the locale column',
    (tester) async {
      await pumpScreen(tester);

      final languageButton = find.byType(SegmentedButton<AppLanguage>);
      expect(languageButton, findsOneWidget);
      final segmentedButton = tester.widget<SegmentedButton<AppLanguage>>(
        languageButton,
      );
      expect(segmentedButton.selected, {AppLanguage.id});
      for (final segment in segmentedButton.segments) {
        expect(segment.enabled, isTrue);
      }

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      final stored = await database.select(database.settings).getSingle();
      expect(stored.locale, AppLanguage.en);
      // Only the locale column changed — currency, theme mode and seed
      // color are untouched (D2's independent-writes rule).
      expect(stored.currency, Currency.IDR);
      expect(stored.themeMode, AppThemeMode.system);
      expect(stored.seedColor, isNull);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT03 D2/D3: the theme mode section renders all three options enabled and writes only the themeMode column',
    (tester) async {
      await pumpScreen(tester);

      final themeModeButton = find.byType(SegmentedButton<AppThemeMode>);
      expect(themeModeButton, findsOneWidget);
      final segmentedButton = tester.widget<SegmentedButton<AppThemeMode>>(
        themeModeButton,
      );
      expect(segmentedButton.selected, {AppThemeMode.system});
      expect(segmentedButton.segments, hasLength(3));
      for (final segment in segmentedButton.segments) {
        expect(segment.enabled, isTrue);
      }

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      final stored = await database.select(database.settings).getSingle();
      expect(stored.themeMode, AppThemeMode.dark);
      expect(stored.locale, AppLanguage.id);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT03 D1/D2: every theme color swatch stays tappable, including the one already selected, and writes only the seedColor column',
    (tester) async {
      await pumpScreen(tester);

      // Eight preset swatches (FEAT03 D1), each keyed `theme-swatch-$index`
      // — every one, including index 0 (the already-selected default)
      // stays tappable (NFR-4 zero refusals).
      for (var index = 0; index < 8; index++) {
        final swatch = find.byKey(ValueKey('theme-swatch-$index'));
        expect(swatch, findsOneWidget);
        final inkWell = tester.widget<InkWell>(
          find.descendant(of: swatch, matching: find.byType(InkWell)),
        );
        expect(inkWell.onTap, isNotNull);
      }

      // Tap the second swatch (index 1 — index 0 is the "reset to default"
      // swatch, `null`).
      await tester.tap(find.byKey(const ValueKey('theme-swatch-1')));
      await tester.pumpAndSettle();

      final stored = await database.select(database.settings).getSingle();
      expect(stored.seedColor, isNotNull);
      expect(stored.currency, Currency.IDR);

      await unmountAndFlushTimers(tester);
    },
  );

  group('FEAT20 D6: the Data section', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('feat20-screen-test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('all three buttons render', (tester) async {
      final notifier = _RecordingDatabaseMaintenanceNotifier();
      await pumpScreen(
        tester,
        extraOverrides: [
          databaseMaintenanceProvider.overrideWith(() => notifier),
        ],
      );

      expect(find.widgetWithText(OutlinedButton, 'Backup'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Restore'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Delete all data'),
        findsOneWidget,
      );

      await unmountAndFlushTimers(tester);
    });

    testWidgets(
      'an invalid (non-SQLite-header) picked file shows the acknowledge dialog and never calls restore',
      (tester) async {
        // Sync `dart:io` write (`testing.md`: real, OS-callback-driven
        // asynchronous I/O never resolves under `testWidgets`'s FakeAsync
        // zone; a synchronous call has no such dependency).
        final badFile = File('${tempDir.path}/not-a-backup.sqlite')
          ..writeAsStringSync('not a sqlite file at all');
        final notifier = _RecordingDatabaseMaintenanceNotifier(
          pickResult: badFile,
        );
        await pumpScreen(
          tester,
          extraOverrides: [
            databaseMaintenanceProvider.overrideWith(() => notifier),
          ],
        );

        await tester.tap(find.widgetWithText(OutlinedButton, 'Restore'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Not a backup file'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(notifier.restoreCalled, isFalse);

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'a valid picked file shows the Continue/Cancel dialog; Cancel calls neither restore nor changes anything',
      (tester) async {
        final goodFile = File('${tempDir.path}/backup.sqlite')
          ..writeAsBytesSync([
            ...'SQLite format 3\x00'.codeUnits,
            ...List.filled(80, 0),
          ]);
        final notifier = _RecordingDatabaseMaintenanceNotifier(
          pickResult: goodFile,
        );
        await pumpScreen(
          tester,
          extraOverrides: [
            databaseMaintenanceProvider.overrideWith(() => notifier),
          ],
        );

        await tester.tap(find.widgetWithText(OutlinedButton, 'Restore'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Restore this backup?'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(notifier.restoreCalled, isFalse);

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets('a valid picked file, Continue calls restore', (tester) async {
      final goodFile = File('${tempDir.path}/backup.sqlite')
        ..writeAsBytesSync([
          ...'SQLite format 3\x00'.codeUnits,
          ...List.filled(80, 0),
        ]);
      final notifier = _RecordingDatabaseMaintenanceNotifier(
        pickResult: goodFile,
      );
      await pumpScreen(
        tester,
        extraOverrides: [
          databaseMaintenanceProvider.overrideWith(() => notifier),
        ],
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Restore'));
      await tester.pumpAndSettle();

      // The confirm dialog's affirmative button repeats the action name.
      await tester.tap(find.widgetWithText(TextButton, 'Restore'));
      await tester.pumpAndSettle();

      expect(notifier.restoreCalled, isTrue);
      expect(notifier.restoredFile?.path, goodFile.path);
      expect(find.text('Data restored'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    });

    testWidgets(
      'Delete shows its own Continue/Cancel dialog; Cancel calls nothing, Continue calls deleteAll',
      (tester) async {
        final notifier = _RecordingDatabaseMaintenanceNotifier();
        await pumpScreen(
          tester,
          extraOverrides: [
            databaseMaintenanceProvider.overrideWith(() => notifier),
          ],
        );

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Delete all data'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete all data?'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(notifier.deleteAllCalled, isFalse);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Delete all data'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Delete all data'));
        await tester.pumpAndSettle();

        expect(notifier.deleteAllCalled, isTrue);
        expect(find.text('All data deleted'), findsOneWidget);

        await unmountAndFlushTimers(tester);
      },
    );
  });
}
