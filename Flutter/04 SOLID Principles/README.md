# 04 · SOLID Principles

## Introduction

SOLID is five design principles that keep object-oriented code **flexible, testable, and maintainable** as it grows. They're not academic trivia — they're the reasoning senior engineers use to decide where to draw boundaries, what to abstract, and how to avoid the "change one thing, break five" trap. This module teaches each with a **wrong implementation, a corrected one, a Flutter example, and an enterprise example**.

## Why this module exists

Most large codebases don't rot from bad syntax — they rot from bad *structure*: God classes, rigid `if/else` type checks, leaky abstractions, fat interfaces, and hard-wired dependencies. SOLID is the antidote. Interviewers ask about SOLID because it predicts whether you'll build systems that survive change.

## The five principles

| Letter | Principle | One-line intent | File |
|--------|-----------|-----------------|------|
| **S** | Single Responsibility | A class should have one reason to change | [srp_single_responsibility.md](srp_single_responsibility.md) |
| **O** | Open/Closed | Open for extension, closed for modification | [ocp_open_closed.md](ocp_open_closed.md) |
| **L** | Liskov Substitution | Subtypes must be usable as their base | [lsp_liskov_substitution.md](lsp_liskov_substitution.md) |
| **I** | Interface Segregation | No client forced to depend on unused methods | [isp_interface_segregation.md](isp_interface_segregation.md) |
| **D** | Dependency Inversion | Depend on abstractions, not concretions | [dip_dependency_inversion.md](dip_dependency_inversion.md) |

```mermaid
flowchart LR
    S[SRP: cohesion] --> O[OCP: extend w/o edit]
    O --> L[LSP: safe substitution]
    L --> I[ISP: lean interfaces]
    I --> D[DIP: invert dependencies]
    D -.enables.-> O
```

The principles reinforce each other: DIP + polymorphism ([Module 03](../03%20Object%20Oriented%20Programming/polymorphism.md)) make OCP possible; ISP keeps LSP honest; SRP makes all of them easier.

## Prerequisites

[03 OOP](../03%20Object%20Oriented%20Programming/README.md) — especially abstraction/interfaces, polymorphism, and composition. SOLID is applied OOP.

## What you'll be able to do after this module

- Spot SOLID violations in a code review and name the fix.
- Refactor a God class/rigid hierarchy into cohesive, extensible components.
- Justify architectural boundaries (why an interface here, why inject there).
- Connect SOLID to design patterns ([Module 05](../05%20Design%20Patterns/README.md)) and Clean Architecture ([Module 40](../40%20Clean%20Architecture/README.md)).

## How each file is structured

Beyond the standard template, every principle file includes a **❌ Violation → ✅ Refactor** pair, a **Flutter example**, and an **enterprise example**, plus the smells that signal the violation.

## Capstone

**SOLID refactor kata:** Take a deliberately bad "order service" (a God class that parses, validates, saves, emails, logs, and formats — with `if (type == ...)` branching and `new` dependencies everywhere) and refactor it to satisfy all five principles. Provided in [dip_dependency_inversion.md](dip_dependency_inversion.md#mini-project) as the culminating mini-project.

## Summary

SOLID is the bridge from "knows OOP syntax" to "designs maintainable systems." Read the files in order (they build on each other), do each refactor, and you'll internalize the judgment behind clean architecture and design patterns.
