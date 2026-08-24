import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'accounts/balance_sheet_screen.dart';
import 'budgeting/budget_overview_screen.dart';
import 'settings/settings_providers.dart';
import 'settings/settings_table.dart';
import 'transactions/record_transaction_screen.dart';
import 'transactions/transaction_list_screen.dart';

/// The app's default theme seed — used whenever `Settings.seedColor` is
/// `null` (FEAT03 D1).
const Color _defaultSeedColor = Colors.deepPurple;

/// `MaterialApp` root.
///
/// `home` is [AppShell] — F8's resolution (FEAT02 plan D1): every screen
/// since UC-13 shipped with no route to it, and F8 tracked the absence since
/// UC-11's close as "the owner's standing question." `AppShell` is the
/// navigation host that answers it; `App` itself stays the thin
/// `MaterialApp` wrapper it always was.
///
/// **`ConsumerWidget` as of FEAT03 D4**: `theme`/`darkTheme` derive from the
/// stored `seedColor` (or [_defaultSeedColor]) via `ColorScheme.fromSeed`;
/// `themeMode` maps the stored `AppThemeMode` to Flutter's own `ThemeMode`;
/// `locale` is driven by the stored `AppLanguage`. Each is read by watching
/// its provider and rebuilding, the same degrade-before-first-emission
/// pattern every other screen in this app already uses — a brief flash of
/// the default locale/theme before the first stream emission is acceptable
/// (FEAT03 D4).
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider).value ?? AppLanguage.id;
    final themeModeSetting =
        ref.watch(themeModeProvider).value ?? AppThemeMode.system;
    final seedColor = ref.watch(seedColorProvider).value;
    final seed = seedColor == null ? _defaultSeedColor : Color(seedColor);

    return MaterialApp(
      title: 'uangsaku',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(language.name),
      themeMode: switch (themeModeSetting) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// The navigation host FEAT02 adds (plan D1): a Material 3 `NavigationBar`
/// with four primary destinations — Balance Sheet, Record, Transactions,
/// Budget — each its own persistent subtree via `IndexedStack` so switching
/// tabs never rebuilds a tab's provider subscriptions from scratch (a tab's
/// loading state does not re-trigger just from switching back to it).
///
/// The contextual entry points plan D1 lists (create/edit account, debt
/// detail, category manager, currency, set budget) are wired inside
/// `BalanceSheetScreen` and `BudgetOverviewScreen` themselves (D2) — this
/// shell only owns which of the four primary screens is visible.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet),
        label: loc.navBalanceSheet,
      ),
      NavigationDestination(
        icon: const Icon(Icons.add_circle_outline),
        selectedIcon: const Icon(Icons.add_circle),
        label: loc.navRecord,
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: loc.navTransactions,
      ),
      NavigationDestination(
        icon: const Icon(Icons.pie_chart_outline),
        selectedIcon: const Icon(Icons.pie_chart),
        label: loc.navBudget,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          BalanceSheetScreen(),
          RecordTransactionScreen(),
          TransactionListScreen(),
          BudgetOverviewScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: destinations,
      ),
    );
  }
}
