import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumptionAsync = ref.watch(budgetConsumptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget this month'),
        actions: [
          IconButton(
            tooltip: 'Set budget',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SetBudgetScreen()),
            ),
          ),
        ],
      ),
      body: consumptionAsync.when(
        data: _list,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }

  Widget _list(List<BudgetConsumption> rows) {
    if (rows.isEmpty) {
      return const Center(child: Text('No budget groups yet'));
    }

    return ListView(
      children: [
        for (final row in rows)
          _BudgetConsumptionTile(
            key: ValueKey(row.groupId ?? 'others'),
            row: row,
          ),
      ],
    );
  }
}

class _BudgetConsumptionTile extends StatelessWidget {
  const _BudgetConsumptionTile({required super.key, required this.row});

  final BudgetConsumption row;

  @override
  Widget build(BuildContext context) {
    // The "Others" label is applied here, at the view — never stored in the
    // query result (D4).
    final label = row.name ?? 'Others';

    return ListTile(
      title: Text(label),
      subtitle: Text('Budget: ${row.amount}   Spent: ${row.spent}'),
      trailing: Text(
        '${row.remaining}',
        key: ValueKey('remaining-${row.groupId ?? 'others'}'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
