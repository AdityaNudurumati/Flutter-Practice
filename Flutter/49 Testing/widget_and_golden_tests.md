# Widget & Golden Tests

> Widget tests verify **UI behavior** without a device: `testWidgets` **pumps** a widget into a fake test binding, you locate elements with **finders** (`find.text`/`byType`/`byKey`), drive **interactions** (`tester.tap`/`enterText` + `pump`/`pumpAndSettle`), and **assert** with matchers (`findsOneWidget`). **Golden tests** go further — they render a widget and compare it **pixel-for-pixel** against a saved reference image (`matchesGoldenFile`), catching *visual* regressions (layout/color/spacing) that behavioral assertions miss. Both are the pyramid's middle: slower than unit, far faster than E2E, and the way to test screens/widgets and their states/interactions.

## Introduction

This file covers widget testing (pump/finders/interactions/`pumpWidget` harness, faking dependencies, `pump` vs `pumpAndSettle`) and golden (snapshot) testing (when/how, managing goldens). It's the UI-behavior middle of the pyramid ([testing_fundamentals_and_pyramid.md](testing_fundamentals_and_pyramid.md)).

## Why this concept exists

Unit tests can't verify that the UI **renders correctly and responds to interaction**; E2E tests can but are slow/flaky. Widget tests fill the gap: real widget rendering in a controllable, device-free binding — fast enough to run many, precise enough to catch UI regressions. Golden tests add **visual** verification (pixels), catching layout/style regressions that "find the text" assertions can't.

## Real-world analogy

A widget test is **testing a dashboard cluster on a bench rig**: you power it with simulated inputs (faked state), **press its buttons** (tap), and **check the gauges read correctly** (finders/matchers) — without installing it in a car (device). A golden test is **photographing the lit dashboard and comparing it to an approved photo** — catching a misaligned needle or wrong-colored light that "the speed value is 60" wouldn't.

## Internal Working

```mermaid
flowchart TD
    Pump[pumpWidget(harness + widget + faked deps)] --> Find[find: byText/byType/byKey]
    Find --> Interact[tap/enterText/drag -> pump / pumpAndSettle]
    Interact --> Assert[expect(finder, findsOneWidget/findsNothing)]
    Golden[render -> matchesGoldenFile('x.png')] --> Compare[pixel compare vs saved reference]
    Note[widget = behavior; golden = visual pixels; no device (fake binding)]
```

