# Testing — Interview Questions

> How you prove Flutter/Dart code works, at unit, widget, and integration levels. For depth see the handbook module [49 Testing](../49%20Testing/README.md).

Testing is a senior-signal topic: it exposes whether you write code that can *be* tested (DI, pure functions, seams) and whether you know the cost/value trade-off of each test type. Interviewers escalate from "what does `expect` do" to "why is your golden test flaky in CI" and "how do you test a debounced stream".

## 🟢 Basic

**1. What is the testing pyramid, and how does it map to Flutter?**
The pyramid says: have many fast, cheap tests at the bottom and few slow, expensive tests at the top. In Flutter that's **unit tests** (bottom — pure Dart, logic, no widgets, milliseconds), **widget tests** (middle — a single widget or screen in a headless `WidgetTester`, no real device), and **integration tests** (top — the whole app on a device/emulator, slow). You want the bulk of coverage in unit tests because they run in milliseconds and pinpoint failures; integration tests are few because they're slow and flaky. The anti-pattern is the "ice-cream cone" — mostly manual/E2E tests and almost no unit tests.

**2. What are the three test types Flutter ships and how do you run them?**
Unit and widget tests both use the `flutter_test` package and run headlessly with `flutter test` (on the Dart VM, no device). Integration tests use the `integration_test` package and run on a real device/emulator with `flutter test integration_test/...` or `flutter drive`. Rule of thumb: unit = pure logic, widget = UI in isolation, integration = full app flows.

**3. What do `test`, `expect`, and matchers do?**
`test('description', () { ... })` declares a single test case. Inside it, `expect(actual, matcher)` asserts a condition; if the matcher fails, the test fails. A **matcher** describes the expected value — `equals(3)`, `isTrue`, `isNull`, `throwsA(isA<FormatException>())`, `contains('x')`, `greaterThan(0)`. You can pass a raw value (`expect(x, 3)`) and it's implicitly wrapped in `equals`.

```dart
test('adds two numbers', () {
  expect(add(2, 3), equals(5));
  expect(() => divide(1, 0), throwsA(isA<ArgumentError>()));
});
```

**4. What are `group`, `setUp`, and `tearDown` for?**
`group('...', () {...})` bundles related tests and namespaces their descriptions. `setUp` runs before *each* test in its scope (fresh fixtures — a new repository, a new mock), and `tearDown` runs after each (cleanup — close a stream, clear a DB). `setUpAll`/`tearDownAll` run once for the whole group. Prefer `setUp` over `setUpAll` so tests stay isolated and don't leak state between each other.

**5. What is a unit test, and what should it *not* touch?**
A unit test verifies one unit of logic — a function, a method, a class — in isolation, with no I/O, no network, no file system, no `MethodChannel`, and ideally no clock or randomness. Those dependencies are replaced with test doubles. If a "unit test" hits a real API or database, it's an integration test wearing the wrong label — it'll be slow and flaky.

**6. What is a widget test and what is `WidgetTester`?**
A widget test pumps a widget into a headless test environment and drives it, verifying layout, text, and interaction without a real device. `WidgetTester` is the handle you get from `testWidgets((tester) async {...})`: it builds the widget (`pumpWidget`), advances frames (`pump`), sends gestures (`tap`, `enterText`, `drag`), and queries the tree via finders.

```dart
testWidgets('increments counter', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();               // rebuild after setState
  expect(find.text('1'), findsOneWidget);
});
```

**7. What are finders, and name the common ones?**
Finders locate widgets in the tree for assertions or actions. Common ones: `find.text('Login')`, `find.byType(ElevatedButton)`, `find.byIcon(Icons.add)`, `find.byKey(const Key('email'))`, `find.byWidgetPredicate(...)`, `find.widgetWithText(ElevatedButton, 'Save')`. You assert existence with matchers: `findsOneWidget`, `findsNothing`, `findsNWidgets(3)`, `findsWidgets`. Keys are the most robust finder because they survive copy changes and localization.

**8. `pump` vs `pumpAndSettle` — what's the difference?**
`await tester.pump(duration)` triggers a single frame (or advances the clock by `duration` and renders one frame). `await tester.pumpAndSettle()` repeatedly pumps frames until there are no more scheduled — i.e., all animations and transitions have completed. Use `pump()` when you know exactly how many frames you need (and to avoid hanging); use `pumpAndSettle()` after navigation or an animation. **`pumpAndSettle` times out (default 10 min) if something animates forever** — e.g. an infinite `CircularProgressIndicator` — which is a classic hang.

