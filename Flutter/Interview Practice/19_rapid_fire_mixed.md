# Rapid-Fire & Mixed Mock Rounds — Interview Questions

> Last-minute revision + timed mock practice spanning **every** topic in this question bank. For depth on any line, jump to the topic file or the handbook: [55 Flutter Interview Preparation](../55%20Flutter%20Interview%20Preparation/README.md) and [56 Machine Coding Rounds](../56%20Machine%20Coding%20Rounds/README.md).

This is the file you skim the night before and drill the morning of. It tests *recall speed* (can you fire the fact instantly?), *articulation* (can you explain it in 60 seconds?), and *composure under trick questions*. Use it after you've read the individual topic files — this is the compression layer, not the teaching layer.

## How to use this

1. **Rapid-fire (revision mode):** cover the answer column, read the question, say the answer aloud, then reveal. If you stall, open the linked topic file. Do a full pass the night before.
2. **60-second drills (articulation mode):** set a phone timer to 60s per prompt. Speak — don't type. A strong answer hits the bullet points *and* stays inside the minute.
3. **Gotchas (composure mode):** these are the questions that separate memorizers from engineers. Predict the output / spot the bug before reading the answer.
4. **Mock sets (simulation mode):** pick the round matching your level, start a timer, and answer out loud with no notes. Record yourself. Grade on correctness *and* delivery.

Topic files for depth: [01_dart_core.md](01_dart_core.md) · [02_dart_advanced_async.md](02_dart_advanced_async.md) · [03_oop_solid_patterns.md](03_oop_solid_patterns.md) · [04_flutter_internals.md](04_flutter_internals.md) · [05_widgets_layout_lifecycle.md](05_widgets_layout_lifecycle.md) · [06_rendering_performance.md](06_rendering_performance.md) · [07_state_management.md](07_state_management.md) · [08_navigation_routing.md](08_navigation_routing.md) · [09_networking_data_storage.md](09_networking_data_storage.md) · [10_dependency_injection.md](10_dependency_injection.md) · [11_animations_custom_ui.md](11_animations_custom_ui.md) · [12_architecture.md](12_architecture.md) · [13_testing.md](13_testing.md) · [14_platform_native_device.md](14_platform_native_device.md)

---

## ⚡ Rapid-fire by topic

### Dart
| Q | A |
|---|---|
| `final` vs `const`? | `final` = set once at runtime; `const` = compile-time, deeply immutable |
| Top type in Dart? | `Object?` |
| `dynamic` vs `Object?`? | Both hold anything; `dynamic` disables static checks |
| What is a `sealed` class for? | Exhaustive `switch` — compiler forces all subtypes handled |
| Access 2nd positional record field? | `.$2` |
| Override alongside `==`? | `hashCode` |
| What does `late` defer? | Initialization; lazy on first read |
| Null-aware spread? | `...?` |
| `int` on web is really? | An IEEE-754 double |
| `identical(const[1], const[1])`? | `true` — canonicalized |

### Async & Isolates
| Q | A |
|---|---|
| Single-value vs multi-value async type? | `Future` vs `Stream` |
| Microtask vs event queue priority? | Microtasks drain fully before the next event |
| What schedules a microtask? | `scheduleMicrotask`, `Future.value().then`, awaited completions |
| Do isolates share memory? | No — separate heaps, message-passing only |
| Cheapest way to run one function off-thread? | `Isolate.run` (Dart 2.19+) / `compute` |
| `async*` produces? | A `Stream` (generator) |
| Broadcast vs single-subscription stream? | Broadcast allows many listeners; single allows one |
| `await for` does what? | Iterates a stream sequentially |
| Does `async` move work off the UI thread? | No — same isolate, just non-blocking scheduling |
| Unhandled Future error goes where? | Zone error handler / `runZonedGuarded` |

