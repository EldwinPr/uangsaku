import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/group_style.dart';

/// FEAT09 D1: `group_style.dart`'s three color-and-icon mappings, one per
/// `AccountGroup`.
void main() {
  testWidgets('FEAT09 D1: each AccountGroup has a distinct color and icon', (
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
      accountGroupColor(capturedContext, AccountGroup.HOLDING),
      colorScheme.primary,
    );
    expect(
      accountGroupColor(capturedContext, AccountGroup.RECEIVABLE),
      Colors.green.shade700,
    );
    expect(
      accountGroupColor(capturedContext, AccountGroup.PAYABLE),
      colorScheme.error,
    );
    expect(
      accountGroupColor(capturedContext, AccountGroup.PERSON),
      colorScheme.tertiary,
    );

    expect(
      accountGroupIcon(AccountGroup.HOLDING),
      Icons.account_balance_wallet,
    );
    expect(accountGroupIcon(AccountGroup.RECEIVABLE), Icons.call_received);
    expect(accountGroupIcon(AccountGroup.PAYABLE), Icons.call_made);
    expect(accountGroupIcon(AccountGroup.PERSON), Icons.sync_alt);
  });

  testWidgets('FEAT09 D1: RECEIVABLE swaps its green shade in dark mode', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      accountGroupColor(capturedContext, AccountGroup.RECEIVABLE),
      Colors.green.shade300,
    );
  });
}
