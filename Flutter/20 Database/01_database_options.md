# Database Options (SQL vs NoSQL; Choosing an Engine)

> Pick by data shape and needs: **SQL** (SQLite/`sqflite`/Drift) for relational, queryable, ACID data; **NoSQL object stores** (Isar/Hive) for fast schemaless/object persistence — and prefer a **typed, reactive** solution (Drift/Isar) so reads are compile-safe and stream updates.

## Introduction

Flutter has several embedded databases with different models and ergonomics. This file frames the choice — SQL vs NoSQL, typed vs untyped, reactive vs one-shot — so the engine files (`sqflite`/Drift/Isar/Hive) are applied to the right problem.

## Why this concept exists

The wrong engine causes pain: raw SQL strings everywhere (untyped, error-prone), NoSQL where you needed joins/aggregations, or a non-reactive DB in a reactive UI. A clear decision framework matches the engine to the data model and app requirements.

## Real-world analogy

Choosing a database is choosing **how you organize a warehouse**: labeled shelves with a cross-reference index and strict rules (SQL — great for querying/relations) vs bins you toss labeled objects into and grab fast (NoSQL object store — great for speed/flexibility). Pick by how you'll store *and retrieve*.

## Problem Statement

Your app needs: relational data with joins/reporting, plus a large set of objects read very fast, and reactive lists that auto-update. Which engine(s)? By the end you'll route each and pick defaults.

## Internal Working

```mermaid
flowchart TD
    D{Data + needs} --> Rel[relational, joins, complex queries, ACID] --> SQL[SQLite: sqflite / Drift]
    D --> Obj[object/schemaless, very fast, simple] --> NoSQL[Isar / Hive]
    D --> Type{want type-safety + reactive?}
    Type --> Drift[Drift (typed SQL, streams)]
    Type --> Isar[Isar (typed objects, streams)]
```

| Engine | Model | Typed | Reactive | Query power | Notes |
|--------|-------|-------|----------|-------------|-------|
| **`sqflite`** | SQL (SQLite) | ❌ (raw strings/maps) | ❌ (manual) | Full SQL | Battle-tested, low-level, verbose |
| **Drift** | SQL (SQLite) | ✅ (codegen) | ✅ (`watch`) | Full SQL + typed DSL | Recommended typed reactive SQL |
| **Isar** | NoSQL objects | ✅ (codegen) | ✅ (streams) | Rich indexed queries | Fast, typed object DB |
| **Hive** | NoSQL key-object | ✅ (adapters) | ⚠️ (box listeners) | Key/box lookups (limited query) | Very simple/fast; weak querying |
| **ObjectBox** | NoSQL objects | ✅ | ✅ | Indexed queries | Fast alternative to Isar |

Decision heuristics:
- **Relational / joins / complex queries / reporting / ACID** → **SQL** (Drift preferred; `sqflite` if you want raw control).
- **Object-oriented / schemaless / speed-first / simple queries** → **NoSQL** (Isar for typed+queryable; Hive for simple key-object).
- **Want compile-safe queries + reactive streams** → **Drift** or **Isar** (avoid raw `sqflite` maps for large apps).
- **Just a few key-values / secrets / blobs** → not a DB — use prefs/secure/files ([15](../15%20Local%20Storage/01_storage_options_overview.md)).

## Memory Representation

DBs store on disk; queries load result sets into memory (bound with `LIMIT`/pagination). Reactive engines re-emit on change ([02 · streams](../02%20Advanced%20Dart/03_streams.md), [02 · memory_and_gc](../02%20Advanced%20Dart/13_memory_and_gc.md)).

## Compiler Behavior

Typed engines (Drift/Isar) **codegen** query/row types → compile-safe queries; raw `sqflite` returns untyped `Map`s (runtime-cast, error-prone).

## Runtime Behavior

Queries are async; typed engines validate at compile time; reactive engines push updates on writes. Heavy queries should run without blocking the UI isolate.

## Flutter Engine Behavior

DB plugins cross the embedder to native SQLite/engine; some (Drift/Isar) can run on background isolates for heavy work ([02 · isolates](../02%20Advanced%20Dart/04_isolates.md)).

## Dart VM Behavior

Not applicable beyond async.

## Examples

```dart
// Routing data to an engine (mental model):
// - users + orders with joins/reports        -> SQL (Drift preferred, or sqflite)
// - 50k cached objects, very fast reads       -> Isar (typed) / ObjectBox
// - a few key->object records, simple lookup   -> Hive
// - reactive task list auto-updating the UI    -> Drift .watch() or Isar streams
// - a handful of settings / a token / a file   -> NOT a DB (prefs/secure/files, Module 15)
```

## Diagrams

