import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_form_screen.dart';
import 'package:uangsaku/src/accounts/accounts_screen.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/balance_sheet_screen.dart';
import 'package:uangsaku/src/accounts/debt_detail_screen.dart';
import 'package:uangsaku/src/app.dart';
import 'package:uangsaku/src/budgeting/set_budget_screen.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/help_screen.dart';
import 'package:uangsaku/src/settings/settings_screen.dart';
import 'package:uangsaku/src/settings/settings_table.dart';
import 'package:uangsaku/src/transactions/category_manager_screen.dart';

/// FEAT02's test (plan, Definition of done), restructured by FEAT04: every
/// primary destination renders, and every contextual entry point plan D1
/// lists is reachable from the shell it wires them into. FEAT04 splits the
/// account list into its own `AccountsScreen` tab and replaces Record's
/// `NavigationBar` destination with a docked FAB.
void main() {
  late AppDatabase database;

  setUp(() async {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    // FEAT03 D1 seeds `AppLanguage.id` by default. This file's navigation
    // assertions predate FEAT03 and are written in English; forcing English
    // here keeps them testing navigation, not translation — the locale
    // toggle itself gets its own test below, which manages the language it
    // needs explicitly.
    await database
        .update(database.settings)
        .write(const SettingsCompanion(locale: Value(AppLanguage.en)));
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
    'each of the five destinations renders its screen when selected',
    (tester) async {
      await pumpShell(tester);

      // Index 0 (Home / BalanceSheetScreen) is the initial destination.
      expect(find.text('uangsaku'), findsOneWidget);

      await tester.tap(find.text('Balance'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountsScreen).hitTestable(), findsOneWidget);

      // Record has no bottom-bar label — it is the docked FAB (FEAT04 D3).
      // `AccountsScreen`'s own "Add account" FAB is also mounted
      // (`IndexedStack` keeps every tab alive), so the tooltip disambiguates.
      await tester.tap(find.byTooltip('Record'));
      await tester.pumpAndSettle();
      expect(find.text('Record money movement').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.text('All transactions').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      expect(find.text('Budget this month').hitTestable(), findsOneWidget);

      // Switching back to Home keeps the earlier tabs' state alive
      // underneath (`IndexedStack`, never rebuilt from scratch) — every
      // screen stays mounted throughout, so this only re-shows it rather
      // than re-triggering its loading state.
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('uangsaku').hitTestable(), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT08 D2: a successful save on Record switches back to Home (index 0)',
    (tester) async {
      final accountId = await insertAccount(
        'Wallet',
        AccountGroup.HOLDING,
        100000,
      );

      await pumpShell(tester);

      await tester.tap(find.byTooltip('Record'));
      await tester.pumpAndSettle();
      expect(find.text('Record money movement').hitTestable(), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '15000');
      // `find.byType(FloatingActionButton)` is ambiguous here — the shell's
      // own docked "Record" FAB stays mounted underneath (`IndexedStack`).
      // The Save tooltip picks out the form's FAB specifically.
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Home is visible again — the shell switched tabs, not popped a route.
      expect(find.byType(BalanceSheetScreen).hitTestable(), findsOneWidget);
      expect(find.text('Record money movement').hitTestable(), findsNothing);

      final rows = await database.select(database.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.amount, 15000);
      expect(rows.single.fromAccountId, accountId);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT14 D4: the docked Record FAB reads colorScheme.primary/onPrimary, '
    'not tertiary',
    (tester) async {
      await pumpShell(tester);

      // `find.byTooltip` also matches the tooltip's own `RawTooltip` widget
      // (same caveat `saveButton()` documents above) — filter by type and
      // tooltip together to land on the `FloatingActionButton` itself.
      final fabFinder = find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton && widget.tooltip == 'Record',
      );
      final fab = tester.widget<FloatingActionButton>(fabFinder);
      final colorScheme = Theme.of(tester.element(fabFinder)).colorScheme;
      expect(fab.backgroundColor, colorScheme.primary);
      expect(fab.foregroundColor, colorScheme.onPrimary);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('the docked FAB opens Record', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Record'));
    await tester.pumpAndSettle();

    expect(find.text('Record money movement').hitTestable(), findsOneWidget);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'BalanceSheetScreen no longer renders the account list (FEAT04 D1)',
    (tester) async {
      await insertAccount('Wallet', AccountGroup.HOLDING, 100000);

      await pumpShell(tester);

      // Home is the initial destination — BalanceSheetScreen. AccountsScreen
      // is mounted underneath (`IndexedStack` keeps every tab alive) but
      // not painted/hit-testable, so `hitTestable()` distinguishes "moved
      // to another tab" from "gone" (`IndexedStack` offstages, doesn't
      // unmount, inactive children).
      expect(find.byType(BalanceSheetScreen).hitTestable(), findsOneWidget);
      expect(find.text('Wallet').hitTestable(), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('the Accounts FAB reaches AccountFormScreen in create mode', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Balance'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add account'));
    await tester.pumpAndSettle();

    final screen = tester.widget<AccountFormScreen>(
      find.byType(AccountFormScreen),
    );
    expect(screen.mode, AccountFormMode.create);
    expect(screen.accountId, isNull);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'tapping an account row on AccountsScreen reaches AccountFormScreen in edit mode with the right accountId',
    (tester) async {
      final accountId = await insertAccount(
        'Wallet',
        AccountGroup.HOLDING,
        100000,
      );

      await pumpShell(tester);

      await tester.tap(find.text('Balance'));
      await tester.pumpAndSettle();

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

  testWidgets(
    "tapping a debt row's icon on AccountsScreen reaches DebtDetailScreen",
    (tester) async {
      final accountId = await insertAccount(
        'Budi',
        AccountGroup.RECEIVABLE,
        50000,
      );

      await pumpShell(tester);

      await tester.tap(find.text('Balance'));
      await tester.pumpAndSettle();

      // FEAT10 D2 put `Icons.info_outline` tooltip icons on Home's seven
      // cards too (mounted underneath, `IndexedStack` keeps every tab
      // alive) — `.hitTestable()` narrows to the one actually visible here.
      await tester.tap(find.byIcon(Icons.info_outline).hitTestable());
      await tester.pumpAndSettle();

      final screen = tester.widget<DebtDetailScreen>(
        find.byType(DebtDetailScreen),
      );
      expect(screen.accountId, accountId);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'the Home app-bar actions reach CategoryManagerScreen, SettingsScreen and HelpScreen',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byTooltip('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryManagerScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Help'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT10 D3: Categories appears only on Home and Transactions; Settings '
    'and Help appear on every tab',
    (tester) async {
      await pumpShell(tester);

      // Home: all three.
      expect(find.byTooltip('Categories').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Help').hitTestable(), findsOneWidget);

      // Accounts: Settings and Help only.
      await tester.tap(find.text('Balance'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Categories').hitTestable(), findsNothing);
      expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Help').hitTestable(), findsOneWidget);

      // Record: Settings and Help only.
      await tester.tap(find.byTooltip('Record'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Categories').hitTestable(), findsNothing);
      expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Help').hitTestable(), findsOneWidget);

      // Transactions: all three.
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Categories').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Help').hitTestable(), findsOneWidget);

      // Budget: Settings and Help alongside the pre-existing "Set budget"
      // action; Categories stays absent.
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Categories').hitTestable(), findsNothing);
      expect(find.byTooltip('Settings').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Help').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Set budget').hitTestable(), findsOneWidget);

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

  testWidgets(
    'FEAT03 D4/D5: switching the language on SettingsScreen changes rendered '
    'text on another screen — proves the locale is wired through '
    'MaterialApp, not just stored',
    (tester) async {
      await pumpShell(tester);

      // Starting locale is English (seeded in setUp) — confirm the
      // Transactions tab renders in English first.
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.text('All transactions').hitTestable(), findsOneWidget);

      // Switch to Indonesian from Settings.
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Indonesian'));
      await tester.pumpAndSettle();

      // Not `tester.pageBack()`: it looks up the back button by its
      // localized 'Back' tooltip, which no longer matches now that the
      // locale just switched to Indonesian.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // The same Transactions tab, reached through its now-Indonesian nav
      // label, renders its now-Indonesian title — the locale is a live
      // toggle wired through MaterialApp, not a value that only sits in
      // storage.
      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Semua transaksi').hitTestable(), findsOneWidget);
      expect(find.text('All transactions'), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT03 D4: switching the theme mode on SettingsScreen changes the '
    'resolved brightness',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      final lightContext = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(lightContext).brightness, Brightness.light);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      final darkContext = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(darkContext).brightness, Brightness.dark);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    '2026-08-24 overflow audit: the bottom nav does not overflow under id '
    'labels and a large accessibility text scale',
    (tester) async {
      // The exact conditions that caused BalanceSheetScreen's figure-card
      // overflow (owner feedback, same day): a longer `id`-locale label
      // combined with a larger system font size. `id` is this app's
      // seeded default (`FEAT03 D1`) — undo the `setUp` override to it.
      await database
          .update(database.settings)
          .write(const SettingsCompanion(locale: Value(AppLanguage.id)));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(database)],
            child: const App(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A `RenderFlex` overflow throws during layout, caught here rather
      // than left to paint as the debug yellow/black stripes.
      expect(tester.takeException(), isNull);

      await unmountAndFlushTimers(tester);
    },
  );
}
