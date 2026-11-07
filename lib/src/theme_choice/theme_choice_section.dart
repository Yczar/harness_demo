import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme.dart';
import 'theme_choice.dart';

/// A "Theme" heading and three radio options: System, Light and Dark.
///
/// ShadRadio puts its checked state on the circle, its label on a sibling Text
/// and its tap on a GestureDetector around both. Each option here is drawn by a
/// ShadRadio but handled by [_Option], which exposes one node with the label,
/// the checked state and the tap. It also keeps ShadRadio's own tap from
/// unfocusing the field the user is typing in.
class ThemeChoiceSection extends StatelessWidget {
  const ThemeChoiceSection(
      {super.key, required this.choice, required this.onChanged});

  final ThemeChoice choice;
  final ValueChanged<ThemeChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: theme.textTheme.h4),
        const SizedBox(height: Spacing.md),
        ShadRadioGroup<dynamic>(
          initialValue: choice,
          spacing: Spacing.md,
          onChanged: (value) {
            // The group reports the value it was given when the choice is set
            // from outside too. Only a real change goes up, so the parent
            // never rebuilds during its own build.
            if (value is ThemeChoice && value != choice) onChanged(value);
          },
          items: [
            for (final option in ThemeChoice.values)
              _Option(
                option: option,
                selected: option == choice,
                onTap: () => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option(
      {required this.option, required this.selected, required this.onTap});

  final ThemeChoice option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: option.label,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      // The one node above replaces whatever ShadRadio reports.
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        // ShadRadio's own tap would unfocus the current field.
        child: IgnorePointer(
          child: ShadRadio<dynamic>(
            value: option,
            label: Text(option.label),
          ),
        ),
      ),
    );
  }
}
