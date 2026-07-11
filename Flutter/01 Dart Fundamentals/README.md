# 01 · Dart Fundamentals

## Introduction

Flutter is written in **Dart**, so fluency in Dart is non-negotiable. This module builds that fluency from first principles — not "here's the syntax," but *why the language is shaped this way* and *what the compiler and VM do with your code*. Master this and every later module (widgets, state, architecture) rests on solid ground.

## Why this module exists

You cannot reason about Flutter performance, rebuilds, or memory without understanding Dart's type system, null safety, and value/reference semantics. Interviewers at top companies probe these fundamentals precisely because they predict whether you'll write correct, efficient UI code.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [variables_and_mutability.md](variables_and_mutability.md) | `var` / `final` / `const` / `late`, type inference | 🟢 |
| 2 | [data_types.md](data_types.md) | `num`/`int`/`double`, `String`, `bool`, `dynamic`, `Object?` | 🟢 |
| 3 | [operators.md](operators.md) | Arithmetic, logical, null-aware, cascade, spread | 🟢 |
| 4 | [control_flow.md](control_flow.md) | `if`/`for`/`while`/`switch`, collection-if/for | 🟢 |
| 5 | [functions.md](functions.md) | Params, arrow, closures, higher-order, `typedef` | 🟢 |
| 6 | [collections.md](collections.md) | `List`/`Set`/`Map`/`Iterable`/`Queue`, lazy ops | 🟢 |
| 7 | [null_safety.md](null_safety.md) | `?`/`!`/`??`/`??=`/`late`, sound null safety, flow analysis | 🟢 |
| 8 | [enums.md](enums.md) | Basic & enhanced enums | 🟢 |
| 9 | [records_and_patterns.md](records_and_patterns.md) | Records, pattern matching, destructuring (Dart 3) | 🟢 |
| 10 | [exception_handling.md](exception_handling.md) | `throw`/`try`/`catch`/`on`/`finally`, custom exceptions | 🟢 |

> Async, `Future`, `Stream`, the event loop, isolates, generics-in-depth, mixins, extensions, and the Dart VM/AOT/JIT pipeline are covered in **[02 Advanced Dart](../02%20Advanced%20Dart/README.md)** and **[03 OOP](../03%20Object%20Oriented%20Programming/README.md)**.

## Prerequisites

None. This is the entry point. If you can install the Dart SDK and run `dart run file.dart`, you're ready.

## What you'll be able to do after this module

- Choose `var`/`final`/`const`/`late` correctly and explain the difference to an interviewer.
- Read and write null-safe Dart fluently, including flow analysis and promotion.
- Use collections and their lazy `Iterable` methods idiomatically.
- Model data with records, enums, and patterns (Dart 3).
- Handle errors with typed, meaningful exceptions.

## Capstones

| Tier | Build |
|------|-------|
| Beginner | A pure-Dart CLI **contact book** (add/list/search) using collections + null safety. |
| Intermediate | A **CSV report parser** using records, patterns, and exception handling. |
| Advanced | A tiny **expression evaluator** using enums + patterns. |
| Enterprise | A reusable **`Result<T,E>` + validation library** (feeds Module 38). |

## Summary

Module 01 gives you the language substrate. Read the files in order; each is self-contained and follows the handbook template. Finish with the Revision Notes of every file before moving to Advanced Dart.
