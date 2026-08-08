# Advanced Dart & Asynchrony — Interview Questions

> Concurrency, the event loop, Futures/Streams/isolates, and the power features that separate a Dart *engineer* from a Flutter *user*. Depth lives in [02 Advanced Dart](../02%20Advanced%20Dart/README.md) — start with [01_event_loop.md](../02%20Advanced%20Dart/01_event_loop.md), and the runtime/threading foundations in [59 Computer Science Foundations](../59%20Computer%20Science%20Foundations/README.md).

This topic tests whether you understand *what actually runs your code*. Interviewers lean hard here because the event loop, isolates, and stream lifecycle expose the difference between someone who sprinkles `await` and someone who can debug jank, leaks, and race conditions.

## 🟢 Basic

**1. Is Dart single-threaded? Then how does it do async work?**
A single isolate runs on one thread with one event loop. It never runs two pieces of your Dart code at the same instant. Async work isn't parallelism — it's *interleaving*: I/O, timers, and futures register callbacks that the event loop runs one at a time when the current synchronous chunk finishes. True parallelism needs a second isolate. So "asynchronous" means "not now, later on this same thread," not "on another core."

**2. What is a `Future`?**
A `Future<T>` is a handle to a value that isn't available yet — it will complete once with either a value or an error. Creating a future starts the work (or schedules it); you attach continuations with `then`/`catchError` or `await`. It's Dart's equivalent of a JS Promise. A future can be in one of three states: uncompleted, completed-with-value, or completed-with-error.

**3. What's the difference between the microtask queue and the event queue?**
Both are FIFO queues the event loop drains, but the microtask queue has strict priority. After each event-queue task, the loop fully empties the microtask queue *before* touching the next event. Microtasks come from `scheduleMicrotask` and from resolved-future continuations; events come from timers, I/O, gestures, and `Timer.run`. Practical rule: microtasks are for short internal follow-ups; abusing them can starve the event queue and freeze the UI.

**4. Predict the output.**
```dart
void main() {
  print('A');
  Future(() => print('B'));                 // event queue
  Future.microtask(() => print('C'));        // microtask queue
  Future.value(0).then((_) => print('D'));   // microtask (already complete)
  scheduleMicrotask(() => print('E'));       // microtask queue
  print('F');
}
// output: A F C D E B
```
Synchronous `A` and `F` first, then *all* microtasks in registration order (C, D, E), then the event-queue `B`.

**5. `async`/`await` vs `.then()` — what does `await` actually do?**
`await` pauses the enclosing `async` function and returns control to the caller/event loop; when the awaited future completes, the *rest* of the function is scheduled as a continuation (a microtask). It's syntactic sugar over `.then()`, but reads sequentially and gives you normal `try/catch`. `.then()` is still useful for fire-and-forget chaining or when you don't want to make the function `async`.

**6. What does an `async` function return, and when?**
It always returns a `Future`. It returns that future *synchronously* the moment execution first hits an `await` (or the end of the function). Code before the first `await` runs synchronously in the caller's turn — a common surprise:
```dart
Future<void> f() async { print('1'); await null; print('2'); }
void main() { f(); print('3'); }
// output: 1 3 2
```

**7. What is a `Stream`?**
A `Stream<T>` is a sequence of asynchronous events delivered over time — zero or more data events, and either a done or an error event. Think "a Future that can complete many times." You consume it with `await for`, `.listen()`, or stream operators (`map`, `where`, `take`). Futures are for one-shot results; streams are for ongoing sources like sockets, sensor readings, or UI events.

**8. `listen()` vs `await for` — when do you use each?**
`await for` reads a stream sequentially inside an `async` function and is clean for consuming until done, but it *blocks that function* and you can't easily manage the subscription. `.listen()` returns a `StreamSubscription` you can `pause`, `resume`, and `cancel`, and lets you keep running — which is what you almost always want in Flutter (e.g. cancel in `dispose`). Prefer `.listen()` when lifecycle control matters.

**9. What's a `StreamController` for?**
It's the standard way to *create* a stream you push events into manually via `add`, `addError`, and `close`. You expose `controller.stream` to consumers. Use it to bridge callback-based or imperative sources into the stream world (e.g. a WebSocket wrapper, a custom event bus). Always `close()` it to avoid leaks.

