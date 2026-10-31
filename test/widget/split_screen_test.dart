import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/src/split/split_screen.dart';

Future<void> pumpScreen(WidgetTester tester) {
  return tester.pumpWidget(const MaterialApp(home: SplitScreen()));
}

void main() {
  testWidgets('shows the amount each person pays', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Bill total'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'People'), '4');
    await tester.enterText(find.widgetWithText(TextField, 'Tip percent'), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Calculate'));
    await tester.pump();

    expect(find.text('Each person pays 27.50'), findsOneWidget);
  });

  testWidgets('explains a missing total instead of showing zero', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Calculate'));
    await tester.pump();

    expect(find.text('Enter a bill total above zero'), findsOneWidget);
  });
}
