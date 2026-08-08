# Widgets, Layout & Lifecycle — Interview Questions

> How Flutter widgets are built, composed, laid out, and torn down. For depth see [07 Widgets](../07%20Widgets/README.md) and [08 Widget Lifecycle](../08%20Widget%20Lifecycle/README.md).

This topic tests whether you understand Flutter's declarative model beyond the surface: the widget/element/render-object split, the State lifecycle and where side-effects belong, the "constraints go down, sizes go up" layout protocol, and how to avoid leaks and needless rebuilds. Interviewers use it to separate people who memorized widget names from people who understand the framework.

## 🟢 Basic

**1. What is a Widget in Flutter?**
A Widget is an immutable configuration/blueprint for a piece of UI. It is not the thing on screen — it's a lightweight description that Flutter inflates into an `Element` (which holds the tree position and lifecycle) and, for rendering widgets, a `RenderObject` (which does layout and paint). Because widgets are cheap and immutable, Flutter can rebuild them freely and diff the new tree against the old.

**2. StatelessWidget vs StatefulWidget — when do you use each?**
Use `StatelessWidget` when everything the widget needs is passed in via its constructor and never changes internally over its lifetime (it can still change when the parent rebuilds it with new inputs). Use `StatefulWidget` when the widget must hold mutable state that changes over time in response to user interaction, timers, streams, or animations, and it needs to trigger its own rebuilds via `setState`.

```dart
// Stateless: pure function of its inputs
class Price extends StatelessWidget {
  const Price(this.amount, {super.key});
  final double amount;
  @override
  Widget build(BuildContext c) => Text('\$$amount');
}
```

**3. Why is `build()` allowed to be called many times, and what does that imply?**
`build()` can run on every frame, every `setState`, every parent rebuild, and on hot reload. So it must be cheap, pure, and side-effect free — no network calls, no timers, no controller creation inside `build`. Side-effects go in lifecycle methods (`initState`) or event handlers, never in `build`.

**4. Why is `State` separate from the `StatefulWidget` itself?**
The `StatefulWidget` is immutable and gets thrown away and recreated on every rebuild. The `State` object is long-lived — it persists across rebuilds as long as the element stays in the tree — so mutable data lives there. That split is what lets the framework rebuild widgets cheaply while keeping your state intact.

**5. What is the difference between a widget's constructor being `const` and not being `const`?**
A `const` constructor lets Dart canonicalize the widget at compile time so the exact same instance is reused. During rebuilds Flutter can then short-circuit: if the new widget is `identical` to the old one, that subtree is skipped entirely. Non-const widgets are new instances every build, forcing a diff.

**6. What does `setState` actually do?**
`setState` synchronously runs the callback you pass (where you mutate fields) and then marks the element dirty so it's rebuilt on the next frame. It does not rebuild immediately, and it only rebuilds this widget's subtree. Mutating state without `setState` changes the data but never schedules a rebuild, so the UI goes stale.

**7. What is `BuildContext`?**
`BuildContext` is a handle to the location of a widget in the element tree. You use it to look up inherited widgets (`Theme.of`, `MediaQuery.of`), find ancestors, and get the render object. It's essentially the `Element` itself exposed through a narrower interface.

**8. What's the core layout rule in Flutter (one sentence)?**
Constraints go down, sizes go up, and the parent sets the position. A parent passes `BoxConstraints` to each child, the child picks its own size within those constraints and reports it back, then the parent decides where to place the child.

**9. What is a `BoxConstraints`?**
`BoxConstraints` is the min/max width and height a parent imposes on a child during layout (`minWidth`, `maxWidth`, `minHeight`, `maxHeight`). The child must choose a size that satisfies them. This single downward-flowing object is the whole layout contract.

**10. `Row` vs `Column` vs `Flex`?**
`Row` lays children out horizontally, `Column` vertically. Both are just `Flex` with a fixed `direction` — `Flex` is the general form where you pass `direction: Axis.horizontal/vertical`. You control alignment with `mainAxisAlignment` (along the layout direction) and `crossAxisAlignment` (perpendicular).

