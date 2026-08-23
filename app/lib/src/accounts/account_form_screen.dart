import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_table.dart';
import 'accounts_providers.dart';

/// Which of this screen's three flows is showing — UC-02's create, UC-03's
/// adjust, or UC02B's edit/delete (`class-accounts.drawio`: *UC-02, UC-02B,
/// UC-03*). A widget-local discriminator, not a stored/diagram enum — the
/// sequence diagrams fix the messages each flow sends, not this parameter's
/// shape (UC02B plan D6).
enum AccountFormMode { create, adjust, edit }

/// `AccountFormScreen` — UC-02: name an account, choose which of FR-1's
/// three groups it belongs to, and enter what is in it today (FR-3, FR-4,
/// FR-5); UC-03: designate an existing account and correct what it holds;
/// UC02B: rename it, change its group, or delete it outright
/// (`class-accounts.drawio`: *UC-02, UC-02B, UC-03*).
///
/// One form serves all three flows, chosen by [mode] (UC-03 plan D6, UC02B
/// plan D6 — the identical precedent one issue later): [AccountFormMode.create]
/// takes no [accountId]; [AccountFormMode.adjust] and [AccountFormMode.edit]
/// both take one but send different messages — adjust shows the current
/// derived amount (message 7, read through [accountBalancesProvider] once it
/// has emitted) alongside a target-amount field and calls `adjustAccount`;
/// edit shows a rename field and group selector alongside a delete control
/// and calls `editAccount`/`deleteAccount`. Reaching this screen with an id
/// is F8's standing question — this file draws no navigation, only the flow
/// the sequence diagrams show.
///
/// One form serves all three groups (`plan.md` D5) — a credit card or a
/// person who owes money is set up exactly like a wallet; only the enum
/// value differs. The opening amount is stored exactly as entered, signed
/// (D6, FR-4 — "it just holds a negative amount"): the field accepts a
/// leading minus sign and the app applies no group-based negation. Amounts
/// are int minor units of `Settings.currency`, never a double — the adjust
/// flow's target amount follows the same rule; the DAO derives the signed
/// `diff` (UC-03 plan D3). `opening_amount` never appears in edit mode
/// (UC02B plan D3) — correcting it stays adjust mode's job.
///
/// **Nothing on this screen is disabled and nothing is refused** (D7,
/// NFR-4's zero-refusals fit criterion): every save and the delete control
/// are enabled even with every field empty — an empty amount saves as 0 and
/// an unparseable one follows UC-11's shipped precedent (`int.tryParse(...)
/// ?? 0`, `pm/findings.md` F7, now this flow's own instance of that
/// pattern); an empty name is legal and saves as `''` (UC02B plan D5); all
/// three `AccountGroup` values are selectable at all times; delete has no
/// confirmation dialog (UC02B plan D2/D5 — the diagram draws none).
///
/// Firing a write never renders what it returns; nothing comes back on this
/// screen (`riverpod.md`, the read/write asymmetry) — every result arrives
/// on the read path instead.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({
    super.key,
    this.mode = AccountFormMode.create,
    this.accountId,
  }) : assert(
         mode == AccountFormMode.create || accountId != null,
         'adjust and edit modes require an accountId',
       );

  /// Which flow this screen shows (UC02B plan D6).
  final AccountFormMode mode;

  /// The account being adjusted or edited. Null only in [AccountFormMode.create].
  final int? accountId;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _openingAmountController;
  late final TextEditingController _targetAmountController;

  /// Message 1 offers all three groups from the start; HOLDING is the
  /// initial selection, changeable at any time (D7).
  AccountGroup _group = AccountGroup.HOLDING;

  bool get _isAdjustFlow => widget.mode == AccountFormMode.adjust;
  bool get _isEditFlow => widget.mode == AccountFormMode.edit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _openingAmountController = TextEditingController();
    _targetAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingAmountController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _save() {
    // D7 / F7: an empty or unparseable amount proceeds as 0 rather than
    // refusing — the same shape UC-11's screen ships.
    if (_isAdjustFlow) {
      final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;
      ref
          .read(accountsProvider.notifier)
          .adjustAccount(
            accountId: widget.accountId!,
            targetAmount: targetAmount,
          );
      return;
    }
    if (_isEditFlow) {
      // UC02B D5: an empty name is legal and saves as ''.
      ref
          .read(accountsProvider.notifier)
          .editAccount(
            accountId: widget.accountId!,
            name: _nameController.text,
            group: _group,
          );
      return;
    }
    final openingAmount = int.tryParse(_openingAmountController.text) ?? 0;
    ref
        .read(accountsProvider.notifier)
        .addAccount(
          name: _nameController.text,
          group: _group,
          openingAmount: openingAmount,
        );
  }

  /// Message 14 on `seq-uc02b-edit-account.drawio`: `deleteAccount`. Always
  /// enabled, no confirmation dialog — NFR-4, UC02B plan D2/D5.
  void _delete() {
    ref
        .read(accountsProvider.notifier)
        .deleteAccount(accountId: widget.accountId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: _isAdjustFlow
            ? 'Save correction'
            : (_isEditFlow ? 'Save changes' : 'Save account'),
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isAdjustFlow
            ? _buildAdjustFlow()
            : (_isEditFlow ? _buildEditFlow() : _buildNewAccountFlow()),
      ),
    );
  }

  String get _title {
    if (_isAdjustFlow) return 'Correct account';
    if (_isEditFlow) return 'Edit account';
    return 'New account';
  }

  Widget _buildNewAccountFlow() {
    return ListView(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Wallet, credit card, person…',
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<AccountGroup>(
          segments: [
            for (final value in AccountGroup.values)
              ButtonSegment<AccountGroup>(
                value: value,
                label: Text(value.name),
                // No `enabled:` anywhere — all three groups stay
                // selectable at all times (D7, NFR-4).
              ),
          ],
          selected: {_group},
          onSelectionChanged: (chosen) =>
              setState(() => _group = chosen.single),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _openingAmountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Opening amount',
            hintText: 'What is in it today (minus allowed)',
          ),
        ),
      ],
    );
  }

  /// Messages 1, 7, 8: designate an existing account (via [widget.accountId],
  /// F8's reachability question), show its current derived amount and accept
  /// the corrected target — save always enabled (D6, D7).
  Widget _buildAdjustFlow() {
    // Message 7: the current derived amount, once accountBalancesProvider
    // has emitted (UC-01, shipped). No read blocks the save — the flow
    // degrades gracefully to showing nothing yet, exactly as D3 requires
    // nothing above the DAO to depend on this value.
    final balances = ref.watch(accountBalancesProvider);
    final currentAmount = balances.maybeWhen(
      data: (rows) {
        for (final row in rows) {
          if (row.account.accountId == widget.accountId) return row.balance;
        }
        return null;
      },
      orElse: () => null,
    );

    return ListView(
      children: [
        Text(
          currentAmount == null
              ? 'Current amount: —'
              : 'Current amount: $currentAmount',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _targetAmountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'What it should actually be',
            hintText: 'Target amount (minus allowed)',
          ),
        ),
      ],
    );
  }

  /// Messages 1, 7, 8 and the `alt` box's two arms on
  /// `seq-uc02b-edit-account.drawio`: rename field, group selector and a
  /// delete control, all always enabled (D5) — `opening_amount` never
  /// appears here (D3, correcting it stays adjust mode's).
  Widget _buildEditFlow() {
    // Message 7: the current name/group, once accountBalancesProvider has
    // emitted — the same graceful-degradation shape _buildAdjustFlow ships;
    // no read blocks either control.
    final balances = ref.watch(accountBalancesProvider);
    balances.whenData((rows) {
      for (final row in rows) {
        if (row.account.accountId == widget.accountId &&
            _nameController.text.isEmpty) {
          _nameController.text = row.account.name;
          _group = row.account.group;
        }
      }
    });

    return ListView(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Wallet, credit card, person…',
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<AccountGroup>(
          segments: [
            for (final value in AccountGroup.values)
              ButtonSegment<AccountGroup>(
                value: value,
                label: Text(value.name),
                // No `enabled:` anywhere — all three groups stay
                // selectable at all times (D5, NFR-4).
              ),
          ],
          selected: {_group},
          onSelectionChanged: (chosen) =>
              setState(() => _group = chosen.single),
        ),
        const SizedBox(height: 16),
        // Message 14: delete, always enabled, no confirmation dialog
        // (D2/D5 — the diagram draws none, and NFR-4 forbids inventing one).
        OutlinedButton.icon(
          onPressed: _delete,
          icon: const Icon(Icons.delete),
          label: const Text('Delete account'),
        ),
      ],
    );
  }
}
