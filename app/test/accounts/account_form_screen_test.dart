import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_form_screen.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: AccountFormScreen()),
      ),
    );
    await tester.pump();
  }

  // `byTooltip` also matches the tooltip's own `RawTooltip` widget, so the
  // FAB is found by type — there is exactly one on this screen.
  Finder saveButton() => find.byType(FloatingActionButton);

  testWidgets(
    'NFR-4: the save control is enabled with every field empty and pressing it proceeds rather than refusing',
    (tester) async {
      await pumpScreen(tester);

      final button = tester.widget<FloatingActionButton>(saveButton());
      expect(button.onPressed, isNotNull);

      // Nothing filled in — saving proceeds anyway (D7): empty name, the
      // default group, an amount of 0. A form that refused to submit until
      // a field was filled would be a requirements violation, not a UI
      // choice.
      await tester.tap(saveButton());
      await tester.pump();

      final row = await database.select(database.accounts).getSingle();
      expect(row.name, '');
      expect(row.group, AccountGroup.HOLDING);
      expect(row.openingAmount, 0);
    },
  );

  testWidgets('NFR-4: all three AccountGroup values are selectable', (
    tester,
  ) async {
    await pumpScreen(tester);

    final selector = find.byType(SegmentedButton<AccountGroup>);
    expect(selector, findsOneWidget);
    final segmented = tester.widget<SegmentedButton<AccountGroup>>(selector);
    // Every value on the diagram is offered and none is disabled.
    expect(segmented.segments.map((segment) => segment.value), [
      AccountGroup.HOLDING,
      AccountGroup.RECEIVABLE,
      AccountGroup.PAYABLE,
    ]);
    for (final segment in segmented.segments) {
      expect(segment.enabled, isTrue);
    }
    expect(segmented.onSelectionChanged, isNotNull);
  });

  testWidgets(
    'the screen renders, and addAccount reaches the database with the values entered',
    (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Budi');
      await tester.tap(find.text('RECEIVABLE'));
      await tester.pump();
      // A negative opening amount is entered as typed and stored as typed
      // (FR-4, D6) — no group-based negation anywhere.
      await tester.enterText(find.byType(TextField).at(1), '-12000');
      await tester.tap(saveButton());
      await tester.pump();

      final row = await database.select(database.accounts).getSingle();
      expect(row.name, 'Budi');
      expect(row.group, AccountGroup.RECEIVABLE);
      expect(row.openingAmount, -12000);

      // UC-02 writes no transaction row ever (D4).
      expect(await database.select(database.transactions).get(), isEmpty);
    },
  );

  Future<void> pumpAdjustScreen(WidgetTester tester, int accountId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: AccountFormScreen(accountId: accountId)),
      ),
    );
    // pumpAndSettle, not a single pump: the adjust flow watches
    // accountBalancesProvider (message 7), a real drift stream.
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump; the
  // test body flushes it before returning (`testing.md`, verified UC13,
  // UC01's `balance_sheet_screen_test.dart`).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'NFR-4 / UC-03: on the adjust flow, the save control is enabled with the target field empty and pressing it proceeds',
    (tester) async {
      final accountId = await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Wallet',
              group: AccountGroup.HOLDING,
              openingAmount: 100000,
            ),
          );

      await pumpAdjustScreen(tester, accountId);

      final button = tester.widget<FloatingActionButton>(saveButton());
      expect(button.onPressed, isNotNull);

      // Nothing entered — saving proceeds anyway (D7): an empty target
      // parses as 0, and the DAO still writes its diff row unconditionally
      // (D4). Refusing until the field is filled would be a requirements
      // violation, not a UI choice.
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      final rows = await database.select(database.transactions).get();
      expect(rows, hasLength(1));

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'UC-03: the adjust flow reaches the database — adjustAccount writes one Transactions row targeting the designated account',
    (tester) async {
      final accountId = await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              name: 'Wallet',
              group: AccountGroup.HOLDING,
              openingAmount: 100000,
            ),
          );

      await pumpAdjustScreen(tester, accountId);

      await tester.enterText(find.byType(TextField), '150000');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      final row = await database.select(database.transactions).getSingle();
      expect(row.toAccountId, accountId);
      expect(row.fromAccountId, isNull);
      expect(row.amount, 50000);

      await unmountAndFlushTimers(tester);
    },
  );
}
