# Isar & Hive (NoSQL Object Stores)

> **Isar** is a fast, typed NoSQL object database with rich indexed queries and reactive streams; **Hive** is a simpler, extremely fast key-object store with weak querying — both persist Dart objects directly (no SQL/joins), ideal for object-shaped, speed-first data.

## Introduction

Not all data is relational. Isar and Hive store **Dart objects** directly. Isar offers typed collections, indexes, links, queries, and reactive watchers; Hive offers dead-simple, blazing-fast key→object "boxes." This file covers both, their tradeoffs, and when to pick each over SQL.

## Why this concept exists

For object-oriented, schemaless, or performance-critical local data (large caches, offline object stores, settings-plus), mapping to relational tables/joins is friction. Object stores persist objects natively — faster and simpler for that shape, at the cost of relational querying.

## Real-world analogy

Isar is a **smart storage unit with a labeled index** — toss in objects, find them fast by many attributes (indexed queries). Hive is a **set of labeled bins** — drop an object in a bin by key and grab it instantly, but there's no cross-bin search engine.

## Problem Statement

Cache 50k product objects for very fast reads with attribute queries (Isar), and store a handful of key→object records with instant lookup (Hive). You'll model both and query them.

## Internal Working

```mermaid
flowchart TD
    subgraph Isar (typed, queryable, reactive)
      Col[collections of annotated objects] --> Idx[indexes + links]
      Idx --> Q[rich queries + .watch() streams]
    end
    subgraph Hive (simple key-object)
      Box[boxes: key -> object] --> Get[get/put by key]
    end
```

