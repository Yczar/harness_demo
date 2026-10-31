@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/src/split/split_screen.dart';

void main() {
  testWidgets('split screen after a calculation', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SplitScreen()));
    await tester.enterText(find.widgetWithText(TextField, 'Bill total'), '100');
    await tester.tap(find.widgetWithText(FilledButton, 'Calculate'));
    await tester.pump();

    // The builder can never create or update this file. Only the human does,
    // with .claude/harness/accept-goldens.sh, after looking at it.
    await expectLater(find.byType(SplitScreen), matchesGoldenFile('goldens/split_screen.png'));
  });
}