```mermaid
flowchart LR
    Q{relational + queries?}
    Q -- yes --> SQLpick[Drift (typed) / sqflite (raw)]
    Q -- no --> NoSQLpick{typed + queryable?}
    NoSQLpick -- yes --> Isar
    NoSQLpick -- no, simple --> Hive
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Raw `sqflite` maps across a big app | Untyped, error-prone | Use Drift/Isar (typed) |
| NoSQL where you need joins/reports | Poor fit | Use SQL |
| Non-reactive DB in a reactive UI | Manual refresh, stale UI | Use `watch`/streams (Drift/Isar) |
| Using a DB for a few key-values | Overkill | Prefs/secure/files ([15](../15%20Local%20Storage/README.md)) |
| Leaking DB rows to the UI | Coupling | Map rows→entities in a repository |
| Unbounded queries | Memory/perf | `LIMIT`/pagination + indexes ([05_modeling_migrations_performance.md](05_modeling_migrations_performance.md)) |

## Best Practices

- **Match engine to data**: SQL for relational/queryable/ACID; NoSQL objects for speed/flexibility.
- Prefer **typed + reactive** engines (**Drift** for SQL, **Isar** for NoSQL) for compile safety and auto-updating UIs.
- Front the DB behind a **repository** mapping rows/objects→entities; the app depends on the domain, not the DB.
- Bound queries (indexes, `LIMIT`, pagination); run heavy queries off the UI isolate.
- Don't use a DB for tiny key-values/secrets/blobs (use prefs/secure/files).

## Performance

Indexed, bounded queries are fast; typed engines avoid parse/cast overhead; reactive streams re-run only affected queries. Heavy work off-isolate keeps the UI smooth ([05_modeling_migrations_performance.md](05_modeling_migrations_performance.md), [Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+ SQL:** relations/joins/aggregations/ACID, mature. **+ NoSQL object:** speed, simple mapping, schemaless flexibility.
- **− SQL:** more setup/migrations, verbose (raw). **− NoSQL:** weaker ad-hoc querying/relations; per-engine lock-in.

## Interview Questions

1. **🟢 SQL vs NoSQL on-device — when each?** — SQL for relational/queryable/ACID data (joins, reports); NoSQL object stores for fast, schemaless/object persistence with simpler queries.
2. **🟢 Why prefer Drift/Isar over raw `sqflite`?** — Typed, compile-safe queries and reactive streams — vs raw untyped `Map`s and manual refresh.
3. **🟡 What does "reactive" mean for a DB?** — Queries return `Stream`s that re-emit when underlying data changes, auto-updating the UI (Drift `watch`, Isar streams).
4. **🟡 When is Hive appropriate vs Isar?** — Hive for simple key-object storage/caches with minimal querying; Isar when you need typed objects + rich indexed queries.
5. **🟡 When should you NOT use a database?** — For a few key-values, secrets, or blobs — use prefs/secure storage/files instead.
6. **🔴 How do you keep the DB from coupling the app?** — Wrap it behind a repository that maps rows/objects to domain entities; the domain never sees DB types.
7. **🔴 How do you bound query cost/memory?** — Indexes + `LIMIT`/pagination + selecting needed columns; heavy queries off the UI isolate.

## Senior Engineer Tips

- Default to **Drift** for relational apps (typed + reactive SQL) and **Isar** for object-heavy/fast-read apps; reach for raw `sqflite` only when you need low-level control.
- Keep DB types out of the domain (repository mapping) so you can migrate engines and stay testable.
- Choose reactive from the start — retrofitting `watch()`/streams into a one-shot DB layer is invasive.

## Architect Perspective

The database is the structured core of the data layer, underpinning caching ([15](../15%20Local%20Storage/05_caching_strategies.md)) and offline-first ([19](../19%20Offline%20First/README.md)). Choosing a typed, reactive engine behind repositories yields a compile-safe, auto-updating, swappable data foundation; the SQL-vs-NoSQL decision follows the data's relational/query needs and is costly to reverse — decide deliberately.

## Summary

- Choose SQL (SQLite/`sqflite`/Drift) for relational/queryable/ACID; NoSQL (Isar/Hive) for object/speed.
- Prefer typed+reactive (Drift/Isar); front behind repositories; bound queries with indexes/pagination.
- Not for tiny key-values/secrets/blobs; the DB backs caching and offline-first.

## Revision Notes

- SQL (relational/joins/ACID): `sqflite` (raw) / Drift (typed+reactive). NoSQL (objects/fast): Isar (typed+queryable) / Hive (simple key-object) / ObjectBox.
- Prefer typed + reactive (Drift/Isar); avoid raw maps at scale.
- Repository maps rows→entities; bound queries (index/LIMIT); heavy off-isolate.
- Tiny key-values/secrets/blobs → Module 15, not a DB.

## Practice Questions

1. Route four data sets to SQL vs a specific NoSQL engine.
2. Why choose Drift over raw `sqflite` for a large app?
3. When is Hive enough vs needing Isar?

## Coding Questions

1. Design a repository interface over an unspecified DB (rows→entities, reactive `watch`).
2. Justify SQL vs NoSQL for a described feature set.
3. Identify a DB misuse (tiny key-values) and re-route it to Module 15 storage.

## Mini Project

**Engine decision (docs + skeleton):** For a described app (relational reports + a large fast-read object cache + a reactive list), write `DB_CHOICE.md` selecting engine(s) with rationale, and sketch a repository interface (reactive reads, entity mapping) that could sit over any of them. Acceptance: correct SQL/NoSQL routing; typed+reactive preference justified; repository abstraction.
