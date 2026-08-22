import 'package:flutter/material.dart';

import 'accounts/account_form_screen.dart';

/// `MaterialApp` root.
///
/// `home` is `AccountFormScreen`, temporarily (UC02 D8) — this app has no
/// navigation host and no class diagram draws one, so message 1 on
/// `seq-uc02-add-account.drawio` (the owner enters name, group and opening
/// amount) is only satisfiable by pointing `home` here, replacing
/// `CurrencyScreen` (UC14's screen since 2026-08-22, temporarily), exactly
/// as UC14 D3 anticipated a later screen issue would. This orphans
/// `CurrencyScreen` — no route, no reference from any live widget — the
/// same pattern `pm/findings.md` F8 already tracks. UC01's balance sheet
/// takes this spot permanently once it lands (FR-1); `CurrencyScreen`,
/// `SetBudgetScreen` and `CategoryManagerScreen` have no route until then.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AccountFormScreen(),
    );
  }
}
