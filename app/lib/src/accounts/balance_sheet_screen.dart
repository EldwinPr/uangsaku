import 'package:fl_chart/fl_chart.dart';
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
///
/// **FEAT07 D6**: three charts appended below the four figures — balance
/// trend (last 30 days), income vs expense and spending by category (both
/// this calendar month) — each its own `Card`, each watching its own
/// `AccountDao` query (D3/D4/D5) and degrading to an empty-state message
/// rather than a blank or a crash on zero rows/zero total (D7). Display
/// only, matching this screen's existing offers-nothing-to-refuse shape —
/// NFR-4 still has nothing to bite on.
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
          const SizedBox(height: 8),
          const _BalanceTrendCard(),
          const SizedBox(height: 16),
          const _IncomeExpenseCard(),
          const SizedBox(height: 16),
          const _CategorySpendingCard(),
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

/// Shared card chrome for the three FEAT07 charts (D6) — a title, then
/// whatever the chart body is: the chart itself, a loading placeholder, an
/// error message, or the empty-state message (D7).
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

/// FEAT07 D3: the balance-trend line chart, watching [balanceTrendProvider].
class _BalanceTrendCard extends ConsumerWidget {
  const _BalanceTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final trendAsync = ref.watch(balanceTrendProvider);

    return _ChartCard(
      title: loc.balanceTrendChartTitle,
      child: trendAsync.when(
        data: (points) {
          if (points.isEmpty) {
            return Center(child: Text(loc.chartNoDataYet));
          }
          return LineChart(
            LineChartData(
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].netBalance.toDouble()),
                  ],
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(loc.figuresLoadError)),
      ),
    );
  }
}

/// FEAT07 D4: the income-vs-expense bar chart, watching
/// [incomeExpenseProvider].
class _IncomeExpenseCard extends ConsumerWidget {
  const _IncomeExpenseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(incomeExpenseProvider);

    return _ChartCard(
      title: loc.incomeExpenseChartTitle,
      child: summaryAsync.when(
        data: (summary) {
          if (summary.income == 0 && summary.expense == 0) {
            return Center(child: Text(loc.chartNoDataYet));
          }
          final colorScheme = Theme.of(context).colorScheme;
          return BarChart(
            BarChartData(
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      value == 0
                          ? loc.incomeLegendLabel
                          : loc.expenseLegendLabel,
                    ),
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: summary.income.toDouble(),
                      color: Colors.green.shade600,
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: summary.expense.toDouble(),
                      color: colorScheme.error,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(loc.figuresLoadError)),
      ),
    );
  }
}

/// FEAT07 D5: the spending-by-category donut, watching
/// [categorySpendingProvider]. A `null`-named row (the uncategorized
/// bucket, `AccountDao.watchCategorySpending`'s `LEFT JOIN`) is labelled
/// from [AppLocalizations.uncategorizedLabel] here, never stored (D5).
class _CategorySpendingCard extends ConsumerWidget {
  const _CategorySpendingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final spendingAsync = ref.watch(categorySpendingProvider);

    return _ChartCard(
      title: loc.categorySpendingChartTitle,
      child: spendingAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return Center(child: Text(loc.chartNoDataYet));
          }
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
                    title: rows[i].name ?? loc.uncategorizedLabel,
                    color: colors[i % colors.length],
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                    ),
                  ),
              ],
              centerSpaceRadius: 30,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(loc.figuresLoadError)),
      ),
    );
  }
}
