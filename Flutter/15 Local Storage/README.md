# 15 · Local Storage

## Introduction

Apps must persist data on-device: user preferences, auth tokens, cached responses, files. This module covers the **non-database** local storage options — `SharedPreferences`, secure storage, and files (`path_provider`) — plus caching strategies. (Full databases are [Module 20](../20%20Database/README.md); offline sync is [Module 19](../19%20Offline%20First/README.md).)

## Why this module exists

Choosing the wrong storage (tokens in plain prefs, large blobs in key-value, no cache invalidation) causes security holes, bloat, and stale data. Knowing each option's purpose, limits, and security model is essential for correct, safe persistence.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_storage_options_overview.md](01_storage_options_overview.md) | The options and how to choose | 🟢 |
| 2 | [02_shared_preferences.md](02_shared_preferences.md) | Key-value preferences | 🟢 |
| 3 | [03_secure_storage.md](03_secure_storage.md) | `flutter_secure_storage`, keychain/keystore | 🔴 |
| 4 | [04_file_storage.md](04_file_storage.md) | `path_provider`, files & directories | 🔵 |
| 5 | [05_caching_strategies.md](05_caching_strategies.md) | TTL, cache-first, invalidation | 🔴 |

> **Cross-references:** Databases (SQLite/Drift/Isar/Hive): [Module 20](../20%20Database/README.md). Offline-first/sync: [Module 19](../19%20Offline%20First/README.md). Security (encryption, threat model): [Module 37](../37%20Security/README.md). Networking/caching source: [Module 16](../16%20Networking/README.md). File handling (upload/download/ZIP): [Module 34](../34%20File%20Handling/README.md). Repository pattern: [05 · repository](../05%20Design%20Patterns/20_repository.md).

## Prerequisites

[02 · json_and_serialization](../02%20Advanced%20Dart/12_json_and_serialization.md), [05 · repository](../05%20Design%20Patterns/20_repository.md), [14 Dependency Injection](../14%20Dependency%20Injection/README.md).

## What you'll be able to do after this module

- Pick the right storage for a given data type (prefs vs secure vs file vs DB).
- Persist simple settings with `SharedPreferences`.
- Store secrets/tokens securely (keychain/keystore) — never in plain prefs.
- Read/write files and app directories with `path_provider`.
- Implement caching with TTL, cache-first strategies, and invalidation.

## Capstone

**Persistent settings + secure session + cached feed:** Store theme/locale in prefs, the auth token in secure storage, and API responses in a file-based cache with TTL — all behind a repository so the rest of the app is storage-agnostic.

## Summary

Match data to storage: small settings → prefs; secrets → secure storage; files/blobs → filesystem; structured/queryable data → a database (Module 20). Wrap storage behind repositories, and cache with explicit TTL/invalidation.
