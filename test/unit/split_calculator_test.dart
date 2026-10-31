import 'package:flutter_test/flutter_test.dart';
import 'package:harness_demo/src/split/split_calculator.dart';

void main() {
  group('splitBill', () {
    test('splits evenly with a tip', () {
      final result = splitBill(total: 100, people: 4, tipPercent: 10);
      expect(result.isSuccess, isTrue);
      expect(result.perPerson, closeTo(27.5, 0.001));
    });

    test('rejects a total of zero', () {
      expect(splitBill(total: 0, people: 2).error, SplitError.invalidTotal);
    });

    test('rejects zero people', () {
      expect(splitBill(total: 50, people: 0).error, SplitError.invalidPeople);
    });

    test('rejects a negative tip', () {
      expect(splitBill(total: 50, people: 2, tipPercent: -5).error, SplitError.invalidTip);
    });
  });
}
