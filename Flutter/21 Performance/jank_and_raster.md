# Jank & the Raster Thread (`RepaintBoundary`, Shaders, Impeller)

> Raster-bound jank (high `rasterDuration`) comes from expensive GPU work — `saveLayer` (opacity/clips), big blurs, complex paths, and first-run **shader compilation**; fix it with `RepaintBoundary` isolation, cheaper effects, and Impeller (precompiled shaders) — not with `const`.

## Introduction

Some jank isn't the UI thread's fault — it's the **raster thread** drawing pixels ([09 · rasterization](../09%20Rendering%20Pipeline/rasterization_skia_impeller.md)). This file covers diagnosing raster-bound frames, reducing GPU cost, isolating repaints, and eliminating shader-compilation jank.

## Why this concept exists

Rebuild fixes (`const`/scoping) do nothing for GPU-bound jank. Expensive paints (offscreen buffers, blurs, clips) and one-time shader compilation overrun the raster budget even when the UI thread is fast — a distinct problem needing distinct remedies.

## Real-world analogy

If the UI thread is the **director** deciding the scene, the raster thread is the **film lab developing each frame**. A lab overwhelmed by heavy effects (blurs) or building a custom filter on first use (shader compilation) can't keep up — no amount of faster directing helps; you fix the lab's workload.

## Problem Statement

A screen with a blurred, semi-transparent animated card stutters (especially the first time), while `buildDuration` is low but `rasterDuration` is high. You'll isolate repaints, cut effect cost, and address shader compilation.

## Internal Working

```mermaid
flowchart TD
    High[high rasterDuration] --> Cause{cause}
    Cause --> SaveLayer[saveLayer: Opacity/Clip w/ child -> offscreen buffer]
    Cause --> Blur[BackdropFilter/large blur/complex paths]
    Cause --> Shader[first-run shader compilation (Skia)]
    SaveLayer & Blur --> Fix1[RepaintBoundary + simpler/smaller effects]
    Shader --> Fix2[Impeller (precompiled) / shader warm-up]
```

- **Diagnose**: high `rasterDuration` (vs `buildDuration`) and "Highlight Repaints" showing broad/costly repaints ([profiling_and_frame_budget.md](profiling_and_frame_budget.md)).
- **`saveLayer` cost**: `Opacity`/`ClipRRect`/`ShaderMask` **with a child** allocate an offscreen buffer per frame — expensive. Prefer: animate opacity via a single widget, tint colors on `Paint` (`color.withOpacity`) instead of wrapping, use `ClipRect`/`Clip.hardEdge` when quality allows, or bake effects into images.
- **Blurs/paths**: `BackdropFilter`/large `ImageFilter.blur` and many complex paths are heavy — limit area/size, cache results, reduce blur radius.
- **`RepaintBoundary`**: isolate a frequently-repainting or expensive-static subtree into its own layer so it repaints/caches independently — the key raster/repaint tool ([09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md)). Measure — too many boundaries waste GPU memory/compositing.
- **Shader compilation jank (Skia)**: first use of a shader (gradients/blurs/animations) compiles lazily → one-time stutter. Fixes: **Impeller** (precompiles shaders → no first-run jank), or SkSL shader **warm-up** on Skia ([09 · rasterization](../09%20Rendering%20Pipeline/rasterization_skia_impeller.md)).
- **`shouldRepaint`**: custom painters must return `false`/compare inputs so they don't repaint every frame ([09 · paint_phase](../09%20Rendering%20Pipeline/paint_phase.md)).

## Memory Representation

`saveLayer`/boundaries allocate GPU offscreen buffers/layer textures; too many/large ones pressure GPU memory. Cached boundary layers trade memory for reuse ([09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md)).

## Compiler Behavior

Impeller prepares shaders ahead of time; Skia compiles them at runtime on first use.

## Runtime Behavior

Raster runs on its thread; heavy layers/effects overrun the raster budget; first-run shader compilation (Skia) causes a transient hitch then caches.

## Flutter Engine Behavior

This is the engine's rasterizer. Impeller (default on iOS, expanding) eliminates shader-compilation jank and offers more predictable raster times vs Skia.

## Dart VM Behavior

Not applicable (raster is engine-side C++/GPU).

## Examples

```dart
import 'package:flutter/material.dart';

class RasterDemo extends StatefulWidget {
  const RasterDemo({super.key});
  @override State<RasterDemo> createState() => _RasterDemoState();
}
class _RasterDemoState extends State<RasterDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const _ExpensiveStaticBackground(), // heavy static -> cache it
      // Isolate the animating widget so ONLY it repaints (not the background):
      RepaintBoundary(
        child: RotationTransition(turns: _c, child: const Icon(Icons.refresh, size: 64)),
      ),
    ]);
  }
}
class _ExpensiveStaticBackground extends StatelessWidget {
  const _ExpensiveStaticBackground();
  @override
  Widget build(BuildContext context) => RepaintBoundary( // cache static expensive content
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.teal]),
          ),
        ),
      );
}
```

```text
Run Impeller (avoids shader-compilation jank on supported platforms):
  flutter run --profile   # Impeller is default on iOS; enabling/checking varies by platform/version
Skia shader warm-up (pre-Impeller):
  flutter run --profile --cache-sksl --purge-persistent-cache
  flutter build ... --bundle-sksl-path <captured-file>
```

## Diagrams

