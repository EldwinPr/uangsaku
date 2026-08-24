import 'package:flutter/material.dart';

import 'transactions_table.dart';

/// One color per [TransactionKind] (FEAT09 D1) — the exact mapping
/// `TransactionListScreen._titleColor` shipped for income/expense, extended
/// to the other five kinds so every kind now has one. `adjustment` stays
/// neutral: a correction, not a real movement.
Color transactionKindColor(BuildContext context, TransactionKind kind) {
  final colorScheme = Theme.of(context).colorScheme;
  final brightness = Theme.of(context).brightness;
  return switch (kind) {
    TransactionKind.income =>
      brightness == Brightness.dark
          ? Colors.green.shade300
          : Colors.green.shade700,
    TransactionKind.expense => colorScheme.error,
    TransactionKind.transfer => colorScheme.primary,
    TransactionKind.lend || TransactionKind.borrow => colorScheme.tertiary,
    TransactionKind.repayment => colorScheme.secondary,
    TransactionKind.adjustment => colorScheme.onSurfaceVariant,
  };
}
