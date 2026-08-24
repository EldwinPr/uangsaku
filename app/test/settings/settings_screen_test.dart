import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/settings_screen.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
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
}
