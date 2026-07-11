# 12 · Navigation

## Introduction

Navigation is how users move between screens. Flutter models screens as a **stack of routes** managed by a `Navigator`, with two paradigms: **imperative** (`push`/`pop`) and **declarative** (Navigator 2.0 / Router API). This module covers both, named routes, nested navigators/tabs, and transitions.

## Why this module exists

Navigation touches every app and is a common source of bugs (lost arguments, back-button issues, deep-link mismatches, nested-navigator confusion). Understanding the stack model and both paradigms lets you build correct, testable navigation — and choose the right approach.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [navigator_stack.md](navigator_stack.md) | The route stack model | 🟢 |
| 2 | [imperative_navigation.md](imperative_navigation.md) | `push`/`pop`, `MaterialPageRoute`, args & results | 🟢 |
| 3 | [named_routes.md](named_routes.md) | Named routes, `onGenerateRoute`, settings | 🔵 |
| 4 | [declarative_navigation.md](declarative_navigation.md) | Navigator 2.0 / Router / `Page` API | 🔴 |
| 5 | [nested_navigators_and_tabs.md](nested_navigators_and_tabs.md) | Nested navigators, tabs, `IndexedStack` | 🔵 |
| 6 | [route_transitions.md](route_transitions.md) | `PageRouteBuilder`, custom transitions, `Hero` | 🔵 |

> **Cross-references:** Deep links, route guards, and `go_router` are in [Module 13 Routing](../13%20Routing/README.md). `BuildContext`/`Navigator.of`: [06 · build_context](../06%20Flutter%20Fundamentals/build_context.md). State across navigation: [Module 11](../11%20State%20Management/README.md). App shell/`MaterialApp`: [06 · app_entry_point](../06%20Flutter%20Fundamentals/app_entry_point.md).

## Prerequisites

[06 Flutter Fundamentals](../06%20Flutter%20Fundamentals/README.md) (context, app entry) and [07 Widgets](../07%20Widgets/README.md).

## What you'll be able to do after this module

- Explain the navigator stack and push/pop semantics.
- Pass arguments and return results between screens (type-safely).
- Use named routes + `onGenerateRoute`.
- Understand Navigator 2.0 / Router and when it's needed.
- Build nested navigators, tabs, and custom transitions/Hero animations.

## Capstones

| Tier | Build |
|------|-------|
| Beginner | Two-screen push/pop with a returned result. |
| Intermediate | Named-route app with argument passing + `onGenerateRoute`. |
| Advanced | Bottom-nav shell with per-tab nested navigators preserving state. |
| Enterprise | A declarative router mapping app state → pages (bridge to [Module 13](../13%20Routing/README.md)). |

## Summary

Screens are a stack of routes. Master imperative push/pop + args/results first, then named routes, then the declarative Router for URL-driven/complex navigation. Nested navigators and transitions round out real-world needs.
