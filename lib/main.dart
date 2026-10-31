import 'package:flutter/material.dart';

import 'src/split/split_screen.dart';

void main() {
  runApp(const HarnessDemoApp());
}

class HarnessDemoApp extends StatelessWidget {
  const HarnessDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Split',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4285F4), useMaterial3: true),
      home: const SplitScreen(),
    );
  }
}
