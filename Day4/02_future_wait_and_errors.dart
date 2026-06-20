// =============================================================================
// Day 4 · Part 2 — Future.wait (parallel) + error handling
// Run: dart run Day4/02_future_wait_and_errors.dart
// =============================================================================
//
// - Future.wait([...]) runs futures IN PARALLEL: total time = the SLOWEST one,
//   not the sum. Critical for fast screens (fetch user + posts + settings
//   together instead of one after another).
// - Error handling: try/catch around await (sync style) OR .then().catchError()
//   (callback style). `.timeout()` bounds how long you'll wait.
// =============================================================================

import 'dart:async';

Future<void> main() async {
  // 1. PARALLEL with Future.wait — three 100ms calls finish in ~100ms.
  final sw = Stopwatch()..start();
  final results = await Future.wait([fetchUser(1), fetchUser(2), fetchUser(3)]);
  print('1. parallel $results in ${sw.elapsedMilliseconds}ms (~100, not 300)');

  // 2. try/catch around await — reads like synchronous error handling.
  try {
    await fetchUser(-1); // throws inside the async function
  } catch (e) {
    print('2. caught: $e');
  }

  // 3. .then() / .catchError() — the callback form. .whenComplete() ~ finally.
  await fetchUser(99)
      .then((u) => print('3. then got $u'))
      .catchError((e) => print('3. catchError: $e'))
      .whenComplete(() => print('3. whenComplete (always runs)'));

  // 4. [GOTCHA] Future.wait fails fast: if ANY future errors, the combined
  //    Future errors. Use eagerError / individual catches to control this.
  try {
    await Future.wait([fetchUser(5), fetchUser(-2), fetchUser(6)]);
  } catch (e) {
    print('4. Future.wait surfaced the first error: $e');
  }

  // 5. .timeout() — give up if a Future takes too long (e.g. slow network).
  try {
    await slowCall().timeout(const Duration(milliseconds: 150));
  } on TimeoutException {
    print('5. timed out — slowCall took too long');
  }

  // 6. Recover per-future so one failure doesn't sink the whole batch.
  final safe = await Future.wait([
    fetchUser(7),
    fetchUser(-3).catchError((_) => 'fallback-user'),
  ]);
  print('6. resilient batch: $safe');
}

Future<String> fetchUser(int id) async {
  await Future.delayed(const Duration(milliseconds: 100));
  if (id < 0) throw StateError('invalid id: $id');
  return 'User#$id';
}

Future<String> slowCall() async {
  await Future.delayed(const Duration(milliseconds: 400));
  return 'finally done';
}