**9. How do you simulate a tap and check the result?**
`await tester.tap(find.byType(FloatingActionButton));` then `await tester.pump();` to process the resulting rebuild, then `expect(find.text('1'), findsOneWidget);`. The `pump` between the action and the assertion is essential — without it the frame hasn't rebuilt and your assertion checks stale UI.

**10. What is code coverage and how do you generate it?**
Coverage measures which lines/branches your tests exercised. Generate it with `flutter test --coverage`, which writes `coverage/lcov.info`; view it as HTML with `genhtml`. It's a useful *floor* signal (untested critical paths are visible) but a poor *ceiling* goal — 100% coverage of trivial getters proves nothing. Track coverage on business logic, not on generated files or `main.dart`.

**11. What is a mock, and why mock at all?**
A mock is a stand-in for a real dependency that you program to return canned responses and/or verify calls against. You mock to make tests **fast** (no network), **deterministic** (no flaky I/O or clock), and **isolated** (test *your* unit, not the collaborator). Example: mock a `Repository` so a `ViewModel` test doesn't hit HTTP.

**12. What is TDD in one sentence?**
Test-Driven Development is the red-green-refactor loop: write a failing test first (red), write the minimum code to pass it (green), then refactor with the test as a safety net. It drives you toward small, testable units and forces you to define behavior before implementation.

## 🟡 Intermediate

**13. mockito vs mocktail — which and why?**
Both create test doubles; the difference is code generation.

| | mockito | mocktail |
|---|---|---|
| Setup | `@GenerateMocks` + `build_runner` codegen | No codegen — extend `Mock` directly |
| Null safety | Needs generated mocks for sound null safety | Null-safe by design |
| Arg matching | `any`, `argThat` | `any()`, `any(named:)`, `captureAny()` |
| Boilerplate | Generated `.mocks.dart` files | Zero |

Mocktail is the modern favorite because it drops the `build_runner` step and reads cleaner. Mockito is still common in older/enterprise codebases. With mocktail you must `registerFallbackValue` for custom types used with `any()`.

**14. Fakes vs mocks vs stubs — define each.**
All are test doubles but differ in intent:
- **Stub** — returns hardcoded canned answers; no logic, no verification. "When asked, return this."
- **Mock** — a stub plus recorded interactions you *verify* ("was `save()` called once with X?"). Behavior verification.
- **Fake** — a real, working lightweight implementation (e.g. an in-memory repository, `sqflite_common_ffi` in-memory DB). It actually runs logic, just not the production version.

