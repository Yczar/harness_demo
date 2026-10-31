---
name: no-error-masking
description: The Dart patterns that hide failures instead of surfacing them, and what to write instead. Use when writing or reviewing Dart code.
---

# Don't hide failures

Error masking is code that turns a failure into a quiet wrong answer. The app doesn't crash, it just shows the wrong screen. AI-written code does this more and more, and it gets past tired reviewers. Each pattern below is either blocked by a lint or flagged by the reviewer.

## `?? ''` and other fake defaults
```dart
// Hides missing data. The user sees an empty name and nobody knows why.
final name = user?.profile?.name ?? '';

// Make the missing case explicit and show it.
final name = user?.profile?.name;
if (name == null) return const MissingProfileView();
```
A default is fine when it's a real product decision ("no tip means 0%"). Write down why next to it.

## `!` without a guarantee
```dart
final count = cart!.items.length;   // crashes later, somewhere confusing
```
Use `!` only where the line above it guarantees the value (a check, or a `late` you control). Otherwise handle the null.

## Empty or catch-all `catch`
```dart
try { await syncOrders(); } catch (_) {}   // blocked: empty_catches

try {
  await syncOrders();
} on SocketException catch (e, s) {
  log.warning('Order sync failed, will retry', e, s);
  showRetryBanner();
}
```
Catch the specific exception you expect (`avoid_catches_without_on_clauses` is an error here), and either recover visibly or rethrow.

## Results that can't fail
If something can fail, its type should say so. Return a result type (see `SplitResult` in `lib/src/split/`) and make the UI handle every case. A `switch` over an enum makes the compiler point out a missing case.

## Futures nobody waits for
`unawaited_futures` is an error. If you really mean fire-and-forget, wrap it in `unawaited(...)` and say why.
