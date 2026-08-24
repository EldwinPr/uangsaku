import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_screen.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';

/// `AccountsScreen`'s own screen test (FEAT04 D1): the per-account list
/// assertions that used to live in `balance_sheet_screen_test.dart` before
/// the split — same widgets, same behavior, ported verbatim onto the new
/// screen rather than dropped.
void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<int> insertAccount(
    String name,
    AccountGroup group,
    int openingAmount,
  ) => database
      .into(database.accounts)
      .insert(
        AccountsCompanion.insert(
          name: name,
          group: group,
          openingAmount: openingAmount,
        ),
      );

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
          home: AccountsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump; the
  // test body flushes it before returning (`testing.md`, verified UC13).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('FR-2: the account list renders one row per place money lives', (
    tester,
  ) async {
    // Seeded with plain inserts, never by consuming the watch streams
    // first — that would starve the widget's own subscriptions
    // (`testing.md`, verified UC13).
    await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    await insertAccount('Budi', AccountGroup.RECEIVABLE, 50000);

    await pumpScreen(tester);

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('HOLDING'), findsOneWidget);
    expect(find.text('RECEIVABLE'), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'NFR-2 / D4: an empty database renders an empty-list placeholder',
    (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(const ValueKey('no-accounts')), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );
}
