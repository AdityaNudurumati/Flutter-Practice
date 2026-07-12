# 14 · Dependency Injection

## Introduction

This module covers **how to do DI in Flutter apps** — the practical tooling that realizes the DI *pattern* from [Module 05](../05%20Design%20Patterns/21_dependency_injection.md). It compares `get_it`/`injectable`, Provider/Riverpod as DI, and `InheritedWidget`-based DI, plus scopes/lifetimes and testing with injected fakes.

## Why this module exists

Every non-trivial app must wire repositories, services, clients, and view models to their consumers — testably and consistently. Choosing and using a DI approach determines testability, modularity, and how easily you swap implementations (real/fake/flavors). It's the connective tissue of clean architecture.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_di_fundamentals.md](01_di_fundamentals.md) | Composition root, DI vs service locator, in Flutter | 🔵 |
| 2 | [02_get_it_and_injectable.md](02_get_it_and_injectable.md) | `get_it` service locator + `injectable` codegen | 🔵 |
| 3 | [03_provider_riverpod_as_di.md](03_provider_riverpod_as_di.md) | Provider/Riverpod as DI containers | 🔵 |
| 4 | [04_scopes_and_lifetimes.md](04_scopes_and_lifetimes.md) | Singleton/factory/lazy/scoped + disposal | 🔴 |
| 5 | [05_testing_with_di.md](05_testing_with_di.md) | Injecting fakes/mocks, overrides | 🔴 |

> **Cross-references:** DI pattern + DIP: [05 · dependency_injection](../05%20Design%20Patterns/21_dependency_injection.md), [04 · DIP](../04%20SOLID%20Principles/05_dip_dependency_inversion.md). Providers as state: [Module 11](../11%20State%20Management/README.md). Singletons: [05 · singleton](../05%20Design%20Patterns/03_singleton.md). App entry/composition root: [06 · app_entry_point](../06%20Flutter%20Fundamentals/07_app_entry_point.md), [10 · embedder_and_startup](../10%20Flutter%20Architecture/05_embedder_and_startup.md). Testing: [Module 49](../49%20Testing/README.md).

## Prerequisites

[04 SOLID (DIP)](../04%20SOLID%20Principles/05_dip_dependency_inversion.md), [05 Design Patterns (DI/Singleton)](../05%20Design%20Patterns/21_dependency_injection.md), [11 State Management](../11%20State%20Management/README.md).

## What you'll be able to do after this module

- Set up a composition root and choose constructor injection vs service locator.
- Wire dependencies with `get_it`/`injectable`, Provider, or Riverpod.
- Manage lifetimes (singleton/factory/lazy/scoped) and disposal.
- Inject fakes/mocks to make code fully testable.
- Support build flavors (dev/prod/mock) via DI.

## Capstone

**Wired, testable app slice:** Wire a `Repository → UseCase → ViewModel` graph with a chosen DI approach, register real impls at a composition root, and run the same use case in tests with injected fakes — proving swap-ability and testability.

## Summary

DI in Flutter = choosing a mechanism (`get_it`/Riverpod/Provider) to supply abstractions to consumers, wired at a composition root, with managed lifetimes and testable via fakes. The pattern (Module 05) is the *why*; this module is the *how*.
