# 49 · Testing

## Introduction

This module covers testing Flutter apps properly: the **testing pyramid** (many fast unit tests, fewer widget tests, few integration/E2E tests) and *why*, **unit testing + mocking/fakes + TDD**, **widget testing** (pump/finders/interactions) and **golden tests** (pixel snapshots), **integration/E2E testing** (`integration_test`, driving the real app, `patrol`), and how it all comes together — **testing each architectural layer** + **coverage** + **CI integration**. It's the safety net that makes every other module's architecture, refactoring, and scaling actually safe ([Module 40](../40%20Clean%20Architecture/README.md)–[47](../47%20Scalable%20Applications/README.md), [Module 50](../50%20CI%20CD/README.md)).

## Why this module exists

Untested code can't be safely changed — every refactor, feature, or dependency bump risks silent regressions, so teams either freeze or ship bugs. Tests are what let you **move fast without breaking things**: they document behavior, catch regressions, enable confident refactoring, and gate CI. But testing done wrong (all slow E2E tests, brittle assertions, no isolation) is worse than useless. This module teaches the *right shape* (the pyramid), the tools per layer, and the discipline (isolation, fakes, TDD) that make tests fast, reliable, and valuable — the payoff the whole handbook's testable architecture was built for.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [testing_fundamentals_and_pyramid.md](testing_fundamentals_and_pyramid.md) | Why test, the testing pyramid, test types, what to test | 🔵 |
| 2 | [unit_and_mocking.md](unit_and_mocking.md) | Unit tests, mocks/fakes (mocktail), TDD | 🔴 |
| 3 | [widget_and_golden_tests.md](widget_and_golden_tests.md) | Widget tests (pump/finders/interactions), golden tests | 🔴 |
| 4 | [integration_and_e2e.md](integration_and_e2e.md) | `integration_test`, E2E, driving the app, `patrol` | 🟡 |
| 5 | [testing_integration.md](testing_integration.md) | Capstone: test each layer + coverage + CI | 🔴 |

> **Cross-references:** Architecture (testable layers): [40](../40%20Clean%20Architecture/README.md)/[43](../43%20MVVM/README.md)/[44](../44%20Feature%20First%20Architecture/README.md). CI (run tests): [Module 50](../50%20CI%20CD/README.md). Error handling (test failure paths): [Module 38](../38%20Error%20Handling/README.md). Networking/storage (fakes at boundaries): [Module 16](../16%20Networking/README.md)/[Module 15](../15%20Local%20Storage/README.md). Performance (perf tests): [Module 21](../21%20Performance/README.md). Scalable apps (tests as regression safety): [Module 47](../47%20Scalable%20Applications/README.md).

## Prerequisites

[40 Clean Architecture](../40%20Clean%20Architecture/README.md) (testable layers), [43 MVVM](../43%20MVVM/README.md) (state-sequence tests), [38 Error Handling](../38%20Error%20Handling/README.md), [14 Dependency Injection](../14%20Dependency%20Injection/README.md) (inject fakes).

## What you'll be able to do after this module

- Explain the testing pyramid and choose the right test type per concern.
- Write fast, isolated unit tests with mocks/fakes; practice TDD.
- Write widget tests (pump/finders/interactions) and golden tests.
- Write integration/E2E tests that drive the real app.
- Test each architectural layer, measure coverage meaningfully, and run tests in CI.

## Capstone

**Layered test suite:** For a feature slice (domain/data/presentation), write unit tests (use case with fake repo; data repo with fake sources; view-model state sequences), widget tests (screen states + interactions), a golden test, and one integration test driving the flow — organized by the pyramid, with meaningful coverage and a CI job (`melos`/`flutter test` + `integration_test`) gating merges.

## Summary

Testing = the right shape (pyramid: many unit, some widget, few E2E) + the right tools per layer (unit + mocks/fakes, widget + golden, integration/E2E) + discipline (isolation, fakes, TDD). It's what makes the handbook's testable architecture pay off — enabling confident refactoring, regression safety, and CI gating.
