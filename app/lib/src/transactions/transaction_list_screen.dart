import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'transactions_providers.dart';
import 'transactions_table.dart';

/// `TransactionListScreen` — UC-09 (`class-transactions.drawio`:
/// *UC-09 · ConsumerWidget*): review everything ever recorded and correct
/// any row — amend its fields or remove it outright (FR-18).
///
/// Watches [transactionListProvider] and renders whatever it emits (messages
/// 2 and 12 on `seq-uc09-review-and-correct.drawio`); every control fires a
/// write through `ref.read(transactionsProvider.notifier)` and never renders
/// what the call returns — the changed list arrives as stream re-emission
/// (`riverpod.md`, the read/write asymmetry).
///
/// **Every control stays enabled, always, and nothing is refused** (UC-09
/// D7, NFR-4's zero-refusals fit criterion): delete runs immediately with no
/// confirmation dialog (D5 — the diagram draws none, and a cancelled delete
/// would be the quiet refusal NFR-4 exists to catch); the amend surface's
/// Save proceeds under empty pickers, zero amounts and blank tags exactly as
/// `RecordTransactionScreen`'s Save ships (F7 precedent).
///
/// Reached as the Transactions tab of `AppShell` (FEAT02 plan D1) — F8's
/// answer.
class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All transactions')),
      body: listAsync.when(
        data: (rows) => rows.isEmpty
            ? const Center(child: Text('No transactions yet'))
            : ListView(
                children: [for (final row in rows) _TransactionTile(row: row)],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

/// The kind label a list tile shows. Presentation only — nothing branches on
/// kind anywhere below this string; the tile renders columns (UC-09 D3/D6).
String _kindLabel(TransactionKind kind) => switch (kind) {
  TransactionKind.expense => 'Expense',
  TransactionKind.income => 'Income',
  TransactionKind.transfer => 'Transfer',
  TransactionKind.lend => 'Lend',
  TransactionKind.borrow => 'Borrow',
  TransactionKind.repayment => 'Repayment',
  TransactionKind.adjustment => 'Adjustment',
};

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.row});

  final ({Transaction transaction, String? fromName, String? toName}) row;

  /// Raw minor-unit integers, same convention `BalanceSheetScreen` ships —
  /// currency prefix/exponent formatting is widget-layer work that no
  /// artifact has specified yet (UC-01 shipped `${position.spendable}`).
  String get _dateText {
    final date = row.transaction.occurredOn;
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String get _sidesText {
    final from = row.fromName;
    final to = row.toName;
    return switch ((from, to)) {
      (final String f, final String t) => '$f → $t',
      (final String f, null) => f,
      (null, final String t) => t,
      (null, null) => 'no account set',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = row.transaction;

    return ListTile(
      onTap: () => _EditSheet.show(context, row: row),
      title: Text('${_kindLabel(transaction.kind)} · ${transaction.amount}'),
      subtitle: Text(
        '$_dateText · $_sidesText'
        '${transaction.note == null ? '' : ' · ${transaction.note}'}'
        '${transaction.categoryId == null ? '' : ' · category #${transaction.categoryId}'}'
        '${transaction.subcategoryId == null ? '' : ' · subcategory #${transaction.subcategoryId}'}'
        '${transaction.budgetGroupId == null ? '' : ' · group #${transaction.budgetGroupId}'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Amend transaction',
            onPressed: () => _EditSheet.show(context, row: row),
          ),
          // UC-09 D5: delete runs immediately and unconditionally — no
          // confirmation whose "no" could quietly become a refusal, no
          // disabled state ever (NFR-4's fit criterion is zero refusals).
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete transaction',
            onPressed: () => ref
                .read(transactionsProvider.notifier)
                .delete(id: transaction.transactionId),
          ),
        ],
      ),
    );
  }
}

