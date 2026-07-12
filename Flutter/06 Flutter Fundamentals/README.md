# 06 · Flutter Fundamentals

## Introduction

This module is where Dart meets pixels. It explains **what Flutter is**, how it runs, its layered architecture, the **three trees** (Widget/Element/RenderObject) that power everything, the `Stateless`/`Stateful` split, `BuildContext`, the app entry point, the **declarative UI** mental model, and hot reload. Master this and every later Flutter module (widgets, state, rendering, performance) has a solid base.

## Why this module exists

Most Flutter confusion — "why did my widget rebuild?", "what is `context`?", "why is everything a widget?" — comes from not understanding the model underneath. This module builds that model *before* you drown in the widget catalog.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_what_is_flutter.md](01_what_is_flutter.md) | What Flutter is; how it renders; vs native/React Native | 🟢 |
| 2 | [02_architecture_overview.md](02_architecture_overview.md) | Framework / Engine / Embedder layers | 🔵 |
| 3 | [03_declarative_ui.md](03_declarative_ui.md) | Declarative vs imperative UI (UI = f(state)) | 🟢 |
| 4 | [04_widgets_elements_render_objects.md](04_widgets_elements_render_objects.md) | The three trees and how they relate | 🔵 |
| 5 | [05_stateless_vs_stateful.md](05_stateless_vs_stateful.md) | `StatelessWidget` vs `StatefulWidget` + `setState` | 🟢 |
| 6 | [06_build_context.md](06_build_context.md) | What `BuildContext` actually is; `.of(context)` | 🔵 |
| 7 | [07_app_entry_point.md](07_app_entry_point.md) | `main` / `runApp` / `MaterialApp` / `Scaffold` | 🟢 |
| 8 | [08_hot_reload.md](08_hot_reload.md) | Hot reload vs restart; how it works | 🟢 |

> **Cross-references:** The deep **rendering pipeline** (build→layout→paint→composite→raster) is [Module 09](../09%20Rendering%20Pipeline/README.md). Deep **architecture** (engine internals, threads, Skia/Impeller) is [Module 10](../10%20Flutter%20Architecture/README.md). **Widget lifecycle** (`initState`→`dispose`) is [Module 08](../08%20Widget%20Lifecycle/README.md). The JIT/AOT basis of hot reload is in [02 · dart_compilation](../02%20Advanced%20Dart/14_dart_compilation.md).

## Prerequisites

[01 Dart Fundamentals](../01%20Dart%20Fundamentals/README.md) + [03 OOP](../03%20Object%20Oriented%20Programming/README.md). Composition ([03](../03%20Object%20Oriented%20Programming/06_composition_and_relationships.md)) especially — Flutter is composition-first.

## What you'll be able to do after this module

- Explain how Flutter draws UI and why it's consistent across platforms.
- Describe the three trees and what each is responsible for.
- Choose `Stateless` vs `Stateful` correctly and use `setState` properly.
- Explain `BuildContext` and `Theme.of(context)`-style lookups.
- Read a `main`→`runApp`→`MaterialApp`→`Scaffold` skeleton fluently.
- Explain why hot reload works and when you need hot restart.

## Capstones

| Tier | Build |
|------|-------|
| Beginner | A `Hello Flutter` app with a themed `Scaffold` + counter. |
| Intermediate | A profile card built purely by widget composition. |
| Advanced | A small multi-screen app demonstrating stateless/stateful split + `Theme.of`. |
| Enterprise | A widget-tree inspector write-up mapping a screen to its element/render trees. |

## Summary

Flutter renders its own UI from a widget tree via three cooperating trees. Learn the model first: declarative UI, the trees, state, context, and the entry point. Then the widget catalog ([Module 07](../07%20Widgets/README.md)) and rendering internals ([Module 09](../09%20Rendering%20Pipeline/README.md)) will make sense.
