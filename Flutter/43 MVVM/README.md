# 43 · MVVM

## Introduction

This module covers **Model-View-ViewModel (MVVM)** — the **reactive, Flutter-native** presentation pattern: a **View** that **binds** to an observable **ViewModel** (`UI = f(state)`), a **ViewModel** that exposes **immutable state + commands** (mapping domain results to display state, delegating rules to use cases), and a **Model** (domain/data). It walks the **fundamentals**, **view-model design**, **data binding & state** (how Provider/Riverpod/Bloc/`ChangeNotifier` realize MVVM in Flutter with scoped rebuilds), and **testing (state-sequence) + comparison** to MVC/MVP/Clean — capped by a capstone. It's the culmination of the presentation-pattern arc ([Module 41 MVC](../41%20MVC/README.md), [Module 42 MVP](../42%20MVP/README.md)) over the Clean backbone ([Module 40](../40%20Clean%20Architecture/README.md)).

## Why this module exists

MVVM is what Flutter's declarative, reactive UI naturally produces — most "Provider/Riverpod/Bloc/GetX" apps are MVVM whether they name it or not. It delivers MVP-level testability (assert the ViewModel's **state sequence**) **without** MVP's imperative friction, and slots cleanly as the **presentation layer of Clean Architecture**. Understanding MVVM precisely — state vs commands, binding vs rebuild scope, view model over use cases — is the key to idiomatic, testable, maintainable Flutter architecture.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_mvvm_fundamentals.md](01_mvvm_fundamentals.md) | Roles, observable state, data binding, reactive fit | 🔵 |
| 2 | [02_viewmodel_design.md](02_viewmodel_design.md) | ViewModel responsibilities: state, commands, over use cases | 🔴 |
| 3 | [03_data_binding_and_state.md](03_data_binding_and_state.md) | Binding in Flutter (ChangeNotifier/Provider/Riverpod/Bloc), scoped rebuilds | 🔴 |
| 4 | [04_mvvm_testing_and_comparison.md](04_mvvm_testing_and_comparison.md) | State-sequence testing; MVVM vs MVC/MVP; + Clean | 🟡 |
| 5 | [05_mvvm_integration.md](05_mvvm_integration.md) | Capstone: MVVM feature + Clean layering + state test | 🔴 |

> **Cross-references:** MVC/MVP: [Module 41](../41%20MVC/README.md)/[Module 42](../42%20MVP/README.md). Clean Architecture (presentation layer): [Module 40](../40%20Clean%20Architecture/README.md). State management: [Module 11](../11%20State%20Management/README.md). Error handling (Result→state): [Module 38](../38%20Error%20Handling/README.md). Performance (scoped rebuilds): [Module 21](../21%20Performance/README.md). Testing (state-sequence): [Module 49](../49%20Testing/README.md).

## Prerequisites

[41 MVC](../41%20MVC/README.md), [42 MVP](../42%20MVP/README.md), [11 State Management](../11%20State%20Management/README.md), [40 Clean Architecture](../40%20Clean%20Architecture/README.md), [38 Error Handling](../38%20Error%20Handling/README.md).

## What you'll be able to do after this module

- Explain MVVM's roles and why it's the natural fit for reactive Flutter.
- Design a ViewModel exposing immutable state + commands over use cases.
- Bind views to view models with the right tool and scope rebuilds efficiently.
- Test presentation logic by asserting the ViewModel's state sequence.
- Combine MVVM (presentation) with Clean Architecture (layering) idiomatically.

## Capstone

**MVVM feature:** A search/list feature with a ViewModel exposing immutable state (loading/data/empty/error) + commands (`search`, `retry`) over use cases, a View that binds and rebuilds efficiently (scoped), Clean layering underneath (domain/data), and a **state-sequence unit test** (loading → data/error) with fakes — realized with your chosen state tool (Provider/Riverpod/Bloc).

## Summary

MVVM = View binds to an observable ViewModel (state + commands) over a Model (domain/data). It's the reactive, Flutter-native pattern — MVP-level testability via state-sequence assertions, no imperative friction — and the idiomatic **presentation layer of Clean Architecture**, realized by Provider/Riverpod/Bloc/`ChangeNotifier` with scoped rebuilds.
