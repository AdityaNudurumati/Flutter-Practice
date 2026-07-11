# 07 · Widgets

## Introduction

Widgets are Flutter's building blocks — *everything* is a widget: layout, styling, gestures, even the app itself. This module is the practical catalog: how to lay out, size, scroll, style, and compose widgets, and how to build your own. It builds directly on the three-trees model from [Module 06](../06%20Flutter%20Fundamentals/widgets_elements_render_objects.md).

## Why this module exists

Knowing *what widget to reach for* and *how layout/constraints work* is the day-to-day skill of Flutter UI development. Most layout frustration ("unbounded height", "overflow", "why won't this expand?") comes from not understanding constraints — which this module makes concrete.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [widget_categories.md](widget_categories.md) | The kinds of widgets and how to navigate the catalog | 🟢 |
| 2 | [layout_flex.md](layout_flex.md) | `Row`/`Column`/`Flex`/`Expanded`/`Flexible`/`Spacer`, alignment | 🟢 |
| 3 | [constraints_and_sizing.md](constraints_and_sizing.md) | Constraints go down, sizes go up; `Container`/`SizedBox`/`ConstrainedBox` | 🔵 |
| 4 | [stack_and_positioning.md](stack_and_positioning.md) | `Stack`/`Positioned`/`Align`/`Alignment` (overlap layout) | 🟢 |
| 5 | [scrolling_and_slivers.md](scrolling_and_slivers.md) | `ListView`/`GridView`/`CustomScrollView`/slivers | 🔵 |
| 6 | [text_and_theming.md](text_and_theming.md) | `Text`/`TextStyle`/`Theme`/`TextTheme` | 🟢 |
| 7 | [images_and_assets.md](images_and_assets.md) | `Image`, assets, network, caching, `pubspec` | 🟢 |
| 8 | [input_and_forms.md](input_and_forms.md) | `TextField`/`Form`/validation/buttons/gestures | 🔵 |
| 9 | [custom_composite_widgets.md](custom_composite_widgets.md) | Building your own widgets by composition | 🔵 |

> **Cross-references:** The layout *pipeline* (constraints/layout/paint internals) is [Module 09](../09%20Rendering%20Pipeline/README.md). Custom drawing is [Module 23](../23%20Custom%20Painting/README.md). Responsive/adaptive layout are Modules [24](../24%20Responsive%20UI/README.md)/[25](../25%20Adaptive%20UI/README.md). Animations are [Module 22](../22%20Animations/README.md).

## Prerequisites

[06 Flutter Fundamentals](../06%20Flutter%20Fundamentals/README.md) — especially the three trees, stateless/stateful, and `BuildContext`.

## What you'll be able to do after this module

- Build any static layout with `Row`/`Column`/`Stack` + flex.
- Predict and fix layout errors using the constraints model.
- Build performant scrolling lists/grids with builders and slivers.
- Style text and theme an app; load images/assets correctly.
- Build forms with validation and compose reusable custom widgets.

## Capstones

| Tier | Build |
|------|-------|
| Beginner | A profile card (avatar + text + buttons) via composition. |
| Intermediate | A scrollable feed with a `ListView.builder` + custom item widget. |
| Advanced | A collapsing-header screen using `CustomScrollView` + slivers. |
| Enterprise | A reusable, themed **design-system widget kit** (buttons, cards, inputs). |

## Summary

Master layout via the constraints model, reach for the right catalog widget, and compose small custom widgets. This is the practical core of building Flutter UIs; rendering internals ([Module 09](../09%20Rendering%20Pipeline/README.md)) explain *why* it behaves as it does.
