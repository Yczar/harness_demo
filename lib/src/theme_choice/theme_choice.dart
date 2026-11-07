import 'package:flutter/material.dart';

/// The theme the user can pick in the app. Pure Dart: no widgets.
enum ThemeChoice {
  system('System', ThemeMode.system),
  light('Light', ThemeMode.light),
  dark('Dark', ThemeMode.dark);

  const ThemeChoice(this.label, this.themeMode);

  /// The visible label. Device tests find the option by this text.
  final String label;

  final ThemeMode themeMode;

  /// The choice that matches [mode]. Every [ThemeMode] has one.
  static ThemeChoice fromThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => ThemeChoice.system,
        ThemeMode.light => ThemeChoice.light,
        ThemeMode.dark => ThemeChoice.dark,
      };
}
