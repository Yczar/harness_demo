import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'src/split/split_screen.dart';
import 'src/theme.dart';
import 'src/theme_choice/theme_choice.dart';

void main() {
  runApp(const HarnessDemoApp());
}

class HarnessDemoApp extends StatefulWidget {
  /// [themeMode] is the theme the app starts with. The user can change it.
  const HarnessDemoApp({super.key, this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  @override
  State<HarnessDemoApp> createState() => _HarnessDemoAppState();
}

class _HarnessDemoAppState extends State<HarnessDemoApp> {
  late ThemeChoice _choice = ThemeChoice.fromThemeMode(widget.themeMode);

  @override
  Widget build(BuildContext context) {
    // ShadApp also provides a Material theme and localizations, so Scaffold and
    // other Material widgets keep working under it.
    return ShadApp(
      title: 'Split',
      themeMode: _choice.themeMode,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      home: SplitScreen(
        themeChoice: _choice,
        onThemeChoiceChanged: (choice) => setState(() => _choice = choice),
      ),
    );
  }
}