### Flutter internals & the 3 trees
| Q | A |
|---|---|
| The three trees? | Widget, Element, RenderObject |
| What is a Widget? | Immutable config / blueprint |
| What is an Element? | Mutable instance holding state + tree position |
| What is a BuildContext? | A handle to the Element's location in the tree |
| What is a RenderObject for? | Layout, painting, hit-testing |
| Why are widgets cheap to rebuild? | They're immutable configs; Elements are reused |
| What decides Element reuse? | `runtimeType` + `key` match at same position |
| Who holds `State`? | The `StatefulElement` |
| What is a `RenderObjectWidget`? | Widget that creates/updates a RenderObject |
| `InheritedWidget` gives you? | O(1) dependency lookup + targeted rebuilds |

### Widgets & lifecycle
| Q | A |
|---|---|
| StatelessWidget lifecycle? | `build` only (recreated on config change) |
| Key `State` lifecycle order? | `initState` → `didChangeDependencies` → `build` → `dispose` |
| Where to subscribe to an `InheritedWidget`? | `didChangeDependencies` |
| When does `didUpdateWidget` fire? | Parent rebuilds with a new widget of same type |
| Safe place for one-time async init? | `initState` (guard with `mounted` before setState) |
| What must `dispose` clean up? | Controllers, streams, listeners, tickers |
| `const` constructor benefit? | Widget instance canonicalized → skipped rebuild |
| Why use a `Key`? | Preserve state/identity across reorders & type-stable swaps |
| `GlobalKey` cost? | Expensive; enables cross-tree access & state retention |
| `mounted` guards against? | `setState` after dispose |

### Rendering & performance
| Q | A |
|---|---|
| Frame budget at 60fps? | ~16.6 ms (build+layout+paint on UI thread) |
| Layout algorithm? | Constraints down, sizes up, parent sets position |
| `BoxConstraints` carries? | min/max width & height |
| Cheapest way to skip subtree rebuild? | `const` widgets |
| `RepaintBoundary` does? | Isolates a layer so repaints don't propagate |
| Jank = ? | A frame that misses the 16.6 ms budget |
| Tool to find rebuilds? | DevTools "Track widget builds" / rebuild counts |
| `ListView` vs `ListView.builder`? | Builder lazily builds only visible items |
| `saveLayer` is expensive because? | Allocates offscreen buffer (opacity/clip layers) |
| Shader jank fix? | Shader warm-up / Impeller (precompiled) |

### State management
| Q | A |
|---|---|
| Cheapest built-in shared state? | `InheritedWidget` / `InheritedNotifier` |
| Provider is a wrapper over? | `InheritedWidget` |
| BLoC core primitive? | Streams (events in → states out) |
| Cubit vs BLoC? | Cubit = methods emit; BLoC = events mapped to states |
| Riverpod advantage over Provider? | Compile-safe, no `BuildContext`, testable, no `ProviderNotFound` |
| `context.watch` vs `read`? | `watch` rebuilds on change; `read` one-shot, no listen |
| `select` does? | Rebuilds only when a chosen slice changes |
| Golden rule for emitted state? | Emit new immutable instances (identity change) |
| Where does business logic live? | Outside widgets (notifier/bloc/controller) |
| `ChangeNotifier` notifies via? | `notifyListeners()` |

### Navigation
| Q | A |
|---|---|
| Imperative API? | `Navigator.push` / `pop` |
| Declarative API? | `Router` + `Navigator(pages: [...])` (Nav 2.0) |
| Return a result from a route? | `await Navigator.push(...)` → `pop(result)` |
| Deep links need? | Declarative routing / `onGenerateRoute` mapping |
| `pushReplacement` does? | Swaps current route (no back to it) |
| `pushAndRemoveUntil` for? | Clearing stack (e.g. after login) |
| Popular declarative package? | `go_router` |
| Named vs `onGenerateRoute`? | Named = static map; generate = dynamic + args parsing |
| Nested navigators for? | Tab-local stacks / shell routes |
| Guard a route (auth)? | Redirect in router / check in `onGenerateRoute` |

### Networking & data
| Q | A |
|---|---|
| Common HTTP clients? | `http`, `dio` |
| Why `dio` over `http`? | Interceptors, cancel tokens, timeouts, form-data |
| Parse JSON off the UI thread? | `compute(jsonDecode+map)` for big payloads |
| Retry/refresh-token best place? | An interceptor |
| Key-value local store? | `shared_preferences` |
| Structured local DB options? | `sqflite`, `drift`, `Isar`, `Hive` |
| Secure token storage? | `flutter_secure_storage` (Keychain/Keystore) |
| Offline-first pattern? | Cache-then-network / single source of truth = DB |
| Serialize models without boilerplate? | `json_serializable` / `freezed` codegen |
| Cancel an in-flight request? | `CancelToken` (dio) |

