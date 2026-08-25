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

  testWidgets(
    'FEAT09 D4: the kind description swaps with the dropdown selection',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);

      expect(
        find.text('Money leaving one of your accounts, spent on something.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('kind-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transfer').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Money moving between two of your own accounts — not spending.',
        ),
        findsOneWidget,
      );

      await unmountAndFlushTimers(tester);
    },
  );

  Future<void> switchTo(WidgetTester tester, String kindLabel) async {
    await tester.tap(find.byKey(const Key('kind-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kindLabel).last);
    await tester.pumpAndSettle();
  }

  // FEAT13: the checkbox above _PersonAccountField is persistent (D1) and
  // gates creation entirely (D2/D3) — unchecked can never create, checked
  // always creates PERSON. Existing accounts stay selectable either way.
  // Exercised identically across Lend/Borrow/Repay (D4), replacing FEAT11
  // D7's per-flow RECEIVABLE/PAYABLE-default and no-checkbox-in-Repay tests.
  for (final flowLabel in ['Lend', 'Borrow', 'Repay']) {
    testWidgets(
      'FEAT13 D1: $flowLabel flow shows the checkbox as a persistent widget before any text is typed',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        final personField = find.byKey(const Key('person-debt-field'));
        expect(
          find.descendant(of: personField, matching: find.byType(Checkbox)),
          findsOneWidget,
        );

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'FEAT13 D2: $flowLabel flow, unchecked, typing a non-matching name shows no create option',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        final personField = find.byKey(const Key('person-debt-field'));
        await tester.enterText(
          find.descendant(of: personField, matching: find.byType(TextField)),
          'NewPerson',
        );
        await tester.pumpAndSettle();

        expect(find.text("Create 'NewPerson'"), findsNothing);
        expect(find.textContaining('Create'), findsNothing);

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'FEAT13 D2: $flowLabel flow, unchecked, an existing account is still selectable',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        final personField = find.byKey(const Key('person-debt-field'));
        await tester.enterText(
          find.descendant(of: personField, matching: find.byType(TextField)),
          'Budi',
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Budi'), findsOneWidget);
        await tester.tap(find.widgetWithText(ListTile, 'Budi'));
        await tester.pumpAndSettle();

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'FEAT13 D3: $flowLabel flow, checked, typing a new name shows a create option and always writes PERSON',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        final personField = find.byKey(const Key('person-debt-field'));
        await tester.tap(
          find.descendant(
            of: personField,
            matching: find.byKey(const Key('create-as-person-checkbox')),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(of: personField, matching: find.byType(TextField)),
          'NewPerson$flowLabel',
        );
        await tester.pumpAndSettle();

        expect(find.text("Create 'NewPerson$flowLabel'"), findsOneWidget);
        await tester.tap(
          find.widgetWithText(ListTile, "Create 'NewPerson$flowLabel'"),
        );
        await tester.pumpAndSettle();

        final created = await (database.select(
          database.accounts,
        )..where((r) => r.name.equals('NewPerson$flowLabel'))).getSingle();
        expect(created.group, AccountGroup.PERSON);
        expect(created.openingAmount, 0);

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'FEAT13 D2: $flowLabel flow, checked, an existing account is still selectable too',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        final personField = find.byKey(const Key('person-debt-field'));
        await tester.tap(
          find.descendant(
            of: personField,
            matching: find.byKey(const Key('create-as-person-checkbox')),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(of: personField, matching: find.byType(TextField)),
          'Budi',
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Budi'), findsOneWidget);
        await tester.tap(find.widgetWithText(ListTile, 'Budi'));
        await tester.pumpAndSettle();

        await unmountAndFlushTimers(tester);
      },
    );
  }

  // FEAT16 D1/D5: the admin-fee checkbox + amount field render only for
  // Transfer/Lend/Borrow/Repay — Expense/Income never show it.
  for (final flowLabel in ['Transfer', 'Lend', 'Borrow', 'Repay']) {
    testWidgets(
      'FEAT16 D1: $flowLabel flow shows the admin-fee checkbox, and checking it reveals the amount field',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        expect(find.byKey(const Key('admin-fee-checkbox')), findsOneWidget);
        expect(find.byKey(const Key('admin-fee-field')), findsNothing);

        await tester.tap(find.byKey(const Key('admin-fee-checkbox')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('admin-fee-field')), findsOneWidget);

        await unmountAndFlushTimers(tester);
      },
    );
  }

  for (final flowLabel in ['Expense', 'Income']) {
    testWidgets(
      'FEAT16 D1: $flowLabel flow never shows the admin-fee checkbox',
      (tester) async {
        await seedAccounts();
        await pumpScreen(tester);
        await switchTo(tester, flowLabel);

        expect(find.byKey(const Key('admin-fee-checkbox')), findsNothing);
        expect(find.byKey(const Key('admin-fee-field')), findsNothing);

        await unmountAndFlushTimers(tester);
      },
    );
  }

  testWidgets(
    'FEAT16 D5: checking the admin-fee box and typing a fee, then saving, writes a second linked expense row',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);
      await switchTo(tester, 'Transfer');

      await tester.enterText(find.byType(TextField).first, '100000');

      await tester.tap(find.byKey(const Key('admin-fee-checkbox')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admin-fee-field')), '2500');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final rows = await database.select(database.transactions).get();
      expect(rows, hasLength(2));
      final fee = rows.firstWhere((row) => row.kind == TransactionKind.expense);
      expect(fee.amount, 2500);
      final categories = await database.select(database.categories).get();
      expect(categories.single.name, 'Admin Fee');

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT16 D5: leaving the checkbox unchecked passes no fee even with stray text sitting in the hidden field',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);
      await switchTo(tester, 'Transfer');

      await tester.enterText(find.byType(TextField).first, '100000');

      // Check, type a stray value, then uncheck again — the field itself
      // stays populated but hidden, and unchecked means no fee (D5).
      await tester.tap(find.byKey(const Key('admin-fee-checkbox')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admin-fee-field')), '9999');
      await tester.tap(find.byKey(const Key('admin-fee-checkbox')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-fee-field')), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final rows = await database.select(database.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.kind, TransactionKind.transfer);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT16 D5: the admin-fee checkbox and field reset after save and after switching flows',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);
      await switchTo(tester, 'Transfer');

      await tester.tap(find.byKey(const Key('admin-fee-checkbox')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admin-fee-field')), '2500');

      await tester.enterText(find.byType(TextField).first, '100000');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Back at the default Expense flow — no admin-fee affordance shows,
      // and switching back to Transfer proves the checkbox reset too.
      expect(find.byKey(const Key('admin-fee-checkbox')), findsNothing);
      await switchTo(tester, 'Transfer');
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const Key('admin-fee-checkbox')),
      );
      expect(checkbox.value, isFalse);
      expect(find.byKey(const Key('admin-fee-field')), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT16 D5: checking the box then switching flows resets it on the new flow too',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);
      await switchTo(tester, 'Transfer');

      await tester.tap(find.byKey(const Key('admin-fee-checkbox')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admin-fee-field')), '2500');

      await switchTo(tester, 'Lend');

      final checkbox = tester.widget<Checkbox>(
        find.byKey(const Key('admin-fee-checkbox')),
      );
      expect(checkbox.value, isFalse);
      expect(find.byKey(const Key('admin-fee-field')), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT11 D8: selecting a RECEIVABLE debt in the Repay flow shows no direction toggle',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);
      await switchTo(tester, 'Repay');

      // 'Budi' (RECEIVABLE) is the pool's first and only debt — preselected.
      expect(find.byKey(const Key('repay-direction-toggle')), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT11 D8: selecting a PERSON debt in Repay shows the toggle, pre-selected from its balance sign, and save honors a flipped choice',
    (tester) async {
      await seedAccounts();
      await insertAccount('Sam', AccountGroup.PERSON, 30000);
      await pumpScreen(tester);
      await switchTo(tester, 'Repay');

      final personField = find.byKey(const Key('person-debt-field'));
      await tester.enterText(
        find.descendant(of: personField, matching: find.byType(TextField)),
        'Sam',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Sam'));
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const Key('repay-direction-toggle'));
      expect(toggleFinder, findsOneWidget);
      // Positive balance (30000) pre-selects "They paid me" (true).
      var toggle = tester.widget<SegmentedButton<bool>>(toggleFinder);
      expect(toggle.selected, {true});

      // Flip it to "I paid them" before saving — fully user-changeable
      // (D8: never silently trusted).
      await tester.tap(find.text('I paid them'));
      await tester.pumpAndSettle();
      toggle = tester.widget<SegmentedButton<bool>>(toggleFinder);
      expect(toggle.selected, {false});

      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final sam = await (database.select(
        database.accounts,
      )..where((r) => r.name.equals('Sam'))).getSingle();
      final row = await database.select(database.transactions).getSingle();
      expect(row.kind, TransactionKind.repayment);
      // "I paid them" (debtIsSource = false): money leaves the wallet into
      // Sam's account.
      expect(row.toAccountId, sam.accountId);
      expect(row.fromAccountId, isNot(sam.accountId));

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'Post-close fix (2026-08-25): switching the kind dropdown clears a '
    'typed-but-never-confirmed name out of the person field',
    (tester) async {
      await seedAccounts();
      await pumpScreen(tester);
      await switchTo(tester, 'Lend');

      final personField = find.byKey(const Key('person-debt-field'));
      await tester.enterText(
        find.descendant(of: personField, matching: find.byType(TextField)),
        'Someone I never confirmed',
      );
      await tester.pumpAndSettle();

      // Never tapped a suggestion or a "Create '...'" entry — selectedId
      // stays null, exactly the scenario `didUpdateWidget`'s old
      // selectedId-only check couldn't see.
      await switchTo(tester, 'Borrow');

      final textField = find.descendant(
        of: personField,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(textField).controller!.text, isEmpty);

      await unmountAndFlushTimers(tester);
    },
  );
}
