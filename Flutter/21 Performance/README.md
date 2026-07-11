# 21 · Performance

## Introduction

Performance is measured, not guessed. This module turns the rendering-pipeline internals ([Module 09](../09%20Rendering%20Pipeline/README.md)) into practical optimization: profiling, killing rebuild/raster jank, taming memory/leaks, fast lists, and quick startup/small size — all driven by DevTools data.

## Why this module exists

Jank, memory bloat, and slow startup drive users away and fail reviews. The skill isn't "add tricks everywhere" — it's **diagnose the actual bottleneck by phase/thread**, fix that, and verify. This module teaches that disciplined loop.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [profiling_and_frame_budget.md](profiling_and_frame_budget.md) | DevTools, frame budget, diagnosing by phase/thread | 🔴 |
| 2 | [rebuild_optimization.md](rebuild_optimization.md) | `const`, scoping, selectors (build phase) | 🔵 |
| 3 | [jank_and_raster.md](jank_and_raster.md) | Raster thread, `RepaintBoundary`, shaders/Impeller | 🔴 |
| 4 | [memory_optimization.md](memory_optimization.md) | Leaks, image memory, GC pressure | 🔴 |
| 5 | [list_and_scroll_performance.md](list_and_scroll_performance.md) | Lazy building, pagination, image caching | 🔵 |
| 6 | [startup_and_app_size.md](startup_and_app_size.md) | Cold start, deferred loading, tree shaking, size | 🔴 |

> **Cross-references:** Rendering pipeline (mechanism): [Module 09](../09%20Rendering%20Pipeline/README.md). Build phase/rebuilds: [09 · build_phase](../09%20Rendering%20Pipeline/build_phase.md). Repaint boundaries: [09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md). Memory/GC: [02 · memory_and_gc](../02%20Advanced%20Dart/memory_and_gc.md). Isolates: [02 · isolates](../02%20Advanced%20Dart/isolates.md). Startup: [10 · embedder_and_startup](../10%20Flutter%20Architecture/embedder_and_startup.md). Images/lists: [07](../07%20Widgets/images_and_assets.md).

## Prerequisites

[09 Rendering Pipeline](../09%20Rendering%20Pipeline/README.md), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (memory/GC, isolates), [08 · dispose_and_leaks](../08%20Widget%20Lifecycle/dispose_and_leaks.md).

## What you'll be able to do after this module

- Profile with DevTools and attribute jank to the right phase/thread.
- Cut unnecessary rebuilds and raster cost.
- Find and fix memory leaks and image-memory bloat.
- Build smooth lists and reduce startup time/app size.

## Capstone

**Jank hunt:** Given a janky screen, profile it, attribute the cost (build vs layout vs raster vs memory), apply the targeted fix, and prove the improvement with before/after frame timings.

## Summary

Performance work is a measure→diagnose→fix→verify loop. Use DevTools to find the real bottleneck by phase/thread, apply the specific remedy (const/scoping for rebuilds, RepaintBoundary/Impeller for raster, dispose/sizing for memory, lazy/pagination for lists, deferral for startup), and confirm in profile/release builds.
