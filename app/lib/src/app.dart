import 'package:flutter/material.dart';

import 'transactions/category_manager_screen.dart';

/// `MaterialApp` root.
///
/// `home` is `CategoryManagerScreen`, temporarily (UC13 D3) — this app has
/// no navigation host and no class diagram draws one, so message 1 on
/// `seq-uc13-categories.drawio` (the owner opens category setup) is only
/// satisfiable by pointing `home` here, replacing FEAT01's placeholder.
/// UC01's balance sheet takes this spot permanently once it lands (FR-1).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CategoryManagerScreen(),
    );
  }
}
