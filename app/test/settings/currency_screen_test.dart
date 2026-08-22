import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/currency_screen.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

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
        child: const MaterialApp(home: CurrencyScreen()),
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
    'UC-14: the screen renders whatever currencyProvider emits (message 7)',
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
}
