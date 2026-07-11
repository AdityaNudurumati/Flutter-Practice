# 19 · Offline First

## Introduction

Offline-first apps treat the **local store as the source of truth** and the network as a background sync — so the UI is instant and works with no connection, syncing when possible. This module covers the architecture, sync engine, conflict resolution, connectivity/queued mutations (outbox), and optimistic UI.

## Why this module exists

Mobile networks are unreliable. Apps that block on the network feel slow and break offline. Offline-first delivers instant, resilient UX — but introduces hard problems (sync, conflicts, queued writes) that must be designed deliberately, not bolted on.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [offline_first_fundamentals.md](offline_first_fundamentals.md) | Principles + local-source-of-truth architecture | 🔴 |
| 2 | [sync_engine.md](sync_engine.md) | Pull/push, delta sync, sync state | 🔴 |
| 3 | [conflict_resolution.md](conflict_resolution.md) | LWW, versioning, merge, CRDTs | 🔴 |
| 4 | [connectivity_and_outbox.md](connectivity_and_outbox.md) | Connectivity handling, queued mutations (outbox) | 🔴 |
| 5 | [optimistic_ui.md](optimistic_ui.md) | Optimistic updates + rollback | 🔵 |

> **Cross-references:** Caching/TTL: [15 · caching_strategies](../15%20Local%20Storage/caching_strategies.md). Database (local store): [Module 20](../20%20Database/README.md). Networking: [Module 16](../16%20Networking/README.md). Repository boundary: [05 · repository](../05%20Design%20Patterns/repository.md). Background sync: [Module 33](../33%20Background%20Services/README.md). Firestore offline: [18 · firestore](../18%20Firebase/firestore.md). State/streams: [Modules 11](../11%20State%20Management/README.md), [02 · streams](../02%20Advanced%20Dart/streams.md).

## Prerequisites

[15 Local Storage](../15%20Local%20Storage/README.md), [16 Networking](../16%20Networking/README.md), [05 · repository](../05%20Design%20Patterns/repository.md), [02 · streams](../02%20Advanced%20Dart/streams.md).

## What you'll be able to do after this module

- Design a local-source-of-truth, offline-first architecture.
- Build a sync engine (pull/push, delta, sync status) behind a repository.
- Choose and implement a conflict-resolution strategy.
- Queue mutations offline (outbox) and flush on reconnect.
- Implement optimistic UI with rollback.

## Capstone

**Offline-first notes app:** Local DB is source of truth; UI reads/writes locally (instant, optimistic); a sync engine pushes an outbox + pulls deltas on connectivity, with last-write-wins + version conflict handling — all behind a repository exposing a reactive stream.

## Summary

Offline-first = local store is truth, network is background sync. Get the four hard parts right — sync, conflicts, queued writes, optimistic UI — behind a repository, and the app feels instant and never "breaks offline."
