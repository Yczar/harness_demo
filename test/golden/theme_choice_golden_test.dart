@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/main.dart';
import 'package:harness_demo/src/split/split_screen.dart';

// The builder can never create or update these files. Only the human does,
// with .claude/harness/accept-goldens.sh, after looking at them.

void main() {
  testWidgets('split screen with Dark chosen in the Theme section',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const HarnessDemoApp(themeMode: ThemeMode.light));
    await tester.pump();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SplitScreen),
      matchesGoldenFile('goldens/split_screen_theme_dark_chosen.png'),
    );
  });
}
