import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_providers.dart';
import '../settings/settings_table.dart';
import '../settings/tab_app_bar_actions.dart';
import 'account_dao.dart';
import 'account_form_screen.dart';
import 'accounts_providers.dart';
import 'accounts_table.dart';
import 'debt_detail_screen.dart';
import 'money_format.dart';

/// `AccountsScreen` — split out of `BalanceSheetScreen` by FEAT04 D1: the
/// per-account list, its FAB, row-tap-to-edit, and the debt-details icon,
/// moved here verbatim (same widgets, same behavior). `BalanceSheetScreen`
/// keeps only the four top-level figures.
///
/// Watches [accountBalancesProvider] — the same single stream
/// `BalanceSheetScreen` used to watch for this section
/// (`class-accounts.drawio`, FEAT04 label). Writes nothing itself; every
/// action here navigates to another screen that owns the write.
///
/// **Owner feedback, 2026-08-24:** the bottom-nav label for this tab
/// changed from "Akun"/"Accounts" to "Saldo"/"Balance" (`navAccounts`); this
/// screen's own list is now split into two collapsible sections — every
/// `HOLDING`/`RECEIVABLE`/`PAYABLE` account under the existing "Akun"/
/// "Accounts" header (`accountsSectionTitle`, reused — this section really
/// is exactly what that title already said), every `PERSON` account under
/// its own header (`accountGroupLabelPerson`, reused rather than a second
/// key with the same word) — each header showing that section's balance
/// sum next to it. This is a display grouping only: it does not change
/// which figure any account counts toward on `BalanceSheetScreen` (D2's
/// sign-based `PERSON` bucketing there is untouched) and computes nothing
/// beyond a plain sum of what `accountBalancesProvider` already derived.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final balancesAsync = ref.watch(accountBalancesProvider);
    // Degrades to IDR before the first emission — the same graceful-
    // degradation shape `BalanceSheetScreen` already uses for the section
    // sums' formatting.
    final currency = ref.watch(currencyProvider).value ?? Currency.IDR;

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
        children: balancesAsync.when(
          data: (balances) => _sections(context, loc, balances, currency),
          loading: () => [Text(loc.accountsLoading)],
          error: (_, _) => [Text(loc.accountsLoadError)],
        ),
      ),
    );
  }

  /// Two collapsible sections — every non-`PERSON` account, then every
  /// `PERSON` account — each its own sum next to the header (owner
  /// feedback, 2026-08-24). Both always render, even empty, the same
  /// "show zero rather than hide the section" shape every other screen in
  /// this app already uses.
  List<Widget> _sections(
    BuildContext context,
    AppLocalizations loc,
    List<AccountBalance> balances,
    Currency currency,
  ) {
    final accounts = [
      for (final entry in balances)
        if (entry.account.group != AccountGroup.PERSON) entry,
    ];
    final people = [
      for (final entry in balances)
        if (entry.account.group == AccountGroup.PERSON) entry,
    ];
    final accountsSum = accounts.fold(0, (sum, entry) => sum + entry.balance);
    final peopleSum = people.fold(0, (sum, entry) => sum + entry.balance);

    return [
      _AccountSection(
        key: const ValueKey('accounts-section'),
        title: loc.accountsSectionTitle,
        sumText: formatMinorUnits(context, accountsSum, currency),
        rows: _accountRows(context, loc, accounts, currency),
      ),
      const SizedBox(height: 8),
      _AccountSection(
        key: const ValueKey('person-section'),
        title: loc.accountGroupLabelPerson,
        sumText: formatMinorUnits(context, peopleSum, currency),
        rows: _accountRows(context, loc, people, currency),
      ),
    ];
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
    Currency currency,
  ) => [
    if (balances.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(loc.noAccountsYetPeriod),
      )
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
              Text(
                formatMinorUnits(
                  context,
                  entry.account.group == AccountGroup.HOLDING
                      ? entry.balance
                      : entry.balance.abs(),
                  currency,
                ),
              ),
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

/// One collapsible section (owner feedback, 2026-08-24) — a header showing
/// [title] and [sumText] side by side, expanded by default so the split
/// never hides information the flat list already showed.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    super.key,
    required this.title,
    required this.sumText,
    required this.rows,
  });

  final String title;
  final String sumText;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(sumText, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        children: rows,
      ),
    );
  }
}