```mermaid
flowchart LR
    Anim[animation over complex bg] -->|no boundary| Both[bg repaints too -> raster jank]
    Anim -->|RepaintBoundary| Only[only animation repaints; bg cached]
    FirstRun[first gradient/blur (Skia)] --> Stutter[shader compile stutter]
    Impeller[Impeller] --> Smooth[precompiled -> no first-run stutter]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Using `const`/scoping for raster jank | Wrong thread | Use RepaintBoundary/effects/Impeller |
| Overusing `Opacity`/`saveLayer` | Offscreen buffers per frame | Tint paint / animate opacity / bake images |
| Large `BackdropFilter`/blurs everywhere | Heavy raster | Limit area/radius; cache |
| No boundary around per-frame animation | Neighbors repaint | Wrap animation in `RepaintBoundary` |
| `RepaintBoundary` everywhere | GPU memory/compositing waste | Add only where measured |
| `shouldRepaint => true` (custom painters) | Repaints every frame | Compare inputs / return false |
| Blaming first-run stutter on rebuilds | It's shader compilation | Impeller / SkSL warm-up |

## Best Practices

- **Diagnose raster-bound frames** (`rasterDuration` + Highlight Repaints) before acting.
- **Isolate** frequently/independently repainting or expensive-static subtrees with `RepaintBoundary` (measure; don't overuse).
- **Reduce effect cost**: avoid `saveLayer` where possible (tint paints, animate a single opacity widget), limit blur area/radius, simplify clips/paths, bake static effects into images.
- **Eliminate shader jank** with **Impeller** (or SkSL warm-up on Skia).
- Implement `shouldRepaint` correctly in custom painters.
- Always **verify in profile/release** on a low-end device.

## Performance

Raster budget shares the frame with UI work; raster fixes (boundaries, cheaper effects, Impeller) target GPU time specifically. `const`/rebuild tuning won't help raster-bound jank ([profiling_and_frame_budget.md](profiling_and_frame_budget.md)).

## Advantages / Disadvantages

- **+** Smooth complex visuals/animations; Impeller removes first-run jank; boundaries cache expensive layers.
- **−** GPU-memory cost of layers/boundaries; effect-reduction may compromise visuals; must measure to place boundaries.

## Interview Questions

1. **🟢 What indicates raster-bound jank?** — High `rasterDuration` (with low `buildDuration`) and heavy repaints in "Highlight Repaints."
2. **🟢 What does `RepaintBoundary` do?** — Isolates a subtree into its own layer so it repaints (and caches) independently — the key raster/repaint tool.
3. **🟡 Why is `Opacity` with a child potentially expensive?** — It may use `saveLayer`, allocating an offscreen buffer each frame that the raster thread must composite.
4. **🟡 What causes first-run animation stutter, and the fix?** — Skia's lazy shader compilation; fix with Impeller (precompiled shaders) or SkSL warm-up.
5. **🟡 Why won't `const` fix raster jank?** — `const` reduces build-phase (UI-thread) work; raster jank is GPU-thread cost — different remedy.
6. **🔴 What's the tradeoff of `RepaintBoundary`?** — Each adds a layer (GPU memory + compositing step); overuse hurts — add only where profiling shows benefit.
7. **🔴 How does Impeller change raster performance?** — It precompiles shaders (no first-run compilation jank) and gives more predictable raster times vs Skia.

## Senior Engineer Tips

- First-run-only stutter = shader compilation → Impeller/warm-up, not rebuild tuning.
- Classic win: animation/spinner over a complex background → `RepaintBoundary` around the animation (and often the cached static background).
- Treat opacity/clip/blur as "raster-expensive"; prefer tinting paints and baking static effects; measure GPU memory when adding boundaries.

## Architect Perspective

Raster performance is a distinct discipline from rebuilds: it's about GPU workload and layer strategy. Designing effect-light UIs, deliberate `RepaintBoundary` placement, and adopting Impeller are architectural choices for animation-heavy/visual apps, grounded in the paint/compositing/rasterization internals ([Module 09](../09%20Rendering%20Pipeline/README.md)).

## Summary

- Raster-bound jank (`rasterDuration`) = GPU cost: `saveLayer`/blurs/clips/paths + shader compilation.
- Fix with `RepaintBoundary` isolation, cheaper/baked effects, correct `shouldRepaint`, and Impeller (no shader jank).
- Distinct from rebuild fixes; diagnose then place boundaries by measurement; verify in release.

## Revision Notes

- Diagnose: high `rasterDuration` + Highlight Repaints.
- Costly: `saveLayer` (opacity/clip w/ child), blurs, complex paths; reduce/bake/tint.
- `RepaintBoundary` isolates repaint/caches (costs GPU memory — measure).
- Shader jank (Skia first-run) → Impeller/SkSL warm-up; `shouldRepaint` in painters; verify release/low-end.

## Practice Questions

1. How do you tell raster-bound from UI-bound jank?
2. Why does `Opacity`-with-child cost more than tinting a paint?
3. What fixes first-run animation stutter?

## Coding Questions

1. Isolate a spinner over a complex background with `RepaintBoundary`; verify with Highlight Repaints.
2. Replace an `Opacity` wrapper with paint tinting to avoid `saveLayer`.
3. Reduce a `BackdropFilter`'s raster cost (area/radius/caching) and measure `rasterDuration`.

## Mini Project

**Raster jank fix (Flutter):** Take an animated, blurred, semi-transparent card over a heavy background; profile to confirm raster-bound jank; apply `RepaintBoundary` isolation + effect reduction (+ note Impeller for shader jank). Capture `rasterDuration` before/after. Acceptance: raster-bound confirmed; targeted raster fixes; measurable `rasterDuration` improvement; runs in release.
