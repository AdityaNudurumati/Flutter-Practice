# 02 · Advanced Dart

## Introduction

Module 01 gave you the language. This module gives you the **runtime model and power features** that separate a Flutter developer from a Dart *engineer*: the single-threaded event loop, `Future`/`Stream` concurrency, isolates for true parallelism, generics, mixins, extensions, immutability patterns, and the VM's JIT/AOT compilation pipeline.

## Why this module exists

Every jank bug, every "why didn't my `await` block the UI," every "how do I parse a 10MB JSON without freezing the app" traces back to the concepts here. Interviewers at top companies lean *hard* on the event loop, isolates, and streams because they reveal whether you understand what actually runs your code.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_event_loop.md](01_event_loop.md) | Event loop, microtask vs event queue, scheduling | 🟢 |
| 2 | [02_async_futures.md](02_async_futures.md) | `Future`, `async`/`await`, error handling, `Completer` | 🟢 |
| 3 | [03_streams.md](03_streams.md) | `Stream`, controllers, `async*`, transformers, broadcast | 🟢 |
| 4 | [04_isolates.md](04_isolates.md) | Isolates, `Isolate.run`, `compute`, ports, true parallelism | 🔵 |
| 5 | [05_generics.md](05_generics.md) | Generic classes/methods, bounds, variance, advanced generics | 🔵 |
| 6 | [06_mixins.md](06_mixins.md) | `mixin`, `on`, linearization, diamond resolution | 🔵 |
| 7 | [07_extension_methods.md](07_extension_methods.md) | Add methods to existing types | 🟢 |
| 8 | [08_extension_types.md](08_extension_types.md) | Zero-cost wrappers (Dart 3.3+) | 🔵 |
| 9 | [09_constructors_and_singletons.md](09_constructors_and_singletons.md) | Factory/named/private constructors, singletons, callable classes | 🔵 |
| 10 | [10_immutability.md](10_immutability.md) | Immutable objects, `copyWith`, value equality | 🔵 |
| 11 | [11_libraries_and_packages.md](11_libraries_and_packages.md) | `library`/`part`/`import`/`export`, pub packages | 🟢 |
| 12 | [12_json_and_serialization.md](12_json_and_serialization.md) | `jsonEncode`/`Decode`, manual + codegen, annotations | 🟢 |
| 13 | [13_memory_and_gc.md](13_memory_and_gc.md) | Memory model, generational GC, leaks | 🔴 |
| 14 | [14_dart_compilation.md](14_dart_compilation.md) | Dart VM, JIT, AOT, snapshots, tree shaking | 🔴 |

## Prerequisites

Complete **[01 Dart Fundamentals](../01%20Dart%20Fundamentals/README.md)** — especially functions/closures, null safety, and collections.

## What you'll be able to do after this module

- Explain, on a whiteboard, exactly what happens when you `await` — and why the UI stays responsive.
- Choose between `async`, `Stream`, `Isolate`, and `compute` for a given workload.
- Write generic, reusable APIs with correct bounds and variance intuition.
- Reach for mixins, extensions, and immutability idiomatically.
- Describe how Dart compiles (JIT for hot reload, AOT for release) and why tree shaking matters for app size.

## Capstones

| Tier | Build |
|------|-------|
| Beginner | An async **countdown + polling** CLI using `Future`/`Stream`. |
| Intermediate | A **rate-limited downloader** with a `Stream` progress API. |
| Advanced | A **parallel image/JSON processor** using isolates + `compute`. |
| Enterprise | A reusable **`AsyncResult`/retry/backoff** library (feeds Modules 16 & 38). |

## Summary

Advanced Dart is where correctness under concurrency and performance intuition are forged. Read the async core (event loop → futures → streams → isolates) first; it underpins everything in Flutter.
