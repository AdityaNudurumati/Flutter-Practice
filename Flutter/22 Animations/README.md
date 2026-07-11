# 22 · Animations

## Introduction

Motion communicates state, hierarchy, and continuity. Flutter's animation system is built on `Animation`/`AnimationController`/`Tween`/`Curve`, driven per-frame by the scheduler ([Module 09](../09%20Rendering%20Pipeline/scheduler_and_vsync.md)). This module covers implicit animations, explicit control, staggered/choreographed sequences, physics/gesture-driven motion, and animation performance.

## Why this module exists

Good motion elevates UX; bad motion janks or distracts. Knowing when to use the simple implicit widgets vs full explicit control — and how to keep animations at 60/120fps — is the difference between polish and pain.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [animation_fundamentals.md](animation_fundamentals.md) | `Animation`/`AnimationController`/`Tween`/`Curve` | 🔵 |
| 2 | [implicit_animations.md](implicit_animations.md) | `AnimatedFoo`/`TweenAnimationBuilder` | 🟢 |
| 3 | [explicit_animations.md](explicit_animations.md) | Controllers, `AnimatedBuilder`, transitions | 🔵 |
| 4 | [staggered_and_choreographed.md](staggered_and_choreographed.md) | `Interval`, sequences, `AnimatedList` | 🔴 |
| 5 | [physics_and_gesture_driven.md](physics_and_gesture_driven.md) | Springs/physics, gesture-driven motion | 🔴 |
| 6 | [animation_performance.md](animation_performance.md) | Keeping animations smooth | 🔴 |

> **Cross-references:** Scheduler/`Ticker`/vsync: [09 · scheduler_and_vsync](../09%20Rendering%20Pipeline/scheduler_and_vsync.md). Raster/repaint isolation: [09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md), [21 · jank_and_raster](../21%20Performance/jank_and_raster.md). Dispose controllers: [08 · dispose_and_leaks](../08%20Widget%20Lifecycle/dispose_and_leaks.md). Hero/route transitions: [12 · route_transitions](../12%20Navigation/route_transitions.md). Custom painting: [Module 23](../23%20Custom%20Painting/README.md).

## Prerequisites

[08 Widget Lifecycle](../08%20Widget%20Lifecycle/README.md), [09 · scheduler_and_vsync](../09%20Rendering%20Pipeline/scheduler_and_vsync.md), [21 · jank_and_raster](../21%20Performance/jank_and_raster.md).

## What you'll be able to do after this module

- Explain the animation system (controller → tween/curve → value → rebuild).
- Use implicit animations for simple state transitions.
- Build explicit, controllable, choreographed animations.
- Add physics/gesture-driven motion.
- Keep animations smooth (isolation, cheap builds, avoid raster cost).

## Capstone

**Animated interactions:** An implicit expand/collapse card, an explicit staggered list entrance, and a gesture-driven draggable/dismissible item with spring physics — all profiled to hold 60fps.

## Summary

Flutter animation is value-driven: a controller produces a 0→1 value, tweens/curves shape it, and widgets rebuild from it. Prefer implicit for simple cases, explicit for control, physics for natural motion — and always dispose controllers and keep frames within budget.
