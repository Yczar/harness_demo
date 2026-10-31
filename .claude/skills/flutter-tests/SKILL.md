---
name: flutter-tests
description: How tests are written in this Flutter project - unit, widget, golden and Maestro device flows, and why visible labels matter. Use when writing or reviewing tests.
---

# Tests in this project

## Layout
- `test/unit/` for pure Dart logic, with no widgets.
- `test/widget/` for one screen or widget at a time, pumped inside a `MaterialApp`.
- `test/golden/` for pixel comparisons. Every file starts with `@Tags(['golden'])` and `library;`. Goldens live in `test/golden/goldens/`.
- `.maestro/` for device flows on a real simulator or emulator.

## Find widgets the way a user does
Use what's on screen: `find.widgetWithText(TextField, 'Bill total')`, `find.widgetWithText(FilledButton, 'Calculate')`, `find.text(...)`. Avoid `find.byKey` for anything a user interacts with.

The reason: device tools like Maestro and mobile-mcp only see the Semantics tree. They can't see widget keys. If a widget has no clear visible label, an agent driving the app on a device can't find it, and on Flutter Web its taps fail silently. A good label serves the user, the widget test and the device test at once.

Don't wrap widgets that already have a label (a TextField's `labelText`, a button's text) in another `Semantics(label: ...)`. Stacked labels merge into one string that neither Maestro nor `find.bySemanticsLabel` can match.

## Goldens
- Fix the size: set `tester.view.physicalSize` and `devicePixelRatio`, and reset them in `addTearDown`.
- Compare the screen widget, not the whole app: `find.byType(MyScreen)`.
- Agents never create or update golden files. A new golden test fails with "non-existent file" until the human looks at the UI and runs `.claude/harness/accept-goldens.sh`. The checks report that as waiting for the human, not as a failure.

## Maestro flows
```yaml
appId: com.example.harness_demo
---
- launchApp
- tapOn: "Bill total"      # the field's visible label
- inputText: "100"
- tapOn: "Calculate"
- assertVisible: "Each person pays 50.00"
```

## A good test
- One behaviour per test, named after that behaviour: `'explains a missing total instead of showing zero'`.
- It fails for the right reason before the code exists.
- It checks what the user sees, not private state.
