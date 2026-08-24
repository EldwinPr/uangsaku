import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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
    final loc = AppLocalizations.of(context)!;
    final listAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.allTransactionsTitle)),
      body: listAsync.when(
        data: (rows) => rows.isEmpty
            ? Center(child: Text(loc.noTransactionsYet))
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
String _kindLabel(AppLocalizations loc, TransactionKind kind) => switch (kind) {
  TransactionKind.expense => loc.kindExpense,
  TransactionKind.income => loc.kindIncome,
  TransactionKind.transfer => loc.kindTransfer,
  TransactionKind.lend => loc.kindLend,
  TransactionKind.borrow => loc.kindBorrow,
  TransactionKind.repayment => loc.kindRepayment,
  TransactionKind.adjustment => loc.kindAdjustment,
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

  String _sidesText(AppLocalizations loc) {
    final from = row.fromName;
    final to = row.toName;
    return switch ((from, to)) {
      (final String f, final String t) => '$f → $t',
      (final String f, null) => f,
      (null, final String t) => t,
      (null, null) => loc.noAccountSet,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final transaction = row.transaction;

    return ListTile(
      onTap: () => _EditSheet.show(context, row: row),
      title: Text(
        '${_kindLabel(loc, transaction.kind)} · ${transaction.amount}',
      ),
      subtitle: Text(
        '$_dateText · ${_sidesText(loc)}'
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
            tooltip: loc.amendTransactionTooltip,
            onPressed: () => _EditSheet.show(context, row: row),
          ),
          // UC-09 D5: delete runs immediately and unconditionally — no
          // confirmation whose "no" could quietly become a refusal, no
          // disabled state ever (NFR-4's fit criterion is zero refusals).
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: loc.deleteTransactionTooltip,
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
    final loc = AppLocalizations.of(context)!;
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
            loc.amendSheetTitle(_kindLabel(loc, kind)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('edit-amount'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: loc.amountLabel,
              hintText: loc.amountHintMinor,
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
              loc,
              label: switch (kind) {
                TransactionKind.lend => loc.ownAccountLabel,
                TransactionKind.borrow ||
                TransactionKind.repayment ||
                TransactionKind.adjustment => loc.fromSideAccountLabel,
                _ => loc.payingAccountLabel,
              },
              pool: accounts,
              value: _fromAccountId,
              onChanged: (id) => setState(() => _fromAccountId = id),
            ),
          if (needsTo)
            _accountDropdown(
              loc,
              label: switch (kind) {
                TransactionKind.lend ||
                TransactionKind.borrow => loc.personDebtLabel,
                TransactionKind.repayment ||
                TransactionKind.adjustment => loc.toSideAccountLabel,
                _ => loc.receivingAccountLabel,
              },
              pool: accounts,
              value: _toAccountId,
              onChanged: (id) => setState(() => _toAccountId = id),
            ),
          // FEAT05 D1/D2: autocomplete-with-inline-create. D3: unlike
          // `RecordTransactionScreen`'s narrowed pool, this sheet's
          // subcategory suggestions stay the full flattened list above (UC-09
          // D6, "browsing" rule) — only the create-new affordance is gated on
          // a category being selected.
          _CategoryAutocompleteField(
            key: const Key('edit-category-field'),
            label: loc.categoryLabel,
            options: [
              for (final category in categories)
                (id: category.categoryId, name: category.name),
            ],
            selectedId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
            onCreate: (name) =>
                ref.read(categoriesProvider.notifier).add(name: name),
            createLabel: loc.createOptionLabel,
          ),
          _CategoryAutocompleteField(
            key: const Key('edit-subcategory-field'),
            label: loc.subcategoryLabel,
            options: [
              for (final subcategory in subcategories)
                (id: subcategory.subcategoryId, name: subcategory.name),
            ],
            selectedId: _subcategoryId,
            onSelected: (id) => setState(() => _subcategoryId = id),
            onCreate: _categoryId == null
                ? null
                : (name) => ref
                      .read(categoriesProvider.notifier)
                      .add(categoryId: _categoryId, name: name),
            createLabel: loc.createOptionLabel,
          ),
          DropdownButtonFormField<int?>(
            initialValue: _budgetGroupId,
            hint: Text(loc.noneHint),
            decoration: InputDecoration(labelText: loc.budgetGroupLabel),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(loc.noneHint)),
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
            decoration: InputDecoration(labelText: loc.noteOptionalLabel),
          ),
          const SizedBox(height: 16),
          // Always enabled (UC-09 D7): whatever the sheet holds gets written,
          // including zero amounts and blank tags.
          FilledButton.icon(
            key: const Key('edit-save'),
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(loc.saveButton),
          ),
        ],
      ),
    );
  }

  Widget _accountDropdown(
    AppLocalizations loc, {
    required String label,
    required List<Account> pool,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      hint: Text(pool.isEmpty ? loc.noAccountsYetHint : loc.noneHint),
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

/// FEAT05 D1/D2: the category/subcategory picker, autocomplete with an
/// inline "create new" affordance replacing the dropdown. Typing a name that
/// matches an existing row (case-insensitive) lets it be picked from the
/// suggestion list, setting the id exactly as the dropdown did; typing a
/// name that matches nothing appends a distinct create-new entry, which
/// calls [onCreate] and then resolves the field to the row once it appears
/// in the next [options] the parent passes down (matched by name — `add()`
/// hands back no id, same read/write asymmetry every write in this app
/// already has).
///
/// Private, per-file widget (same shape as `_FigureCard`/`_NavIconButton`):
/// not a class either class diagram tracks. Duplicated from
/// `record_transaction_screen.dart` rather than shared — plan D1 leaves that
/// choice to the coder, and the two screens' narrowing rules differ (D3).
class _CategoryAutocompleteField extends StatefulWidget {
  const _CategoryAutocompleteField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
    required this.createLabel,
  });

  final String label;
  final List<({int id, String name})> options;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  /// Null when creating is unavailable — a subcategory field with no parent
  /// category selected yet (D3: the affordance is absent, not refused).
  final void Function(String name)? onCreate;
  final String Function(String name) createLabel;

  @override
  State<_CategoryAutocompleteField> createState() =>
      _CategoryAutocompleteFieldState();
}

class _CategoryAutocompleteFieldState
    extends State<_CategoryAutocompleteField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  /// Set right after firing [onCreate]; cleared once an option by this name
  /// shows up in a later [_CategoryAutocompleteField.options] and the field
  /// resolves to its id.
  String? _pendingCreateName;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _labelFor(widget.selectedId));
    _focusNode = FocusNode();
  }

  String _labelFor(int? id) {
    if (id == null) return '';
    for (final option in widget.options) {
      if (option.id == id) return option.name;
    }
    return '';
  }

  @override
  void didUpdateWidget(covariant _CategoryAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) {
      _controller.text = _labelFor(widget.selectedId);
    }
    final pending = _pendingCreateName;
    if (pending != null) {
      for (final option in widget.options) {
        if (option.name.toLowerCase() == pending.toLowerCase()) {
          _pendingCreateName = null;
          _controller.text = option.name;
          // Deferred: this runs from didUpdateWidget, still inside a build
          // phase — calling the setState-bound callback synchronously here
          // is exactly the "setState during build" framework forbids.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onSelected(option.id);
            }
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<({int? id, String name, bool isCreateNew})>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = value.text.trim();
        final lowerQuery = query.toLowerCase();
        final matches = <({int? id, String name, bool isCreateNew})>[
          for (final option in widget.options)
            if (option.name.toLowerCase().contains(lowerQuery))
              (id: option.id, name: option.name, isCreateNew: false),
        ];
        final onCreate = widget.onCreate;
        final exists = widget.options.any(
          (option) => option.name.toLowerCase() == lowerQuery,
        );
        if (query.isNotEmpty && !exists && onCreate != null) {
          matches.add((id: null, name: query, isCreateNew: true));
        }
        return matches;
      },
      displayStringForOption: (choice) => choice.name,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: widget.label),
          onChanged: (text) {
            if (text.isEmpty) {
              widget.onSelected(null);
            }
          },
        );
      },
      onSelected: (choice) {
        if (choice.isCreateNew) {
          _pendingCreateName = choice.name;
          _controller.text = choice.name;
          widget.onCreate!(choice.name);
        } else {
          _controller.text = choice.name;
          widget.onSelected(choice.id);
        }
        // Closes the suggestion overlay on selection, same as a dropdown's
        // menu closing once an item is picked. Deferred a frame: unfocusing
        // synchronously here races the overlay's own removal when selection
        // also triggers a rebuild (the create-new path always does).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.unfocus();
          }
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      leading: option.isCreateNew
                          ? const Icon(Icons.add)
                          : null,
                      title: Text(
                        option.isCreateNew
                            ? widget.createLabel(option.name)
                            : option.name,
                      ),
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
