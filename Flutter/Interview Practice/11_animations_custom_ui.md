# Animations & Custom UI — Interview Questions

> How Flutter animates over time, paints arbitrary pixels, and adapts to every screen and platform. Depth in [22 Animations](../22%20Animations/README.md), [23 Custom Painting](../23%20Custom%20Painting/README.md), [24 Responsive UI](../24%20Responsive%20UI/README.md), and [25 Adaptive UI](../25%20Adaptive%20UI/README.md).

This topic tests whether you know when to reach for implicit vs explicit animations, can manage an `AnimationController` lifecycle without leaking tickers, understand what actually makes an animation jank, and can drop to `CustomPainter` / `RenderObject` or reshape a UI across breakpoints and platforms when the framework widgets aren't enough.

## 🟢 Basic

**1. What is the difference between implicit and explicit animations?**
**Implicit** animations (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedPadding`, `TweenAnimationBuilder`) animate automatically whenever you rebuild with a new target value — you set the new value and a `duration`, and Flutter interpolates for you. **Explicit** animations (`AnimationController` + `Tween` + `AnimatedBuilder`/transitions) give you a handle you drive manually: forward, reverse, repeat, stop, seek. Rule of thumb: use implicit for simple one-shot A→B transitions triggered by state, explicit when you need control over playback, looping, coordination, or reuse.

**2. How does `AnimatedContainer` work?**
You give it a `duration` (and optional `curve`) and rebuild it with different property values (color, width, padding, alignment…). On each rebuild it detects which properties changed and animates from the old value to the new over the duration. Internally it's an `ImplicitlyAnimatedWidget` backed by a hidden `AnimationController`, so you get animation with zero controller boilerplate. The trigger is just `setState` with new values.

**3. What is `TweenAnimationBuilder` and when do you use it?**
It's the implicit animation for a *single custom value* when there's no ready-made `AnimatedX` widget. You give it a `Tween`, a `duration`, and a `builder(context, value, child)`; whenever the tween's `end` changes it animates from the current value to the new end and rebuilds via the builder. Use it for one-off custom interpolations (e.g. animating a progress arc or a number counting up) without wiring an `AnimationController`.

**4. What are the core objects in an explicit animation?**
- **`AnimationController`** — drives a value from 0.0→1.0 over a duration; produces ticks, controls playback.
- **`Tween<T>`** — maps that 0→1 into a real range (e.g. `Tween<Color>`, `Tween<Offset>`, `Tween<double>`), via `tween.animate(controller)`.
- **`Curve`** — reshapes the 0→1 timeline (ease-in, bounce…) via `CurvedAnimation`.
- **`Animation<T>`** — the read-only value + status you listen to.
- **`AnimatedBuilder`/`*Transition`** — rebuilds only the animating subtree each tick.

**5. What is a `Tween` and what does `.animate()` do?**
A `Tween<T>` defines a `begin` and `end` and knows how to `lerp` between them. `tween.animate(controller)` returns an `Animation<T>` whose value tracks the controller's 0→1 progress mapped into `[begin, end]`. Tweens hold no state themselves — they're just interpolation recipes, so you can reuse one across controllers.

**6. What is a `Curve` and why use one?**
A `Curve` remaps the linear 0→1 progress into a non-linear one — `Curves.easeInOut`, `Curves.bounceOut`, `Curves.elasticIn`, etc. Real motion is rarely linear; curves make animations feel natural (accelerate then settle). Apply with `CurvedAnimation(parent: controller, curve: Curves.easeOut)` or pass `curve:` to implicit widgets. You can also give a separate `reverseCurve`.

**7. What is `AnimatedBuilder` and why is it preferred over listening + `setState`?**
`AnimatedBuilder(animation: ..., builder: ...)` rebuilds only its `builder` on every tick, scoping the rebuild to the animating widget instead of the whole `State`. Its `child` argument lets you pass a subtree that's built **once** and reused each frame (not rebuilt), so expensive static children aren't rebuilt 60 times a second. Manually calling `setState` in a listener rebuilds the entire `build()` method — wasteful.

**8. What is a Hero animation?**
A Hero animation is a shared-element transition between two routes: wrap a widget in `Hero(tag: 'x', child: ...)` on both the source and destination pages with the **same tag**, and during navigation Flutter flies the element from its old position/size to the new one. The `Navigator` and `HeroController` handle it automatically. Tags must be unique per screen; a duplicate tag on one screen throws.

**9. What is `vsync` and why does an `AnimationController` need it?**
`vsync` takes a `TickerProvider`. The controller needs a `Ticker` that fires once per frame (driven by vsync) to advance the animation. Passing `vsync: this` binds the ticker to the widget so it's **muted when the widget is off-screen** (e.g. in an inactive route), preventing animations from burning CPU when nobody can see them. Without vsync there'd be no frame signal to step the animation.

**10. `SingleTickerProviderStateMixin` vs `TickerProviderStateMixin` — which do you use?**
Add the mixin to your `State` so it can be the `TickerProvider` (`vsync: this`). Use **`SingleTickerProviderStateMixin`** when the State drives exactly **one** `AnimationController` — it's lighter. Use **`TickerProviderStateMixin`** when you have **multiple** controllers in the same State. Using the single variant with two controllers throws at runtime.

**11. Why must you dispose an `AnimationController`?**
The controller holds a `Ticker` registered with the framework. If you don't call `controller.dispose()` in the State's `dispose()`, the ticker keeps ticking after the widget is gone — a leak that Flutter flags in debug ("A Ticker was being disposed but was still active" / disposed-controller-still-in-use). Always: create in `initState`, dispose in `dispose`.

**12. What's the difference between MediaQuery and LayoutBuilder for responsive UI?**
`MediaQuery.of(context)` gives you **screen/window-level** info: full size, orientation, padding/insets (safe area, keyboard), text scale, device pixel ratio. `LayoutBuilder` gives you the **constraints of the parent slot** the widget actually occupies — which can be much smaller than the screen. Use MediaQuery for global decisions (phone vs tablet layout, keyboard avoidance); use LayoutBuilder to adapt a widget to the space it's *given* (e.g. a card that reflows inside a column).

**13. What does "adaptive" UI mean versus "responsive" UI?**
**Responsive** = adjusting layout to *size* (columns, spacing, breakpoints) — same platform, different screen. **Adaptive** = adjusting behavior/look to the *platform or device conventions* — Material on Android/web, Cupertino on iOS; a swipe-back gesture on iOS, a mouse hover state on desktop. Responsive is about geometry; adaptive is about platform idioms. Good apps do both.

## 🟡 Intermediate

**14. Walk through the full lifecycle of an `AnimationController`.**
1. In `initState`, create it: `_c = AnimationController(vsync: this, duration: ...)`.
2. Build `Animation`s from it via tweens/curves (`_c.drive(tween)` or `tween.animate(_c)`).
3. Start playback: `forward()`, `reverse()`, `repeat()`, `animateTo()`, `fling()`.
4. React via `addListener` (value changed) and `addStatusListener` (completed/dismissed/forward/reverse).
5. In `dispose`, call `_c.dispose()`.
The controller's value stays in `[lowerBound, upperBound]` (default 0..1) and `status` reports where it is.

**15. How do you build a staggered animation?**
Use **one** `AnimationController` and give each animated property its own `Interval` curve so pieces start/finish at different fractions of the same timeline:
```dart
final fade = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));
final slide = CurvedAnimation(parent: _c, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
```
Sharing one controller keeps the phases perfectly in sync and cheap. Driving each with its own controller is possible but harder to coordinate and easier to desync.

**16. How do physics-based animations differ from duration-based ones?**
Duration-based animations run for a fixed time regardless of state. **Physics-based** ones (`SpringSimulation`, `FrictionSimulation`, `GravitySimulation` via `controller.animateWith(simulation)`) run until the *simulation settles* — duration emerges from physics (mass, stiffness, velocity), not a clock. They feel natural for gesture continuations because you can hand off the gesture's release velocity into a spring so motion continues seamlessly.

**17. How do you make a gesture-driven animation (drag to dismiss / swipe)?**
Bind an `AnimationController` to the gesture instead of playing it on a timer: in `onPanUpdate` set `_c.value += delta/extent` to track the finger, and in `onPanEnd` call `_c.fling(velocity: ...)` or `animateWith(SpringSimulation(...))` using the release velocity to settle to the nearest snap point. The controller becomes the single source of truth for position, so the finger-follow and the release animation are the same value stream. `Draggable`, `Dismissible`, and `DraggableScrollableSheet` package this pattern.

**18. What causes an animation to jank, and how do you fix it?**
Jank = a frame missed the budget (~16 ms at 60 Hz). Common causes:
- **Rebuilding too much per tick** — use `AnimatedBuilder` with a cached `child`, not `setState` on the whole tree.
- **Expensive work inside `build`/`paint`** running every frame — precompute outside the tick.
- **Repaint spilling into neighbors** — wrap the animating subtree in a `RepaintBoundary` so it composites on its own layer.
- **`saveLayer`, big images, blurs, shader compile jank** on the raster thread.
Diagnose in DevTools: is the UI thread or the raster thread over budget? Fix that one.

**19. How does `RepaintBoundary` help an animation?**
It isolates the animating subtree onto its **own compositing layer**. When the animation repaints, only that layer is re-rasterized; the static content around it reuses its cached layer, and vice-versa. This cuts raster-thread work for localized animation (a spinner, a pulsing badge). It costs extra memory per layer, so add it where an animation repaints frequently — not everywhere.

**20. Why prefer transition widgets like `FadeTransition`/`SlideTransition`/`ScaleTransition` over animating in `setState`?**
The `*Transition` widgets listen to the `Animation` and rebuild/repaint only what's necessary — often just re-applying an opacity or transform at the **paint/composite** layer without rebuilding the child. That avoids re-running `build()` for the subtree each frame. `setState`-per-tick rebuilds the entire widget and its children 60×/s. Same visual result, far less work.

**21. What is `shouldRepaint` in a `CustomPainter` and why does it matter?**
When a `CustomPaint` rebuilds, Flutter calls `shouldRepaint(oldDelegate)`; return `true` only if the painter's inputs changed, else `false` to **skip repainting** and reuse the cached picture. Getting this wrong is a classic bug: return `true` always and you repaint needlessly (jank); capture inputs incorrectly and you paint stale visuals. Compare the fields that actually affect the drawing.

**22. How do you drive a `CustomPainter` from an animation efficiently?**
Pass the `Animation` to the painter's `repaint:` constructor argument (`CustomPainter(repaint: animation)`), and base `shouldRepaint` on it. The painter then repaints on each tick **without rebuilding** the widget tree at all — the `CustomPaint` subscribes to the listenable directly. This is the cheapest way to animate custom drawing.

**23. How do you make a layout responsive with breakpoints?**
Pick width thresholds (common: ~600 for tablet, ~840/1024 for desktop) and switch layouts:
```dart
final w = MediaQuery.sizeOf(context).width;
if (w >= 1024) return DesktopLayout();
if (w >= 600)  return TabletLayout();
return MobileLayout();
```
Prefer `MediaQuery.sizeOf(context)` (Flutter 3.10+) over `MediaQuery.of` so you only rebuild on size changes. For per-widget adaptation use `LayoutBuilder`. Flutter's own `NavigationRail` vs `BottomNavigationBar` swap is a canonical breakpoint use.

**24. How do you build an adaptive (platform-aware) UI?**
Branch on the platform and use the matching design language: `Theme.of(context).platform`, `Platform.isIOS` (mobile), or `defaultTargetPlatform`. Options:
- Use `.adaptive` constructors (`Switch.adaptive`, `Checkbox.adaptive`, `CircularProgressIndicator.adaptive`) that render Cupertino on iOS and Material elsewhere.
- Swap whole widgets (`CupertinoPageScaffold`/`CupertinoButton` vs `Scaffold`/`ElevatedButton`).
- Use `defaultTargetPlatform` (not `Platform`) so it works on web too, and so you can override it in tests.

**25. `MediaQuery.of(context)` vs `MediaQuery.sizeOf(context)` — why does it matter?**
`MediaQuery.of` subscribes the widget to the **entire** `MediaQueryData`, so it rebuilds on any change (keyboard insets, text scale, size…). The `.sizeOf`, `.paddingOf`, `.orientationOf` aspect accessors subscribe to just that slice, so the widget rebuilds only when *that* value changes. Use the narrow accessor to avoid needless rebuilds — e.g. a layout that only cares about width shouldn't rebuild when the keyboard opens.

## 🔴 Advanced

**26. When would you drop from `CustomPainter` to a custom `RenderObject`?**
`CustomPainter` only participates in the **paint** phase — it can't influence layout (it paints within the size it's given). Write a custom `RenderObject` (`RenderBox`) when you need custom **layout** (measuring children, non-standard sizing under constraints), custom **hit testing**, multiple children with bespoke positioning, or intrinsic dimensions — things paint alone can't do. It's the most work and least ergonomic, so reserve it for genuinely novel layout/interaction (custom charts, editors, layout algorithms) after `CustomPaint`, `Flow`, and composition fail.

**27. Explain the `Canvas` operations you use in a `CustomPainter` and their cost.**
`canvas.drawPath/drawRect/drawCircle/drawRRect` with a `Paint` (style, color, `strokeWidth`, `shader`, `maskFilter`). Build complex shapes with `Path` (moveTo/lineTo/cubicTo/arcTo/close). Gradients go on `Paint.shader` via `ui.Gradient.linear/radial/sweep` (or `LinearGradient(...).createShader(rect)`). Costs: solid fills are cheap; `MaskFilter` blurs, `saveLayer`, and large paths are expensive on the raster thread. Prefer drawing directly over `saveLayer` when possible.

**28. What does `saveLayer` do and why is it expensive?**
`canvas.saveLayer(bounds, paint)` allocates an **offscreen buffer**, draws subsequent commands into it, then composites that buffer back with the paint's opacity/blend/filter. It's needed for group opacity, blend modes across multiple draws, and some clips. It's costly because it's an extra allocation + render target switch + composite on the raster thread — a frequent source of raster jank. Widgets like `Opacity` and `ShaderMask` use it internally, which is why animating `Opacity` over a big subtree janks (prefer `FadeTransition`/`AnimatedOpacity`, or `opacity` on an image).

**29. How do fragment shaders work in modern Flutter?**
You author a **GLSL fragment shader** (`.frag`), declare it under `flutter: shaders:` in `pubspec.yaml`, load it with `FragmentProgram.fromAsset`, set its uniforms, and use the resulting `FragmentShader` as a `Paint.shader` inside a `CustomPainter` (or via `ShaderMask`). It runs per-pixel on the GPU — great for gradients, noise, ripples, dissolves, and effects too expensive to compute per-pixel in Dart. Uniforms (time, resolution, pointer) let you animate them. Under Impeller shaders are compiled ahead-of-time, which also removes the old "shader compilation jank" on first run.

**30. What is shader compilation jank and how is it addressed?**
On the older Skia backend, a shader used for the first time was compiled **at draw time on the raster thread**, stalling that frame — a visible hitch the first time an effect/animation appeared. Historically mitigated with **SkSL warm-up** (bundling precompiled shaders captured via `--cache-sksl`). The modern fix is **Impeller** (default on iOS and Android), which precompiles its shaders during build, largely eliminating the class of jank.

**31. How do you coordinate multiple animations that must stay in sync?**
Prefer a **single `AnimationController`** as the clock and derive each animation from it with different `Tween`s + `Interval`s/`Curve`s (the staggered pattern). One ticker, one timeline, guaranteed sync, minimal overhead. Reach for multiple controllers only when phases are truly independent (different triggers/durations/lifecycles); then you coordinate via status listeners (`chain` on completion) or `TickerFuture` (`await _c.forward()`). Multiple controllers = multiple tickers = more per-frame cost and desync risk.

**32. How does the `Hero` flight actually work, and how do you customize it?**
On a route push, `HeroController` (installed by `MaterialApp`) finds matching tags on the outgoing and incoming routes, measures both rects, and inserts an **overlay** widget that animates (via a `RectTween` and the route's transition) from source to destination rect, hiding the real widgets during flight. Customize with `flightShuttleBuilder` (control what's drawn mid-flight — e.g. cross-fade), `createRectTween` (arc vs linear path — `MaterialRectArcTween` gives a curved flight), and `placeholderBuilder`. Pitfalls: duplicate tags on one screen throw; heroes need the same tag and should wrap similarly-shaped widgets.

**33. Your list scroll janks only on low-end devices during a fade-in animation. How do you approach it?**
Reproduce in **profile mode on that class of device**, open DevTools Timeline. Determine thread: if the **UI thread** overruns, the animation is rebuilding too much — move to `AnimatedBuilder` with cached `child`, cut work in `build`, ensure item widgets are `const` where possible. If the **raster thread** overruns, suspect `Opacity`/`saveLayer` over large subtrees (switch to `FadeTransition`), unbounded image sizes (add `cacheWidth`), missing `RepaintBoundary` around the animating cell, or shader jank (verify Impeller). Fix the measured bottleneck, then re-measure — don't sprinkle boundaries blindly.

**34. How do you animate between two entirely different layouts (not just a property)?**
Options by complexity: `AnimatedSwitcher` (cross-fade/scale swapping child widgets by key), `AnimatedCrossFade` (between exactly two children with size interpolation), `Hero` (shared elements across routes), or `Flow`/`CustomMultiChildLayout` driven by a controller for bespoke reflow. For implicit multi-property morphs, `AnimatedContainer`/`TweenAnimationBuilder`. When the two states share elements, prefer a shared-element approach so items move rather than fade — it reads as continuity, not replacement.

**35. How do `AnimatedList`/`SliverAnimatedList` handle insertions and removals?**
They animate items in/out by requiring you to keep the list and a `GlobalKey<AnimatedListState>` in sync: call `listKey.currentState!.insertItem(index)` / `removeItem(index, builder)` **alongside** mutating your backing data. On removal you must supply a builder because the data is already gone — the widget needs to know how to paint the departing item during its exit animation. Getting the data and the animated-list calls out of sync causes range errors or ghost items.

**36. When is a custom `RenderObject`'s `performLayout` the right tool, and what must it respect?**
When your sizing/positioning logic can't be expressed by existing layout widgets. In `performLayout` you must: read the incoming `constraints`, lay out each child with `child.layout(childConstraints, parentUsesSize: true)`, position children via their `parentData.offset`, and set your own `size` **within** the constraints (`constraints.constrain(...)`). Respect the constraint contract (constraints down, sizes up, parent sets position) or you get overflow/assertion errors. Also implement `hitTest`, `paint`, and often `computeDryLayout`/intrinsics.

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Implicit animation for one custom value? | `TweenAnimationBuilder`. |
| What drives an explicit animation's time? | `AnimationController` (ticker/vsync). |
| One controller, multiple properties, different timing? | `Interval` curves (staggered). |
| Mixin for one controller? | `SingleTickerProviderStateMixin`. |
| Where do you dispose a controller? | `State.dispose()`. |
| Widget that rebuilds only the animating subtree? | `AnimatedBuilder` (with cached `child`). |
| Shared-element route transition? | `Hero` (same `tag`). |
| Run animation until physics settles? | `animateWith(SpringSimulation(...))`. |
| Cheapest way to repaint a `CustomPainter` per tick? | Pass `repaint: animation`. |
| `shouldRepaint` returns…? | `true` only if paint inputs changed. |
| Group opacity offscreen buffer op? | `canvas.saveLayer`. |
| Isolate animation repaint onto its own layer? | `RepaintBoundary`. |
| Screen size vs parent slot size? | `MediaQuery.sizeOf` vs `LayoutBuilder`. |
| Rebuild only on size change? | `MediaQuery.sizeOf(context)`. |
| iOS/Material auto-switching control? | `.adaptive` constructors. |
| Platform check that also works on web/tests? | `defaultTargetPlatform`. |
| Backend that kills shader-compile jank? | Impeller. |
| Need custom layout, not just paint? | Custom `RenderObject`. |

## Follow-up drills

1. Design a pull-to-refresh with a custom `CustomPainter` indicator whose arc grows with drag distance and spins during load — wire the gesture, controller, and painter.
2. Implement a staggered "cards fly in" onboarding screen using a single `AnimationController` and `Interval` curves; explain how you'd tune the timing.
3. Debug: an `Opacity`-wrapped image gallery janks on scroll only on a 3-year-old Android phone. Walk through your DevTools investigation and the fix.
4. Build a screen that shows a `NavigationRail` on desktop, a bottom nav on phone, and Cupertino tab bar on iOS — responsive *and* adaptive in one widget.
5. Optimize a `CustomPainter` charting 10k points that repaints on every animation tick; get it under the frame budget.
6. Implement a swipe-to-dismiss card stack (Tinder-style) with gesture-driven position and spring settle on release, handing the fling velocity into the simulation.
