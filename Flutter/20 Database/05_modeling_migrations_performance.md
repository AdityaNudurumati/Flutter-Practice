# Data Modeling, Migrations & Performance

> Cross-engine essentials: model schemas around your queries (relations/indexes), evolve them with **safe, versioned migrations** (never lose user data), and make queries fast with **indexes, bounded reads, and off-isolate execution**.

## Introduction

Whatever engine you chose ([01_database_options.md](01_database_options.md)), three concerns decide your data layer's quality: **modeling** (schema, relations, normalization vs denormalization), **migrations** (evolving the schema without data loss), and **performance** (indexing, query cost, memory). This file covers all three, engine-agnostically.

## Why this concept exists

Poor modeling causes slow/awkward queries; botched migrations corrupt or wipe user data (a catastrophic bug); and unindexed/unbounded queries jank the UI or blow memory. These are the recurring, high-stakes database skills across `sqflite`/Drift/Isar/Hive.

## Real-world analogy

Modeling is **designing a warehouse layout** for how you'll fetch goods; migrations are **renovating the warehouse while it's full of inventory** (you must not lose stock); performance is **adding aisle signs/indexes and forklifts** so retrieval is fast and you don't haul the whole warehouse to find one box.

## Problem Statement

Design a users↔tasks schema for common queries, add a new column in v2 without losing data, and make "open tasks by user" fast at scale. You'll model relations/indexes, write a migration, and optimize the query.

## Internal Working

```mermaid
flowchart TD
    Model[Model around queries: relations, normalize vs denormalize] --> Index[Indexes on filtered/sorted/FK columns]
    Index --> Query[Bounded, projected queries (LIMIT, select cols)]
    Version[schema version bump] --> Migrate[versioned migration: additive, stepwise, tested]
    Query --> Isolate[heavy queries off UI isolate]
```

- **Modeling**:
  - **Relations**: one-to-many/many-to-many via foreign keys (SQL) or links (Isar); avoid duplicating what you must keep consistent.
  - **Normalize vs denormalize**: normalize for integrity/writes; denormalize selectively for read speed (trade duplication for fewer joins) — mirror the caching/offline tradeoff ([15 · caching_strategies](../15%20Local%20Storage/05_caching_strategies.md)).
  - **Model around queries**: shape tables/indexes for the reads you actually do.
- **Migrations**:
  - Bump the **schema version**; run **stepwise** migrations (v1→v2→v3), **additive** where possible (add columns/tables), avoid destructive changes.
  - **Never lose data**: back-fill new columns, migrate/transform rows in-place; test against **real old databases**.
  - Engine tooling: `sqflite` `onUpgrade`, Drift `MigrationStrategy`/schema tests, Isar schema migration.
- **Performance**:
  - **Indexes** on columns you filter/sort/join by (and FKs); unindexed filters = full scans.
  - **Bound reads**: `LIMIT`/pagination; **project** only needed columns; avoid `SELECT *` on wide rows.
  - **Batch/transaction** bulk writes; use **reactive queries** so only affected reads re-run.
  - **Off-isolate**: run heavy queries/imports on a background isolate ([02 · isolates](../02%20Advanced%20Dart/04_isolates.md)).
  - **Analyze**: use `EXPLAIN QUERY PLAN` (SQLite) to confirm index usage.

## Memory Representation

Result sets load into memory — bound them. Indexes add storage/write cost but speed reads. Large migrations/imports should stream/batch off-isolate ([02 · memory_and_gc](../02%20Advanced%20Dart/13_memory_and_gc.md)).

## Compiler Behavior

Typed engines (Drift/Isar) validate schema/queries at build time; migrations are still runtime logic you must test.

## Runtime Behavior

Migrations run on version bump at open; a failed/incorrect migration can corrupt data — hence testing. Unindexed queries scale O(n); indexed lookups are ~O(log n).

## Flutter Engine Behavior / Dart VM Behavior

Not applicable beyond async; heavy DB work off the UI isolate.

## Examples

```dart
// SQLite index + bounded, projected query (fast "open tasks by user"):
// CREATE INDEX idx_tasks_user_done ON tasks(user_id, done);   -- composite index
// SELECT id, title FROM tasks WHERE user_id = ? AND done = 0 ORDER BY id DESC LIMIT 50;
//   -> uses the index; projects only needed columns; bounded.

// Safe additive migration (sqflite onUpgrade), stepwise:
Future<void> onUpgrade(dynamic db, int oldV, int newV) async {
  if (oldV < 2) {
    await db.execute('ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 0'); // additive + default
  }
  if (oldV < 3) {
    await db.execute('CREATE INDEX idx_tasks_user_done ON tasks(user_id, done)'); // add index
  }
}

// Bulk import off the UI isolate + in a transaction:
// await Isolate.run(() => db.transaction((txn) => bulkInsert(txn, rows)));
```

```text
Diagnose index usage (SQLite):
  EXPLAIN QUERY PLAN SELECT ... WHERE user_id = ? AND done = 0;
  -> should show "USING INDEX idx_tasks_user_done", not "SCAN"
```

## Diagrams

