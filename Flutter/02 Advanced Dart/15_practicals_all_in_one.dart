// =============================================================================
// 02 · ADVANCED DART — ALL-IN-ONE PRACTICAL FILE
// =============================================================================
// Runnable companion to the 14 notes files in this folder. Every "Revision
// Notes" bullet from each file has a live, printable demonstration here.
//
//   REQUIRES DART 3.3+ (Section 8 uses `extension type`).
//   This machine's default Flutter 3.16.8 ships Dart 3.2.5, which is too old.
//   Use the FVM-cached Flutter 3.35.4 (Dart 3.9.2):
//
//     & "$env:USERPROFILE\fvm\versions\3.35.4\bin\dart.bat" analyze "15_practicals_all_in_one.dart"
//     & "$env:USERPROFILE\fvm\versions\3.35.4\bin\dart.bat" run     "15_practicals_all_in_one.dart"
//
//   Or pin the whole project once with:  fvm use 3.35.4
//
// Map of sections -> source notes file:
//   1  Event Loop ...................... 01_event_loop.md
//   2  Futures & async/await ........... 02_async_futures.md
//   3  Streams ......................... 03_streams.md
//   4  Isolates ........................ 04_isolates.md
//   5  Generics ........................ 05_generics.md
//   6  Mixins .......................... 06_mixins.md
//   7  Extension Methods ............... 07_extension_methods.md
//   8  Extension Types ................. 08_extension_types.md
//   9  Constructors & Singletons ....... 09_constructors_and_singletons.md
//   10 Immutability .................... 10_immutability.md
//   11 Libraries & Packages ............ 11_libraries_and_packages.md
//   12 JSON & Serialization ............ 12_json_and_serialization.md
//   13 Memory & GC ..................... 13_memory_and_gc.md
//   14 Dart Compilation ................ 14_dart_compilation.md
//   15 Mini Projects (one per notes file)
// =============================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:math' as math;

Future<void> main() async {
  await section1EventLoop();
  await section2FuturesAndAsync();
  await section3Streams();
  await section4Isolates();
  section5Generics();
  section6Mixins();
  section7ExtensionMethods();
  section8ExtensionTypes();
  section9ConstructorsAndSingletons();
  section10Immutability();
  section11LibrariesAndPackages();
  await section12JsonAndSerialization();
  await section13MemoryAndGc();
  section14DartCompilation();
  await section15MiniProjects();
}

// -----------------------------------------------------------------------------
// Output helpers.
// -----------------------------------------------------------------------------
void section(String title) => print('\n${'=' * 74}\n$title\n${'=' * 74}');
void topic(String title) => print('\n-- $title ${'-' * math.max(3, 60 - title.length)}');
void show(String label, Object? value) => print('  $label: $value');
void note(String text) => print('  $text');

/// Hides a value from the analyzer's flow analysis so deliberate
/// null / false / "stale" demos don't get folded away as dead code.
T? opaque<T>(T? value) => value;

/// Burns CPU synchronously for [duration] — simulates a blocking computation.
void busyWait(Duration duration) {
  final sw = Stopwatch()..start();
  var sink = 0;
  while (sw.elapsed < duration) {
    for (var i = 0; i < 5000; i++) {
      sink += i;
    }
  }
  if (sink == -1) print('unreachable'); // keeps the loop from being optimised out
}

// =============================================================================
// SECTION 1 — THE EVENT LOOP (microtask queue vs event queue)
// =============================================================================
// Points covered:
//   * Order: run sync code -> drain ALL microtasks -> take ONE event ->
//     drain microtasks again -> repeat
//   * Microtask sources: scheduleMicrotask, Future.microtask, `.then`, `await`
//   * Event sources: Future(() {}), Future.delayed, Timer, I/O
//   * `await` ALWAYS yields — even on an already-completed future
//   * A starved microtask queue starves the event queue (timers fire late)
//   * Blocking the loop = jank; CPU work belongs in an isolate
// =============================================================================

Future<void> section1EventLoop() async {
  section('SECTION 1 · THE EVENT LOOP');

  topic('Execution order of the two queues');
  final order = <String>[];
  order.add('sync A (main body)');
  scheduleMicrotask(() => order.add('microtask 1 — scheduleMicrotask'));
  Future(() => order.add('event 1 — Future(() {})'));
  Future.microtask(() => order.add('microtask 2 — Future.microtask'));
  Future.delayed(Duration.zero, () => order.add('event 2 — Future.delayed(zero)'));
  Future.value(0).then((_) => order.add('microtask 3 — .then on a done future'));
  Timer.run(() => order.add('event 3 — Timer.run'));
  order.add('sync B (main body)');

  // Give both queues time to drain before reading the result.
  await Future.delayed(const Duration(milliseconds: 50));
  for (final (i, label) in order.indexed) {
    print('  ${i + 1}. $label');
  }
  note('');
  note('ALL sync code first, then EVERY microtask, only then the first event.');
  note('Microtasks and events each run FIFO within their own queue.');

  topic('`await` always yields — even on a completed future');
  final trace = <String>[];
  Future<void> asyncFn() async {
    trace.add('2. async body — runs SYNCHRONOUSLY up to the first await');
    await Future.value('already complete');
    trace.add('4. async body — AFTER await (resumed as a microtask)');
  }

  trace.add('1. before calling the async function');
  final pending = asyncFn(); // body starts immediately, then suspends
  trace.add('3. after the call returned its Future');
  await pending;
  for (final line in trace) {
    note(line);
  }
  note('');
  note('An `async` function is NOT deferred: it runs eagerly until the first');
  note('`await`. Everything after the await is a microtask continuation.');

  topic('Blocking the loop: a 10ms timer cannot fire on time');
  final blockedClock = Stopwatch()..start();
  var blockedFiredAt = -1;
  Timer(const Duration(milliseconds: 10),
      () => blockedFiredAt = blockedClock.elapsedMilliseconds);
  busyWait(const Duration(milliseconds: 200)); // synchronous CPU work
  await Future.delayed(const Duration(milliseconds: 30));
  show('timer due at 10ms fired at', '${blockedFiredAt}ms  <-- JANK');

  topic('Same work, chunked: the timer fires roughly on time');
  final chunkedClock = Stopwatch()..start();
  var chunkedFiredAt = -1;
  Timer(const Duration(milliseconds: 10),
      () => chunkedFiredAt = chunkedClock.elapsedMilliseconds);
  await chunkedWork(
    total: const Duration(milliseconds: 200),
    slice: const Duration(milliseconds: 5),
  );
  show('timer due at 10ms fired at', '${chunkedFiredAt}ms');
  note('Chunking yields to the loop between slices, so timers/IO get a turn.');
  note('It does NOT make the work parallel — for that, use an isolate.');

  topic('A microtask flood starves the event queue');
  final starveOrder = <String>[];
  Timer.run(() => starveOrder.add('event (queued FIRST)'));
  for (var i = 1; i <= 3; i++) {
    scheduleMicrotask(() => starveOrder.add('microtask $i (queued after)'));
  }
  await Future.delayed(const Duration(milliseconds: 20));
  show('resulting order', starveOrder);
  note('Every microtask drains before the already-waiting event. Never loop');
  note('microtasks that schedule more microtasks — the loop never advances.');

  topic('Cheat sheet');
  note('Microtask queue: scheduleMicrotask · Future.microtask · .then · await');
  note('Event queue   : Future(() {}) · Future.delayed · Timer · I/O · gestures');
  note('Flutter frame : also an event — block the loop and you drop frames.');
}

/// Does [total] worth of CPU work in [slice]-sized pieces, yielding to the
/// event loop between pieces so timers and I/O can run.
Future<void> chunkedWork({
  required Duration total,
  required Duration slice,
}) async {
  final clock = Stopwatch()..start();
  while (clock.elapsed < total) {
    busyWait(slice);
    await Future.delayed(Duration.zero); // hand the loop back
  }
}

// =============================================================================
// SECTION 2 — FUTURES & async / await
// =============================================================================
// Points covered:
//   * an `async` function ALWAYS returns a Future (even with no await)
//   * await suspends; the continuation is a microtask
//   * .then / .catchError / .whenComplete vs try / catch / finally
//   * Future.value / .error / .sync / .delayed
//   * sequential awaits vs Future.wait (measured), Future.any
//   * error handling in Future.wait (first error wins; eagerError)
//   * .timeout + TimeoutException, and .timeout(onTimeout:)
//   * Completer for bridging callback APIs
//   * unawaited futures -> errors escape to the Zone (runZonedGuarded)
//   * retry with exponential backoff
//   * CPU work does NOT belong in async — it belongs in an isolate
// =============================================================================

Future<void> section2FuturesAndAsync() async {
  section('SECTION 2 · FUTURES & ASYNC/AWAIT');

  topic('An async function always returns a Future');
  final result = noAwaitInside();
  show('static type / runtime type', '${result.runtimeType}');
  show('awaited value', await result);
  show('async fn declared Future<void> returns', await returnsNothing());

  topic('Future constructors');
  show('Future.value', await Future.value(42));
  show('Future.delayed', await Future.delayed(const Duration(milliseconds: 5), () => 'late'));
  show('Future.sync (runs body NOW)', await Future.sync(() => 'sync body'));
  try {
    await Future<int>.error(StateError('deliberate'));
  } on StateError catch (e) {
    show('Future.error caught by try/catch', e.message);
  }

  topic('try/catch/finally around await == .then/.catchError/.whenComplete');
  try {
    await failingCall();
  } on FormatException catch (e) {
    show('try/catch style', e.message);
  } finally {
    note('  finally always runs');
  }
  await failingCall()
      .then((v) => show('then', v))
      .catchError((Object e) => show('catchError style', (e as FormatException).message))
      .whenComplete(() => note('  whenComplete always runs'));

  topic('Sequential awaits vs Future.wait (parallel)');
  final sequentialClock = Stopwatch()..start();
  final a = await fakeCall('A', const Duration(milliseconds: 60));
  final b = await fakeCall('B', const Duration(milliseconds: 60));
  final c = await fakeCall('C', const Duration(milliseconds: 60));
  final sequentialMs = sequentialClock.elapsedMilliseconds;
  show('sequential result', [a, b, c]);
  show('sequential took', '${sequentialMs}ms  (60+60+60)');

  final parallelClock = Stopwatch()..start();
  final all = await Future.wait([
    fakeCall('A', const Duration(milliseconds: 60)),
    fakeCall('B', const Duration(milliseconds: 60)),
    fakeCall('C', const Duration(milliseconds: 60)),
  ]);
  show('Future.wait result', all);
  show('Future.wait took', '${parallelClock.elapsedMilliseconds}ms  (max, not sum)');
  note('Independent calls -> start them all, THEN await. Dependent -> sequential.');

  topic('Future.any — first one to settle wins');
  final fastest = await Future.any([
    fakeCall('slow', const Duration(milliseconds: 80)),
    fakeCall('fast', const Duration(milliseconds: 10)),
  ]);
  show('Future.any', fastest);

  topic('Errors inside Future.wait');
  try {
    await Future.wait([
      fakeCall('ok', const Duration(milliseconds: 10)),
      Future<String>.error(StateError('endpoint 2 died')),
    ]);
  } on StateError catch (e) {
    show('Future.wait rethrows the first error', e.message);
  }
  note('Want per-item outcomes instead of one throw? Wrap each future so it');
  note('completes with a Result/record and never rejects — see mini project 2.');
  final settled = await Future.wait([
    guarded(() => fakeCall('ok', const Duration(milliseconds: 5))),
    guarded(() => Future<String>.error(StateError('boom'))),
  ]);
  show('per-item outcomes', settled);

  topic('.timeout');
  try {
    await fakeCall('slowpoke', const Duration(milliseconds: 100))
        .timeout(const Duration(milliseconds: 20));
  } on TimeoutException catch (e) {
    show('timeout threw', e.duration);
  }
  final fallback = await fakeCall('slowpoke', const Duration(milliseconds: 100))
      .timeout(const Duration(milliseconds: 20), onTimeout: () => 'cached fallback');
  show('timeout with onTimeout', fallback);

  topic('Completer — bridge a callback API into a Future');
  show('completer-based call', await legacyCallbackApi('payload'));
  final doubleComplete = Completer<int>();
  doubleComplete.complete(1);
  show('isCompleted', doubleComplete.isCompleted);
  try {
    doubleComplete.complete(2); // completing twice is a StateError
  } on StateError catch (_) {
    note('  completing a Completer twice throws StateError — guard with isCompleted');
  }

  topic('Unawaited futures — errors escape to the Zone');
  await runZonedGuarded(() async {
    unawaited(Future<void>.error(StateError('nobody awaited me')));
    await Future.delayed(const Duration(milliseconds: 10));
  }, (error, stack) {
    show('caught by runZonedGuarded', error);
  });
  note('A `try/catch` cannot see an error from a future you never awaited.');
  note('In Flutter this surfaces via FlutterError.onError / PlatformDispatcher.');

  topic('Retry with exponential backoff');
  var attempt = 0;
  final retried = await retry(
    () async {
      attempt++;
      if (attempt < 3) throw StateError('attempt $attempt failed');
      return 'succeeded on attempt $attempt';
    },
    maxAttempts: 4,
    baseDelay: const Duration(milliseconds: 5),
  );
  show('retry result', retried);
  show('attempts used', attempt);

  topic('async is CONCURRENCY, not PARALLELISM');
  final asyncCpuClock = Stopwatch()..start();
  await Future.wait([cpuBoundAsync(50), cpuBoundAsync(50)]);
  show('two "parallel" CPU-bound async calls', '${asyncCpuClock.elapsedMilliseconds}ms');
  note('~100ms, not ~50ms: both ran on the SAME thread, one after the other.');
  note('await only helps when something else (IO, timer) does the waiting.');
  note('For real parallelism see Section 4 (isolates).');
}

