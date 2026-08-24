import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'accounts/accounts_screen.dart';
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

/// The navigation host FEAT02 adds (plan D1), restructured by FEAT04 D1–D3:
/// five primary destinations — Home, Accounts, Record, Transactions, Budget
/// — each its own persistent subtree via `IndexedStack` so switching tabs
/// never rebuilds a tab's provider subscriptions from scratch (a tab's
/// loading state does not re-trigger just from switching back to it).
///
/// Record (index 2) is no longer a `NavigationBar` destination: it is a
/// colored circular `FloatingActionButton` docked in a `BottomAppBar` notch
/// (FEAT04 D3) — tapping it sets `_index` the same way tapping any other
/// destination does, so it is one more way into the same `IndexedStack`
/// slot, not a separate mechanism.
///
/// The contextual entry points plan D1 lists (create/edit account, debt
/// detail, category manager, currency, set budget) are wired inside
/// `AccountsScreen` and `BudgetOverviewScreen` themselves (D2) — this shell
/// only owns which of the five primary screens is visible.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _recordIndex = 2;

  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const BalanceSheetScreen(),
          const AccountsScreen(),
          // FEAT08 D2: a successful save switches back to Home (index 0).
          RecordTransactionScreen(onSaved: () => _select(0)),
          const TransactionListScreen(),
          const BudgetOverviewScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'app-shell-record-fab',
        tooltip: loc.navRecord,
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        onPressed: () => _select(_recordIndex),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _NavIconButton(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: loc.navHome,
                  selected: _index == 0,
                  onTap: () => _select(0),
                ),
                _NavIconButton(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  label: loc.navAccounts,
                  selected: _index == 1,
                  onTap: () => _select(1),
                ),
              ],
            ),
            Row(
              children: [
                _NavIconButton(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: loc.navTransactions,
                  selected: _index == 3,
                  onTap: () => _select(3),
                ),
                _NavIconButton(
                  icon: Icons.pie_chart_outline,
                  selectedIcon: Icons.pie_chart,
                  label: loc.navBudget,
                  selected: _index == 4,
                  onTap: () => _select(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One `BottomAppBar` destination — the hand-rolled equivalent of a
/// `NavigationDestination` (FEAT04 D3), since `BottomAppBar` does not supply
/// the selected/unselected tinting `NavigationBar` gave for free. Always
/// tappable, including while already selected (NFR-4) — selection changes
/// `_index`, it never disables an `onTap`.
class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
