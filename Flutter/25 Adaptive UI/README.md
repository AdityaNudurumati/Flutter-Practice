# 25 · Adaptive UI

## Introduction

Adaptive UI conforms to **platform conventions** — Material on Android, Cupertino on iOS, desktop idioms on Windows/macOS/Linux, web patterns on the browser — so the app feels native everywhere. This is the *platform* dimension, complementary to responsive design's *size* dimension ([Module 24](../24%20Responsive%20UI/README.md)).

## Why this module exists

Flutter renders one consistent UI by default, which can feel "non-native" (Material dialogs on iOS, wrong scroll physics/back gestures). Adaptive UI selectively conforms to each platform's expectations where it matters — a deliberate, bounded effort, not blanket duplication.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_adaptive_fundamentals.md](01_adaptive_fundamentals.md) | Adaptive vs responsive; platform detection; when to adapt | 🔵 |
| 2 | [02_material_vs_cupertino.md](02_material_vs_cupertino.md) | Design languages; `.adaptive` constructors; theming | 🔵 |
| 3 | [03_platform_adaptive_widgets_and_navigation.md](03_platform_adaptive_widgets_and_navigation.md) | Adaptive widgets, dialogs, navigation, scroll/back | 🔴 |
| 4 | [04_cross_platform_design_system.md](04_cross_platform_design_system.md) | Abstraction layer + adaptive components | 🔴 |

> **Cross-references:** Responsive (size): [Module 24](../24%20Responsive%20UI/README.md). Widgets/theming: [07 · widget_categories](../07%20Widgets/01_widget_categories.md), [07 · text_and_theming](../07%20Widgets/06_text_and_theming.md). Navigation/back: [12](../12%20Navigation/README.md). Web/desktop: [Modules 53](../53%20Flutter%20Web/README.md)/[54](../54%20Flutter%20Desktop/README.md). Platform detection: [10 · layered_architecture](../10%20Flutter%20Architecture/01_layered_architecture.md).

## Prerequisites

[07 Widgets](../07%20Widgets/README.md), [24 Responsive UI](../24%20Responsive%20UI/README.md), [12 Navigation](../12%20Navigation/README.md).

## What you'll be able to do after this module

- Distinguish adaptive from responsive and decide *when* to adapt.
- Detect platform correctly and use Material/Cupertino + `.adaptive` widgets.
- Adapt dialogs, navigation, scroll physics, and back behavior per platform.
- Build a cross-platform design system that centralizes adaptation.

## Capstone

**Platform-adaptive app:** A screen that uses platform-correct scaffolding, dialogs, switches, scroll physics, and navigation (Material vs Cupertino vs desktop), driven by a small adaptive design-system layer — one codebase, native feel on each platform.

## Summary

Adaptive UI = conform to platform conventions where it matters (design language, dialogs, navigation, scroll/back), via detection + `.adaptive` widgets + a design-system abstraction. Combine with responsive (size) for apps that feel right on every platform *and* form factor.