/// No `await` in the body, but the return type is still a Future.
Future<String> noAwaitInside() async => 'I am wrapped in a Future';

Future<String> returnsNothing() async {
  await Future<void>.delayed(Duration.zero);
  return 'done';
}

Future<String> fakeCall(String label, Duration latency) async {
  await Future<void>.delayed(latency);
  return '$label(${latency.inMilliseconds}ms)';
}

Future<String> failingCall() async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
  throw const FormatException('bad payload from server');
}

/// Turns a throwing future into one that always completes with an outcome.
Future<String> guarded(Future<String> Function() action) async {
  try {
    return 'ok: ${await action()}';
  } catch (e) {
    return 'err: $e';
  }
}

/// A classic callback-style API adapted to a Future with a Completer.
Future<String> legacyCallbackApi(String input) {
  final completer = Completer<String>();
  Timer(const Duration(milliseconds: 10), () {
    if (!completer.isCompleted) completer.complete('callback -> future: $input');
  });
  return completer.future;
}

/// Retries [action], doubling the delay after each failure.
Future<T> retry<T>(
  Future<T> Function() action, {
  required int maxAttempts,
  required Duration baseDelay,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;
      if (attempt == maxAttempts) break;
      await Future<void>.delayed(baseDelay * math.pow(2, attempt - 1).toInt());
    }
  }
  throw StateError('all $maxAttempts attempts failed; last error: $lastError');
}

/// `async` does not move CPU work off the thread.
Future<void> cpuBoundAsync(int milliseconds) async {
  busyWait(Duration(milliseconds: milliseconds));
}

// =============================================================================
// SECTION 3 — STREAMS
// =============================================================================
// Points covered:
//   * Stream = many values over time; Future = exactly one
//   * produce: `async*` + yield / yield*, or StreamController
//   * consume: `await for` and `.listen(onData, onError, onDone)`
//   * single-subscription (buffers, ONE listener) vs broadcast (many, no replay)
//   * transformers: map / where / take / skip / distinct / asyncMap / expand /
//     handleError / fold, plus StreamTransformer.fromHandlers
//   * backpressure via subscription.pause() / resume()
//   * ALWAYS cancel subscriptions and close controllers (leaks!)
//   * a custom debounce transformer + switchMap-style stale-result dropping
// =============================================================================

Future<void> section3Streams() async {
  section('SECTION 3 · STREAMS');

  topic('async* generator consumed with `await for`');
  final ticks = <int>[];
  await for (final tick in countdown(3)) {
    ticks.add(tick);
  }
  show('countdown(3)', ticks);

  topic('yield* delegates to another stream');
  show('nested generator', await nested().toList());

  topic('.listen(onData, onError, onDone)');
  final seen = <String>[];
  final doneSignal = Completer<void>();
  final subscription = mixedStream().listen(
    (value) => seen.add('data:$value'),
    onError: (Object e) => seen.add('error:$e'),
    onDone: () {
      seen.add('done');
      doneSignal.complete();
    },
  );
  await doneSignal.future;
  await subscription.cancel(); // cancel even after onDone — cheap and safe
  show('event sequence', seen);
  note('An error does NOT end the stream unless cancelOnError: true.');

  topic('Single-subscription controller: buffers, allows ONE listener');
  final single = StreamController<int>();
  single.add(1); // buffered — nobody is listening yet
  single.add(2);
  final buffered = <int>[];
  final singleSub = single.stream.listen(buffered.add);
  try {
    single.stream.listen((_) {}); // second listener on a single-sub stream
  } on StateError catch (_) {
    note('  a 2nd listener on a single-subscription stream -> StateError');
  }
  single.add(3);
  await single.close();
  await singleSub.cancel();
  show('received (including buffered)', buffered);

  topic('Broadcast controller: many listeners, NO replay');
  final broadcast = StreamController<int>.broadcast();
  broadcast.add(100); // lost — no listeners yet
  final listenerA = <int>[];
  final listenerB = <int>[];
  final subA = broadcast.stream.listen(listenerA.add);
  final subB = broadcast.stream.listen(listenerB.add);
  broadcast.add(200);
  broadcast.add(300);
  await Future<void>.delayed(Duration.zero);
  await subA.cancel();
  await subB.cancel();
  await broadcast.close();
  show('listener A', listenerA);
  show('listener B', listenerB);
  note('100 was dropped: a broadcast stream never replays for late listeners.');
  note('Need the latest value on subscribe? Use a state holder / BehaviorSubject.');

  topic('Transformations');
  show('map', await countdown(4).map((n) => n * 10).toList());
  show('where', await countdown(6).where((n) => n.isEven).toList());
  show('take / skip', await countdown(6).skip(2).take(2).toList());
  show('distinct', await Stream.fromIterable([1, 1, 2, 2, 2, 3]).distinct().toList());
  show('expand', await Stream.fromIterable([1, 2]).expand((n) => [n, -n]).toList());
  show('asyncMap (awaits per event)',
      await countdown(3).asyncMap((n) => fakeCall('q$n', const Duration(milliseconds: 2))).toList());
  show('fold', await countdown(4).fold<int>(0, (acc, n) => acc + n));
  show('first / length', '${await countdown(4).first} / ${await countdown(4).length}');
  show('handleError recovers',
      await mixedStream().handleError((Object e) {}).toList());

  topic('StreamTransformer.fromHandlers');
  final tagged = await countdown(3)
      .transform(StreamTransformer<int, String>.fromHandlers(
        handleData: (value, sink) => sink.add('#$value'),
        handleDone: (sink) => sink.close(),
      ))
      .toList();
  show('custom transformer', tagged);

  topic('Backpressure: pause / resume');
  final produced = <int>[];
  final paused = <String>[];
  final source = StreamController<int>();
  final pausedSub = source.stream.listen(produced.add);
  source.add(1);
  await Future<void>.delayed(Duration.zero);
  pausedSub.pause();
  paused.add('paused');
  source.add(2); // buffered inside the stream while paused
  source.add(3);
  await Future<void>.delayed(const Duration(milliseconds: 5));
  show('delivered while paused', produced);
  pausedSub.resume();
  await Future<void>.delayed(const Duration(milliseconds: 5));
  show('delivered after resume', produced);
  await pausedSub.cancel();
  await source.close();
  note('A paused single-subscription stream buffers in memory — unbounded');
  note('producers + a slow consumer = growing heap. Bound your queue.');

  topic('Leaks: the #1 stream bug');
  final leakDemo = StreamController<int>.broadcast();
  final live = leakDemo.stream.listen((_) {});
  show('hasListener before cancel', leakDemo.hasListener);
  await live.cancel();
  show('hasListener after cancel', leakDemo.hasListener);
  await leakDemo.close();
  note('In Flutter: cancel every subscription in dispose(), and close every');
  note('controller you created. A live subscription keeps its closure — and');
  note('everything it captured (State, context, widgets) — reachable forever.');

  topic('Custom debounce + switchMap-style stale dropping');
  final keystrokes = StreamController<String>();
  final emitted = <String>[];
  final dropped = <String>[];
  var generation = 0;

  final searchSub = debounce(keystrokes.stream, const Duration(milliseconds: 30))
      .listen((query) async {
    final myGeneration = ++generation;
    final results = await fakeSearch(query);
    if (myGeneration != generation) {
      dropped.add(query); // a newer query started while this one was in flight
      return;
    }
    emitted.add(results);
  });

  // Type "d", "da" quickly (only "da" survives the debounce), then "dart".
  keystrokes.add('d');
  await Future<void>.delayed(const Duration(milliseconds: 10));
  keystrokes.add('da');
  await Future<void>.delayed(const Duration(milliseconds: 60)); // "da" fires
  keystrokes.add('dart');
  await Future<void>.delayed(const Duration(milliseconds: 60)); // "dart" fires
  await Future<void>.delayed(const Duration(milliseconds: 200)); // let both settle
  await keystrokes.close();
  await searchSub.cancel();

  show('emitted results', emitted);
  show('stale queries dropped', dropped);
  note('"d" never searched (debounced away); "da" searched but its slow result');
  note('was discarded because "dart" superseded it. That is switchMap.');
}

/// Async generator: produces values lazily, one per `yield`.
Stream<int> countdown(int from) async* {
  for (var i = 1; i <= from; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    yield i;
  }
}

/// `yield*` splices another stream's events into this one.
Stream<int> nested() async* {
  yield 0;
  yield* countdown(2);
  yield 99;
}

/// Emits data, then an error, then more data, then closes.
Stream<int> mixedStream() async* {
  yield 1;
  yield* Stream<int>.error(const FormatException('bad event'));
  yield 2;
}

/// Simulated search where the shorter query is deliberately SLOWER, so a stale
/// result would arrive after a newer one if we did not guard against it.
Future<String> fakeSearch(String query) async {
  final latency = query.length <= 2
      ? const Duration(milliseconds: 150)
      : const Duration(milliseconds: 20);
  await Future<void>.delayed(latency);
  return 'results for "$query"';
}

/// Emits a value only after [duration] of silence. The last pending value is
/// flushed when the source closes.
Stream<T> debounce<T>(Stream<T> source, Duration duration) {
  final controller = StreamController<T>();
  Timer? timer;
  T? pending;
  var hasPending = false;

  final sub = source.listen(
    (value) {
      pending = value;
      hasPending = true;
      timer?.cancel();
      timer = Timer(duration, () {
        hasPending = false;
        controller.add(value);
      });
    },
    onError: controller.addError,
    onDone: () {
      timer?.cancel();
      if (hasPending) controller.add(pending as T); // flush the last keystroke
      controller.close();
    },
  );

  controller.onCancel = () {
    timer?.cancel();
    return sub.cancel();
  };
  return controller.stream;
}

// =============================================================================
// SECTION 4 — ISOLATES (true parallelism)
// =============================================================================
// Points covered:
//   * an isolate has its OWN heap and its OWN event loop — no shared memory
//   * communication is message passing; messages are deep-copied
//   * Isolate.run (Flutter's `compute`) for one-shot CPU work
//   * Isolate.spawn + ReceivePort/SendPort for long-lived workers
//   * a reusable worker POOL (workers are not respawned per task)
//   * measured sequential vs parallel speedup
//   * always close ports and kill isolates
//   * big byte payloads -> TransferableTypedData; Flutter plugins in a
//     background isolate -> RootIsolateToken
// =============================================================================

Future<void> section4Isolates() async {
  section('SECTION 4 · ISOLATES');

  show('logical cores on this machine', Platform.numberOfProcessors);

  topic('Isolate.run — one-shot CPU work off the main isolate');
  final clock = Stopwatch()..start();
  final fib = await Isolate.run(() => fibonacci(30));
  show('fibonacci(30) computed in an isolate', fib);
  show('took', '${clock.elapsedMilliseconds}ms (includes spawn cost)');
  note('In Flutter this is `compute(fn, arg)` — same idea, older API.');

  topic('No shared memory: messages are DEEP COPIES');
  final original = <int>[1, 2, 3];
  final returned = await Isolate.run(() {
    final copy = [...original]; // `original` arrived as a copy
    copy.add(4);
    return copy;
  });
  show('list in the main isolate (unchanged)', original);
  show('list returned from the isolate', returned);
  note('Mutating the copy inside the isolate cannot affect the original.');
  note('Corollary: sending a huge object costs a full copy — measure it.');

  topic('Isolate.spawn + ports: a long-lived worker with a handshake');
  final echoes = await echoWorkerDemo(['ping 1', 'ping 2', 'ping 3']);
  for (final echo in echoes) {
    note('  $echo');
  }
  note('Handshake: main sends its SendPort -> worker replies with its own');
  note('SendPort -> now both sides can talk.');

  topic('Worker POOL: sequential vs parallel, with progress');
  const workload = [29, 29, 29, 29];

  final sequentialClock = Stopwatch()..start();
  final sequentialResults = workload.map(fibonacci).toList();
  final sequentialMs = sequentialClock.elapsedMilliseconds;
  show('sequential (main isolate)', '${sequentialMs}ms -> $sequentialResults');

  final poolSize = math.min(workload.length, Platform.numberOfProcessors);
  final spawnClock = Stopwatch()..start();
  final pool = await IsolatePool.spawn(poolSize);
  show('spawned $poolSize workers in', '${spawnClock.elapsedMilliseconds}ms');

  final parallelClock = Stopwatch()..start();
  var completed = 0;
  final parallelResults = await Future.wait([
    for (final (index, input) in workload.indexed)
      pool.submit(index, input).then((value) {
        completed++;
        print('  progress: $completed/${workload.length} done (task $index)');
        return value;
      }),
  ]);
  final parallelMs = parallelClock.elapsedMilliseconds;
  await pool.shutdown();

  show('parallel (pool of $poolSize)', '${parallelMs}ms -> $parallelResults');
  final speedup = parallelMs == 0 ? 0.0 : sequentialMs / parallelMs;
  show('speedup (excluding spawn cost)', '${speedup.toStringAsFixed(2)}x');
  note('Workers were REUSED across tasks and killed once, at shutdown.');
  note('Spawn cost is real (~10-100ms each) — pool, do not spawn per task.');

  topic('Rules');
  note('CPU-bound (parse/encode/hash/image) -> isolate. IO-bound -> async.');
  note('`async` never adds a thread; only an isolate does.');
  note('Large byte buffers: wrap in TransferableTypedData for a zero-copy move.');
  note('Calling Flutter plugins from a background isolate needs a');
  note('RootIsolateToken passed in and BackgroundIsolateBinaryMessenger set up.');
  note('State is NOT shared: no locks needed, but no globals either.');
}

