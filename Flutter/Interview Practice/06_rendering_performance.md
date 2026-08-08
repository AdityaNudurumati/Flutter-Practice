# Rendering Pipeline & Performance — Interview Questions

> How Flutter turns widgets into pixels each frame, and how to keep that under the frame budget. Depth in [09 Rendering Pipeline](../09%20Rendering%20Pipeline/README.md) and [21 Performance](../21%20Performance/README.md).

This topic tests whether you understand what actually happens per frame (build → layout → paint → composite → rasterize), where jank comes from (UI vs raster thread), and whether you optimize by *measuring* rather than by sprinkling `const` and `RepaintBoundary` everywhere. Senior interviews live here.

## 🟢 Basic

**1. What are the phases of a single frame in Flutter?**
For a frame Flutter runs, in order: **build** (run `build()` on dirty widgets, reconcile the Element tree), **layout** (RenderObjects size/position themselves under parent constraints — constraints go down, sizes come up), **paint** (RenderObjects emit paint commands into layers), **composite** (assemble the layer tree into a scene), and **rasterize** (the raster thread turns the scene into GPU commands and pixels). Build/layout/paint/composite run on the UI thread; rasterize runs on the raster thread. Understanding this order tells you *which* work to cut when a frame is slow.

**2. What triggers a new frame? What is vsync?**
The OS display emits a **vsync** signal (~every 16.6 ms at 60 Hz). Flutter's `SchedulerBinding` registers a frame callback with the engine, which is driven by vsync — this is Flutter's analogue of Android's **Choreographer**. When something marks the tree dirty (`setState`, animation tick, `markNeedsBuild/Layout/Paint`), Flutter schedules a frame; on the next vsync it runs the pipeline. Nothing renders "as fast as possible" — work is paced to the display refresh so you don't waste effort producing frames the screen can't show.

**3. What's the frame budget and why 16 ms?**
At 60 Hz you get one frame every ~16.6 ms, so *all* UI-thread work (build+layout+paint+composite) for that frame must finish inside that window, and the raster thread must also finish its part. On a 120 Hz display the budget halves to ~8.3 ms. Blow the budget and the previous frame stays on screen an extra refresh — that dropped frame is **jank**. The budget is shared, not per-phase.

**4. What is jank?**
Jank is a visibly dropped or late frame — a stutter during scrolling or animation. It happens when a frame can't be produced within the budget, so the display repeats the old frame. It comes in two flavors: **build/UI jank** (too much Dart work on the UI thread) and **raster jank** (the GPU/raster thread takes too long to rasterize the scene). Fixing them requires opposite tactics, so you must first identify which one you have.

**5. What is the difference between the UI thread and the raster thread?**
The **UI (Dart) thread** runs your Dart code: build, layout, paint (recording), and composite. The **raster thread** (historically "GPU thread") takes the layer tree and issues actual draw calls to the GPU. They run in parallel and pipeline across frames. A frame is only smooth if *both* finish their share in time. This is why "my code is fast but it still janks" is usually raster-side (expensive shaders, huge images, saveLayer).

**6. What is `const` on a widget and why does it help performance?**
A `const` widget is canonicalized at compile time — the same instance is reused. During reconciliation, when Flutter compares the new widget with the old, `const` widgets short-circuit via `identical()`: same instance ⇒ the Element and its subtree are not rebuilt. So `const` widgets skip build work for their whole subtree. Cheap and effective; enable `prefer_const_constructors` lint.

**7. What is `ListView.builder` and why prefer it over `ListView(children: [...])`?**
`ListView(children: [...])` builds *all* children eagerly, even off-screen ones — O(n) work and memory up front. `ListView.builder` is lazy: it builds only the items in (and near) the viewport via `itemBuilder`, recycling as you scroll. For long or infinite lists this is the difference between a smooth scroll and an out-of-memory / long-build-jank list. Use `.builder` whenever the item count is large or unknown.

**8. What is `RepaintBoundary` at a high level?**
`RepaintBoundary` inserts a separate compositing layer so its subtree paints independently. When something *outside* the boundary repaints, the boundary's cached layer is reused instead of repainting its subtree — and vice versa. It isolates repaint work. It's a tool for *paint*-phase cost, not build cost, and it's not free (extra layer + memory), so it must be justified.

