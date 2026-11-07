import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'src/split/split_screen.dart';
import 'src/theme.dart';

void main() {
  runApp(const HarnessDemoApp());
}

class HarnessDemoApp extends StatelessWidget {
  const HarnessDemoApp({super.key, this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    // ShadApp also provides a Material theme and localizations, so Scaffold and
    // other Material widgets keep working under it.
    return ShadApp(
      title: 'Split',
      themeMode: themeMode,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      home: const SplitScreen(),
    );
  }
}
