---
name: design-system
description: How UI is built in this app - shadcn_ui components and theme tokens, never hand-rolled styling. Use when writing a spec, tests, code or a review that touches anything on screen.
---

# Design system: shadcn_ui

The app's look comes from one place: [shadcn_ui](https://pub.dev/packages/shadcn_ui) (MIT), a Flutter take on shadcn/ui. Screens use its components and read every colour, font and radius from its theme. If a screen looks good only because someone picked a hex value by hand, it will drift from the rest.

The version is whatever `pubspec.lock` pins. Flutter 3.35 resolves 0.53.x. The API moves between versions, so before you use a widget, read its source in `~/.pub-cache/hosted/pub.dev/shadcn_ui-<version>/lib/`. Don't work from memory or from the latest docs.

## Use the component, not a Material lookalike
| Need | Use | Not |
|---|---|---|
| App root and theme | `ShadApp` (or its Material bridge, so `Theme.of` keeps working) | bare `MaterialApp` theme tweaks |
| Text field | `ShadInput` / `ShadInputFormField` | `TextField` with a custom `InputDecoration` |
| Dropdown | `ShadSelect` | `DropdownButtonFormField` |
| On/off | `ShadSwitch` | `Switch`, `SwitchListTile` |
| Main action | `ShadButton` (secondary: `ShadButton.outline` / `.secondary`) | `ElevatedButton`, `FilledButton` |
| Grouping | `ShadCard` | `Card`, hand-made `Container` boxes |
| Failure message | `ShadAlert.destructive` | red `Text` |

If shadcn_ui has no component for something, compose it from shadcn pieces and theme tokens. Say so in the spec.

## Tokens, not literals
```dart
// Drifts. Nobody knows where this grey came from.
Text('Each person pays ₦27.50', style: TextStyle(fontSize: 28, color: Color(0xFF333333)));

// Follows the theme in light and dark.
final theme = ShadTheme.of(context);
Text('Each person pays ₦27.50', style: theme.textTheme.h2);
Text('Couldn\'t save your currency.', style: theme.textTheme.muted);
```
- Colours come from `ShadTheme.of(context).colorScheme`. There are no `Color(0x...)` or `Colors.*` in screen files.
- Text styles come from `ShadTheme.of(context).textTheme` (`h1` to `h4`, `p`, `large`, `small`, `muted`, `lead`).
- The radius comes from the theme. Spacing uses one scale (4, 8, 12, 16, 24, 32), kept as named constants in one file. Don't scatter magic numbers.
- The theme is defined once, in `lib/main.dart` (or a single `lib/src/theme.dart`). Set both `theme` and `darkTheme`, so dark mode works for free.

## Labels still rule
The house rule on visible labels doesn't change. Device flows and widget tests find fields by their visible label through the Semantics tree. shadcn fields show their label as a `label:` widget above the input, which isn't Material's `labelText`. So:
- Every field, select and switch gets a visible label with the same text as today ("Bill total", "People", "Tip percent", "Round up", "Currency").
- Check how the label reaches Semantics. Run the app and read the tree with the Dart MCP widget tree, or `maestro hierarchy`. A label that sits beside the field but isn't attached to it is a bug, because `tapOn: "Bill total"` must still focus the field.
- Don't stack `Semantics(label:)` over a component that already exposes its label.

## For each role
- **spec-writer:** name the shadcn component for every control on the map, and list which tests and flows will change because the widget types change (finders like `find.byType(TextField)`, Maestro selectors).
- **test-writer:** find widgets by visible text or shadcn type (`ShadInput`, `ShadSelect`, `ShadSwitch`, `ShadButton`), not Material types. Goldens will all change, and the human accepts them.
- **builder:** read the component source before you use it. Use only tokens, with no new literals. Check the Semantics tree on a device.
- **reviewer:** block on hard-coded colours or text styles in screens, Material controls where a shadcn one exists, or a label that doesn't reach Semantics.