- **Isar** (`isar`): annotate classes (`@collection`, `Id id`), codegen generates schemas; **indexes** (`@Index`) enable fast typed queries (`.filter().xEqualTo(...).findAll()`), **links** relate objects, and **`.watch()`** provides reactive streams. Fast (mmap), typed, supports queries/sorting/aggregation and background isolates.
- **Hive** (`hive`/`hive_ce`): **boxes** are key→value maps persisting primitives or objects (via `TypeAdapter`s, often codegen'd). `box.put(key, obj)`/`box.get(key)`; iterate a box; limited querying (no rich filters/joins). Extremely fast/simple; great for caches/settings-plus.
- **Choosing**: **Isar** when you need typed objects **and** queries/relations/reactivity; **Hive** for simple key-object storage where you look up by key and don't need querying.
- Both **persist Dart objects directly** (no SQL); front behind a repository mapping stored objects→entities where the domain model differs.

## Memory Representation

Isar uses memory-mapped files (fast, lazy loading); Hive keeps boxes largely in memory (fast, but a huge box costs RAM). Bound reads (queries/`limit` in Isar; avoid giant Hive boxes) ([02 · memory_and_gc](../02%20Advanced%20Dart/memory_and_gc.md)).

## Compiler Behavior

Both use **codegen** (Isar schemas / Hive adapters) via `build_runner`; Isar queries are typed (compile-checked filters). Hive get/put by key is typed by the box's type but has no query DSL.

## Runtime Behavior

Isar queries are fast (indexed) and can `watch()` for reactivity; Hive lookups are O(1) by key; scanning a Hive box for "queries" is O(n). Both async-open; writes persist immediately.

## Flutter Engine Behavior

Native fast I/O via the plugin; Isar supports background-isolate queries ([02 · isolates](../02%20Advanced%20Dart/isolates.md)).

## Dart VM Behavior

Not applicable beyond async.

## Examples

```yaml
# pubspec.yaml
dependencies:
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  hive: ^2.2.0
  hive_flutter: ^1.1.0
dev_dependencies:
  isar_generator: ^3.1.0
  hive_generator: ^2.0.0
  build_runner: ^2.4.0
```

```dart
// --- Isar: typed, indexed, reactive ---
import 'package:isar/isar.dart';
// part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;
  @Index() late String category;   // indexed -> fast query
  late String name;
  late double price;
}

Future<void> isarDemo(Isar isar) async {
  await isar.writeTxn(() => isar.products.put(Product()..category = 'book'..name = 'Dart'..price = 9.99));
  // typed, indexed query:
  final books = await isar.products.filter().categoryEqualTo('book').sortByPrice().findAll();
  // reactive stream (auto-updates):
  final stream = isar.products.filter().categoryEqualTo('book').watch(fireImmediately: true);
  stream.listen((list) {/* UI updates */});
}

// --- Hive: simple key-object ---
import 'package:hive/hive.dart';
Future<void> hiveDemo() async {
  final box = await Hive.openBox<String>('settings'); // key -> object box
  await box.put('theme', 'dark');   // instant put
  final theme = box.get('theme');   // O(1) lookup
}
```

## Diagrams

```mermaid
flowchart LR
    Need{typed + queries + reactive?}
    Need -- yes --> Isar
    Need -- no, simple key lookup --> Hive
    Both --> Objects[persist Dart objects directly (no SQL/joins)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Hive for queryable/relational data | No real querying/joins | Use Isar or SQL (Drift) |
| Huge Hive box in memory | RAM bloat | Use Isar (lazy/mmap) or bound data |
| No indexes in Isar for filtered fields | Slow scans | `@Index()` filtered/sorted fields |
| Forgetting `build_runner` (adapters/schemas) | Codegen missing | Run/watch codegen |
| Leaking stored objects to UI | Coupling/lock-in | Map to entities in a repository |
| Expecting joins in either | They're NoSQL | Model with links (Isar) or denormalize |

## Best Practices

- Pick **Isar** for typed objects needing queries/relations/reactivity; **Hive** for simple key-object storage/caches.
- **Index** Isar fields you filter/sort by; bound queries (`limit`); use `.watch()` for reactive UI.
- Keep **Hive boxes reasonable**; don't treat a box as a queryable table (no filters/joins).
- Run codegen (adapters/schemas); front behind a **repository** mapping stored objects→entities.
- For relational/reporting needs, prefer **SQL (Drift)** instead ([drift.md](drift.md)).

## Performance

Isar (mmap + indexes) is very fast for typed queries and scales to large datasets; Hive is fastest for key lookups but scans are O(n) and big boxes eat RAM. Index Isar queries; keep Hive boxes bounded ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+ Isar:** fast, typed, indexed queries, links, reactive, large datasets. **+ Hive:** trivial API, extremely fast key lookups, minimal setup.
- **− Isar:** codegen/setup, NoSQL (no SQL joins). **− Hive:** weak querying, in-memory box cost, not for relational/large-query data.

## Interview Questions

1. **🟢 Isar vs Hive?** — Isar: typed NoSQL with indexed queries, links, and reactive streams (large/queryable data); Hive: simple, very fast key→object boxes with minimal querying.
2. **🟢 When choose a NoSQL object store over SQL?** — For object-shaped, schemaless, or speed-first data without relational joins/reporting needs.
3. **🟡 How do you get fast queries in Isar?** — Add `@Index()` to filtered/sorted fields; use typed filter queries with `limit`.
4. **🟡 Why is scanning a Hive box for "queries" a problem?** — Hive has no query engine; filtering iterates the whole box (O(n)) — use Isar/SQL for real queries.
5. **🟡 How do both persist data?** — As Dart objects directly (via codegen schemas/adapters), no SQL tables.
6. **🔴 What's the memory difference between Isar and Hive at scale?** — Isar uses memory-mapped files (lazy, large-dataset friendly); Hive tends to hold boxes in memory (large boxes = high RAM).
7. **🔴 How do you avoid lock-in/coupling with these?** — Wrap in a repository mapping stored objects→domain entities so the domain doesn't depend on Isar/Hive types.

## Senior Engineer Tips

- Default to **Isar** for object-heavy apps needing queries + reactivity; use **Hive** only for simple key-object caches/settings.
- Index every field you filter/sort on in Isar; unindexed queries silently degrade to scans.
- Keep Hive boxes small and purpose-specific; if you're iterating a box to "query," you picked the wrong tool.

## Architect Perspective

Isar/Hive give object-native persistence — Isar as a fast, queryable, reactive NoSQL DB (viable local source of truth for offline-first — [Module 19](../19%20Offline%20First/README.md)); Hive as a lightweight key-object cache. The SQL-vs-NoSQL choice ([database_options.md](database_options.md)) hinges on relational/query needs; behind repositories, either keeps the domain clean and swappable.

## Summary

- Isar: typed NoSQL, indexed queries, links, reactive — fast and scalable. Hive: simple/fast key→object boxes, weak querying.
- Persist Dart objects directly (no SQL); index Isar queries, keep Hive boxes small, front behind repositories.
- Prefer SQL (Drift) for relational/reporting; NoSQL object stores for object/speed-first data.

## Revision Notes

- Isar: `@collection`/`@Index` + codegen; typed filter queries + `.watch()`; mmap, large datasets, background isolates.
- Hive: boxes (key→object via `TypeAdapter`), O(1) get/put, minimal querying, in-memory (keep small).
- Both NoSQL (objects, no joins); index Isar; repository maps objects→entities.
- Relational/reporting → SQL (Drift); object/speed → Isar/Hive.

## Practice Questions

1. When is Hive enough vs needing Isar?
2. Why index Isar query fields?
3. Why is a NoSQL object store a poor fit for relational reporting?

## Coding Questions

1. Model a `Product` Isar collection with an index + a filtered reactive query.
2. Store/retrieve settings in a typed Hive box.
3. Wrap an Isar collection in a repository mapping objects→entities.

## Mini Project

**Object cache (Flutter):** Build an Isar-backed `ProductRepository` with an indexed category query and a reactive `watch`, mapped to entities, plus a Hive box for simple app settings. Benchmark an indexed vs unindexed Isar query. Acceptance: typed indexed queries + reactive stream; Hive for key-object settings; objects mapped to entities; index benefit shown; runs.
