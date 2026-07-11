# 52 · Monitoring

## Introduction

This module covers **observing a live Flutter app**: the **fundamentals** (monitoring vs observability, the three pillars — logs/metrics/traces), **crash reporting** (Crashlytics/Sentry, crash-free rate, symbolication, breadcrumbs), **analytics & custom metrics** (product events, funnels, privacy), and **performance monitoring & alerting** (startup/frames/network SLIs, dashboards, alerts, SLOs) — tied together into a **feedback loop** that turns production signals into action. It closes the delivery cycle after deployment ([Module 51](../51%20Deployment/README.md)), consuming the logging you set up ([Module 39](../39%20Logging/README.md)) and enforcing the performance budgets you defined ([Module 21](../21%20Performance/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)).

## Why this module exists

Once an app is live on thousands of uncontrolled devices, **you can't see what's happening without instrumentation** — crashes, slow screens, dropped funnels, and errors are invisible until users complain (or leave). Monitoring makes production **observable**: it captures crashes with context, measures usage + performance, alerts you to regressions, and **closes the loop** so you fix and improve based on real data instead of guesses. It's what makes staged rollouts safe, launches sustainable, and the whole build→ship pipeline *learn*.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [monitoring_fundamentals.md](monitoring_fundamentals.md) | Monitoring vs observability; logs/metrics/traces; the feedback loop | 🔴 |
| 2 | [crash_reporting.md](crash_reporting.md) | Crashlytics/Sentry, crash-free rate, symbolication, breadcrumbs | 🔴 |
| 3 | [analytics_and_metrics.md](analytics_and_metrics.md) | Product analytics, events, funnels, custom metrics, privacy | 🟡 |
| 4 | [performance_monitoring_and_alerting.md](performance_monitoring_and_alerting.md) | Perf monitoring (startup/frames/network), SLIs/SLOs, dashboards, alerts | 🔴 |
| 5 | [monitoring_integration.md](monitoring_integration.md) | Capstone: full observability + feedback loop | 🔴 |

> **Cross-references:** Logging (feeds monitoring): [Module 39](../39%20Logging/README.md). Error handling (report failures): [Module 38](../38%20Error%20Handling/README.md). Deployment/staged rollout (monitored): [Module 51](../51%20Deployment/README.md). Performance budgets: [Module 21](../21%20Performance/README.md)/[Module 47](../47%20Scalable%20Applications/README.md). Firebase (Crashlytics/Analytics/Performance): [Module 18](../18%20Firebase/README.md). Security (no PII in telemetry): [Module 37](../37%20Security/README.md).

## Prerequisites

[39 Logging](../39%20Logging/README.md), [38 Error Handling](../38%20Error%20Handling/README.md), [51 Deployment](../51%20Deployment/README.md), [21 Performance](../21%20Performance/README.md), [18 Firebase](../18%20Firebase/README.md) (Crashlytics/Analytics/Performance).

## What you'll be able to do after this module

- Explain observability, the three pillars, and the monitoring feedback loop.
- Set up crash reporting with symbolication, breadcrumbs, and crash-free-rate tracking.
- Instrument product analytics + custom metrics (privacy-respecting).
- Monitor performance (startup/frames/network), define SLIs/SLOs, and alert on regressions.
- Assemble a full observability stack that closes the loop from production signals to action.

## Capstone

**Observability stack:** For an app, wire crash reporting (Crashlytics/Sentry with symbolication + breadcrumbs + correlation ids), analytics (key events + a conversion funnel, PII-safe), and performance monitoring (startup/frame/network SLIs), with dashboards, alerts on regressions (crash-free rate / SLO breach), and a documented feedback loop (staged-rollout gate → triage → fix → iterate).

## Summary

Monitoring makes a live app observable via logs/metrics/traces: crash reporting (with symbolication + context), analytics/custom metrics (privacy-safe), and performance monitoring with SLIs/SLOs + alerting. It closes the feedback loop — turning real production signals into safe rollouts, fast fixes, and data-driven iteration — completing the build→ship→observe→improve cycle.
