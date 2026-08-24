import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/category_dao.dart';
import 'package:uangsaku/src/transactions/record_transaction_screen.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> seedAccounts() async {
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
            name: 'Budi',
            group: AccountGroup.RECEIVABLE,
            openingAmount: 0,
          ),
        );
  }

  Future<void> pumpScreen(WidgetTester tester, {VoidCallback? onSaved}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecordTransactionScreen(onSaved: onSaved ?? () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer` that
  // only fires on a later pump; the test body has to flush it itself before
  // returning (`testing.md`, verified UC13).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'D9 / NFR-4: save renders enabled, drives the write through notifier and DAO, and fires no dialog or refusal path',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNotNull);

      await tester.enterText(find.byType(TextField).first, '15000');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final row = await database.select(database.transactions).getSingle();
      expect(row.kind, TransactionKind.expense);
      expect(row.amount, 15000);
      expect(row.fromAccountId, isNotNull);
      expect(row.toAccountId, isNull);

      // No confirmation, no warning dialog, no refusal — the write simply
      // happened (NFR-4's fit criterion is zero).
      expect(find.byType(AlertDialog), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT06 D2: the FAB reads Icons.check, and after save the form clears and a confirmation SnackBar shows',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.save), findsNothing);

      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '15000');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Confirmation shows — this tab has nothing to pop.
      expect(find.byType(SnackBar), findsOneWidget);

      // The form cleared back to its initial blank state (plan D2).
      final controllerAfter = tester.widget<TextField>(amountField).controller;
      expect(controllerAfter!.text, '');

      final rows = await database.select(database.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.amount, 15000);

      await tester.pumpAndSettle();
      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'D9 / NFR-4: a zero amount and a same-source-and-destination transfer both proceed unrefused',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);

      // Zero amount, default expense flow — saved as 0 (F7 precedent), no
      // gate.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      var rows = await database.select(database.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.amount, 0);

      // Switch to Transfer. Both sides preselect the first account ('Cash'),
      // so this is a same-account transfer without touching either picker.
      await tester.tap(find.byKey(const Key('kind-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transfer').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      rows = await database.select(database.transactions).get();
      expect(rows, hasLength(2));
      final transfer = rows.last;
      expect(transfer.kind, TransactionKind.transfer);
      expect(transfer.fromAccountId, isNotNull);
      expect(transfer.toAccountId, transfer.fromAccountId);
      expect(find.byType(AlertDialog), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('FEAT08 D2: a successful save calls onSaved exactly once', (
    tester,
  ) async {
    await seedAccounts();
    var calls = 0;
    await pumpScreen(tester, onSaved: () => calls++);

    await tester.enterText(find.byType(TextField).first, '15000');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(calls, 1);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'FEAT05 D2: typing an existing category name and selecting it sets the same id the dropdown would have',
    (tester) async {
      await seedAccounts();
      final categoryDao = CategoryDao(database);
      await categoryDao.insert(name: 'Food');
      await pumpScreen(tester);

      final categoryField = find.byKey(const Key('category-field'));
      await tester.enterText(
        find.descendant(of: categoryField, matching: find.byType(TextField)),
        'Food',
      );
      await tester.pumpAndSettle();

      // The suggestion list shows the existing category, no create-new
      // entry (an exact case-insensitive match already exists).
      expect(find.text("Create 'Food'"), findsNothing);
      await tester.tap(find.widgetWithText(ListTile, 'Food'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '15000');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final row = await database.select(database.transactions).getSingle();
      final category = await database.select(database.categories).getSingle();
      expect(row.categoryId, category.categoryId);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT05 D2: typing a new category name and creating it writes via categoriesProvider and the field resolves to the new row',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);

      final categoryField = find.byKey(const Key('category-field'));
      await tester.enterText(
        find.descendant(of: categoryField, matching: find.byType(TextField)),
        'Transport',
      );
      await tester.pumpAndSettle();

      expect(find.text("Create 'Transport'"), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, "Create 'Transport'"));
      await tester.pumpAndSettle();

      final category = await database.select(database.categories).getSingle();
      expect(category.name, 'Transport');

      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final row = await database.select(database.transactions).getSingle();
      expect(row.categoryId, category.categoryId);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT05 D3: subcategory suggestions stay narrowed to the selected category',
    (tester) async {
      await seedAccounts();
      final categoryDao = CategoryDao(database);
      await categoryDao.insert(name: 'Food');
      final food = await database.select(database.categories).getSingle();
      await categoryDao.insert(categoryId: food.categoryId, name: 'Groceries');
      await categoryDao.insert(name: 'Transport');

      await pumpScreen(tester);

      // No category selected yet — the create-new affordance for the
      // subcategory field is absent (D3), not a refusal.
      final subcategoryField = find.byKey(const Key('subcategory-field'));
      await tester.enterText(
        find.descendant(of: subcategoryField, matching: find.byType(TextField)),
        'Anything',
      );
      await tester.pumpAndSettle();
      expect(find.text("Create 'Anything'"), findsNothing);
      // Select 'Food' — its 'Groceries' subcategory becomes suggestible.
      final categoryField = find.byKey(const Key('category-field'));
      await tester.enterText(
        find.descendant(of: categoryField, matching: find.byType(TextField)),
        'Food',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Food'));
      await tester.pumpAndSettle();

      // 'Groceries' (Food's child) is suggestible; 'Transport' has no
      // children, so nothing outside Food's pool is offered.
      await tester.enterText(
        find.descendant(of: subcategoryField, matching: find.byType(TextField)),
        'Gro',
      );
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );
}
