# 03 · Object Oriented Programming

## Introduction

OOP is how you **model a domain** in Dart: turning real-world concepts (a user, an account, a payment) into classes with state, behavior, and relationships. Flutter itself is deeply OO — every widget, element, and render object is a class in a hierarchy. This module teaches OOP as a *design* skill, not just syntax.

## Why this module exists

Interviewers probe OOP because it reveals whether you can structure code that scales: encapsulation that protects invariants, inheritance vs composition tradeoffs, polymorphism for extensibility, and correct equality/identity. These decisions determine whether a codebase stays maintainable at 50k+ lines.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_classes_and_objects.md](01_classes_and_objects.md) | Classes, objects, fields, methods, `static`, `this`, lifecycle, memory layout | 🟢 |
| 2 | [02_encapsulation.md](02_encapsulation.md) | Privacy (`_`), getters/setters, protecting invariants | 🟢 |
| 3 | [03_inheritance.md](03_inheritance.md) | `extends`, `super`, `@override`, abstract base classes | 🔵 |
| 4 | [04_polymorphism.md](04_polymorphism.md) | Dynamic dispatch, method overriding, Liskov substitution | 🔵 |
| 5 | [05_abstraction_and_interfaces.md](05_abstraction_and_interfaces.md) | Abstract classes, implicit interfaces, `implements`, `sealed` | 🔵 |
| 6 | [06_composition_and_relationships.md](06_composition_and_relationships.md) | Composition vs inheritance, aggregation, association, mixin-vs-composition | 🔵 |
| 7 | [07_equality_and_copying.md](07_equality_and_copying.md) | `==`/`hashCode`, identity, deep vs shallow copy | 🔵 |

> **Cross-references:** Constructors (named/factory/private/`const`) and **mixins** are covered in depth in [02 Advanced Dart](../02%20Advanced%20Dart/README.md) ([09_constructors_and_singletons.md](../02%20Advanced%20Dart/09_constructors_and_singletons.md), [06_mixins.md](../02%20Advanced%20Dart/06_mixins.md)). Dependency Injection has its own module ([14](../14%20Dependency%20Injection/README.md)). Immutability/value equality tooling is in [10_immutability.md](../02%20Advanced%20Dart/10_immutability.md).

## Prerequisites

[01 Dart Fundamentals](../01%20Dart%20Fundamentals/README.md) and the constructors/mixins/immutability files of [02 Advanced Dart](../02%20Advanced%20Dart/README.md).

## What you'll be able to do after this module

- Model a domain with well-encapsulated classes that protect their invariants.
- Choose **composition over inheritance** deliberately and justify it.
- Use abstract classes, interfaces, and sealed types to design for extension.
- Implement correct value equality and understand deep vs shallow copy.
- Explain dynamic dispatch and the Liskov Substitution Principle (bridge to [SOLID, Module 04](../04%20SOLID%20Principles/README.md)).

## Capstones

| Tier | Build |
|------|-------|
| Beginner | A `Shape` hierarchy (area/perimeter) with polymorphism. |
| Intermediate | A `BankAccount → SavingsAccount` domain with encapsulated invariants + custom exceptions. |
| Advanced | A `PaymentMethod` design using sealed classes + composition. |
| Enterprise | A small **domain model** (orders/inventory) with value objects, aggregates, and equality (feeds [DDD, Module 46](../46%20Domain%20Driven%20Design/README.md)). |

## Summary

OOP here is about *design judgment*: encapsulate to protect invariants, prefer composition, use polymorphism and abstraction for extensibility, and get equality/identity right. These are the foundations for SOLID, design patterns, and clean architecture.
