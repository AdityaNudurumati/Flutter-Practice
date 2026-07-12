# 20 · Database

## Introduction

When data is structured, queryable, relational, or large, you need a real on-device **database** — the backing store for offline-first and rich caching. This module covers choosing SQL vs NoSQL and the main Flutter options: SQLite/`sqflite`, Drift (typed reactive SQL), and Isar/Hive (object stores), plus modeling, migrations, and performance.

## Why this module exists

`SharedPreferences`/files can't query or scale ([Module 15](../15%20Local%20Storage/README.md)). Real apps need indexed queries, relations, reactive reads, and migrations. Choosing and using the right database — and modeling/migrating it well — determines correctness, performance, and maintainability of the whole data layer.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_database_options.md](01_database_options.md) | SQL vs NoSQL; choosing an engine | 🔵 |
| 2 | [02_sqlite_sqflite.md](02_sqlite_sqflite.md) | Raw SQLite via `sqflite` | 🔵 |
| 3 | [03_drift.md](03_drift.md) | Typed, reactive SQL (compile-safe) | 🔴 |
| 4 | [04_isar_hive.md](04_isar_hive.md) | NoSQL/object stores | 🔵 |
| 5 | [05_modeling_migrations_performance.md](05_modeling_migrations_performance.md) | Schema, migrations, indexing, performance | 🔴 |

> **Cross-references:** Storage decision framework: [15 · storage_options_overview](../15%20Local%20Storage/01_storage_options_overview.md). Offline-first (uses the DB as source of truth): [Module 19](../19%20Offline%20First/README.md). Repository boundary/DTO mapping: [05 · repository](../05%20Design%20Patterns/20_repository.md). Streams (reactive reads): [02 · streams](../02%20Advanced%20Dart/03_streams.md). Isolates (heavy queries): [02 · isolates](../02%20Advanced%20Dart/04_isolates.md). Firestore (cloud NoSQL): [18 · firestore](../18%20Firebase/03_firestore.md).

## Prerequisites

[15 Local Storage](../15%20Local%20Storage/README.md), [05 · repository](../05%20Design%20Patterns/20_repository.md), [02 · streams](../02%20Advanced%20Dart/03_streams.md).

## What you'll be able to do after this module

- Choose SQL vs NoSQL and a specific engine by data shape/needs.
- Use `sqflite` for raw SQLite; Drift for typed reactive SQL; Isar/Hive for object storage.
- Model schemas with relations/indexes and write safe migrations.
- Build reactive, repository-fronted data layers and optimize query performance.

## Capstone

**Typed reactive data layer:** Model a small domain (users/tasks) in Drift with relations + indexes, expose reactive queries behind a repository (mapped to entities), write a v1→v2 migration, and benchmark an indexed vs unindexed query.

## Summary

Databases give queryable, relational, reactive, migratable on-device storage. Pick SQL (relational/queries) or NoSQL (object/speed), front it behind repositories, model with indexes, and migrate carefully — the foundation beneath caching and offline-first.
