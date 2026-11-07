# Spec: dark-mode-toggle

**Request:** "Add dark mode"
**Size:** Small. One new control, about 5 files. One run is enough.

## Read this first: what already exists
- **Dark mode itself shipped in `cf6a706` (shadcn revamp).** `lib/src/theme.dart` defines `lightTheme()` and `darkTheme()` (shadcn blue), `ShadApp` in `lib/main.dart` sets both, and `HarnessDemoApp(themeMode:)` defaults to `ThemeMode.system`. The `themes` group in `test/widget/split_screen_test.dart` already covers light, dark, following the system, and re-theming without losing input. That spec listed "an in-app theme toggle" as out of scope.
- **So this spec reads "Add dark mode" as: let the user choose the theme inside the app** (the run is named `dark-mode-toggle`). If you only wanted dark mode to follow the phone's setting, that works already and this run is not needed. See Q1.
- **The earlier dark-mode work is not in the working tree.** `git status` is clean. There is no `lib/src/theme_choice/`, no `test/widget/theme_choice_test.dart`, and no theme-choice code in `lib/main.dart` or `lib/src/split/split_screen.dart` (searched for `theme_choice`, `ThemeChoice`, `'System'`, `'Dark'`: no matches). What is left is only gitignored run files in `.harness/runs/dark-mode/`: `approved`, `checks_passed`, an empty `goldens_pending`, `checks.log`, `recording.mp4`, and no `spec.md`. Its `checks.log` shows what it built: a "Theme" heading with three options, System / Light / Dark, session only, and 72 passing tests.
- **Plan: start fresh and match that earlier design** (same labels, same behaviour), because there is no code to build on. If that work lives on a stash or another branch, you have to restore it before the run starts. Otherwise it gets rebuilt. See Q2.
- No golden PNGs exist yet (`test/golden/goldens/` is missing). The four light and dark goldens from the revamp are still waiting for you to accept them.

## What done looks like
- Given a fresh launch, when the split screen shows, then a "Theme" heading is shown with three options, "System", "Light" and "Dark", and only "System" is chosen.
- Given System is chosen, when the platform brightness is dark (or light), then the screen uses the dark (or light) shadcn blue scheme. This is today's behaviour, kept.
- Given any choice, when the user taps "Dark", then `ShadTheme.of(context).brightness` is `Brightness.dark` and only "Dark" is chosen. The same holds for "Light".
- Given "Light" or "Dark" is chosen, when the platform brightness changes, then the theme does not change.
- Given "Dark" is chosen, when the user taps "System", then the theme follows the platform again.
- Given a typed bill total and a shown result or error message, when the theme changes, then the typed text and the result or error are still there, and a focused field stays focused.
- Given the user tapped the option that is already chosen, then nothing changes. Given several taps in a row, the last option tapped wins.
- Given the app is restarted, then it starts on "System" again (session only, see Q3).
- Given `HarnessDemoApp(themeMode: ThemeMode.light)` (or `.dark`/`.system`), then the matching option starts chosen. Existing tests and goldens that pass `themeMode` keep working unchanged.
- Semantics: each option is exactly one node that carries its label, its checked state (`isChecked` true only for the chosen one, false for the rest, in a mutually exclusive group) and a tap action. The "Theme" heading is its own node and doesn't merge into the options. `labeledTapTargetGuideline` still passes.
- Device flow: launching, tapping "Dark", then `assertVisible: "Dark"` with checked state, and the happy path still works afterwards.

