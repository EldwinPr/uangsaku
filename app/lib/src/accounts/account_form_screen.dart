import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../accounts/accounts_table.dart';
import 'accounts_providers.dart';
import 'group_style.dart';

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
/// is F8's resolution — `BalanceSheetScreen`'s row tap opens edit mode
/// (FEAT02 plan D3); this file draws no navigation of its own, only the flow
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
/// **Nothing on this screen is disabled, and nothing is refused except one
/// case** (D7, NFR-4's zero-refusals fit criterion, with the sole counted
/// exception FEAT08 D3/D4 adds): every save and the delete control are
/// enabled even with every field empty — an empty amount saves as 0 and an
/// unparseable one follows UC-11's shipped precedent (`int.tryParse(...) ??
/// 0`, `pm/findings.md` F7, now this flow's own instance of that pattern);
/// an empty name is legal and saves as `''` (UC02B plan D5); all three
/// `AccountGroup` values are selectable at all times; delete has no
/// confirmation dialog (UC02B plan D2/D5 — the diagram draws none). The one
/// exception: a name that case-insensitively collides with another
/// non-deleted account's name hard-blocks the save (FEAT08 D3) — the owner's
/// own 2026-08-24 answer, "Hard block for real," replacing FEAT06 D3's
/// warn-and-proceed.
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

  /// FEAT08 D3: a real gate now, checked against the currently loaded
  /// [accountBalancesProvider] list (already shipped, already filters
  /// `WHERE NOT deleted`; no new DAO method or query), case-insensitive,
  /// excluding the account's own id when editing. Adjust mode never calls
  /// this — that flow never touches `name`.
  bool _nameCollides(String name) {
    final rows = ref.read(accountBalancesProvider).value ?? const [];
    final lowerName = name.toLowerCase();
    for (final row in rows) {
      if (row.account.accountId == widget.accountId) continue;
      if (row.account.name.toLowerCase() == lowerName) return true;
    }
    return false;
  }

  /// FEAT08 D3: single-button dialog for a blocked save, replacing FEAT06's
  /// acknowledge-and-proceed notice. The name collision is a real refusal
  /// now — this dialog only informs; it does not proceed on dismissal, the
  /// caller already returned before showing it.
  Future<void> _showBlockedNotice() {
    final loc = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.duplicateAccountNameBlockedTitle),
        content: Text(loc.duplicateAccountNameBlockedContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.okButton),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    // D7 / F7: an empty or unparseable amount proceeds as 0 rather than
    // refusing — the same shape UC-11's screen ships.
    if (_isAdjustFlow) {
      final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;
      unawaited(
        ref
            .read(accountsProvider.notifier)
            .adjustAccount(
              accountId: widget.accountId!,
              targetAmount: targetAmount,
            ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (_isEditFlow) {
      // UC02B D5: an empty name is legal and saves as ''.
      final name = _nameController.text;
      // FEAT08 D3: a colliding name is a real refusal — the sole exception
      // to NFR-4's zero-refusals rule (docs/fr-nfr.md, decisions.md). No
      // write, no pop; the screen stays open with the name still typed in.
      if (_nameCollides(name)) {
        await _showBlockedNotice();
        return;
      }
      unawaited(
        ref
            .read(accountsProvider.notifier)
            .editAccount(
              accountId: widget.accountId!,
              name: name,
              group: _group,
            ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    final openingAmount = int.tryParse(_openingAmountController.text) ?? 0;
    final name = _nameController.text;
    // FEAT08 D3: same hard block on create.
    if (_nameCollides(name)) {
      await _showBlockedNotice();
      return;
    }
    unawaited(
      ref
          .read(accountsProvider.notifier)
          .addAccount(name: name, group: _group, openingAmount: openingAmount),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
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
    final loc = AppLocalizations.of(context)!;
    // FEAT06 D3: keeps accountBalancesProvider subscribed on every mode
    // (adjust/edit flows already watch it below for message 7; create mode
    // otherwise never would) so `_save`'s uniqueness check reads a live
    // list rather than an unstarted stream's empty default.
    ref.watch(accountBalancesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_title(loc))),
      floatingActionButton: FloatingActionButton.extended(
        // Explicit tag (FEAT02 plan D1): reached with `AppShell`'s
        // `IndexedStack` still mounted underneath, whose Accounts tab
        // has its own FAB — the shared default tag would otherwise collide
        // (Flutter's Hero identity requirement), not a business-logic
        // change.
        heroTag: 'account-form-fab',
        tooltip: _isAdjustFlow
            ? loc.saveCorrectionTooltip
            : (_isEditFlow ? loc.saveChangesTooltip : loc.saveAccountTooltip),
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text(loc.saveButton),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isAdjustFlow
            ? _buildAdjustFlow(loc)
            : (_isEditFlow ? _buildEditFlow(loc) : _buildNewAccountFlow(loc)),
      ),
    );
  }

  /// FEAT09 D3/D5: plain, factual sentence for the currently selected
  /// group, tinted with [accountGroupColor] so the color system and the
  /// wording reinforce each other.
  String _groupDescription(AppLocalizations loc, AccountGroup group) =>
      switch (group) {
        AccountGroup.HOLDING => loc.accountGroupDescriptionHolding,
        AccountGroup.RECEIVABLE => loc.accountGroupDescriptionReceivable,
        AccountGroup.PAYABLE => loc.accountGroupDescriptionPayable,
        AccountGroup.PERSON => loc.accountGroupDescriptionPerson,
      };

  Widget _groupDescriptionText(AppLocalizations loc) {
    return Text(
      _groupDescription(loc, _group),
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: accountGroupColor(context, _group)),
    );
  }

  String _title(AppLocalizations loc) {
    if (_isAdjustFlow) return loc.titleCorrectAccount;
    if (_isEditFlow) return loc.titleEditAccount;
    return loc.titleNewAccount;
  }

  Widget _buildNewAccountFlow(AppLocalizations loc) {
    return ListView(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: loc.nameLabel,
            hintText: loc.nameHint,
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
        const SizedBox(height: 8),
        _groupDescriptionText(loc),
        const SizedBox(height: 16),
        TextField(
          controller: _openingAmountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: loc.openingAmountLabel,
            hintText: loc.openingAmountHint,
          ),
        ),
      ],
    );
  }

  /// Messages 1, 7, 8: designate an existing account (via [widget.accountId]),
  /// show its current derived amount and accept the corrected target — save
  /// always enabled (D6, D7). No entry point in `AppShell` reaches this mode
  /// (FEAT02 plan D3, out of scope) — it is exercised only by tests.
  Widget _buildAdjustFlow(AppLocalizations loc) {
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
              ? loc.currentAmountUnknown
              : loc.currentAmountKnown(currentAmount),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _targetAmountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: loc.targetAmountLabel,
            hintText: loc.targetAmountHint,
          ),
        ),
      ],
    );
  }

  /// Messages 1, 7, 8 and the `alt` box's two arms on
  /// `seq-uc02b-edit-account.drawio`: rename field, group selector and a
  /// delete control, all always enabled (D5) — `opening_amount` never
  /// appears here (D3, correcting it stays adjust mode's).
  Widget _buildEditFlow(AppLocalizations loc) {
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
          decoration: InputDecoration(
            labelText: loc.nameLabel,
            hintText: loc.nameHint,
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
        const SizedBox(height: 8),
        _groupDescriptionText(loc),
        const SizedBox(height: 16),
        // Message 14: delete, always enabled, no confirmation dialog
        // (D2/D5 — the diagram draws none, and NFR-4 forbids inventing one).
        OutlinedButton.icon(
          onPressed: _delete,
          icon: const Icon(Icons.delete),
          label: Text(loc.deleteAccountButton),
        ),
      ],
    );
  }
}
