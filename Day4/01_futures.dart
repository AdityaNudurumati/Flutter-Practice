// =============================================================================
// Day 4 · Part 1 — Futures, async, await, Future.delayed
// Run: dart run Day4/01_futures.dart
// =============================================================================
//
// A FUTURE is ONE value that arrives later. This is the backbone of every
// Flutter API call, Firebase read, DB query, and file operation.
//
// MENTAL MODEL: Dart is single-threaded with an EVENT LOOP. `async` code does
// NOT run on another thread — at `await` it SUSPENDS, lets the loop do other
// work, and RESUMES when the Future completes.
// =============================================================================

import 'dart:async';

Future<void> main() async {
  print('1. main start (synchronous)');

  // 1. await unwraps a Future's value and pauses until it's ready.
  final user = await fetchUser(1);
  print('2. got $user');

  // 2. Future.delayed = schedule a value/work after a duration (fake latency).
  final msg = await Future.delayed(
    const Duration(milliseconds: 100),
    () => 'delayed hello',
  );
  print('3. $msg');

  // 3. Future.value / Future.error — create already-completed futures.
  print('4. ${await Future.value(42)}');

  // 4. SEQUENTIAL awaits run one after another -> total = sum of times.
  final sw = Stopwatch()..start();
  final a = await fetchUser(10);
  final b = await fetchUser(11);
  print('5. sequential [$a, $b] took ${sw.elapsedMilliseconds}ms (~200)');

  // 5. An async function ALWAYS returns a Future. `return x` completes it; a
  //    `throw` completes it with an error (see file 02 for handling).
  print('6. doubled = ${await doubleAfterDelay(21)}');

  print('7. main end');
}

// `async` marks a function returning a Future; `await` is only legal inside it.
// A Future has 3 states: uncompleted -> completed-with-value OR -with-error.
Future<String> fetchUser(int id) async {
  await Future.delayed(const Duration(milliseconds: 100)); // simulate network
  return 'User#$id';
}

Future<int> doubleAfterDelay(int n) async {
  await Future.delayed(const Duration(milliseconds: 50));
  return n * 2;
}
