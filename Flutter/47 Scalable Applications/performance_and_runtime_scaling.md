# Performance & Runtime Scaling

> As features, data, and users grow, the **runtime** dimension degrades in predictable ways: **startup** slows (more init work + bigger app), **memory** climbs (more state/caches/images/features resident), and the **frame budget** (~16ms at 60fps / ~8ms at 120fps) gets blown (bigger lists, more rebuilds, heavier screens). Scaling runtime means enforcing a **performance budget** (startup/memory/frame targets), **deferring work** (lazy init, deferred/route-based loading, on-demand feature loading), keeping the **frame budget** (virtualized lists, scoped rebuilds, const/repaint boundaries), and **profiling continuously** — so the app stays fast at 500 screens as it was at 5.

## Introduction

This file covers keeping runtime healthy under growth: the performance budget, deferring startup/memory/loading work, protecting the frame budget at scale, and continuous profiling. It applies the performance techniques of [Module 21](../21%20Performance/README.md) to the specific pressures of a *large, growing* app.

## Why this concept exists

Individual optimizations aren't enough at scale — growth *systematically* erodes startup, memory, and frames unless you set budgets and defer work by default. Without a budget + deferral strategy, each new feature adds a little startup time and memory until the app is slow and bloated, with no single culprit. Runtime scaling is about **structural** performance, not one-off fixes.

## Real-world analogy

