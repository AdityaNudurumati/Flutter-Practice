# Caching, Offline & Scale Trade-offs

> The mobile-defining part of the design: choose **where and how to cache** (memory/disk/DB, per data type), a **freshness strategy** (cache-first / network-first / **stale-while-revalidate**, with TTL + validators), an **offline model** (read-only cached snapshot vs full offline-first with an outbox + sync + **conflict resolution**), and reason about **scale + trade-offs** on the client (large lists, image memory, storage growth, battery). The unifying tension is **consistency vs availability vs cost**: fresher data means more network/battery; offline means sync/conflict complexity. Senior design is **picking and justifying** the right point on these spectra for the requirements.

## Introduction

This file covers the caching/offline/scale layer of the design — the part most distinctive to mobile. It ties together caching strategy, offline models, sync/conflict resolution, and client-side scale trade-offs, drawing on offline-first ([Module 19](../19%20Offline%20First/README.md)), storage ([Module 20](../20%20Database/README.md)/[Module 34](../34%20File%20Handling/README.md)), and performance ([Module 21](../21%20Performance/README.md)).

## Why this concept exists

On mobile, the network is the bottleneck and offline is the norm at times, so **caching and offline strategy dominate perceived performance and reliability** — and they're where the hard trade-offs live (freshness vs battery, availability vs consistency, storage vs re-fetch). Designing them deliberately (not "just cache everything") is the crux of a good mobile design.

## Real-world analogy

It's **stocking the expedition vehicle**: you decide **what to carry** (cache) vs **fetch from base** (network), **how fresh supplies must be** (TTL/freshness), and whether you can **operate fully off-grid** (offline-first with your own log to reconcile later) or only **read your last resupply** (read-only snapshot). Carrying more means heavier load (storage/memory); insisting on fresh means frequent trips (battery/data). You **stock for the mission's actual needs** — over-stocking and under-stocking both cost you.

## Internal Working

```mermaid
flowchart TD
    Cache[caching: where (memory/disk/DB) + freshness (TTL/validators)] --> Strategy{read strategy}
    Strategy -->|cache-first| CF[fast/offline, may be stale]
    Strategy -->|network-first| NF[fresh, needs network]
    Strategy -->|stale-while-revalidate| SWR[instant cache + background refresh]
    Offline{offline model} -->|read-only snapshot| Snap[cache last data; writes need network]
    Offline -->|offline-first| OF[local writes -> outbox -> sync -> conflict resolution]
    Scale[client scale: lists/images/storage/battery] --> Tradeoffs[consistency vs availability vs cost]
```

- **Where to cache** (by data type):
  - **In-memory** (fast, volatile) for hot/session data; **disk/files** for blobs/images (bounded — [Module 34](../34%20File%20Handling/README.md)); **local DB** (sqflite/Drift/Isar/Hive) for structured, queryable, persistent data ([Module 20](../20%20Database/README.md)). **secure storage** for tokens ([Module 37](../37%20Security/README.md)).
  - Match store to access pattern (query? blob? ephemeral?).
- **Freshness strategy** (per data type):
  - **Cache-first**: serve cache, maybe refresh in background — **fast + offline-capable**, may be **stale**. Great for feeds/read-heavy.
  - **Network-first**: fetch, fall back to cache — **fresh**, needs network. For must-be-current data (balances).
  - **Stale-while-revalidate (SWR)**: show cache **instantly** + refresh in background + update UI — the **best-of-both** default for most reads.
  - **TTL + validators**: age-based freshness (TTL) + **ETag/Last-Modified** conditional GET to skip unchanged ([Module 34](../34%20File%20Handling/README.md)). Cache is **re-fetchable** (OS may clear).
- **Offline model** (choose per requirements):
  - **Read-only offline snapshot**: cache last-fetched data for offline **reading**; **writes require network**. Simple; enough for many apps.
  - **Full offline-first**: local writes succeed offline → **outbox queue** → **sync** on reconnect → **conflict resolution** (last-write-wins / server-wins / merge / CRDTs) → optimistic UI + reconcile. Powerful but **complex** ([Module 19](../19%20Offline%20First/README.md)). Justify the complexity against the requirement.
  - **Conflict resolution** is the hard part: decide the policy (LWW is simple but loses data; merge/CRDT is correct but complex); design idempotent sync ([Module 31](../31%20Payments/README.md)).