**11. What does `Expanded` do?**
`Expanded` forces its child to fill the available free space along a `Flex`'s main axis, dividing space by `flex` factor when there are several. It applies a *tight* constraint on the main axis, so the child has no say in its main-axis size.

**12. What is a `Stack` / `Positioned` for?**
`Stack` overlays children on top of each other in paint order (later children on top). `Positioned` (only valid directly inside a `Stack`) pins a child by `top`/`right`/`bottom`/`left`/`width`/`height`. Non-positioned children are sized and aligned by the stack's `alignment`.

**13. Why must you call `super.dispose()` and dispose controllers?**
Controllers (`AnimationController`, `TextEditingController`, `ScrollController`, `StreamSubscription`, timers) hold resources and often register with tickers or listeners. If you don't `dispose()` them when the `State` is removed, they keep firing and holding references — a memory/CPU leak. `dispose` is the mirror of `initState`.

## 🟡 Intermediate

**14. Walk through the `State` lifecycle in order and say what belongs where.**
| Method | When | What goes here |
|---|---|---|
| `createState()` | once, when widget inserted | return your `State` instance only |
| `initState()` | once, before first build | one-time setup: controllers, subscriptions, listeners. No `InheritedWidget` lookups |
| `didChangeDependencies()` | after `initState`, and whenever an inherited dependency changes | react to `InheritedWidget` data (Theme/MediaQuery/Provider) |
| `build()` | every frame it's dirty | return the widget subtree, pure |
| `didUpdateWidget(old)` | parent rebuilds with a new widget instance | react to changed config; e.g. re-subscribe if a callback/id changed |
| `deactivate()` | element removed from tree (may be reinserted) | rarely used; cleanup before possible move |
| `dispose()` | permanently removed | tear down everything created in `initState` |

**15. Why can't you use `context` for an `InheritedWidget` in `initState`?**
In `initState` the element is inserted but the framework has not yet registered this widget as a dependent of any ancestor `InheritedWidget`, so calling `Theme.of(context)` / `MediaQuery.of(context)` either throws in debug or won't rebuild you when that ancestor later changes. `didChangeDependencies` runs right after `initState` *and* every time a dependency changes — that's the correct place, because the dependency link exists and you'll be re-notified.

**16. `didChangeDependencies` vs `didUpdateWidget` — what triggers each?**
`didChangeDependencies` fires when an `InheritedWidget` this state depends on changes (e.g. theme/locale switch). `didUpdateWidget(oldWidget)` fires when the *parent* rebuilds and hands this element a new widget of the same type — you compare `widget` vs `oldWidget` and react to changed constructor params (e.g. the parent swapped the `animation` or `url`).

**17. Why does a `ListView` inside a `Column` throw an unbounded-height error?**
`Column` gives its children *unbounded* height on the main axis (it wants each child to be as tall as it wants). A scrollable like `ListView` wants to expand to fill all available height — but "all available height" is infinite here, which is undefined. Fix by giving it a bounded height: wrap in `Expanded` (take the remaining space), give it a fixed-height `SizedBox`, or set `shrinkWrap: true` (only for small lists — it measures all children, defeating lazy building).

**18. `Expanded` vs `Flexible` vs `Spacer`?**
| | Constraint on child | Use |
|---|---|---|
| `Expanded` | tight — child *must* fill its share | fill remaining space |
| `Flexible` | loose (`fit: FlexFit.loose`) — child may be *up to* its share | let a child shrink but not forced to grow |
| `Spacer` | takes flexible empty space | push widgets apart with no visible child |
`Expanded` is literally `Flexible(fit: FlexFit.tight)`. `Spacer` is an `Expanded` wrapping an empty `SizedBox`.

