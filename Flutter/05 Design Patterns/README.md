# 05 · Design Patterns

## Introduction

Design patterns are **named, reusable solutions to recurring design problems**. They're a shared vocabulary ("let's use a Strategy here") and, more importantly, the *applied form* of SOLID. This module covers the classic Gang-of-Four (GoF) patterns across three families, plus two patterns essential to Flutter apps: **Repository** and **Dependency Injection**.

## Why this module exists

Patterns turn SOLID principles ([Module 04](../04%20SOLID%20Principles/README.md)) into concrete structures. Knowing them lets you recognize a problem's shape and reach for a proven solution instead of reinventing (often badly). Interviewers use patterns to test design maturity; codebases use them to stay extensible.

## The three families

```mermaid
flowchart TD
    C["Creational\n(how objects are made)"]
    S["Structural\n(how objects compose)"]
    B["Behavioral\n(how objects interact)"]
    C --> Factory & Builder & Singleton & Prototype
    S --> Adapter & Decorator & Facade & Bridge & Composite & Proxy
    B --> Strategy & Observer & Command & State & Template & Chain & Mediator & Visitor & Iterator
```

## Module map

### Creational (object creation)

| Pattern | Intent | File |
|---------|--------|------|
| Factory (Simple/Method/Abstract) | Create objects without naming concrete classes | [factory.md](factory.md) |
| Builder | Construct complex objects step by step | [builder.md](builder.md) |
| Singleton | One shared instance | [singleton.md](singleton.md) |
| Prototype | Clone existing objects | [prototype.md](prototype.md) |

### Structural (object composition)

| Pattern | Intent | File |
|---------|--------|------|
| Adapter | Make incompatible interfaces work together | [adapter.md](adapter.md) |
| Decorator | Add behavior by wrapping | [decorator.md](decorator.md) |
| Facade | Simplify a complex subsystem | [facade.md](facade.md) |
| Bridge | Decouple abstraction from implementation | [bridge.md](bridge.md) |
| Composite | Treat trees uniformly | [composite.md](composite.md) |
| Proxy | Stand-in controlling access | [proxy.md](proxy.md) |

### Behavioral (object interaction)

| Pattern | Intent | File |
|---------|--------|------|
| Strategy | Swappable algorithms | [strategy.md](strategy.md) |
| Observer | Notify dependents of change | [observer.md](observer.md) |
| Command | Encapsulate a request as an object | [command.md](command.md) |
| State | Behavior varies with internal state | [state.md](state.md) |
| Template Method | Fixed skeleton, variable steps | [template_method.md](template_method.md) |
| Chain of Responsibility | Pass a request along handlers | [chain_of_responsibility.md](chain_of_responsibility.md) |
| Mediator | Centralize complex communication | [mediator.md](mediator.md) |
| Visitor | Add operations without editing types | [visitor.md](visitor.md) |
| Iterator | Traverse without exposing internals | [iterator.md](iterator.md) |

### Application patterns (Flutter-critical)

| Pattern | Intent | File |
|---------|--------|------|
| Repository | Abstract data access behind a clean API | [repository.md](repository.md) |
| Dependency Injection | Supply dependencies from outside | [dependency_injection.md](dependency_injection.md) |

## Prerequisites

[03 OOP](../03%20Object%20Oriented%20Programming/README.md) and [04 SOLID](../04%20SOLID%20Principles/README.md). Patterns are OOP + SOLID applied.

## How each file is structured

Beyond the standard template, each pattern file states: the **problem it solves**, a **UML diagram**, a **Dart implementation**, a **Flutter/real-world usage**, and **when NOT to use it** (patterns are tools, not goals).

## What you'll be able to do after this module

- Recognize which pattern fits a problem — and when *no* pattern is the right answer.
- Implement each idiomatically in Dart (using records, sealed classes, closures where they simplify the classic form).
- Explain where Flutter/its ecosystem already uses these (e.g., Builder in widget builders, Observer in `ChangeNotifier`, Strategy in `ScrollPhysics`).

## Summary

Patterns are the applied vocabulary of good design. Learn the intent and the smell each addresses; implement them in Dart; and resist over-engineering — reach for a pattern when the problem actually has its shape.