**10. What is an isolate, in one sentence?**
An isolate is Dart's unit of concurrency: an independent worker with its *own memory heap and event loop*, communicating only by message passing — so there's no shared mutable state and therefore no locks or data races.

**11. What is `compute()` and when do you reach for it?**
`compute(fn, message)` is a Flutter helper that spawns a one-off isolate, runs a top-level/static `fn` on `message`, returns the result as a `Future`, and tears the isolate down. Use it to move CPU-heavy work (parsing a large JSON, image processing, crypto) off the UI isolate so frames keep rendering. On modern Dart, `Isolate.run` is the more general equivalent.

**12. What is a mixin and why not just use inheritance?**
A `mixin` lets you inject a bundle of methods/fields into a class without a subclass relationship, and a class can mix in *many* of them (`class A extends B with M1, M2`). It's how Dart gets reuse across unrelated hierarchies without multiple inheritance's ambiguity. Example: `SingleTickerProviderStateMixin` gives a `State` the `vsync` capability.

**13. What is an extension method?**
Extensions add methods/getters to an existing type *you don't own* without subclassing or wrapping it, resolved statically at compile time. Example:
```dart
extension StringX on String {
  bool get isBlank => trim().isEmpty;
}
'  '.isBlank; // true
```
They're syntactic reach, not runtime polymorphism — dispatch is based on the *static* type.

**14. What does `const` give you that `final` doesn't?**
`final` is a runtime single-assignment; `const` is a *compile-time* constant, fully computed and canonicalized during compilation. Two identical `const` values are the same instance (canonicalization), which is why `const` widgets are cheap and skip rebuilds. Everything in a `const` object graph must itself be `const`.

## 🟡 Intermediate

**15. Walk through `Future.wait`, `Future.value`, and error handling.**
`Future.wait([...])` runs futures concurrently and completes with a `List` of results when *all* finish — but it completes with an *error* as soon as *any* one fails (use `eagerError` / catch per-future to change that). `Future.value(x)` wraps an already-available value in a completed future (its `then` fires on the microtask queue). Standard error handling: `try/catch` around `await`, or `.catchError`/`.then(onError:)` in chains.

**16. `catchError` vs `whenComplete` vs `try/catch`?**

| Tool | Fires on | Analogy |
|------|----------|---------|
| `.then(onValue)` | success | `try` body |
| `.catchError(fn)` | error (optionally `test:`) | `catch` |
| `.whenComplete(fn)` | success *or* error | `finally` |
| `await` + `try/catch/finally` | same, but linear | the whole thing |

`whenComplete` runs cleanup regardless of outcome and does not swallow the error (unless it throws its own). `catchError`'s optional `test:` predicate lets you catch only specific error types.

**17. How does `async`/`await` desugar?**
The compiler rewrites an `async` function into a state machine driven by the `Future`/microtask machinery. Each `await` becomes a suspension point: the function registers a continuation on the awaited future and returns; on completion the continuation resumes at the saved state as a microtask. That's why (a) the function returns a future immediately, (b) resumption is asynchronous even for already-complete futures, and (c) exceptions propagate through the returned future rather than up the sync stack.

**18. Predict the output — nested futures and microtasks.**
```dart
void main() {
  Future(() => print('1'));
  Future(() { print('2'); Future(() => print('3')); scheduleMicrotask(() => print('4')); });
  Future(() => print('5')).then((_) => print('6'));
  scheduleMicrotask(() => print('7'));
  print('8');
}
// output: 8 7 1 2 4 5 6 3
```
Sync `8`; microtask `7`; then event queue in order — `1`; `2` (which enqueues event `3` and microtask `4`); `4` drains before next event; `5` then its `then` continuation `6` (microtask); finally the deferred `3`.

**19. What's `unawaited` and why does it exist?**
`unawaited(future)` (from `dart:async` / `package:meta`) explicitly signals "I'm intentionally not awaiting this," silencing the `discarded_futures`/`unawaited_futures` lint. It documents intent and keeps you from *accidentally* dropping a future whose errors would otherwise go uncaught. Note: unawaited errors still surface to the isolate's error handler / zone — `unawaited` doesn't swallow them.

**20. Single-subscription vs broadcast streams.**

