# 27 · Native Android

## Introduction

This module covers the **Android platform side** of a Flutter app: the Android project structure and Gradle, writing Kotlin (channel handlers, activity/context, lifecycle), embedding native Android views (platform views), the manifest and permissions, and Android-specific integration (services/intents/receivers). It's the Android half of native integration ([Module 26](../26%20Platform%20Channels/README.md)).

## Why this module exists

Flutter apps still ship as Android apps: you configure Gradle, request permissions, write Kotlin for platform channels/plugins, embed native views, and integrate with Android services/intents. Doing this correctly is essential for real apps and for native integration.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_android_project_and_gradle.md](01_android_project_and_gradle.md) | Project structure, Gradle, build config, flavors | 🔵 |
| 2 | [02_kotlin_plugin_code.md](02_kotlin_plugin_code.md) | Kotlin channel handlers, `MainActivity`, context, lifecycle | 🔴 |
| 3 | [03_platform_views_android.md](03_platform_views_android.md) | Embedding native Android views | 🔴 |
| 4 | [04_permissions_and_manifest.md](04_permissions_and_manifest.md) | Manifest, permissions (declared + runtime) | 🔵 |
| 5 | [05_android_integration.md](05_android_integration.md) | Services, intents, broadcast receivers, background | 🔴 |

> **Cross-references:** Platform channels/plugins: [Module 26](../26%20Platform%20Channels/README.md). Embedder/startup: [10 · embedder_and_startup](../10%20Flutter%20Architecture/05_embedder_and_startup.md). Device features (plugins): [Module 29](../29%20Device%20Features/README.md). Background: [Module 33](../33%20Background%20Services/README.md). Deployment/signing: [Module 51](../51%20Deployment/README.md). iOS counterpart: [Module 28](../28%20Native%20iOS/README.md).

## Prerequisites

[26 Platform Channels](../26%20Platform%20Channels/README.md), [10 Flutter Architecture](../10%20Flutter%20Architecture/README.md). Basic Kotlin helps.

## What you'll be able to do after this module

- Navigate the Android project + configure Gradle (SDK versions, flavors, signing basics).
- Write Kotlin channel handlers with correct activity/context/lifecycle usage.
- Embed native Android views via platform views.
- Declare and request Android permissions correctly (incl. runtime).
- Integrate with Android services, intents, and broadcast receivers.

## Capstone

**Android integration slice:** A Kotlin `MethodChannel`/`EventChannel` reading a system value, a permission-gated feature (runtime permission), an embedded native Android view, and a foreground-service/intent integration — wired to the Flutter side via a repository.

## Summary

The Android side is Gradle config + Kotlin (channels/activity/context/lifecycle) + manifest/permissions + platform views + service/intent integration. Master it to ship real Android apps and to implement native features that Dart/plugins can't.
