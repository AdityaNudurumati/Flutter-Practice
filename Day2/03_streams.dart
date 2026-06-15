// =============================================================================
// Day 2 · Part 3 — Streams
// Run: dart run Day2/03_streams.dart
// =============================================================================
//
// Goal: a Future = ONE async value; a Stream = a SEQUENCE of async values over
// time (0..N). You consume a Stream with `await for` or `.listen()`. Flutter's
// StreamBuilder, BLoC, and many plugins (sensors, sockets) are Stream-based.
//
// SINGLE-SUBSCRIPTION (default, e.g. file reads) — one listener, once.
// BROADCAST (.asBroadcastStream / StreamController.broadcast) — many listeners.
// =============================================================================

import 'dart:async';

Future<void> main() async {
  // 1. async* + yield builds a Stream that emits values one at a time.
  print('--- await for ---');
  await for (final n in countStream(3)) {
    print('tick $n'); // tick 1, tick 2, tick 3 (100ms apart)
  }

  // 2. Stream transformations are LAZY & chainable, like Iterable methods.
  print('--- map / where ---');
  final doubledEvens = countStream(5).where((n) => n.isEven).map((n) => n * 10);
  await for (final v in doubledEvens) {
    print(v); // 20, 40
  }

  // 3. .listen() is the callback form — gives you onData/onError/onDone.
  print('--- listen ---');
  final done = Completer<void>();
  countStream(3).listen(
    (n) => print('listened $n'),
    onError: (e) => print('err $e'),
    onDone: () {
      print('done!');
      done.complete();
    },
  );
  await done.future; // wait for the subscription to finish for demo ordering

  // 4. StreamController = a manual Stream you push events into (sink side).
  //    This is the basis of BLoC: UI listens to .stream, logic adds to .sink.
  print('--- StreamController ---');
  final controller = StreamController<String>();
  controller.stream.listen((msg) => print('event: $msg'));
  controller.add('hello');
  controller.add('world');
  await controller.close(); // triggers onDone; always close to avoid leaks.

  // 5. Useful reducers that return a Future<single value>.
  print('--- reducers ---');
  print('sum = ${await countStream(4).fold(0, (acc, n) => acc + n)}'); // 10
  print('count = ${await countStream(4).length}'); // 4
  print('first = ${await countStream(4).first}'); // 1
}

// async* = a "generator" function returning a Stream. `yield` emits one value;
// the function pauses there and resumes on the next pull from the consumer.
Stream<int> countStream(int n) async* {
  for (var i = 1; i <= n; i++) {
    await Future.delayed(Duration(milliseconds: 100));
    yield i;
  }
}