### Dependency injection
| Q | A |
|---|---|
| What problem does DI solve? | Decouples construction from use → testable, swappable |
| Service locator package? | `get_it` |
| Codegen DI package? | `injectable` |
| `registerSingleton` vs `registerLazySingleton`? | Eager vs created on first resolve |
| `registerFactory` gives? | A new instance every resolve |
| Riverpod as DI? | Providers *are* the container (overridable) |
| Swap a real dep for a fake in tests? | Override registration / provider override |
| Constructor injection benefit? | Explicit deps, no hidden globals |
| Scoped DI use case? | Per-feature / per-route lifetime |
| Anti-pattern to avoid? | Reaching into a global singleton from widgets |

### Architecture
| Q | A |
|---|---|
| Clean Architecture layers? | Presentation → Domain → Data |
| Dependency rule direction? | Inward — outer depends on inner, never reverse |
| What is a UseCase? | A single application action in the domain layer |
| Repository pattern hides? | Data sources behind a domain interface |
| MVVM binds view to? | A ViewModel exposing observable state |
| Where do entities live? | Domain (framework-independent) |
| Feature-first vs layer-first? | Group by feature vs by technical layer |
| DTO vs Entity? | DTO = data/transport shape; Entity = domain model |
| Why interfaces at layer boundaries? | Dependency inversion → testable, swappable |
| Modular architecture wins? | Build isolation, ownership, faster CI |

### Testing
| Q | A |
|---|---|
| Three test tiers? | Unit, widget, integration |
| Widget test entry point? | `tester.pumpWidget` |
| Advance frames in a widget test? | `pump` / `pumpAndSettle` |
| Find widgets? | `find.byType/byKey/text` |
| Mock package? | `mockito` / `mocktail` |
| Test async without real delays? | `fakeAsync` / `tester.pump(duration)` |
| Golden test verifies? | Pixel-level rendering vs a reference image |
| Fake time in unit tests? | `fakeAsync` / injected `Clock` |
| Test coverage command? | `flutter test --coverage` |
| Why avoid `pumpAndSettle` with infinite anims? | It never settles → timeout |

### Platform & native
| Q | A |
|---|---|
| Talk to native code via? | Platform channels |
| `MethodChannel` for? | Request/response native calls |
| `EventChannel` for? | Streaming native events (sensors, etc.) |
| New lower-overhead interop? | Pigeon (type-safe) / FFI |
| FFI is for? | Calling C/C++ directly, no channel hop |
| Channel calls are? | Async, message-passing, serialized |
| Detect platform at runtime? | `Platform.isAndroid` / `defaultTargetPlatform` |
| Adaptive vs responsive? | Adaptive = per-platform look; responsive = per-size layout |
| Run native UI inside Flutter? | `PlatformView` |
| Where does channel native code live? | Android (Kotlin/Java) & iOS (Swift/ObjC) host |

---

## 🎯 "Explain in 60 seconds"

Each prompt: give a crisp elevator explanation. A strong answer hits the bullets *and* stays under a minute.

1. **How does Flutter render a frame?**
   - Build phase: rebuild dirty widgets → reconcile Element tree.
   - Layout: constraints go down, sizes come up.
   - Paint → composite layers → GPU rasterizes.
   - All within the ~16.6 ms UI-thread budget; miss it = jank.

2. **Why is the Element tree the "middle man"?**
   - Widgets are immutable and thrown away every rebuild.
   - RenderObjects are expensive to create.
   - Elements persist, diff old vs new widget, and mutate/reuse RenderObjects.
   - This is what makes rebuilds cheap.

3. **`setState` vs a state-management solution — when to reach past `setState`?**
   - `setState` is fine for local, ephemeral, widget-owned state.
   - Reach past it when state is shared across screens, outlives the widget, or holds business logic.
   - Options scale: InheritedWidget → Provider → Riverpod/BLoC.
   - Goal: keep logic testable and out of `build`.

