/// Why a split could not be calculated. The UI shows a message for each case
/// instead of quietly showing zero.
enum SplitError { invalidTotal, invalidPeople, invalidTip }

/// The outcome of a split: either an amount per person or a reason it failed.
class SplitResult {
  const SplitResult.success(this.perPerson) : error = null;
  const SplitResult.failure(SplitError this.error) : perPerson = null;

  final double? perPerson;
  final SplitError? error;

  bool get isSuccess => error == null;
}

/// Splits a bill evenly, tip included.
///
/// [total] is the bill before tip. [people] must be at least 1.
/// [tipPercent] is a percentage, for example 10 for 10%.
SplitResult splitBill({
  required double total,
  required int people,
  double tipPercent = 0,
}) {
  if (total.isNaN || total <= 0) {
    return const SplitResult.failure(SplitError.invalidTotal);
  }
  if (people < 1) {
    return const SplitResult.failure(SplitError.invalidPeople);
  }
  if (tipPercent.isNaN || tipPercent < 0) {
    return const SplitResult.failure(SplitError.invalidTip);
  }
  final withTip = total * (1 + tipPercent / 100);
  return SplitResult.success(withTip / people);
}
