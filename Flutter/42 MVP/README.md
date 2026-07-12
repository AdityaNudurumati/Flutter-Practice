# 42 · MVP

## Introduction

This module covers **Model-View-Presenter (MVP)**: the pattern where a **passive View** (implementing a **view interface/contract**) delegates all logic to a **Presenter** that drives it explicitly (`view.showLoading()`, `view.showData(...)`), with the **Model** holding data/rules. It walks the **fundamentals**, the **presenter ↔ view contract** (MVP's defining feature), its **standout testability** (mock the view, test the presenter without a UI), and its **fit and friction in Flutter** plus comparison to MVC/MVVM — tied together in a capstone. It sits with the other presentation patterns ([Module 41 MVC](../41%20MVC/README.md), [Module 43 MVVM](../43%20MVVM/README.md)) over the Clean backbone ([Module 40](../40%20Clean%20Architecture/README.md)).

## Why this module exists

MVP's contribution is **maximum testability via an explicit view contract**: the presenter talks to an interface, so you can mock the view and test all presentation logic in plain Dart. That's valuable to understand — but MVP's **imperative "presenter drives the view"** model fits Flutter's **reactive/declarative** UI awkwardly (even more than MVC), so it's rarely the idiomatic choice. Knowing MVP clarifies the testability idea (which MVVM achieves differently) and why reactive Flutter gravitates to MVVM.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_mvp_fundamentals.md](01_mvp_fundamentals.md) | Roles, passive view, presenter, data flow | 🔵 |
| 2 | [02_presenter_and_view_contract.md](02_presenter_and_view_contract.md) | The view interface/contract (MVP's core), presenter driving the view | 🟡 |
| 3 | [03_mvp_testability.md](03_mvp_testability.md) | Mock the view, test the presenter — MVP's standout strength | 🟡 |
| 4 | [04_mvp_in_flutter_and_comparison.md](04_mvp_in_flutter_and_comparison.md) | Flutter fit/friction; MVP vs MVC/MVVM | 🔴 |
| 5 | [05_mvp_integration.md](05_mvp_integration.md) | Capstone: an MVP feature with a mocked-view test | 🟡 |

> **Cross-references:** MVC: [Module 41](../41%20MVC/README.md). MVVM (reactive fit): [Module 43](../43%20MVVM/README.md). Clean Architecture: [Module 40](../40%20Clean%20Architecture/README.md). Testing (mocking): [Module 49](../49%20Testing/README.md). SOLID (DIP/interfaces): [Module 04](../04%20SOLID%20Principles/README.md). State management: [Module 11](../11%20State%20Management/README.md).

## Prerequisites

[41 MVC](../41%20MVC/README.md), [04 SOLID](../04%20SOLID%20Principles/README.md) (interfaces/DIP), [40 Clean Architecture](../40%20Clean%20Architecture/README.md), [49 Testing](../49%20Testing/README.md) (mocking).

## What you'll be able to do after this module

- Explain MVP's roles and the passive-view + presenter-driven-view flow.
- Define a view contract (interface) and a presenter that drives it.
- Test all presentation logic by mocking the view (MVP's key strength).
- Articulate MVP's friction in reactive Flutter and how it compares to MVC/MVVM.
- Decide when (rarely) MVP is worth its boilerplate in Flutter.

## Capstone

**MVP feature:** A login/list feature with a `View` interface (`showLoading/showData/showError`), a `Presenter` that calls use cases and drives the view, and a widget implementing the view — with a full **presenter unit test using a mocked view** (asserting `showLoading` then `showData`/`showError`), plus a note on why MVVM is usually the better Flutter fit.

## Summary

MVP = passive View (behind an interface) + Presenter (drives the view, holds presentation logic) + Model (data/rules). Its defining strength is **testability via the view contract** (mock the view). Its imperative flow fits reactive Flutter poorly, so it's uncommon here — but the testability lesson informs MVVM, the idiomatic choice.
