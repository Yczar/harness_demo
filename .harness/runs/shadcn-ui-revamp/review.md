Verdict: BLOCK

# Review: shadcn-ui-revamp

## Blocking

- `lib/src/split/split_screen.dart:136-141` - **Three stray, unlabelled tap nodes.** `ExcludeSemantics` wraps only the label `Text`, but the `GestureDetector` around it still adds its own tap action to the Semantics tree. I dumped the real screen's tree (`HarnessDemoApp`, light, after Calculate). Above each field it shows a node with `actions: tap` and **no label** (nodes #6, #8 and #10, above "Bill total", "People" and "Tip percent"). TalkBack and VoiceOver stop on each one and read only "double-tap to activate". This breaks the spec's "no duplicate or stray label nodes" and "each field is announced once", and Android's Accessibility Scanner would flag it. The existing tests can't see it, because they only look for nodes *with* a label. Fixed means the label's tap handler stays out of Semantics, for example `GestureDetector(excludeFromSemantics: true, ...)` (or put the `ExcludeSemantics` outside the `GestureDetector`), so the tree has exactly one node per field. Suggested guard for the test-writer or the human: `expect(tester, meetsGuideline(labeledTapTargetGuideline))` on the split screen.

- `lib/src/split/split_screen.dart:143-164` - **The hand-built text-field node removes the field's editing semantics, and the reason given for it is wrong.** `Semantics(excludeSemantics: true, textField: true, label, value, focused, onTap, onSetText)` replaces the node `EditableText` builds. A screen-reader user loses `textSelection`/cursor position, `setSelection`, move-cursor-by-character/word, cut/copy/paste and `inputType` (the number keyboard). The old `TextField` exposed all of these, and the request says to keep every existing behaviour. The semantic `onTap` is also only `_focus.requestFocus`. On a field that already has focus but whose keyboard was dismissed, that does nothing, so a TalkBack user can't get the keyboard back by double-tapping the field. (`TextField` calls `requestKeyboard`. Sighted users don't hit this, because they tap ShadInput's own gesture detector.)
  The code comment says "a label wrapped around it never joins it". That holds for a bare `Semantics(label:)`, but not for `MergeSemantics`, which spec Decision 4 explicitly allows. I checked against shadcn_ui 0.53.6 in a scratch copy: `MergeSemantics(child: Semantics(label: 'Bill total', child: ShadInput(controller: c, focusNode: f, ...)))` produces **one** node with `flags: isTextField, isFocused`, `label: "Bill total"`, `value: "12"`, `textSelection: [2, 2]`, `actions: moveCursorBackwardByCharacter, setSelection, moveCursorBackwardByWord, setText`. That satisfies the existing "exactly one text-field node" test and keeps the editing actions.
  Fixed means: drop the `ListenableBuilder` and the hand-built node, wrap `ShadInput` in `MergeSemantics` + one `Semantics(label: widget.label)`, and give it a semantic tap that both focuses the field and shows the keyboard. One way is a `GlobalKey<ShadInputState>` and its public `editableTextKey` to call `requestKeyboard()`, with the missing-state case handled explicitly, not with `!`. Then check the tree on the emulator (Dart MCP or `maestro hierarchy`) as the design-system skill asks, and re-run `split_happy_path.yaml`.

- `lib/src/split/split_screen.dart:80-96` - **The button stacks a `Semantics(label: 'Calculate')` over `ShadButton`.** The house rule (CLAUDE.md) and the design-system skill both say not to stack `Semantics(label:)` over a component that already exposes its label, and Decision 4 only allows a wrapper for the fields. The hand-built node also drops ShadButton's `isFocusable` flag and `focus` action, which keyboard and switch-access users rely on. It hard-codes `enabled: true` and copies the `onTap`, so the label and the handler now have two sources of truth. I checked this too: `MergeSemantics(child: ShadButton(onPressed: ..., child: Text('Calculate')))` gives one node with `flags: isButton, hasEnabledState, isEnabled, isFocusable`, `label: "Calculate"`, `actions: focus, tap`. That passes the existing "exactly one button node" test. Fixed means the hand-built `Semantics` is replaced by `MergeSemantics` (or an equivalent that keeps ShadButton's own semantics), with no hand-written label.

