# 38 · Error Handling

## Introduction

This module covers handling failure well in Flutter/Dart: the **errors-vs-exceptions distinction** (bugs you shouldn't catch vs conditions you should), **functional error handling** (`Result`/`Either`/sealed classes — making failure explicit in the type system), **global error handling** (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`, widget error boundaries), and **recovery & user-facing errors** (retry/backoff, graceful degradation, mapping technical failures to helpful messages), tied together in a capstone. It threads through networking ([Module 16](../16%20Networking/README.md)), state management ([Module 11](../11%20State%20Management/README.md)), monitoring ([Module 52](../52%20Monitoring/README.md)), and clean architecture ([Module 40](../40%20Clean%20Architecture/README.md)).

## Why this module exists

Real apps fail constantly — networks drop, APIs 500, files vanish, inputs are bad. The difference between a fragile app and a resilient one is a **deliberate error strategy**: knowing which failures are recoverable, modeling them explicitly so they can't be forgotten, catching uncaught errors globally (so nothing crashes silently), and turning failures into clear user experiences instead of red screens or infinite spinners. Ad hoc `try/catch` scattered everywhere is how apps become unmaintainable and users get stuck.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_errors_vs_exceptions.md](01_errors_vs_exceptions.md) | Dart `Error` vs `Exception`, throw/catch, custom exceptions, when to catch | 🔵 |
| 2 | [02_result_and_either.md](02_result_and_either.md) | `Result`/`Either`/sealed classes, explicit failure in types | 🔴 |
| 3 | [03_global_error_handling.md](03_global_error_handling.md) | `FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`, error boundaries | 🔴 |
| 4 | [04_recovery_and_user_errors.md](04_recovery_and_user_errors.md) | Retry/backoff, graceful degradation, error→message mapping, error UX | 🟡 |
| 5 | [05_error_integration.md](05_error_integration.md) | Capstone: an error strategy across layers | 🔴 |

> **Cross-references:** Networking failures/retries: [Module 16](../16%20Networking/README.md). State (error states): [Module 11](../11%20State%20Management/README.md). Monitoring/crash reporting: [Module 52](../52%20Monitoring/README.md). Logging: [Module 39](../39%20Logging/README.md). Clean architecture (where errors map): [Module 40](../40%20Clean%20Architecture/README.md). Offline (failure as normal): [Module 19](../19%20Offline%20First/README.md).

## Prerequisites

[02 Advanced Dart](../02%20Advanced%20Dart/README.md) (async/futures/streams), [11 State Management](../11%20State%20Management/README.md), [16 Networking](../16%20Networking/README.md).

## What you'll be able to do after this module

- Distinguish errors (bugs) from exceptions (conditions) and catch the right things.
- Model expected failures explicitly with `Result`/`Either`/sealed classes.
- Catch all uncaught errors globally and add widget-level error boundaries.
- Implement retry/backoff, graceful degradation, and clear user-facing error messages.
- Compose a coherent, layered error strategy that's observable and testable.

## Capstone

**Error strategy slice:** A feature where the data layer returns typed `Result`/failures (no leaking exceptions), the domain maps them to user-meaningful errors, the UI renders error states with retry, a global handler + `runZonedGuarded` capture anything uncaught (reported to monitoring), and a widget error boundary prevents a single widget crash from taking down the screen — all consistent and testable.

## Summary

Error handling = a deliberate strategy, not scattered `try/catch`: distinguish bugs from conditions, model expected failures in the type system (`Result`/`Either`), catch everything uncaught globally, and turn failures into recovery + clear UX. Layer it (data→domain→UI), make it observable (monitoring/logging), and test the failure paths.