A growing app is like a **car accumulating cargo**: add enough and acceleration (startup) suffers, fuel/space (memory) fills, and cornering (frame budget) degrades — gradually, invisibly. The fix is a **weight budget** (limits + weigh-ins = profiling), **only carrying what you need right now** (deferred/lazy loading), and **not loading the whole warehouse at the depot** (don't init every feature at startup). You monitor total weight continuously, not after it won't move.

## Internal Working

```mermaid
flowchart TD
    Growth[more features/data/users] --> Startup[startup slows]
    Growth --> Memory[memory climbs]
    Growth --> Frame[frame budget blown]
    Startup --> LazyInit[defer init: lazy DI, minimal main(), deferred loading]
    Memory --> Evict[bound caches, dispose, evict, load on demand]
    Frame --> FrameLevers[virtualized lists, scoped rebuilds, const, repaint boundaries]
    Budget[performance budget + continuous profiling] --> All[gate all three]
```

- **Set a performance budget** (targets you don't exceed): e.g., **cold start < X s**, **memory < Y MB** on target devices, **frame time ≤ 16ms (60fps)/8ms (120fps)** with jank < Z%, **app size < W MB**. Measure against it in CI/monitoring; a feature that blows the budget must be optimized/deferred ([Module 21](../21%20Performance/README.md)/[Module 52](../52%20Monitoring/README.md)).
- **Startup scaling** (init grows with features):
  - Keep **`main()` minimal**; **lazy-register DI** (create on first use, not at boot — [Module 14](../14%20Dependency%20Injection/README.md)); defer non-critical init (analytics, prefetch) to after first frame.
  - **Deferred/route-based loading**: don't build/load every feature upfront; load a feature's code/state **when navigated to** (lazy routes; Flutter web **deferred imports**/`--split-debug-info`; on-demand feature loading in modular apps).
  - Reduce **app size** (tree-shaking, `--obfuscate --split-debug-info`, split assets, app thinning — [Module 21](../21%20Performance/README.md)/[Module 51](../51%20Deployment/README.md)).
- **Memory scaling** (more state/caches resident):
  - **Bound caches** (TTL/LRU/size — [Module 34](../34%20File%20Handling/README.md)); **dispose** controllers/subscriptions/streams; **evict** off-screen feature state; use **`cached_network_image`**/resized images (image memory is a top offender).
  - **Load features/state on demand** and release when leaving; don't keep every feature's data resident.
  - Watch for **leaks** (undisposed listeners, retained contexts) — they compound at scale ([Module 52](../52%20Monitoring/README.md)).
- **Frame-budget scaling** (bigger/heavier UI):
  - **Virtualize long lists** (`ListView.builder`/slivers — never build all items); **scoped rebuilds** (select slices — [Module 43](../43%20MVVM/README.md)); **`const` widgets** + **`RepaintBoundary`**; avoid expensive work in `build`; offload heavy compute to **isolates** ([Module 02](../02%20Advanced%20Dart/README.md)).
  - Keep per-screen widget trees shallow; avoid whole-page rebuilds on small changes.
- **Profile continuously** (not once): DevTools (timeline, memory, CPU), performance overlay, integration/perf tests in CI, and **production monitoring** (startup/frame/crash metrics — [Module 52](../52%20Monitoring/README.md)). Catch regressions **as features land**, keyed to the budget.
- **Deferral by default (the scaling mindset)**: at scale, the default answer to "when to load/init X?" is **"as late as possible / on demand"** — because *every* feature adding a little upfront cost is what kills large apps.
- **Right-sizing**: a small app rarely needs budgets/deferred loading; a large one needs all of it. Introduce as the runtime dimension shows pressure ([scaling_dimensions.md](scaling_dimensions.md)).

## Memory Representation

The budget is a set of measured targets; deferral means feature code/state isn't resident until needed; bounded caches cap resident memory; disposal frees off-screen state. The invariant: resident work ≈ what's currently on screen/needed, not the whole app.

## Compiler Behavior

Tree-shaking + deferred imports (web) + obfuscation/split-debug-info reduce shipped/loaded code; `const` enables widget canonicalization. Build tooling supports app-size + deferred-loading levers.

## Runtime Behavior

Lazy init → faster cold start; on-demand loading → lower baseline memory + faster start; virtualized lists + scoped rebuilds + isolates → frames stay within budget; bounded caches + disposal → stable memory. Without these, all three degrade with growth.

## Flutter Engine Behavior

Frame-budget levers reduce build/layout/paint/raster work per frame ([Module 09](../09%20Rendering%20Pipeline/README.md)); virtualization limits widget/element creation; repaint boundaries isolate repaints; the raster thread stays within budget.

## Dart VM Behavior

Isolates offload heavy compute off the UI isolate; bounded memory reduces GC pressure; deferred loading defers code compilation/loading. Startup benefits from minimal boot-time work.

## Examples

```dart
// Startup: minimal main() + lazy DI + defer non-critical work to after first frame
void main() {
  final di = GetIt.instance;
  registerCoreLazily(di);                 // lazy singletons: created on first use, not at boot
  runApp(const App());
}
// After first frame, kick off non-critical init (analytics/prefetch) — off the startup path.
WidgetsBinding.instance.addPostFrameCallback((_) => initNonCritical());

// Deferred/route-based feature loading (don't build every feature upfront)
GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()); // built only when navigated
// (Flutter web: deferred import of a heavy feature library, loaded on first use.)

// Frame budget: virtualized list + scoped rebuild + const
ListView.builder(                          // builds only visible items (virtualized)
  itemCount: items.length,
  itemBuilder: (_, i) => const _Row(),     // const where possible
);
Selector<FeedVm, int>(                      // scoped rebuild (Module 43)
  selector: (_, vm) => vm.unreadCount,
  builder: (_, count, __) => Badge(count),
);

// Memory: bounded cache + dispose
final imageCache = LruCache(maxBytes: 100 << 20);   // bound it
@override void dispose() { _sub.cancel(); _controller.dispose(); super.dispose(); } // release
```

## Diagrams

```mermaid
flowchart LR
    Budget[performance budget (startup/memory/frame/size)] --> Gate[CI + monitoring gate]
    Defer[defer/lazy: init, loading, on-demand features] --> Startup2[fast start + low baseline memory]
    FrameLevers[virtualize + scope + const + isolate] --> Frames[frames within budget]
    Profile[continuous profiling] --> Catch[catch regressions as features land]
```

## Common Mistakes

| Mistake | Why it degrades at scale | Fix |
|---------|-------------------------|-----|
| Eager-initializing everything at boot | Slow cold start grows per feature | Lazy DI + defer non-critical + on-demand loading |
| Building all list items | Memory/jank on long lists | Virtualize (`.builder`/slivers) |
| Whole-page rebuilds | Frame budget blown | Scoped rebuilds + const + repaint boundaries |
| Unbounded caches / no disposal | Memory climbs + leaks | Bound caches (TTL/LRU) + dispose |
| Keeping all feature state resident | Baseline memory bloat | Load on demand; evict off-screen |
| Heavy compute in build/UI isolate | Jank | Offload to isolates |
| Profiling only once (or never) | Regressions slip in | Continuous profiling + CI/monitoring vs budget |
| No performance budget | No guardrail; gradual rot | Set + enforce startup/memory/frame/size targets |

## Best Practices

- Set and **enforce a performance budget** (cold start, memory, frame time/jank, app size) via **CI + production monitoring**; block features that blow it.
- **Defer by default**: minimal `main()`, **lazy DI**, post-first-frame non-critical init, **route-based/on-demand** feature + code loading; reduce app size.
- Protect the **frame budget**: **virtualize lists**, **scope rebuilds**, `const` + `RepaintBoundary`, offload heavy compute to **isolates**; keep resident work ≈ what's on screen.
- **Bound caches + dispose** everything (controllers/subscriptions/images); **profile continuously** and catch regressions as features land; **right-size** to the app's stage.

## Performance

This whole file *is* the performance discipline for scale: budgets prevent gradual rot, deferral keeps startup/memory low as features multiply, frame levers keep 60/120fps under heavier UI, and continuous profiling catches regressions. The compounding win is **flat performance as the app grows**, instead of linear degradation.

## Advantages / Disadvantages

- **+** Stable startup/memory/frames as features grow, regression detection, smaller/faster app, sustainable runtime scaling.
- **−** Budget + monitoring setup, deferral/laziness complexity (loading states, on-demand wiring), disposal discipline, profiling effort; overkill for tiny apps.

## Interview Questions

1. **🟢 How does growth degrade runtime, and along which axes?** — Startup slows (more init/bigger app), memory climbs (more resident state/caches), and the frame budget is blown (bigger lists/more rebuilds).
2. **🟢 What is a performance budget?** — Enforced targets (cold start, memory, frame time/jank, app size) measured in CI + monitoring; features that exceed them must be optimized or deferred.
3. **🟡 How do you keep startup fast as features multiply?** — Minimal `main()`, lazy DI, defer non-critical init to after first frame, and route-based/on-demand feature + code loading (deferred imports on web).
4. **🟡 How do you protect the frame budget at scale?** — Virtualize lists, scope rebuilds, `const`/`RepaintBoundary`, and offload heavy compute to isolates — keep per-frame work small.
5. **🟡 How do you keep memory bounded?** — Bound caches (TTL/LRU/size), dispose controllers/subscriptions, evict off-screen feature state, resize/cache images, and watch for leaks.
6. **🔴 Why is "defer by default" the scaling mindset?** — Because every feature adding a little upfront init/memory is what kills large apps; loading/initializing on demand keeps baseline cost flat.
7. **🔴 Why profile continuously rather than once?** — Regressions accumulate as features land; continuous profiling (DevTools + CI perf tests + production monitoring) catches them against the budget.

## Senior Engineer Tips

- Set a performance budget early and wire it into CI + monitoring; without a guardrail, large apps rot gradually with no single culprit to blame.
- Make deferral the default — lazy DI, on-demand feature loading, post-first-frame init; eager everything-at-boot is the number-one startup killer at scale.
- Treat unbounded caches, missing disposal, and un-virtualized lists as bugs; at scale they're the memory/jank offenders that compound silently.

## Architect Perspective

Runtime scaling is structural performance: a budget defines the guardrails, deferral keeps baseline cost flat as features grow, frame/memory levers protect responsiveness under heavier UI/data, and continuous profiling enforces it all. Combined with modular on-demand loading and monitoring, it lets an app grow to hundreds of features while staying as fast as it was small. The architect's job is to institutionalize the budget + deferral defaults so performance is a property of the system, not a heroic one-off — proportional to the app's actual runtime pressure ([Module 21](../21%20Performance/README.md), [Module 52](../52%20Monitoring/README.md), [scaling_dimensions.md](scaling_dimensions.md)).

## Summary

- Growth degrades startup, memory, and frames unless managed structurally: set + enforce a performance budget (CI + monitoring).
- Defer by default (lazy DI, on-demand feature/code loading, post-first-frame init); protect the frame budget (virtualize, scope, const, isolates); bound caches + dispose.
- Profile continuously to catch regressions as features land; right-size to the app's runtime pressure.

## Revision Notes

- Budget: cold start / memory / frame time (16ms@60 / 8ms@120) + jank% / app size — enforce via CI + monitoring; block over-budget features.
- Startup: minimal `main()`, lazy DI, post-first-frame non-critical init, route-based/on-demand + deferred imports (web), reduce app size.
- Memory: bound caches (TTL/LRU), dispose subs/controllers, evict off-screen, resized/cached images, no leaks. Frame: virtualize lists, scope rebuilds, const + RepaintBoundary, isolates.
- Profile continuously (DevTools + CI perf + monitoring); defer-by-default mindset; right-size.

## Practice Questions

1. What are the three runtime axes that degrade with growth, and their levers?
2. Why is "defer by default" essential at scale?
3. How do you enforce that a new feature doesn't blow the performance budget?

## Coding Questions

1. Make `main()` minimal + lazy DI + post-first-frame non-critical init.
2. Convert an eager list + whole-page rebuild to virtualized + scoped.
3. Bound a cache + add disposal, and add a CI perf check against the budget.

## Mini Project

**Runtime scaling plan (Flutter):** For a growing app, define a performance budget (cold start/memory/frame/app-size targets), implement deferral (minimal `main()` + lazy DI + post-first-frame init + route-based/on-demand feature loading), frame-budget levers (virtualized lists, scoped rebuilds, const/repaint boundaries, isolate for a heavy task), and memory hygiene (bounded caches + disposal), plus a continuous-profiling/CI-gate hook. Acceptance: enforced budget (CI + monitoring); deferral-by-default startup + loading; frame-budget levers applied; bounded caches + disposal; continuous profiling; right-sized to runtime pressure.