/// Deliberately naive so it burns measurable CPU.
int fibonacci(int n) => n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2);

/// Spawns one worker, does a full SendPort handshake, exchanges messages, then
/// tears everything down.
Future<List<String>> echoWorkerDemo(List<String> messages) async {
  final fromWorker = ReceivePort();
  final isolate = await Isolate.spawn(echoWorker, fromWorker.sendPort);

  final workerReady = Completer<SendPort>();
  final allReplies = Completer<void>();
  final replies = <String>[];

  final sub = fromWorker.listen((dynamic message) {
    if (message is SendPort) {
      workerReady.complete(message);
    } else if (message is String) {
      replies.add(message);
      if (replies.length == messages.length && !allReplies.isCompleted) {
        allReplies.complete();
      }
    }
  });

  final toWorker = await workerReady.future;
  for (final message in messages) {
    toWorker.send(message);
  }
  await allReplies.future;

  toWorker.send('shutdown');
  await sub.cancel();
  fromWorker.close();
  isolate.kill(priority: Isolate.immediate);
  return replies;
}

/// Runs INSIDE the spawned isolate. Must be a top-level (or static) function.
void echoWorker(SendPort toMain) {
  final fromMain = ReceivePort();
  toMain.send(fromMain.sendPort); // handshake: hand back our own port
  fromMain.listen((dynamic message) {
    if (message == 'shutdown') {
      fromMain.close();
      return;
    }
    toMain.send('worker echoed "$message" (isolate #${Isolate.current.hashCode})');
  });
}

/// A fixed set of long-lived worker isolates, dispatched round-robin.
class IsolatePool {
  final List<Isolate> _isolates = [];
  final List<SendPort> _commandPorts = [];
  final List<ReceivePort> _responsePorts = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<int, Completer<int>> _pending = {};
  var _nextWorker = 0;

  static Future<IsolatePool> spawn(int size) async {
    final pool = IsolatePool();
    for (var i = 0; i < size; i++) {
      final responses = ReceivePort();
      final ready = Completer<SendPort>();

      pool._subscriptions.add(responses.listen((dynamic message) {
        if (message is SendPort) {
          ready.complete(message);
        } else if (message is List && message.length == 2) {
          final taskId = message[0] as int;
          final value = message[1] as int;
          pool._pending.remove(taskId)?.complete(value);
        }
      }));

      pool._isolates.add(await Isolate.spawn(poolWorker, responses.sendPort));
      pool._responsePorts.add(responses);
      pool._commandPorts.add(await ready.future);
    }
    return pool;
  }

  /// Sends one task to the next worker and completes when its result returns.
  Future<int> submit(int taskId, int input) {
    final completer = Completer<int>();
    _pending[taskId] = completer;
    final worker = _commandPorts[_nextWorker % _commandPorts.length];
    _nextWorker++;
    worker.send([taskId, input]);
    return completer.future;
  }

  Future<void> shutdown() async {
    for (final port in _commandPorts) {
      port.send('shutdown');
    }
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    for (final port in _responsePorts) {
      port.close();
    }
    for (final isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
  }
}

/// Worker body: waits for `[taskId, input]` messages until told to shut down.
void poolWorker(SendPort toMain) {
  final fromMain = ReceivePort();
  toMain.send(fromMain.sendPort);
  fromMain.listen((dynamic message) {
    if (message == 'shutdown') {
      fromMain.close();
      return;
    }
    final task = message as List;
    final taskId = task[0] as int;
    final input = task[1] as int;
    toMain.send([taskId, fibonacci(input)]);
  });
}

// =============================================================================
// SECTION 5 — GENERICS
// =============================================================================
// Points covered:
//   * generic classes and generic METHODS; declare <T> before using it
//   * bounds: `T extends Something` documents AND constrains
//   * Dart generics are REIFIED — type arguments survive to runtime
//   * covariance: List<Cat> IS-A List<Animal>; an illegal write throws TypeError
//   * F-bounded polymorphism: `T extends Comparable<T>`
//   * generic typedefs, generic sealed types (Result<T, E>)
//   * `covariant` keyword to widen a parameter type deliberately
// =============================================================================

void section5Generics() {
  section('SECTION 5 · GENERICS');

  topic('Generic class');
  final intBox = Box<int>(7);
  final stringBox = Box('hello'); // T inferred as String
  show('Box<int>', intBox);
  show('Box (inferred)', stringBox);
  show('mapped to another type', intBox.map((v) => 'value=$v'));

  topic('Generic method — <R> belongs to the METHOD, not the class');
  // The explicit <int> matters: `show` takes Object?, so downward inference
  // would otherwise widen T to Object and `n > 2` would not compile.
  show('firstWhereOrNull', firstWhereOrNull<int>([1, 2, 3, 4], (n) => n > 2));
  show('firstWhereOrNull (no match)', firstWhereOrNull<int>([1, 2], (n) => n > 9));
  show('zip', zip([1, 2, 3], ['a', 'b', 'c']));

  topic('Bounds: `T extends Entity` gives you the members AND the constraint');
  final repo = InMemoryRepository<UserEntity>();
  repo.save(const UserEntity('u1', 'Ada'));
  repo.save(const UserEntity('u2', 'Bob'));
  show('repository ids (bound guarantees .id exists)', repo.ids);
  show('findById', repo.findById('u2'));
  show('findById missing', repo.findById('nope'));
  note('Without the bound, `item.id` would not compile — T could be anything.');

  topic('Dart generics are REIFIED (unlike Java erasure)');
  // Typed as Object so the checks below are real runtime tests, not constants
  // the analyzer can fold away.
  final Object ints = <int>[1, 2, 3];
  show('ints is List<int>', ints is List<int>);
  show('ints is List<String>', ints is List<String>);
  show('runtimeType keeps its argument', ints.runtimeType);
  show('T is visible at runtime inside the class', Box<double>(1.5).typeName);
  note('This is why `is List<int>` works in Dart but is meaningless in Java.');

  topic('Covariance — sound at compile time, checked at runtime');
  final cats = <Cat>[Cat('Tom')];
  final List<Animal> asAnimals = cats; // legal: List<Cat> <: List<Animal>
  show('read through the supertype view', asAnimals.first.speak());
  try {
    asAnimals.add(Dog('Rex')); // would put a Dog into a List<Cat>
  } on TypeError catch (_) {
    show('adding a Dog to the List<Animal> view', 'TypeError at RUNTIME');
  }
  note('Covariant reads are safe; covariant WRITES are the hole Dart plugs');
  note('with a runtime check. Accept Iterable<T> for read-only parameters.');

  topic('F-bounded polymorphism: T extends Comparable<T>');
  // Explicit <num> required: `int implements Comparable<num>`, NOT
  // Comparable<int>, so inferring T = int fails the bound.
  show('largest num', largest<num>([3, 9, 4]));
  show('largest String', largest(['pear', 'apple', 'zebra']));
  show('largest Version', largest([Version(1, 2), Version(2, 0), Version(1, 9)]));
  note('`T extends Comparable<T>` says "T is comparable to ITSELF". Dart\'s own');
  note('int/double break the self-bound (both compare as num), which is why the');
  note('int call needs an explicit <num>. Your own types (Version, String) fit.');

  topic('Generic sealed type: Result<T, E>');
  final ok = Ok<int, String>(21);
  final err = Err<int, String>('not a number');
  show('Ok.map', describe(ok.map((v) => v * 2)));
  show('Err.map (passes the error through)', describe(err.map((v) => v * 2)));
  show('getOrElse on Err', err.getOrElse(-1));

  topic('`covariant` — deliberately widening a parameter');
  show('CatShelter accepts a Cat', CatShelter().accept(Cat('Felix')));
  note('`void accept(covariant Cat a)` overriding `accept(Animal a)` tells the');
  note('compiler "trust me", moving the check to runtime. Use sparingly.');

  topic('Guidelines');
  note('Bound to the smallest thing you actually need (Iterable, not List).');
  note('Return the concrete type, accept the abstract one.');
  note('Reach for a generic only when 2+ real types share the shape.');
}

class Box<T> {
  final T value;
  const Box(this.value);

  /// Method-level type parameter: R is independent of T.
  Box<R> map<R>(R Function(T value) transform) => Box<R>(transform(value));

  /// Reification: the type argument is available at runtime.
  String get typeName => '$T';

  @override
  String toString() => 'Box<$T>($value)';
}

T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

List<(A, B)> zip<A, B>(List<A> a, List<B> b) => [
      for (var i = 0; i < math.min(a.length, b.length); i++) (a[i], b[i]),
    ];

abstract class Entity {
  String get id;
}

class UserEntity implements Entity {
  @override
  final String id;
  final String name;
  const UserEntity(this.id, this.name);

  @override
  String toString() => 'User($id, $name)';
}

/// The bound is what makes `item.id` legal here.
class InMemoryRepository<T extends Entity> {
  final Map<String, T> _store = {};

  void save(T item) => _store[item.id] = item;
  T? findById(String id) => _store[id];
  List<String> get ids => _store.keys.toList();
}

class Animal {
  final String name;
  Animal(this.name);
  String speak() => '$name makes a sound';
}

class Cat extends Animal {
  Cat(super.name);
  @override
  String speak() => '$name says meow';
}

class Dog extends Animal {
  Dog(super.name);
  @override
  String speak() => '$name says woof';
}

class Shelter {
  String accept(Animal animal) => 'accepted ${animal.name}';
}

class CatShelter extends Shelter {
  // Narrowing a parameter is unsound, so Dart makes you opt in with
  // `covariant` and inserts a runtime check.
  @override
  String accept(covariant Cat cat) => 'cat-only shelter accepted ${cat.name}';
}

/// `T extends Comparable<T>` — T can be compared to ITSELF, not to anything.
///
/// Takes an `Iterable<T>` and only READS it: with `List<T>` plus `reduce`, a
/// `largest([1, 2, 3])` call infers T = num (because `int implements
/// Comparable<num>`, not `Comparable<int>`) and `List<int>.reduce` then rejects
/// the `(num, num) => num` closure at runtime. Reading avoids the whole trap.
T largest<T extends Comparable<T>>(Iterable<T> items) {
  var best = items.first;
  for (final item in items.skip(1)) {
    if (item.compareTo(best) > 0) best = item;
  }
  return best;
}

class Version implements Comparable<Version> {
  final int major;
  final int minor;
  const Version(this.major, this.minor);

  @override
  int compareTo(Version other) => major != other.major
      ? major.compareTo(other.major)
      : minor.compareTo(other.minor);

  @override
  String toString() => 'v$major.$minor';
}

sealed class Result<T, E> {
  const Result();

  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T, E>(value: final v) => Ok<R, E>(transform(v)),
        Err<T, E>(error: final e) => Err<R, E>(e),
      };

  T getOrElse(T fallback) => switch (this) {
        Ok<T, E>(value: final v) => v,
        Err<T, E>() => fallback,
      };
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}

String describe<T, E>(Result<T, E> result) => switch (result) {
      Ok<T, E>(value: final v) => 'Ok($v)',
      Err<T, E>(error: final e) => 'Err($e)',
    };

// =============================================================================
// SECTION 6 — MIXINS
// =============================================================================
// Points covered:
//   * `with M1, M2` applies mixins LEFT to RIGHT; the rightmost wins
//   * `super` walks the LINEARIZED chain, so order changes behaviour
//   * `on Base` constrains the host type and unlocks super/base members
//   * a pure `mixin` has no generative constructor; `mixin class` is both
//   * diamond resolution follows linearization, not declaration order
//   * extends = inherit implementation · with = mix in behaviour ·
//     implements = contract only
// =============================================================================

void section6Mixins() {
  section('SECTION 6 · MIXINS');

  topic('Linearization: `with` order decides the wrapping order');
  show('Base only', PlainText().render('hi'));
  show('with Bold, Italic', BoldThenItalic().render('hi'));
  show('with Italic, Bold', ItalicThenBold().render('hi'));
  note('Rightmost mixin runs FIRST and delegates inward via `super.render`.');
  note('Chain for `with Bold, Italic` = Italic -> Bold -> Base.');

  topic('All three decorations');
  show('Bold, Italic, Underline', FullyDecorated().render('dart'));

  topic('`on Base` — the mixin declares what it needs');
  final service = AuthService();
  show('mixin method calling a base member', service.describe());
  note('`mixin Loggable on Named` may use Named.name and call super methods.');
  note('Applying it to a class that is not a Named is a COMPILE error.');

  topic('Mixin with its own state and lifecycle hooks');
  final counter = CounterWidget()
    ..increment()
    ..increment()
    ..increment();
  show('mixin-provided state', counter.count);
  show('mixin-provided log', counter.history);

  topic('`mixin class` doubles as a mixin AND a normal class');
  show('used as a class', const Serializable().serialize({'a': 1}));
  show('used as a mixin', ApiPayload().serialize({'b': 2}));
  note('A pure `mixin` cannot be constructed or extended — only mixed in.');

  topic('Diamond: two mixins override the same member');
  show('with A, B', DiamondAB().label());
  show('with B, A', DiamondBA().label());
  note('Last one in the `with` clause wins the method table slot.');

  topic('extends vs with vs implements');
  note('extends X     : inherit X implementation, single parent, `super` works');
  note('with M        : splice M members in, many allowed, order matters');
  note('implements X  : take the CONTRACT only, no code — you write everything');
  final robot = Robot();
  show('Robot implements Animal (no inherited code)', robot.speak());

  topic('When to reach for a mixin');
  note('Cross-cutting behaviour reused by unrelated classes (logging, caching,');
  note('validation, Flutter\'s SingleTickerProviderStateMixin).');
  note('Not for is-a relationships and not as a dumping ground — one job each.');
}

