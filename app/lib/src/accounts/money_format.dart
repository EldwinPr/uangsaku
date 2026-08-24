import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../settings/settings_table.dart';

/// Renders a raw minor-unit amount as a grouped, locale-appropriate number
/// (owner feedback, 2026-08-24: *"i forgot also add . and ,"* on
/// `BalanceSheetScreen`'s figure cards) — `100000` becomes `100.000` under
/// the `id` locale, `100,000` under `en`; `Currency.exponent` decides
/// whether any fraction digits show at all (`IDR` none, `USD` two, matching
/// `docs/enums.md`).
///
/// The decimal point/grouping separator is deliberately introduced only in
/// this widget-layer function, never in storage — every amount column stays
/// an `int` count of minor units (NFR-2); this divides back to major units
/// purely for display and throws nothing away that a caller needs.
String formatMinorUnits(
  BuildContext context,
  int minorUnits,
  Currency currency,
) {
  final exponent = switch (currency) {
    Currency.IDR => 0,
    Currency.USD => 2,
  };
  final major = minorUnits / _pow10(exponent);
  final locale = Localizations.localeOf(context).languageCode;
  final format = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = exponent
    ..maximumFractionDigits = exponent;
  return format.format(major);
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
