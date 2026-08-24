import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/debt_detail_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-10's screen test (plan, Definition of done — *Widget / NFR-4*): the
/// screen renders paid and remaining, the settle control is **enabled**, no
/// dialog appears on tap, and tapping drives notifier → DAO → stream
/// emission (sequence-diagram messages 3–7) over a real in-memory database.
///
/// FEAT14 D2: the button now calls `AccountsNotifier.writeOffDebt`, not
/// `markSettled` — it zeroes the derived balance in addition to setting
/// `settled: true`.
void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<int> insertDebt() => database
      .into(database.accounts)
      .insert(
        AccountsCompanion.insert(
          name: 'Budi',
          group: AccountGroup.RECEIVABLE,
          openingAmount: 500000,
        ),
      );

  Future<void> insertRepayment(int debtId, int amount) => database
      .into(database.transactions)
      .insert(
        TransactionsCompanion.insert(
          kind: TransactionKind.repayment,
          amount: amount,
          occurredOn: DateTime(2026, 8, 23),
          // Repaying a receivable moves money FROM the person's account.
          fromAccountId: Value(debtId),
        ),
      );

  Future<void> pumpScreen(WidgetTester tester, int debtId) async {
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
          home: DebtDetailScreen(accountId: debtId),
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

  testWidgets(
    'NFR-4 / FR-11 / FEAT14 D1/D2: the screen renders paid and remaining, the write-off control is enabled with no dialog on tap, and tapping writes off the debt through notifier → DAO → emission',
    (tester) async {
      final debtId = await insertDebt();
      await insertRepayment(debtId, 200000);

      await pumpScreen(tester, debtId);

      // Messages 2: both figures rendered distinctly, raw minor units.
      expect(figureText(tester, 'figure-paid'), '200000');
      expect(figureText(tester, 'figure-remaining'), '300000');
      expect(find.byKey(const ValueKey('settled-badge')), findsNothing);

      // NFR-4 made checkable: the control exists, is enabled, and tapping
      // it opens no dialog that could end in "no".
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('settle-button')),
      );
      expect(button.enabled, isTrue);

      await tester.tap(find.byKey(const ValueKey('settle-button')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);

      // Message 7: the write returned nothing; the re-emitted stream is how
      // the screen learned the write-off landed — remaining is now zero, not
      // merely the settled flag.
      expect(figureText(tester, 'figure-remaining'), '0');
      expect(find.byKey(const ValueKey('settled-badge')), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Write it off'),
          matching: find.byKey(const ValueKey('settle-button')),
        ),
        findsOneWidget,
      );

      // FEAT14 D1: the write-off transaction is tagged with a literal
      // "Ikhlaskan" category — not `markSettled`'s bare flag flip.
      final categoryRow = await database
          .customSelect(
            'SELECT name FROM categories WHERE name = ?',
            variables: [Variable.withString('Ikhlaskan')],
          )
          .getSingle();
      expect(categoryRow.data['name'], 'Ikhlaskan');

      await unmountAndFlushTimers(tester);
    },
  );
}
