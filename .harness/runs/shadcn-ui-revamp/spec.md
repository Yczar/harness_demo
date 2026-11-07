# Spec: shadcn-ui-revamp

**Request:** "Revamp the split screen UI with the design-system skill: move it to shadcn_ui components and theme tokens, with light and dark themes. Keep every existing behaviour and visible label. The human has approved shadcn_ui as a new package."
**Size:** One run. It touches about 8 files, so the map below is the contract. There is no new logic: `split_calculator.dart` does not change.

## Why this is riskier than it looks (from the shadcn_ui 0.53.6 source)
- `ShadInput` builds a raw `EditableText`, not a `TextField`, and adds no `Semantics` of its own (`lib/src/components/input.dart`).
- `ShadInputFormField`'s `label:` goes through `ShadInputDecorator` (`lib/src/theme/components/input_decorator.dart`), which puts a plain `Text` in a `Column` above the input. The label has no tap handler and no semantic link to the field. Used as-is, the Semantics tree has a "Bill total" text node next to an unlabelled text field. `tapOn: "Bill total"` would then tap dead text and the field would not get focus. So the field's label must be attached to it on purpose. How is up to the builder; the acceptance criteria below check it.
- `ShadButton` wraps its child in `Semantics(container: true, button: true)`, so "Calculate" reaches Semantics as a button label.
- `ShadApp()` builds a `WidgetsApp`, not a `MaterialApp`. If the screen keeps using `Scaffold`, the root has to be the Material bridge (`ShadApp.custom` wrapping a `MaterialApp`, or an equivalent), so Material localizations and `Theme.of` still work.

## What done looks like
Behaviour (unchanged; these must keep passing):
- Given the app has just launched, then "Bill total" is empty, "People" shows "2" and "Tip percent" shows "10".
- Given Bill total 100, People 4, Tip percent 10, when the user taps "Calculate", then "Each person pays 27.50" is shown.
- Given Bill total is empty, when the user taps "Calculate", then "Enter a bill total above zero" is shown.
- Given People is "0" or not a whole number, when the user taps "Calculate", then "Enter at least one person" is shown.
- Given Tip percent is "-5" or not a number, when the user taps "Calculate", then "Enter a tip of zero or more" is shown.
- Given an error is showing, when the user fixes the input and taps "Calculate", then only the result is shown and the error is gone. The reverse also holds.
- The keyboard is a decimal number pad for Bill total and Tip percent, and a whole-number pad for People.

Components and tokens:
- Each of the three fields is a `ShadInputFormField` (or a `ShadInput` under a visible label). There is no `TextField` in `split_screen.dart`.
- "Calculate" is a `ShadButton` (primary). There is no `FilledButton` or `ElevatedButton`.
- A failure message is a `ShadAlert.destructive` that contains the exact message text.
- The success line "Each person pays 27.50" uses a `ShadTheme.of(context).textTheme` style (for example `h2`/`h3`), and it sits in a `ShadCard`.
- `split_screen.dart` and `main.dart` contain no `Color(0x…)`, no `Colors.*` and no hand-built `TextStyle(fontSize:/color:)`. The current `Color(0xFF4285F4)` seed goes. Spacing uses named constants from one scale (4, 8, 12, 16, 24, 32) in one file.
- The result keeps announcing itself to screen readers (live region), for both success and failure.

Labels reach Semantics (this is what device tests depend on):
- Given the screen is shown, then for each of "Bill total", "People" and "Tip percent" there is exactly one Semantics node with that label, and that node is a text field. There are no duplicate or stray label nodes.
- Given the screen is shown, when the user (or Maestro) taps the text "Bill total", then the Bill total field gets focus and typing goes into it. The same holds for "People" and "Tip percent".
- "Calculate" is exactly one Semantics node, a button with the label "Calculate".

Themes:
- `HarnessDemoApp` takes an optional `themeMode` (a `ThemeMode`, default `ThemeMode.system`) so tests can force light or dark.
- Given `themeMode: ThemeMode.dark`, then `ShadTheme.of(context).brightness` is `Brightness.dark` on the split screen, and the happy-path and missing-total behaviours above still hold.
- Given `themeMode: ThemeMode.light`, then the brightness is `Brightness.light`.
- Both `theme` and `darkTheme` are defined once (in `lib/src/theme.dart` or `lib/main.dart`) and use the same shadcn colour scheme family.

