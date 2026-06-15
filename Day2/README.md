# Day 2 — Intermediate Dart (Flutter Interview Prep)

Goal: the Dart topics interviewers reach for **after** the fundamentals. Each maps
directly to Flutter (`Future`→FutureBuilder, `Stream`→StreamBuilder/BLoC,
mixins→TickerProvider, generics→everything). Everything here is written to be
**run and modified**, not just read. Type it out, break it, fix it.

## How to run any file
```bash
dart run Day2/01_generics.dart
```
(No Flutter needed — plain Dart. Install Dart SDK or use the one bundled with Flutter.)

## Files

| # | Topic | File |
|---|-------|------|
| 1 | Generics: `List<T>`, `Map<K,V>`, generic functions/classes, bounded type params | [01_generics.dart](01_generics.dart) |
| 2 | Async: `Future`, `async`/`await`, `Future.wait`, error handling, event loop | [02_async_futures.dart](02_async_futures.dart) |
| 3 | Streams: `async*`/`yield`, `listen`, `StreamController`, single vs broadcast | [03_streams.dart](03_streams.dart) |
| 4 | Mixins (`with`, `on`) & Extensions | [04_mixins_extensions.dart](04_mixins_extensions.dart) |
| 5 | Named & factory constructors, abstract classes, interfaces (`implements`) | [05_constructors_and_classes.dart](05_constructors_and_classes.dart) |
| 6 | Exception handling: `try/catch/on/finally`, custom exceptions, `rethrow` | [06_exception_handling.dart](06_exception_handling.dart) |
| 7 | Isolates: `Isolate.run`, `spawn` + ports, true parallelism | [07_isolates.dart](07_isolates.dart) |
| 8 | Collections deep dive + functional programming (`map`/`where`/`fold`/`reduce`) | [08_collections_functional.dart](08_collections_functional.dart) |
| 9 | Fake API: `getPosts()`→`Future<List>`, throws on empty, caller drives loading/error/success | [09_fake_api.dart](09_fake_api.dart) |

Memory management & garbage collection is conceptual (no runnable file) — it's
covered in **Section 9** of [notes.txt](notes.txt).

## Interview checklist for today
After Day 2 you should be able to answer, out loud, without notes:
- [ ] What are generics for, and are they reified or erased in Dart?
- [ ] Does `async`/`await` use threads? Concurrency vs parallelism.
- [ ] `Future` vs `Stream`; sequential vs `Future.wait` (parallel).
- [ ] Single-subscription vs broadcast stream; why close a `StreamController`.
- [ ] What problem do mixins solve? What does the `on` clause do?
- [ ] Named vs factory constructor; can a factory use `this`?
- [ ] Abstract class vs interface in Dart (no `interface` keyword).
- [ ] Exception vs Error; `rethrow` vs `throw e`; what `finally` guarantees.
- [ ] What is an isolate; how do isolates communicate; isolate vs thread.
- [ ] `fold` vs `reduce`; why `map`/`where` are lazy.
- [ ] How does Dart GC work, and how do leaks still happen in Flutter?

> Tip: don't copy-paste the solutions. Open a blank file, attempt from memory, then
> diff against these. The struggle is the learning.
