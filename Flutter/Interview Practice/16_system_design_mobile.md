# Mobile System Design (Flutter) — Interview Questions

> How to design a Flutter client end-to-end under real mobile constraints: offline, flaky network, battery, app size, sync, and rollout. For depth see [48 System Design](../48%20System%20Design/README.md) and [19 Offline First](../19%20Offline%20First/README.md).

This topic tests whether you can scope a mobile feature and reason about the *client* as a system — not just draw boxes for servers. Interviewers push from "how would you call this API" toward "how does the app behave on a subway with 2% battery, on a 3-year-old phone, on app version N-3, with 50k queued writes".

## 🟢 Basic

**1. How does a mobile system design interview differ from a backend one?**
Backend rounds optimize a server you fully control: throughput, sharding, consistency, availability. Mobile rounds optimize a client you *don't* control — it runs on someone else's device, on a network you can't trust, and on an app version you can't force-update instantly. The scarce resources flip: instead of CPU/DB, you're rationing battery, memory, disk, cellular data, cold-start time, and app-store binary size. Correctness now includes offline behavior and eventual consistency. A strong candidate leads with these client constraints instead of designing a distributed backend.

**2. What are the core client-side constraints you should name up front?**
- **Flaky/variable network** — connections drop, switch WiFi↔cellular, have high latency and packet loss; requests must be retryable and cancellable.
- **Offline** — the app must do something useful with no connectivity, not just show a spinner.
- **Battery & radio** — waking the cellular radio and GPS is expensive; batch and defer work.
- **Limited memory** — the OS kills backgrounded apps; large images/lists cause OOM.
- **App (binary) size** — every MB hurts install/update conversion; watch assets and native deps.
- **Versioning** — many app versions run in the wild simultaneously; your API and schema must tolerate old clients (and you need forced-update for the ones you can't).
- **Deep linking** — the app can be entered at any screen from a URL/notification.

**3. Walk me through a framework for answering a mobile design question.**
1. **Requirements** — functional (what screens/actions) and non-functional (offline? real-time? scale? latency budget?). Clarify, don't assume.
2. **API contract** — endpoints, request/response shapes, pagination, error model, auth.
3. **Data model** — domain entities and their relationships.
4. **Local cache / DB** — what persists on device, in what store, with what schema.
5. **Sync strategy** — how local and server state reconcile, including conflicts.
6. **State management / architecture** — layering (UI → domain → data), which state solution, DI.
7. **Non-functionals** — offline, performance, security, observability, rollout, testing.
Say it out loud as a checklist; it signals structure and keeps you from rat-holing on the backend.

**4. What does "requirements gathering" look like for a client feature?**
Ask scoping questions that change the design: *Does it work offline? Read-only or does the user create data? Real-time updates or pull-to-refresh? How large is the dataset (10 items vs infinite feed)? What's the latency expectation? Which platforms? Existing auth?* Each answer flips a decision — e.g. "must work offline + user writes" forces a local DB and a sync queue, while "read-only, small, online-only" is just an in-memory cache.

**5. Why is the repository the key boundary in a mobile system?**
The repository is the single seam between the domain layer and *all* data sources (network, DB, cache, prefs). The UI/domain asks the repository for data and never knows whether it came from the server or SQLite. This lets you implement offline-first (serve cache, refresh in background), swap sources, retry, and test the domain with a fake repo. In an interview, draw the repository as the box where the offline/caching/sync policy lives.

**6. What's a good default layered architecture for the client?**
`UI (widgets) → State (BLoC/Riverpod/ViewModel) → Domain (use cases + entities) → Data (repositories → data sources)`. Dependencies point inward; the domain has no Flutter or HTTP imports. This is Clean Architecture applied to a client. It matters here because it isolates the volatile parts (API shapes, DB) behind stable interfaces, which is exactly what you need when the backend and app versions drift.

**7. What is offline-first and when do you need it?**
Offline-first means the local store is the source of truth for the UI: reads come from the DB, writes go to the DB immediately (optimistic), and a background process syncs with the server. You need it when users create/edit data on the go (notes, messaging, field apps) or when connectivity is unreliable. Contrast with "offline-tolerant" (cache-only reads, no local writes) which is much simpler. See [19 Offline First](../19%20Offline%20First/README.md).

**8. What is optimistic UI and why does it matter on mobile?**
Optimistic UI applies a user action to local state/UI *immediately*, before the server confirms, then reconciles when the response arrives (or rolls back on failure). It hides network latency and makes the app feel instant on flaky connections. The cost is you must handle rollback and conflicts. Classic examples: sending a chat message (shows as "sending"), liking a post, adding a to-do.

**9. How do you handle pagination for long lists?**
Two common contracts: **offset/limit** (`?page=2&size=20`) — simple but breaks when items shift; and **cursor/keyset** (`?after=<opaque_cursor>`) — stable under inserts/deletes, preferred for feeds. On the client, fetch the next page when the scroll nears the end, append to the list, dedupe by ID, and show a footer loader. Cache pages so back-navigation is instant.

**10. What are the options for getting real-time updates to a mobile client?**
- **Polling** — client asks on an interval; simple, works everywhere, wastes battery/data and is stale between polls.
- **Long-polling** — request held open until data or timeout; less waste, more server load.
- **SSE (Server-Sent Events)** — one-way server→client stream over HTTP; great for feeds/notifications, simple to proxy.
- **WebSockets** — full-duplex; needed for chat, presence, collaborative editing.
- **Push (FCM/APNs)** — OS-level delivery even when the app is closed; use it to *wake* the app, not to carry payloads reliably.

**11. Why can't push notifications be your source of truth?**
FCM/APNs are best-effort: messages can be dropped, delayed, coalesced, or throttled, and the OS may not wake a killed app. Treat a push as a *hint* ("something changed, come sync") — its payload should be minimal, and the app must fetch authoritative data from the API on receipt. Designing a chat app that relies on push payloads to deliver every message is a red flag.

**12. What is a deep link and why does it affect your architecture?**
A deep link is a URL (or notification) that opens the app directly at a specific screen/state, e.g. `myapp://chat/42`. It forces your navigation/routing to be declarative and reconstructable from a URL — you must be able to build the whole back stack for an arbitrary destination, handle the not-logged-in case, and cold-start into it. This is why URL-based routers (go_router) are the interview-safe answer over imperative `Navigator.push`.

## 🟡 Intermediate

**13. Design the API contract and error model before coding — what do you specify?**
Endpoints + verbs, request/response JSON shapes, pagination scheme, and a **consistent error envelope** (e.g. `{ "code": "RATE_LIMITED", "message": ..., "retryable": true }`). Specify auth (bearer token + refresh), idempotency keys for writes, and versioning (`/v1`). Client-side you map transport errors and status codes into a small domain `Failure` type (`NetworkFailure`, `AuthFailure`, `ServerFailure`, `ConflictFailure`) so the UI reasons about *meaning*, not HTTP codes. See [16 Networking](../16%20Networking/README.md).

**14. Why do writes need idempotency keys, and where does the client generate them?**
On flaky networks a request may succeed on the server but time out on the client, which then retries — creating duplicates (double-posted message, double payment). The client generates a UUID per logical operation and sends it (header or body); the server dedupes on it. The client stores this key in its outbox so a retry reuses the *same* key. This is the single most important detail for correct retries.

**15. How do you choose a local storage tier?**
| Need | Use |
|---|---|
| Small key/value flags, tokens | `shared_preferences` (non-sensitive) / secure storage (tokens) |
| Structured, queryable, relational | SQLite via `drift`/`sqflite` |
| Fast object store, simple | `hive` / `isar` |
| Large blobs (images, files) | File system + path, store path in DB |
Don't put images in SQLite or tokens in prefs. Pick relational (drift) when you need joins, migrations, and complex queries — which most offline-first apps eventually do. See [15 Local Storage](../15%20Local%20Storage/README.md) and [20 Database](../20%20Database/README.md).

**16. Describe a cache with a staleness policy.**
Store each entity with a `fetchedAt` timestamp. On read, the repository returns cached data immediately (stale-while-revalidate) and kicks off a network refresh if `now - fetchedAt > ttl`. Use `ETag`/`If-None-Match` or `Last-Modified`/`If-Modified-Since` so a refresh returns `304 Not Modified` with no body when nothing changed — saving battery and data. Distinguish TTL (soft, triggers refresh) from hard expiry (evict/never serve).

**17. How does offline-first sync actually work — the outbox pattern?**
Local writes go into the DB and are appended to an **outbox** (a pending-operations queue) with an idempotency key and status. A sync worker drains the outbox when connectivity returns (listen to `connectivity_plus`), sending each op, marking it synced or failed-with-retry (exponential backoff). Reads always come from the DB, so the UI is consistent regardless of network. The server change feed (or a pull) brings remote changes back down. This decouples user actions from network availability.

**18. How do you detect and pull remote changes efficiently?**
Delta sync: the client stores a high-water mark (a server `updatedAt` timestamp or a monotonic `sync_token`/cursor) and asks `GET /changes?since=<token>`. The server returns only rows changed since then, plus a new token. This avoids re-downloading everything and scales to large datasets. Tombstones (soft-delete rows with a `deleted` flag) let deletes propagate — a plain "row missing" is ambiguous over deltas.

**19. What conflict-resolution strategies exist and when do you use each?**
- **Last-write-wins (LWW)** — compare timestamps/versions, newest wins. Simple, lossy; fine for single-user-multi-device settings.
- **Server-wins / client-wins** — one side is authoritative; predictable but discards intent.
- **Merge / field-level** — combine non-conflicting fields; good for documents.
- **CRDTs** — conflict-free replicated data types converge automatically; used for real collaborative editing (notes, whiteboards) but complex.
- **Prompt the user** — surface the conflict (rare, high-value data).
Pick based on data value and multi-writer likelihood. Most apps start with LWW + version numbers and escalate only where it hurts.

**20. How do you version an API/schema so old clients don't break?**
Additive, backward-compatible changes: never remove or repurpose a field; add new optional fields; version the base path (`/v1`) for breaking changes and run versions in parallel during migration. Clients must ignore unknown fields (tolerant reader). For the local DB, ship ordered, tested migrations (drift/sqflite `onUpgrade`) and never assume a fresh install. Because users sit on old app versions for months, the server contract is effectively forever.

**21. When and how do you force an app update?**
When an old client is unsafe or incompatible (breaking API change, security fix, broken protocol). Implement a **minimum-supported-version** check: the app sends its version, or fetches a `minVersion` from a config/feature-flag endpoint on launch; if below, show a blocking "Update required" screen linking to the store. Keep a soft-nudge tier for recommended updates. Never hard-block without a server-controlled kill switch — you may need to relax it.

**22. Design the image/media pipeline for a media-heavy app.**
- **Server** provides multiple sizes/thumbnails and a CDN URL (don't download a 4MB original for a 100px avatar); support `WebP/AVIF`.
- **Client** uses `cached_network_image` (memory + disk cache), requests the right resolution via `cacheWidth`/`cacheHeight` so it decodes downscaled and doesn't blow up memory.
- **Uploads** compress/resize on device first, upload in the background with resumable/multipart requests, show progress, and retry.
- Cap the disk cache and evict LRU. Placeholders + fade-in for perceived speed.

**23. How do you keep app size and cold-start under control?**
Split ABIs / use app bundles (Play delivers per-device), tree-shake icons, compress/deduplicate assets, lazy-load features (deferred components / dynamic feature modules), and audit heavy native deps. For cold start, defer non-critical init off the first frame, avoid synchronous disk/network in `main()`, and pre-warm nothing you don't render. Measure with `--analyze-size` and startup traces. See [21 Performance](../21%20Performance/README.md).

**24. What belongs in feature flags vs A/B tests, and how do they reach the client?**
**Feature flags** gate code paths (kill switch, gradual rollout, entitlement); **A/B tests** assign users to variants and measure a metric. Both come from a remote config service (Firebase Remote Config, LaunchDarkly) fetched on launch with a cached fallback so a config-server outage doesn't brick the app. Evaluate flags behind an interface so the rest of the app just reads `flags.isEnabled('newFeed')`, and default to the safe value when config is unavailable.

**25. What client observability do you need and why?**
Crash reporting (Crashlytics/Sentry), structured logs, performance traces (cold start, frame drops, network latency), and analytics events for funnels. On mobile you're blind without it — you can't SSH into a user's phone. Tie events to app version and device class so you can spot a regression scoped to one rollout. Respect privacy: no PII in logs, sample high-volume events. See [52 Monitoring](../52%20Monitoring/README.md).

## 🔴 Advanced

**26. How do you roll out a risky client change safely?**
Ship it dark behind a feature flag, do a **staged rollout** on the store (1% → 5% → 25% → 100%) while watching crash-free-sessions and key metrics, and keep a server-side kill switch to disable the feature without a new binary. Because you can't recall a bad build instantly, the flag + kill switch is your real rollback. Halt/roll back the store rollout on regression, and add a forced-update floor only for truly broken versions.

**27. At scale, how do you keep sync efficient with tens of thousands of local records?**
Never full-sync: use cursor-based delta sync with tombstones and a per-entity high-water mark. Batch and paginate the change feed. Do writes through a bounded outbox with backoff and coalescing (collapse repeated edits to the same record before sending). Run sync in a background isolate / WorkManager job so it doesn't jank the UI, and index the DB columns you filter/sort on. Guard against thundering-herd on reconnect by jittering retry timers.

**28. WebSocket vs SSE vs push — how do you combine them for a chat app?**
Use a **WebSocket** for the active conversation (low-latency bidirectional messages, typing/presence). Use **push (FCM/APNs)** to wake the app and notify when it's backgrounded/killed — the push just says "new message in room X", and the app fetches authoritative messages over REST/WS. SSE is a lighter alternative when you only need server→client (e.g. a live feed, not chat). The durable source of truth is always the server's message store fetched by ID/cursor, never the transport.

**29. How do you guarantee message ordering and no-loss in chat over a flaky link?**
Server assigns a monotonic, gap-detectable sequence (per-room `seq` or Lamport/HLC clock); the client orders by it and can detect a gap → refetch the range. Outbound messages carry a client-generated idempotency/temp ID so retries dedupe and the server echo reconciles the optimistic bubble. On reconnect, the client sends its last-seen `seq` and pulls the delta. Acks move state `sending → sent → delivered → read`. This is delta sync applied to a message log.

**30. How do you secure data and tokens on the client?**
Store tokens in platform secure storage (Keychain/Keystore via `flutter_secure_storage`), never in `shared_preferences`. Use short-lived access tokens + refresh tokens with silent refresh-on-401 in an interceptor. Pin certificates for high-value APIs, encrypt sensitive local DBs (SQLCipher), and assume the device can be rooted — don't trust client-side checks for anything security-critical; enforce on the server. See [37 Security](../37%20Security/README.md) and [17 Authentication](../17%20Authentication/README.md).

**31. How do you test an offline-first system design?**
Unit-test the repository and sync logic with fake data sources and a controllable clock/connectivity. Test conflict resolution with concrete divergent-edit scenarios. Integration-test the outbox: enqueue offline, toggle connectivity, assert the server received deduped, correctly-ordered ops. Simulate flaky network (latency, drops, 500s) to verify retries/backoff. The design is only as good as its behavior at the boundaries, so most bugs live in sync — test it hardest. See [49 Testing](../49%20Testing/README.md).

**32. What are common mistakes candidates make in a mobile design round?**
Designing the backend instead of the client; ignoring offline and assuming connectivity; treating push payloads as reliable delivery; no idempotency on retried writes; putting business logic in widgets; unbounded caches (memory/disk) causing OOM; full re-sync instead of deltas; forgetting versioning/forced-update and deep linking; and no observability. Also: jumping to code before stating requirements and the API contract.

**33. How would you architect for multiple app versions in the wild simultaneously?**
Assume version N-k is live for months. Keep the API additive and version-gated; feature-flag new behavior so the server can turn features on only for capable versions; use a `minVersion` gate for forced updates. Make the local DB migrations forward-only and tested against every prior schema. Design analytics/crash data to carry the app version so you can diff behavior per version. Never make a server change that assumes all clients upgraded overnight.

**34. WORKED — Design an offline notes app. Sketch the design.**
- **Requirements**: create/edit/delete notes offline, sync across the user's devices, search, near-instant UI. Multi-device single-user → conflicts possible.
- **API**: `GET /notes?since=<token>` (delta + tombstones), `POST /notes` / `PATCH /notes/:id` with idempotency key + `version`, `DELETE /notes/:id` (soft delete).
- **Data model**: `Note { id (client-generated UUID), title, body, updatedAt, version, deleted }`.
- **Local DB**: SQLite/drift; `notes` table + `outbox` table (op, payload, idempotencyKey, status). FTS index for search.
- **Reads**: always from DB → instant, works offline.
- **Writes**: write DB + enqueue outbox (optimistic). Sync worker drains outbox on connectivity, uses server `version` for **LWW/field-merge** conflict resolution; server bumps `version`.
- **Pull**: delta sync with `sync_token`; apply tombstones.
- **Architecture**: `NotesRepository` as the boundary; Riverpod/BLoC for state; go_router with deep links to a note.
- **Non-functionals**: encrypt DB if notes are sensitive, cap outbox with backoff, observability on sync failures.

**35. WORKED — Design a news feed. Sketch the design.**
- **Requirements**: infinite personalized feed, read-mostly, works semi-offline (show last feed), pull-to-refresh, media-heavy, huge scale (read latency + battery matter).
- **API**: `GET /feed?cursor=<opaque>&limit=20` returning items + `nextCursor` (keyset pagination, stable under inserts). Items reference media by CDN URL with multiple sizes.
- **Data model**: `FeedItem { id, authorId, text, mediaRefs[], createdAt, counters }`.
- **Local cache**: SQLite table of feed items keyed by id + a `feed_page` ordering table; `fetchedAt` for staleness. Serve cached feed on cold start (stale-while-revalidate), refresh top on pull.
- **Pagination**: cursor-based; prefetch next page near scroll end; dedupe by id.
- **Media**: `cached_network_image` with sized thumbnails + `cacheWidth`; bounded LRU disk cache.
- **Real-time**: lightweight — pull-to-refresh + optional SSE/push "new posts available" pill; no WebSocket needed.
- **Architecture**: `FeedRepository` merges cache + network; BLoC with `FeedState(items, hasMore, isLoadingMore)`.
- **Non-functionals**: rank server-side (client stays dumb), feature-flag ranking experiments (A/B), analytics on impressions/scroll depth, staged rollout of ranking changes, virtualized `ListView.builder` for memory.

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| First thing to state in a mobile design round? | Requirements — functional + non-functional (offline? real-time? scale?). |
| Where does caching/offline/sync policy live? | The repository (the domain↔data boundary). |
| Best pagination for a feed? | Cursor/keyset — stable under inserts/deletes. |
| Make a retried write safe how? | Client-generated idempotency key, reused on retry. |
| Reliable message delivery via push? | No — push is a hint; fetch authoritative data from the API. |
| Chat transport? | WebSocket active + push to wake when backgrounded. |
| One-way live feed transport? | SSE (or polling as the fallback). |
| Store auth tokens where? | Platform secure storage, never `shared_preferences`. |
| Offline write mechanism? | Outbox/queue drained by a sync worker on reconnect. |
| Pull remote changes efficiently? | Delta sync with a cursor/`since` token + tombstones. |
| Default conflict strategy? | LWW with version numbers; escalate to merge/CRDT if needed. |
| Handle breaking API changes? | Version the path (`/v1`), additive fields, tolerant reader. |
| Force an update how? | Server-driven `minVersion` gate + blocking screen. |
| Real rollback for a bad feature? | Feature flag / kill switch, not a new binary. |
| Avoid image OOM? | Sized thumbnails + `cacheWidth`/`cacheHeight`, bounded cache. |
| Reduce app size? | App bundles/split ABIs, tree-shake, lazy features, audit deps. |

## Follow-up drills

1. Design a **ride-hailing rider app**: live driver location on a map, request→match→trip lifecycle, ETA, payment — pick transports and offline behavior for each phase.
2. Design a **chat app** end-to-end: ordering, no-loss over flaky links, typing/presence, media, and multi-device read state.
3. Your feed shows **duplicate and out-of-order items** after a refresh on a slow network — diagnose the pagination/caching bug and fix the contract.
4. Users report **notes lost after editing on two devices offline** — design a conflict-resolution scheme that stops the data loss.
5. A **staged rollout** shows a crash spike at 5% scoped to Android 12 on one OEM — walk through your rollout controls and how you contain it without a new release.
6. Cut a media-heavy app's **cellular data usage by 50%** without hurting perceived quality — enumerate the levers.
