import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/settings/help_screen.dart';

/// FEAT10 D1's test: `HelpScreen` is static content, no database, no
/// provider — plain `pumpWidget`, not the `ProviderScope` +
/// `NativeDatabase.memory()` setup every other screen test in this app
/// needs (there is nothing here to watch).
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HelpScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('D1: all four section headers render', (tester) async {
    await pumpScreen(tester);

    expect(find.text('What is an account'), findsOneWidget);
    expect(find.text('Recording money'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Debts'), findsOneWidget);
  });

  testWidgets(
    'D1: expanding the accounts section shows its body text, reusing FEAT09\'s ARB keys',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('help-section-accounts')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Money you hold and can spend directly — a wallet, bank account, or e-wallet.',
        ),
        findsOneWidget,
      );
      expect(find.text('Money someone else owes you.'), findsOneWidget);
      expect(find.text('Money you owe someone else.'), findsOneWidget);
    },
  );

  testWidgets(
    'D1: expanding the recording section shows all six writable kinds plus adjustment',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('help-section-recording')));
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Lend'), findsOneWidget);
      expect(find.text('Borrow'), findsOneWidget);
      expect(find.text('Repayment'), findsOneWidget);
      expect(find.text('Adjustment'), findsOneWidget);
      expect(
        find.text(
          'A correction to an account\'s balance, made directly rather than by recording a transfer or expense — used to fix a mistake or set a starting balance.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('D1: expanding the budgets section shows its paragraph', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('help-section-budgets')));
    await tester.pumpAndSettle();

    expect(find.textContaining('budget group'), findsOneWidget);
    expect(find.textContaining('Others'), findsOneWidget);
  });

  testWidgets('D1: expanding the debts section shows its paragraph', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('help-section-debts')));
    await tester.pumpAndSettle();

    expect(find.textContaining('receivable'), findsOneWidget);
    expect(find.textContaining('payable'), findsOneWidget);
  });
}
