import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import '../transactions/category_manager_screen.dart';
import 'account_dao.dart';
import 'accounts_providers.dart';

/// `BalanceSheetScreen` — the primary screen (FR-1), UC-01.
///
/// Messages 1, 7 and 13 on `seq-uc01-balance-sheet.drawio`: watches
/// [financialPositionProvider] for the four figures. It writes nothing,
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
///
/// The currency app-bar action reaches [SettingsScreen] (FEAT03 D3) — was
/// `CurrencyScreen` before this issue; the currency section inside it is
/// unchanged.
///
/// **FEAT04 D1**: the per-account list (FAB, row tap, debt-details icon)
/// moved to the new [AccountsScreen] (`accounts_screen.dart`) — this screen
/// keeps only the four figures.
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
    final loc = AppLocalizations.of(context)!;
    final positionAsync = ref.watch(financialPositionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.balanceSheetTitle),
        actions: [
          IconButton(
            tooltip: loc.categoriesTooltip,
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoryManagerScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: loc.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...positionAsync.when(
            data: (position) => _figures(loc, position),
            loading: () => _figures(loc, _zero),
            error: (_, _) => [Text(loc.figuresLoadError)],
          ),
        ],
      ),
    );
  }

  /// The four figures, each its own card — spendable is never merged with
  /// owed-to-me; FR-1's "money sitting with Budi cannot buy lunch" is this
  /// list not being one number.
  List<Widget> _figures(AppLocalizations loc, FinancialPosition position) => [
    _FigureCard(
      figureKey: const ValueKey('figure-spendable'),
      label: loc.figureSpendable,
      minorUnits: position.spendable,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-owed-to-me'),
      label: loc.figureOwedToMe,
      minorUnits: position.owedToMe,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-owed-by-me'),
      label: loc.figureOwedByMe,
      minorUnits: position.owedByMe,
    ),
    _FigureCard(
      figureKey: const ValueKey('figure-net'),
      label: loc.figureNet,
      minorUnits: position.net,
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
