import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_table.dart';
import 'accounts_providers.dart';

/// `AccountFormScreen` — UC-02: name an account, choose which of FR-1's
/// three groups it belongs to, and enter what is in it today (FR-3, FR-4,
/// FR-5).
///
/// One form serves all three groups (`plan.md` D5) — a credit card or a
/// person who owes money is set up exactly like a wallet; only the enum
/// value differs. The opening amount is stored exactly as entered, signed
/// (D6, FR-4 — "it just holds a negative amount"): the field accepts a
/// leading minus sign and the app applies no group-based negation. Amounts
/// are int minor units of `Settings.currency`, never a double.
///
/// **Nothing on this screen is disabled and nothing is refused** (D7,
/// NFR-4's zero-refusals fit criterion): the save control is enabled even
/// with every field empty — an empty amount saves as 0 and an unparseable
/// one follows UC-11's shipped precedent (`int.tryParse(...) ?? 0`,
/// `pm/findings.md` F7) — and all three `AccountGroup` values are selectable
/// at all times.
///
/// Firing the save never renders what `addAccount` returns; nothing comes
/// back on this screen (`plan.md` D9 — messages 7 and 8 are UC-01's read
/// path, not yet built).
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _openingAmountController;

  /// Message 1 offers all three groups from the start; HOLDING is the
  /// initial selection, changeable at any time (D7).
  AccountGroup _group = AccountGroup.HOLDING;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _openingAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingAmountController.dispose();
    super.dispose();
  }

  void _save() {
    // D7 / F7: an empty or unparseable amount proceeds as 0 rather than
    // refusing — the same shape UC-11's screen ships.
    final openingAmount = int.tryParse(_openingAmountController.text) ?? 0;
    ref
        .read(accountsProvider.notifier)
        .addAccount(
          name: _nameController.text,
          group: _group,
          openingAmount: openingAmount,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New account')),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Save account',
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
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
        ),
      ),
    );
  }
}