4. **What is sound null safety and why does "sound" matter?**
   - Types are non-nullable by default; `String?` opts into null.
   - "Sound" = guaranteed end-to-end, so the runtime trusts non-null types.
   - No hidden null checks compiled in → faster + safer.
   - Eliminates the classic `NoSuchMethodError: null`.

5. **Isolates vs async/await.**
   - `async`/`await` is concurrency on *one* thread (non-blocking scheduling).
   - Isolates are true parallelism — separate heaps, no shared memory.
   - Use async for I/O waits; use isolates for CPU-heavy work (parsing, crypto).
   - Communicate via message passing (`SendPort`) / `Isolate.run`.

6. **Provider vs Riverpod — pick one and defend it.**
   - Provider: simple, `InheritedWidget`-based, needs `BuildContext`, can throw `ProviderNotFound`.
   - Riverpod: compile-safe, context-free, easily testable, override-friendly.
   - Riverpod fixes Provider's runtime-lookup pitfalls.
   - Trade-off: Riverpod's learning curve vs Provider's ubiquity.

7. **Clean Architecture in a Flutter app.**
   - Three layers: Presentation, Domain, Data.
   - Domain (entities + use cases) is pure Dart, framework-free.
   - Dependencies point inward; data layer implements domain interfaces.
   - Payoff: testability, swappable data sources, feature isolation.

8. **How would you diagnose jank?**
   - Open DevTools performance/timeline; look for frames > 16.6 ms.
   - Separate UI-thread jank (build/layout) from raster-thread jank (paint/shaders).
   - Fix with `const`, `RepaintBoundary`, `ListView.builder`, offloading work.
   - Confirm by re-profiling on a *real device* in profile mode.

9. **The widget lifecycle of a StatefulWidget.**
   - `createState` → `initState` → `didChangeDependencies` → `build`.
   - Updates: `didUpdateWidget` (new config) / `didChangeDependencies` (inherited change).
   - Teardown: `deactivate` → `dispose`.
   - Rule: allocate in `initState`, release in `dispose`, guard with `mounted`.

10. **How do platform channels work?**
    - Dart and native agree on a channel name + codec.
    - `MethodChannel` sends an async, serialized message across the boundary.
    - Native handler runs and returns a result (or streams via `EventChannel`).
    - For hot paths, prefer Pigeon (type-safe) or FFI (no channel hop).

---

## 🧠 Tricky / gotcha questions

1. **Why do `const` constructors actually matter for performance?**
   `const` widgets are canonicalized to a single shared instance, so on rebuild the framework sees the *same* object (`identical`), short-circuits the diff, and skips rebuilding that subtree entirely. It's not micro-optimization — it prunes whole branches of the rebuild.

2. **Why is calling `setState` inside `build` catastrophic?**
   `build` runs during the build phase; `setState` marks the element dirty and schedules another build → infinite rebuild loop (and often a "setState called during build" assertion). State changes belong to event handlers or lifecycle callbacks, never `build`.

3. **You reorder items in a `ListView` and the wrong ones keep their state. Why?**
   Without keys, Elements match by position + type, so state (scroll, animation, form input) sticks to the *slot*, not the item. Give each item a stable `ValueKey(id)` so the framework matches by identity across reorders.

4. **`final List<int> nums = [...]; nums.add(4);` — legal?**
   Yes. `final` freezes the *binding*, not the object. `nums = [...]` would fail; `nums.add(4)` mutates the same list and is fine. Use `const [...]` or `List.unmodifiable` for true immutability.

5. **`==` vs `identical` — when do they diverge?**
   `identical(a, b)` is reference equality; `a == b` is value equality (whatever `==` is overridden to be). Two different objects can be `==` but not `identical`. Two `const` literals with equal content *are* `identical` due to canonicalization.

6. **Predict the output:**
   ```dart
   print('A');
   Future(() => print('B'));            // event queue
   Future.microtask(() => print('C'));  // microtask queue
   print('D');
   // output: A D C B
   ```
   Sync code first (`A`, `D`), then the microtask queue drains fully (`C`) *before* any event-queue task (`B`).

