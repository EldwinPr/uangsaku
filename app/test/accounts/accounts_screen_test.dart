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
    '2026-08-24: an empty database renders both sections with their own '
    'empty-list placeholder',
    (tester) async {
      await pumpScreen(tester);

      // One per section (Accounts, Person) — the split shows zero rather
      // than hiding an empty section.
      expect(find.text('No accounts yet.'), findsNWidgets(2));

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT11 D5: a PERSON row shows the debt-detail icon, same as RECEIVABLE/PAYABLE rows',
    (tester) async {
      await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
      await insertAccount('Sam', AccountGroup.PERSON, 20000);

      await pumpScreen(tester);

      // One icon per debt-shaped row — HOLDING gets none.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    '2026-08-24: the list splits into an Accounts section and a Person '
    'section, each with its own balance sum next to the header',
    (tester) async {
      await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
      await insertAccount('Card', AccountGroup.PAYABLE, -20000);
      await insertAccount('Sam', AccountGroup.PERSON, 30000);
      await insertAccount('Ivy', AccountGroup.PERSON, -5000);

      await pumpScreen(tester);

      // Both section headers render, each showing its own accounts only.
      expect(find.byKey(const ValueKey('accounts-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('person-section')), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Ivy'), findsOneWidget);

      // Accounts section: 100000 + -20000 = 80000. Person section:
      // 30000 + -5000 = 25000. Plain sums of what accountBalancesProvider
      // already derived — not a fifth FR-1 figure.
      expect(find.text('80,000'), findsOneWidget);
      expect(find.text('25,000'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('2026-08-24: a PERSON account never contributes to the Accounts '
      "section's sum, and a HOLDING/PAYABLE account never contributes to "
      "Person's", (tester) async {
    await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    await insertAccount('Sam', AccountGroup.PERSON, 30000);

    await pumpScreen(tester);

    expect(find.text('100,000'), findsOneWidget);
    expect(find.text('30,000'), findsOneWidget);

    await unmountAndFlushTimers(tester);
  });
}
