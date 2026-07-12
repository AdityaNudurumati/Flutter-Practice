# 44 · Feature-First Architecture

## Introduction

This module covers **feature-first** (a.k.a. package-by-feature) organization: structuring a Flutter app so code is grouped **by feature** (`features/auth/`, `features/cart/`) — each a self-contained vertical slice with its own domain/data/presentation — rather than by technical **layer** across the whole app (`models/`, `views/`, `controllers/`). It walks the **fundamentals** (feature vs layer, cohesion), **structuring features + a shared `core`**, **feature boundaries & cross-feature dependencies**, and **scaling + migrating** from layer-first — with a capstone. It builds directly on Clean Architecture ([Module 40](../40%20Clean%20Architecture/README.md)) and MVVM ([Module 43](../43%20MVVM/README.md)), and points toward modular architecture ([Module 45](../45%20Modular%20Architecture/README.md)).

## Why this module exists

As apps grow, **layer-first** folders (all models together, all views together) scatter each feature across the codebase — a change to "cart" touches five distant folders, features tangle, and teams collide. **Feature-first** co-locates everything a feature needs, so slices are **cohesive, independently evolvable, and ownable by a team**, with a shared `core` for cross-cutting concerns. It's the organizing principle that makes Clean/MVVM scale across many features and the step before extracting features into packages/modules.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_feature_first_fundamentals.md](01_feature_first_fundamentals.md) | Feature vs layer organization, cohesion, why it scales | 🔵 |
| 2 | [02_structuring_features_and_core.md](02_structuring_features_and_core.md) | Feature-slice internals + shared `core`/`shared` module | 🟡 |
| 3 | [03_feature_boundaries_and_dependencies.md](03_feature_boundaries_and_dependencies.md) | Boundaries, cross-feature dependencies, avoiding coupling | 🔴 |
| 4 | [04_scaling_and_migration.md](04_scaling_and_migration.md) | Scaling to many features; migrating from layer-first; packages | 🔴 |
| 5 | [05_feature_first_integration.md](05_feature_first_integration.md) | Capstone: a feature-first app skeleton | 🟡 |

> **Cross-references:** Clean Architecture (each slice's layers): [Module 40](../40%20Clean%20Architecture/README.md). MVVM (presentation per feature): [Module 43](../43%20MVVM/README.md). Modular architecture (features as packages): [Module 45](../45%20Modular%20Architecture/README.md). DI (per-feature wiring): [Module 14](../14%20Dependency%20Injection/README.md). Routing (per-feature routes): [Module 13](../13%20Routing/README.md). DDD (domain per bounded context): [Module 46](../46%20Domain%20Driven%20Design/README.md).

## Prerequisites

[40 Clean Architecture](../40%20Clean%20Architecture/README.md), [43 MVVM](../43%20MVVM/README.md), [14 Dependency Injection](../14%20Dependency%20Injection/README.md), [13 Routing](../13%20Routing/README.md).

## What you'll be able to do after this module

- Explain feature-first vs layer-first and why cohesion matters at scale.
- Structure a feature slice (domain/data/presentation) + a shared `core` module.
- Define feature boundaries and manage cross-feature dependencies without coupling.
- Scale to many features and migrate a layer-first codebase incrementally.
- Lay out a feature-first app skeleton ready to grow (and later modularize).

## Capstone

**Feature-first skeleton:** A small app organized as `features/` (auth, home, profile — each with domain/data/presentation) + `core/` (theme, DI, routing, shared widgets, `Result`), with per-feature DI + routes, clear boundaries (no direct cross-feature imports; interaction via core/interfaces), and a documented migration/scaling note.

## Summary

Feature-first organizes code by feature (cohesive vertical slices) with a shared `core`, instead of by layer across the app. It makes features independently evolvable and team-ownable, scales Clean/MVVM across many features, keeps boundaries explicit, and is the natural precursor to modular (package-based) architecture.