## Spec coverage
- Initial values (empty / "2" / "10") - met, `split_screen.dart:22-24`, and tested.
- 100 / 4 / 10 gives "Each person pays 27.50" - met, and tested.
- The three error messages, whitespace, "abc" and "1,000", first failing field wins - met, `_calculate` is unchanged, and all are tested.
- Error to result and result to error replacement - met, and tested.
- Decimal pad for total and tip, whole-number pad for people - met on `EditableText`. The hand-built node does not pass `inputType` to Semantics (see blocker 2).
- `ShadInput` under a visible label, no `TextField` - met.
- `ShadButton` primary, no `FilledButton` or `ElevatedButton` - met.
- `ShadAlert.destructive` with the exact text - met, `split_screen.dart:187`.
- Success in a `ShadCard` with a `ShadTheme` text token (`h3`) - met, `split_screen.dart:189-194`.
- No `Color(0x…)`, `Colors.*` or hand-built `TextStyle` in `split_screen.dart` or `main.dart`, and spacing from one scale in one file - met. The hex seed is gone, `Spacing` lives only in `lib/src/theme.dart`, and every gap and padding uses it.
- Live region for success and failure - met. The dump shows `isLiveRegion` on the result node itself.
- Exactly one Semantics node per label, as a text field - met for labelled nodes, **not met** for "no stray nodes" (blocker 1).
- Tapping the label focuses the field and typing goes into it - met for focus and typing, and tested. Re-showing a dismissed keyboard is not met (blocker 2).
- "Calculate" is one button node - met by the letter, but by a method the house rule forbids (blocker 3).
- `themeMode` parameter, default `ThemeMode.system` - met, `main.dart`.
- Dark and light brightness, and happy path and missing total in dark - met, and tested.
- `theme`/`darkTheme` defined once, both shadcn `blue` (Decision 1) - met, `lib/src/theme.dart:6-14`.
- Material bridge - met by an equivalent. The default `ShadApp` builds a `WidgetsApp` under an `AnimatedTheme` with a Material `ThemeData` built from the shad theme, the Global Material localizations and a `MaterialPageRoute`, so `Scaffold` and `Theme.of` keep working. `ShadApp.debugShowCheckedModeBanner` defaults to false, so dropping that line changes nothing.
- No `AppBar`, and the title uses a ShadTheme heading token (Decision 2) - met.
- System theme change keeps input and result - met. `WidgetsApp` is keyed with `GlobalObjectKey(this)` under `ShadAnimatedTheme`, so the subtree isn't remounted, and the test checks the field text and the result after the animation settles.
- 320x568 with the keyboard open, scrolls to Calculate and the result - met, and tested.
- Text scale 2.0, no overflow - met, but see the heading `FittedBox` suggestion.
- 1e15 wraps without overflow - met, and tested.

## Suggestions (don't block)
- `lib/src/split/split_screen.dart:64-69` - **The heading `FittedBox` only exists to make a test pass.** In a scratch copy I replaced it with a plain `Text`. At scale 2.0 on 320x568, the title wraps to two lines and pushes "Calculate" down to y=654, below the 568 viewport. The `does not overflow at text scale 2.0` test then fails, because it calls `tester.tap(find.text('Calculate'))` without scrolling and the tap misses (only a `warnIfMissed` warning). Nothing overflows. So the `FittedBox` shrinks a title the user asked to enlarge, just to keep the button above the fold for the test. Better: the test scrolls Calculate into view (`ensureVisible` / `scrollUntilVisible` with the page scroller, as the keyboard test already does), and the heading wraps. That is a test-writer change, so it's the human's call.
- `lib/src/split/split_screen.dart:88-95` - **The button `FittedBox` has a real reason.** Without it, the button's row overflows by 12 px at scale 2.0 on a 320-wide screen (measured with the test font). Keep it, or allow the label to wrap instead of scaling down.
- `lib/src/split/split_screen.dart:195-197` - **The `StateError` fits the no-masking rule.** `SplitResult.success(double? perPerson)` lets the type system build a result with neither field, so this branch can be reached only through a programmer error. It fails loudly with a clear message, and that beats the old `result.perPerson!`. A sealed `SplitResult` would make the branch impossible, but that's out of scope here.
- **The three test changes made during the build don't weaken anything.**
  - `nodes.evaluate().single` checks the same `containsSemantics` on the same node, and it's stricter (it fails on more than one node).
  - `scrollable:` is needed because each `ShadInput` brings its own `Scrollable`s. The finder resolves to the page `SingleChildScrollView`'s scrollable, because it comes first in tree order, so the test still proves reachability.
  - `pumpAndSettle` lets `ShadAnimatedTheme` and `AnimatedTheme` finish before checking brightness, and the test still asserts that the input and the result survive.
- `pubspec.lock` - besides shadcn_ui and its transitive packages, the lock moves `characters` (1.4.1 to 1.4.0), `matcher`, `material_color_utilities`, `meta` and `test_api` back to the versions Flutter 3.35.4 pins, and drops the SDK floor from `>=3.10.0-0`. That's the lock re-resolving on the installed SDK, not a new package, but the human should know before merging.
- `lib/src/theme.dart:20` - `Spacing.md` (12) isn't used yet. That's fine, since the spec asks for the whole scale.

## Scope
- Files changed outside the spec's map: `test/unit/split_calculator_test.dart`, which only had one line rewrapped by the formatter, with no change in what it asserts. `split_calculator.dart`, `.maestro/split_happy_path.yaml`, `analysis_options.yaml`, `android/` and `ios/` are unchanged. `CLAUDE.md` and `.claude/skills/design-system/` predate the run and weren't judged.
