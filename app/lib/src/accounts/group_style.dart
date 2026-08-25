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
    // FEAT11 D3: PERSON has no fixed direction (it can owe or be owed
    // depending on the sign of its balance), so it gets no fixed
    // directional color — deliberately distinct from RECEIVABLE's green
    // and PAYABLE's colorScheme.error.
    AccountGroup.PERSON => colorScheme.tertiary,
  };
}

/// Sign-aware row/header color for `AccountsScreen` only (FEAT18 D3) — a
/// separate, narrower-scoped function from [accountGroupColor], which stays
/// unchanged and keeps every other caller (`BalanceSheetScreen`'s figure
/// cards, `AccountFormScreen`'s group picker description). `HOLDING` is the
/// theme-neutral "black" the owner asked for (`colorScheme.onSurface`), not
/// `accountGroupColor`'s `colorScheme.primary`. `RECEIVABLE`/`PAYABLE` reuse
/// `accountGroupColor`'s existing green/red exactly. `PERSON` has no fixed
/// color here — it borrows RECEIVABLE's green when [balance] is non-negative
/// (owed to me) and PAYABLE's red when negative (owed by me), matching
/// `AccountDao.watchPosition()`'s own sign-based bucketing made visible as
/// color.
Color accountRowColor(BuildContext context, AccountGroup group, int balance) {
  return switch (group) {
    AccountGroup.HOLDING => Theme.of(context).colorScheme.onSurface,
    AccountGroup.RECEIVABLE => accountGroupColor(
      context,
      AccountGroup.RECEIVABLE,
    ),
    AccountGroup.PAYABLE => accountGroupColor(context, AccountGroup.PAYABLE),
    AccountGroup.PERSON =>
      balance >= 0
          ? accountGroupColor(context, AccountGroup.RECEIVABLE)
          : accountGroupColor(context, AccountGroup.PAYABLE),
  };
}

/// One icon per [AccountGroup] (FEAT09 D1) — paired with [accountGroupColor]
/// everywhere a group is shown, never used alone.
IconData accountGroupIcon(AccountGroup group) => switch (group) {
  AccountGroup.HOLDING => Icons.account_balance_wallet,
  AccountGroup.RECEIVABLE => Icons.call_received,
  AccountGroup.PAYABLE => Icons.call_made,
  // FEAT11 D3: sync_alt (bidirectional arrows) reads as "can flip," unlike
  // RECEIVABLE's call_received/PAYABLE's call_made, which are
  // one-directional by design.
  AccountGroup.PERSON => Icons.sync_alt,
};
