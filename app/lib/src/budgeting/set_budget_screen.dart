import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'budgeting_providers.dart';

/// `SetBudgetScreen` — UC-11: set, change or clear each budget group's
/// amount for the current calendar month, and create, rename or delete a
/// budget group (FR-12, FR-14, FR-15, FR-16, FR-18).
///
/// Watches `budgetProvider` and renders whatever it emits; every control
/// fires `ref.read(budgetProvider.notifier).…` and never renders what the
/// call returns — the updated view arrives on the next stream emission
/// (`riverpod.md`, the read/write asymmetry).
///
/// **Every control stays enabled, always** (D9, NFR-4's zero-refusals fit
/// criterion): save, delete period, add group, rename group, delete group.
/// A group's delete-period control is absent, not disabled, when there is
/// no current-month row to delete — there is nothing to delete, which is
/// not a refusal.
class SetBudgetScreen extends ConsumerWidget {
  const SetBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set the monthly budget')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _promptAddGroup(context, ref),
        tooltip: 'Add budget group',
        child: const Icon(Icons.add),
      ),
      body: rows.when(
        data: (rows) => _BudgetGroupList(rows: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

class _BudgetGroupList extends StatelessWidget {
  const _BudgetGroupList({required this.rows});

  final List<BudgetRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No budget groups yet'));
    }

    return ListView(
      children: [
        for (final row in rows)
          _BudgetGroupTile(
            key: ValueKey('${row.groupId}-${row.periodId}-${row.amount}'),
            row: row,
          ),
      ],
    );
  }
}

class _BudgetGroupTile extends StatefulWidget {
  const _BudgetGroupTile({required super.key, required this.row});

  final BudgetRow row;

  @override
  State<_BudgetGroupTile> createState() => _BudgetGroupTileState();
}

class _BudgetGroupTileState extends State<_BudgetGroupTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.row.amount == null ? '' : widget.row.amount.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final row = widget.row;
        return ListTile(
          title: Text(row.name),
          subtitle: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Amount'),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save amount',
                onPressed: () {
                  final amount = int.tryParse(_controller.text) ?? 0;
                  ref
                      .read(budgetProvider.notifier)
                      .setAmount(groupId: row.groupId, amount: amount);
                },
              ),
              if (row.periodId != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: "Delete this month's period",
                  onPressed: () => ref
                      .read(budgetProvider.notifier)
                      .delete(periodId: row.periodId!),
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Rename group',
                onPressed: () => _promptRenameGroup(
                  context,
                  ref,
                  groupId: row.groupId,
                  currentName: row.name,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete group',
                onPressed: () => ref
                    .read(budgetProvider.notifier)
                    .deleteGroup(groupId: row.groupId),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _promptAddGroup(BuildContext context, WidgetRef ref) async {
  final name = await _promptForName(context, initialValue: '');
  if (name == null) {
    return;
  }
  await ref.read(budgetProvider.notifier).addGroup(name: name);
}

Future<void> _promptRenameGroup(
  BuildContext context,
  WidgetRef ref, {
  required int groupId,
  required String currentName,
}) async {
  final name = await _promptForName(context, initialValue: currentName);
  if (name == null) {
    return;
  }
  await ref
      .read(budgetProvider.notifier)
      .renameGroup(groupId: groupId, newName: name);
}

Future<String?> _promptForName(
  BuildContext context, {
  required String initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
