import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/transactions/kind_style.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// FEAT09 D1: `kind_style.dart`'s seven color mappings, one per
/// `TransactionKind`.
void main() {
  testWidgets('FEAT09 D1: each TransactionKind maps to its own color', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light()),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final colorScheme = Theme.of(capturedContext).colorScheme;

    expect(
      transactionKindColor(capturedContext, TransactionKind.income),
      Colors.green.shade700,
    );
    expect(
      transactionKindColor(capturedContext, TransactionKind.expense),
      colorScheme.error,
    );
    expect(
      transactionKindColor(capturedContext, TransactionKind.transfer),
      colorScheme.primary,
    );
    expect(
      transactionKindColor(capturedContext, TransactionKind.lend),
      colorScheme.tertiary,
    );
    expect(
      transactionKindColor(capturedContext, TransactionKind.borrow),
      colorScheme.tertiary,
    );
    expect(
      transactionKindColor(capturedContext, TransactionKind.repayment),
      colorScheme.secondary,
    );
    expect(
      transactionKindColor(capturedContext, TransactionKind.adjustment),
      colorScheme.onSurfaceVariant,
    );
  });
}
