import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../accounts/accounts_table.dart';
import '../database/app_database.dart';
import 'transactions_providers.dart';

/// Which recording flow the form is in — one entry per writable kind, named
/// for the notifier method the flow's save calls (messages 3 on
/// `seq-uc04`..`seq-uc08`). Pure presentation: the artifacts fix that there
/// is **one** form (plan D1), not how its kind switch looks (plan, "Open
/// questions"). Not a stored enum — `TransactionKind` is; this only picks
/// which of its six writable values the save uses.
enum _Flow { expense, income, transfer, lend, borrow, repay }

/// Finder target for the kind switch in widget tests.
const Key _kindFieldKey = Key('kind-dropdown');

/// The person/debt pool for the lend/borrow/repay pickers: the accounts list
/// narrowed to `RECEIVABLE`/`PAYABLE` groups — a person and a debt *are*
/// accounts (`docs/enums.md`: *"the owner re-confirmed that a debt is an
/// account"*), so this is not a fourth source (plan D7). Exposed for the
/// D7 test that pins the narrowing.
@visibleForTesting
List<Account> personDebtChoices(List<Account> accounts) {
  return accounts
      .where(
        (account) =>
            account.group == AccountGroup.RECEIVABLE ||
            account.group == AccountGroup.PAYABLE,
      )
      .toList();
}

/// `RecordTransactionScreen` — UC-04 to UC-08: one form for all six
/// writable kinds (`class-transactions.drawio`, plan D1).
///
/// Amount first (FR-6), tags optional on the flows whose diagrams draw them
/// (expense/income only — FR-10; seq-uc06 draws no tag fragment), note
/// optional everywhere (`decisions.md` 2026-08-21). Blank optional fields
/// store null, keeping "wrote nothing" and "wrote empty" one fact (plan D8).
///
/// **Save is always enabled and nothing is refused** (plan D9, NFR-4's zero
/// refusals): no validation gate blocks zero, negative, over-budget,
/// future-dated or same-account entries — each writes exactly what the form
/// holds. The write returns nothing to this screen; what the owner sees
/// afterwards arrives as stream re-emissions downstream (`riverpod.md`, the
/// read/write asymmetry).
///
/// Loading and empty picker states render placeholders, never errors; an
/// empty pool leaves the side null rather than disabling anything.
class RecordTransactionScreen extends ConsumerStatefulWidget {
  const RecordTransactionScreen({super.key});

  @override
  ConsumerState<RecordTransactionScreen> createState() =>
      _RecordTransactionScreenState();
}

