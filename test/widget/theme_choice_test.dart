import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/main.dart';
import 'package:harness_demo/src/split/split_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _options = ['System', 'Light', 'Dark'];

Future<void> pumpApp(WidgetTester tester,
    {ThemeMode themeMode = ThemeMode.system}) async {
  await tester.pumpWidget(HarnessDemoApp(themeMode: themeMode));
  await tester.pump();
}

Brightness _brightness(WidgetTester tester) =>
    ShadTheme.of(tester.element(find.byType(SplitScreen))).brightness;

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Which of System / Light / Dark are reported as checked, by Semantics.
List<String> _checked(WidgetTester tester) {
  final chosen = <String>[];
  for (final label in _options) {
    final nodes = find.semantics.byLabel(label);
    expect(nodes, findsOneWidget, reason: '"$label" must be exactly one node');
    final node = nodes.evaluate().single;
    expect(
        node,
        containsSemantics(
            hasCheckedState: true, hasTapAction: true, label: label));
    if (containsSemantics(isChecked: true)
        .matches(node, <dynamic, dynamic>{})) {
      chosen.add(label);
    }
  }
  return chosen;
}

Future<void> _typeInto(WidgetTester tester, String label, String text) async {
  await tester.tap(find.text(label));
  await tester.pump();
  tester.testTextInput.enterText(text);
  await tester.pump();
}