**19. What is the difference between tight and loose constraints?**
A *tight* constraint has `minWidth == maxWidth` (and same for height) — the child has exactly one legal size, it's forced. A *loose* constraint has `min == 0` — the child may be any size up to the max, so it sizes to its content. `BoxConstraints.tight(size)` vs `BoxConstraints.loose(size)`. `Center`, for example, loosens the constraints it passes to its child.

**20. What is `LayoutBuilder` and when do you need it (vs `MediaQuery`)?**
`LayoutBuilder` gives you the `BoxConstraints` from the *parent* at build time, so you can build differently based on the space actually available to this widget. `MediaQuery.of(context).size` gives the whole screen/window. Use `LayoutBuilder` for responsive layout inside a panel/card that isn't full-screen; use `MediaQuery` for screen-level decisions.

**21. Name a few "builder" widgets and why they exist.**
`LayoutBuilder` (build from parent constraints), `StreamBuilder`/`FutureBuilder` (rebuild on async data), `ValueListenableBuilder` / `AnimatedBuilder` (rebuild only on a listenable, keeping the rest const), `Builder` (get a fresh `context` below the current widget, e.g. to access a `Scaffold` provided above). They exist to scope rebuilds tightly and/or to defer building until some value/context is available.

**22. How do `const` constructors help performance concretely?**
When a parent rebuilds, it produces new child widgets. If a child is `const`, the new instance is `identical` to the old one, so `Element.updateChild` returns immediately without rebuilding that subtree or touching its render objects. Marking leaf widgets `const` (and enabling the `prefer_const_constructors` lint) is the cheapest widespread rebuild optimization.

**23. What is intrinsic sizing and why is it expensive?**
Intrinsic sizing (`IntrinsicWidth`/`IntrinsicHeight`, or a parent that queries `getMinIntrinsicWidth` etc.) asks a child "how big would you be ideally?" *before* the real layout pass. Answering usually requires an extra speculative layout of the subtree, turning a single-pass O(n) layout into effectively O(n²) in the worst case. Use it only when unavoidable; prefer fixed sizes, `Flexible`, or `Table`/`Wrap` alternatives.

**24. Why is `key` important, and when do you need one?**
Keys let Flutter match elements to widgets correctly when reordering, inserting, or removing children of the same type in a list. Without keys, Flutter matches by position and can attach the wrong `State` to the wrong item (e.g. after removing an item, the checkbox state "shifts"). Use `ValueKey`/`ObjectKey` on list items with identity; use `GlobalKey` sparingly to access a state/element across the tree.

**25. What happens on hot reload with respect to the lifecycle?**
Hot reload re-runs `build()` and preserves `State` (fields keep their values), but it does *not* re-run `initState`. So changes to `initState` logic won't take effect until a hot *restart*. This is why controllers set up once in `initState` survive a hot reload unchanged.

**26. How do you rebuild only part of a large widget on a value change?**
Wrap just the reactive slice in `ValueListenableBuilder`/`AnimatedBuilder`/`StreamBuilder` and pass the static rest via the `child` parameter so it's built once and reused. This confines `build` work to the small subtree instead of rebuilding the whole page with `setState`.

## 🔴 Advanced

**27. Explain the three trees: Widget, Element, RenderObject.**
The **Widget** tree is the immutable configuration you write. The **Element** tree is the mutable, persistent middle layer: each element holds a widget, its position in the tree, and its lifecycle, and it decides whether to update or replace its render object on rebuild. The **RenderObject** tree does the real work — layout (constraints/size), painting, and hit-testing. On rebuild Flutter diffs new widgets against the existing elements; elements are reused (updating their render objects) whenever the widget's `runtimeType` and `key` match, which is what makes rebuilds cheap.

**28. Precisely, how does the element decide to update vs recreate a child?**
`Element.updateChild(oldChild, newWidget)` checks: if `newWidget == null`, deactivate the child; if `oldChild != null` and `Widget.canUpdate(old.widget, newWidget)` is true (same `runtimeType` **and** same `key`), it calls `child.update(newWidget)` and keeps the element (and its `State`/render object); otherwise it deflates the old element and inflates a new one. This is why changing a widget's `key` blows away its `State`.

