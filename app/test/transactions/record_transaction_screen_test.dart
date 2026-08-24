import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
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
          home: RecordTransactionScreen(),
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
}
