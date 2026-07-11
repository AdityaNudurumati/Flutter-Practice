# 40 · Clean Architecture

## Introduction

This module covers Clean Architecture in Flutter: the **layered design** (presentation / domain / data) governed by the **dependency rule** (dependencies point **inward**, toward the domain), the **domain layer** (entities, use cases, repository *interfaces*), the **data layer** (repository *implementations*, data sources, DTOs, mapping), the **presentation layer** (state management + view state, mapping domain → UI), and how they **wire together** via DI — with a capstone building a full vertical slice. It's the synthesis of SOLID ([Module 04](../04%20SOLID/README.md)), design patterns ([Module 05](../05%20Design%20Patterns/README.md)), DI ([Module 14](../14%20Dependency%20Injection/README.md)), state ([Module 11](../11%20State%20Management/README.md)), and error handling ([Module 38](../38%20Error%20Handling/README.md)).

## Why this module exists

As apps grow, "put everything in the widget" collapses under change — business rules tangle with UI and I/O, nothing is testable, and swapping a data source ripples everywhere. Clean Architecture imposes **boundaries** so the **business logic (domain) is independent** of Flutter, the network, and the database. The payoff is testability (domain tests need no device/network), flexibility (swap data sources/UI/state libs), and longevity — the difference between an app you can evolve for years and one that ossifies. It's the backbone that later architecture modules (MVVM, feature-first, DDD) build on.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [clean_architecture_overview.md](clean_architecture_overview.md) | Layers, the dependency rule, why boundaries, tradeoffs | 🔴 |
| 2 | [domain_layer.md](domain_layer.md) | Entities, use cases, repository interfaces (the pure core) | 🔴 |
| 3 | [data_layer.md](data_layer.md) | Repository impls, data sources, DTOs, mapping, `Result` | 🔴 |
| 4 | [presentation_layer.md](presentation_layer.md) | State/view models, calling use cases, domain→UI mapping | 🟡 |
| 5 | [clean_architecture_integration.md](clean_architecture_integration.md) | Capstone: a full vertical slice wired via DI | 🔴 |

> **Cross-references:** SOLID (DIP underpins the dependency rule): [Module 04](../04%20SOLID/README.md). Patterns (Repository/Adapter): [Module 05](../05%20Design%20Patterns/README.md). DI (wiring): [Module 14](../14%20Dependency%20Injection/README.md). State management: [Module 11](../11%20State%20Management/README.md). Error handling (`Result`/failures): [Module 38](../38%20Error%20Handling/README.md). Testing: [Module 49](../49%20Testing/README.md). Compared with MVC/MVP/MVVM: [41](../41%20MVC/README.md)/[42](../42%20MVP/README.md)/[43](../43%20MVVM/README.md); feature-first/DDD: [44](../44%20Feature%20First%20Architecture/README.md)/[46](../46%20Domain%20Driven%20Design/README.md).

## Prerequisites

[04 SOLID](../04%20SOLID/README.md) (esp. DIP), [05 Design Patterns](../05%20Design%20Patterns/README.md) (Repository), [14 Dependency Injection](../14%20Dependency%20Injection/README.md), [11 State Management](../11%20State%20Management/README.md), [38 Error Handling](../38%20Error%20Handling/README.md).

## What you'll be able to do after this module

- Explain the layers and the dependency rule, and why the domain must be independent.
- Model a pure domain (entities, use cases, repository interfaces) with no Flutter/IO.
- Implement the data layer (repositories, data sources, DTOs, mapping) returning `Result`.
- Connect UI via state/view models that call use cases and map domain → UI state.
- Wire a full vertical slice via DI and test each layer in isolation.

## Capstone

**Vertical slice:** A feature (e.g., "user profile") built cleanly end-to-end — domain (entity + `GetProfile` use case + `ProfileRepository` interface), data (repository impl over remote/local data sources + DTO mapping + `Result`), presentation (bloc/notifier calling the use case, mapping to view state) — wired with DI, each layer unit-tested with fakes, and a documented tradeoff analysis (when this structure is worth it).

## Summary

Clean Architecture = layered boundaries with the dependency rule pointing inward, keeping the **domain independent** of Flutter/network/DB. Domain (entities/use cases/interfaces) is pure; data implements interfaces and maps DTOs; presentation calls use cases and maps to UI; DI wires it. The result is testable, flexible, long-lived software — applied proportionally to the app's complexity.