**9. What is a key and how does it relate to performance?**
Keys control how Flutter matches new widgets to existing Elements/State during reconciliation. When a list of same-type widgets reorders, keys let Flutter *reuse* the right Elements and their State instead of tearing down and rebuilding — preserving State and avoiding wasted rebuild/layout. Use `ValueKey`/`ObjectKey` on items that reorder or get inserted/removed in the middle of a list.

**10. What tool do you use to diagnose performance problems?**
**Flutter DevTools** — specifically the Performance/Timeline view (per-frame flame chart split into UI and raster), the Frame chart (bars colored by which thread overran), the CPU profiler, the widget **rebuild counter**, and the memory view. Always profile in **profile mode** on a **real device**, never debug mode (debug adds asserts/overhead and is not representative).

**11. Why must you profile in profile mode, not debug?**
Debug mode runs unoptimized JIT code with assertions, service extensions, and no AOT compilation, so timings are meaningless (often 5–10x slower). **Profile mode** is AOT-compiled like release but keeps tracing/DevTools hooks, so numbers reflect reality while remaining observable. Release mode has no tracing at all. Rule: profile in profile mode on a physical device representative of your low-end target.

**12. What does "measure before optimizing" mean here?**
Don't guess. Reproduce the jank, capture a timeline, and read whether frames overrun on the UI thread or the raster thread — then optimize *that*. Blindly adding `const`, `RepaintBoundary`, or micro-tweaks often adds complexity and memory for no measured gain, and can even make things worse. Optimization without a before/after measurement is superstition.

## 🟡 Intermediate

**13. How do you tell build jank from raster jank in DevTools?**
In the Frame chart each frame is a bar split into a **blue/UI** portion and a **green/raster** portion. If the UI portion is over budget, it's build/layout/paint jank — look at your Dart work (expensive `build()`, big layouts, synchronous work on the UI thread). If the raster portion is over budget, it's raster jank — expensive painting, `saveLayer`, big/unscaled images, or **shader compilation**. Enable the performance overlay to see the two graphs live.

**14. When does `RepaintBoundary` help, and when does it hurt?**
It **helps** when a small, frequently-repainting subtree (an animation, a progress spinner, a blinking cursor) sits inside a larger static one — the boundary stops the animation from dirtying the whole screen's paint, and stops screen repaints from redrawing the animation. It **hurts** when applied indiscriminately: each boundary is a new layer costing memory and a composite step, and wrapping cheap or rarely-painting widgets just adds overhead. Use DevTools' "Highlight repaints" to find what actually repaints, then wrap only that. `ListView` already inserts RepaintBoundaries around its children, so don't double-wrap them.

**15. Why doesn't `const` help if I pass a non-const argument?**
`const` requires *all* constructor arguments to be compile-time constants. The moment you pass a runtime value (a variable, a value from state, a closure, `MediaQuery.of(context)`), the constructor can't be `const`, so a fresh instance is created every build and the subtree can rebuild. That's why hoisting truly-static subtrees into `const` (or into fields) matters: you're preserving the `identical()` short-circuit. A closure or `Theme.of(context)` in the args silently defeats it.

**16. Compare `itemExtent`, `prototypeItem`, and neither in a scroll list.**

| Approach | What it does | When |
|---|---|---|
| `itemExtent: h` | Fixes each item's main-axis size, so the list can compute scroll positions and off-screen extent *without laying out items* | All items same height — fastest |
| `prototypeItem` | Lays out one prototype to derive the extent, then treats items as fixed | Uniform but height not known as a literal |
| Neither | List must lay out items to know their size — more layout work, slower scroll-to and extent math | Genuinely variable heights |

Giving the list a known extent avoids per-item layout during fling and makes scrollbar/`jumpTo` math cheap.

**17. What is `cacheExtent` and how does tuning it cut jank?**
`cacheExtent` is how many logical pixels *beyond* the visible viewport the list keeps built/painted (default ~250 px). A larger cacheExtent builds upcoming items earlier, so they're ready before they scroll in — smoothing fast flings — at the cost of more memory and build work off-screen. Too large wastes memory and can *cause* build jank; too small causes items to pop in / build late at the viewport edge. Tune it against a measured fling, don't max it out.