class TextRenderer {
  String render(String text) => text;
}

mixin Bold on TextRenderer {
  @override
  String render(String text) => '<b>${super.render(text)}</b>';
}

mixin Italic on TextRenderer {
  @override
  String render(String text) => '<i>${super.render(text)}</i>';
}

mixin Underline on TextRenderer {
  @override
  String render(String text) => '<u>${super.render(text)}</u>';
}

class PlainText extends TextRenderer {}

class BoldThenItalic extends TextRenderer with Bold, Italic {}

class ItalicThenBold extends TextRenderer with Italic, Bold {}

class FullyDecorated extends TextRenderer with Bold, Italic, Underline {}

abstract class Named {
  String get name;
}

/// `on Named` = "you may only be mixed into a Named", which is what makes
/// `name` legal inside the mixin body.
mixin Loggable on Named {
  String describe() => '[$runtimeType] name=$name';
}

class AuthService extends Named with Loggable {
  @override
  String get name => 'auth';
}

/// Mixins can carry state and provide reusable hooks.
mixin CounterMixin {
  int _count = 0;
  final List<String> _history = [];

  int get count => _count;
  List<String> get history => List.unmodifiable(_history);

  void increment() {
    _count++;
    _history.add('increment -> $_count');
  }
}

class CounterWidget with CounterMixin {}

/// `mixin class` can be instantiated, extended AND mixed in.
mixin class Serializable {
  const Serializable();
  String serialize(Map<String, Object?> data) => jsonEncode(data);
}

class ApiPayload with Serializable {}

mixin LabelA {
  String label() => 'A';
}

mixin LabelB {
  String label() => 'B';
}

class DiamondAB with LabelA, LabelB {}

class DiamondBA with LabelB, LabelA {}

/// `implements` copies the contract, never the code.
class Robot implements Animal {
  @override
  String get name => 'R2';

  @override
  String speak() => 'R2 beeps (had to implement speak() from scratch)';
}

// =============================================================================
// SECTION 7 — EXTENSION METHODS
// =============================================================================
// Points covered:
//   * `extension Name on Type { }` adds methods/getters/setters/operators
//   * extensions CANNOT add instance fields (no per-object storage)
//   * resolution is STATIC: it uses the static type, so `dynamic` fails
//   * a real instance member always beats an extension member
//   * conflicts resolved with `show`/`hide` on import, or `Ext(x).member()`
//   * generic extensions, extensions on nullable types
//   * zero runtime cost — it compiles to a plain static call
// =============================================================================

void section7ExtensionMethods() {
  section('SECTION 7 · EXTENSION METHODS');

  topic('Extensions on String');
  show("'  hello world  '.cleaned", '  hello world  '.cleaned);
  show("'hello world'.titleCase", 'hello world'.titleCase);
  show("'4111111111111111'.masked()", '4111111111111111'.masked());
  show("'ada@example.com'.isEmail", 'ada@example.com'.isEmail);
  show("'nope'.isEmail", 'nope'.isEmail);

  topic('Extensions on num');
  show('129999.asRupees', 129999.asRupees);
  show('0.8734.asPercent', 0.8734.asPercent);
  show('7.clampTo(1, 5)', 7.clampTo(1, 5));
  show('3.timesRepeat', 3.timesRepeat((i) => 'run$i'));

  topic('Extensions on DateTime');
  final when = DateTime(2026, 8, 17, 14, 30);
  show('formatted', when.ymd);
  show('isSameDayAs', when.isSameDayAs(DateTime(2026, 8, 17, 9)));
  show('relative to +3 days', when.relativeTo(when.add(const Duration(days: 3))));

  topic('Generic extension on Iterable');
  show('[3,1,2].sortedCopy()', [3, 1, 2].sortedCopy());
  show('groupBy first letter',
      ['apple', 'avocado', 'banana'].groupBy((w) => w[0]));
  show('sumBy', [1, 2, 3, 4].sumBy((n) => n * 10));
  show('firstOrNull on empty', <int>[].firstOrNullExt);

  topic('Extension on a NULLABLE type');
  final String? missing = opaque<String>(null);
  show('null.orEmpty', missing.orEmpty);
  show("'x'.orEmpty", 'x'.orEmpty);
  note('`extension on String?` can be called ON null — handy for defaults.');

  topic('Static resolution: extensions are NOT virtual dispatch');
  const String typed = 'hello';
  show('static type String -> extension works', typed.titleCase);
  final Object erased = 'hello';
  note('`erased.titleCase` does NOT compile: static type is Object.');
  show('cast back first', (erased as String).titleCase);
  dynamic loose = 'hello';
  try {
    // ignore: avoid_dynamic_calls
    loose.titleCase as String;
  } on NoSuchMethodError catch (_) {
    show('on `dynamic`', 'NoSuchMethodError — resolution happens at COMPILE time');
  }

  topic('A real member always wins');
  show("'abc'.length (real member)", 'abc'.length);
  note('If String ever gained a real `titleCase`, it would silently shadow the');
  note('extension — this is why extensions are risky on types you do not own.');

  topic('Resolving conflicts explicitly');
  // An emoji is 2 UTF-16 code units but 1 rune, so the two extensions really
  // do disagree — which is the whole reason the ambiguity matters.
  const tricky = 'hi \u{1F600}';
  show('StringStats(x).size  (UTF-16 code units)', StringStats(tricky).size);
  show('StringChars(x).size  (runes)', StringChars(tricky).size);
  note('Two extensions declaring `size` on String -> `tricky.size` is');
  note('AMBIGUOUS and will not compile. Fix by naming the extension you mean');
  note('(as above), or with `import ... show/hide` to bring in only one.');

  topic('No fields — and zero cost');
  note('Extensions may declare STATIC fields and getters, never instance ones:');
  note('there is nowhere to store per-object data. Need state? Use a wrapper,');
  note('a real subclass, or an Expando (Section 13).');
  note('`x.titleCase` compiles to `StringCasing.titleCase(x)` — a static call,');
  note('no allocation, fully tree-shakeable.');
}

extension StringCasing on String {
  String get cleaned => trim().replaceAll(RegExp(r'\s+'), ' ');

  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  bool get isEmail => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(this);

  String masked({int visible = 4, String mask = '*'}) => length <= visible
      ? this
      : mask * (length - visible) + substring(length - visible);
}

extension StringStats on String {
  int get size => length; // deliberately conflicts with StringChars.size
}

extension StringChars on String {
  int get size => runes.length;
}

extension NullableString on String? {
  String get orEmpty => this ?? '';
}

extension NumFormatting on num {
  String get asRupees => 'Rs. ${(this / 100).toStringAsFixed(2)}';
  String get asPercent => '${(this * 100).toStringAsFixed(1)}%';
  num clampTo(num low, num high) => this < low ? low : (this > high ? high : this);
}

extension IntRepeat on int {
  List<T> timesRepeat<T>(T Function(int index) build) =>
      [for (var i = 0; i < this; i++) build(i)];
}

extension DateTimeFormatting on DateTime {
  String get ymd => '$year-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  String relativeTo(DateTime now) {
    final diff = now.difference(this);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}

extension IterableExtras<T> on Iterable<T> {
  T? get firstOrNullExt => isEmpty ? null : first;

  List<T> sortedCopy([int Function(T a, T b)? compare]) {
    final copy = toList();
    copy.sort(compare ?? (a, b) => (a as Comparable).compareTo(b));
    return copy;
  }

  Map<K, List<T>> groupBy<K>(K Function(T item) keyOf) {
    final grouped = <K, List<T>>{};
    for (final item in this) {
      grouped.putIfAbsent(keyOf(item), () => []).add(item);
    }
    return grouped;
  }

  num sumBy(num Function(T item) valueOf) =>
      fold<num>(0, (acc, item) => acc + valueOf(item));
}

// =============================================================================
// SECTION 8 — EXTENSION TYPES (zero-cost wrappers, Dart 3.3+)
// =============================================================================
// Points covered:
//   * `extension type UserId(int value) {}` is a COMPILE-TIME-only type
//   * at runtime it IS the representation type — zero allocation, zero cost
//   * two extension types over the same primitive are NOT interchangeable
//   * `implements int` makes it TRANSPARENT (inherits the int API)
//   * without `implements`, the API is exactly what you declare (opaque)
//   * private primary constructor + static factory = validated construction
//   * CAVEAT: no runtime identity — `runtimeType` is the representation type,
//     so `is`/`as`/`switch` on the wrapper cannot distinguish it
// =============================================================================

void section8ExtensionTypes() {
  section('SECTION 8 · EXTENSION TYPES');

  topic('The problem: primitives are interchangeable');
  note('int userId, int orderId -> `chargeOrder(userId, orderId)` with the');
  note('arguments swapped compiles fine and fails in production.');

  topic('Opaque extension types fix that at compile time');
  const user = UserId(7);
  const order = OrderId(1042);
  show('UserId', '${user.tag} (value=${user.value})');
  show('OrderId', '${order.tag} (value=${order.value})');
  show('correct call', chargeOrder(user, order));
  note('`chargeOrder(order, user)` is a COMPILE ERROR — argument type mismatch.');
  note('`user + 1` is also a compile error: UserId declares no `+`.');

  topic('Zero cost: at runtime it IS the representation type');
  show('user.runtimeType', user.runtimeType);
  show('user.runtimeType == int', user.runtimeType == int);
  show('<UserId>[...].runtimeType', <UserId>[UserId(1), UserId(2)].runtimeType);
  note('No wrapper object is allocated — unlike a `class UserId { final int v; }`');
  note('which costs one object header + one field per ID. A List<UserId> and a');
  note('List<int> are the SAME object at runtime.');
  note('');
  note('Note: `final Object o = user;` does NOT compile. An opaque extension');
  note('type is not a subtype of Object at all — it sits outside the normal');
  note('hierarchy until you give it an `implements` clause. Pass `.value` when');
  note('you need to hand the raw representation to generic code.');
  final int representation = user.value;
  show('representation handed out explicitly', representation);

  topic('CAVEAT: no runtime type, so no runtime discrimination');
  show('UserId(7) == OrderId(7) at runtime', identical(UserId(7).value, OrderId(7).value));
  note('You cannot write `if (x is UserId)` and expect it to exclude OrderId —');
  note('both are plain ints once compiled. Safety is COMPILE-TIME ONLY.');
  note('So: never rely on an extension type for runtime validation or for');
  note('`switch` dispatch, and do not send them across isolate boundaries');
  note('expecting the distinction to survive.');

  topic('Transparent: `implements num` inherits the whole numeric API');
  const width = Meters(3.5);
  const height = Meters(2.0);
  show('width.value', width.value);
  show('width < height (from num)', width < height);
  show('width.toStringAsFixed(1) (from num)', width.toStringAsFixed(1));
  show('width.plus(height) (declared here)', width.plus(height));
  note('`implements num` = transparent: everything num can do, Meters can too.');
  note('Omit `implements` when you want to FORBID raw arithmetic (opaque).');

  topic('Opaque money type with declared operators only');
  const price = Cents(129999);
  const shipping = Cents(4900);
  show('price', price.formatted);
  show('price + shipping', (price + shipping).formatted);
  show('price * 2', (price * 2).formatted);
  show('comparison', price > shipping);
  note('Money as an int of the smallest unit + a type that forbids float math.');

  topic('Validated construction: private ctor + static factory');
  final good = Email.parse('ada@example.com');
  final bad = Email.parse('not-an-email');
  show('Email.parse (valid)', good?.value);
  show('Email.parse (valid).domain', good?.domain);
  show('Email.parse (invalid)', bad);
  note('The primary constructor is private (`Email._`), so the ONLY way in is');
  note('`parse` — every Email in the program is guaranteed well-formed.');

  topic('extension type vs extension vs wrapper class');
  note('extension       : add methods to an EXISTING type, same type identity');
  note('extension type  : a NEW compile-time type, zero runtime cost, curated API');
  note('wrapper class   : a real runtime type (works with is/switch) but allocates');
  note('Choose extension type for typed IDs/units/money on a hot path;');
  note('choose a real class when you need runtime type checks or subtyping.');
}

/// Opaque: the only members are the ones declared here.
extension type const UserId(int value) {
  String get tag => 'user-$value';
}

extension type const OrderId(int value) {
  String get tag => 'order-$value';
}

String chargeOrder(UserId user, OrderId order) =>
    'charged ${order.tag} for ${user.tag}';

/// Transparent: `implements num` exposes the entire num API on Meters.
extension type const Meters(double value) implements num {
  Meters plus(Meters other) => Meters(value + other.value);
}

