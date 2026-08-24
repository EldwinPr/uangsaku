import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/balance_sheet_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-01's screen test (plan, Definition of done — *Widget, FR-1*): the
/// primary screen renders the four figures distinctly. Sequence-diagram
/// messages 1/7/13 exercised through real provider watches over a real
/// in-memory database.
///
/// **FEAT04 D1**: the per-account list assertions this file used to carry
/// moved to `test/accounts/accounts_screen_test.dart` alongside the
/// `AccountsScreen` split — `BalanceSheetScreen` no longer renders that
/// list, so this file only ever asserts the four figures now.
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
          home: BalanceSheetScreen(),
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

  String figureText(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('FR-1: the primary screen renders the four figures distinctly', (
    tester,
  ) async {
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

    // FEAT04 D1: the account list moved to AccountsScreen — none of its
    // rows render here anymore.
    expect(find.text('Wallet'), findsNothing);
    expect(find.text('Budi'), findsNothing);

    await unmountAndFlushTimers(tester);
  });

  testWidgets('NFR-2 / D4: an empty database renders four zero figures', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(figureText(tester, 'figure-spendable'), '0');
    expect(figureText(tester, 'figure-owed-to-me'), '0');
    expect(figureText(tester, 'figure-owed-by-me'), '0');
    expect(figureText(tester, 'figure-net'), '0');

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'FEAT07 D3/D6: the balance-trend line chart renders given seeded data',
    (tester) async {
      await insertAccount('Wallet', AccountGroup.HOLDING, 100000);

      await pumpScreen(tester);

      expect(find.byType(LineChart), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT07 D4/D7: the income-vs-expense chart degrades to a message, not a blank chart, on an empty database',
    (tester) async {
      await pumpScreen(tester);

      expect(find.byType(BarChart), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT07 D5/D6: the category-spending donut renders given a seeded expense',
    (tester) async {
      final wallet = await insertAccount('Wallet', AccountGroup.HOLDING, 0);
      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: TransactionKind.expense,
              amount: 5000,
              occurredOn: DateTime.now(),
              fromAccountId: Value(wallet),
            ),
          );

      await pumpScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT07 D5/D7: the category-spending donut degrades to a message, not a blank chart, with no spending this month',
    (tester) async {
      await pumpScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );
}
