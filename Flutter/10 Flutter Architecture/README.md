# 10 · Flutter Architecture

## Introduction

This module goes deep on *how Flutter is built and runs*: the layered architecture, the Dart **framework stack** (foundation → rendering → widgets → Material/Cupertino), the **engine** internals (C++, Dart runtime, Skia/Impeller), the **threading model** (platform/UI/raster/IO), and the **embedder + startup** path. It's the architectural counterpart to the rendering pipeline ([09](../09%20Rendering%20Pipeline/README.md)).

## Why this module exists

Senior/staff interviews and hard performance/integration problems demand a precise model of Flutter's internals: what runs on which thread, how bindings wire the framework to the engine, and where platform integration happens. Module 06 gave the overview; this module makes it rigorous.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_layered_architecture.md](01_layered_architecture.md) | Framework / Engine / Embedder in depth | 🔵 |
| 2 | [02_framework_stack.md](02_framework_stack.md) | foundation→rendering→widgets→Material + bindings | 🔴 |
| 3 | [03_threading_model.md](03_threading_model.md) | Platform / UI / Raster / IO task runners | 🔴 |
| 4 | [04_engine_internals.md](04_engine_internals.md) | Engine (C++): Dart runtime, Skia/Impeller, text, channels | 🔴 |
| 5 | [05_embedder_and_startup.md](05_embedder_and_startup.md) | Embedder responsibilities + app boot sequence | 🔴 |

> **Cross-references:** Overview: [06 · architecture_overview](../06%20Flutter%20Fundamentals/02_architecture_overview.md). Rendering phases/threads: [09](../09%20Rendering%20Pipeline/README.md). Isolates/event loop: [02](../02%20Advanced%20Dart/README.md). Platform channels: [Module 26](../26%20Platform%20Channels/README.md). Performance: [Module 21](../21%20Performance/README.md).

## Prerequisites

[06 Flutter Fundamentals](../06%20Flutter%20Fundamentals/README.md) and [09 Rendering Pipeline](../09%20Rendering%20Pipeline/README.md); [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (isolates, event loop, compilation).

## What you'll be able to do after this module

- Diagram the full architecture and name each layer's responsibility.
- Explain the Dart framework stack and how **bindings** connect it to the engine.
- Describe the four thread/task runners and what runs on each.
- Explain engine internals (Dart runtime hosting, Skia/Impeller, platform channels).
- Trace the app startup sequence from process launch to first frame.

## Capstone

**Architecture teardown:** Produce a one-page architecture diagram + narrative for a real app: layers, threads, bindings, engine responsibilities, and the boot sequence — the kind of artifact a staff engineer draws on a whiteboard.

## Summary

Flutter = a portable Dart framework stack + a native C++ engine + a per-platform embedder, coordinated by bindings and a multi-threaded task-runner model. This module makes that model precise so you can reason about performance, integration, and startup with authority.