```mermaid
flowchart LR
    Unindexed[filter unindexed col] --> Scan[full table scan O(n)]
    Indexed[index on filtered col] --> Seek[index seek ~O(log n)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| No indexes on filtered/sorted/FK columns | Full scans → slow | Add (composite) indexes; verify with EXPLAIN |
| Destructive/untested migrations | Data loss/corruption | Additive + stepwise + tested on real old DBs |
| `SELECT *` / unbounded queries | Memory/perf | Project columns + `LIMIT`/pagination |
| Over-normalizing read-hot data | Costly joins | Denormalize selectively for reads |
| Heavy queries/imports on UI isolate | Jank | Off-isolate + batch/transaction |
| Skipping schema version discipline | Broken upgrades | Bump version + migration per change |

## Best Practices

- **Model around your queries**; use relations + **indexes** (composite where filters combine); denormalize selectively for read speed.
- Treat **migrations as critical code**: versioned, **additive**, **stepwise**, back-fill data, and **test against real old databases**.
- **Bound and project** queries (`LIMIT`, pagination, needed columns); index filtered/sorted/FK columns; verify with `EXPLAIN QUERY PLAN`.
- **Batch/transaction** bulk writes; use **reactive queries**; run heavy work **off-isolate**.
- Front the DB behind a **repository**; keep DB types out of the domain.

## Performance

Indexes turn scans into seeks (huge at scale); bounded/projected queries cap memory; transactions batch writes; off-isolate execution keeps frames smooth. Profile queries (EXPLAIN, DevTools) rather than guessing ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Fast, correct, evolvable data layer; safe upgrades; scalable queries.
- **−** Indexing/migration discipline required; denormalization adds duplication/consistency work; migrations are risky if untested.

## Interview Questions

1. **🟢 Why add indexes?** — To turn full-table scans (O(n)) into index seeks (~O(log n)) for filtered/sorted/joined columns.
2. **🟢 What makes a migration safe?** — Versioned, additive, stepwise (v1→v2→v3), data back-filled, and tested against real old databases — no destructive/untested changes.
3. **🟡 Normalize vs denormalize — tradeoff?** — Normalize for integrity/write-efficiency; denormalize selectively for read speed (fewer joins) at the cost of duplication/consistency work.
4. **🟡 How do you bound query cost/memory?** — `LIMIT`/pagination, project only needed columns, and index the query — avoid `SELECT *`/unbounded reads.
5. **🟡 How do you verify a query uses an index?** — `EXPLAIN QUERY PLAN` (SQLite) — it should show index usage, not a scan.
6. **🔴 How do you migrate without losing user data?** — Stepwise additive changes with data back-fill/transformation, run in order at open, tested on real old-schema databases (and consider backups).
7. **🔴 How do you keep heavy DB work from janking the UI?** — Run large queries/imports on a background isolate and batch writes in transactions.

## Senior Engineer Tips

- Design indexes from your **actual query patterns** (composite indexes matching WHERE+ORDER BY); confirm with EXPLAIN, don't assume.
- Keep a **migration test suite** that opens fixtures of every prior schema version and upgrades them — migrations are the highest-risk DB code.
- Denormalize deliberately and document it; uncontrolled duplication becomes a consistency nightmare.

## Architect Perspective

Modeling, migrations, and performance are the durable database concerns independent of engine choice. A query-shaped, indexed schema; disciplined, tested migrations; and bounded, off-isolate queries behind repositories yield a fast, correct, evolvable data layer — the backbone under caching ([15](../15%20Local%20Storage/05_caching_strategies.md)) and offline-first ([19](../19%20Offline%20First/README.md)) and a frequent scaling/system-design topic ([Module 48](../48%20System%20Design/README.md)).

## Summary

- Model around queries with relations + indexes; denormalize selectively for reads.
- Migrations: versioned, additive, stepwise, data-preserving, tested against real old DBs.
- Performance: index filtered/sorted/FK columns, bound+project queries, batch writes, run heavy work off-isolate; verify with EXPLAIN.

## Revision Notes

- Model around queries; relations + composite indexes; denormalize selectively.
- Migrations: bump version, additive+stepwise, back-fill, test on real old DBs (highest-risk code).
- Perf: index filtered/sorted/FK; `LIMIT`+project (no `SELECT *`); transactions/batch; off-isolate; EXPLAIN QUERY PLAN.
- Repository-fronted; DB types out of domain.

## Practice Questions

1. What columns should you index for "open tasks by user, newest first"?
2. What makes a migration data-safe?
3. How do you confirm a query uses an index?

## Coding Questions

1. Add a composite index and rewrite a query to use it; verify with EXPLAIN.
2. Write a stepwise additive migration (v1→v3) that back-fills a column.
3. Run a bulk import in a transaction on a background isolate.

## Mini Project — Module capstone

**Optimized, migratable data layer (Flutter):** Model users↔tasks (relations + composite index) in your chosen engine, expose reactive bounded queries behind a repository (rows→entities), write a v1→v2→v3 migration with a back-filled column + added index, add a migration test opening old-schema fixtures, and benchmark indexed vs unindexed "open tasks by user." Acceptance: query-shaped indexed schema; safe tested migrations; bounded/projected queries; measured index benefit; heavy import off-isolate; runs.