**18. My whole screen rebuilds on every tick. How do you stop that?**
Narrow the rebuild scope:
- **Split widgets** so `setState`/state changes live in the smallest subtree that actually changes; extract the static parts into `const` siblings.
- Use a **selector** (`Selector` in Provider, `select` in Riverpod, `context.select`, `BlocSelector`) so a widget rebuilds only when the specific slice it reads changes.
- For animations, use `AnimatedBuilder`/`ValueListenableBuilder` with a `child:` argument so only the animated part rebuilds and the static `child` is passed through untouched.
- Verify with the **rebuild counter** that the count actually dropped.

**19. Why is `AnimatedBuilder`'s `child` parameter a performance feature?**
The `builder` runs every animation frame, but anything you pass as `child` is built **once** and handed into the builder as an already-built widget. So you keep the expensive static subtree out of the per-frame rebuild and only rebuild the tiny animated wrapper. Same pattern for `ValueListenableBuilder` and `TweenAnimationBuilder`. Forgetting it means rebuilding the whole subtree 60–120 times a second.

**20. What is shader compilation jank?**
The first time a particular shader is needed (a gradient, a specific `BackdropFilter`, some `Path` effects), the engine compiles it *on the raster thread*, mid-frame — a one-time but very visible stutter, classically on the first run of an animation. It's raster jank you can't fix with Dart optimizations. Historically mitigated with **SkSL warm-up** (bundling precompiled shaders captured via `--cache-sksl`); the modern fix is **Impeller**.

**21. What is Impeller and how does it address shader jank?**
Impeller is Flutter's rendering engine that replaces the runtime Skia shader-compilation path. It **precompiles a fixed set of shaders at build time** (offline), so there's no on-the-fly shader compilation during animation — killing shader-compilation jank by design. It's the default on iOS and is the default/rolling out on Android. With Impeller the whole SkSL warm-up workaround becomes unnecessary.

**22. How does Flutter cache images and why does that matter?**
Decoded images live in `ImageCache` (via `PaintingBinding.instance.imageCache`), keyed by provider, with limits on count (default 1000) and bytes (default ~100 MB). Re-using the same `ImageProvider` serves a decoded bitmap instead of re-decoding/re-downloading. The killer detail: images are cached at their **decoded** resolution, so decoding a 4000×3000 photo to show a 100×100 thumbnail wastes huge memory — use `cacheWidth`/`cacheHeight` (or `ResizeImage`) to decode at display size.

**23. How do you reduce app (binary) size?**
Build with `--split-per-abi` (or App Bundle) so each device downloads only its ABI; use `--obfuscate --split-debug-info` for release; run `flutter build --analyze-size` to find the heaviest assets/packages; compress/right-size images and prefer vector/`WebP`; drop unused fonts/locales and unused dependencies; and use **deferred loading** to split rarely-used features out of the initial download. Tree-shaking of icon fonts happens automatically in release.

**24. What is deferred loading and when do you use it?**
`import '...' deferred as x;` plus `await x.loadLibrary();` splits a library into a chunk loaded on demand instead of at startup. It shrinks the initial download / startup cost for features most users never open (an admin panel, a heavy report/PDF module). It's most impactful on **Flutter Web** (real network chunks); on mobile the benefit is smaller. The trade-off is an async load point you must handle in the UI.

## 🔴 Advanced

**25. Walk through exactly what happens between `setState` and pixels on screen.**
`setState` calls `Element.markNeedsBuild`, adding the element to the dirty list and calling `scheduleFrame` on the `SchedulerBinding`. On the next **vsync**, `WidgetsBinding.drawFrame` runs: (1) **build** — `buildScope` rebuilds dirty elements, reconciling widgets against the element tree; (2) **layout** — `flushLayout` visits `markNeedsLayout` RenderObjects, passing constraints down and receiving sizes up; (3) **paint** — `flushPaint` records paint ops into the layer tree for `markNeedsPaint` objects; (4) **compositing** — the layer tree is flattened and a `Scene` is built via `SceneBuilder`; (5) **semantics** flush; then the scene is handed to the engine, and the **raster thread** rasterizes it to the GPU. Relayout boundaries and repaint boundaries limit how far steps 2 and 3 propagate.

**26. What are relayout boundaries and how do they bound layout cost?**
A RenderObject is a **relayout boundary** when its size can't be affected by its children's changes — this holds when it's given **tight constraints**, when `parentUsesSize` is false, or when `sizedByParent` is true. When a child calls `markNeedsLayout`, dirtiness propagates *up* only until it hits a relayout boundary, so layout re-runs on that bounded subtree rather than the whole tree. That's why tightly-constraining a subtree (e.g. a fixed-size box) is a real perf lever: it caps how much layout a deep change can trigger.