## Map
- `pubspec.yaml` - add `shadcn_ui` (approved; resolves 0.53.6 on Flutter 3.35.4).
- `pubspec.lock` - updated by `flutter pub add`. It already shows as modified in git, so check that the diff only adds shadcn_ui and its transitive packages.
- `lib/main.dart` - replace the `MaterialApp` and hex seed with the ShadApp Material bridge, light and dark `ShadThemeData`, and the new `themeMode` parameter on `HarnessDemoApp`.
- `lib/src/theme.dart` (new) - the single home for the light and dark themes and the spacing constants. Optional if both fit cleanly in `main.dart`, but spacing constants must live in exactly one file.
- `lib/src/split/split_screen.dart` - swap `TextField` for a shadcn input with an attached label, `FilledButton` for `ShadButton`, error `Text` for `ShadAlert.destructive`, and `Theme.of` styles for `ShadTheme` tokens. Keep the controllers, the defaults, `_calculate` and the live region.
- `test/widget/split_screen_test.dart` - finders change: `find.widgetWithText(TextField, …)` becomes the shadcn input type or the label, and `FilledButton` becomes `ShadButton`. `pumpScreen` must provide a ShadTheme (pump `HarnessDemoApp`, or wrap in the same themes), because a bare `MaterialApp` has no `ShadTheme` and the screen will throw. Add tests for: each label is one text-field Semantics node, tapping the label focuses its field, the three error messages, error-to-success replacement, dark mode brightness plus happy path.
- `test/golden/split_screen_golden_test.dart` - finders change as above. Pump with the app themes and produce four goldens: `goldens/split_screen_success_light.png`, `goldens/split_screen_success_dark.png`, `goldens/split_screen_error_light.png`, `goldens/split_screen_error_dark.png`. The error state is the missing-total message "Enter a bill total above zero". Note that `goldens/split_screen.png` does not exist in the repo today. Only the human creates or accepts golden files.
- `.maestro/split_happy_path.yaml` - no change expected. It is the device-level check that labels are attached (`tapOn: "Bill total"` then `inputText`). If it has to change, that is a sign the labels are broken, not a reason to edit the flow.

**Maybe:**
- `test/unit/split_calculator_test.dart` - should not change, since the logic is untouched. Listed so the reviewer can confirm it didn't.
- `test/golden/goldens/` - a new folder for the golden PNGs. The human creates it via `accept-goldens.sh`, not the builder or the test-writer.
- `analysis_options.yaml` - only if the human wants a lint against `Color(`/`Colors.` in `lib/src/**` screens. Not required by this request.
- `android/`, `ios/` - no change expected. shadcn_ui is pure Dart. Listed in case the build step complains.

## Labels
Unchanged text. These are the device-test contract.
- Bill total field (shadcn input, decimal): "Bill total"
- People field (shadcn input, integer): "People"
- Tip percent field (shadcn input, decimal): "Tip percent"
- Primary button (`ShadButton`): "Calculate"
- Screen title (visible text, not interactive): "Split the bill"
- Messages (exact): "Each person pays <amount to 2 dp>", "Enter a bill total above zero", "Enter at least one person", "Enter a tip of zero or more"

## Edge cases
- Empty fields, whitespace only, and non-numeric text ("abc", "1,000") each give their matching error message, never a blank or zero result.
- The first failing field wins (total, then people, then tip), the same as today.
- Very large input (for example 1e15) gives a long result string. It wraps rather than overflowing the card or alert, with no RenderFlex overflow.
- Small screen (320 x 568 logical) with the keyboard open: the screen still scrolls so "Calculate" and the result are reachable.
- Text scale 2.0: labels, inputs, button and alert don't clip or overflow.
- Dark mode: the destructive alert, muted text, input borders and the focus ring all come from the dark colour scheme and stay readable. No light-only literal survives.
- The system theme changes while the app is running: the screen re-themes without losing what was typed or the shown result.
- Screen reader: each field is announced once with its label, the button as "Calculate, button", and results and errors as live-region announcements. No doubled labels from an extra `Semantics(label:)`.
- Network: not applicable, the app makes no calls.

## Decisions (human-approved; these override anything above that conflicts)
1. Colour scheme: shadcn `blue`, for both the light and dark themes.
2. Title: "Split the bill" is a shadcn heading, styled with a `ShadTheme.of(context).textTheme` token. There is no Material `AppBar`. The text is unchanged.
3. Success result: it sits in a `ShadCard`.
4. Labels: the builder may add one `Semantics` or `MergeSemantics` wrapper per field to attach its visible label, because `ShadInput` doesn't expose one. A field must never carry two labels.
5. Goldens: four in total, the success state and one error state, each in light and dark. The human creates and accepts them.
6. No dark-mode Maestro flow. The widget tests and the dark goldens cover dark mode.
7. Font: keep shadcn_ui's bundled default font.

## Out of scope
- Any change to `split_calculator.dart` or to the rules for splitting.
- Round-up and currency (stashed work). No "Round up" switch or "Currency" select in this run.
- An in-app theme toggle. Dark mode follows the system setting (and `themeMode` exists for tests only).
- New screens, navigation, persistence, localisation.
- Other packages besides shadcn_ui (and its own transitive dependencies).
- Reworking the existing `result.perPerson!` in `_ResultView` beyond what the move to shadcn needs. It is guarded by `error == null`. The reviewer may note it, but changing `SplitResult` is not part of this run.