## Map
- `lib/main.dart` - `HarnessDemoApp` has to own the chosen mode so `ShadApp.themeMode` can change at runtime. It becomes stateful (or wraps a stateful root). The `themeMode` param stays as the initial value.
- `lib/src/theme_choice/theme_choice.dart` (new) - pure Dart: the three choices, their labels, and the mapping to `ThemeMode`. Unit-testable, no widgets.
- `lib/src/theme_choice/theme_choice_section.dart` (new) - the "Theme" heading plus a `ShadRadioGroup` of three `ShadRadio`s. Tokens only. It fixes Semantics so each option is one node (see Edge cases).
- `lib/src/split/split_screen.dart` - puts the section on the screen and passes the current choice and the on-change callback through. `SplitScreen`'s constructor gains those parameters. The existing state (controllers, `_result`) must survive a theme change.
- `test/unit/theme_choice_test.dart` (new) - choice to `ThemeMode` mapping, labels.
- `test/widget/theme_choice_test.dart` (new) - every "done" criterion above, plus small screen and large text in light and dark.
- `test/widget/split_screen_test.dart` - should pass unchanged. The finder `find.byType(SingleChildScrollView)` and the "uses shadcn controls" counts must still hold with the new section (the section adds no `EditableText` and no `ShadButton`).
- `test/golden/split_screen_golden_test.dart` - all four goldens change because the section is now on the screen. You accept them. Optionally add a golden with "Dark" chosen.
- `.maestro/theme_choice.yaml` (new) - taps "Dark", checks it is chosen, then runs the happy path.

**Maybe:**
- `.maestro/split_happy_path.yaml` - should be untouched. It changes only if the section pushes "Calculate" off screen and a scroll step is needed.
- `lib/src/theme.dart` - should be untouched. It would change only if the section needs a new spacing constant.
- `.harness/runs/dark-mode/` - stale artefacts with an `approved` marker. Check that the harness scripts don't mix them up with this run.

## Labels
- Section heading (plain text, not interactive): "Theme"
- `ShadRadio` option: "System"
- `ShadRadio` option: "Light"
- `ShadRadio` option: "Dark"
- Labels that stay the same: "Bill total", "People", "Tip percent", "Calculate"

## Edge cases
- In shadcn_ui 0.53.6, `ShadRadio` puts `Semantics(checked:)` on the circle only. The label is a sibling `Text`, and the tap sits on a `GestureDetector` around both. Out of the box, the label, the checked state and the tap land on different nodes. That is the same class of bug the split screen's fields had. Tests must check that the label, checked state and tap are on one node. Don't stack a second label on top.
- Dark mode: the radio ring, the dot, the heading and the focus ring all use dark-scheme tokens. No `Colors.*` or `Color(0x...)`.
- Small screen (320x568) at text scale 2.0, in light and dark: no overflow. Labels wrap or scale, and "Calculate" and the result can still be reached by scrolling.
- Keyboard open: changing the theme doesn't close the keyboard or move focus.
- System brightness changes while System is chosen: re-themes live (already tested, must not regress).
- Nothing here can fail (no I/O), so there are no new error messages. Saving the choice would change that (Q3).

## Open questions for the human
1. **Scope:** dark mode already follows the system setting. Do you want the in-app choice described here, or was "Add dark mode" meant as something else (for example, nothing more is needed)?
2. **Earlier work:** the uncommitted theme-choice code you mentioned isn't in the tree, and git is clean. Is it on a stash or a branch you want restored and built on, or should this run rebuild it from scratch as specced? Also, can the stale `.harness/runs/dark-mode/` folder be deleted?
3. **Remember the choice?** As specced, it resets to System on every launch, like the earlier run. Remembering it needs storage such as `shared_preferences`, which is a new package and needs your OK, plus a failure message if loading or saving fails.
4. **Control and copy:** three radios, "System" / "Light" / "Dark", under a "Theme" heading (matching the earlier run)? Or a single `ShadSwitch` labelled "Dark mode", which gives no way back to System? Or `ShadTabs` as a segmented control?
5. **Placement:** where on the split screen? I'd suggest below the result, so the bill flow stays on top, but it's your call. Top of the screen and a settings sheet are the other options.

## Out of scope
- Saving the choice across launches (unless Q3 says yes).
- New colour schemes, or changing the light or dark palettes.
- A settings screen or navigation.
- Changes to the split logic, labels or messages.
