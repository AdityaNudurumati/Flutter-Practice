# 33 · Background Services

## Introduction

This module covers running work when your app **isn't in the foreground**: the **background execution model** (why the OS restricts it, background isolates, platform differences), **`workmanager`** for deferrable/periodic tasks with constraints, **Android foreground services** for user-visible ongoing work (location tracking, playback) with a persistent notification, **iOS background execution** (`BGTaskScheduler`, background fetch/processing, silent push — all strictly metered), and a capstone tying them behind a service. It builds on isolates ([Module 02](../02%20Advanced%20Dart/04_isolates.md)), notifications ([Module 32](../32%20Notifications/README.md)), and native setup ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)).

## Why this module exists

Sync, uploads, geofencing, and periodic refresh need to run without the UI open — but mobile OSes **aggressively restrict background work to protect battery**. The rules differ sharply by platform (Android WorkManager/foreground services vs iOS's tightly-metered `BGTaskScheduler`), tasks run in a **separate isolate** with no UI/state access, and OEM battery optimizations make timing unreliable. Knowing what's *possible*, *guaranteed*, and *forbidden* is essential to avoid building features the OS will silently kill.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_background_execution_model.md](01_background_execution_model.md) | Why background is restricted, background isolates, platform model | 🔴 |
| 2 | [02_workmanager_and_periodic_tasks.md](02_workmanager_and_periodic_tasks.md) | `workmanager`: one-off/periodic tasks, constraints, retries | 🔴 |
| 3 | [03_foreground_services_android.md](03_foreground_services_android.md) | Android foreground services, persistent notification, live tracking | 🔴 |
| 4 | [04_ios_background_execution.md](04_ios_background_execution.md) | `BGTaskScheduler`, background fetch/processing, silent push, limits | 🔴 |
| 5 | [05_background_integration.md](05_background_integration.md) | Capstone: background sync behind a service, cross-platform strategy | 🔴 |

> **Cross-references:** Isolates: [02 · isolates](../02%20Advanced%20Dart/04_isolates.md). Notifications (required for foreground services): [Module 32](../32%20Notifications/README.md). iOS capabilities/background modes: [28 · ios_integration](../28%20Native%20iOS/05_ios_integration.md). Android permissions/manifest: [27 · permissions](../27%20Native%20Android/04_permissions_and_manifest.md). Offline-first sync (the main use case): [Module 19](../19%20Offline%20First/README.md). Location: [29 · geolocation](../29%20Device%20Features/02_geolocation.md).

## Prerequisites

[02 Advanced Dart](../02%20Advanced%20Dart/README.md) (isolates), [32 Notifications](../32%20Notifications/README.md), [27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md) (native config, iOS background modes), [19 Offline First](../19%20Offline%20First/README.md) (sync).

## What you'll be able to do after this module

- Explain the OS background-execution model and its isolate/battery constraints.
- Schedule deferrable and periodic background tasks with constraints via `workmanager`.
- Run an Android foreground service with a persistent notification for ongoing work.
- Use iOS `BGTaskScheduler`/background fetch/silent push within Apple's limits.
- Design a cross-platform background-sync strategy behind a service, degrading gracefully.

## Capstone

**Background sync slice:** Periodic background sync (WorkManager on Android / `BGTaskScheduler` on iOS) that flushes an offline outbox ([Module 19](../19%20Offline%20First/README.md)) when connected + charging, an Android foreground service for a live-tracking session, and silent-push-triggered refresh — all behind a `BackgroundService` with graceful degradation to foreground sync.

## Summary

Background work is OS-restricted and platform-divergent: Android uses WorkManager (deferrable/periodic) + foreground services (ongoing/visible); iOS uses tightly-metered `BGTaskScheduler`/fetch/silent-push. Tasks run in a separate isolate, timing isn't guaranteed, and continuous work needs justification. Design for "best-effort, catch up in foreground," behind a cross-platform service.
