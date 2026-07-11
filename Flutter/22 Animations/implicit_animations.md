# Implicit Animations (`AnimatedFoo`, `TweenAnimationBuilder`)

> Implicit animations animate **automatically** when a property changes: give an `AnimatedContainer`/`AnimatedOpacity`/etc. a new target value + `duration`, and Flutter tweens from old to new for you — no controller, no lifecycle, ideal for simple state-driven transitions.

## Introduction

Implicit animation widgets (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedPositioned`, `AnimatedAlign`, `AnimatedDefaultTextStyle`, and the general `TweenAnimationBuilder`/`AnimatedSwitcher`) animate to whatever new value you build with. This file covers them and when they're the right, low-boilerplate choice.

## Why this concept exists

Many animations are just "smoothly go from the old value to the new one" on a state change (size, color, opacity, position). Managing a controller for that is overkill. Implicit widgets do it declaratively: change the value, set a duration, done — perfectly matching the declarative UI model.

## Real-world analogy

Implicit animation is a **thermostat with a smooth dial**: you set a new target temperature (property), and it eases there over time automatically — you don't manually turn the dial degree by degree (no controller).

## Problem Statement

A card should smoothly resize/recolor when expanded, an icon should cross-fade when toggled, and a badge should animate its count — all from simple state changes, no controllers. You'll use `AnimatedContainer`, `AnimatedSwitcher`, and `TweenAnimationBuilder`.

## Internal Working

```mermaid
flowchart TD
    State[build with a NEW value] --> Widget[AnimatedFoo (duration, curve)]
    Widget --> Detect[detects value changed vs last build]
    Detect --> Tween[internally tweens old -> new over duration]
    Tween --> Render[animates automatically]
```

- **`AnimatedFoo` widgets**: hold animatable props + `duration` (+ optional `curve`). On rebuild with a **different** value, they animate from the previous to the new value internally (their own controller). Examples: `AnimatedContainer` (size/color/padding/decoration), `AnimatedOpacity`, `AnimatedPositioned` (in a `Stack`), `AnimatedAlign`, `AnimatedPadding`, `AnimatedDefaultTextStyle`, `AnimatedPhysicalModel`.
- **`AnimatedSwitcher`**: cross-fades (or custom-transitions) between **different child widgets** when the child changes (use a `Key` to signal "different").
- **`TweenAnimationBuilder<T>`**: animates to a target value via a builder — implicit animation for arbitrary values/one-offs (e.g., animate a number, a custom paint value) without a controller.
- **Trigger**: just build with a new value (via `setState`/state management) — the animation is automatic.
- **When to use**: simple, single-shot, state-driven transitions. For **control** (play/reverse/repeat/precise sequencing) use **explicit** animations ([explicit_animations.md](explicit_animations.md)).

## Memory Representation

Implicit widgets manage their own controller/ticker internally (disposed for you). Lightweight; no manual lifecycle ([08 · dispose_and_leaks](../08%20Widget%20Lifecycle/dispose_and_leaks.md)).

## Compiler Behavior

Not applicable.

## Runtime Behavior

On rebuild, the widget compares the new value to its last and animates the delta over `duration`/`curve`; interrupting with a newer value re-targets smoothly. `AnimatedSwitcher` animates on child-key change.

## Flutter Engine Behavior

Each animating frame repaints the widget; keep the animated subtree small and isolate if expensive ([animation_performance.md](animation_performance.md)).

## Dart VM Behavior

Not applicable.

## Examples

```dart
import 'package:flutter/material.dart';

class ImplicitDemo extends StatefulWidget {
  const ImplicitDemo({super.key});
  @override State<ImplicitDemo> createState() => _ImplicitDemoState();
}
class _ImplicitDemoState extends State<ImplicitDemo> {
  bool _expanded = false;
  bool _dark = false;
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // AnimatedContainer: animates size + color on state change (no controller)
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _expanded ? 200 : 100,
          height: _expanded ? 120 : 60,
          color: _dark ? Colors.indigo : Colors.teal,
        ),
      ),

      // AnimatedSwitcher: cross-fade between DIFFERENT children (key signals change)
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          _dark ? Icons.dark_mode : Icons.light_mode,
          key: ValueKey(_dark),   // different key -> transition
          size: 48,
        ),
      ),
      Switch(value: _dark, onChanged: (v) => setState(() => _dark = v)),

      // TweenAnimationBuilder: animate an arbitrary value (a number) implicitly
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _count.toDouble()),
        duration: const Duration(milliseconds: 400),
        builder: (_, value, __) => Text('Count: ${value.toStringAsFixed(0)}'),
      ),
      ElevatedButton(onPressed: () => setState(() => _count += 10), child: const Text('+10')),
    ]);
  }
}
```

## Diagrams

```mermaid
flowchart LR
    Simple{simple state-driven transition?} -- yes --> Implicit[AnimatedFoo / TweenAnimationBuilder]
    Simple -- no, need control/sequence --> Explicit[AnimationController (explicit)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Using explicit controllers for simple transitions | Needless boilerplate/lifecycle | Use implicit `AnimatedFoo` |
| No `Key` on `AnimatedSwitcher` children | Won't detect "different" child | Give distinct `Key`s |
| Expecting play/reverse/repeat control | Implicit is fire-on-change only | Use explicit animations |
| Animating a huge subtree implicitly | Repaint cost | Isolate; keep animated part small |
| Same value each build | No animation triggers | Ensure the value actually changes |

## Best Practices

- Use **implicit** widgets for simple, state-driven, single-shot transitions (size/color/opacity/position/child-swap) — least code.
- Give **`AnimatedSwitcher`** children distinct **`Key`s**; supply a `transitionBuilder` for custom effects.
- Use **`TweenAnimationBuilder`** to implicitly animate arbitrary values without a controller.
- Set a sensible **duration/curve** (~200–400ms, standard curves); keep the animated subtree small.
- Escalate to **explicit** animations only when you need control/sequencing/repetition.

## Performance

Cheap for small subtrees; the widget manages its controller efficiently. Cost is the per-frame repaint of the animated subtree — keep it small, isolate expensive content ([21 · jank_and_raster](../21%20Performance/jank_and_raster.md)).

## Advantages / Disadvantages

- **+** Minimal boilerplate, no lifecycle to manage, declarative, great for common transitions.
- **−** No fine control (play/reverse/repeat/precise timing), fire-on-change only, less suited to complex choreography.

## Interview Questions

1. **🟢 What is an implicit animation?** — A widget that animates automatically from the old to the new value when a property changes (e.g., `AnimatedContainer`), with no explicit controller.
2. **🟢 How do you trigger one?** — Rebuild with a different value + a `duration`; the widget tweens the delta.
3. **🟡 Implicit vs explicit — when each?** — Implicit for simple, single-shot, state-driven transitions (least code); explicit when you need control/sequencing/repetition.
4. **🟡 How does `AnimatedSwitcher` know to animate?** — When its child changes identity (different `Key`), it transitions (default cross-fade) between old and new.
5. **🟡 What is `TweenAnimationBuilder` for?** — Implicitly animating an arbitrary value to a target via a builder, without managing a controller.
6. **🔴 Do implicit widgets leak?** — No; they manage/dispose their internal controller — a benefit over hand-rolled controllers.
7. **🔴 When do implicit animations *not* fit?** — Complex choreography, staggering, reversible/repeating, or physics/gesture-driven motion — use explicit/physics ([explicit_animations.md](explicit_animations.md), [physics_and_gesture_driven.md](physics_and_gesture_driven.md)).

## Senior Engineer Tips

- Reach for implicit first — most UI motion (expand/collapse, color/opacity/position changes, icon swaps) needs nothing more.
- Remember the `Key` rule for `AnimatedSwitcher`; without a changing key it won't animate.
- Keep durations consistent with your design system; wrap common implicit transitions in reusable widgets.

## Architect Perspective

Implicit animations align motion with the declarative model (animate on value change) and eliminate controller lifecycle bugs — ideal for the bulk of everyday UI motion. Reserving explicit/physics for genuinely complex cases keeps animation code minimal and maintainable across a design system ([Module 25](../25%20Adaptive%20UI/README.md)).

## Summary

- Implicit widgets (`AnimatedFoo`/`AnimatedSwitcher`/`TweenAnimationBuilder`) animate automatically on value/child change — no controller, no lifecycle.
- Best for simple, single-shot, state-driven transitions; give `AnimatedSwitcher` children keys.
- Escalate to explicit/physics for control, choreography, or gesture/physics-driven motion.

## Revision Notes

- `AnimatedFoo(duration, curve)` animates old→new on rebuild (self-managed controller).
- `AnimatedSwitcher` (child key change → transition); `TweenAnimationBuilder<T>` (implicit arbitrary value).
- No play/reverse/repeat control → use explicit for that.
- Keep animated subtree small; ~200–400ms; standard curves.

## Practice Questions

1. When choose implicit over explicit?
2. Why does `AnimatedSwitcher` need a changing `Key`?
3. What does `TweenAnimationBuilder` enable without a controller?

## Coding Questions

1. Build an expand/collapse `AnimatedContainer` (size + color).
2. Cross-fade an icon with `AnimatedSwitcher` (keys) + a custom `transitionBuilder`.
3. Animate a counter number with `TweenAnimationBuilder`.

## Mini Project

**Implicit interactions (Flutter):** Build a card that expands/recolors (`AnimatedContainer`), a theme icon that cross-fades (`AnimatedSwitcher`), and a stat that animates its number (`TweenAnimationBuilder`) — all driven by simple state, no controllers. Acceptance: smooth transitions on state change; correct switcher keys; no lifecycle management; runs.
