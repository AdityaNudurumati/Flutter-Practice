# 24 · Responsive UI

## Introduction

Responsive UI adapts a **single layout** to any screen size/orientation — phone, tablet, desktop, web, split-screen — using the constraints model, `MediaQuery`/`LayoutBuilder`, flexible widgets, and breakpoints. This module builds directly on the constraints system ([07 · constraints_and_sizing](../07%20Widgets/constraints_and_sizing.md)).

## Why this module exists

Flutter runs everywhere; a phone-only layout breaks on tablets/desktop/web. Responsive design (fluid + breakpoint-based) is essential for reach and quality. This is distinct from **adaptive** UI (platform conventions/widgets), which is [Module 25](../25%20Adaptive%20UI/README.md).

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [responsive_fundamentals.md](responsive_fundamentals.md) | Principles, breakpoints, mobile→desktop | 🟢 |
| 2 | [mediaquery_vs_layoutbuilder.md](mediaquery_vs_layoutbuilder.md) | Global vs local size/constraints | 🔵 |
| 3 | [responsive_layout_widgets.md](responsive_layout_widgets.md) | `Flexible`/`Wrap`/`AspectRatio`/`FractionallySizedBox` | 🔵 |
| 4 | [adaptive_grids_and_split_views.md](adaptive_grids_and_split_views.md) | Responsive grids, master-detail/split views | 🔴 |
| 5 | [responsive_typography_and_orientation.md](responsive_typography_and_orientation.md) | Text scaling, spacing, orientation, safe areas | 🔵 |

> **Cross-references:** Constraints model: [07 · constraints_and_sizing](../07%20Widgets/constraints_and_sizing.md). Flex layout: [07 · layout_flex](../07%20Widgets/layout_flex.md). Adaptive (platform) UI: [Module 25](../25%20Adaptive%20UI/README.md). Web/desktop: [Modules 53](../53%20Flutter%20Web/README.md)/[54](../54%20Flutter%20Desktop/README.md). Theming: [07 · text_and_theming](../07%20Widgets/text_and_theming.md).

## Prerequisites

[07 Widgets](../07%20Widgets/README.md) — especially constraints and flex.

## What you'll be able to do after this module

- Design fluid + breakpoint-based layouts for phone/tablet/desktop/web.
- Choose `MediaQuery` vs `LayoutBuilder` correctly.
- Use flexible/wrapping widgets and responsive grids.
- Build master-detail/split-view layouts that adapt to width.
- Handle text scaling, spacing, orientation, and safe areas.

## Capstone

**Adaptive product screen:** A screen that shows a single scrolling list on phones and a master-detail split view on tablet/desktop, with a responsive grid, fluid spacing/typography, and orientation/safe-area handling — one codebase, many sizes.

## Summary

Responsive = one layout, many sizes. Combine fluid sizing (constraints/flex/fractions) with breakpoints (`MediaQuery`/`LayoutBuilder`), reflow grids and switch to split views on large screens, and respect text scale/orientation/safe areas.
