// =============================================================================
// Day 4 · Part 4 — StreamController
// Run: dart run Day4/04_stream_controller.dart
// =============================================================================
//
// A StreamController is a MANUAL stream: you push events into its SINK
// (.add / .addError) and expose its .stream to listeners. This is the engine
// under BLoC/Cubit: UI listens to .stream, logic adds new state to .sink.
//   - single-subscription (default): one listener.
//   - broadcast: many listeners (UI + analytics + logger, etc.).
//   - ALWAYS .close() it to fire `done` and free resources (Flutter: dispose()).
// =============================================================================

import 'dart:async';

Future<void> main() async {
  // 1. Single-subscription controller: push events, listen, close.
  print('--- single-subscription ---');
  final controller = StreamController<String>();
  final done = Completer<void>();
  controller.stream.listen(
    (msg) => print('event: $msg'),
    onError: (e) => print('error: $e'),
    onDone: () {
      print('stream closed');
      done.complete();
    },
  );
  controller.add('hello');
  controller.add('world');
  controller.addError('something failed'); // push an error event
  controller.add('after error'); // stream continues after a non-fatal error
  await controller.close(); // triggers onDone
  await done.future;

  // 2. Broadcast controller: multiple listeners receive every event.
  print('--- broadcast (2 listeners) ---');
  final bus = StreamController<int>.broadcast();
  bus.stream.listen((n) => print('listener A: $n'));
  bus.stream.where((n) => n.isEven).listen((n) => print('listener B (even): $n'));
  for (var i = 1; i <= 4; i++) {
    bus.add(i);
  }
  await bus.close();

  // 3. A tiny BLoC-style counter: state pushed through a controller's sink.
  print('--- mini Cubit (counter) ---');
  final counter = CounterBloc();
  final sub = counter.state.listen((value) => print('UI rebuild -> count = $value'));
  counter.increment();
  counter.increment();
  counter.decrement();
  await Future.delayed(const Duration(milliseconds: 10)); // let events flush
  await sub.cancel();
  counter.dispose();
}

// A minimal BLoC/Cubit pattern using StreamController as the state pipe.
class CounterBloc {
  int _count = 0;
  final _controller = StreamController<int>.broadcast();

  Stream<int> get state => _controller.stream; // UI subscribes here

  void increment() => _controller.sink.add(++_count);
  void decrement() => _controller.sink.add(--_count);

  void dispose() => _controller.close(); // call in State.dispose() in Flutter
}
