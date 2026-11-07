# Ready for you: dark-mode-toggle

**What changed:** Dark mode already followed the phone's setting. You can now also choose System, Light or Dark inside the app, from a "Theme" section below the result. The choice resets to System on every launch.

## Acceptance criteria
- Fresh launch shows a "Theme" heading with System, Light and Dark, and only System chosen - `test/widget/theme_choice_test.dart` ("shows a Theme heading...", "starts with only System chosen...").
- System follows the platform brightness - the two "System follows a ... platform" tests.
- Tapping Dark or Light switches the theme and checks only that option - the "tapping Dark/Light" tests.
- Light or Dark ignores platform changes; Dark then System follows the platform again - matching widget tests.
- Typed total, result, error and focus survive a theme change - the "changing the theme keeps the screen state" group.
- Tapping the chosen option does nothing; the last of several taps wins - matching widget tests.
- Restart goes back to System; `themeMode` sets the starting option - "a new app instance starts on System again" and the three `themeMode` tests.
- Each option is one Semantics node with label, checked state and tap; `labeledTapTargetGuideline` passes - the Semantics tests.
- Small screen at 2x text, light and dark, no overflow - the small-screen tests.
- Device flow - `.maestro/theme_choice.yaml` passed on the device, together with `split_happy_path`.

## Files changed
- `lib/src/theme_choice/theme_choice.dart` (new) - the `ThemeChoice` enum with labels and the `ThemeMode` mapping.
- `lib/src/theme_choice/theme_choice_section.dart` (new) - the heading and three radio options.
- `lib/main.dart` - `HarnessDemoApp` is now stateful and holds the chosen mode for the session.
- `lib/src/split/split_screen.dart` - shows the section below the result.
- `test/widget/theme_choice_test.dart`, `test/golden/theme_choice_golden_test.dart`, `.maestro/theme_choice.yaml` (new) - the tests.

## Worth a closer look
- Each option is a custom `Semantics` around a `GestureDetector` and an `IgnorePointer(ShadRadio)`. `ShadRadio` splits its label, checked state and tap across separate nodes, and its own tap clears the focus of the field you're typing in. The reviewer accepted this and noted that `_NumberField` already uses the same pattern. The cost is no click cursor or hover feedback on desktop and web.
- Five goldens are waiting for you to accept: the four existing split-screen ones, which now show the Theme section, and the new "Dark chosen" one.
- Some widget tests print a "tap() would not hit test" warning because of the `IgnorePointer`. None of them fail because of it.
- No unit test exists for `ThemeChoice`. The spec gave no Dart names, so the test-writer skipped it, but `test/unit/theme_choice_test.dart` is in the spec's map.
- The old `.harness/runs/dark-mode/` folder is untouched, and so is your earlier lost work.

## Reviewer suggestions (not blocking)
- Type the group as `ShadRadioGroup<ThemeChoice>` instead of `<dynamic>`. The existing test finds `ShadRadioGroup<dynamic>` by exact type, so this would need a test change.
- Add a comment on the group's `initialValue` being used as a controlled value, and say that `onChanged` only serves keyboard use.
- Mark the "Theme" heading with `Semantics(header: true)`.
- `.maestro/theme_choice.yaml` should assert `checked: true` on "Dark", not just that it's visible.
- Add a test for choosing a theme from the keyboard.

## Before you merge
- [ ] Watch the recording (`recording.mp4`), or run the app
- [ ] New golden files? Look at the UI, then run `.claude/harness/accept-goldens.sh`
- [ ] Push and merge yourself
