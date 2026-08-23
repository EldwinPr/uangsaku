import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
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
        child: const MaterialApp(home: TransactionListScreen()),
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
}