/// Opaque money type: only the operations declared here are legal.
extension type const Cents(int value) {
  String get formatted => 'Rs. ${(value / 100).toStringAsFixed(2)}';
  Cents operator +(Cents other) => Cents(value + other.value);
  Cents operator -(Cents other) => Cents(value - other.value);
  Cents operator *(int factor) => Cents(value * factor);
  bool operator >(Cents other) => value > other.value;
  bool operator <(Cents other) => value < other.value;
}

/// Private primary constructor forces construction through [parse].
extension type const Email._(String value) {
  static Email? parse(String raw) {
    final trimmed = raw.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)
        ? Email._(trimmed)
        : null;
  }

  String get domain => value.split('@').last;
}

// =============================================================================
// SECTION 9 — CONSTRUCTORS, FACTORIES, SINGLETONS & CALLABLE CLASSES
// =============================================================================
// Points covered:
//   * default, named, and const constructors
//   * initializer list: assigns final fields, runs asserts, calls super —
//     BEFORE the body, and with no access to `this`
//   * redirecting constructors (`: this(...)`)
//   * factory constructors: may return a cache hit or a SUBTYPE; no
//     initializer list and no `this`
//   * private constructor `Foo._()` + `static final instance` = singleton
//   * callable classes: define `call(...)` and invoke the object directly
//   * dependency injection beats a singleton for testability
// =============================================================================

void section9ConstructorsAndSingletons() {
  section('SECTION 9 · CONSTRUCTORS, FACTORIES & SINGLETONS');

  topic('Named constructors + initializer list + asserts');
  show('Temperature.celsius(25)', Temperature.celsius(25));
  show('Temperature.fahrenheit(98.6)', Temperature.fahrenheit(98.6));
  show('Temperature.absoluteZero (redirecting)', Temperature.absoluteZero());
  try {
    Temperature.celsius(-500); // violates the assert in the initializer list
    note('  (asserts are disabled — run without --enable-asserts to see this)');
  } on AssertionError catch (_) {
    show('assert in the initializer list', 'AssertionError — invariant enforced');
  }
  note('Initializer list runs BEFORE the body, so it can assign `final` fields');
  note('and validate arguments; `this` does not exist yet.');

  topic('const constructor + canonicalization');
  const a = Temperature.zeroC;
  const b = Temperature.zeroC;
  show('identical(a, b)', identical(a, b));
  show('non-const instance is a new object',
      identical(a, Temperature.celsius(0)));

  topic('Factory constructor returning a CACHED instance');
  final first = IconGlyph.named('home');
  final second = IconGlyph.named('home');
  final other = IconGlyph.named('settings');
  show('IconGlyph.named("home") twice -> identical', identical(first, second));
  show('different name -> different object', identical(first, other));
  show('cache size', IconGlyph.cacheSize);
  note('A factory may return an existing object; a generative constructor');
  note('always creates a brand-new one.');

  topic('Factory returning a SUBTYPE (polymorphic construction)');
  for (final raw in ['{"a":1}', '<xml/>', 'plain text']) {
    final parser = PayloadParser.forContent(raw);
    print('  ${raw.padRight(12)} -> ${parser.runtimeType}: ${parser.parse(raw)}');
  }
  note('Callers ask for `PayloadParser`; the factory picks the implementation.');

  topic('Singleton: private ctor + static final instance');
  final logA = AppLogger.instance;
  final logB = AppLogger.instance;
  logA.log('first message');
  logB.log('second message');
  show('identical(logA, logB)', identical(logA, logB));
  show('shared buffer', logA.entries);
  note('`AppLogger._()` is private, so no one else can construct one.');
  note('`static final` is LAZY — the instance is built on first access.');

  topic('Why DI usually beats a singleton');
  final production = OrderService(clock: const SystemClock());
  final tested = OrderService(clock: FixedClock(DateTime(2020, 1, 1)));
  show('with the real clock', production.stamp().isNotEmpty);
  show('with a fake clock (deterministic test)', tested.stamp());
  note('A hard-coded singleton is a hidden global: untestable, order-dependent,');
  note('and impossible to swap per environment. Inject the dependency instead.');

  topic('Callable classes — define `call(...)`');
  const policy = PasswordPolicy(minLength: 8);
  show('policy("short")', policy('short'));
  show('policy("longenough1")', policy('longenough1'));
  final validators = <String Function(String)>[policy, (s) => s.trim()];
  show('usable anywhere a function is expected', validators.first('tiny'));
  note('`call` makes the object satisfy a function type — great for injectable');
  note('strategies (validators, formatters, use-cases).');
}

class Temperature {
  final double celsiusValue;

  static const Temperature zeroC = Temperature.raw(0);

  const Temperature.raw(this.celsiusValue);

  /// Initializer list with an assert: validates before the object exists.
  Temperature.celsius(double value)
      : assert(value >= -273.15, 'below absolute zero'),
        celsiusValue = value;

  Temperature.fahrenheit(double value) : celsiusValue = (value - 32) * 5 / 9;

  /// Redirecting constructor — delegates to another constructor.
  Temperature.absoluteZero() : this.raw(-273.15);

  double get fahrenheit => celsiusValue * 9 / 5 + 32;

  @override
  String toString() =>
      '${celsiusValue.toStringAsFixed(1)}C / ${fahrenheit.toStringAsFixed(1)}F';
}

/// Factory + cache: repeated names return the SAME object.
class IconGlyph {
  static final Map<String, IconGlyph> _cache = {};

  final String name;
  IconGlyph._(this.name);

  factory IconGlyph.named(String name) =>
      _cache.putIfAbsent(name, () => IconGlyph._(name));

  static int get cacheSize => _cache.length;

  @override
  String toString() => 'IconGlyph($name)';
}

/// Factory choosing a subtype based on the input.
abstract class PayloadParser {
  const PayloadParser();

  factory PayloadParser.forContent(String raw) {
    if (raw.trimLeft().startsWith('{')) return const JsonPayloadParser();
    if (raw.trimLeft().startsWith('<')) return const XmlPayloadParser();
    return const TextPayloadParser();
  }

  String parse(String raw);
}

class JsonPayloadParser extends PayloadParser {
  const JsonPayloadParser();
  @override
  String parse(String raw) => 'decoded ${jsonDecode(raw)}';
}

class XmlPayloadParser extends PayloadParser {
  const XmlPayloadParser();
  @override
  String parse(String raw) => 'xml of ${raw.length} chars';
}

class TextPayloadParser extends PayloadParser {
  const TextPayloadParser();
  @override
  String parse(String raw) => 'text "$raw"';
}

/// Classic Dart singleton.
class AppLogger {
  static final AppLogger instance = AppLogger._();
  final List<String> _entries = [];

  AppLogger._();

  void log(String message) => _entries.add(message);
  List<String> get entries => List.unmodifiable(_entries);
}

/// Injectable dependency instead of a singleton clock.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  final DateTime fixed;
  FixedClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class OrderService {
  final Clock clock;
  const OrderService({required this.clock});

  String stamp() => 'order placed at ${clock.now().toIso8601String()}';
}

/// Callable class: `policy(value)` invokes `call`.
class PasswordPolicy {
  final int minLength;
  const PasswordPolicy({required this.minLength});

  String call(String password) => password.length >= minLength
      ? 'ok'
      : 'too short (need $minLength, got ${password.length})';
}

// =============================================================================
// SECTION 10 — IMMUTABILITY
// =============================================================================
// Points covered:
//   * immutable recipe: final fields + const ctor + ==/hashCode + copyWith
//   * value equality powers diffing, Set/Map keys, and rebuild-skipping
//   * the copyWith nullability trap, and the sentinel that fixes it
//   * expose List.unmodifiable — a `final List` is still mutable
//   * nested models must be immutable too, or the guarantee leaks
//   * a pure reducer + history list = undo for free
//   * freezed / equatable / records automate equality and copyWith
// =============================================================================

void section10Immutability() {
  section('SECTION 10 · IMMUTABILITY');

  topic('The immutable value object recipe');
  const settings = Settings(theme: 'dark', fontSize: 14, notifications: true);
  show('settings', settings);
  final bigger = settings.copyWith(fontSize: 18);
  show('copyWith(fontSize: 18)', bigger);
  show('original untouched', settings);

  topic('Value equality');
  const same = Settings(theme: 'dark', fontSize: 14, notifications: true);
  show('settings == same', settings == same);
  show('identical (const canonicalized)', identical(settings, same));
  show('hashCodes match', settings.hashCode == same.hashCode);
  show('usable as a Map key', {settings: 'stored'}[same]);
  show('changed copy is NOT equal', settings == bigger);
  note('This is exactly how Flutter skips rebuilds: if the new state equals');
  note('the old state, there is nothing to repaint.');

  topic('The copyWith null trap');
  const withNickname = Profile(name: 'Ada', nickname: 'The Countess');
  show('start', withNickname);
  show('naive copyWith(nickname: null) — no change (BUG)',
      withNickname.naiveCopyWith(nickname: null));
  show('sentinel copyWith(nickname: null) — actually clears it',
      withNickname.copyWith(nickname: null));
  note('`Type? nickname` cannot distinguish "not passed" from "passed null".');
  note('Fix with a sentinel default (used here) or an Optional<T> wrapper.');

  topic('A `final` collection is still mutable');
  final leaky = LeakyBasket(['apple']);
  leaky.items.add('sneaked in'); // compiles, mutates internal state
  show('leaky basket after external add', leaky.items);
  final safe = SafeBasket(['apple']);
  try {
    safe.items.add('sneaked in');
  } on UnsupportedError catch (_) {
    show('safe basket rejects external add', 'UnsupportedError');
  }
  show('safe basket', safe.items);
  note('Copy on the way IN and expose List.unmodifiable on the way OUT.');

  topic('Immutability must go all the way down');
  final nested = Order(id: 'o1', lines: [const OrderLine('Book', 2)]);
  show('order total', nested.total);
  note('If OrderLine were mutable, an Order "value" could change under you and');
  note('its cached hashCode would go stale — breaking Sets and Maps.');

  topic('Pure reducer + history = undo');
  var state = const AppState();
  final history = <AppState>[state];
  for (final action in [
    const AddToCart('Book'),
    const AddToCart('Pen'),
    const ChangeTheme('dark'),
  ]) {
    state = reduce(state, action);
    history.add(state);
    print('  after ${action.runtimeType.toString().padRight(12)} -> $state');
  }
  final undone = history[history.length - 2];
  show('undo (previous state from history)', undone);
  show('states are comparable by value', history.last == state);
  note('Nothing was mutated: every step produced a NEW state, so the whole');
  note('history stays valid. That is time-travel debugging in 3 lines.');

  topic('Cost and tooling');
  note('Cost: one allocation per change. Usually irrelevant — and cheaper than');
  note('the defensive copies and bug-hunting that mutable state demands.');
  note('Hot paths: keep objects small, reuse `const`, avoid deep copies.');
  note('Automate with `freezed` (codegen), `equatable`, or records for');
  note('short-lived local values.');
}

class Settings {
  final String theme;
  final int fontSize;
  final bool notifications;

  const Settings({
    required this.theme,
    required this.fontSize,
    required this.notifications,
  });

  Settings copyWith({String? theme, int? fontSize, bool? notifications}) =>
      Settings(
        theme: theme ?? this.theme,
        fontSize: fontSize ?? this.fontSize,
        notifications: notifications ?? this.notifications,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.theme == theme &&
      other.fontSize == fontSize &&
      other.notifications == notifications;

  @override
  int get hashCode => Object.hash(theme, fontSize, notifications);

  @override
  String toString() =>
      'Settings(theme: $theme, fontSize: $fontSize, notifications: $notifications)';
}

/// Sentinel object distinguishing "argument omitted" from "argument was null".
const Object _unset = Object();

class Profile {
  final String name;
  final String? nickname;
  const Profile({required this.name, this.nickname});

  /// BUGGY: `nickname: null` is indistinguishable from omitting it.
  Profile naiveCopyWith({String? name, String? nickname}) =>
      Profile(name: name ?? this.name, nickname: nickname ?? this.nickname);

  /// CORRECT: the sentinel default lets an explicit null through.
  Profile copyWith({Object? name = _unset, Object? nickname = _unset}) =>
      Profile(
        name: name == _unset ? this.name : name as String,
        nickname: nickname == _unset ? this.nickname : nickname as String?,
      );

  @override
  String toString() => 'Profile($name, nickname: $nickname)';
}

class LeakyBasket {
  final List<String> items; // final reference, mutable list
  LeakyBasket(this.items);
}

class SafeBasket {
  final List<String> _items;
  SafeBasket(List<String> items) : _items = List.of(items); // copy IN
  List<String> get items => List.unmodifiable(_items); // freeze OUT
}

class OrderLine {
  final String sku;
  final int quantity;
  const OrderLine(this.sku, this.quantity);

  @override
  bool operator ==(Object other) =>
      other is OrderLine && other.sku == sku && other.quantity == quantity;

  @override
  int get hashCode => Object.hash(sku, quantity);
}

class Order {
  final String id;
  final List<OrderLine> _lines;

  Order({required this.id, required List<OrderLine> lines})
      : _lines = List.unmodifiable(lines);

  List<OrderLine> get lines => _lines;
  int get total => _lines.fold(0, (acc, line) => acc + line.quantity);
}

// --- immutable state + pure reducer ------------------------------------------

class AppState {
  final String theme;
  final List<String> cart;

