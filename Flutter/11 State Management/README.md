# 11 · State Management

## Introduction

State management is *how you store, update, and expose application state so the right widgets rebuild at the right time*. It's the single most consequential architectural choice in a Flutter app — and the most common interview topic. This module covers the full spectrum from `setState` to Riverpod/BLoC, with internals, performance, tradeoffs, and a selection guide.

## Why this module exists

Every non-trivial app has state shared across screens (auth, cart, settings, cached data). Choosing and using a state solution well determines testability, rebuild performance, and scalability. Interviewers probe this to gauge architectural maturity.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_overview_and_choosing.md](01_overview_and_choosing.md) | Kinds of state; the decision framework | 🔵 |
| 2 | [02_setstate_and_lifting_state.md](02_setstate_and_lifting_state.md) | Baseline: local state + lifting up | 🟢 |
| 3 | [03_inherited_widget.md](03_inherited_widget.md) | `InheritedWidget`/`InheritedModel` — the primitive | 🔴 |
| 4 | [04_value_change_notifier.md](04_value_change_notifier.md) | `ValueNotifier`/`ChangeNotifier`/builders | 🔵 |
| 5 | [05_provider.md](05_provider.md) | Provider: DI + `ChangeNotifier` over InheritedWidget | 🔵 |
| 6 | [06_riverpod.md](06_riverpod.md) | Riverpod: compile-safe, testable providers | 🔴 |
| 7 | [07_bloc.md](07_bloc.md) | BLoC: events → states, streams | 🔴 |
| 8 | [08_cubit.md](08_cubit.md) | Cubit: simplified BLoC | 🔵 |
| 9 | [09_getx.md](09_getx.md) | GetX: reactive + DI + routing | 🔵 |
| 10 | [10_comparison_and_selection.md](10_comparison_and_selection.md) | 5-way comparison + selection guide | 🔴 |

> **Cross-references:** Observer pattern: [05 · observer](../05%20Design%20Patterns/12_observer.md). Rebuild/build phase: [09 · build_phase](../09%20Rendering%20Pipeline/02_build_phase.md). `BuildContext`/`InheritedWidget` lookup: [06 · build_context](../06%20Flutter%20Fundamentals/06_build_context.md). Lifecycle/dispose: [08](../08%20Widget%20Lifecycle/README.md). DIP/DI: [04 · DIP](../04%20SOLID%20Principles/05_dip_dependency_inversion.md), [05 · dependency_injection](../05%20Design%20Patterns/21_dependency_injection.md). Streams: [02 · streams](../02%20Advanced%20Dart/03_streams.md).

## Prerequisites

[06–09](../06%20Flutter%20Fundamentals/README.md) (widgets, context, lifecycle, rebuilds), [05 · observer](../05%20Design%20Patterns/12_observer.md), [04 · SOLID](../04%20SOLID%20Principles/README.md).

## How each solution file is structured

Per the handbook spec, each solution includes **Theory, Internals, Performance, Pros, Cons, Architecture, Enterprise Usage, Interview Questions**, plus a mini/medium project idea. Package-based solutions note their `pubspec` dependency.

## What you'll be able to do after this module

- Classify state (ephemeral vs app) and pick the right tool.
- Implement the same feature in setState, Provider, Riverpod, BLoC, Cubit, and GetX.
- Reason about rebuild scope and performance for each.
- Defend a state-management choice in an interview or design review.

## Capstone

**Counter+ across five solutions:** Build one small feature (a counter with async load + error state) in Provider, Riverpod, BLoC, Cubit, and GetX; compare boilerplate, rebuild scope, testability, and structure (the 5-way lens in [10_comparison_and_selection.md](10_comparison_and_selection.md)).

## Summary

State management ranges from built-in (`setState`, `InheritedWidget`, `ChangeNotifier`) to packages (Provider, Riverpod, BLoC/Cubit, GetX). Choose by state scope, team, testability, and rebuild-control needs. Master the primitive (`InheritedWidget`) and you'll understand them all.
