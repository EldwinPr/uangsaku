import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/money_format.dart';
import 'package:uangsaku/src/settings/settings_table.dart';

/// Owner feedback 2026-08-24: *"i forgot also add . and ,"* on
/// `BalanceSheetScreen`'s figure cards. Locked here against literal expected
/// strings (unlike the screen test, which computes its expectation through
/// the same function) so a regression in the separators themselves is
/// actually caught.
void main() {
  Future<BuildContext> pumpWithLocale(
    WidgetTester tester,
    Locale locale,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('id')],
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return capturedContext;
  }

  testWidgets('id locale: IDR groups with "." and shows no fraction digits', (
    tester,
  ) async {
    final context = await pumpWithLocale(tester, const Locale('id'));

    expect(formatMinorUnits(context, 100000, Currency.IDR), '100.000');
    expect(formatMinorUnits(context, 1500000, Currency.IDR), '1.500.000');
    expect(formatMinorUnits(context, 0, Currency.IDR), '0');
  });

  testWidgets('en locale: IDR groups with "," and shows no fraction digits', (
    tester,
  ) async {
    final context = await pumpWithLocale(tester, const Locale('en'));

    expect(formatMinorUnits(context, 100000, Currency.IDR), '100,000');
  });

  testWidgets(
    'id locale: USD groups with "." and shows two fraction digits after ","',
    (tester) async {
      final context = await pumpWithLocale(tester, const Locale('id'));

      // 123456 minor units of USD (exponent 2) = 1234.56 major units.
      expect(formatMinorUnits(context, 123456, Currency.USD), '1.234,56');
    },
  );

  testWidgets(
    'en locale: USD groups with "," and shows two fraction digits after "."',
    (tester) async {
      final context = await pumpWithLocale(tester, const Locale('en'));

      expect(formatMinorUnits(context, 123456, Currency.USD), '1,234.56');
    },
  );
}