  const AppState({this.theme = 'light', this.cart = const []});

  AppState copyWith({String? theme, List<String>? cart}) =>
      AppState(theme: theme ?? this.theme, cart: cart ?? this.cart);

  @override
  bool operator ==(Object other) =>
      other is AppState &&
      other.theme == theme &&
      _sameList(other.cart, cart);

  @override
  int get hashCode => Object.hash(theme, Object.hashAll(cart));

  @override
  String toString() => 'AppState(theme: $theme, cart: $cart)';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

sealed class Action {
  const Action();
}

class AddToCart extends Action {
  final String sku;
  const AddToCart(this.sku);
}

class ChangeTheme extends Action {
  final String theme;
  const ChangeTheme(this.theme);
}

/// Pure: same inputs -> same output, no mutation, no side effects.
AppState reduce(AppState state, Action action) => switch (action) {
      AddToCart(sku: final sku) => state.copyWith(cart: [...state.cart, sku]),
      ChangeTheme(theme: final theme) => state.copyWith(theme: theme),
    };

// =============================================================================
// SECTION 11 — LIBRARIES & PACKAGES
// =============================================================================
// Points covered:
//   * `_name` privacy is LIBRARY-scoped, not class-scoped
//   * import (in) vs export (out); barrel files
//   * show / hide / as prefixes / deferred as
//   * public API in lib/, internals in lib/src/ — never import someone's src/
//   * `^1.2.0` means >=1.2.0 <2.0.0; commit pubspec.lock for apps, not packages
// =============================================================================

void section11LibrariesAndPackages() {
  section('SECTION 11 · LIBRARIES & PACKAGES');

  topic('`_privacy` is per-LIBRARY (per file), not per class');
  final account = BankAccount(100);
  show('public API', account.balance);
  account.deposit(50);
  show('after deposit', account.balance);
  show('another class in the SAME file can touch _balance',
      AccountAuditor().peek(account));
  note('`_balance` is private to this FILE. Any class in the same library sees');
  note('it. Split into another file and the same code stops compiling.');
  show('top-level private helper', _internalHelper('x'));

  topic('Curated public API (the barrel-file pattern, in miniature)');
  show('facade hides the internals', TextKit.slugify('  Hello Dart World! '));
  note('`TextKit` is the exported surface; `_Slugifier` is an internal detail');
  note('nobody outside this library can name.');

  topic('Import forms (syntax reference — one file cannot demo them)');
  note("import 'dart:math';                      // whole library");
  note("import 'dart:math' show min, max;        // ONLY these symbols");
  note("import 'dart:math' hide Random;          // everything except these");
  note("import 'dart:math' as math;              // prefixed: math.pi");
  note("import 'package:x/x.dart';               // a pub dependency");
  note("import '../core/utils.dart';             // relative, same package");
  note("import 'heavy.dart' deferred as heavy;   // lazy: await heavy.loadLibrary()");
  note('This file uses the `as` form: `import \'dart:math\' as math`.');

  topic('export and the barrel file');
  note('lib/my_package.dart:');
  note("  export 'src/models/user.dart' show User;");
  note("  export 'src/services/api.dart';");
  note('Consumers write ONE import and you keep freedom to move src/ around.');

  topic('part / part of (legacy, mostly codegen now)');
  note("  // user.dart:      part 'user.g.dart';");
  note("  // user.g.dart:    part of 'user.dart';");
  note('`part` files share ONE library, so they see each other\'s privates.');
  note('That is why json_serializable puts generated code in a part file.');
  note('Do not hand-write parts for organisation — use imports/exports.');

  topic('Package layout');
  note('lib/my_package.dart  -> the barrel: your PUBLIC api');
  note('lib/src/...          -> internals; importing another package\'s src/');
  note('                        is a lint error and can break on any release');
  note('test/                -> *_test.dart');
  note('bin/                 -> executables (dart run :name)');
  note('example/             -> usage sample shown on pub.dev');
  note('pubspec.yaml         -> name, version, environment, dependencies');

  topic('Version constraints (semver)');
  for (final (constraint, meaning) in const [
    ('^1.2.0', '>=1.2.0 <2.0.0   (caret: same major)'),
    ('^0.3.1', '>=0.3.1 <0.4.0   (pre-1.0: minor acts as major)'),
    ('>=1.2.0 <1.5.0', 'explicit range'),
    ('1.2.3', 'exact pin — avoid in libraries, blocks consumers'),
    ('any', 'no constraint — never do this'),
  ]) {
    print('  ${constraint.padRight(16)} $meaning');
  }
  note('');
  note('Apps: COMMIT pubspec.lock for reproducible builds.');
  note('Packages: do NOT commit it — consumers resolve their own versions.');
  note('`dart pub get` respects the lock; `dart pub upgrade` rewrites it.');
  note('dev_dependencies (test, build_runner, lints) never ship to users.');
}

class BankAccount {
  int _balance; // private to this LIBRARY (this file)
  BankAccount(this._balance);

  int get balance => _balance;
  void deposit(int amount) => _balance += amount;
}

/// Different class, same library -> `_balance` is visible.
class AccountAuditor {
  int peek(BankAccount account) => account._balance;
}

String _internalHelper(String input) => 'handled "$input" privately';

/// The only symbol a consumer would import.
class TextKit {
  const TextKit._();
  static String slugify(String input) => _Slugifier().run(input);
}

/// Library-private implementation detail.
class _Slugifier {
  String run(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');
}

// =============================================================================
// SECTION 12 — JSON & SERIALIZATION
// =============================================================================
// Points covered:
//   * jsonEncode / jsonDecode; decode produces a `dynamic` tree
//   * confine `dynamic` to fromJson — validate at the boundary
//   * nested objects and lists: (j['x'] as List).map(T.fromJson).toList()
//   * enums by NAME, nullable fields with defaults
//   * DateTime and other non-JSON types need explicit conversion
//   * toJson round-trip; toEncodable for custom objects
//   * DTO != domain entity — map between them
//   * big payloads: parse in an isolate
// =============================================================================

Future<void> section12JsonAndSerialization() async {
  section('SECTION 12 · JSON & SERIALIZATION');

  topic('jsonEncode / jsonDecode basics');
  const raw = '{"id":1,"name":"Ada","tags":["dart","flutter"],"active":true}';
  final decoded = jsonDecode(raw);
  show('decoded runtimeType', decoded.runtimeType);
  show('decoded value', decoded);
  show('re-encoded', jsonEncode(decoded));
  show('pretty printed', '\n${const JsonEncoder.withIndent('  ').convert(decoded)}');
  note('jsonDecode returns dynamic: Map<String,dynamic> / List<dynamic> /');
  note('String / num / bool / null. Nothing is type-checked yet.');

  topic('Typed parsing with validation at the boundary');
  const userJson = '''
  {
    "id": 7,
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "role": "admin",
    "createdAt": "2026-08-17T10:30:00.000Z",
    "address": {"city": "London", "zip": "NW1"},
    "orders": [
      {"id": "o1", "amountCents": 129999, "status": "delivered"},
      {"id": "o2", "amountCents": 4900, "status": "pending"}
    ]
  }''';
  final dto = UserDto.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  show('parsed DTO', dto);
  show('nested object', dto.address);
  show('nested list', dto.orders);
  show('enum parsed by name', dto.role);
  show('DateTime parsed from ISO-8601', dto.createdAt.toIso8601String());

  topic('Round trip');
  final encoded = jsonEncode(dto.toJson());
  final reparsed = UserDto.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  show('round-trip equal', reparsed.toJson().toString() == dto.toJson().toString());
  show('encoded', encoded);

  topic('Missing, null, and wrong-typed fields');
  for (final (label, body) in [
    ('missing optional', '{"id":1,"name":"X","email":"x@y.z","role":"viewer"}'),
    ('explicit null', '{"id":1,"name":"X","email":"x@y.z","role":"viewer","address":null}'),
    ('unknown enum', '{"id":1,"name":"X","email":"x@y.z","role":"wizard"}'),
    ('wrong type', '{"id":"one","name":"X","email":"x@y.z","role":"viewer"}'),
    ('missing required', '{"name":"X"}'),
  ]) {
    try {
      final parsed = UserDto.fromJson(jsonDecode(body) as Map<String, dynamic>);
      print('  ${label.padRight(18)} -> ok: role=${parsed.role.name}, '
          'address=${parsed.address}');
    } on FormatException catch (e) {
      print('  ${label.padRight(18)} -> FormatException: ${e.message}');
    }
  }
  note('Every failure is a clear FormatException, not a late null crash.');

  topic('Enums: serialize by NAME, never by index');
  show('Role.values by name', {for (final r in Role.values) r.name: r.index});
  show('parse "admin"', parseRole('admin'));
  show('parse garbage -> null', tryParseRole('nope'));
  note('Reorder the enum and every persisted `index` silently changes meaning.');

  topic('toEncodable for types JSON does not know');
  final payload = {'when': DateTime(2026, 8, 17), 'amount': const Cents(4900)};
  show('jsonEncode with toEncodable', jsonEncode(payload, toEncodable: encodeExtra));
  try {
    jsonEncode({'bad': Object()});
  } on JsonUnsupportedObjectError catch (_) {
    show('encoding an unknown type', 'JsonUnsupportedObjectError');
  }

  topic('DTO vs domain entity');
  final domainUser = dto.toDomain();
  show('domain entity', domainUser);
  show('domain total spend', domainUser.totalSpend.formatted);
  note('The DTO mirrors the WIRE (nullable, snake_case, strings for dates).');
  note('The entity models your DOMAIN (non-nullable, rich types, invariants).');
  note('A mapper between them means an API change touches one file.');

  topic('Big payloads: parse in an isolate');
  final bigJson = jsonEncode({
    'items': [for (var i = 0; i < 20000; i++) {'id': i, 'name': 'item$i'}],
  });
  show('payload size', '${(bigJson.length / 1024).toStringAsFixed(1)} KB');

  final mainClock = Stopwatch()..start();
  final onMain = countItems(bigJson);
  show('parsed on the main isolate', '$onMain items in ${mainClock.elapsedMilliseconds}ms (BLOCKS the UI)');

  final isolateClock = Stopwatch()..start();
  final offMain = await Iso.parse(bigJson);
  show('parsed via Isolate.run', '$offMain items in ${isolateClock.elapsedMilliseconds}ms (UI stays live)');
  note('In Flutter: `await compute(countItems, bigJson)`. Rule of thumb —');
  note('payloads over a few hundred KB belong off the main isolate.');

  topic('Codegen');
  note('Hand-written fromJson is fine for a few models and has zero deps.');
  note('At scale use json_serializable (@JsonSerializable + part \'x.g.dart\')');
  note('or freezed (immutability + copyWith + unions + JSON in one).');
  note('Both need build_runner: `dart run build_runner build -d`.');
  note('`dart:mirrors` runtime reflection does NOT exist in Flutter -> codegen');
  note('is the only option (see Section 14).');
}

enum Role { viewer, editor, admin }

Role parseRole(String name) => Role.values.byName(name);
Role? tryParseRole(String name) =>
    Role.values.where((r) => r.name == name).firstOrNull;

class AddressDto {
  final String city;
  final String zip;
  const AddressDto({required this.city, required this.zip});

  factory AddressDto.fromJson(Map<String, dynamic> json) => AddressDto(
        city: _requireString(json, 'city'),
        zip: _requireString(json, 'zip'),
      );

  Map<String, dynamic> toJson() => {'city': city, 'zip': zip};

  @override
  String toString() => 'Address($city, $zip)';
}

class OrderDto {
  final String id;
  final int amountCents;
  final String status;
  const OrderDto({required this.id, required this.amountCents, required this.status});

  factory OrderDto.fromJson(Map<String, dynamic> json) => OrderDto(
        id: _requireString(json, 'id'),
        amountCents: _requireInt(json, 'amountCents'),
        status: _requireString(json, 'status'),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'amountCents': amountCents, 'status': status};

  @override
  String toString() => 'Order($id, ${Cents(amountCents).formatted}, $status)';
}

class UserDto {
  final int id;
  final String name;
  final String email;
  final Role role;
  final DateTime createdAt;
  final AddressDto? address; // optional
  final List<OrderDto> orders; // defaults to empty

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.address,
    this.orders = const [],
  });

  /// The ONLY place `dynamic` is allowed to live.
  factory UserDto.fromJson(Map<String, dynamic> json) {
    final rawRole = _requireString(json, 'role');
    final role = tryParseRole(rawRole);
    if (role == null) {
      throw FormatException('unknown role "$rawRole" (expected one of '
          '${Role.values.map((r) => r.name).join(", ")})');
    }

    final rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is String
        ? (DateTime.tryParse(rawCreatedAt) ??
            (throw FormatException('createdAt is not ISO-8601: $rawCreatedAt')))
        : DateTime.fromMillisecondsSinceEpoch(0);

    final rawAddress = json['address'];
    if (rawAddress != null && rawAddress is! Map<String, dynamic>) {
      throw const FormatException('address must be an object or null');
    }

    final rawOrders = json['orders'];
    if (rawOrders != null && rawOrders is! List) {
      throw const FormatException('orders must be a list');
    }

    return UserDto(
      id: _requireInt(json, 'id'),
      name: _requireString(json, 'name'),
      email: _requireString(json, 'email'),
      role: role,
      createdAt: createdAt,
      address: rawAddress == null
          ? null
          : AddressDto.fromJson(rawAddress as Map<String, dynamic>),
      orders: rawOrders == null
          ? const []
          : (rawOrders as List)
              .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name, // by NAME
        'createdAt': createdAt.toIso8601String(),
        if (address != null) 'address': address!.toJson(),
        'orders': orders.map((o) => o.toJson()).toList(),
      };

  /// Wire model -> domain model.
  DomainUser toDomain() => DomainUser(
        id: UserId(id),
        name: name,
        email: Email.parse(email) ?? (throw FormatException('bad email: $email')),
        role: role,
        totalSpend: Cents(orders.fold(0, (acc, o) => acc + o.amountCents)),
      );

  @override
  String toString() =>
      'UserDto($id, $name, ${role.name}, orders=${orders.length})';
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('"$key" must be a String, got ${value.runtimeType}');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('"$key" must be an int, got ${value.runtimeType}');
  }
  return value;
}

/// Domain entity: rich types, no nullables, no wire concerns.
class DomainUser {
  final UserId id;
  final String name;
  final Email email;
  final Role role;
  final Cents totalSpend;

