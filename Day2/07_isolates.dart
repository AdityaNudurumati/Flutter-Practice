// =============================================================================
// Day 2 · Part 7 — Isolates (true parallelism)
// Run: dart run Day2/07_isolates.dart
// =============================================================================
//
// WHY: Dart is single-threaded per isolate. `async`/`await` gives CONCURRENCY
// (interleaving on one thread) but NOT parallelism — a long CPU loop still
// FREEZES the UI. To run heavy CPU work without jank, move it to another
// ISOLATE (its own memory + event loop, running on a separate thread).
//
// Isolates DON'T share memory. They communicate only by passing MESSAGES
// (copies) over ports. This avoids locks/race conditions by design.
// =============================================================================

import 'dart:isolate';

Future<void> main() async {
  // 1. Isolate.run (Dart 2.19+) — the EASY, modern way. Runs a function on a
  //    fresh isolate, returns its result as a Future, and tears it down for you.
  print('1. computing on another isolate (UI stays responsive)...');
  final sum = await Isolate.run(() => heavyComputation(50000000));
  print('1. result = $sum');

  // 2. The CLASSIC low-level API: spawn + ReceivePort for manual messaging.
  //    Use this when you need long-lived, two-way communication (vs one-shot run).
  final receivePort = ReceivePort();
  await Isolate.spawn(worker, receivePort.sendPort);

  // The first message the worker sends back is ITS sendPort (a handshake),
  // then we send it a job and await the reply.
  final SendPort workerPort = await receivePort.first;
  final answer = await sendAndReceive(workerPort, 21);
  print('2. worker doubled 21 -> $answer');
}

// CPU-bound work. On the main isolate this would block the event loop / UI.
int heavyComputation(int n) {
  var total = 0;
  for (var i = 0; i < n; i++) {
    total += i % 7;
  }
  return total;
}

// 2. Worker entry point. Receives the main isolate's SendPort to reply on.
void worker(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort); // handshake: tell main how to reach us

  port.listen((message) {
    final job = message as List; // [value, replyPort]
    final value = job[0] as int;
    final SendPort reply = job[1] as SendPort;
    reply.send(value * 2); // do the work, send result back
  });
}

// Helper: send one request with a fresh reply port and await the single answer.
Future<int> sendAndReceive(SendPort target, int value) async {
  final response = ReceivePort();
  target.send([value, response.sendPort]);
  final result = await response.first as int;
  response.close();
  return result;
}