/// UC-09's amend surface, presented from inside the list screen — the class
/// diagram has no edit-screen box, and naming one would invent a class
/// (UC-09 D4). A modal sheet is the coder's presentation call under D4,
/// bounded by two rules: **kind is not offered as a choice** (message 4 has
/// no kind parameter; retagging across kinds is out of scope), and every
/// control obeys D7 — always enabled, nothing refused.
///
/// Message 4's singular `account` arrives expanded per the row's kind
/// (`docs/enums.md`'s table): one side picker for expense/income/lend/
/// borrow, two for transfer/repayment/adjustment — prefilled from the stored
/// sides so an untouched field round-trips unchanged and the row never ends
/// up contradicting the kind table unless the owner clears it themselves
/// (which writes, never refuses). Tag pickers are offered for every kind,
/// because message 4 carries them unconditionally; blanks become nulls
/// (UC04's D8 convention).
class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({required this.row});

  final ({Transaction transaction, String? fromName, String? toName}) row;

  static Future<void> show(
    BuildContext context, {
    required ({Transaction transaction, String? fromName, String? toName}) row,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _EditSheet(row: row),
      ),
    );
  }

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late int? _fromAccountId;
  late int? _toAccountId;
  late int? _categoryId;
  late int? _subcategoryId;
  late int? _budgetGroupId;

  @override
  void initState() {
    super.initState();
    final transaction = widget.row.transaction;
    _amountController = TextEditingController(text: '${transaction.amount}');
    _noteController = TextEditingController(text: transaction.note ?? '');
    _date = transaction.occurredOn;
    _fromAccountId = transaction.fromAccountId;
    _toAccountId = transaction.toAccountId;
    _categoryId = transaction.categoryId;
    _subcategoryId = transaction.subcategoryId;
    _budgetGroupId = transaction.budgetGroupId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // F7 precedent (`pm/findings.md`): an empty or unparseable amount
    // proceeds as 0 rather than refusing — NFR-4.
    final amount = int.tryParse(_amountController.text) ?? 0;

    // Blanks become nulls (UC04's D8 convention, restated by UC-09 D4).
    final noteText = _noteController.text;
    final note = noteText.isEmpty ? null : noteText;

    await ref
        .read(transactionsProvider.notifier)
        .edit(
          id: widget.row.transaction.transactionId,
          amount: amount,
          fromAccountId: _fromAccountId,
          toAccountId: _toAccountId,
          date: _date,
          categoryId: _categoryId,
          subcategoryId: _subcategoryId,
          budgetGroupId: _budgetGroupId,
          note: note,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountPickerProvider);
    final groupsAsync = ref.watch(budgetGroupPickerProvider);
    final treeAsync = ref.watch(categoryTreeProvider);

    final accounts = accountsAsync.value ?? const <Account>[];
    final groups = groupsAsync.value ?? const <BudgetGroup>[];
    final tree = treeAsync.value ?? const <Category, List<Subcategory>>{};

    final categories = tree.keys.toList();
    // All subcategories flattened, unlike the record form's narrowed pool:
    // a stored subcategory must stay visible even if its parent was cleared,
    // and clearing it here is a write, never a surprise (NFR-4).
    final subcategories = [for (final children in tree.values) ...children];

    final kind = widget.row.transaction.kind;
    final needsFrom = switch (kind) {
      TransactionKind.income => false,
      _ => true,
    };
    final needsTo = switch (kind) {
      TransactionKind.expense => false,
      _ => true,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Amend ${_kindLabel(kind)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('edit-amount'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: 'Minor units, minus allowed',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (chosen != null) {
                setState(() => _date = chosen);
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              '${_date.year}-'
              '${_date.month.toString().padLeft(2, '0')}-'
              '${_date.day.toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 16),
          if (needsFrom)
            _accountDropdown(
              label: switch (kind) {
                TransactionKind.lend => 'Own account',
                TransactionKind.borrow ||
                TransactionKind.repayment ||
                TransactionKind.adjustment => 'From-side account',
                _ => 'Paying account',
              },
              pool: accounts,
              value: _fromAccountId,
              onChanged: (id) => setState(() => _fromAccountId = id),
            ),
          if (needsTo)
            _accountDropdown(
              label: switch (kind) {
                TransactionKind.lend ||
                TransactionKind.borrow => 'Person / debt',
                TransactionKind.repayment ||
                TransactionKind.adjustment => 'To-side account',
                _ => 'Receiving account',
              },
              pool: accounts,
              value: _toAccountId,
              onChanged: (id) => setState(() => _toAccountId = id),
            ),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            hint: const Text('(none)'),
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('(none)')),
              for (final category in categories)
                DropdownMenuItem<int?>(
                  value: category.categoryId,
                  child: Text(category.name),
                ),
            ],
            onChanged: (id) => setState(() => _categoryId = id),
          ),
          DropdownButtonFormField<int?>(
            initialValue: _subcategoryId,
            hint: const Text('(none)'),
            decoration: const InputDecoration(labelText: 'Subcategory'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('(none)')),
              for (final subcategory in subcategories)
                DropdownMenuItem<int?>(
                  value: subcategory.subcategoryId,
                  child: Text(subcategory.name),
                ),
            ],
            onChanged: (id) => setState(() => _subcategoryId = id),
          ),
          DropdownButtonFormField<int?>(
            initialValue: _budgetGroupId,
            hint: const Text('(none)'),
            decoration: const InputDecoration(labelText: 'Budget group'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('(none)')),
              for (final group in groups)
                DropdownMenuItem<int?>(
                  value: group.budgetGroupId,
                  child: Text(group.name),
                ),
            ],
            onChanged: (id) => setState(() => _budgetGroupId = id),
          ),
          TextField(
            key: const Key('edit-note'),
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 16),
          // Always enabled (UC-09 D7): whatever the sheet holds gets written,
          // including zero amounts and blank tags.
          FilledButton.icon(
            key: const Key('edit-save'),
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _accountDropdown({
    required String label,
    required List<Account> pool,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      hint: Text(pool.isEmpty ? 'No accounts yet' : '(none)'),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final account in pool)
          DropdownMenuItem<int?>(
            value: account.accountId,
            child: Text(account.name),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
