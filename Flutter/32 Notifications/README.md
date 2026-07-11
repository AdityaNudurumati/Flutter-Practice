# 32 · Notifications

## Introduction

This module covers notifications in Flutter: **local notifications** (`flutter_local_notifications` — scheduled/immediate, channels, actions), **push via Firebase Cloud Messaging** (FCM — tokens, the foreground/background/terminated delivery model), **message types & targeting** (notification vs data messages, topics, device tokens), and **handling taps + deep links** (routing a tapped notification to the right screen), tied together in a capstone. It builds on Firebase ([Module 18](../18%20Firebase/README.md)), permissions ([27](../27%20Native%20Android/permissions_and_manifest.md)/[28](../28%20Native%20iOS/infoplist_and_permissions.md)), and deep linking ([Module 13](../13%20Routing/README.md)).

## Why this module exists

Notifications drive re-engagement and deliver time-sensitive info, but they're deceptively tricky: platform permission models differ, FCM behaves differently across app states (foreground/background/terminated), **notification** vs **data** messages route differently, and a tapped notification must deep-link reliably even from a cold start. Getting these right is what separates flaky notifications from dependable ones.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [local_notifications.md](local_notifications.md) | `flutter_local_notifications`: immediate/scheduled, channels, actions | 🔵 |
| 2 | [fcm_push.md](fcm_push.md) | FCM setup, tokens, foreground/background/terminated delivery | 🔴 |
| 3 | [message_types_and_targeting.md](message_types_and_targeting.md) | Notification vs data messages, topics, token/segment targeting | 🔴 |
| 4 | [handling_and_deeplinks.md](handling_and_deeplinks.md) | Tap handling, cold-start routing, deep links, foreground display | 🔴 |
| 5 | [notifications_integration.md](notifications_integration.md) | Capstone: FCM + local + deep-link routing behind a service | 🔴 |

> **Cross-references:** Firebase project/setup: [Module 18](../18%20Firebase/README.md). Permissions: [27 · permissions](../27%20Native%20Android/permissions_and_manifest.md), [28 · infoplist](../28%20Native%20iOS/infoplist_and_permissions.md), [28 · ios_integration](../28%20Native%20iOS/ios_integration.md) (APNs/background modes). Deep linking/routing: [Module 13](../13%20Routing/README.md). Background execution: [Module 33](../33%20Background%20Services/README.md). Backend send: [Module 16](../16%20Networking/README.md).

## Prerequisites

[18 Firebase](../18%20Firebase/README.md) (project + FlutterFire), [27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md) (permissions, APNs/entitlements), [13 Routing](../13%20Routing/README.md) (go_router for deep links).

## What you'll be able to do after this module

- Show immediate and scheduled local notifications with channels and actions.
- Set up FCM, obtain/refresh device tokens, and handle all three app states.
- Choose and send notification vs data messages; target by token/topic.
- Route notification taps (including cold start) to the right screen via deep links.
- Wrap it all behind a notification service that's testable and permission-aware.

## Capstone

**Notification slice:** FCM push received in foreground (shown via local notification), background, and terminated states; data payloads routed through `go_router` to a target screen on tap (including cold start); topic subscription for broadcasts; and scheduled local reminders — all behind a `NotificationService`.

## Summary

Notifications = local (`flutter_local_notifications`) + push (FCM), with careful handling of permissions, the foreground/background/terminated model, notification-vs-data messages, and deep-link routing on tap. Wrap it behind a service and let the server own targeting/sending.