  const DomainUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.totalSpend,
  });

  @override
  String toString() => 'DomainUser(${id.tag}, $name, ${email.domain}, '
      '${role.name}, ${totalSpend.formatted})';
}

/// Teaches jsonEncode how to handle types it does not know.
Object? encodeExtra(Object? value) => switch (value) {
      DateTime() => value.toIso8601String(),
      Cents() => value.value,
      _ => throw JsonUnsupportedObjectError(value),
    };

/// Top-level so it can run inside an isolate.
int countItems(String json) =>
    ((jsonDecode(json) as Map<String, dynamic>)['items'] as List).length;

/// Wrapper so the isolate entry point stays a plain top-level call.
class Iso {
  static Future<int> parse(String json) => Isolate.run(() => countItems(json));
}

// =============================================================================
// SECTION 13 — MEMORY MANAGEMENT & GARBAGE COLLECTION
// =============================================================================
// Points covered:
//   * objects live until UNREACHABLE from a root — GC is automatic
//   * generational GC: cheap young-space scavenge, then promotion to old space
//     collected by mark-sweep/mark-compact
//   * the classic Flutter leaks: uncancelled subscriptions, live timers,
//     undisposed controllers, unbounded static caches, captured context
//   * fixes: dispose owners, bound caches, WeakReference, cut per-frame garbage
//   * Expando for attaching data without keeping objects alive
//   * Finalizer is BEST-EFFORT — never required to run
//   * debug with DevTools memory view + retaining paths
// =============================================================================

Future<void> section13MemoryAndGc() async {
  section('SECTION 13 · MEMORY & GARBAGE COLLECTION');

  topic('Reachability decides everything');
  note('Roots = globals/statics, the current stack, live isolate state.');
  note('If no chain of references reaches your object, it is garbage —');
  note('regardless of how big it is or how "done" you think you are with it.');
  note('A leak in Dart is therefore always an UNWANTED REFERENCE, never');
  note('"forgot to free".');

  topic('Generational GC');
  note('New space  : bump-pointer allocation, semi-space SCAVENGE. Most objects');
  note('             die here (widgets, closures, boxes) — collection is cheap');
  note('             and proportional to SURVIVORS, not to garbage.');
  note('Old space  : survivors get promoted; collected by concurrent');
  note('             mark-sweep / mark-compact. Slower, rarer.');
  note('Consequence: short-lived garbage is nearly free; long-lived leaks are');
  note('             expensive. Allocating in build() is normal — RETAINING is');
  note('             the sin.');

  topic('LEAK 1 — an uncancelled stream subscription');
  final controller = StreamController<int>.broadcast();
  final leaky = LeakyListener(controller.stream);
  final tidy = TidyListener(controller.stream);
  controller.add(1);
  await Future<void>.delayed(Duration.zero);
  show('leaky received', leaky.received);
  show('tidy received', tidy.received);

  await tidy.dispose(); // cancels its subscription
  controller.add(2);
  await Future<void>.delayed(Duration.zero);
  show('after tidy.dispose() — leaky still receiving', leaky.received);
  show('after tidy.dispose() — tidy stopped', tidy.received);
  show('controller.hasListener (leaky is still attached)', controller.hasListener);

  await leaky.subscription.cancel(); // what LeakyListener forgot to do
  await controller.close();
  note('The live subscription holds the callback, which holds the LISTENER');
  note('object, which in Flutter holds State -> context -> element -> subtree.');
  note('One missing cancel() can retain an entire screen.');

  topic('LEAK 2 — a periodic timer nobody cancels');
  var tickCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 5), (_) => tickCount++);
  await Future<void>.delayed(const Duration(milliseconds: 30));
  show('ticks while alive', tickCount);
  timer.cancel();
  final afterCancel = tickCount;
  await Future<void>.delayed(const Duration(milliseconds: 20));
  show('ticks after cancel (frozen)', '$afterCancel -> $tickCount');
  note('An uncancelled Timer.periodic is a root: it keeps its closure and');
  note('everything captured alive forever, and burns CPU every tick.');

  topic('LEAK 3 — an unbounded static cache');
  UnboundedCache.put('a', 'x' * 10);
  UnboundedCache.put('b', 'y' * 10);
  show('unbounded cache size after 2 writes', UnboundedCache.size);
  note('`static final Map` is a GC ROOT. Anything you put there is immortal.');

  final lru = LruCache<String, int>(maxSize: 3);
  for (final key in ['a', 'b', 'c', 'd', 'e']) {
    lru[key] = key.codeUnitAt(0);
  }
  show('bounded LRU after 5 writes (max 3)', lru.keys);
  lru['c']; // touch 'c' so it becomes most-recently-used
  lru['f'] = 6;
  show('after touching "c" then inserting "f"', lru.keys);
  note('Bound every cache: max entries, TTL, or both.');

  topic('WeakReference — cache without retaining');
  var payload = LargePayload('report-2026');
  final weak = WeakReference(payload);
  show('target while a strong ref exists', weak.target?.label);
  payload = LargePayload('replacement'); // drop the only strong ref
  // Create garbage to encourage (never force) a collection.
  for (var i = 0; i < 200000; i++) {
    LargePayload('churn$i');
  }
  await Future<void>.delayed(const Duration(milliseconds: 20));
  show('target after dropping the strong ref', weak.target?.label ?? '<collected>');
  note('NON-DETERMINISTIC: you cannot force a GC from Dart. Either result here');
  note('is correct — the point is that a WeakReference never PREVENTS');
  note('collection, so it cannot leak.');

  topic('Expando — attach data to an object you do not own');
  final metadata = Expando<String>('debugLabel');
  final host = LargePayload('host');
  metadata[host] = 'attached without touching the class';
  show('expando lookup', metadata[host]);
  note('The Expando does not keep `host` alive — when host dies, the entry');
  note('goes with it. This is how you add "fields" from an extension.');

  topic('Finalizer — best effort ONLY');
  final finalizer = Finalizer<String>((label) => print('  finalized: $label'));
  final tracked = LargePayload('finalizable');
  finalizer.attach(tracked, 'finalizable', detach: tracked);
  show('attached a finalizer to', tracked.label);
  finalizer.detach(tracked);
  note('Dart makes NO guarantee a finalizer ever runs (not at exit, not at');
  note('all). Never release a socket/file/native handle only in a finalizer —');
  note('use an explicit dispose() and treat the finalizer as a safety net.');

  topic('ResourceScope — dispose many things at once');
  final scope = ResourceScope();
  final scoped = StreamController<int>.broadcast();
  scope.addSubscription(scoped.stream.listen((_) {}));
  scope.addTimer(Timer.periodic(const Duration(milliseconds: 5), (_) {}));
  scope.addDisposer(() async => scoped.close());
  show('registered resources', scope.length);
  await scope.dispose();
  show('after dispose', scope.length);
  show('controller still has a listener?', scoped.hasListener);
  note('One owner, one dispose() — the pattern behind Flutter\'s State.dispose.');

  topic('Flutter leak checklist');
  note('dispose(): cancel subscriptions · cancel timers · dispose Animation/');
  note('  Text/Scroll/Tab controllers · remove listeners · close sinks');
  note('Never capture BuildContext in a long-lived object or a late callback.');
  note('Bound every cache and every image cache override.');
  note('Debug: DevTools > Memory > snapshot, diff, then "retaining path" on a');
  note('  class whose instance count only ever grows.');
  note('Cut per-frame garbage: const widgets, cached Paint/TextPainter, no');
  note('  allocations inside build()/paint() loops.');
}

class LeakyListener {
  final List<int> received = [];
  late final StreamSubscription<int> subscription;
  LeakyListener(Stream<int> stream) {
    subscription = stream.listen(received.add); // never cancelled — the leak
  }
}

class TidyListener {
  final List<int> received = [];
  late final StreamSubscription<int> _subscription;
  TidyListener(Stream<int> stream) {
    _subscription = stream.listen(received.add);
  }

  Future<void> dispose() => _subscription.cancel();
}

class UnboundedCache {
  static final Map<String, String> _entries = {}; // a GC root: grows forever
  static void put(String key, String value) => _entries[key] = value;
  static int get size => _entries.length;
}

/// Least-recently-used cache with a hard cap.
class LruCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  LruCache({required this.maxSize});

  V? operator [](K key) {
    if (!_entries.containsKey(key)) return null;
    final value = _entries.remove(key) as V;
    _entries[key] = value; // reinsert => most recently used
    return value;
  }

  void operator []=(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > maxSize) {
      _entries.remove(_entries.keys.first); // evict least recently used
    }
  }

  List<K> get keys => _entries.keys.toList();
}

class LargePayload {
  final String label;
  final List<int> bytes;
  LargePayload(this.label) : bytes = List<int>.filled(64, 0);
}

/// Owns a set of resources and releases them together.
class ResourceScope {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<Future<void> Function()> _disposers = [];

  void addSubscription(StreamSubscription<dynamic> sub) => _subscriptions.add(sub);
  void addTimer(Timer timer) => _timers.add(timer);
  void addDisposer(Future<void> Function() disposer) => _disposers.add(disposer);

  int get length => _subscriptions.length + _timers.length + _disposers.length;

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final disposer in _disposers) {
      await disposer();
    }
    _subscriptions.clear();
    _timers.clear();
    _disposers.clear();
  }
}

// =============================================================================
// SECTION 14 — DART COMPILATION (VM, JIT, AOT, snapshots, tree shaking)
// =============================================================================
// Points covered:
//   * pipeline: source -> CFE -> Kernel (.dill) -> JIT | AOT | dart2js/wasm
//   * JIT (debug): hot reload, asserts on, unoptimized-then-optimized tiers
//   * AOT (release): fast startup, no runtime codegen (App Store compliant)
//   * hot reload keeps state; hot restart resets it
//   * tree shaking removes unreachable code and unused icon glyphs
//   * no dart:mirrors in Flutter -> codegen instead of reflection
//   * ALWAYS benchmark in profile/release, never in debug
// =============================================================================

