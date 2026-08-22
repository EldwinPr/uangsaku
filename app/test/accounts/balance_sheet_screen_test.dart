import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/balance_sheet_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';

/// UC-01's screen test (plan, Definition of done — *Widget, FR-1*): the
/// primary screen renders the four figures distinctly plus the per-account
/// list. Sequence-diagram messages 1/7/13 exercised through real provider
/// watches over a real in-memory database.
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
        child: const MaterialApp(home: BalanceSheetScreen()),
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

  String figureText(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets(
    'FR-1: the primary screen renders the four figures distinctly plus the per-account list',
    (tester) async {
      // Seeded with plain inserts, never by consuming the watch streams
      // first — that would starve the widget's own subscriptions
      // (`testing.md`, verified UC13).
      await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
      await insertAccount('Budi', AccountGroup.RECEIVABLE, 50000);

      await pumpScreen(tester);

      // Four distinct figures — spendable is not merged with owed-to-me.
      expect(figureText(tester, 'figure-spendable'), '100000');
      expect(figureText(tester, 'figure-owed-to-me'), '50000');
      expect(figureText(tester, 'figure-owed-by-me'), '0');
      expect(figureText(tester, 'figure-net'), '150000');

      // The account list beneath, one row per place money lives (FR-2).
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Budi'), findsOneWidget);
      expect(find.text('HOLDING'), findsOneWidget);
      expect(find.text('RECEIVABLE'), findsOneWidget);
      // '50000' appears twice on purpose: the owedToMe card's trailing
      // figure *and* Budi's list-row balance — both must be present, and
      // neither is the other's source (NFR-2).
      expect(find.text('50000'), findsNWidgets(2));

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'NFR-2 / D4: an empty database renders four zero figures and an empty-list placeholder',
    (tester) async {
      await pumpScreen(tester);

      expect(figureText(tester, 'figure-spendable'), '0');
      expect(figureText(tester, 'figure-owed-to-me'), '0');
      expect(figureText(tester, 'figure-owed-by-me'), '0');
      expect(figureText(tester, 'figure-net'), '0');
      expect(find.byKey(const ValueKey('no-accounts')), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );
}
