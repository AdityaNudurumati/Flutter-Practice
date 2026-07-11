# 23 · Custom Painting

## Introduction

When widgets can't express your visual — charts, gauges, signatures, custom shapes, backgrounds, effects — you drop to the **canvas**. This module covers `CustomPainter`/`Canvas`, paths/shapes/gradients, custom `RenderObject`s for bespoke layout/paint, shaders/effects, and keeping it all fast.

## Why this module exists

Widget composition covers most UIs, but data-viz, drawing tools, and unique brand visuals need pixel-level control. Custom painting gives it — grounded in the paint phase ([09 · paint_phase](../09%20Rendering%20Pipeline/paint_phase.md)) — and must be done efficiently (`shouldRepaint`, isolation) to avoid jank.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [custompainter_and_canvas.md](custompainter_and_canvas.md) | `CustomPaint`/`CustomPainter`/`Canvas`/`Paint` | 🔵 |
| 2 | [paths_shapes_gradients.md](paths_shapes_gradients.md) | `Path`, shapes, gradients, clipping | 🔵 |
| 3 | [custom_renderobject.md](custom_renderobject.md) | Bespoke layout + paint via `RenderObject` | 🔴 |
| 4 | [shaders_and_effects.md](shaders_and_effects.md) | Fragment shaders, `ImageFilter`, blend modes | 🔴 |
| 5 | [custom_painting_performance.md](custom_painting_performance.md) | Keeping custom paint fast | 🔴 |

> **Cross-references:** Paint phase: [09 · paint_phase](../09%20Rendering%20Pipeline/paint_phase.md). Layout phase / render objects: [09 · layout_phase](../09%20Rendering%20Pipeline/layout_phase.md). Repaint isolation: [09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md), [21 · jank_and_raster](../21%20Performance/jank_and_raster.md). Animation (driving repaints): [Module 22](../22%20Animations/README.md). `dart:ui`: [10 · engine_internals](../10%20Flutter%20Architecture/engine_internals.md).

## Prerequisites

[09 Rendering Pipeline](../09%20Rendering%20Pipeline/README.md) (paint/layout), [22 Animations](../22%20Animations/README.md), [21 · jank_and_raster](../21%20Performance/jank_and_raster.md).

## What you'll be able to do after this module

- Draw with `CustomPainter`/`Canvas` and implement `shouldRepaint` correctly.
- Build shapes/paths/gradients and clip regions.
- Write custom `RenderObject`s for bespoke layout + painting.
- Apply shaders/filters/blend modes.
- Keep custom painting smooth (isolation, caching, cheap paint).

## Capstone

**Animated gauge + signature pad:** A `CustomPainter` gauge driven by an animation (correct `shouldRepaint`, isolated with `RepaintBoundary`), and a path-based signature pad capturing drag input — both profiled to hold 60fps.

## Summary

Custom painting is `Canvas` drawing under a `CustomPainter` (or a full `RenderObject` for layout+paint). Master paths/gradients/shaders, implement `shouldRepaint`, isolate repaints, and cache expensive draws — the toolkit for charts, gauges, drawing tools, and bespoke visuals.