Future<void> _calculate(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Calculate'));
  await tester.pump();
  await tester.tap(find.text('Calculate'));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('the Theme section', () {
    testWidgets('shows a Theme heading with System, Light and Dark',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Theme'), findsOneWidget);
      for (final label in _options) {
        await tester.ensureVisible(find.text(label));
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('is placed below the result area and Calculate',
        (tester) async {
      await pumpApp(tester);

      final calculateY = tester.getTopLeft(find.text('Calculate')).dy;
      final themeY = tester.getTopLeft(find.text('Theme')).dy;
      expect(themeY, greaterThan(calculateY));
    });

    testWidgets('starts with only System chosen on a fresh launch',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);

      expect(_checked(tester), ['System']);
      handle.dispose();
    });

    testWidgets('uses three ShadRadio options and adds no buttons or inputs',
        (tester) async {
      await pumpApp(tester);

      expect(find.byType(ShadRadioGroup), findsWidgets);
      expect(find.byType(ShadButton), findsOneWidget);
      expect(find.byType(EditableText), findsNWidgets(3));
    });

    for (final entry in {
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
    }.entries) {
      testWidgets('starts on ${entry.value} when themeMode is ${entry.key}',
          (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester, themeMode: entry.key);

        expect(_checked(tester), [entry.value]);
        handle.dispose();
      });
    }
  });

  group('choosing a theme', () {
    testWidgets('System follows a dark platform', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);

      expect(_brightness(tester), Brightness.dark);
    });

    testWidgets('System follows a light platform', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);

      expect(_brightness(tester), Brightness.light);
    });

    testWidgets('tapping Dark switches to the dark scheme and checks only Dark',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);

      await _choose(tester, 'Dark');

      expect(_brightness(tester), Brightness.dark);
      expect(
          ShadTheme.of(tester.element(find.byType(SplitScreen)))
              .colorScheme
              .primary,
          const ShadBlueColorScheme.dark().primary);
      expect(_checked(tester), ['Dark']);
      handle.dispose();
    });

    testWidgets(
        'tapping Light switches to the light scheme and checks only Light',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);

      await _choose(tester, 'Light');

      expect(_brightness(tester), Brightness.light);
      expect(_checked(tester), ['Light']);
      handle.dispose();
    });

    testWidgets('Light stays light when the platform turns dark',
        (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);
      await _choose(tester, 'Light');

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      expect(_brightness(tester), Brightness.light);
    });

    testWidgets('Dark stays dark when the platform turns light',
        (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);
      await _choose(tester, 'Dark');

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(_brightness(tester), Brightness.dark);
    });

    testWidgets('going from Dark back to System follows the platform again',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);
      await _choose(tester, 'Dark');
      expect(_brightness(tester), Brightness.dark);

      await _choose(tester, 'System');
      expect(_brightness(tester), Brightness.light);
      expect(_checked(tester), ['System']);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(_brightness(tester), Brightness.dark);
      handle.dispose();
    });

    testWidgets('tapping the option already chosen changes nothing',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, themeMode: ThemeMode.dark);

      await _choose(tester, 'Dark');

      expect(_brightness(tester), Brightness.dark);
      expect(_checked(tester), ['Dark']);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('several taps in a row: the last option wins', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);

      await _choose(tester, 'Dark');
      await _choose(tester, 'Light');
      await _choose(tester, 'Dark');
      await _choose(tester, 'Light');

      expect(_brightness(tester), Brightness.light);
      expect(_checked(tester), ['Light']);
      handle.dispose();
    });

    testWidgets('a new app instance starts on System again', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);
      await _choose(tester, 'Dark');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const HarnessDemoApp());
      await tester.pump();

      expect(_checked(tester), ['System']);
      handle.dispose();
    });
  });

  group('changing the theme keeps the screen state', () {
    testWidgets('keeps the typed total and the result', (tester) async {
      await pumpApp(tester, themeMode: ThemeMode.light);
      await _typeInto(tester, 'Bill total', '100');
      await _calculate(tester);
      expect(find.text('Each person pays 55.00'), findsOneWidget);

      await _choose(tester, 'Dark');

      expect(_brightness(tester), Brightness.dark);
      expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          '100');
      expect(find.text('Each person pays 55.00'), findsOneWidget);
    });

    testWidgets('keeps an error message', (tester) async {
      await pumpApp(tester, themeMode: ThemeMode.light);
      await _calculate(tester);
      expect(find.text('Enter a bill total above zero'), findsOneWidget);

      await _choose(tester, 'Dark');

      expect(find.text('Enter a bill total above zero'), findsOneWidget);
    });

    testWidgets('keeps a focused field focused', (tester) async {
      await pumpApp(tester, themeMode: ThemeMode.light);
      await tester.tap(find.text('People'));
      await tester.pump();
      bool peopleFocused() => tester
          .widget<EditableText>(find.byType(EditableText).at(1))
          .focusNode
          .hasFocus;
      expect(peopleFocused(), isTrue);

      await _choose(tester, 'Dark');

      expect(peopleFocused(), isTrue);
    });
  });

  group('Semantics', () {
    for (final label in _options) {
      testWidgets('"$label" is exactly one node with label, checked and tap',
          (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester);

        final nodes = find.semantics.byLabel(label);
        expect(nodes, findsOneWidget);
        expect(
            nodes.evaluate().single,
            containsSemantics(
              label: label,
              hasCheckedState: true,
              isInMutuallyExclusiveGroup: true,
              hasTapAction: true,
            ));
        handle.dispose();
      });
    }

    testWidgets('the Theme heading is its own node, separate from the options',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);

      final nodes = find.semantics.byLabel('Theme');
      expect(nodes, findsOneWidget);
      final node = nodes.evaluate().single;
      expect(node.label, 'Theme');
      for (final label in _options) {
        expect(node.label, isNot(contains(label)));
      }
      handle.dispose();
    });

    testWidgets('has no unlabelled tap targets', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, themeMode: ThemeMode.light);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await _choose(tester, 'Dark');
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('small screens and large text', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('does not overflow at 320x568, text scale 2.0, $mode',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(tester, themeMode: mode);

        expect(find.text('Theme'), findsOneWidget);
        await tester.ensureVisible(find.text('Dark'));
        await tester.pump();
        expect(tester.takeException(), isNull);

        await _calculate(tester);
        expect(find.text('Enter a bill total above zero'), findsOneWidget);
        await _choose(tester, 'System');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
