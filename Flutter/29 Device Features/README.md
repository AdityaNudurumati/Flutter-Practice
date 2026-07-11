# 29 · Device Features

## Introduction

This module covers accessing **native device capabilities** from Flutter through plugins: the **camera & gallery** (capture/pick images/video), **geolocation** (GPS position, streams, geocoding), **device sensors** (accelerometer/gyroscope/magnetometer + battery/connectivity/device info), and **connectivity** (network reachability). It shows how to wrap each behind a repository, handle permissions ([Module 27](../27%20Native%20Android/permissions_and_manifest.md) / [Module 28](../28%20Native%20iOS/infoplist_and_permissions.md)), and stream results reactively.

## Why this module exists

Most real apps read the physical device: scan/attach photos, locate the user, react to motion, adapt to being offline. Flutter reaches these through platform channels ([Module 26](../26%20Platform%20Channels/README.md)) — usually via maintained plugins — but you must handle permissions, lifecycle, streams, and graceful degradation correctly to be reliable and battery-friendly.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [camera_and_gallery.md](camera_and_gallery.md) | Capture photos/video, pick from gallery (`camera`/`image_picker`) | 🔵 |
| 2 | [geolocation.md](geolocation.md) | GPS position, location streams, accuracy, geocoding (`geolocator`) | 🔴 |
| 3 | [sensors_and_device_info.md](sensors_and_device_info.md) | Accelerometer/gyroscope, battery, device info (`sensors_plus` family) | 🔵 |
| 4 | [connectivity.md](connectivity.md) | Network reachability + streams, offline handling (`connectivity_plus`) | 🔵 |
| 5 | [device_integration.md](device_integration.md) | Capstone: features behind repositories, permissions, streams | 🔴 |

> **Cross-references:** Permissions: [27 · permissions_and_manifest](../27%20Native%20Android/permissions_and_manifest.md), [28 · infoplist_and_permissions](../28%20Native%20iOS/infoplist_and_permissions.md). Platform channels (how plugins work): [Module 26](../26%20Platform%20Channels/README.md). Maps: [Module 30](../30%20Google%20Maps/README.md). Streams: [02 · streams](../02%20Advanced%20Dart/streams_and_async.md). Offline-first: [Module 19](../19%20Offline%20First/README.md). File handling: [Module 34](../34%20File%20Handling/README.md).

## Prerequisites

[26 Platform Channels](../26%20Platform%20Channels/README.md), [27 Native Android](../27%20Native%20Android/README.md), [28 Native iOS](../28%20Native%20iOS/README.md) (permissions), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (streams/async).

## What you'll be able to do after this module

- Capture photos/video and pick media, handling permissions + files.
- Read the device location once and as a stream, with accuracy/geocoding.
- Read sensors, battery, connectivity, and device info reactively.
- Detect and react to offline/online transitions.
- Wrap every device feature behind a repository with graceful degradation.

## Capstone

**Device feature slice:** A screen that attaches a photo (camera/gallery), tags it with the current location (geolocator + geocoding), shows an online/offline banner (connectivity stream), and reads device/battery info — every feature behind a repository, permissions handled, degrading gracefully when denied/unavailable.

## Summary

Device features = maintained plugins over platform channels for camera/gallery, geolocation, sensors/device info, and connectivity. Handle permissions and lifecycle, prefer streams for continuous data, and wrap each behind a repository so the app stays testable, battery-friendly, and resilient offline.
