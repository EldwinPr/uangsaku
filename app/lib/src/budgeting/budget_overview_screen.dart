import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/tab_app_bar_actions.dart';
import 'budget_dao.dart';
import 'budgeting_providers.dart';
import 'set_budget_screen.dart';

/// `BudgetOverviewScreen` — UC-12 (FR-13, FR-17): the current month's amount,
/// spent and remaining for every budget group, plus an "Others" line for
/// spending recorded with no budget group.
///
/// Messages 1 and 6 on `seq-uc12-budget-consumption.drawio`: watches
/// [budgetConsumptionProvider] and renders whatever it emits. It computes
/// nothing itself — `remaining` arrives already derived by query (NFR-2) —
/// and has **no controls at all** (D8): no confirmation, no warning banner,
/// no "over budget" modal. A negative `remaining` is rendered exactly like a
/// positive one; overspending is a data value, never a block (FR-12, NFR-4).
///
/// Reached as the Budget tab of `AppShell` (FEAT02 plan D1) — F8's answer.
/// Its own app-bar action opens `SetBudgetScreen`, where the amounts are set
/// (FEAT02 plan D1).
///
/// **FEAT15 D2**: a donut chart of each group's `amount` (allocation, not
/// spend) sits above the rows, inside the same scrollable `ListView` — same
/// display-only, no-new-provider shape as every other chart in this app.
class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final consumptionAsync = ref.watch(budgetConsumptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.budgetOverviewTitle),
        actions: [
          IconButton(
            tooltip: loc.setBudgetTooltip,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SetBudgetScreen()),
            ),
          ),
          ...tabAppBarActions(context, showCategories: false),
        ],
      ),
      body: consumptionAsync.when(
        data: (rows) => _list(loc, rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }

  Widget _list(AppLocalizations loc, List<BudgetConsumption> rows) {
    if (rows.isEmpty) {
      return Center(child: Text(loc.noBudgetGroupsYet));
    }

    return ListView(
      children: [
        _BudgetAllocationChart(rows: rows),
        for (final row in rows)
          _BudgetConsumptionTile(
            key: ValueKey(row.groupId ?? 'others'),
            row: row,
          ),
      ],
    );
  }
}

/// FEAT15 D2: the budget-allocation donut, above the group rows — each
/// group's `amount` (what was set aside), never `spent`/`remaining` (D1).
/// Reads the same [BudgetConsumption] list [BudgetOverviewScreen] already
/// watches — no new provider, no new DAO query (D3). The "Others" row's
/// `amount` is always 0 (`BudgetDao` D4) so it needs no special-case
/// exclusion; it just contributes an invisible zero-width slice.
///
/// Same degrade-on-zero shape every other chart in this app uses (FEAT07
/// D7): an empty [rows] or every row's `amount` being 0 (which is exactly
/// what an unseeded database looks like — only the ever-present, always-0
/// Others row) shows [AppLocalizations.chartNoDataYet] instead of a
/// degenerate pie.
class _BudgetAllocationChart extends StatelessWidget {
  const _BudgetAllocationChart({required this.rows});

  final List<BudgetConsumption> rows;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasAllocation = rows.any((row) => row.amount > 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.budgetAllocationChartTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: hasAllocation
                  ? _pie(context, loc)
                  : Center(child: Text(loc.chartNoDataYet)),
            ),
          ],
        ),
      ),
    );
  }

  /// Same color-cycling shape as `BalanceSheetScreen`'s
  /// `_CategorySpendingCard` (`colorScheme.primary/secondary/tertiary/
  /// error/primaryContainer/secondaryContainer`, repeating via modulo) — no
  /// new palette invented (D2).
  Widget _pie(BuildContext context, AppLocalizations loc) {
    final palette = Theme.of(context).colorScheme;
    final colors = [
      palette.primary,
      palette.secondary,
      palette.tertiary,
      palette.error,
      palette.primaryContainer,
      palette.secondaryContainer,
    ];
    return PieChart(
      PieChartData(
        sections: [
          for (var i = 0; i < rows.length; i++)
            PieChartSectionData(
              value: rows[i].amount.toDouble(),
              title: rows[i].name ?? loc.othersLabel,
              color: colors[i % colors.length],
              radius: 60,
              titleStyle: const TextStyle(fontSize: 9, color: Colors.white),
            ),
        ],
        centerSpaceRadius: 30,
      ),
    );
  }
}

class _BudgetConsumptionTile extends StatelessWidget {
  const _BudgetConsumptionTile({required super.key, required this.row});

  final BudgetConsumption row;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // The "Others" label is applied here, at the view — never stored in the
    // query result (D4).
    final label = row.name ?? loc.othersLabel;

    return ListTile(
      title: Text(label),
      subtitle: Text(loc.budgetSpentSubtitle(row.amount, row.spent)),
      trailing: Text(
        '${row.remaining}',
        key: ValueKey('remaining-${row.groupId ?? 'others'}'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
