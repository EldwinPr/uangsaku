import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/budgeting/budget_overview_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-12's screen test (D8, NFR-4): amount/spent/remaining render per group,
/// the "Others" line always appears, an overspent group renders a negative
/// remaining with nothing blocked or disabled, and no control of any kind
/// exists to disable — the fit criterion for this screen's NFR-4 is that
/// there is nothing to refuse.
void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<int> insertGroup(String name) async {
    await database
        .into(database.budgetGroups)
        .insert(BudgetGroupsCompanion.insert(name: name));
    final row = await (database.select(
      database.budgetGroups,
    )..where((row) => row.name.equals(name))).getSingle();
    return row.budgetGroupId;
  }

  Future<void> insertPeriod(int groupId, int amount) => database
      .into(database.budgetPeriods)
      .insert(
        BudgetPeriodsCompanion.insert(
          budgetGroupId: groupId,
          startsOn: DateTime(DateTime.now().year, DateTime.now().month, 1),
          endsOn: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
          amount: amount,
        ),
      );

  Future<void> insertSpend(int amount, {int? groupId}) => database
      .into(database.transactions)
      .insert(
        TransactionsCompanion.insert(
          kind: TransactionKind.expense,
          amount: amount,
          occurredOn: DateTime.now(),
          fromAccountId: const Value(1),
          budgetGroupId: Value(groupId),
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
          home: BudgetOverviewScreen(),
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

  testWidgets(
    'FR-13/FR-17: renders amount/spent/remaining per group and always includes Others',
    (tester) async {
      final groupId = await insertGroup('Groceries');
      await insertPeriod(groupId, 1000000);
      await insertSpend(300000, groupId: groupId);
      await insertSpend(50000); // untagged — Others

      await pumpScreen(tester);

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);
      expect(
        (tester.widget(
          find.byKey(ValueKey('remaining-$groupId')),
        ) as Text).data,
        '700000',
      );
      expect(
        (tester.widget(
          find.byKey(const ValueKey('remaining-others')),
        ) as Text).data,
        '-50000',
      );

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FR-12/NFR-4: an overspent group renders a negative remaining, and the screen has no control to disable',
    (tester) async {
      final groupId = await insertGroup('Groceries');
      await insertPeriod(groupId, 100000);
      await insertSpend(150000, groupId: groupId);

      await pumpScreen(tester);

      expect(
        (tester.widget(
          find.byKey(ValueKey('remaining-$groupId')),
        ) as Text).data,
        '-50000',
      );
      // No confirmation, no warning banner, no disabled control anywhere —
      // this screen draws nothing that could be found disabled. The
      // `IconButton`s that do exist are the FEAT02 app-bar action into
      // `SetBudgetScreen` plus FEAT10 D3's Settings/Help actions — every
      // one always enabled, never a refusal.
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      for (final iconButton in tester.widgetList<IconButton>(
        find.byType(IconButton),
      )) {
        expect(iconButton.onPressed, isNotNull);
      }

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FR-14: spending outside the month contributes nothing to this month\'s figure',
    (tester) async {
      final groupId = await insertGroup('Groceries');
      await insertPeriod(groupId, 100000);
      final now = DateTime.now();
      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: TransactionKind.expense,
              amount: 999999,
              occurredOn: DateTime(now.year, now.month - 2, 1),
              fromAccountId: const Value(1),
              budgetGroupId: Value(groupId),
            ),
          );

      await pumpScreen(tester);

      expect(
        (tester.widget(
          find.byKey(ValueKey('remaining-$groupId')),
        ) as Text).data,
        '100000',
      );

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('no budget groups yet — only Others renders, nothing crashes', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Others'), findsOneWidget);
    expect(
      (tester.widget(
        find.byKey(const ValueKey('remaining-others')),
      ) as Text).data,
      '0',
    );

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'FEAT15 D2: the allocation donut renders above the group rows when a group has a nonzero amount',
    (tester) async {
      final groupId = await insertGroup('Groceries');
      await insertPeriod(groupId, 1000000);

      await pumpScreen(tester);

      expect(find.byType(PieChart), findsOneWidget);
      final chartPosition = tester.getTopLeft(find.byType(PieChart)).dy;
      final firstTilePosition = tester
          .getTopLeft(find.byType(ListTile).first)
          .dy;
      expect(chartPosition, lessThan(firstTilePosition));

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT15 D2: the allocation donut degrades to a message, not a chart, with an empty database (only the always-0 Others row)',
    (tester) async {
      await pumpScreen(tester);

      expect(find.byType(PieChart), findsNothing);
      expect(find.text('No data yet.'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT15 D2: the allocation donut degrades to a message when every group amount is 0',
    (tester) async {
      await insertGroup('Groceries');

      await pumpScreen(tester);

      expect(find.byType(PieChart), findsNothing);
      expect(find.text('No data yet.'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );
}