void section14DartCompilation() {
  section('SECTION 14 · DART COMPILATION');

  topic('What this binary knows about itself');
  show('Dart version', Platform.version);
  show('OS / arch', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  show('logical cores', Platform.numberOfProcessors);

  topic('Detecting the compilation mode at runtime');
  var assertsEnabled = false;
  assert(() {
    assertsEnabled = true;
    return true;
  }());
  const productMode = bool.fromEnvironment('dart.vm.product');
  show('asserts enabled (JIT / debug)', assertsEnabled);
  show('bool.fromEnvironment("dart.vm.product")', productMode);
  note(assertsEnabled
      ? 'Running under the JIT with asserts on — this is DEBUG-like.'
      : 'Asserts are compiled out — this is a RELEASE-like build.');
  note('`assert` statements cost NOTHING in release: they are removed, not');
  note('skipped. That is why invariants belong in asserts, not `if` checks.');

  topic('The pipeline');
  note('  .dart  --CFE-->  Kernel AST (.dill)  -->  one of:');
  note('    JIT  : dart run / flutter run (debug)   -> interpret, then optimise');
  note('           hot spots; can PATCH code at runtime = hot reload');
  note('    AOT  : dart compile exe / flutter build -> machine code ahead of');
  note('           time, no compiler shipped, fastest startup');
  note('    Web  : dart2js (JS) or dart2wasm (WasmGC) -> tree-shaken bundle');

  topic('JIT vs AOT trade-offs');
  for (final (aspect, jit, aot) in const [
    ('startup', 'slower (warm-up)', 'fast (precompiled)'),
    ('peak speed', 'high once warm', 'high, predictable'),
    ('hot reload', 'YES', 'no'),
    ('asserts', 'on', 'removed'),
    ('binary size', 'larger (VM+compiler)', 'smaller, tree-shaken'),
    ('used for', 'development', 'production / stores'),
  ]) {
    print('  ${aspect.padRight(12)} JIT: ${jit.padRight(22)} AOT: $aot');
  }

  topic('Hot reload vs hot restart');
  note('Hot reload  : inject changed methods into the running isolate, KEEP');
  note('              state. Fails for main(), initState, const/global');
  note('              initializers, class shape changes, native code.');
  note('Hot restart : tear the isolate down, rebuild, LOSE state.');
  note('Both are JIT-only — a release build has no compiler to inject with.');

  topic('Tree shaking');
  note('Only code reachable from main() ships. Consequences:');
  note('  * reflection would make EVERYTHING reachable -> dart:mirrors is');
  note('    unsupported in Flutter/AOT. Use build_runner codegen instead.');
  note('  * dynamic lookups (a map of String -> Function built at runtime)');
  note('    defeat shaking; prefer explicit references / const tables.');
  note('  * `--no-tree-shake-icons` disables the MaterialIcons pass; the');
  note('    release build normally logs:');
  note('      "Font asset ... tree-shaken, reducing it from 1.6MB to 3KB"');

  topic('const helps the compiler');
  const x = ConstMarker('shared');
  const y = ConstMarker('shared');
  show('identical const values (canonicalized at compile time)', identical(x, y));
  note('const objects are built once and baked into the snapshot: no runtime');
  note('allocation, and `const` widgets let Flutter skip whole subtrees.');

  topic('Commands worth memorising');
  note('dart run file.dart                 # JIT; asserts OFF by default');
  note('dart run --enable-asserts file.dart # JIT with asserts (do this!)');
  note('dart compile exe file.dart         # native AOT binary');
  note('dart compile js  file.dart         # JS output');
  note('dart run --enable-asserts ...      # force asserts on');
  note('flutter run                        # debug JIT + hot reload');
  note('flutter run --profile              # AOT + tracing: MEASURE HERE');
  note('flutter run --release              # AOT, no tooling overhead');
  note('flutter build apk --analyze-size   # where the bytes went');

  topic('Benchmarking rule');
  note('Debug builds are 3-10x slower: asserts on, no inlining, service');
  note('protocol attached, extra checks in the framework. A "slow list" in');
  note('debug is often perfectly smooth in profile. Never quote debug numbers.');
}

class ConstMarker {
  final String label;
  const ConstMarker(this.label);
}

// =============================================================================
// SECTION 15 — MINI PROJECTS (one per notes file)
// =============================================================================

Future<void> section15MiniProjects() async {
  section('SECTION 15 · MINI PROJECTS (one per notes file)');

  // -- 01 -------------------------------------------------------------------
  topic('01 · Event-loop visualizer');
  final visualizer = EventLoopVisualizer();
  await visualizer.run();
  for (final line in visualizer.log) {
    note('  $line');
  }

  // -- 02 -------------------------------------------------------------------
  topic('02 · Resilient fetch layer (timeout + backoff + parallel)');
  final client = ResilientClient(baseDelay: const Duration(milliseconds: 5));
  final combined = await client.fetchAll({
    'users': () => fakeCall('users', const Duration(milliseconds: 20)),
    'orders': () => fakeCall('orders', const Duration(milliseconds: 30)),
    'flaky': client.flakyEndpoint,
    'dead': () => Future<String>.error(StateError('permanently down')),
    'slow': () => fakeCall('slow', const Duration(milliseconds: 500)),
  });
  for (final entry in combined.results.entries) {
    print('  ok   ${entry.key.padRight(8)} -> ${entry.value}');
  }
  for (final entry in combined.errors.entries) {
    print('  fail ${entry.key.padRight(8)} -> ${entry.value}');
  }
  note('One dead endpoint did not sink the other four; "slow" hit the timeout.');

  // -- 03 -------------------------------------------------------------------
  topic('03 · Live search pipeline — see Section 3 (debounce + stale drop)');
  note('Built above: debounce(30ms) + generation counter for switchMap');
  note('cancellation, with every subscription cancelled and controller closed.');

  // -- 04 -------------------------------------------------------------------
  topic('04 · Parallel batch processor — see Section 4 (IsolatePool)');
  note('Built above: a reusable pool of N workers, round-robin dispatch,');
  note('progress printed per completed task, measured speedup, clean shutdown.');

  // -- 05 -------------------------------------------------------------------
  topic('05 · Generic repository + Result core');
  final users = InMemoryRepository<UserEntity>();
  final products = InMemoryRepository<ProductEntity>();
  users.save(const UserEntity('u1', 'Ada'));
  products.save(const ProductEntity('p1', 'Keyboard', 499000));
  show('two entity types, one generic repo', '${users.ids} + ${products.ids}');
  show('typed find (hit)', describe(findEntity(users, 'u1')));
  show('typed find (miss)', describe(findEntity(users, 'zzz')));
  show('mapped Result', describe(findEntity(products, 'p1').map((p) => p.name)));

  // -- 06 -------------------------------------------------------------------
  topic('06 · Text decoration engine — see Section 6');
  show('with Bold, Italic', BoldThenItalic().render('order matters'));
  show('with Italic, Bold', ItalicThenBold().render('order matters'));
  note('Same mixins, different `with` order, different nesting.');

  // -- 07 -------------------------------------------------------------------
  topic('07 · Fluent formatting toolkit');
  show('String', '  hello   dart world '.cleaned.titleCase);
  show('num', '${129999.asRupees} @ ${0.185.asPercent}');
  show('DateTime', DateTime(2026, 8, 17).ymd);
  show('chained', '4111111111111111'.masked(visible: 4));

  // -- 08 -------------------------------------------------------------------
  topic('08 · Typed-primitives domain kit');
  const uid = UserId(7);
  const oid = OrderId(1042);
  show('ids cannot be swapped', chargeOrder(uid, oid));
  show('money math stays integral', (const Cents(129999) + const Cents(4900)).formatted);
  show('validated email', Email.parse('ada@example.com')?.domain);
  show('zero allocation: runtime type', uid.runtimeType);

  // -- 09 -------------------------------------------------------------------
  topic('09 · Object-creation patterns kit');
  show('immutable Money via const', const Cents(2500).formatted);
  show('cached factory (identical)', identical(IconGlyph.named('star'), IconGlyph.named('star')));
  show('injected fake Clock', OrderService(clock: FixedClock(DateTime(2020, 1, 1))).stamp());
  show('callable policy', const PasswordPolicy(minLength: 8)('hunter2'));
  show('singleton', identical(AppLogger.instance, AppLogger.instance));

  // -- 10 -------------------------------------------------------------------
  topic('10 · Immutable app-state core with undo');
  var state = const AppState();
  final history = <AppState>[state];
  for (final action in const [AddToCart('Book'), AddToCart('Pen'), ChangeTheme('dark')]) {
    state = reduce(state, action);
    history.add(state);
  }
  show('final state', state);
  show('history length', history.length);
  show('undo once', history[history.length - 2]);
  show('undo twice', history[history.length - 3]);
  show('equal states compare equal', history.first == const AppState());

  // -- 11 -------------------------------------------------------------------
  topic('11 · Reusable utility package (structure, not runnable here)');
  note('A package cannot be demonstrated inside one file. The shape to create:');
  note('  my_utils/');
  note('    pubspec.yaml            name/version/environment/dependencies');
  note('    lib/my_utils.dart       barrel: export \'src/text.dart\' show TextKit;');
  note('    lib/src/text.dart       implementation + library-private helpers');
  note('    test/text_test.dart     unit tests');
  note('    example/main.dart       shown on pub.dev');
  note('Verify with: dart pub get && dart test && dart analyze');
  note('This file models the idea in miniature: `TextKit` is public,');
  show('  TextKit.slugify', TextKit.slugify('Reusable Utility Package!'));
  note('  and `_Slugifier` is unreachable from outside the library.');

  // -- 12 -------------------------------------------------------------------
  topic('12 · Typed API client (DTO -> entity, isolate parse)');
  const apiResponse = '''
  {"id":9,"name":"Grace Hopper","email":"grace@navy.mil","role":"editor",
   "createdAt":"2026-01-05T08:00:00.000Z",
   "orders":[{"id":"o9","amountCents":250000,"status":"delivered"}]}''';
  final apiDto = UserDto.fromJson(jsonDecode(apiResponse) as Map<String, dynamic>);
  show('DTO', apiDto);
  show('domain entity', apiDto.toDomain());
  show('offloaded parse', await Iso.parse(jsonEncode({'items': [1, 2, 3]})));

  // -- 13 -------------------------------------------------------------------
  topic('13 · Leak-safe resource manager');
  final scope = ResourceScope();
  final feed = StreamController<int>.broadcast();
  var delivered = 0;
  scope.addSubscription(feed.stream.listen((_) => delivered++));
  var ticks = 0;
  scope.addTimer(Timer.periodic(const Duration(milliseconds: 5), (_) => ticks++));
  // The scope does NOT own `feed` here, so the stream stays usable after
  // dispose() — that is what lets us prove the subscription really is gone.
  var disposerRan = false;
  scope.addDisposer(() async => disposerRan = true);

  feed.add(1);
  feed.add(2);
  await Future<void>.delayed(const Duration(milliseconds: 25));
  show('before dispose', 'delivered=$delivered ticks=$ticks listeners=${feed.hasListener}');

  await scope.dispose();
  final ticksAtDispose = ticks;
  feed.add(3); // nobody is listening any more
  await Future<void>.delayed(const Duration(milliseconds: 25));
  show('after dispose',
      'delivered=$delivered (event 3 ignored) ticks frozen at $ticksAtDispose->$ticks '
      'listeners=${feed.hasListener} customDisposer=$disposerRan');
  await feed.close();
  final bounded = LruCache<int, int>(maxSize: 3);
  for (var i = 0; i < 100; i++) {
    bounded[i] = i;
  }
  show('cache stayed bounded after 100 writes', bounded.keys);

  // -- 14 -------------------------------------------------------------------
  topic('14 · Compilation report (measurements, not runnable here)');
  note('Needs three real builds of a Flutter app; record for each:');
  note('  flutter run            (debug/JIT)   startup ms, hot reload works?');
  note('  flutter run --profile  (AOT+trace)   startup ms, frame times');
  note('  flutter build apk --release          APK size, icon-shaking log line');
  note('Then explain: debug is slower because asserts + no inlining + service');
  note('protocol; release is smaller because of tree shaking; a package using');
  note('dart:mirrors fails in release because AOT ships no reflection metadata.');
  note('What this file CAN measure right now:');
  var assertsOn = false;
  assert(() {
    assertsOn = true;
    return true;
  }());
  show('  asserts enabled (=> JIT/debug)', assertsOn);
  show('  dart.vm.product', bool.fromEnvironment('dart.vm.product'));
  show('  SDK', Platform.version.split(' ').first);

  print('\nAll 14 topics demonstrated. Read each notes file for the theory.');
}

class ProductEntity implements Entity {
  @override
  final String id;
  final String name;
  final int priceCents;
  const ProductEntity(this.id, this.name, this.priceCents);

  @override
  String toString() => 'Product($id, $name)';
}

/// Generic lookup returning a Result instead of a nullable.
Result<T, String> findEntity<T extends Entity>(
  InMemoryRepository<T> repo,
  String id,
) {
  final found = repo.findById(id);
  return found == null ? Err('no $T with id "$id"') : Ok(found);
}

/// Mini project 01: schedules a labelled mix of work and records the real order.
class EventLoopVisualizer {
  final List<String> log = [];

  Future<void> run() async {
    log.add('predicted: sync -> microtasks -> events');
    log.add('actual:');
    log.add('  sync 1');
    scheduleMicrotask(() => log.add('  microtask 1'));
    Future(() => log.add('  event 1 (Future)'));
    Future.microtask(() => log.add('  microtask 2'));
    Timer.run(() => log.add('  event 2 (Timer)'));
    log.add('  sync 2');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Blocking vs chunked, with a timer as the "frame".
    final blockClock = Stopwatch()..start();
    var blockedAt = -1;
    Timer(const Duration(milliseconds: 5), () => blockedAt = blockClock.elapsedMilliseconds);
    busyWait(const Duration(milliseconds: 80));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    log.add('  blocking: 5ms timer fired at ${blockedAt}ms');

    final chunkClock = Stopwatch()..start();
    var chunkedAt = -1;
    Timer(const Duration(milliseconds: 5), () => chunkedAt = chunkClock.elapsedMilliseconds);
    await chunkedWork(
      total: const Duration(milliseconds: 80),
      slice: const Duration(milliseconds: 4),
    );
    log.add('  chunked:  5ms timer fired at ${chunkedAt}ms');
  }
}

/// Mini project 02: timeout + exponential-backoff retry + parallel fan-out that
/// collects per-endpoint errors instead of failing the whole batch.
class ResilientClient {
  final Duration baseDelay;
  final Duration timeout;
  final int maxAttempts;
  var _flakyCalls = 0;

  ResilientClient({
    required this.baseDelay,
    this.timeout = const Duration(milliseconds: 200),
    this.maxAttempts = 3,
  });

  /// Fails twice, then succeeds — proves the retry actually retries.
  Future<String> flakyEndpoint() async {
    _flakyCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (_flakyCalls < 3) throw StateError('flaky failure #$_flakyCalls');
    return 'flaky recovered after $_flakyCalls attempts';
  }

  Future<String> fetch(Future<String> Function() call) => retry(
        () => call().timeout(timeout),
        maxAttempts: maxAttempts,
        baseDelay: baseDelay,
      );

  /// Runs every endpoint in parallel; no single failure aborts the batch.
  Future<({Map<String, String> results, Map<String, String> errors})> fetchAll(
    Map<String, Future<String> Function()> endpoints,
  ) async {
    final results = <String, String>{};
    final errors = <String, String>{};

    await Future.wait(endpoints.entries.map((entry) async {
      try {
        results[entry.key] = await fetch(entry.value);
      } catch (e) {
        errors[entry.key] = e is TimeoutException ? 'timed out' : '$e';
      }
    }));

    return (results: results, errors: errors);
  }
}
