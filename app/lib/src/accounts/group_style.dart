import 'package:flutter/material.dart';

import 'accounts_table.dart';

/// One color per [AccountGroup] (FEAT09 D1), reused everywhere a group
/// needs a visual identity — the `BalanceSheetScreen` figure cards (D2) and
/// `AccountFormScreen`'s group picker description (D3).
///
/// `RECEIVABLE` uses the same fixed green literal `TransactionListScreen`
/// already ships for income, rather than `colorScheme.tertiary`, so the two
/// screens agree on what "money owed to me" looks like.
Color accountGroupColor(BuildContext context, AccountGroup group) {
  final colorScheme = Theme.of(context).colorScheme;
  final brightness = Theme.of(context).brightness;
  return switch (group) {
    AccountGroup.HOLDING => colorScheme.primary,
    AccountGroup.RECEIVABLE =>
      brightness == Brightness.dark
          ? Colors.green.shade300
          : Colors.green.shade700,
    AccountGroup.PAYABLE => colorScheme.error,
  };
}

/// One icon per [AccountGroup] (FEAT09 D1) — paired with [accountGroupColor]
/// everywhere a group is shown, never used alone.
IconData accountGroupIcon(AccountGroup group) => switch (group) {
  AccountGroup.HOLDING => Icons.account_balance_wallet,
  AccountGroup.RECEIVABLE => Icons.call_received,
  AccountGroup.PAYABLE => Icons.call_made,
};
