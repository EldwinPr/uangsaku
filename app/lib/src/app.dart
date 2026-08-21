import 'package:flutter/material.dart';

/// `MaterialApp` root. A placeholder — the first real screen belongs to
/// UC14 (ISSUE-001 D5). No screens, DAOs or providers beyond `AppDatabase`'s
/// land in this issue.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uangsaku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(body: Center(child: Text('uangsaku'))),
    );
  }
}
