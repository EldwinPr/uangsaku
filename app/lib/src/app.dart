import 'package:flutter/material.dart';

import 'settings/currency_screen.dart';

/// `MaterialApp` root.
///
/// `home` is `CurrencyScreen`, temporarily (UC14 D3) — this app has no
/// navigation host and no class diagram draws one, so message 1 on
/// `seq-uc14-choose-currency.drawio` (the owner opens the currency setting)
/// is only satisfiable by pointing `home` here, replacing `SetBudgetScreen`
/// (UC11's screen since 2026-08-22, temporarily), exactly as UC13 D3
/// anticipated a later screen issue would. This orphans `SetBudgetScreen` —
/// no route, no reference from any live widget — the same pattern
/// `pm/findings.md` F8 already tracks. UC01's balance sheet takes this spot
/// permanently once it lands (FR-1); `SetBudgetScreen` has no route until
/// then.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CurrencyScreen(),
    );
  }
}
