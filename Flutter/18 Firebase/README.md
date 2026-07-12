# 18 · Firebase

## Introduction

Firebase is Google's Backend-as-a-Service (BaaS): auth, databases (Firestore/Realtime DB), storage, serverless functions, messaging, analytics, and crash reporting — accessed from Flutter via **FlutterFire** plugins. This module covers setup and each major service, with security and architecture guidance.

## Why this module exists

Firebase lets small teams ship full-stack apps fast without running servers. But its convenience hides sharp edges: security rules, cost/read-count modeling, offline behavior, and vendor lock-in. Using it *well* (behind repositories, with proper rules) is the skill.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_firebase_setup_and_core.md](01_firebase_setup_and_core.md) | FlutterFire setup, init, project config | 🟢 |
| 2 | [02_firebase_auth.md](02_firebase_auth.md) | `FirebaseAuth`, providers, state | 🔵 |
| 3 | [03_firestore.md](03_firestore.md) | NoSQL modeling, queries, real-time, offline, rules | 🔴 |
| 4 | [04_realtime_db_and_storage.md](04_realtime_db_and_storage.md) | Realtime Database + Cloud Storage | 🔵 |
| 5 | [05_cloud_functions.md](05_cloud_functions.md) | Serverless functions, triggers, callable | 🔵 |
| 6 | [06_observability_and_messaging.md](06_observability_and_messaging.md) | Crashlytics, Analytics, FCM, Remote Config, App Check | 🔵 |

> **Cross-references:** Auth patterns: [Module 17](../17%20Authentication/README.md). Repository boundary: [05 · repository](../05%20Design%20Patterns/20_repository.md). Offline/sync: [Module 19](../19%20Offline%20First/README.md). Notifications: [Module 32](../32%20Notifications/README.md). Monitoring: [Module 52](../52%20Monitoring/README.md). Security: [Module 37](../37%20Security/README.md). Streams: [02 · streams](../02%20Advanced%20Dart/03_streams.md).

## Prerequisites

[16 Networking](../16%20Networking/README.md), [17 Authentication](../17%20Authentication/README.md), [05 · repository](../05%20Design%20Patterns/20_repository.md), [02 · streams](../02%20Advanced%20Dart/03_streams.md).

## What you'll be able to do after this module

- Set up FlutterFire and initialize Firebase correctly (dev/prod).
- Implement auth with `FirebaseAuth` + providers and reactive auth state.
- Model, query, and stream Firestore data with security rules and offline support.
- Use Realtime Database, Storage, Cloud Functions, FCM, Crashlytics/Analytics, Remote Config, App Check.
- Wrap Firebase behind repositories to limit lock-in and stay testable.

## Capstone

**Firebase-backed app slice:** Email/Google auth → Firestore-backed data (real-time + offline) with security rules → file upload to Storage → a Cloud Function trigger → Crashlytics + Analytics + FCM — all behind repositories.

## Summary

Firebase is a fast, integrated BaaS. Use its services through repository boundaries, write strict security rules, model for cost (read counts), and be deliberate about lock-in. Powerful for MVPs and many production apps when used with discipline.
