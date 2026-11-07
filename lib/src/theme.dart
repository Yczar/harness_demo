import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The app's shadcn themes, defined once. Screens read colours, text styles and
/// radii from `ShadTheme.of(context)`; they never pick their own.
ShadThemeData lightTheme() => ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadBlueColorScheme.light(),
    );

ShadThemeData darkTheme() => ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadBlueColorScheme.dark(),
    );

/// The one spacing scale. Use these names, not bare numbers.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}
