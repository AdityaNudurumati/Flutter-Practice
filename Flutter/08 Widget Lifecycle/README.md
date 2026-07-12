# 08 · Widget Lifecycle

## Introduction

A `StatefulWidget`'s `State` object goes through a well-defined lifecycle: created, initialized, built, updated, and disposed. Knowing *which method runs when* — and what belongs in each — is what separates correct, leak-free Flutter code from the buggy kind. This module also covers **app-level** lifecycle (foreground/background).

## Why this module exists

Most Flutter bugs — leaks, "setState after dispose", "no initialized value", stale subscriptions, work done at the wrong time — are lifecycle mistakes. This module makes the sequence and the responsibilities of each method precise, building on the three-trees model ([Module 06](../06%20Flutter%20Fundamentals/04_widgets_elements_render_objects.md)).

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_state_lifecycle_overview.md](01_state_lifecycle_overview.md) | The full `State` lifecycle sequence | 🔵 |
| 2 | [02_initstate_and_dependencies.md](02_initstate_and_dependencies.md) | `initState` vs `didChangeDependencies` | 🔵 |
| 3 | [03_didupdatewidget.md](03_didupdatewidget.md) | Reacting to new widget config | 🔵 |
| 4 | [04_setstate_mechanics.md](04_setstate_mechanics.md) | How `setState` works + pitfalls | 🟢 |
| 5 | [05_dispose_and_leaks.md](05_dispose_and_leaks.md) | `dispose`, cleanup, leak prevention | 🔴 |
| 6 | [06_app_lifecycle.md](06_app_lifecycle.md) | `AppLifecycleState`, `WidgetsBindingObserver` | 🔵 |

> **Cross-references:** Three trees / state persistence: [Module 06](../06%20Flutter%20Fundamentals/04_widgets_elements_render_objects.md). Memory/leaks: [02 · memory_and_gc](../02%20Advanced%20Dart/13_memory_and_gc.md). Streams/subscriptions: [02 · streams](../02%20Advanced%20Dart/03_streams.md). Controllers/forms: [07 · input_and_forms](../07%20Widgets/08_input_and_forms.md). State management alternatives to raw `setState`: [Module 11](../11%20State%20Management/README.md).

## Prerequisites

[06 Flutter Fundamentals](../06%20Flutter%20Fundamentals/README.md) (three trees, stateless/stateful, `BuildContext`) and [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (streams, memory/GC).

## What you'll be able to do after this module

- Recite the `State` lifecycle and put each responsibility in the right method.
- Choose `initState` vs `didChangeDependencies` correctly.
- React to config changes via `didUpdateWidget`.
- Use `setState` safely (no post-dispose calls, no async pitfalls).
- Prevent leaks by disposing controllers/subscriptions/timers.
- Respond to app foreground/background transitions.

## Capstones

| Tier | Build |
|------|-------|
| Beginner | A timer widget that starts in `initState` and cancels in `dispose`. |
| Intermediate | A widget subscribing to a stream, resubscribing on `didUpdateWidget`. |
| Advanced | A screen that pauses/resumes work on app background/foreground. |
| Enterprise | A `LifecycleAwareMixin` that standardizes subscription/controller cleanup. |

## Summary

The lifecycle is a contract: initialize in `initState`, react to inherited data in `didChangeDependencies`, react to config in `didUpdateWidget`, rebuild via `setState`, and **always clean up in `dispose`**. Master it and a whole class of bugs disappears.