**27. Why does `Opacity` (or `ClipRRect`/`saveLayer`) cause raster jank, and what are the alternatives?**
`Opacity`, non-trivial clips, `ShaderMask`, and `BackdropFilter` force the engine to allocate an **offscreen buffer** via `saveLayer` — render the subtree into it, then composite — which is expensive on the raster thread, especially animated. Alternatives: use `AnimatedOpacity` only where needed; for a fading image use `FadeInImage`; prefer `Container(color:)` over `Opacity` on a color; use `clipBehavior: Clip.hardEdge` instead of anti-aliased clips when acceptable; and for a whole-widget fade, `Opacity` on a `RepaintBoundary`'d subtree so the offscreen is at least cached. Watch the raster line in the overlay to confirm.

**28. Where do `RepaintBoundary`s already exist for free, and why does that change your strategy?**
Flutter auto-inserts `RepaintBoundary`s in several spots — around each `ListView`/`Scrollable` child, in `TabBarView` pages, and around some transitions — precisely because scrolling content constantly repaints and must be isolated from the static frame. So you rarely need to wrap list items yourself (double-wrapping wastes layers). Your job is to add boundaries where the *framework can't know* your intent: a hand-rolled animation inside a static page, a `CustomPaint` that repaints often, a video/canvas surface.

**29. How do you diagnose "the UI thread is fine but frames still drop"?**
That's raster-thread bound. In the timeline, the raster track overruns while the UI track is comfortable. Usual suspects: shader compilation (first-run stutter → check with `--trace-skia`/switch to Impeller), too many `saveLayer`s (Opacity/clip/blur), large unscaled images decoding/uploading, an unbounded number of layers, or expensive `CustomPainter` paint. DevTools' **Raster Stats** shows per-layer rasterization cost and lets you spot the one layer eating the budget. Fix the layer, not the Dart.

**30. How does `RepaintBoundary` interact with the `debugRepaintRainbowEnabled` and profiling flags?**
`debugRepaintRainbowEnabled = true` recolors each layer's border on every repaint, so a region that flashes new colors constantly is repainting every frame — that's your candidate to wrap (or to investigate why it repaints). Pair it with the rebuild counter (build-phase repaint cause) and Raster Stats (paint cost). The workflow: rainbow to find *what* repaints → decide if a boundary isolates it → measure raster time before/after. Adding a boundary that doesn't reduce measured repaint area is pure overhead.

**31. What causes memory growth / OOM in a Flutter app and how do you find it?**
Common causes: unbounded image cache from full-res decodes (fix with `cacheWidth`), retained large objects via un-cancelled `StreamSubscription`s / `AnimationController`s / `Timer`s not disposed, `GlobalKey` misuse holding subtrees, and caching lists that never evict. Use DevTools **Memory** view: watch the heap over an interaction, take snapshots, diff allocations, and look for classes whose instance count only grows. The `dispose()` audit (every controller/subscription cancelled) fixes most leaks. Set `imageCache.maximumSizeBytes` down on low-RAM targets.

**32. When should you move work off the UI thread, and how?**
Move CPU-heavy synchronous work (JSON parsing of large payloads, image processing, crypto, parsing/compression) off the UI thread when it would exceed the build budget. Use `compute()` for a one-shot, or `Isolate.run` (Dart 2.19+) / a long-lived isolate with `SendPort` for repeated work. Note isolates don't share memory, so you pay serialization cost — only worth it above a threshold you should *measure*. `async/await` alone does **not** help here: it doesn't add parallelism, so a long synchronous computation inside an `await`ed function still blocks the UI thread.

**33. How do you optimize a `CustomPainter` that repaints during animation?**
Implement `shouldRepaint` to return `false` when inputs are unchanged (a wrong `shouldRepaint` forces repaint every frame). Isolate the painter behind a `RepaintBoundary` so its repaints don't dirty siblings. Drive it with a `Listenable` passed to `CustomPaint(painter: ...)` / repaint arg so only the paint runs, not a widget rebuild. Avoid allocating `Paint`/`Path` objects inside `paint()` — hoist them to fields. Minimize `saveLayer`, and cache static geometry (e.g. a `Picture` recorded once) if only a transform changes.