- **Client-side scale trade-offs** (the "scale" that matters on-device):
  - **Large lists** → cursor pagination + virtualization + paged cache (don't hold everything).
  - **Images/blobs** → bounded disk cache + resized variants + memory limits (top memory offender).
  - **Storage growth** → eviction (TTL/LRU/size budget), don't cache unbounded; cache is re-fetchable.
  - **Battery/data** → SWR/push over aggressive polling; batch sync; sync on wifi/charging where possible.
- **The core tensions (articulate them)**:
  - **Consistency vs availability**: offline/cache-first = available but possibly stale; network-first = fresh but unavailable offline.
  - **Freshness vs cost**: fresher = more network/battery.
  - **Simplicity vs capability**: read-only snapshot (simple) vs full offline-first (capable, complex).
  - Senior design = **choosing a justified point** per data type, not maximal everything.
- **Consistency model**: mobile is usually **eventually consistent** (cache + eventual sync); state this explicitly and design reconciliation for it.

## Memory Representation

Design artifact: a **per-data-type table** (where cached, freshness strategy, TTL/validators, offline model). Runtime: memory/disk/DB caches + an outbox (for offline-first) + eviction policies. The invariant: bounded, re-fetchable caches; eventual consistency via sync.

## Compiler / Runtime / Engine / VM Behavior

Design-level (implemented via storage/networking/offline modules). Runtime characteristics you design for: cache-hit latency (instant/offline), sync timing (eventual), memory/storage bounds, and battery cost of freshness/sync.

## Examples

```text
Per-data-type caching/offline design (feed app):
  Data           Where          Freshness            Offline model
  ----           -----          ---------            -------------
  Feed posts     local DB       stale-while-revalid. read-only snapshot (offline read)
  Post images    disk cache     TTL + LRU + size cap re-fetchable (OS may clear)
  Account balance (not cached)  network-first        no offline (must be fresh)
  Draft/compose  local DB       n/a                  FULL offline-first (outbox + sync + LWW)
  Auth token     secure storage n/a                  persisted (short-lived + refresh)

Trade-off statements to say out loud:
  "Feed = cache-first/SWR -> available offline, eventually consistent (acceptable for a feed)."
  "Balance = network-first -> must be fresh; show 'unavailable offline' rather than stale money."
  "Drafts = offline-first with LWW -> simple conflict policy; acceptable since single-user edits."
```

```mermaid
flowchart LR
    Read[read] --> SWR2[stale-while-revalidate (default): instant cache + bg refresh]
    Write[write offline?] -->|no| NeedsNet[network required (snapshot model)]
    Write -->|yes| Outbox[outbox -> sync -> conflict resolution (offline-first)]
    Scale2[scale] --> Bound[paginate + virtualize + bounded caches + evict]
```

## Diagrams

```mermaid
flowchart TD
    Requirements[NFRs: offline? freshness? consistency?] --> Choose[choose per data type]
    Choose --> Cache2[cache location + freshness (SWR/cache-first/network-first + TTL/validators)]
    Choose --> Offline2[offline model (snapshot vs offline-first + conflict policy)]
    Choose --> Scale3[scale: pagination/virtualization/bounded caches/battery]
    Cache2 & Offline2 & Scale3 --> Justify[justify: consistency vs availability vs cost]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| "Cache everything" (one strategy) | Different data needs different freshness | Choose strategy per data type |
| Full offline-first when not needed | Huge complexity (sync/conflicts) | Read-only snapshot if writes-offline aren't required |
| Ignoring conflict resolution | Data loss/corruption on sync | Explicit policy (LWW/server-wins/merge/CRDT) |
| Unbounded caches | Storage/memory bloat | TTL/LRU/size eviction; re-fetchable |
| Showing stale money/critical data | Wrong/unsafe | Network-first for must-be-fresh data |
| Aggressive polling for freshness | Battery/data drain | SWR + push; batch/conditional sync |
| Not stating the consistency model | Ambiguous design | Declare eventual consistency + reconciliation |
| Holding entire list/images in memory | OOM/jank | Paginate + virtualize + bounded image cache |

## Best Practices

- Choose **caching per data type** (where + freshness): **SWR** as the default read strategy, **network-first** for must-be-fresh data, **cache-first** for read-heavy; use **TTL + validators**; keep caches **bounded + re-fetchable**.
- Pick the **offline model per requirement**: **read-only snapshot** (simple) unless offline **writes** are required, then **full offline-first** (outbox + sync + explicit **conflict resolution**) — justify the complexity.
- Design **client-side scale**: cursor pagination + virtualization + paged/bounded caches + image memory limits + battery-aware sync (SWR/push, batch, wifi/charging).
- **State the consistency model** (usually eventual) and **articulate the trade-offs** (consistency vs availability vs cost) for each choice.

## Performance

Caching/offline strategy *is* mobile performance: SWR gives instant reads + freshness; bounded caches keep memory/storage sane; pagination/virtualization keep lists smooth; battery-aware sync avoids drain. The trade-offs (fresh vs battery, available vs consistent) are performance/UX decisions made explicit ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** (Deliberate per-data strategy) fast + resilient + battery-friendly UX, correct freshness where it matters, bounded resource use, justified trade-offs.
- **−** More design effort (per-data decisions), offline-first complexity (sync/conflicts), cache-invalidation subtlety, eventual-consistency UX handling.

## Interview Questions

1. **🟢 What caching read strategies are there, and a good default?** — Cache-first, network-first, and stale-while-revalidate; SWR (instant cache + background refresh) is a strong default for most reads.
2. **🟢 Read-only snapshot vs full offline-first — how to choose?** — Snapshot (cache for offline reads; writes need network) unless the requirement demands offline *writes*, which needs full offline-first (outbox + sync + conflict resolution).
3. **🟡 What's the hard part of offline-first, and the options?** — Conflict resolution: last-write-wins (simple, lossy), server-wins, merge, or CRDTs (correct, complex) — plus idempotent sync.
4. **🟡 Which data should NOT be cached/served stale?** — Must-be-fresh/critical data (balances, live prices) — use network-first and show "unavailable offline" rather than stale.
5. **🟡 How do you handle client-side scale (big lists/images)?** — Cursor pagination + list virtualization + paged/bounded caches + resized images + memory limits; battery-aware sync.
6. **🔴 What are the core trade-offs to articulate?** — Consistency vs availability (offline/cache = available but stale; network-first = fresh but offline-unavailable) and freshness vs cost (fresher = more network/battery).
7. **🔴 What consistency model do mobile apps usually have, and why state it?** — Eventual consistency (cache + eventual sync); stating it clarifies reconciliation design and sets UX expectations.

## Senior Engineer Tips

- Make caching/offline decisions **per data type** in a small table (where/freshness/offline model); "one strategy for everything" is the tell of a shallow design.
- Default reads to SWR and reserve network-first for genuinely must-be-fresh data; never show stale money/critical values to save a request.
- Only reach for full offline-first when offline *writes* are a real requirement — its sync/conflict complexity is large, and a read-only snapshot satisfies most apps.

## Architect Perspective

Caching, offline, and client-side scale are where mobile system design is won or lost, because the network is unreliable and the device is constrained. The senior move is a **per-data-type strategy** (location + freshness + offline model) that lands each datum at a justified point on the consistency/availability/cost spectra, with bounded caches, pagination, and battery-aware sync — and an explicit consistency model. This synthesizes offline-first, storage, and performance into the resilience layer of the design, feeding directly into the interview approach and the end-to-end capstone ([Module 19](../19%20Offline%20First/README.md), [Module 20](../20%20Database/README.md), [Module 21](../21%20Performance/README.md), [04_mobile_system_design_interview.md](04_mobile_system_design_interview.md)).

## Summary

- Cache per data type (memory/disk/DB) with a freshness strategy (SWR default; network-first for fresh-critical; cache-first for read-heavy) + TTL/validators; keep caches bounded + re-fetchable.
- Choose the offline model per requirement (read-only snapshot vs full offline-first with outbox + sync + conflict resolution); justify complexity.
- Design client scale (pagination/virtualization/bounded caches/battery-aware sync); state the (usually eventual) consistency model and articulate consistency-vs-availability-vs-cost trade-offs.

## Revision Notes

- Cache location by type: memory (hot), disk (blobs, bounded), local DB (structured/queryable), secure storage (tokens). Freshness: cache-first / network-first / **SWR** (default) + TTL + ETag/Last-Modified; bounded + re-fetchable.
- Offline model: read-only snapshot (simple; writes need net) vs full offline-first (outbox + sync + conflict resolution: LWW/server-wins/merge/CRDT + idempotent); justify.
- Scale: cursor pagination + virtualization + paged/bounded caches + image memory limits + battery-aware sync (SWR/push/batch/wifi-charging). Consistency usually eventual — state it; articulate consistency vs availability vs cost.

## Practice Questions

1. When do you choose cache-first vs network-first vs SWR?
2. Read-only snapshot vs full offline-first — how do you decide, and what's the hard part?
3. What client-side scale issues arise for big lists/images, and their fixes?

## Coding Questions

1. Build a per-data-type caching/offline table for a given app (where/freshness/offline model).
2. Design an SWR read flow + a bounded image cache.
3. Design an offline-first write path (outbox + sync + a chosen conflict policy).

## Mini Project

**Caching/offline/scale design (Flutter/design):** For a feed + compose app, produce a per-data-type caching/offline table (feed=SWR/snapshot, images=disk TTL/LRU, balance=network-first/no-offline, drafts=offline-first LWW, token=secure), design the SWR read + offline-first write (outbox/sync/conflict) flows, address client-side scale (pagination/virtualization/bounded caches/battery-aware sync), and articulate the consistency-vs-availability-vs-cost trade-offs + the (eventual) consistency model. Acceptance: per-data-type strategy (not one-size); SWR default + network-first for fresh-critical; justified offline model + conflict policy; bounded caches + pagination/virtualization + battery-aware sync; consistency model + trade-offs stated.
