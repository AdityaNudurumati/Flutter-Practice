# 39 · Logging

## Introduction

This module covers logging done right in Flutter: **fundamentals** (why logging matters, log levels, structured vs string logs, `print` vs `dart:developer` vs a logging package), **the `logger` package & setup** (formatting, filters, dev-vs-prod configuration behind an abstraction), **production logging & redaction** (never log PII/secrets, sampling, performance, security), and **remote logging & observability** (remote sinks, crash-report integration, correlation ids, breadcrumbs/tracing) — tied together in a capstone. It complements error handling ([Module 38](../38%20Error%20Handling/README.md)) and monitoring ([Module 52](../52%20Monitoring/README.md)).

## Why this module exists

You can't fix what you can't see. Logging is how you understand behavior in dev *and* — critically — in production where you can't attach a debugger. But naive logging causes real harm: `print` everywhere bloats and slows apps, logging tokens/PII is a **security and compliance breach**, and unstructured string logs are useless at scale. Good logging is deliberate: leveled, structured, redacted, environment-aware, and wired to observability — so you can debug production without leaking data or degrading performance.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [logging_fundamentals.md](logging_fundamentals.md) | Why log, log levels, structured logging, `print`/`log`/package | 🔵 |
| 2 | [logger_package_and_setup.md](logger_package_and_setup.md) | `logger` package, formatting, filters, dev-vs-prod behind an abstraction | 🟡 |
| 3 | [production_logging_and_redaction.md](production_logging_and_redaction.md) | PII/secret redaction, what not to log, sampling, performance, security | 🔴 |
| 4 | [remote_logging_and_observability.md](remote_logging_and_observability.md) | Remote sinks, crash-report integration, correlation ids, breadcrumbs/tracing | 🔴 |
| 5 | [logging_integration.md](logging_integration.md) | Capstone: a logging facade across environments | 🔴 |

> **Cross-references:** Error handling (log on failure): [Module 38](../38%20Error%20Handling/README.md). Monitoring/crash reporting: [Module 52](../52%20Monitoring/README.md). Security (never log secrets): [Module 37](../37%20Security/README.md). Networking (request/response logging): [Module 16](../16%20Networking/README.md). DI (inject the logger): [Module 14](../14%20Dependency%20Injection/README.md). App size/perf (strip logs): [Module 21](../21%20Performance/README.md).

## Prerequisites

[38 Error Handling](../38%20Error%20Handling/README.md), [37 Security](../37%20Security/README.md) (redaction), [14 Dependency Injection](../14%20Dependency%20Injection/README.md), basic app architecture.

## What you'll be able to do after this module

- Use log levels and structured logging instead of scattered `print`s.
- Configure the `logger` package with dev-vs-prod behavior behind an abstraction.
- Redact PII/secrets, sample, and keep logging cheap and compliant in production.
- Ship logs/breadcrumbs to remote sinks and correlate them with crash reports and traces.
- Wire a single logging facade across environments that's testable and observable.

## Capstone

**Logging slice:** A logging facade (interface) with a pretty console logger in dev and a redacting, sampled, remote-shipping logger in prod, integrated with the crash reporter (breadcrumbs + correlation ids), used across layers (with a `dio` request logger) — PII-safe, performant, and testable.

## Summary

Logging = deliberate visibility: leveled + structured logs behind a facade, environment-aware (verbose dev, redacted/sampled/remote prod), never leaking PII/secrets, and correlated with crash reporting and traces. It's how you debug production safely — the observability complement to error handling.
