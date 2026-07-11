# 45 · Modular Architecture

## Introduction

This module covers **modular architecture** — taking feature-first organization ([Module 44](../44%20Feature%20First%20Architecture/README.md)) to its conclusion by making each feature (and `core`) a **separate Dart/Flutter package** with **compiler-enforced boundaries** and its own dependencies. It walks the **fundamentals** (packages as hard boundaries, why/when), **monorepo management with melos** (workspace, path deps, scripts), **module boundaries & contracts** (package exports/public API, dependency graph, contract packages), and **build/versioning/team benefits** — with a capstone. It's the formalization of feature-first and the bridge to enterprise-scale and DDD ([Module 46](../46%20Domain%20Driven%20Design/README.md), [Module 47](../47%20Scalable%20Applications/README.md)).

## Why this module exists

Feature-first folders rely on **discipline/lints** to keep boundaries — which erode silently. Turning features into **packages** makes boundaries **compiler-enforced** (a package literally cannot import another's private code), unlocks **incremental/parallel builds** (only changed packages rebuild), enables **independent versioning/ownership**, and allows **reuse across apps**. But modularity adds real overhead (workspace tooling, contract design, wiring), so it must be adopted **when the scale justifies it** — the module teaches both the how and the when.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [modular_fundamentals.md](modular_fundamentals.md) | Packages as hard boundaries, why/when to modularize | 🔴 |
| 2 | [monorepo_and_melos.md](monorepo_and_melos.md) | Monorepo layout, melos, path deps, workspace scripts | 🔴 |
| 3 | [module_boundaries_and_contracts.md](module_boundaries_and_contracts.md) | Package exports/public API, contracts, dependency graph | 🔴 |
| 4 | [build_versioning_and_teams.md](build_versioning_and_teams.md) | Build speed, versioning, ownership, CI | 🟡 |
| 5 | [modular_integration.md](modular_integration.md) | Capstone: a modular monorepo skeleton | 🔴 |

> **Cross-references:** Feature-first (the precursor): [Module 44](../44%20Feature%20First%20Architecture/README.md). Clean Architecture (module internals): [Module 40](../40%20Clean%20Architecture/README.md). DI (cross-module wiring): [Module 14](../14%20Dependency%20Injection/README.md). DDD (module per bounded context): [Module 46](../46%20Domain%20Driven%20Design/README.md). Scalable apps: [Module 47](../47%20Scalable%20Applications/README.md). CI/CD: [Module 50](../50%20CI%20CD/README.md).

## Prerequisites

[44 Feature First Architecture](../44%20Feature%20First%20Architecture/README.md), [40 Clean Architecture](../40%20Clean%20Architecture/README.md), [14 Dependency Injection](../14%20Dependency%20Injection/README.md), Dart package/pubspec basics.

## What you'll be able to do after this module

- Explain packages as compiler-enforced boundaries and decide when modularization is justified.
- Structure a monorepo and manage it with melos (path deps, bootstrap, scripts).
- Design module public APIs (exports/barrels), contract packages, and an acyclic dependency graph.
- Reason about build speed, versioning, ownership, and CI implications of modules.
- Lay out a modular monorepo skeleton (app + feature packages + core/contracts).

## Capstone

**Modular monorepo skeleton:** A melos workspace with an `app` package depending on feature packages (`feature_auth`, `feature_cart`) + shared packages (`core`, `contracts`), each a Clean slice with a controlled public API (`export`s), an acyclic dependency graph (features → core/contracts, never each other), cross-module wiring via contracts + DI, and workspace scripts (bootstrap/analyze/test) — with a documented "when to modularize" rationale.

## Summary

Modular architecture makes features **packages** with **compiler-enforced boundaries**, managed in a **monorepo (melos)**: hard isolation, incremental/parallel builds, independent versioning/ownership, cross-app reuse. Modules expose controlled public APIs and interact via contract packages + DI on an acyclic graph. Powerful but with overhead — adopt when scale (build time, team count, reuse) justifies it.