- **`testWidgets` + `WidgetTester`**: the entry point. `await tester.pumpWidget(widget)` builds a tree in the **test binding** (a fake engine — no real screen, controllable time). Wrap the widget under test in the needed ancestors (`MaterialApp`/`Directionality`/providers) — a **test harness**.
- **Finders** (locate elements): `find.text('Retry')`, `find.byType(ElevatedButton)`, `find.byKey(Key('submit'))`, `find.byIcon`, `find.byWidgetPredicate`. Prefer **`byKey`/`byType`** for stability over brittle text where appropriate.
- **Interactions**: `await tester.tap(finder)`, `enterText(finder, 'x')`, `drag`, `fling`, `longPress` — each followed by a **pump** to process the frame.
- **`pump` vs `pumpAndSettle`**: `pump()` advances **one frame** (or a duration); `pumpAndSettle()` pumps **until no frames are scheduled** (animations/async settle). Use `pumpAndSettle` after navigation/animations; but it **hangs on infinite animations** — use `pump(duration)` there.
- **Matchers**: `findsOneWidget`, `findsNothing`, `findsNWidgets(n)`, `findsWidgets`; combine with `expect`.
- **Faking dependencies**: inject **fakes** (fake view model/use case/repository) via the harness (Provider override, constructor, DI) so the widget test is **isolated + deterministic** — no real network ([unit_and_mocking.md](unit_and_mocking.md)). Test **each UI state** (loading/data/empty/error) by feeding the corresponding state/fake ([Module 43](../43%20MVVM/README.md)).
- **What widget tests verify**: rendering per state, presence/absence of elements, interaction outcomes (tap → state change → new render), form validation, navigation triggers — **UI behavior**, not business logic (that's unit tests).
- **Golden (snapshot) tests**: `await expectLater(find.byType(MyWidget), matchesGoldenFile('goldens/my_widget.png'))`. First run (`--update-goldens`) **saves** the reference; later runs **compare pixel-for-pixel** and fail on diffs. Catches **visual** regressions (layout/spacing/color/font).
  - **Manage carefully**: goldens are **platform/font-sensitive** (render can differ across OS/CI) — generate on a **consistent environment** (CI or `golden_toolkit`/`alchemist` for device-independent rendering + multi-device goldens), **review golden diffs** as artifacts, and **regenerate deliberately** on intended UI changes. Don't golden-test volatile/dynamic content (timestamps, random data).
  - Use goldens for **stable, design-critical** widgets (design-system components, key screens), not everything.
- **Test keys**: add `Key`s to widgets you need to find reliably (avoids brittle text-based finders), especially for lists/dynamic UI.
- **Speed/reliability**: widget tests run in the VM's test binding (no device) — fast enough for many; keep them **isolated** (fakes) and **deterministic** (control time via `pump`, avoid real async).

## Memory Representation

Widget tests build a real widget/element/render tree in the test binding (in-memory, no GPU). Goldens are saved PNG references compared against freshly-rendered pixels. Fakes provide deterministic state.

## Compiler Behavior

Widget tests compile against real widgets + fakes; goldens reference saved image files. Test keys/finders are compile-time widget references.

## Runtime Behavior

The test binding renders synchronously under your control (`pump`); interactions + async resolve only when you pump. Golden comparison is pixel-diff (fails on any mismatch beyond tolerance). No real device/vsync.

## Flutter Engine Behavior

The **test binding fakes the engine**: layout/paint happen into an offscreen surface, time is manually advanced (`pump`), and there's no real rasterization to a screen — enabling fast, deterministic UI tests. Goldens capture that offscreen render.

## Dart VM Behavior

Runs in the VM with the Flutter test binding — slower than pure unit (tree building) but far faster than device E2E; parallelizable.

## Examples

```dart
import 'package:flutter_test/flutter_test.dart';

// Harness: wrap the widget with needed ancestors + faked state
Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('error state shows message + retry, tap triggers retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(harness(                    // pump into fake binding
      ProfileView(state: const ProfileError('Failed'), onRetry: () => retried = true),
    ));
    expect(find.text('Failed'), findsOneWidget);        // finder + matcher
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));               // interaction
    await tester.pump();                                // process the frame
    expect(retried, isTrue);                            // behavior assertion
  });

  testWidgets('loading state shows a spinner', (tester) async {
    await tester.pumpWidget(harness(const ProfileView(state: ProfileLoading())));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // GOLDEN — visual snapshot of a design-system component (stable UI)
  testWidgets('AppButton matches golden', (tester) async {
    await tester.pumpWidget(harness(const AppButton(label: 'Save')));
    await expectLater(find.byType(AppButton), matchesGoldenFile('goldens/app_button.png'));
    // First run: flutter test --update-goldens (saves reference). Later: pixel compare.
  });
}
```

```text
pump vs pumpAndSettle:
  await tester.pump();               // advance ONE frame (or pump(Duration))
  await tester.pumpAndSettle();      // pump until no frames scheduled (animations/async settle)
                                     // WARNING: hangs on infinite animations -> use pump(duration)
```

## Diagrams

```mermaid
flowchart LR
    State[faked state (loading/data/empty/error)] --> Pump2[pumpWidget in harness]
    Pump2 --> Verify[finders + matchers verify render]
    Pump2 --> Tap[interact -> pump -> assert behavior]
    Pump2 --> Snap[golden: pixel compare (stable UI)]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Real network/deps in widget tests | Slow/flaky/non-deterministic | Inject fakes (fake VM/use case) |
| Forgetting to `pump` after interaction | UI not updated → wrong assertion | `pump`/`pumpAndSettle` after actions |
| `pumpAndSettle` with infinite animation | Test hangs | `pump(duration)` instead |
| Brittle text-only finders | Break on copy changes | Use `byKey`/`byType` where sensible |
| Golden-testing volatile content | Constant false failures | Golden only stable/design-critical UI |
| Goldens on inconsistent envs | Platform/font pixel diffs | Generate on consistent env / `golden_toolkit`/`alchemist` |
| Not testing all UI states | Missed empty/error regressions | Test loading/data/empty/error |
| Missing harness ancestors | Widget throws (no Directionality/Material) | Wrap in required ancestors |

## Best Practices

- Use `testWidgets` + a **harness** (needed ancestors) with **faked state/deps** to test **each UI state** (loading/data/empty/error) + interactions; assert with **finders + matchers**; `pump`/`pumpAndSettle` appropriately.
- Prefer **`byKey`/`byType`** finders for stability; add `Key`s to dynamic widgets; keep widget tests **isolated + deterministic** (no real I/O/time).
- Use **golden tests** for **stable, design-critical** widgets (design-system components, key screens); generate on a **consistent environment** (or `golden_toolkit`/`alchemist`), **review diffs**, and **regenerate deliberately**; avoid goldening volatile content.
- Test **UI behavior** here (rendering/interactions/navigation triggers), leaving **business logic to unit tests**.

## Performance

Widget tests run in the test binding (no device) — fast enough for many, but slower than unit tests (tree building) → keep the pyramid unit-heavy. Golden pixel-diffs add a bit; run + parallelize in CI. `pumpAndSettle` on infinite animations is the classic hang (use `pump(duration)`).

## Advantages / Disadvantages

- **+** Verifies real UI rendering + interactions device-free; per-state coverage; goldens catch visual regressions; fast enough for many.
- **−** Slower than unit; goldens are env/font-sensitive + need review/regeneration; brittle finders; harness/faking setup; `pumpAndSettle` pitfalls.

## Interview Questions

1. **🟢 What does a widget test verify, and how?** — UI behavior (rendering/interactions) device-free: `pumpWidget` into a test binding, locate with finders, drive interactions + `pump`, assert with matchers.
2. **🟢 `pump` vs `pumpAndSettle`?** — `pump` advances one frame (or a duration); `pumpAndSettle` pumps until no frames are scheduled — but hangs on infinite animations (use `pump(duration)`).
3. **🟡 What is a golden test and what does it catch?** — A pixel snapshot compared against a saved reference (`matchesGoldenFile`); catches visual regressions (layout/spacing/color/font) that behavioral assertions miss.
4. **🟡 How do you keep widget tests isolated/deterministic?** — Inject fakes for the view model/use case/repository via the harness; no real network/time; test each state by feeding it.
5. **🟡 Why prefer `byKey`/`byType` over text finders?** — Text finders break on copy changes; keys/types are stable references (add `Key`s to dynamic widgets).
6. **🔴 What makes golden tests tricky, and how do you manage them?** — Platform/font pixel differences; generate on a consistent env (or `golden_toolkit`/`alchemist`), review diffs, regenerate deliberately, and avoid goldening volatile content.
7. **🔴 What belongs in a widget test vs a unit test?** — Widget: rendering/interactions/navigation triggers (UI behavior); unit: business logic — don't test logic through the widget.

## Senior Engineer Tips

- Drive widget tests off faked state so you can test loading/data/empty/error deterministically; testing UI through real network is slow, flaky, and misses states.
- Reserve golden tests for stable design-system components and key screens, generate them on a controlled environment (CI or `alchemist`/`golden_toolkit`), and treat golden diffs as reviewable artifacts — casual goldens everywhere are a maintenance sink.
- Add `Key`s and prefer type/key finders; text-based finders that break on every copy tweak are why teams start ignoring widget tests.

## Architect Perspective

Widget and golden tests are the pyramid's UI-behavior middle: they verify that state renders correctly and interactions work (widget) and that the pixels stay right (golden), device-free and fast enough to run broadly. Driven off faked state (the MVVM payoff), they cover the states/interactions unit tests can't and the visuals E2E is too slow to guard — completing behavioral + visual regression safety before the thin E2E tip ([Module 43](../43%20MVVM/README.md), [integration_and_e2e.md](integration_and_e2e.md), [testing_fundamentals_and_pyramid.md](testing_fundamentals_and_pyramid.md)).

## Summary

- Widget tests (`testWidgets`): pump a widget into a fake binding, find elements (finders), interact (tap/enterText + pump/pumpAndSettle), assert (matchers) — verifying UI behavior device-free, per state, with faked deps.
- Golden tests: pixel-snapshot comparison (`matchesGoldenFile`) catching visual regressions — for stable/design-critical UI, on a consistent env, reviewed + regenerated deliberately.
- Prefer key/type finders; isolate with fakes; `pumpAndSettle` (not on infinite animations); leave business logic to unit tests.

## Revision Notes

- `testWidgets((tester){...})`: `pumpWidget(harness)`; finders (`find.text/byType/byKey/byIcon/byWidgetPredicate`); interactions (`tap/enterText/drag` + `pump`/`pumpAndSettle`); matchers (`findsOneWidget/findsNothing/findsNWidgets`).
- `pump` = one frame/duration; `pumpAndSettle` = until idle (hangs on infinite animations → `pump(duration)`); wrap in required ancestors (harness); inject fakes → isolated/deterministic; test each state (loading/data/empty/error).
- Golden: `matchesGoldenFile` pixel compare; `--update-goldens` saves; env/font-sensitive → consistent env / `golden_toolkit`/`alchemist`; review diffs, regenerate deliberately, only stable/design-critical UI; prefer key/type finders; UI behavior here, logic in unit tests.

## Practice Questions

1. How do you test each UI state of a screen device-free?
2. When do you use golden tests, and what makes them tricky?
3. `pump` vs `pumpAndSettle` — and when does the latter hang?

## Coding Questions

1. Write widget tests for loading/data/empty/error states with a faked VM.
2. Test a tap → state-change → re-render interaction (with `pump`).
3. Add a golden test for a design-system component.

## Mini Project

**Widget + golden suite (Flutter):** For a screen with loading/data/empty/error states, write widget tests (harness + faked view model) verifying each state's render + a tap interaction (retry → triggers reload), using key/type finders, plus a golden test for one stable design-system component (generated on a consistent env). Acceptance: each UI state tested with faked deps (isolated/deterministic); interaction verified with proper `pump`; stable finders (key/type); one golden for a design-critical widget (reviewable, deliberately regenerated); no business logic tested through the widget.