7. **`scheduleMicrotask` vs `Future(() => ...)` — why does ordering flip intuition?**
   Microtasks always run before the next event-loop task, no matter when they were queued in the current turn. A `Future(...)` body goes to the event queue and yields to *all* pending microtasks first — so a later-scheduled microtask can run before an earlier-scheduled `Future`.

8. **Why can't you promote a nullable *field* with `if (obj.field != null)`?**
   A getter could return a different value on the second read (overridden getter, concurrent change), so the compiler can't prove non-null. Promote a local copy: `final f = obj.field; if (f != null) f.use();`.

9. **You `await` something after an `if (!mounted) return;` check and then call `setState` — still safe?**
   No. The `await` yields; the widget can be disposed *during* the gap. Re-check `mounted` **after** every `await` that precedes a `setState`, not just once at the top.

10. **Two objects are `==` but end up in a `Set` twice. What broke?**
    You overrode `==` but not `hashCode`. Hash-based collections bucket by `hashCode` first; unequal hashes never even compare with `==`. Always override both together (or use `Equatable`/`freezed`).

---

## 🧪 Mock interview sets

Set a timer. Answer **out loud**, no notes. Record and grade on correctness *and* delivery. No answers here by design — self-check against the linked topic files.

### Round 1 — Junior (45 min)
*Emphasis: language fundamentals, core widgets, `setState`, and clear articulation. Interviewers want correctness and evidence you understand what you type, not depth.*

1. Explain `var` vs `final` vs `const` with an example of when each is right.
2. What's the difference between `StatelessWidget` and `StatefulWidget`?
3. Walk me through the lifecycle of a `StatefulWidget`.
4. What does `setState` do under the hood, and when is it the wrong tool?
5. `Row`/`Column`/`Expanded` — how does Flutter decide sizes here?
6. What is a `Future`, and what does `await` actually do?
7. How do you make and parse a simple HTTP GET request?
8. Why do we add a `key` to items in a list?
9. What's the difference between `ListView` and `ListView.builder`?
10. What is `BuildContext`, in one sentence?

### Round 2 — Mid-level (60 min)
*Emphasis: internals, state management trade-offs, async/streams, navigation, and testing. They probe *why* and expect you to compare options and justify a choice.*

1. Explain the three trees and why the Element tree exists.
2. Compare Provider, Riverpod, and BLoC — which do you reach for and why?
3. Walk through how Flutter renders one frame and where jank comes from.
4. Streams: broadcast vs single-subscription, and where microtasks fit.
5. How do you return a result from a pushed route, and how does Navigator 2.0 differ?
6. Design the data layer for a screen that must work offline.
7. How do you structure and inject dependencies for testability?
8. Write (verbally) a widget test for a counter — what do you pump and assert?
9. When and how would you use `compute`/`Isolate.run`?
10. You see jank scrolling a list — how do you diagnose and fix it?

### Round 3 — Senior (60 min)
*Emphasis: architecture, scale, performance under pressure, and platform/native depth. They want system-level reasoning, trade-off ownership, and how you'd lead a codebase — depth beats breadth.*

1. Design the architecture for a multi-feature app owned by 4 teams — layers, modules, boundaries.
2. Defend your state-management choice for a large app and its testing story.
3. How do you enforce the dependency rule and keep the domain framework-free at scale?
4. A production frame budget is blowing up only on low-end Android — how do you investigate end to end?
5. Design an offline-first sync engine with conflict resolution.
6. When do you choose FFI vs Pigeon vs `MethodChannel`, and what are the costs of each?
7. How do isolates change how you architect CPU-heavy features, and what are the messaging pitfalls?
8. Design a CI pipeline: what gets tested, gated, and how do you keep it fast?
9. How would you introduce modularization into a large monolithic Flutter codebase incrementally?
10. Walk me through a performance or architecture decision you'd defend to a skeptical staff engineer.

---

*Revise topic-by-topic in the [sibling Interview Practice files](README.md); go deep via [55 Flutter Interview Preparation](../55%20Flutter%20Interview%20Preparation/README.md) and drill live-coding in [56 Machine Coding Rounds](../56%20Machine%20Coding%20Rounds/README.md).*
