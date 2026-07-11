# 09 · Rendering Pipeline

## Introduction

This module explains exactly how Flutter turns your widget tree into pixels every frame: **build → layout → paint → composite → rasterize**, driven by the scheduler at vsync. It's the internals companion to Fundamentals ([06](../06%20Flutter%20Fundamentals/README.md)) and Widgets ([07](../07%20Widgets/README.md)), and the foundation for Performance ([21](../21%20Performance/README.md)).

## Why this module exists

You can't reason about jank, repaint cost, `RepaintBoundary`, or shader compilation without understanding the phases and what each costs. Senior engineers debug frame drops by knowing *which phase* is slow — build, layout, paint, or raster.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [pipeline_overview.md](pipeline_overview.md) | The full frame: build→layout→paint→composite→raster | 🔵 |
| 2 | [build_phase.md](build_phase.md) | Dirty tracking, `BuildOwner`, rebuild scope | 🔵 |
| 3 | [layout_phase.md](layout_phase.md) | `RenderObject.layout`, constraints/sizes, relayout boundaries | 🔴 |
| 4 | [paint_phase.md](paint_phase.md) | Painting, `PaintingContext`, paint order | 🔵 |
| 5 | [compositing_and_repaint_boundaries.md](compositing_and_repaint_boundaries.md) | Layers, `RepaintBoundary`, compositing | 🔴 |
| 6 | [rasterization_skia_impeller.md](rasterization_skia_impeller.md) | GPU rasterization, Skia vs Impeller, shader jank | 🔴 |
| 7 | [scheduler_and_vsync.md](scheduler_and_vsync.md) | `SchedulerBinding`, vsync, frame phases, threads | 🔴 |

> **Cross-references:** Widget/element/render trees: [06](../06%20Flutter%20Fundamentals/widgets_elements_render_objects.md). Constraints (widget usage): [07 · constraints_and_sizing](../07%20Widgets/constraints_and_sizing.md). Optimization techniques: [Module 21 Performance](../21%20Performance/README.md). Custom painting: [Module 23](../23%20Custom%20Painting/README.md). Threads/engine: [Module 10](../10%20Flutter%20Architecture/README.md).

## Prerequisites

[06 Flutter Fundamentals](../06%20Flutter%20Fundamentals/README.md) (three trees) and [07 Widgets](../07%20Widgets/constraints_and_sizing.md) (constraints).

## What you'll be able to do after this module

- Describe each frame phase and what runs on the UI vs raster thread.
- Explain the layout algorithm (constraints down, sizes up) at the render-object level.
- Reason about paint order, layers, and `RepaintBoundary`.
- Explain Skia vs Impeller and shader-compilation jank.
- Diagnose which phase is causing a dropped frame.

## Capstone

**Frame-phase diagnosis:** Given a janky screen, use DevTools (timeline, "Track Widget Rebuilds", raster stats) to attribute the cost to build/layout/paint/raster and propose a fix. (Techniques deepened in [Module 21](../21%20Performance/README.md).)

## Summary

A frame is build→layout→paint→composite→raster, scheduled at vsync across UI and raster threads. Knowing the phases and their costs is what turns "it's janky" into a precise, fixable diagnosis.
