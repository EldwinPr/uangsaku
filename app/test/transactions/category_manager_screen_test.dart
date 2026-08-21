import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/category_dao.dart';
import 'package:uangsaku/src/transactions/category_manager_screen.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

void main() {
  late AppDatabase database;
  late CategoryDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = CategoryDao(database);
  });

  tearDown(() => database.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: CategoryManagerScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump.
  // `flutter_test` disposes the widget tree (and with it every provider,
  // including `categoryTreeProvider`'s stream) *after* the test body
  // returns, so the Timer has to be flushed from inside the test body
  // itself — an `addTearDown` callback runs too early to see it (verified
  // while building this issue: it still hit "A Timer is still pending").
  // Unmounting to a plain widget and pumping a real duration flushes it.
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('UC-13: the screen renders what categoryTreeProvider emits', (
    tester,
  ) async {
    await dao.insert(name: 'Food');
    // A plain select, not `watchTree().first` — consuming the watch stream
    // before the widget subscribes to the same query starves the widget's
    // subscription under `flutter_test`'s binding (verified while building
    // this issue; see `category_dao_test.dart`, where the same `.first`
    // pattern is fine because nothing else watches the query afterwards).
    final category = await database.select(database.categories).getSingle();
    await dao.insert(categoryId: category.categoryId, name: 'Groceries');

    await pumpScreen(tester);

    expect(find.text('Food'), findsOneWidget);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'NFR-4: add, rename and delete stay enabled for a category with subcategories and a referencing transaction, and delete proceeds',
    (tester) async {
      await dao.insert(name: 'Food');
      final category = await database.select(database.categories).getSingle();
      await dao.insert(categoryId: category.categoryId, name: 'Groceries');
      final subcategory = await database
          .select(database.subcategories)
          .getSingle();

      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: TransactionKind.expense,
              amount: 1000,
              occurredOn: DateTime(2026, 8, 21),
              categoryId: Value(category.categoryId),
              subcategoryId: Value(subcategory.subcategoryId),
            ),
          );

      await pumpScreen(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      final addButton = find.widgetWithIcon(IconButton, Icons.add).last;
      final editButtons = find.widgetWithIcon(IconButton, Icons.edit);
      final deleteButtons = find.widgetWithIcon(IconButton, Icons.delete);

      for (final finder in [addButton, editButtons, deleteButtons]) {
        for (final element in finder.evaluate()) {
          final button = element.widget as IconButton;
          expect(button.onPressed, isNotNull);
        }
      }

      // Delete the category — NFR-4: no confirmation, no refusal.
      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'D7: a subcategory row offers no control that would create a third level',
    (tester) async {
      await dao.insert(name: 'Food');
      final category = await database.select(database.categories).getSingle();
      await dao.insert(categoryId: category.categoryId, name: 'Groceries');

      await pumpScreen(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      final subcategoryTile = find.widgetWithText(ListTile, 'Groceries');
      expect(subcategoryTile, findsOneWidget);
      final addIconsUnderSubcategory = find.descendant(
        of: subcategoryTile,
        matching: find.byIcon(Icons.add),
      );
      expect(addIconsUnderSubcategory, findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );
}
