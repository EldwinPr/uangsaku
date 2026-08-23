import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_form_screen.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/debt_detail_screen.dart';
import 'package:uangsaku/src/app.dart';
import 'package:uangsaku/src/budgeting/set_budget_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/currency_screen.dart';
import 'package:uangsaku/src/transactions/category_manager_screen.dart';

/// FEAT02's test (plan, Definition of done): every primary destination
/// renders, and every contextual entry point plan D1 lists is reachable
/// from the shell it wires them into.
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

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const App(),
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
    'each of the four bottom destinations renders its screen when selected',
    (tester) async {
      await pumpShell(tester);

      // Index 0 (Balance Sheet) is the initial destination.
      expect(find.text('uangsaku'), findsOneWidget);

      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();
      expect(find.text('Record money movement').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.text('All transactions').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      expect(find.text('Budget this month').hitTestable(), findsOneWidget);

      // Switching back to Balance Sheet keeps the earlier tabs' state alive
      // underneath (`IndexedStack`, never rebuilt from scratch) — every
      // screen stays mounted throughout, so this only re-shows it rather
      // than re-triggering its loading state.
      await tester.tap(find.text('Balance Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('uangsaku').hitTestable(), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'the Balance Sheet FAB reaches AccountFormScreen in create mode',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final screen = tester.widget<AccountFormScreen>(
        find.byType(AccountFormScreen),
      );
      expect(screen.mode, AccountFormMode.create);
      expect(screen.accountId, isNull);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'tapping an account row reaches AccountFormScreen in edit mode with the right accountId',
    (tester) async {
      final accountId = await insertAccount(
        'Wallet',
        AccountGroup.HOLDING,
        100000,
      );

      await pumpShell(tester);

      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      final screen = tester.widget<AccountFormScreen>(
        find.byType(AccountFormScreen),
      );
      expect(screen.mode, AccountFormMode.edit);
      expect(screen.accountId, accountId);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('tapping a debt row\'s icon reaches DebtDetailScreen', (
    tester,
  ) async {
    final accountId = await insertAccount(
      'Budi',
      AccountGroup.RECEIVABLE,
      50000,
    );

    await pumpShell(tester);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    final screen = tester.widget<DebtDetailScreen>(
      find.byType(DebtDetailScreen),
    );
    expect(screen.accountId, accountId);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'the two Balance Sheet app-bar actions reach CategoryManagerScreen and CurrencyScreen',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byTooltip('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryManagerScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Currency'));
      await tester.pumpAndSettle();
      expect(find.byType(CurrencyScreen), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets("the Budget tab's app-bar action reaches SetBudgetScreen", (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Set budget'));
    await tester.pumpAndSettle();
    expect(find.byType(SetBudgetScreen), findsOneWidget);

    await unmountAndFlushTimers(tester);
  });
}