| | Single-subscription | Broadcast |
|--|--|--|
| Listeners | exactly one, ever | many, concurrently |
| Buffers before listen | yes (pauses source) | no — events fire whether or not anyone listens |
| Re-listen after cancel | no | yes |
| Typical source | file/socket read | UI/events, `Stream.periodic().asBroadcast...` |

Default `StreamController()` is single-subscription; use `StreamController.broadcast()` for many listeners. Listening twice to a single-subscription stream throws.

**21. How do you write your own stream with `async*` / `yield`?**
An `async*` function is a *stream generator*: each `yield` emits a data event, `yield*` delegates to another stream, and the stream completes when the function returns. It respects backpressure — it pauses at `yield` while the consumer is paused.
```dart
Stream<int> countTo(int n) async* {
  for (var i = 1; i <= n; i++) { await Future.delayed(Duration(milliseconds: 100)); yield i; }
}
```
(`sync*` + `yield` produces a lazy `Iterable` instead — synchronous, pull-based.)

**22. What are stream transformers, and name common operators.**
A transformer converts one stream into another. Built-in operators: `map`, `where`, `expand`, `take`/`skip`, `distinct`, `asyncMap` (awaits per event), `handleError`, `asBroadcastStream`. For custom logic use `.transform(StreamTransformer.fromHandlers(...))` or `package:rxdart` (`debounceTime`, `switchMap`, `combineLatest`) — heavily used in BLoC. `asyncMap` preserves order and awaits each result, unlike firing overlapping futures yourself.

**23. Why must you cancel stream subscriptions, and where in Flutter?**
An un-cancelled subscription keeps the callback (and its captured `this`/`State`) alive, leaking memory and — worse — calling `setState` on a disposed widget, which throws. Cancel in `State.dispose()`:
```dart
StreamSubscription? _sub;
@override void initState() { super.initState(); _sub = stream.listen(_onData); }
@override void dispose() { _sub?.cancel(); super.dispose(); }
```
Or use `StreamBuilder`, which manages the subscription for you.

**24. Why can't isolates just share objects like threads do?**
Because Dart's memory model is deliberately share-nothing: each isolate owns its heap, so there's no shared mutable state, no need for locks/mutexes, and no data races — the entire class of concurrency bugs that plague Java/C++ threads is designed out. The tradeoff is that communication is by *copying* messages across ports (structured clone), which costs serialization but keeps things safe. See [59 Computer Science Foundations](../59%20Computer%20Science%20Foundations/README.md) for the threads-vs-message-passing tradeoff.

