import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/main.dart';
import 'package:harness_demo/src/split/split_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _totalError = 'Enter a bill total above zero';
const _peopleError = 'Enter at least one person';
const _tipError = 'Enter a tip of zero or more';

Future<void> pumpScreen(WidgetTester tester,
    {ThemeMode themeMode = ThemeMode.light}) async {
  await tester.pumpWidget(HarnessDemoApp(themeMode: themeMode));
  await tester.pump();
}

/// The three number inputs, in screen order: Bill total, People, Tip percent.
Finder get _inputs => find.byType(EditableText);

String _textOf(WidgetTester tester, int index) =>
    tester.widget<EditableText>(_inputs.at(index)).controller.text;

/// Taps the visible label, like Maestro's `tapOn`, then types into whatever
/// got focus. If the label is not attached to its field, nothing is typed.
Future<void> typeInto(WidgetTester tester, String label, String text) async {
  await tester.tap(find.text(label));
  await tester.pump();
  tester.testTextInput.enterText(text);
  await tester.pump();
}

Future<void> calculate(WidgetTester tester) async {
  await tester.tap(find.text('Calculate'));
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _alertWith(String message) =>
    find.descendant(of: find.byType(ShadAlert), matching: find.text(message));

ShadThemeData _shadTheme(WidgetTester tester) =>
    ShadTheme.of(tester.element(find.byType(SplitScreen)));

bool _isHeadingToken(ShadTextTheme t, TextStyle? s) {
  if (s == null) return false;
  return [t.h1, t.h2, t.h3, t.h4]
      .any((h) => h.fontSize == s.fontSize && h.fontWeight == s.fontWeight);
}

bool _inLiveRegion(WidgetTester tester, Finder finder) {
  SemanticsNode? node = tester.getSemantics(finder);
  while (node != null) {
    if (containsSemantics(isLiveRegion: true)
        .matches(node, <dynamic, dynamic>{})) {
      return true;
    }
    node = node.parent;
  }
  return false;
}

void main() {
  group('behaviour', () {
    testWidgets('starts with an empty total, 2 people and a 10 percent tip',
        (tester) async {
      await pumpScreen(tester);

      expect(_textOf(tester, 0), isEmpty);
      expect(_textOf(tester, 1), '2');
      expect(_textOf(tester, 2), '10');
    });

    testWidgets('shows the amount each person pays', (tester) async {
      await pumpScreen(tester);

      await typeInto(tester, 'Bill total', '100');
      await typeInto(tester, 'People', '4');
      await typeInto(tester, 'Tip percent', '10');
      await calculate(tester);

      expect(find.text('Each person pays 27.50'), findsOneWidget);
    });

    testWidgets('explains a missing total instead of showing zero',
        (tester) async {
      await pumpScreen(tester);

      await calculate(tester);

      expect(_alertWith(_totalError), findsOneWidget);
    });

    for (final bad in ['', '   ', 'abc', '1,000']) {
      testWidgets('explains a bad total "$bad"', (tester) async {
        await pumpScreen(tester);

        await typeInto(tester, 'Bill total', bad);
        await calculate(tester);

        expect(_alertWith(_totalError), findsOneWidget);
        expect(find.textContaining('Each person pays'), findsNothing);
      });
    }

    for (final bad in ['0', 'abc', '1.5', '', '  ']) {
      testWidgets('explains bad people "$bad"', (tester) async {
        await pumpScreen(tester);

        await typeInto(tester, 'Bill total', '100');
        await typeInto(tester, 'People', bad);
        await calculate(tester);

        expect(_alertWith(_peopleError), findsOneWidget);
        expect(find.textContaining('Each person pays'), findsNothing);
      });
    }

    for (final bad in ['-5', 'abc', '', '  ']) {
      testWidgets('explains a bad tip "$bad"', (tester) async {
        await pumpScreen(tester);

        await typeInto(tester, 'Bill total', '100');
        await typeInto(tester, 'Tip percent', bad);
        await calculate(tester);

        expect(_alertWith(_tipError), findsOneWidget);
        expect(find.textContaining('Each person pays'), findsNothing);
      });
    }

    testWidgets('reports the first failing field: total, then people, then tip',
        (tester) async {
      await pumpScreen(tester);

      await typeInto(tester, 'People', '0');
      await typeInto(tester, 'Tip percent', '-5');
      await calculate(tester);

      expect(_alertWith(_totalError), findsOneWidget);
      expect(find.text(_peopleError), findsNothing);
      expect(find.text(_tipError), findsNothing);
    });

    testWidgets('replaces an error with the result once the input is fixed',
        (tester) async {
      await pumpScreen(tester);

      await calculate(tester);
      expect(_alertWith(_totalError), findsOneWidget);

      await typeInto(tester, 'Bill total', '100');
      await calculate(tester);

      expect(find.text('Each person pays 55.00'), findsOneWidget);
      expect(find.text(_totalError), findsNothing);
      expect(find.byType(ShadAlert), findsNothing);
    });

    testWidgets('replaces a result with the error once the input breaks',
        (tester) async {
      await pumpScreen(tester);

      await typeInto(tester, 'Bill total', '100');
      await calculate(tester);
      expect(find.text('Each person pays 55.00'), findsOneWidget);

      await typeInto(tester, 'Bill total', '');
      await calculate(tester);

      expect(_alertWith(_totalError), findsOneWidget);
      expect(find.textContaining('Each person pays'), findsNothing);
    });

    testWidgets(
        'uses a decimal pad for total and tip, a whole-number pad for people',
        (tester) async {
      await pumpScreen(tester);

      TextInputType keyboard(int i) =>
          tester.widget<EditableText>(_inputs.at(i)).keyboardType;
      expect(keyboard(0), const TextInputType.numberWithOptions(decimal: true));
      expect(
          keyboard(1), const TextInputType.numberWithOptions(decimal: false));
      expect(keyboard(2), const TextInputType.numberWithOptions(decimal: true));
    });
  });

  group('components and tokens', () {
    testWidgets('uses shadcn controls and no Material ones', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(ShadButton), findsOneWidget);
      expect(find.widgetWithText(ShadButton, 'Calculate'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(_inputs, findsNWidgets(3));
    });

    testWidgets('shows the title as a theme heading token', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Split the bill'), findsOneWidget);
      final title = tester.widget<Text>(find.text('Split the bill'));
      expect(
          _isHeadingToken(_shadTheme(tester).textTheme, title.style), isTrue);
    });

    testWidgets('shows the result in a card with a theme text token',
        (tester) async {
      await pumpScreen(tester);

      await typeInto(tester, 'Bill total', '100');
      await typeInto(tester, 'People', '4');
      await calculate(tester);

      final inCard = find.descendant(
        of: find.byType(ShadCard),
        matching: find.text('Each person pays 27.50'),
      );
      expect(inCard, findsOneWidget);
      final line = tester.widget<Text>(inCard);
      expect(_isHeadingToken(_shadTheme(tester).textTheme, line.style), isTrue);
    });

    testWidgets('shows every failure in a destructive alert, not in a card',
        (tester) async {
      await pumpScreen(tester);

      await calculate(tester);

      expect(find.byType(ShadAlert), findsOneWidget);
      expect(find.byType(ShadCard), findsNothing);
    });

    testWidgets('announces a success result as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      await typeInto(tester, 'Bill total', '100');
      await calculate(tester);

      expect(
          _inLiveRegion(tester, find.text('Each person pays 55.00')), isTrue);
      handle.dispose();
    });

    testWidgets('announces a failure as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      await calculate(tester);

      expect(_inLiveRegion(tester, find.text(_totalError)), isTrue);
      handle.dispose();
    });
  });

  group('labels reach Semantics', () {
    for (final label in ['Bill total', 'People', 'Tip percent']) {
      testWidgets('"$label" is exactly one text-field node', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester);

        final nodes = find.semantics.byLabel(label);
        expect(nodes, findsOneWidget);
        expect(nodes.evaluate().single, containsSemantics(isTextField: true));
        handle.dispose();
      });
    }

    testWidgets('"Calculate" is exactly one button node', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester);

      final nodes = find.semantics.byLabel('Calculate');
      expect(nodes, findsOneWidget);
      expect(nodes.evaluate().single, containsSemantics(isButton: true));
      handle.dispose();
    });

    testWidgets('has no unlabelled tap targets, empty and after a calculation',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, themeMode: ThemeMode.light);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await typeInto(tester, 'Bill total', '100');
      await calculate(tester);
      expect(find.text('Each person pays 55.00'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    for (final entry
        in {'Bill total': 0, 'People': 1, 'Tip percent': 2}.entries) {
      testWidgets('tapping "${entry.key}" focuses its field', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text(entry.key));
        await tester.pump();

        for (var i = 0; i < 3; i++) {
          final focused =
              tester.widget<EditableText>(_inputs.at(i)).focusNode.hasFocus;
          expect(focused, i == entry.value,
              reason: 'field $i focus after tapping ${entry.key}');
        }
      });
    }

    testWidgets(
        'typing after tapping "Bill total" goes into the Bill total field',
        (tester) async {
      await pumpScreen(tester);

      await typeInto(tester, 'Bill total', '42');

      expect(_textOf(tester, 0), '42');
      expect(_textOf(tester, 1), '2');
      expect(_textOf(tester, 2), '10');
    });
  });

  group('themes', () {
    testWidgets('light mode uses the light blue scheme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      final theme = _shadTheme(tester);
      expect(theme.brightness, Brightness.light);
      expect(
          theme.colorScheme.primary, const ShadBlueColorScheme.light().primary);
    });

    testWidgets('dark mode uses the dark blue scheme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);

      final theme = _shadTheme(tester);
      expect(theme.brightness, Brightness.dark);
      expect(
          theme.colorScheme.primary, const ShadBlueColorScheme.dark().primary);
    });

    testWidgets('dark mode still shows the result', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);

      await typeInto(tester, 'Bill total', '100');
      await typeInto(tester, 'People', '4');
      await calculate(tester);

      expect(find.text('Each person pays 27.50'), findsOneWidget);
    });

    testWidgets('dark mode still explains a missing total', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);

      await calculate(tester);

      expect(_alertWith(_totalError), findsOneWidget);
    });

    testWidgets('follows the system theme by default', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(const HarnessDemoApp());
      await tester.pump();

      expect(_shadTheme(tester).brightness, Brightness.dark);
    });

    testWidgets('re-themes on a system change without losing input or result',
        (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(const HarnessDemoApp());
      await tester.pump();

      await typeInto(tester, 'Bill total', '100');
      await calculate(tester);
      expect(_shadTheme(tester).brightness, Brightness.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      expect(_shadTheme(tester).brightness, Brightness.dark);
      expect(_textOf(tester, 0), '100');
      expect(find.text('Each person pays 55.00'), findsOneWidget);
    });
  });

  group('small screens and large text', () {
    testWidgets('wraps a very long result without overflowing a small screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpScreen(tester);

      await typeInto(tester, 'Bill total', '1e15');
      await typeInto(tester, 'People', '1');
      await calculate(tester);

      expect(find.textContaining('Each person pays'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'keeps Calculate and the result reachable with the keyboard open',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.reset);
      await pumpScreen(tester);

      final pageScroller = find
          .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(find.text('Calculate'), 100,
          scrollable: pageScroller);
      await calculate(tester);
      await tester.scrollUntilVisible(find.text(_totalError), 100,
          scrollable: pageScroller);

      expect(_alertWith(_totalError), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('does not overflow at text scale 2.0 in $mode with a result',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpScreen(tester, themeMode: mode);

        await typeInto(tester, 'Bill total', '100');
        await calculate(tester);
        expect(tester.takeException(), isNull);

        await typeInto(tester, 'Bill total', '');
        await calculate(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(_totalError), findsOneWidget);
      });
    }
  });
}
