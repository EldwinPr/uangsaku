import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_dao.dart';
import 'accounts_providers.dart';

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
      appBar: AppBar(title: const Text('uangsaku')),
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
            data: _accountRows,
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

  List<Widget> _accountRows(List<AccountBalance> balances) => [
    if (balances.isEmpty)
      const Text('No accounts yet.', key: ValueKey('no-accounts'))
    else
      for (final entry in balances)
        ListTile(
          title: Text(entry.account.name),
          subtitle: Text(entry.account.group.name),
          trailing: Text('${entry.balance}'),
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
