# 41 · MVC

## Introduction

This module covers **Model-View-Controller (MVC)** and how it does (and doesn't) fit Flutter: the **classic pattern** (Model = data/rules, View = UI, Controller = input→model orchestration), **how MVC maps to Flutter** (where the widget tree, controllers, and reactive state land), **controller design** (keeping views thin, notifying the view of change), and the **tradeoffs + comparison** to MVP/MVVM/Clean Architecture — tied together in a capstone. It sits alongside the other presentation patterns ([Module 42 MVP](../42%20MVP/README.md), [Module 43 MVVM](../43%20MVVM/README.md)) and the layered backbone ([Module 40 Clean Architecture](../40%20Clean%20Architecture/README.md)).

## Why this module exists

MVC is the oldest and most name-dropped UI pattern, and many Flutter apps (especially GetX-based) describe themselves as MVC — but **Flutter's declarative, reactive widget model fits MVC awkwardly** (the classic "controller updates view" flow assumes imperative views). Understanding MVC's roles, why it strains in Flutter, and how it compares to MVVM/Clean prevents cargo-culting a pattern that fights the framework, and clarifies what people actually mean when they say "MVC in Flutter."

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [mvc_fundamentals.md](mvc_fundamentals.md) | Classic MVC: three roles, data flow, origins | 🔵 |
| 2 | [mvc_in_flutter.md](mvc_in_flutter.md) | Mapping MVC to Flutter's reactive model (and the friction) | 🟡 |
| 3 | [controllers_and_thin_views.md](controllers_and_thin_views.md) | Controller responsibilities, thin views, change notification | 🟡 |
| 4 | [mvc_tradeoffs_and_comparison.md](mvc_tradeoffs_and_comparison.md) | Strengths/weaknesses; MVC vs MVP/MVVM/Clean | 🔴 |
| 5 | [mvc_integration.md](mvc_integration.md) | Capstone: a pragmatic MVC-style feature | 🟡 |

> **Cross-references:** MVP: [Module 42](../42%20MVP/README.md). MVVM (the better reactive fit): [Module 43](../43%20MVVM/README.md). Clean Architecture (layering): [Module 40](../40%20Clean%20Architecture/README.md). State management: [Module 11](../11%20State%20Management/README.md). Design patterns (Observer): [Module 05](../05%20Design%20Patterns/README.md). Widget rebuilds: [Module 07](../07%20Widgets/README.md).

## Prerequisites

[11 State Management](../11%20State%20Management/README.md), [40 Clean Architecture](../40%20Clean%20Architecture/README.md), [05 Design Patterns](../05%20Design%20Patterns/README.md) (Observer), Flutter widget basics.

## What you'll be able to do after this module

- Explain classic MVC's three roles and its data flow.
- Map MVC onto Flutter and articulate precisely where it fits and where it strains.
- Design thin views + controllers with proper change notification (Observer/reactive).
- Compare MVC to MVP/MVVM/Clean and choose deliberately.
- Build a pragmatic MVC-style feature that respects Flutter's reactive model.

## Capstone

**MVC-style feature:** A counter/list feature structured as Model (data + rules), View (thin widgets), and Controller (handles input, mutates the model, notifies the view via a `ChangeNotifier`/reactive mechanism) — kept testable, with an honest note on how it differs from and relates to MVVM.

## Summary

MVC = Model (data/rules) + View (UI) + Controller (input→model). In Flutter, the classic imperative flow strains against the reactive widget model, so "Flutter MVC" is usually a reactive variant (controllers + notifiers) that's really closer to MVVM. Know the roles, the friction, and the comparisons — and pick the pattern that fits the framework.