**34. Explain the pipeline's back-pressure: what happens if the raster thread falls behind the UI thread?**
The two threads pipeline: the UI thread produces a layer tree for frame N while the raster thread rasterizes frame N-1. If the raster thread consistently takes longer than the budget, produced frames queue and the engine throttles frame scheduling — so even a fast UI thread can't help, and you see sustained jank tied to raster cost. This is why raster-bound problems (shaders, saveLayer, image upload) feel like "everything is slow" and can't be profiled away on the Dart side. The fix must reduce raster work or precompile shaders (Impeller).

**35. Give a principled optimization workflow for a janky scrolling screen.**
1) Reproduce on a **real low-end device in profile mode**. 2) Capture a timeline while scrolling; read UI vs raster split. 3) If **UI-bound**: check rebuild counts (selectors/`const`/split widgets), ensure `ListView.builder` with `itemExtent`/`prototypeItem`, tune `cacheExtent`, move heavy parsing to an isolate. 4) If **raster-bound**: find the costly layer in Raster Stats, remove `Opacity`/clip/`saveLayer`, decode images at display size, confirm Impeller is on. 5) **Re-measure** and keep only changes with a proven before/after win. 6) Add a regression guard if possible (e.g. a golden/perf test). The discipline — measure, change one thing, re-measure — is the actual answer interviewers want.

**36. `const` vs keys vs `RepaintBoundary` — which phase does each optimize?**

| Tool | Phase it saves | Mechanism |
|---|---|---|
| `const` widgets | **Build** | `identical()` short-circuit skips rebuild of unchanged subtree |
| Keys | **Build/layout** | Correct element+state reuse across reorders, avoids teardown/rebuild |
| Selectors | **Build** | Rebuild only on the specific state slice that changed |
| `itemExtent`/`cacheExtent` | **Layout** | Skip per-item layout / control off-screen build volume |
| `RepaintBoundary` | **Paint/composite** | Isolate a subtree's layer so repaints don't cascade |
| Impeller / precompiled shaders | **Rasterize** | No runtime shader compilation on the raster thread |

Knowing *which phase* a tool targets is what stops you from applying `const` to a raster problem.

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Frame pipeline order? | build → layout → paint → composite → rasterize |
| Which phases on UI thread? | build, layout, paint(record), composite |
| Which on raster thread? | rasterize (draw calls to GPU) |
| 60 Hz budget? | ~16.6 ms; 120 Hz ~8.3 ms — shared across all work |
| Flutter's Choreographer analogue? | `SchedulerBinding` + engine vsync frame callback |
| Two kinds of jank? | UI/build jank vs raster jank |
| Why `const` helps? | `identical()` short-circuit skips subtree rebuild |
| `ListView` vs `.builder`? | eager (all children) vs lazy (viewport only) |
| `itemExtent` for? | fixed item size → skip per-item layout |
| `cacheExtent` for? | pixels built beyond viewport to smooth flings |
| When RepaintBoundary hurts? | over-wrapping cheap/static widgets → extra layers |
| Shader jank fix? | Impeller (precompiled shaders) / SkSL warm-up |
| Big image, tiny slot fix? | `cacheWidth`/`cacheHeight` / `ResizeImage` |
| Profile in which mode? | profile mode, real device, never debug |
| Reduce initial download? | deferred loading + `--split-per-abi`/App Bundle |
| Heavy JSON parse blocks UI — fix? | `compute`/`Isolate.run`, not just `await` |
| DevTools for repaints? | Highlight repaints / repaint rainbow + Raster Stats |
| `AnimatedBuilder` child arg? | build static subtree once, skip per-frame rebuild |

## Follow-up drills

1. **Optimize** a 60-item feed that janks on fling: given a timeline showing raster overrun, list the exact changes you'd make and how you'd verify each.
2. **Debug this scenario:** an animation stutters *only the first time* it plays, then is smooth. Name the cause, prove it in DevTools, and give two fixes.
3. **Design** a rebuild strategy for a dashboard where one card updates every second but 20 others are static — minimize rebuilds and justify each tool.
4. **Explain** to a mid-level engineer when adding `RepaintBoundary` makes things *worse*, with a concrete example.
5. **Optimize** app startup and download size for a feature-heavy app where 70% of users only use the home tab.
6. **Debug** an OOM that only reproduces after scrolling an image-heavy gallery for a minute — outline your DevTools memory workflow end to end.
