Verdict: APPROVE

# Review: dark-mode-toggle

## Blocking
None.

## The custom Semantics + GestureDetector + IgnorePointer around ShadRadio
`lib/src/theme_choice/theme_choice_section.dart:62-81`. I judged this against the house rule "Don't stack extra `Semantics(label:)` on top of them" and found it acceptable:
- It doesn't stack anything. `excludeSemantics: true` drops ShadRadio's own subtree (the `Semantics(checked:)` on the circle and the sibling `Text` label). What's left is exactly one node, with the label, the checked state, `inMutuallyExclusiveGroup` and the tap. The rule exists to stop two labels sitting on top of each other, and this has one. The spec asks for it ("It fixes Semantics so each option is one node"), and it's the same pattern `_NumberField` already uses (`split_screen.dart:160-172`: `ExcludeSemantics` plus one `Semantics` label).
- The visible label and the semantic label both come from `option.label`, so they can't drift apart. Maestro's `tapOn: "Dark"` matches the text the user sees.
- The `IgnorePointer` is there for a reason. In shadcn_ui 0.53.6, `ShadRadio.onTap` calls `FocusScope.of(context).unfocus()` whenever the radio itself isn't focused (`radio.dart:325-330`). That would break the spec's rule that a focused field stays focused with the keyboard open. Moving the tap to an outer `GestureDetector` (`HitTestBehavior.opaque`, `excludeFromSemantics: true`) is the least invasive fix. The only semantic tap is the one on the `Semantics` node, so nothing fires twice.
- The cost is small and fits a mobile app: on desktop or web you lose ShadRadio's click cursor and hover feedback. Keyboard use still works, because `IgnorePointer` doesn't block focus. Enter or Space on a focused radio sets the group controller, and the change reaches the parent through `ShadRadioGroup.onChanged`.

## Spec coverage
- Fresh launch shows the "Theme" heading and System / Light / Dark, with only System chosen. Met: `theme_choice_section.dart:27-45`, `main.dart:23` (the default `ThemeMode.system`).
- System follows the platform brightness. Met: `main.dart:31` passes `ThemeMode.system` through to `ShadApp`.
- Tapping Dark or Light sets that brightness and checks only that option. Met: `_Option.onTap` calls `onChanged(option)`, then `setState` in `_HarnessDemoAppState`.
- Light or Dark ignores platform brightness changes. Met (a fixed `ThemeMode`).
- Going from Dark back to System follows the platform again. Met.
- Typed text, the result or error, and focus all survive a theme change. Met. `SplitScreen` keeps its element and state, because `home:` is rebuilt with the same type at the same position. Focus is kept because ShadRadio's unfocus path is bypassed (see above).
- Tapping the option that's already chosen changes nothing, and the last tap wins. Met. The parent sets an equal value, the group's `didUpdateWidget` doesn't fire because `initialValue` is unchanged, and `value != choice` stops the echo.
- A restart goes back to System (session only). Met. State lives only in `_HarnessDemoAppState`, and nothing is saved.
- `HarnessDemoApp(themeMode:)` picks the starting option. Met: `ThemeChoice.fromThemeMode`, an exhaustive switch with no default.
- Semantics: one node per option with label, checked, mutually exclusive group and tap; the heading is its own node; `labeledTapTargetGuideline` passes. Met in the code and covered by widget tests.
- Small screen, large text, light and dark: no overflow. Covered by widget tests. The section is a `Column` inside the existing `SingleChildScrollView`.
- Tokens only. Met: `theme.textTheme.h4` and `Spacing.md`, no `Colors.*` or `Color(0x...)`. ShadRadio uses `colorScheme.primary`, so it follows the dark scheme.
- Device flow: tap "Dark", then `assertVisible: "Dark"` with its checked state. Partly met, but the gap is in the test file, not the builder's code (see Suggestions).
- Existing split screen tests and goldens unchanged. Met: `git diff` touches no existing test. `lib/src/theme.dart` and `.maestro/split_happy_path.yaml` are untouched too.

## Suggestions (don't block)
- `lib/src/theme_choice/theme_choice_section.dart:29,36,75` - `ShadRadioGroup<dynamic>` and `ShadRadio<dynamic>` throw the type away. Then `value is ThemeChoice` quietly drops anything else, null included, without saying so. That's a mild form of the masking `no-error-masking` warns about. `ShadRadioGroup<ThemeChoice>` and `ShadRadio<ThemeChoice>` work with 0.53.6's provider cast. With them, the check becomes `if (value != null && value != choice)`, and you can drop the dynamic typing.
- `lib/src/theme_choice/theme_choice_section.dart:30` - `initialValue` is used as a controlled value. This depends on `ShadRadioGroup.didUpdateWidget` copying a changed `initialValue` into its controller (`radio.dart:152-154`), which isn't part of its public contract. The comment at :33-35 explains the echo. One line naming that dependency would help whoever next upgrades shadcn_ui.
- `lib/src/theme_choice/theme_choice_section.dart:9-13` - the class doc doesn't say that keyboard activation still goes through ShadRadio and the group's `onChanged`. That's the only path the group callback serves now. Worth saying, so nobody deletes it as dead code.
- `lib/src/theme_choice/theme_choice_section.dart:27` - think about `Semantics(header: true, child: Text('Theme', ...))` so screen readers announce it as a heading. It adds a role, not a label, so it doesn't break the no-stacked-labels rule. This is optional, because the spec only asks for its own node.
- Test gaps the builder can't fix (for the human or the test writer):
  - `test/unit/theme_choice_test.dart` is in the spec's map but doesn't exist. The labels and the `fromThemeMode` and `themeMode` mapping are covered only indirectly, by the widget tests.
  - `.maestro/theme_choice.yaml:8` checks `assertVisible: "Dark"` with no checked state. The text was already visible before the tap, so this proves nothing. The spec asks for the checked state: `assertVisible: { text: "Dark", checked: true }`.
  - No test covers Enter or Space on a focused radio (the keyboard path through the group's `onChanged`).
- The four existing split-screen goldens and the new `split_screen_theme_dark_chosen.png` are waiting for you to accept them (`test/golden/goldens/` doesn't exist yet). Look at the dark radio ring and dot before you accept.

## Scope
- Files changed outside the spec's map: none. Changed: `lib/main.dart` and `lib/src/split/split_screen.dart`. New: `lib/src/theme_choice/theme_choice.dart`, `lib/src/theme_choice/theme_choice_section.dart`, `test/widget/theme_choice_test.dart`, `test/golden/theme_choice_golden_test.dart` (the optional Dark golden) and `.maestro/theme_choice.yaml`. No new packages, and no secrets or personal data.
