# 26 · Platform Channels

## Introduction

Platform channels are Flutter's bridge to **native code** (Kotlin/Java, Swift/Obj-C, C/C++, platform APIs) when Dart/plugins can't do the job. This module covers the messaging model, `MethodChannel` (call native methods), `EventChannel` (native→Dart streams), writing plugins with **Pigeon** (type-safe), and **FFI** (direct C interop).

## Why this module exists

Some capabilities live only in native SDKs/OS APIs (sensors, native UI, platform features, C libraries). Channels let Dart and native exchange messages asynchronously; FFI calls C directly. Doing this correctly (async, threading, type-safety) is what makes native integration reliable.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [platform_channel_fundamentals.md](platform_channel_fundamentals.md) | Messaging model, codec, async, threading | 🔴 |
| 2 | [method_channel.md](method_channel.md) | `MethodChannel` (invoke/handle/errors) | 🔵 |
| 3 | [event_channel.md](event_channel.md) | `EventChannel` (native→Dart streams) | 🔵 |
| 4 | [plugins_and_pigeon.md](plugins_and_pigeon.md) | Writing plugins, federated, Pigeon | 🔴 |
| 5 | [ffi.md](ffi.md) | `dart:ffi` direct C interop | 🔴 |

> **Cross-references:** Engine/embedder boundary + task runners: [10 · threading_model](../10%20Flutter%20Architecture/threading_model.md), [10 · engine_internals](../10%20Flutter%20Architecture/engine_internals.md). Native Android/iOS: [Modules 27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md). Device features (via plugins): [Module 29](../29%20Device%20Features/README.md). Isolates/async: [02](../02%20Advanced%20Dart/README.md). Background isolate channels: [02 · isolates](../02%20Advanced%20Dart/isolates.md).

## Prerequisites

[10 Flutter Architecture](../10%20Flutter%20Architecture/README.md) (threading/embedder), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (async/streams/isolates).

## What you'll be able to do after this module

- Explain the channel messaging model (codec, async, threading).
- Call native methods (`MethodChannel`) and stream native events (`EventChannel`).
- Write plugins and use Pigeon for type-safe channels.
- Call C libraries directly via FFI.
- Decide channel vs FFI vs existing plugin.

## Capstone

**Native battery + sensor bridge:** A `MethodChannel` to read battery level, an `EventChannel` streaming battery/charging changes, wrapped behind a repository — plus a Pigeon-generated type-safe interface, and a small FFI call to a C function.

## Summary

Platform channels pass async messages between Dart and native (via a codec, across threads); `MethodChannel`/`EventChannel` are the primitives, Pigeon adds type-safety, and FFI bypasses channels for direct C calls. Wrap all native access behind repositories to keep the app clean and testable.
