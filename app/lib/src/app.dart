import 'package:flutter/material.dart';

import 'accounts/balance_sheet_screen.dart';
import 'budgeting/budget_overview_screen.dart';
import 'transactions/record_transaction_screen.dart';
import 'transactions/transaction_list_screen.dart';

/// `MaterialApp` root.
///
/// `home` is [AppShell] — F8's resolution (FEAT02 plan D1): every screen
/// since UC-13 shipped with no route to it, and F8 tracked the absence since
/// UC-11's close as "the owner's standing question." `AppShell` is the
/// navigation host that answers it; `App` itself stays the thin
/// `MaterialApp` wrapper it always was.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Balance Sheet',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_circle_outline),
      selectedIcon: Icon(Icons.add_circle),
      label: 'Record',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Transactions',
    ),
    NavigationDestination(
      icon: Icon(Icons.pie_chart_outline),
      selectedIcon: Icon(Icons.pie_chart),
      label: 'Budget',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        destinations: _destinations,
      ),
    );
  }
}
