import 'package:flutter/material.dart';

import 'budgeting/set_budget_screen.dart';

/// `MaterialApp` root.
///
/// `home` is `SetBudgetScreen`, temporarily (UC11 D8) — this app has no
/// navigation host and no class diagram draws one, so message 1 on
/// `seq-uc11-set-budget.drawio` (the owner opens the budget screen) is only
/// satisfiable by pointing `home` here, replacing `CategoryManagerScreen`
/// (UC13's screen since 2026-08-21, temporarily), exactly as UC13 D3
/// anticipated a later screen issue would. UC01's balance sheet takes this
/// spot permanently once it lands (FR-1); `CategoryManagerScreen` has no
/// route until then.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SetBudgetScreen(),
    );
  }
}
