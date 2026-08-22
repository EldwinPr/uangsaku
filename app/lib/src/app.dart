import 'package:flutter/material.dart';

import 'accounts/balance_sheet_screen.dart';

/// `MaterialApp` root.
///
/// `home` is `BalanceSheetScreen`, permanently (UC01 D7) — FR-1 makes the
/// balance sheet *the primary screen, not a report behind a menu*, and
/// message 1 on `seq-uc01-balance-sheet.drawio` (the owner reaches it by
/// opening the app) is only satisfiable by pointing `home` here, replacing
/// `AccountFormScreen` (UC02's temporary occupant since 2026-08-22), exactly
/// as UC02 D8 anticipated: *"Explicitly temporary … Re-pointing `home` is
/// UC-01's business."* Unlike the three previous re-pointings this one is
/// not temporary — no planned issue draws a screen meant to displace it.
/// This orphans `AccountFormScreen`, the fourth dead screen after
/// `CurrencyScreen`, `SetBudgetScreen` and `CategoryManagerScreen` — the
/// same pattern `pm/findings.md` F8 tracks. There is still no navigation
/// host: no class diagram draws one, so none can be invented here.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BalanceSheetScreen(),
    );
  }
}
