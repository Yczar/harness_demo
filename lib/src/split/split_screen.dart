import 'package:flutter/material.dart';

import 'split_calculator.dart';

/// One screen: bill total, number of people, tip, and the amount each person pays.
///
/// Every interactive widget exposes a clear label to the Semantics tree (the
/// field's labelText, the button's text). Device tests (Maestro, Patrol) find
/// widgets through the Semantics tree, not through widget keys, so these labels
/// are part of the contract. Don't wrap them in extra Semantics labels: that
/// produces duplicated labels that device tests can't match.
class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Split the bill')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _NumberField(controller: _total, label: 'Bill total', decimal: true),
          const SizedBox(height: 16),
          _NumberField(controller: _people, label: 'People', decimal: false),
          const SizedBox(height: 16),
          _NumberField(controller: _tip, label: 'Tip percent', decimal: true),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _calculate,
            child: const Text('Calculate'),
          ),
          const SizedBox(height: 32),
          if (result != null) _ResultView(result: result),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, required this.decimal});

  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final SplitResult result;

  @override
  Widget build(BuildContext context) {
    final error = result.error;
    final text = error == null
        ? 'Each person pays ${result.perPerson!.toStringAsFixed(2)}'
        : switch (error) {
            SplitError.invalidTotal => 'Enter a bill total above zero',
            SplitError.invalidPeople => 'Enter at least one person',
            SplitError.invalidTip => 'Enter a tip of zero or more',
          };
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: error == null ? null : Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}
