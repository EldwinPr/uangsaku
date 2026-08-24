import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/tab_app_bar_actions.dart';
import 'account_dao.dart';
import 'account_form_screen.dart';
import 'accounts_providers.dart';
import 'accounts_table.dart';
import 'debt_detail_screen.dart';

/// `AccountsScreen` — split out of `BalanceSheetScreen` by FEAT04 D1: the
/// per-account list, its FAB, row-tap-to-edit, and the debt-details icon,
/// moved here verbatim (same widgets, same behavior). `BalanceSheetScreen`
/// keeps only the four top-level figures.
///
/// Watches [accountBalancesProvider] — the same single stream
/// `BalanceSheetScreen` used to watch for this section
/// (`class-accounts.drawio`, FEAT04 label). Writes nothing itself; every
/// action here navigates to another screen that owns the write.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final balancesAsync = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.accountsSectionTitle),
        actions: tabAppBarActions(context, showCategories: false),
      ),
      floatingActionButton: FloatingActionButton(
        // Explicit tag (FEAT02 plan D1, carried over by the FEAT04 split):
        // `AppShell`'s `IndexedStack` keeps every tab mounted at once, so
        // this FAB and Record's FAB coexist in the same subtree — the
        // implicit default tag they'd otherwise share collides (Flutter's
        // Hero identity requirement), not a business-logic change.
        heroTag: 'accounts-fab',
        tooltip: loc.addAccountTooltip,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...balancesAsync.when(
            data: (balances) => _accountRows(context, loc, balances),
            loading: () => [Text(loc.accountsLoading)],
            error: (_, _) => [Text(loc.accountsLoadError)],
          ),
        ],
      ),
    );
  }

  /// Row tap opens [AccountFormScreen] in edit mode (FEAT02 plan D3 — never
  /// adjust mode; UC-03's adjust flow has no entry point in this shell). A
  /// trailing icon on `RECEIVABLE`/`PAYABLE`/`PERSON` rows opens
  /// [DebtDetailScreen] (FEAT02 plan D1, extended by FEAT11 D5) — the
  /// screen is meaningless for `HOLDING` accounts.
  List<Widget> _accountRows(
    BuildContext context,
    AppLocalizations loc,
    List<AccountBalance> balances,
  ) => [
    if (balances.isEmpty)
      Text(loc.noAccountsYetPeriod, key: const ValueKey('no-accounts'))
    else
      for (final entry in balances)
        ListTile(
          title: Text(entry.account.name),
          subtitle: Text(entry.account.group.name),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AccountFormScreen(
                mode: AccountFormMode.edit,
                accountId: entry.account.accountId,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${entry.balance}'),
              if (entry.account.group == AccountGroup.RECEIVABLE ||
                  entry.account.group == AccountGroup.PAYABLE ||
                  entry.account.group == AccountGroup.PERSON)
                IconButton(
                  tooltip: loc.debtDetailsTooltip,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DebtDetailScreen(accountId: entry.account.accountId),
                    ),
                  ),
                ),
            ],
          ),
        ),
  ];
}
