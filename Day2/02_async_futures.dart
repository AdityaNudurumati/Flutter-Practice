// =============================================================================
// Day 2 · Part 2 — Async Programming (Future, async, await)
// Run: dart run Day2/02_async_futures.dart
// =============================================================================
//
// Goal: understand the event loop model, Future states, async/await vs
// .then(), running futures in parallel (Future.wait), and error handling.
// This is the #1 async topic in Flutter (network calls, file I/O, etc.).
//
// MENTAL MODEL: Dart is single-threaded with an EVENT LOOP. async code does
// not run on another thread — it SUSPENDS at `await` and lets the loop do
// other work, then RESUMES when the Future completes.
// =============================================================================

import 'dart:async';

Future<void> main() async {
  print('1. main start');

  // 1. await pauses THIS function until the Future completes, then resumes.
  final user = await fetchUser(1);
  print('2. got $user');

  // 2. .then() is the callback form (no await). Same Future, different style.
  fetchUser(2).then((u) => print('3. then-style got $u'));

  // 3. Run independent futures IN PARALLEL with Future.wait — total time is the
  //    SLOWEST one, not the sum. (vs awaiting them one-by-one = sum of times.)
  final sw = Stopwatch()..start();
  final results = await Future.wait([fetchUser(10), fetchUser(11), fetchUser(12)]);
  print('4. parallel results $results in ${sw.elapsedMilliseconds}ms (~100, not 300)');

  // 4. Error handling with try/catch around await (reads like sync code).
  try {
    await fetchUser(-1);
  } catch (e) {
    print('5. caught: $e');
  }

  // 5. The .catchError() form for the callback style.
  fetchUser(-2).catchError((e) {
    print('6. catchError: $e');
    return 'fallback-user';
  });

  // 6. Future.delayed is how you simulate latency / schedule later work.
  await Future.delayed(Duration(milliseconds: 50));

  // 7. [GOTCHA] microtask vs event queue ordering. Synchronous code runs first,
  //    then microtasks (scheduleMicrotask / completed-future callbacks),
  //    then timers/events. So this prints AFTER all the sync prints above.
  scheduleMicrotask(() => print('7. microtask'));

  print('8. main end (sync) — note 7 prints after this');
}

// A Future has 3 states: uncompleted -> completed-with-value OR completed-with-error.
// `async` makes a function return a Future automatically; `return x` completes it.
Future<String> fetchUser(int id) async {
  await Future.delayed(Duration(milliseconds: 100)); // simulate network
  if (id < 0) {
    throw StateError('invalid id: $id'); // completes the Future with an error
  }
  return 'User#$id';
}
