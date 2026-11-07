import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme.dart';
import '../theme_choice/theme_choice.dart';
import '../theme_choice/theme_choice_section.dart';
import 'split_calculator.dart';

/// One screen: bill total, number of people, tip, and the amount each person pays.
///
/// Every interactive widget exposes a clear label to the Semantics tree (the
/// button's text, and each field's visible label). Device tests (Maestro,
/// Patrol) find widgets through the Semantics tree, not through widget keys, so
/// these labels are part of the contract. shadcn's field label is not attached
/// to its input, so [_NumberField] attaches it with a single Semantics label.
class SplitScreen extends StatefulWidget {
  const SplitScreen(
      {super.key,
      required this.themeChoice,
      required this.onThemeChoiceChanged});

  final ThemeChoice themeChoice;
  final ValueChanged<ThemeChoice> onThemeChoiceChanged;

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final _total = TextEditingController();
  final _people = TextEditingController(text: '2');
  final _tip = TextEditingController(text: '10');

  SplitResult? _result;

  void _calculate() {
    final total = double.tryParse(_total.text.trim());
    final people = int.tryParse(_people.text.trim());
    final tip = double.tryParse(_tip.text.trim());
    setState(() {
      if (total == null) {
        _result = const SplitResult.failure(SplitError.invalidTotal);
      } else if (people == null) {
        _result = const SplitResult.failure(SplitError.invalidPeople);
      } else if (tip == null) {
        _result = const SplitResult.failure(SplitError.invalidTip);
      } else {
        _result = splitBill(total: total, people: people, tipPercent: tip);
      }
    });
  }

  @override
  void dispose() {
    _total.dispose();
    _people.dispose();
    _tip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final theme = ShadTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scales down instead of wrapping over many lines at huge text sizes.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Split the bill', style: theme.textTheme.h3),
              ),
              const SizedBox(height: Spacing.xl),
              _NumberField(
                  controller: _total, label: 'Bill total', decimal: true),
              const SizedBox(height: Spacing.lg),
              _NumberField(
                  controller: _people, label: 'People', decimal: false),
              const SizedBox(height: Spacing.lg),
              _NumberField(
                  controller: _tip, label: 'Tip percent', decimal: true),
              const SizedBox(height: Spacing.xl),
              // Merged so ShadButton's role node and its text node become one.
              MergeSemantics(
                child: ShadButton(
                  onPressed: _calculate,
                  // Scales down instead of overflowing at very large text sizes.
                  child: Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      // The role flag goes on the text's own node too, so the
                      // node that carries the label is also the button node.
                      child: Semantics(
                          button: true, child: const Text('Calculate')),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xxl),
              if (result != null) ...[
                _ResultView(result: result),
                const SizedBox(height: Spacing.xxl),
              ],
              ThemeChoiceSection(
                choice: widget.themeChoice,
                onChanged: widget.onThemeChoiceChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField(
      {required this.controller, required this.label, required this.decimal});

  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  final _focus = FocusNode();
  final _input = GlobalKey<ShadInputState>();

  /// A semantic tap focuses the field and brings back a dismissed keyboard.
  void _activate() {
    _focus.requestFocus();
    final editable = _input.currentState?.editableTextKey.currentState;
    if (editable == null) {
      throw StateError('${widget.label} field has no editable text to focus');
    }
    editable.requestKeyboard();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The visible label focuses its field when tapped. It stays out of
        // Semantics: the field's own node carries the one label.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: _activate,
          child: ExcludeSemantics(
              child: Text(widget.label, style: theme.textTheme.small)),
        ),
        const SizedBox(height: Spacing.sm),
        // shadcn's label is not attached to its input. MergeSemantics folds this
        // label into the input's own node, which keeps its editing actions.
        MergeSemantics(
          child: Semantics(
            label: widget.label,
            onTap: _activate,
            child: ShadInput(
              key: _input,
              controller: widget.controller,
              focusNode: _focus,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: widget.decimal),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final SplitResult result;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final error = result.error;
    final perPerson = result.perPerson;
    final Widget content;
    if (error != null) {
      final message = switch (error) {
        SplitError.invalidTotal => 'Enter a bill total above zero',
        SplitError.invalidPeople => 'Enter at least one person',
        SplitError.invalidTip => 'Enter a tip of zero or more',
      };
      content = ShadAlert.destructive(description: Text(message));
    } else if (perPerson != null) {
      content = ShadCard(
        child: Text(
          'Each person pays ${perPerson.toStringAsFixed(2)}',
          style: theme.textTheme.h3,
        ),
      );
    } else {
      throw StateError('SplitResult has neither an error nor an amount');
    }
    return Semantics(liveRegion: true, child: content);
  }
}
