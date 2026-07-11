# 56 · Machine Coding Rounds

## Introduction

This module covers the **machine-coding round** — a timed (typically 60–120 min) interview where you **build a small working Flutter feature/app** and are judged on **functionality + code quality + structure**, not just "does it run." It walks the **fundamentals** (format, evaluation criteria, mindset), the **approach & time management** (scope → plan → build incrementally → polish), **clean architecture under time pressure** (right-sized structure, state-management choice, separation without over-engineering), **common problems + patterns** (todo/timer/search/form/paginated list…), and a **worked-round capstone**. It applies state management ([Module 11](../11%20State%20Management/README.md)), MVVM/Clean ([Module 43](../43%20MVVM/README.md)/[Module 40](../40%20Clean%20Architecture/README.md)), and testing ([Module 49](../49%20Testing/README.md)) under a clock.

## Why this module exists

Machine coding is where strong engineers **win or lose offers**: it's not about clever algorithms but about **shipping a clean, working feature fast** — scoping requirements, picking the right state approach, structuring code that's readable and extensible, handling edge cases, and communicating throughout — all under time pressure. Common failures are **over-engineering** (no time to finish), **under-structuring** (a god-widget mess), **poor scoping** (building the wrong thing), and **not finishing**. This module gives the approach, the right-sized architecture, and the practiced patterns to consistently produce a solid submission.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [machine_coding_fundamentals.md](machine_coding_fundamentals.md) | Format, evaluation criteria, mindset | 🔵 |
| 2 | [approach_and_time_management.md](approach_and_time_management.md) | Scope → plan → incremental build → polish; time-boxing | 🔴 |
| 3 | [clean_architecture_under_pressure.md](clean_architecture_under_pressure.md) | Right-sized structure, state choice, separation w/o over-engineering | 🔴 |
| 4 | [common_problems_and_patterns.md](common_problems_and_patterns.md) | Common problems (todo/timer/search/form/list) + reusable patterns | 🟡 |
| 5 | [machine_coding_integration.md](machine_coding_integration.md) | Capstone: a worked machine-coding round | 🔴 |

> **Cross-references:** Interview prep (round context): [Module 55](../55%20Flutter%20Interview%20Preparation/README.md). State management: [Module 11](../11%20State%20Management/README.md). MVVM/Clean (right-sized): [Module 43](../43%20MVVM/README.md)/[Module 40](../40%20Clean%20Architecture/README.md). Testing: [Module 49](../49%20Testing/README.md). Networking (if API-backed): [Module 16](../16%20Networking/README.md). Error handling: [Module 38](../38%20Error%20Handling/README.md).

## Prerequisites

[55 Flutter Interview Preparation](../55%20Flutter%20Interview%20Preparation/README.md), [11 State Management](../11%20State%20Management/README.md), [43 MVVM](../43%20MVVM/README.md), [40 Clean Architecture](../40%20Clean%20Architecture/README.md), [49 Testing](../49%20Testing/README.md).

## What you'll be able to do after this module

- Explain the machine-coding format + how it's evaluated, with the right mindset.
- Run a reliable approach: scope, plan, build incrementally, and polish within the time box.
- Apply right-sized architecture (state choice + separation) without over-engineering.
- Recognize + solve common machine-coding problems with reusable patterns.
- Execute a full worked round that finishes a clean, working, extensible feature.

## Capstone

**Worked round:** A full simulated machine-coding round for a common prompt (e.g., a searchable/paginated list or a todo app) — clarify + scope, plan the increments, build a working feature with right-sized architecture (state management + clean separation), handle edge cases (loading/empty/error), add a light test or two, and communicate throughout — finished within a realistic time box, with a reflection on the evaluation criteria.

## Summary

Machine coding tests shipping a clean, working feature fast: scope tightly, pick the right state approach, structure code right-sized (not over/under-engineered), handle edge cases, finish, and communicate. Practicing the approach + common patterns turns time pressure into a consistent, offer-winning submission.
