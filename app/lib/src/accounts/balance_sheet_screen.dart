import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/currency_screen.dart';
import '../transactions/category_manager_screen.dart';
import 'account_dao.dart';
import 'account_form_screen.dart';
import 'accounts_providers.dart';
import 'accounts_table.dart';
import 'debt_detail_screen.dart';

/// `BalanceSheetScreen` — the primary screen (FR-1), UC-01.
///
/// Messages 1, 7 and 13 on `seq-uc01-balance-sheet.drawio`: watches
/// [financialPositionProvider] for the four figures and
/// [accountBalancesProvider] for the per-account list. It writes nothing,
/// computes nothing itself (NFR-2 — every figure arrives already derived by
/// query) and offers no action that could be refused, so NFR-4's zero-
/// refusal criterion has nothing to bite on: there is not a single control
/// on this screen.
///
/// Amounts render as raw minor-unit integers (`${position.spendable}`) —
/// currency prefix/exponent formatting is deliberately out of UC-01's scope
/// (`plan.md`, Out of scope: *Currency display*); the decimal point exists
/// only in the widget layer (`drift.md` §Money).
///
/// Loading states show zeros / placeholders; an error shows a message rather
/// than silently rendering zeros as if they were real figures.
class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  /// D4's COALESCE behaviour made visible: before the first emission (and
  /// only then) the figures read as zeros.
  static const FinancialPosition _zero = FinancialPosition(
    spendable: 0,
    owedToMe: 0,
    owedByMe: 0,
    net: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(financialPositionProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('uangsaku'),
        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoryManagerScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Currency',
            icon: const Icon(Icons.attach_money),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CurrencyScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Explicit tag (FEAT02 plan D1): `AppShell`'s `IndexedStack` keeps
        // every tab mounted at once, so this FAB and Record's FAB coexist
        // in the same subtree — the implicit default tag they'd otherwise
        // share collides (Flutter's Hero identity requirement), not a
        // business-logic change.
        heroTag: 'balance-sheet-fab',
        tooltip: 'Add account',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...positionAsync.when(
            data: _figures,
            loading: () => _figures(_zero),
            error: (_, _) => const [Text('The figures could not be loaded.')],
          ),
          const SizedBox(height: 24),
          Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
          ...balancesAsync.when(
            data: (balances) => _accountRows(context, balances),
            loading: () => const [Text('Loading accounts…')],
            error: (_, _) => const [Text('The accounts could not be loaded.')],
          ),
        ],
      ),
    );
  }

  /// The four figures, each its own card — spendable is never merged with
  /// owed-to-me; FR-1's "money sitting with Budi cannot buy lunch" is this
  /// list not being one number.
  List<Widget> _figures(FinancialPosition position) => [
    _FigureCard(
      figureKey: const ValueKey('figure-spendable'),
      label: 'What I can spend now',
      minorUnits: position.spendable,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-owed-to-me'),
      label: 'Owed to me',
      minorUnits: position.owedToMe,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-owed-by-me'),
      label: 'Owed by me',
      minorUnits: position.owedByMe,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-net'),
      label: 'Net',
      minorUnits: position.net,
    ),
  ];

  /// Row tap opens [AccountFormScreen] in edit mode (FEAT02 plan D3 — never
  /// adjust mode; UC-03's adjust flow has no entry point in this shell). A
  /// trailing icon on `RECEIVABLE`/`PAYABLE` rows opens [DebtDetailScreen]
  /// (FEAT02 plan D1) — the screen is meaningless for `HOLDING` accounts.
  List<Widget> _accountRows(
    BuildContext context,
    List<AccountBalance> balances,
  ) => [
    if (balances.isEmpty)
      const Text('No accounts yet.', key: ValueKey('no-accounts'))
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
                  entry.account.group == AccountGroup.PAYABLE)
                IconButton(
                  tooltip: 'Debt details',
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

class _FigureCard extends StatelessWidget {
  const _FigureCard({
    this.figureKey,
    required this.label,
    required this.minorUnits,
  });

  /// On the value [Text] itself, so tests assert the figure, not the card.
  final Key? figureKey;
  final String label;
  final int minorUnits;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '$minorUnits',
          key: figureKey,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