**29. Why does `initState` run before `didChangeDependencies`, and what would break if you did inherited lookups in `initState`?**
The framework mounts the element, then calls `initState`, then registers dependencies and calls `didChangeDependencies` for the first time. If you read an `InheritedWidget` in `initState`, you read it *without* creating a dependency, so you won't get `didChangeDependencies` callbacks when it changes — your widget would silently use stale theme/locale/provider data forever. Debug mode asserts against this for the common `.of(context)` helpers.

**30. Trace a full layout pass for `Center(child: Text('hi'))` inside a sized box.**
The box passes tight constraints down to `Center`. `Center` (a loosening parent) passes *loose* constraints (`0..maxW`, `0..maxH`) down to `Text`. `Text` measures its content and returns its intrinsic size up. `Center` sizes itself to the incoming constraints (fills the box) and positions the child at the center by setting the child's offset. Sizes flowed up, position was set by the parent — the protocol end to end.

**31. When does a `RenderObject` decide it is or isn't a "relayout boundary," and why does it matter?**
If a render object receives *tight* constraints (its size can't change regardless of children) and doesn't size to its parent, it becomes a relayout boundary: when it marks itself dirty, layout doesn't have to propagate up past it. Boundaries limit how far `markNeedsLayout` walks the tree, so tight constraints and `RepaintBoundary` (its paint analog) are how you contain the cost of frequent updates.

**32. What subtle bug does `didUpdateWidget` prevent with listeners/controllers?**
If your state subscribes to something derived from a widget parameter (e.g. `widget.controller` or `widget.stream`) in `initState`, and the parent later passes a *different* controller/stream, `initState` won't run again — so you're still listening to the old one. In `didUpdateWidget` you compare `oldWidget.controller != widget.controller`, remove the listener from the old, and add it to the new. Forgetting this is a classic "stale listener / wrong data" bug.

```dart
@override
void didUpdateWidget(covariant MyWidget old) {
  super.didUpdateWidget(old);
  if (old.controller != widget.controller) {
    old.controller.removeListener(_onChange);
    widget.controller.addListener(_onChange);
  }
}
```

**33. `deactivate` vs `dispose` — is there a case where `deactivate` doesn't lead to `dispose`?**
Yes. `deactivate` runs when an element is removed from the tree, but if it's reinserted elsewhere in the *same frame* (e.g. moved via a `GlobalKey`), it's reactivated and never disposed. `dispose` only runs when the element is not readopted by end of frame and is permanently removed. So put reversible/move-safe cleanup in `deactivate` and permanent teardown in `dispose`.

**34. How exactly does an undisposed `AnimationController` leak, and how would you catch it?**
An `AnimationController` registers with the `Ticker` provider (via `TickerProviderStateMixin`), so it keeps receiving frame callbacks and holds a reference to its `State` (and its subtree). Not disposing it means the ticker stays active, wasting frames, and the `State` can't be garbage-collected. Flutter's debug mode actively throws "A TickerProvider was disposed with an active Ticker" / leak warnings; also watch for `setState called after dispose` from late async callbacks — guard with `if (!mounted) return;`.

**35. Why can `shrinkWrap: true` on a `ListView` hurt, and what's the right fix for "list inside a column"?**
`shrinkWrap` makes the list measure *all* its children to size itself, defeating lazy/viewport building and causing jank/O(n) work for long lists. When you need a list inside a `Column`, prefer `Expanded(child: ListView(...))` so the list gets a bounded height and stays lazy, or restructure using a `CustomScrollView` with slivers so headers and the list share one scrollable.

**36. What is a `RepaintBoundary` and when do you add one?**
A `RepaintBoundary` isolates a subtree onto its own layer so that when it repaints (e.g. an animation) it doesn't force ancestors/siblings to repaint, and vice-versa. Add it around frequently-animating widgets or expensive-to-paint static content next to churning UI. Overusing it costs memory (extra layers), so measure with the "repaint rainbow" in DevTools first.

**37. How do `Flexible`/`Expanded` interact with a child that has its own intrinsic/min size?**
`Expanded` applies a tight main-axis constraint equal to the child's flex share, overriding the child's preferred size — so a min-size child gets stretched or, if the share is smaller than its content, can overflow. `Flexible` (loose) lets the child stay at its intrinsic size up to the share. If content might exceed the space, combine with `FittedBox`, `overflow` handling, or make the child scrollable — don't rely on flex alone to prevent overflow.

**38. Why is mutating widget fields wrong, and where does mutable state legitimately live?**
Widgets are immutable by contract; the framework assumes it can compare and discard them, and it may reuse a widget instance across builds. Mutating a widget field breaks the diffing assumptions and won't schedule a rebuild. All mutable state lives in the `State` object (or a state-management holder outside the tree), which is persistent and whose changes are funneled through `setState`/listeners.

**39. A screen janks on every keystroke in a `TextField`. Diagnose with lifecycle/rebuild reasoning.**
Likely the whole page rebuilds because the `TextEditingController`/form state change triggers `setState` high in the tree, or a heavy widget isn't `const`/isn't behind a `RepaintBoundary`. Fixes: listen to the controller with `ValueListenableBuilder` and pass the static subtree via `child`; mark unchanging children `const`; move the field into its own small `StatefulWidget` so `setState` is scoped; ensure no expensive work (parsing, layout with intrinsics) runs in `build`.

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| Is a Widget mutable? | No — immutable config; `Element` holds the mutable position/lifecycle. |
| Where do you create controllers? | `initState`, and dispose them in `dispose`. |
| Where do you read `Theme.of(context)` for the first time safely? | `didChangeDependencies` (or `build`), not `initState`. |
| Constraints flow which way? | Down; sizes flow up; parent sets position. |
| `Expanded` = ? | `Flexible(fit: FlexFit.tight)`. |
| Tight constraint means? | `min == max` — one legal size. |
| Why does ListView-in-Column crash? | Column gives unbounded height; scrollable can't fill infinity. Wrap in `Expanded`. |
| `Spacer` is? | An `Expanded` around empty space. |
| Cost of `IntrinsicHeight`? | Extra speculative layout pass — up to O(n²). |
| What makes `const` widgets fast? | `identical` check skips rebuilding the subtree. |
| `didUpdateWidget` is for? | Reacting to changed constructor params from the parent. |
| Does hot reload call `initState`? | No — only hot restart does. |
| `setState` after `dispose`? | Guard with `if (!mounted) return;`. |
| `LayoutBuilder` gives you? | The parent's `BoxConstraints`. |
| `Stack` paint order? | Later children paint on top. |
| Changing a widget's `key`? | Destroys and recreates its `State`. |

## Follow-up drills

1. Design a responsive dashboard tile that switches between a 1-column and 2-column internal layout based on the space its parent gives it (not the screen size). Which builder and why?
2. Debug this: after deleting the second item in a list, the *third* item's expand/collapse state is now wrong. Explain the root cause and fix.
3. Optimize a page where a 1-second-interval clock in the app bar is causing the entire scaffold body to rebuild every tick.
4. You have a `StatefulWidget` whose `widget.userId` can change when the parent rebuilds. Write the lifecycle code that keeps a stream subscription correct across `initState`, `didUpdateWidget`, and `dispose`.
5. Explain why wrapping a whole page in a single `AnimatedBuilder` is worse than wrapping only the animating leaf, in terms of the element/render trees.
6. Given a `Row` that overflows on small screens, walk through three structurally different fixes (`Flexible`, `FittedBox`, scroll) and the trade-offs of each.
