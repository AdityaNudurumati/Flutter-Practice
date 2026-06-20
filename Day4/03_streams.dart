// =============================================================================
// Day 4 · Part 3 — Streams
// Run: dart run Day4/03_streams.dart
// =============================================================================
//
// A Future = ONE async value. A Stream = a SEQUENCE of async values over time
// (0..N). Consume with `await for` or `.listen()`. Flutter's StreamBuilder,
// BLoC, Firebase snapshots, and many plugins are Stream-based.
//
// SINGLE-SUBSCRIPTION (default): exactly one listener.
// BROADCAST: many simultaneous listeners (.asBroadcastStream / broadcast ctrl).
// =============================================================================

import 'dart:async';

Future<void> main() async {
  // 1. async* + yield builds a stream (a generator), emitting one value at a time.
  print('--- await for ---');
  await for (final n in countStream(3)) {
    print('tick $n'); // 1, 2, 3 (100ms apart)
  }

  // 2. Transformations are LAZY & chainable, just like Iterable methods.
  print('--- map / where / take ---');
  final pipeline = countStream(10).where((n) => n.isEven).map((n) => n * 10).take(3);
  print(await pipeline.toList()); // [20, 40, 60]

  // 3. .listen() — callback form with onData / onError / onDone hooks.
  print('--- listen ---');
  final done = Completer<void>();
  countStream(3).listen(
    (n) => print('data $n'),
    onError: (e) => print('error $e'),
    onDone: () {
      print('done!');
      done.complete();
    },
  );
  await done.future;

  // 4. Reducers return a Future<single value>.
  print('--- reducers ---');
  print('sum   = ${await countStream(4).fold(0, (acc, n) => acc + n)}'); // 10
  print('count = ${await countStream(4).length}'); // 4
  print('first = ${await countStream(4).first}'); // 1

  // 5. BROADCAST: multiple listeners on the same stream.
  print('--- broadcast (2 listeners) ---');
  final bc = countStream(3).asBroadcastStream();
  bc.listen((n) => print('A got $n'));
  bc.listen((n) => print('B got $n'));
  await bc.drain<void>(); // wait until it's done
}

// async* generator. `yield` emits one value; the function pauses there and
// resumes when the consumer pulls the next value.
Stream<int> countStream(int n) async* {
  for (var i = 1; i <= n; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
    yield i;
  }
}
