# 28 · Native iOS

## Introduction

This module covers the **iOS platform side** of a Flutter app: the iOS/Xcode project and CocoaPods, writing Swift (channel handlers, `AppDelegate`/`FlutterViewController`, lifecycle), embedding native iOS views (`UiKitView`), `Info.plist` and permissions (usage strings), and iOS integration (capabilities, background modes, universal links). It mirrors Native Android ([Module 27](../27%20Native%20Android/README.md)).

## Why this module exists

Flutter apps ship as iOS apps: you configure Xcode/CocoaPods, add capabilities and Info.plist usage strings, write Swift for platform channels/plugins, embed native views, and integrate with iOS lifecycle/background. Correct iOS setup is required to build, run, and pass App Store review.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [ios_project_and_cocoapods.md](ios_project_and_cocoapods.md) | Xcode project, CocoaPods, build config, schemes/flavors | 🔵 |
| 2 | [swift_plugin_code.md](swift_plugin_code.md) | Swift channels, `AppDelegate`/`FlutterViewController`, lifecycle | 🔴 |
| 3 | [platform_views_ios.md](platform_views_ios.md) | Embedding native iOS views (`UiKitView`) | 🔴 |
| 4 | [infoplist_and_permissions.md](infoplist_and_permissions.md) | `Info.plist`, permission usage strings, runtime flow | 🔵 |
| 5 | [ios_integration.md](ios_integration.md) | Capabilities, background modes, universal links, App Store | 🔴 |

> **Cross-references:** Platform channels/plugins: [Module 26](../26%20Platform%20Channels/README.md). Android counterpart: [Module 27](../27%20Native%20Android/README.md). Embedder/startup: [10 · embedder_and_startup](../10%20Flutter%20Architecture/embedder_and_startup.md). Device features: [Module 29](../29%20Device%20Features/README.md). Deep links/universal links: [13 · deep_linking](../13%20Routing/deep_linking_and_url_strategy.md). Deployment/signing: [Module 51](../51%20Deployment/README.md).

## Prerequisites

[26 Platform Channels](../26%20Platform%20Channels/README.md), [27 Native Android](../27%20Native%20Android/README.md) (many concepts mirror). Basic Swift + a Mac/Xcode help.

## What you'll be able to do after this module

- Navigate the iOS project + manage CocoaPods and Xcode config (versions, schemes, signing basics).
- Write Swift channel handlers with correct `AppDelegate`/`FlutterViewController`/lifecycle usage.
- Embed native iOS views via `UiKitView`.
- Add `Info.plist` usage strings and handle iOS permissions.
- Configure capabilities, background modes, and universal links.

## Capstone

**iOS integration slice:** A Swift `MethodChannel`/`EventChannel` reading a system value, a permission-gated feature (Info.plist usage string), an embedded native iOS view, and a capability/background-mode + universal-link integration — bridged to Flutter behind a repository.

## Summary

The iOS side is Xcode/CocoaPods config + Swift (channels/AppDelegate/lifecycle) + Info.plist/permissions + platform views + capabilities/background/universal links. Master it to ship iOS apps and implement native features — mirroring Android with iOS-specific idioms.
