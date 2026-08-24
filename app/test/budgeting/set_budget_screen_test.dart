import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/budgeting/budget_dao.dart';
import 'package:uangsaku/src/budgeting/set_budget_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';

/// The first day of the calendar month before [today]'s — the same
/// arithmetic `BudgetDao` uses internally (D5), duplicated here because the
/// widget under test uses the real wall clock (no `clockProvider` exists to
/// override it, D5) and the scenario still needs a previous-month row to
/// seed FR-15's pre-fill.
DateTime _previousMonthStart(DateTime today) {
  final totalMonths = today.year * 12 + (today.month - 1) - 1;
  return DateTime(totalMonths ~/ 12, totalMonths % 12 + 1, 1);
}

DateTime _monthEnd(DateTime monthStart) {
  return DateTime(monthStart.year, monthStart.month + 1, 0);
}

void main() {
  late AppDatabase database;
  late BudgetDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = BudgetDao(database);
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
          home: SetBudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump. The
  // test body has to flush it itself before returning, or `flutter_test`'s
  // own teardown throws "A Timer is still pending" (`testing.md`, verified
  // UC13).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'UC-11: the screen renders one row per budget group, pre-filled from budgetProvider (message 8)',
    (tester) async {
      await dao.insertGroup(name: 'Groceries');
      final group = await database.select(database.budgetGroups).getSingle();
      // A plain select, not `watchGroups().first` — consuming the watch
      // stream before the widget subscribes to the identical query starves
      // the widget's own subscription (verified UC13, `testing.md`).

      // The previous month's row is what FR-15's pre-fill reads.
      final previousStart = _previousMonthStart(DateTime.now());
      await database
          .into(database.budgetPeriods)
          .insert(
            BudgetPeriodsCompanion.insert(
              budgetGroupId: group.budgetGroupId,
              startsOn: previousStart,
              endsOn: _monthEnd(previousStart),
              amount: 250000,
            ),
          );

      await pumpScreen(tester);

      expect(find.text('Groceries'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, '250000');

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'NFR-4: save, delete-period, add-group, rename-group and delete-group stay enabled',
    (tester) async {
      await dao.insertGroup(name: 'Groceries');
      final group = await database.select(database.budgetGroups).getSingle();
      await dao.upsert(groupId: group.budgetGroupId, amount: 100000);

      await pumpScreen(tester);

      // F4 (`pm/findings.md`): assert the finder matches the expected count
      // *before* looping over it, so this test cannot pass by finding
      // nothing.
      final saveButtons = find.widgetWithIcon(IconButton, Icons.save);
      final deletePeriodButtons = find.widgetWithIcon(
        IconButton,
        Icons.delete_outline,
      );
      final editButtons = find.widgetWithIcon(IconButton, Icons.edit);
      final deleteGroupButtons = find.widgetWithIcon(IconButton, Icons.delete);
      final addGroupButton = find.byType(FloatingActionButton);

      expect(saveButtons, findsOneWidget);
      expect(deletePeriodButtons, findsOneWidget);
      expect(editButtons, findsOneWidget);
      expect(deleteGroupButtons, findsOneWidget);
      expect(addGroupButton, findsOneWidget);

      for (final finder in [
        saveButtons,
        deletePeriodButtons,
        editButtons,
        deleteGroupButtons,
      ]) {
        for (final element in finder.evaluate()) {
          final button = element.widget as IconButton;
          expect(button.onPressed, isNotNull);
        }
      }
      final fab = tester.widget<FloatingActionButton>(addGroupButton);
      expect(fab.onPressed, isNotNull);

      // Save proceeds with no lock, no refusal (FR-16 rewritten).
      await tester.enterText(find.byType(TextField).first, '999999');
      await tester.tap(saveButtons);
      await tester.pumpAndSettle();
      final saved = await database.select(database.budgetPeriods).getSingle();
      expect(saved.amount, 999999);

      // Delete the period — NFR-4: no confirmation, no refusal.
      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(await database.select(database.budgetPeriods).get(), isEmpty);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'D9: a group with no current-month period offers no delete-period control',
    (tester) async {
      await dao.insertGroup(name: 'Groceries');

      await pumpScreen(tester);

      expect(
        find.widgetWithIcon(IconButton, Icons.delete_outline),
        findsNothing,
      );

      await unmountAndFlushTimers(tester);
    },
  );
}