**25. How do isolates communicate — ports?**
Via `SendPort`/`ReceivePort` pairs. You create a `ReceivePort`, pass its `sendPort` to the spawned isolate (through `Isolate.spawn`'s message), and each side sends messages the other receives as stream events. Messages must be sendable (primitives, lists/maps of sendables, `TransferableTypedData`; not closures capturing state or most native handles). `Isolate.run`/`compute` hide all this boilerplate for the common request/response case.

**26. Bounded generics — what and why?**
A bound constrains a type parameter with `extends`, so you can call the bound's members inside:
```dart
T maxOf<T extends Comparable<T>>(T a, T b) => a.compareTo(b) >= 0 ? a : b;
```
Without `extends Comparable<T>`, the compiler couldn't guarantee `compareTo` exists. Bounds give you compile-time safety *and* the ability to use the constrained API, instead of falling back to `dynamic`.

**27. Explain `mixin ... on` and linearization.**
`mixin M on Base` restricts `M` to classes that extend/implement `Base`, letting `M` call `Base`'s members and `super`. When multiple mixins are applied, Dart *linearizes* them into a single chain — rightmost mixin wins for overrides, and `super` calls walk left along that chain. This deterministic ordering is how Dart resolves the "diamond problem" without ambiguity.

**28. Extension methods vs extension types — what's the difference?**
Extension *methods* add behavior to an existing type; the object is unchanged and dispatch is static. An extension *type* (Dart 3.3+) is a *zero-cost wrapper*: a compile-time-only type over a representation object with no runtime allocation, used to give a distinct, safer API to an existing type (e.g. `extension type UserId(int id)`), erasing to the underlying type at runtime. Extensions add methods; extension types create a new (compile-time) type.

**29. How do you make a truly immutable value object in Dart?**
Mark fields `final`, give a `const` constructor, and implement value equality (`==`/`hashCode`) — plus a `copyWith` for evolving state. For deep immutability, hold unmodifiable collections (`List.unmodifiable` / `UnmodifiableListView`). Codegen (`freezed`) automates equality/`copyWith`/immutability. Immutability makes state predictable, enables cheap `const` reuse, and is why state-management libraries lean on it.

## 🔴 Advanced

**30. An exception thrown inside a future's callback isn't caught by your surrounding `try/catch`. Why, and how do you catch it?**
`try/catch` only catches synchronous throws in the *current* execution turn. Once work is deferred to a future callback, it runs in a later microtask with a fresh stack, so a sync `try/catch` around the *scheduling* code never sees it. You must either `await` the future inside the try (turning the async error into a catchable one), attach `.catchError`, or install a `runZonedGuarded`/`Zone` error handler. Uncaught async errors otherwise bubble to `Isolate.current.addErrorListener` / `PlatformDispatcher.onError` / `FlutterError.onError`.

**31. What is a `Zone` and when do you actually need one?**
A zone is an execution context that can intercept uncaught errors, override `print`, and control how microtasks/timers are scheduled — async callbacks run in the zone that scheduled them. The main real-world use is `runZonedGuarded(() => runApp(...), (error, stack) => report(error, stack))` to funnel *all* uncaught async errors to Crashlytics/Sentry. Beyond error handling and test fakes (fake async, captured prints), you rarely author zones by hand — they're powerful but subtle.

**32. `Future.wait` fails fast on the first error and you lose the other results. How do you get all outcomes?**
`Future.wait` completes with an error as soon as one future rejects; the others keep running but their results are dropped (and can cause unhandled-error warnings). To collect every outcome, wrap each future so it never rejects — e.g. `future.then((v) => Result.ok(v)).catchError((e) => Result.err(e))` — then `await Future.wait([...])` yields a list of results you can inspect individually. This is the manual equivalent of `Promise.allSettled`.

**33. Design a debounced search that cancels stale in-flight requests. What operators?**
Debounce the query stream (`debounceTime(300ms)`), then use `switchMap`: when a new query arrives, `switchMap` cancels the previous inner request stream and subscribes to the new one — so a slow earlier request can never overwrite a newer result (the classic race). With plain `asyncMap` you'd preserve order but still await stale requests; with un-managed futures you'd get out-of-order results. rxdart's `switchMap` is the idiomatic answer.

**34. `compute` shows overhead for small tasks — why, and when is an isolate the wrong tool?**
Spawning an isolate costs memory (a fresh heap) and startup time, and every message crosses the port by *copying* (serialization). For small or frequent tasks the copy + spawn cost dwarfs the work, so you regress performance. Isolates are wrong for I/O-bound work (that's what `async` already handles without a thread) and for anything needing tight shared state. Reach for them only for genuinely CPU-bound, coarse-grained chunks; reuse a long-lived isolate (or a pool) instead of `compute`-per-item.

**35. Explain covariance in Dart generics and the hole it opens.**
Dart generics are *covariant*: `List<Cat>` is assignable to `List<Animal>`. That's convenient for reads but unsound for writes — you could add a `Dog` into a list statically typed `List<Animal>` that's actually a `List<Cat>`. Dart accepts this at compile time and inserts a *runtime* type check that throws on the bad `add`. So covariance trades a bit of static soundness for ergonomics, backed by runtime checks. (`covariant` keyword separately lets you narrow a parameter type in an override, also runtime-checked.)

**36. Two mixins define the same method and both call `super`. What runs?**
Resolution follows the linearization order. `class C extends B with M1, M2` builds the chain `B → M1 → M2 → C`; a call resolves to the *rightmost* definition, and each `super.method()` walks one step left. So `M2`'s version runs first and its `super` reaches `M1`'s, then `B`'s. This deterministic left-to-right composition (rightmost overrides) is exactly how Flutter stacks mixins like `TickerProviderStateMixin` predictably.

**37. JIT vs AOT in Dart — what runs when, and why two modes?**
Debug builds use the JIT VM: source compiled just-in-time with a kernel snapshot, enabling *hot reload* and fast iteration but with warm-up cost. Release builds use AOT: Dart compiled ahead-of-time to native machine code, giving fast startup, predictable performance, and no runtime compiler — at the cost of no hot reload. You get developer velocity in debug and production performance in release from the same source.

**38. What is tree shaking and what defeats it?**
Tree shaking is dead-code elimination during AOT compilation: code (functions, classes) provably unreachable from `main` is dropped, shrinking the binary. It relies on *static* reachability, so it's defeated by dynamic dispatch it can't resolve — notably reflection (`dart:mirrors`, which is why it's banned in Flutter) and `@pragma('vm:entry-point')` code invoked from native. Keep entry points static so the compiler can prune aggressively.

**39. A `setState` fires "called after dispose" from a stream/future callback. Root cause and fixes.**
The async callback outlived the widget: the future/subscription completed after the `State` was disposed, and its captured closure called `setState` on a dead element. Fixes, in order of preference: cancel the subscription (and ideally the request) in `dispose`; guard with `if (!mounted) return;` before `setState`; or use `StreamBuilder`/`FutureBuilder` which own the subscription lifecycle. The guard is a band-aid — cancelling the work is the real fix (it also stops wasted network/CPU).

**40. `scheduleMicrotask` in a loop can freeze your UI even though "async." Explain.**
The event loop fully drains the microtask queue before rendering the next frame or handling input. If each microtask schedules another, the queue never empties, so the loop never returns to the event queue — timers, gestures, and frame callbacks starve, and the app hangs despite no synchronous long loop. This is *microtask starvation*: for repeated deferred work, use the event queue (`Future(...)`, `Timer`) so the loop can breathe between items.

**41. How does an `await` in a hot render path cause a dropped frame even without heavy compute?**
Even a trivial `await` defers the continuation to a microtask *after* the current turn, so any work after it can't complete within the same frame — and if that work rebuilds/relayouts, you've pushed it into a later frame. More importantly, code *before* the first `await` runs synchronously on the UI isolate; if that prelude (or a synchronous JSON decode you forgot to move to an isolate) is heavy, it blocks the 16ms budget directly. The fix is offloading CPU work to an isolate, not adding more `await`s.

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Microtask vs event queue priority? | Microtasks drain completely before each event-queue task. |
| Does an `async` function return before or after its first `await`? | Returns the future synchronously *at* the first await. |
| `Future.value(x).then(...)` runs on which queue? | Microtask. |
| One-shot vs many results? | `Future` vs `Stream`. |
| Default `StreamController` type? | Single-subscription. |
| How to allow many listeners? | `StreamController.broadcast()`. |
| Emit from a generator? | `async*` + `yield` (stream); `sync*` + `yield` (iterable). |
| Move CPU work off UI thread? | `compute()` / `Isolate.run`. |
| Isolates share memory? | No — message passing over ports. |
| `finally` for futures? | `.whenComplete()`. |
| Silence "unawaited future" intentionally? | `unawaited(f)`. |
| Catch only specific future errors? | `.catchError(fn, test: (e) => ...)`. |
| Funnel all uncaught async errors? | `runZonedGuarded`. |
| Constrain a generic type param? | `<T extends Bound>`. |
| Restrict a mixin to a supertype? | `mixin M on Base`. |
| Zero-cost wrapper type? | `extension type` (Dart 3.3+). |
| Hot reload works in which mode? | JIT (debug), not AOT (release). |
| What kills tree shaking? | Reflection / `dart:mirrors`. |

## Follow-up drills

1. **Predict & justify:** given a snippet mixing `print`, `Future`, `Future.microtask`, `scheduleMicrotask`, and a nested future, write the exact output and explain each queue transition.
2. **Design:** a rate-limited, cancellable download manager exposing a `Stream<Progress>` — decide single vs broadcast, backpressure strategy, and cleanup.
3. **Optimize:** the app janks while parsing a 12MB JSON on startup. Diagnose with the event-loop model and refactor using isolates without regressing small payloads.
4. **Debug:** intermittent "setState called after dispose" from a search screen that fires overlapping requests — identify the two distinct bugs (lifecycle + stale response) and fix both.
5. **Whiteboard:** implement `allSettled` semantics on top of `Future.wait`, then extend it with a per-future timeout and retry-with-backoff.
6. **Reason:** explain, using linearization, what `super.build`/`super`-chained mixins resolve to for a `State` using `WidgetsBindingObserver` + `TickerProviderStateMixin`.
