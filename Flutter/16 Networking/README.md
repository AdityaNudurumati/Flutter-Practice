# 16 · Networking

## Introduction

Networking connects your app to backends: REST, GraphQL, WebSockets, gRPC. This module covers HTTP fundamentals, a production REST client (`dio` + interceptors + typed errors), and the other protocols — always **wrapped behind repositories** with retry/timeout/cancellation and DTO↔entity mapping.

## Why this module exists

Networking is where most runtime failures live (timeouts, 4xx/5xx, offline, parsing). A disciplined client — typed failures, interceptors for auth/logging/retry, and repository boundaries — is what separates a robust app from one that crashes on a flaky connection.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_http_fundamentals.md](01_http_fundamentals.md) | HTTP basics, `http` vs `dio` | 🟢 |
| 2 | [02_rest_client_and_interceptors.md](02_rest_client_and_interceptors.md) | `dio` client, interceptors, typed errors, retry/timeout/cancel, DTO mapping | 🔴 |
| 3 | [03_graphql.md](03_graphql.md) | Queries/mutations/subscriptions, caching | 🔵 |
| 4 | [04_websockets_and_realtime.md](04_websockets_and_realtime.md) | WebSockets, SSE, Socket.IO | 🔵 |
| 5 | [05_grpc.md](05_grpc.md) | Protobuf, gRPC, streaming | 🔵 |

> **Cross-references:** Serialization: [02 · json_and_serialization](../02%20Advanced%20Dart/12_json_and_serialization.md). Repository/DTO boundary: [05 · repository](../05%20Design%20Patterns/20_repository.md). Typed failures/`Result`: [Module 38](../38%20Error%20Handling/README.md). Caching/offline: [15 · caching_strategies](../15%20Local%20Storage/05_caching_strategies.md), [Module 19](../19%20Offline%20First/README.md). Auth tokens/refresh: [Module 17](../17%20Authentication/README.md). Isolates for heavy parsing: [02 · isolates](../02%20Advanced%20Dart/04_isolates.md).

## Prerequisites

[02 Advanced Dart](../02%20Advanced%20Dart/README.md) (async/streams/isolates/JSON), [05 · repository/DI](../05%20Design%20Patterns/20_repository.md), [14 DI](../14%20Dependency%20Injection/README.md).

## What you'll be able to do after this module

- Make HTTP requests and reason about methods/status/headers.
- Build a production `dio` client with interceptors, typed errors, retry/timeout/cancellation.
- Map DTOs↔entities at the repository boundary.
- Choose and use GraphQL, WebSockets/real-time, and gRPC appropriately.

## Capstone

**Robust API layer:** A `dio`-based client with auth + logging + retry interceptors, timeouts and cancellation, errors converted to a typed `Result`/failure, DTO→entity mapping, and a repository the app depends on — testable with a mocked client.

## Summary

Pick the protocol per need (REST/GraphQL/WS/gRPC), build a disciplined client (interceptors, typed errors, resilience), and hide it behind repositories that return domain entities. Networking done right is resilient, testable, and invisible to the UI.
