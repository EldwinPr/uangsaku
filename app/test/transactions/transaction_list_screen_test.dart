import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/category_dao.dart';
import 'package:uangsaku/src/transactions/transaction_dao.dart';
import 'package:uangsaku/src/transactions/transaction_list_screen.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-09's widget tests (`pm/issues/uc09-review-and-correct/plan.md`, step
/// 6): the screen renders what `transactionListProvider` emits, and — the
/// two requirements that erode quietly (testing.md) — FR-18's edit/delete
/// actually perform through this screen's controls, and NFR-4's zero-
/// refusals holds on both of them.
void main() {
  late AppDatabase database;
  late TransactionDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = TransactionDao(database);
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
          home: TransactionListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump; it
  // has to be flushed from inside the test body itself (testing.md, verified
  // UC13).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> seedOneExpense() async {
    await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Cash',
            group: AccountGroup.HOLDING,
            openingAmount: 100000,
          ),
        );
    final cash = await database.select(database.accounts).getSingle();
    await dao.insert(
      kind: TransactionKind.expense,
      amount: 15000,
      occurredOn: DateTime(2026, 8, 1),
      fromAccountId: cash.accountId,
      note: 'lunch',
    );
  }

  testWidgets(
    'UC-09: the screen renders what transactionListProvider emits — kind, amount, date, side names and note',
    (tester) async {
      await seedOneExpense();

      await pumpScreen(tester);

      expect(find.text('Expense · 15000'), findsOneWidget);
      expect(find.textContaining('Cash'), findsOneWidget);
      expect(find.textContaining('lunch'), findsOneWidget);
      expect(find.textContaining('2026-08-01'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT08 D1: an income row renders green, an expense row in colorScheme.error, a transfer row in the default color',
    (tester) async {
      await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Cash',
              group: AccountGroup.HOLDING,
              openingAmount: 100000,
            ),
          );
      await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Savings',
              group: AccountGroup.HOLDING,
              openingAmount: 0,
            ),
          );
      final cash = (await database.select(database.accounts).get()).first;
      final savings = (await database.select(database.accounts).get()).last;

      await dao.insert(
        kind: TransactionKind.income,
        amount: 5000,
        occurredOn: DateTime(2026, 8, 1),
        toAccountId: cash.accountId,
      );
      await dao.insert(
        kind: TransactionKind.expense,
        amount: 3000,
        occurredOn: DateTime(2026, 8, 2),
        fromAccountId: cash.accountId,
      );
      await dao.insert(
        kind: TransactionKind.transfer,
        amount: 1000,
        occurredOn: DateTime(2026, 8, 3),
        fromAccountId: cash.accountId,
        toAccountId: savings.accountId,
      );

      await pumpScreen(tester);

      final context = tester.element(find.byType(TransactionListScreen));
      final colorScheme = Theme.of(context).colorScheme;
      final defaultColor =
          DefaultTextStyle.of(context).style.color ??
          Theme.of(context).textTheme.bodyLarge?.color;

      final incomeText = tester.widget<Text>(find.text('Income · 5000'));
      expect(incomeText.style?.color, Colors.green.shade700);

      final expenseText = tester.widget<Text>(find.text('Expense · 3000'));
      expect(expenseText.style?.color, colorScheme.error);

      final transferText = tester.widget<Text>(find.text('Transfer · 1000'));
      expect(transferText.style?.color, isNot(Colors.green.shade700));
      expect(transferText.style?.color, isNot(colorScheme.error));
      // Unstyled: no color override, same as `defaultColor` would resolve to.
      expect(transferText.style?.color, isNull);
      expect(defaultColor, isNotNull);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('UC-09 D3: an empty ledger renders an empty list, not an error', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('No transactions yet'), findsOneWidget);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'NFR-4: the delete control is enabled and performs the deletion immediately — no confirmation dialog, nothing refused',
    (tester) async {
      await seedOneExpense();

      await pumpScreen(tester);

      // The control is enabled — a disabled delete would be the likeliest
      // accidental NFR-4 violation in the app.
      final deleteButton = find.widgetWithIcon(IconButton, Icons.delete);
      expect(deleteButton, findsOneWidget);
      final button = tester.widget<IconButton>(deleteButton);
      expect(button.onPressed, isNotNull);
      // And there is no gate sitting in front of it.
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // The row is gone from the stream re-emission...
      expect(find.textContaining('Expense'), findsNothing);
      expect(find.text('No transactions yet'), findsOneWidget);
      // ...and gone from storage. No confirmation ever appeared.
      expect(await database.select(database.transactions).get(), isEmpty);
      expect(find.byType(AlertDialog), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FR-18: amending round-trips into the next emission — the tile updates without any reload',
    (tester) async {
      await seedOneExpense();

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Amend transaction'));
      await tester.pumpAndSettle();

      // D4: kind is not offered as a choice on the amend surface.
      expect(find.byKey(const Key('kind-dropdown')), findsNothing);

      const amountField = Key('edit-amount');
      await tester.enterText(find.byKey(amountField), '25000');
      await tester.enterText(find.byKey(const Key('edit-note')), 'dinner');

      // The save control is enabled (D7) and performs the write.
      final saveButton = find.byKey(const Key('edit-save'));
      expect((tester.widget<FilledButton>(saveButton)).onPressed, isNotNull);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // The sheet closed and the amended row arrived as stream re-emission.
      expect(find.text('Amend Expense'), findsNothing);
      expect(find.text('Expense · 25000'), findsOneWidget);
      expect(find.textContaining('dinner'), findsOneWidget);

      final row = await database.select(database.transactions).getSingle();
      expect(row.amount, 25000);
      expect(row.note, 'dinner');
      expect(row.kind, TransactionKind.expense);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'NFR-4 / D7: edit proceeds under empty pickers — zero amount, blank tags, nothing refused',
    (tester) async {
      // Nothing seeded but the transaction itself: every picker pool is
      // empty, so the sheet shows hints and stays enabled throughout.
      await dao.insert(
        kind: TransactionKind.expense,
        amount: 15000,
        occurredOn: DateTime(2026, 8, 1),
      );

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Amend transaction'));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('edit-save'));
      expect((tester.widget<FilledButton>(saveButton)).onPressed, isNotNull);
      expect(find.text('No accounts yet'), findsWidgets);

      // F7 precedent: an unparseable amount proceeds as 0 rather than
      // refusing the save.
      await tester.enterText(find.byKey(const Key('edit-amount')), 'x');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final row = await database.select(database.transactions).getSingle();
      expect(row.amount, 0);
      expect(row.fromAccountId, isNull);
      expect(row.categoryId, isNull);
      expect(row.note, isNull);

      // The zero-amount row round-trips onto the tile.
      expect(find.text('Expense · 0'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT05 D2: typing an existing category name and selecting it in the edit sheet sets the same id the dropdown would have',
    (tester) async {
      final categoryDao = CategoryDao(database);
      await categoryDao.insert(name: 'Food');
      await seedOneExpense();

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Amend transaction'));
      await tester.pumpAndSettle();

      final categoryField = find.byKey(const Key('edit-category-field'));
      await tester.enterText(
        find.descendant(of: categoryField, matching: find.byType(TextField)),
        'Food',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Food'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-save')));
      await tester.pumpAndSettle();

      final category = await database.select(database.categories).getSingle();
      final row = await database.select(database.transactions).getSingle();
      expect(row.categoryId, category.categoryId);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT05 D3: the edit sheet\'s subcategory suggestions are NOT narrowed by category — unlike RecordTransactionScreen, this is browsing (UC-09 D6)',
    (tester) async {
      final categoryDao = CategoryDao(database);
      await categoryDao.insert(name: 'Food');
      final food = await database.select(database.categories).getSingle();
      await categoryDao.insert(categoryId: food.categoryId, name: 'Groceries');
      await categoryDao.insert(name: 'Transport');
      final transport = (await database.select(database.categories).get())
          .firstWhere((c) => c.name == 'Transport');
      await categoryDao.insert(categoryId: transport.categoryId, name: 'Fuel');
      await seedOneExpense();

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Amend transaction'));
      await tester.pumpAndSettle();

      // No category is selected on this row (the seeded expense has none),
      // yet both subcategories — from different categories — are
      // suggestible: the pool stays the full flattened list for browsing.
      final subcategoryField = find.byKey(const Key('edit-subcategory-field'));
      await tester.enterText(
        find.descendant(of: subcategoryField, matching: find.byType(TextField)),
        '',
      );
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT05 D3: the create-new affordance is absent for the subcategory field when no category is selected',
    (tester) async {
      final categoryDao = CategoryDao(database);
      await categoryDao.insert(name: 'Food');
      await seedOneExpense();

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Amend transaction'));
      await tester.pumpAndSettle();

      // The row has no category set, so the subcategory field's create-new
      // option is unavailable — absent, not a refusal (D3, NFR-4).
      final subcategoryField = find.byKey(const Key('edit-subcategory-field'));
      await tester.enterText(
        find.descendant(of: subcategoryField, matching: find.byType(TextField)),
        'Snacks',
      );
      await tester.pumpAndSettle();
      expect(find.text("Create 'Snacks'"), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );
}
