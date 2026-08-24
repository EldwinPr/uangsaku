import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../accounts/accounts_table.dart';

/// `HelpScreen` — FEAT10 D1: a static, in-app guide, reached from every tab
/// (`tab_app_bar_actions.dart`). `StatelessWidget`, nothing here comes from
/// the database — a `ConsumerWidget` would claim a read dependency this
/// screen doesn't have (`class-settings.drawio`: no provider edges).
///
/// Four sections, one per concept the app asks the owner to understand:
/// accounts (the three `AccountGroup`s), recording money (the six writable
/// `TransactionKind`s plus `adjustment`), budgets and debts. The accounts
/// and recording sections reuse `FEAT09`'s picker-description ARB keys
/// verbatim so the in-app hint and this screen never drift out of sync —
/// budgets and debts have no `FEAT09` counterpart and get new prose.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.helpScreenTitle)),
      body: ListView(
        children: [
          ExpansionTile(
            key: const ValueKey('help-section-accounts'),
            title: Text(loc.helpSectionAccounts),
            children: [
              for (final group in AccountGroup.values)
                _HelpItem(
                  title: group.name,
                  body: switch (group) {
                    AccountGroup.HOLDING => loc.accountGroupDescriptionHolding,
                    AccountGroup.RECEIVABLE =>
                      loc.accountGroupDescriptionReceivable,
                    AccountGroup.PAYABLE => loc.accountGroupDescriptionPayable,
                  },
                ),
            ],
          ),
          ExpansionTile(
            key: const ValueKey('help-section-recording'),
            title: Text(loc.helpSectionRecording),
            children: [
              _HelpItem(
                title: loc.kindExpense,
                body: loc.kindDescriptionExpense,
              ),
              _HelpItem(title: loc.kindIncome, body: loc.kindDescriptionIncome),
              _HelpItem(
                title: loc.kindTransfer,
                body: loc.kindDescriptionTransfer,
              ),
              _HelpItem(title: loc.kindLend, body: loc.kindDescriptionLend),
              _HelpItem(title: loc.kindBorrow, body: loc.kindDescriptionBorrow),
              _HelpItem(
                title: loc.kindRepayment,
                body: loc.kindDescriptionRepay,
              ),
              _HelpItem(
                title: loc.kindAdjustment,
                body: loc.adjustmentDescription,
              ),
            ],
          ),
          ExpansionTile(
            key: const ValueKey('help-section-budgets'),
            title: Text(loc.helpSectionBudgets),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(loc.helpBudgetsDescription),
              ),
            ],
          ),
          ExpansionTile(
            key: const ValueKey('help-section-debts'),
            title: Text(loc.helpSectionDebts),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(loc.helpDebtsDescription),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One entry inside a section — a title (a group or kind's own name) and its
/// one-sentence description, reused verbatim from `FEAT09`'s ARB keys.
class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