Guideline: prefer fakes for state-holding collaborators (they're less brittle), use mocks when the *interaction itself* is what you're asserting.

**15. When should you NOT mock?**
Don't mock value objects, `data` classes, or pure functions — just use the real thing. Don't mock what you don't own (third-party SDKs) directly; wrap them behind your own interface and mock that, so a library API change doesn't break dozens of tests. And don't over-mock so heavily that the test only proves your mocks agree with each other ("mockery") — that's coupling tests to implementation, not behavior.

**16. How do you test `async` code — `Future`s?**
Make the test callback `async` and `await` the future, then assert. For errors use `expectLater(future, throwsA(...))`. `expect` also accepts `completes` / `completion(matcher)` matchers.

```dart
test('fetches user', () async {
  when(() => api.getUser(1)).thenAnswer((_) async => User('Ada'));
  final user = await repo.load(1);
  expect(user.name, 'Ada');
});
test('propagates error', () {
  expect(repo.load(-1), throwsA(isA<NotFoundException>()));
});
```

**17. How do you test streams?**
Use `expectLater` with the `emitsInOrder` family of matchers: `emits`, `emitsInOrder([...])`, `emitsError`, `emitsDone`, `neverEmits`, `emitsThrough`. These subscribe and assert the emission sequence without manual `listen` bookkeeping.

```dart
expectLater(
  counterStream,
  emitsInOrder([1, 2, 3, emitsDone]),
);
```

**18. What is `fakeAsync` / how do you test time-dependent code?**
Timers, `Future.delayed`, debounce, and throttle shouldn't make tests wait in real time. In widget tests, `tester.pump(Duration(...))` advances the fake clock. In pure Dart, use `fakeAsync((async) { ...; async.elapse(Duration(seconds: 5)); })` from the `fake_async` package to jump the virtual clock instantly. This makes a "wait 30s then retry" test run in microseconds and stay deterministic.

**19. How do you pump a widget that needs `MaterialApp`, providers, or a `Navigator`?**
Wrap it in the ancestors it depends on. A screen using `Theme`, `MediaQuery`, `Navigator`, or localization needs `MaterialApp(home: ...)`. One using Provider/Riverpod needs the scope wrapped:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [repoProvider.overrideWithValue(FakeRepo())],
    child: const MaterialApp(home: ProfileScreen()),
  ),
);
```

Forgetting the ancestor gives the classic `No MediaQuery widget found` / `No Directionality` error. A bare widget can be wrapped in just `Directionality`.

**20. How do you test BLoC/Cubit — what does `bloc_test` give you?**
`bloc_test`'s `blocTest` helper standardizes the arrange-act-assert for BLoCs: `build` the bloc (wiring mocked deps), `act` by adding events, and `expect` the ordered list of emitted states. `seed` sets an initial state; `wait` handles debounce; `verify` runs post-assertions on mocks.

```dart
blocTest<CounterBloc, int>(
  'emits [1] when Increment added',
  build: () => CounterBloc(),
  act: (bloc) => bloc.add(Increment()),
  expect: () => [1],
);
```

**21. How do you test a Provider `ChangeNotifier` or a Riverpod provider?**
For `ChangeNotifier`: instantiate it with mocked dependencies, call methods, and assert on its exposed fields — or attach a listener and count `notifyListeners` calls. For Riverpod: create a `ProviderContainer(overrides: [...])` in the test, read the provider with `container.read(myProvider)`, and `addTearDown(container.dispose)`. Overrides let you inject fakes without any widget tree at all — that's Riverpod's big testability win.

**22. What are golden tests?**
Golden (snapshot) tests render a widget and compare the pixels against a stored reference image (`.png` "golden file"). `await expectLater(find.byType(MyCard), matchesGoldenFile('goldens/card.png'));` and generate/update baselines with `flutter test --update-goldens`. They catch unintended visual regressions that assertion-based widget tests miss (spacing, color, layout).

**23. What is DI's role in testability?**
Dependency Injection is what makes a unit *substitutable*. If a class news-up its own `HttpClient` internally, you can't replace it in a test. If it *accepts* a client (or repository, or clock) via constructor, you inject a fake. DI creates the "seam" that testing requires. See [14 Dependency Injection](../14%20Dependency%20Injection/README.md).

**24. Why do pure functions make testing easy?**
A pure function's output depends only on its inputs and it has no side effects, so a test is just `expect(f(input), output)` — no setup, no mocks, no order dependence, no cleanup. Pushing logic into pure functions (and keeping I/O at the edges) is the single highest-leverage move for a testable codebase.

## 🔴 Advanced

**25. What causes flaky tests, and how do you kill them?**
Flakiness = nondeterminism. Common causes and fixes:
- **Real time** (`Future.delayed`, timers) → use `fakeAsync` / `tester.pump(duration)`.
- **Ordering / shared state** between tests → fresh fixtures in `setUp`, avoid `setUpAll` mutable state, don't rely on test order.
- **`pumpAndSettle` on an infinite animation** → use bounded `pump()` counts.
- **Real network / clock / random** → inject fakes and seed randomness.
- **Async races** (asserting before a `Future` resolves) → `await` properly, use `expectLater`.
- **Environment** (locale, timezone, screen size, fonts) → pin them; set `tester.view.physicalSize`.

A flaky test is worse than no test — teams learn to ignore it, hiding real regressions.

**26. Why are golden tests especially flaky, and how do you stabilize them for CI?**
Rendered pixels differ across platforms: font rendering and anti-aliasing differ between macOS/Linux/Windows, so a golden generated locally fails in CI. Fixes: generate goldens **in the same environment as CI** (often a Linux Docker image) or use a package like `golden_toolkit`/`alchemist` that loads a consistent test font (`Ahem`/Roboto) and disables platform font fallback. Pin the Flutter version. Many teams run goldens as a separate, non-blocking CI job or only on Linux to avoid cross-platform pixel drift.

**27. How do integration tests differ from `flutter drive`, and when do you use each?**
The `integration_test` package runs test code *on the device* in the same process as the app, using the widget-test API (`WidgetTester`) but against the real app. `flutter drive` runs a *driver script on the host* that commands the app over a Dart VM service protocol — needed for things the on-device test can't do: capturing performance timelines/traces, driving from a CI harness like Firebase Test Lab, or screenshots on real hardware. Modern practice: write tests with `integration_test`, and use `flutter drive` (or `flutter test integration_test`) as the runner.

**28. How do you measure performance in an integration test?**
Wrap the flow in `binding.traceAction(() async {...})` (using `IntegrationTestWidgetsFlutterBinding`) to capture a timeline, then write a `TimelineSummary` with jank metrics (`frame_build_times`, `missed_frames`, 90th/99th percentile frame times). Run via `flutter drive` so the results are written to disk for CI to assert against a budget. This is how you catch "this screen dropped from 60fps to 40fps" regressions.

**29. What should you NOT test?**
- The framework itself (don't test that `setState` rebuilds — Flutter's team already does).
- Third-party libraries (test your *usage*, behind your interface).
- Trivial code with no logic — plain getters, generated `copyWith`, DTO field assignments.
- Private implementation details / exact call sequences that aren't part of the contract — testing those makes refactoring break tests with no behavior change.
- Const/static UI with no logic (a golden test is overkill for a static label).

Test **behavior and contracts**, not implementation. The heuristic: "would a reasonable refactor that preserves behavior break this test?" If yes, you're testing the wrong thing.

**30. How do you make legacy, untestable code testable without a big-bang rewrite?**
Introduce seams incrementally: extract the hard dependency behind an interface and inject it (constructor param, or a settable field / service-locator override for the worst cases). Pull business logic out of `build()` methods and `initState` into plain classes/functions you can unit-test. Wrap statics and singletons (`DateTime.now`, `Platform`, plugins) behind an injectable abstraction. Add a characterization test around current behavior *first*, then refactor under its protection.

**31. How do you test code that uses platform channels / plugins?**
Register a mock handler: `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {...})` to intercept `MethodChannel` calls and return fake responses — no native side needed. Better still, wrap the plugin behind your own interface and inject a fake in most tests, reserving the channel mock for the thin adapter class. See [26 Platform Channels](../26%20Platform%20Channels/README.md).

**32. How do you verify interactions and capture arguments with mocktail?**
Use `verify`/`verifyNever` for call assertions and `captureAny()` to grab the actual argument passed:

```dart
verify(() => analytics.log('checkout')).called(1);
final captured = verify(() => repo.save(captureAny())).captured.single as Order;
expect(captured.total, 42);
verifyNever(() => api.delete(any()));
```

Reserve interaction verification for genuine side effects (analytics fired, cache written). Over-verifying every call couples the test to implementation.

**33. What is `WidgetTester.runAsync` and when do you need it?**
By default widget tests run in a `FakeAsync` zone, so real async work (real HTTP, actual timers, `precacheImage`, platform I/O) never completes. `await tester.runAsync(() async {...})` runs the callback with the real event loop so genuine async completes — needed when a widget does real I/O you can't fully fake. Use sparingly; it reintroduces real-time nondeterminism.

**34. How do golden/widget tests handle images and network calls?**
Network images fail in tests (no real HTTP), returning a 400 and often throwing. Solutions: inject a fake `HttpClient` via `HttpOverrides` that returns a transparent 1×1 image, use `mockNetworkImagesFor` from `network_image_mock`, or replace `Image.network` with an injectable image widget. For goldens specifically, ensure fonts and images are loaded before `expectLater`, otherwise you snapshot a half-rendered frame.

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Which command runs unit + widget tests? | `flutter test` (headless, Dart VM) |
| Which package for integration tests? | `integration_test` |
| `pump` vs `pumpAndSettle`? | one frame vs pump until no animations left |
| Most robust finder? | `find.byKey` — survives copy/locale changes |
| Assert widget count of 1? | `expect(find.text('x'), findsOneWidget)` |
| mockito's extra step vs mocktail? | `build_runner` codegen |
| Matcher for an async throw? | `throwsA(isA<T>())` with `expectLater`/`expect` |
| Test a stream's emissions? | `expectLater(s, emitsInOrder([...]))` |
| Advance virtual time in pure Dart? | `fakeAsync((a) => a.elapse(...))` |
| Update golden baselines? | `flutter test --update-goldens` |
| Generate coverage? | `flutter test --coverage` → `lcov.info` |
| Helper for BLoC tests? | `blocTest` from `bloc_test` |
| Override a Riverpod dep in tests? | `ProviderContainer(overrides: [...])` |
| Runs before each test? | `setUp` (per-test), `setUpAll` (once) |
| Real async inside a widget test? | `await tester.runAsync(() async {...})` |
| Biggest golden-test flakiness cause? | cross-platform font/anti-aliasing rendering |

## Follow-up drills

1. Design a test suite for a login flow: which cases go to unit, widget, and integration, and what do you mock at each level?
2. A widget test hangs forever. Walk through diagnosing it (hint: `pumpAndSettle` + an infinite spinner).
3. Your golden tests pass locally but fail on the CI Linux runner. Explain why and fix it.
4. Given a `ViewModel` that directly instantiates an `HttpClient` and calls `DateTime.now()`, refactor it to be unit-testable and write the key tests.
5. Test a search field that debounces input by 300ms and cancels in-flight requests — without any real waiting.
6. You have 92% coverage but production bugs keep shipping. Argue what's wrong with the test strategy and how you'd rebalance it.
