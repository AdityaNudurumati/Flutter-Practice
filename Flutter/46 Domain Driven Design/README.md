# 46 · Domain-Driven Design

## Introduction

This module covers **Domain-Driven Design (DDD)** for Flutter: the **strategic** side (ubiquitous language, bounded contexts, context mapping) and the **tactical** building blocks (entities, **value objects**, **aggregates** + aggregate roots, domain services, **domain events**, DDD-flavored repositories, application services), plus the crucial judgment of **when DDD is worth it**. It walks fundamentals → tactical patterns → aggregates/invariants → repositories/events → a capstone modeling one bounded context. It deepens the domain layer of Clean Architecture ([Module 40](../40%20Clean%20Architecture/README.md)) and pairs with modular/feature-first (module/feature per bounded context — [Module 44](../44%20Feature%20First%20Architecture/README.md)/[Module 45](../45%20Modular%20Architecture/README.md)).

## Why this module exists

Most apps have simple domains where CRUD + basic entities suffice — but **complex domains** (finance, logistics, insurance, healthcare) have rich rules, ambiguous terminology, and tangled invariants that a thin model can't tame. DDD is the toolkit for **taming domain complexity**: a shared **ubiquitous language**, explicit **bounded contexts**, and a rich model (aggregates enforcing invariants, value objects making illegal states unrepresentable). Applied where warranted it's transformative; applied to a CRUD app it's overkill — so the module teaches both the patterns and the discernment.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [ddd_fundamentals.md](ddd_fundamentals.md) | Ubiquitous language, bounded contexts, context mapping, when DDD pays | 🔴 |
| 2 | [tactical_building_blocks.md](tactical_building_blocks.md) | Entities, value objects, domain services, factories | 🔴 |
| 3 | [aggregates_and_invariants.md](aggregates_and_invariants.md) | Aggregates, aggregate roots, consistency boundaries, invariants | 🔴 |
| 4 | [repositories_and_domain_events.md](repositories_and_domain_events.md) | DDD repositories, domain events, application services | 🔴 |
| 5 | [ddd_integration.md](ddd_integration.md) | Capstone: model one bounded context | 🔴 |

> **Cross-references:** Clean Architecture (domain layer): [Module 40](../40%20Clean%20Architecture/README.md). Feature-first / modular (context = feature/module): [Module 44](../44%20Feature%20First%20Architecture/README.md)/[Module 45](../45%20Modular%20Architecture/README.md). OOP (entities/objects): [Module 03](../03%20OOP/README.md). Error handling (`Result`/invariants): [Module 38](../38%20Error%20Handling/README.md). Immutability/value objects: [Module 02](../02%20Advanced%20Dart/README.md).

## Prerequisites

[40 Clean Architecture](../40%20Clean%20Architecture/README.md) (domain layer), [03 OOP](../03%20OOP/README.md), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (immutability), [38 Error Handling](../38%20Error%20Handling/README.md) (`Result`), [44/45](../44%20Feature%20First%20Architecture/README.md) (contexts as features/modules).

## What you'll be able to do after this module

- Build a ubiquitous language and split a domain into bounded contexts (+ context map).
- Model with entities, value objects, aggregates, domain services, and factories.
- Define aggregate roots + consistency boundaries that enforce invariants.
- Use DDD repositories, domain events, and application services correctly.
- Decide when DDD is worth it and apply it proportionally in Flutter.

## Capstone

**Bounded-context model:** Model an "Ordering" context — value objects (`Money`, `Quantity`, `Address`), entities, an `Order` **aggregate** (root enforcing invariants: totals, status transitions), a domain service, a DDD **repository interface** (aggregate-granular), and **domain events** (`OrderPlaced`) — pure Dart, unit-tested, with a documented ubiquitous language and a note on how it maps to a feature/module.

## Summary

DDD tames complex domains via a shared ubiquitous language, explicit bounded contexts, and a rich tactical model (value objects, entities, aggregates enforcing invariants, domain events, repositories). It deepens Clean Architecture's domain layer and maps to features/modules — powerful for complex domains, overkill for CRUD, so applied with judgment.