class _RecordTransactionScreenState
    extends ConsumerState<RecordTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  /// Pre-filled from today (plan step 5); changeable, never gated.
  DateTime _date = DateTime.now();

  _Flow _flow = _Flow.expense;

  // Per-role selections, kept apart so switching flows never leaks one
  // flow's side into another's. Each falls back to its pool's first row at
  // read time, so with any account present a save always produces sides.
  int? _payingAccountId;
  int? _receivingAccountId;
  int? _sourceAccountId;
  int? _destinationAccountId;
  int? _personDebtId;
  int? _walletId;

  int? _categoryId;
  int? _subcategoryId;
  int? _budgetGroupId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _firstIdOf(List<Account> pool) =>
      pool.isEmpty ? null : pool.first.accountId;

  /// Selected-or-first fallback: preselection without a refusal path (plan
  /// D9) — with an empty pool this stays null and the save proceeds with a
  /// null side (plan's flagged open-question handling, NFR-4).
  int? _effective(int? selected, List<Account> pool) =>
      selected ?? _firstIdOf(pool);

  void _save() {
    // F7 precedent (`pm/findings.md`): an empty or unparseable amount
    // proceeds as 0 rather than refusing — NFR-4.
    final amount = int.tryParse(_amountController.text) ?? 0;

    // D8: blank means null; a filled note round-trips verbatim.
    final noteText = _noteController.text;
    final note = noteText.isEmpty ? null : noteText;

    final accounts = ref.read(accountPickerProvider).value ?? const <Account>[];
    final notifier = ref.read(transactionsProvider.notifier);

    switch (_flow) {
      case _Flow.expense:
        unawaited(
          notifier.recordExpense(
            amount: amount,
            fromAccountId: _effective(_payingAccountId, accounts),
            categoryId: _categoryId,
            subcategoryId: _subcategoryId,
            budgetGroupId: _budgetGroupId,
            note: note,
            date: _date,
          ),
        );
      case _Flow.income:
        unawaited(
          notifier.recordIncome(
            amount: amount,
            toAccountId: _effective(_receivingAccountId, accounts),
            categoryId: _categoryId,
            subcategoryId: _subcategoryId,
            budgetGroupId: _budgetGroupId,
            note: note,
            date: _date,
          ),
        );
      case _Flow.transfer:
        unawaited(
          notifier.transfer(
            amount: amount,
            fromAccountId: _effective(_sourceAccountId, accounts),
            toAccountId: _effective(_destinationAccountId, accounts),
            note: note,
            date: _date,
          ),
        );
      case _Flow.lend:
        unawaited(
          notifier.lend(
            amount: amount,
            personAccountId: _effective(
              _personDebtId,
              personDebtChoices(accounts),
            ),
            fromAccountId: _effective(_walletId, accounts),
            note: note,
            date: _date,
          ),
        );
      case _Flow.borrow:
        unawaited(
          notifier.borrow(
            amount: amount,
            debtAccountId: _effective(
              _personDebtId,
              personDebtChoices(accounts),
            ),
            toAccountId: _effective(_walletId, accounts),
            note: note,
            date: _date,
          ),
        );
      case _Flow.repay:
        // Both `alt` arms of `seq-uc08-repayment.drawio`, resolved by the
        // picked debt's group (group-dependent mapping, `pm/active.json`):
        // off a RECEIVABLE account the money enters the wallet (arm 1);
        // into a PAYABLE account it leaves it (arm 2).
        final debts = personDebtChoices(accounts);
        final debtId = _effective(_personDebtId, debts);
        final walletId = _effective(_walletId, accounts);
        Account? debt;
        for (final account in accounts) {
          if (account.accountId == debtId) {
            debt = account;
            break;
          }
        }
        final debtIsSource = debt?.group == AccountGroup.RECEIVABLE;
        unawaited(
          notifier.repay(
            amount: amount,
            fromAccountId: debtIsSource ? debtId : walletId,
            toAccountId: debtIsSource ? walletId : debtId,
            note: note,
            date: _date,
          ),
        );
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

    return Scaffold(
      appBar: AppBar(title: Text(loc.recordTransactionTitle)),
      floatingActionButton: FloatingActionButton.extended(
        // Explicit tag (FEAT02 plan D1): `AppShell`'s `IndexedStack` keeps
        // every tab mounted at once, so this FAB and Balance Sheet's FAB
        // coexist in the same subtree — the implicit default tag they'd
        // otherwise share collides (Flutter's Hero identity requirement),
        // not a business-logic change.
        heroTag: 'record-transaction-fab',
        tooltip: loc.saveButton,
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: Text(loc.saveButton),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<_Flow>(
              key: _kindFieldKey,
              initialValue: _flow,
              decoration: InputDecoration(labelText: loc.kindFieldLabel),
              items: [
                for (final flow in _Flow.values)
                  DropdownMenuItem<_Flow>(
                    value: flow,
                    child: Text(switch (flow) {
                      _Flow.expense => loc.kindExpense,
                      _Flow.income => loc.kindIncome,
                      _Flow.transfer => loc.kindTransfer,
                      _Flow.lend => loc.kindLend,
                      _Flow.borrow => loc.kindBorrow,
                      _Flow.repay => loc.kindRepay,
                    }),
                  ),
              ],
              onChanged: (chosen) {
                if (chosen != null) {
                  setState(() => _flow = chosen);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
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
            ..._sidePickers(loc, accounts),
            ..._tagPickers(loc, tree, groups),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: loc.noteOptionalLabel),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sidePickers(AppLocalizations loc, List<Account> accounts) {
    switch (_flow) {
      case _Flow.expense:
        return [
          _accountDropdown(
            loc,
            label: loc.payingAccountLabel,
            pool: accounts,
            selectedId: _effective(_payingAccountId, accounts),
            onChanged: (id) => setState(() => _payingAccountId = id),
          ),
        ];
      case _Flow.income:
        return [
          _accountDropdown(
            loc,
            label: loc.receivingAccountLabel,
            pool: accounts,
            selectedId: _effective(_receivingAccountId, accounts),
            onChanged: (id) => setState(() => _receivingAccountId = id),
          ),
        ];
      case _Flow.transfer:
        return [
          _accountDropdown(
            loc,
            label: loc.sourceAccountLabel,
            pool: accounts,
            selectedId: _effective(_sourceAccountId, accounts),
            onChanged: (id) => setState(() => _sourceAccountId = id),
          ),
          _accountDropdown(
            loc,
            label: loc.destinationAccountLabel,
            pool: accounts,
            selectedId: _effective(_destinationAccountId, accounts),
            onChanged: (id) => setState(() => _destinationAccountId = id),
          ),
        ];
      case _Flow.lend:
      case _Flow.borrow:
      case _Flow.repay:
        return [
          _accountDropdown(
            loc,
            label: _flow == _Flow.repay
                ? loc.debtPersonLabel
                : loc.personDebtLabel,
            pool: personDebtChoices(accounts),
            selectedId: _effective(_personDebtId, personDebtChoices(accounts)),
            onChanged: (id) => setState(() => _personDebtId = id),
          ),
          _accountDropdown(
            loc,
            label: loc.ownAccountLabel,
            pool: accounts,
            selectedId: _effective(_walletId, accounts),
            onChanged: (id) => setState(() => _walletId = id),
          ),
        ];
    }
  }

  /// The three optional tags — drawn only on the expense/income flows (the
  /// `opt` fragment on `seq-uc04`/`seq-uc05`; seq-uc06 draws none, plan D8).
  /// Every dropdown offers the blank choice, stored as null.
  List<Widget> _tagPickers(
    AppLocalizations loc,
    Map<Category, List<Subcategory>> tree,
    List<BudgetGroup> groups,
  ) {
    if (_flow != _Flow.expense && _flow != _Flow.income) {
      return [const SizedBox(height: 16)];
    }

    final categories = tree.keys.toList();
    Category? selectedCategory;
    for (final category in categories) {
      if (category.categoryId == _categoryId) {
        selectedCategory = category;
        break;
      }
    }
    final subcategories = selectedCategory == null
        ? const <Subcategory>[]
        : tree[selectedCategory] ?? const <Subcategory>[];

    return [
      DropdownButtonFormField<int?>(
        initialValue: _categoryId,
        hint: Text(loc.noneHint),
        decoration: InputDecoration(labelText: loc.categoryOptionalLabel),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(loc.noneHint)),
          for (final category in categories)
            DropdownMenuItem<int?>(
              value: category.categoryId,
              child: Text(category.name),
            ),
        ],
        onChanged: (id) => setState(() {
          _categoryId = id;
          _subcategoryId = null;
        }),
      ),
      DropdownButtonFormField<int?>(
        initialValue: _subcategoryId,
        hint: Text(loc.noneHint),
        decoration: InputDecoration(labelText: loc.subcategoryOptionalLabel),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(loc.noneHint)),
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
        hint: Text(loc.noneHint),
        decoration: InputDecoration(labelText: loc.budgetGroupOptionalLabel),
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
      const SizedBox(height: 16),
    ];
  }

  Widget _accountDropdown(
    AppLocalizations loc, {
    required String label,
    required List<Account> pool,
    required int? selectedId,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      hint: Text(pool.isEmpty ? loc.noAccountsYetHint : loc.noneHint),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final account in pool)
          DropdownMenuItem<int?>(
            value: account.accountId,
            child: Text('${account.name} (${account.group.name})'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
