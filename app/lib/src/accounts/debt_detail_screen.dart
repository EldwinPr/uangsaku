import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_dao.dart';
import 'accounts_providers.dart';

/// `DebtDetailScreen` — UC-10 (FR-11), one debt's paid / remaining figures
/// plus the settle tick.
///
/// Messages 1, 2 and 7 on `seq-uc10-debt-progress.drawio`: watches
/// [debtProgressProvider] keyed by the account id. It computes nothing
/// itself (NFR-2 — both figures arrive already derived by query) and its
/// single control, the settle button, is **always enabled** and fires
/// `markSettled(accountId)` directly: no confirmation dialog that could end
/// in "no", no arithmetic check, no disabled state (NFR-4's zero-refusal
/// criterion; the sequence diagram's `opt` guard names a user action, not a
/// predicate). The debt is never ticked by itself either — reaching
/// `remaining == 0` sets nothing (`plan.md`, Out of scope).
///
/// After the tap, the write returns nothing to this screen; the next stream
/// emission carries `settled: true` (message 7), which is what the settled
/// badge shows.
///
/// Amounts render as raw minor-unit integers — currency formatting is the
/// known display gap shared with `BalanceSheetScreen` (`plan.md`, Out of
/// scope). The header shows no account name: no drawn message fetches one,
/// so it would be an undrawn read; noted as a known gap in the plan.
///
/// Reached from the Balance Sheet tab's `RECEIVABLE`/`PAYABLE` rows, via
/// their trailing icon (FEAT02 plan D1) — F8's answer.
class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.accountId});

  /// The debt being viewed — the family key of [debtProgressProvider].
  final int accountId;

  /// D4's COALESCE behaviour made visible: before the first emission (and
  /// only then) the figures read as zeros.
  static const DebtProgress _zero = DebtProgress(
    paid: 0,
    remaining: 0,
    settled: false,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(debtProgressProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: Text('Debt #$accountId')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...progressAsync.when(
            data: _figures,
            loading: () => _figures(_zero),
            error: (_, _) => const [Text('The figures could not be loaded.')],
          ),
          const SizedBox(height: 24),
          // Always enabled, always proceeds — NFR-4 has nothing to bite on.
          FilledButton.icon(
            key: const ValueKey('settle-button'),
            onPressed: () => ref
                .read(accountsProvider.notifier)
                .markSettled(accountId: accountId),
            icon: const Icon(Icons.check),
            label: const Text('Mark settled'),
          ),
        ],
      ),
    );
  }

  /// The two figures, each its own card — paid is not remaining's complement
  /// shown twice but its own derivation (D4: repayment sum vs ABS balance);
  /// the two move independently, which the dual-encoding tests pin.
  List<Widget> _figures(DebtProgress progress) => [
    _FigureCard(
      figureKey: const ValueKey('figure-paid'),
      label: 'Paid off',
      minorUnits: progress.paid,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-remaining'),
      label: 'Left to pay',
      minorUnits: progress.remaining,
    ),
    if (progress.settled)
      const ListTile(
        key: ValueKey('settled-badge'),
        leading: Icon(Icons.check_circle),
        title: Text('Settled'),
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
