@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/main.dart';
import 'package:harness_demo/src/split/split_screen.dart';

// The builder can never create or update these files. Only the human does,
// with .claude/harness/accept-goldens.sh, after looking at them.

Future<void> _pump(WidgetTester tester, ThemeMode mode) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(HarnessDemoApp(themeMode: mode));
  await tester.pump();
}

Future<void> _showSuccess(WidgetTester tester) async {
  await tester.tap(find.text('Bill total'));
  await tester.pump();
  tester.testTextInput.enterText('100');
  await tester.pump();
  await tester.tap(find.text('Calculate'));
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Each person pays 55.00'), findsOneWidget);
}

Future<void> _showMissingTotal(WidgetTester tester) async {
  await tester.tap(find.text('Calculate'));
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Enter a bill total above zero'), findsOneWidget);
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = mode.name;

    testWidgets('split screen success, $name', (tester) async {
      await _pump(tester, mode);
      await _showSuccess(tester);
      await expectLater(
        find.byType(SplitScreen),
        matchesGoldenFile('goldens/split_screen_success_$name.png'),
      );
    });

    testWidgets('split screen error, $name', (tester) async {
      await _pump(tester, mode);
      await _showMissingTotal(tester);
      await expectLater(
        find.byType(SplitScreen),
        matchesGoldenFile('goldens/split_screen_error_$name.png'),
      );
    });
  }
}
