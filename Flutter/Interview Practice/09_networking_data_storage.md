# Networking, Data & Storage — Interview Questions

> How a Flutter app talks to the network, serializes data, persists it, and stays usable offline. For depth see [16 Networking](../16%20Networking/README.md), [15 Local Storage](../15%20Local%20Storage/README.md), [20 Database](../20%20Database/README.md), and [19 Offline First](../19%20Offline%20First/README.md).

This topic tests whether you can move data across an unreliable boundary and store it correctly: HTTP mechanics, choosing a client, JSON codegen, error mapping to your domain, picking the right storage tier, and designing offline-first sync. Interviewers push from "how do you call an API" toward "how do you cache, retry, paginate, and resolve conflicts".

## 🟢 Basic

**1. What is HTTP and what do the common methods/status codes mean?**
HTTP is a stateless request/response protocol over TCP (or QUIC for HTTP/3). Methods carry intent: `GET` (read, safe/idempotent), `POST` (create, non-idempotent), `PUT` (replace, idempotent), `PATCH` (partial update), `DELETE` (remove, idempotent). Status classes: `2xx` success (`200 OK`, `201 Created`, `204 No Content`), `3xx` redirect (`304 Not Modified`), `4xx` client error (`400`, `401` unauth, `403` forbidden, `404`, `409` conflict, `429` rate-limited), `5xx` server error. Knowing idempotency matters because it decides what's safe to retry.

**2. How do you make a basic GET request with the `http` package?**
```dart
import 'package:http/http.dart' as http;

final res = await http.get(Uri.parse('https://api.example.com/users/1'));
if (res.statusCode == 200) {
  final user = User.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
}
```
`http` is a thin, official wrapper. You check `statusCode` yourself, decode `res.body` (a `String`) with `jsonDecode`, and map to a model. Anything non-2xx does *not* throw — you must branch on the code.

**3. `http` vs `dio` — when do you reach for each?**
`http` is minimal and official: great for simple apps and packages that don't want a heavy dependency. `dio` is a full-featured client: interceptors, global config (`BaseOptions`), automatic JSON decoding, timeouts, `CancelToken`, retries, multipart/form-data, download progress, and better error objects (`DioException`). Reach for `dio` the moment you need cross-cutting concerns (auth token injection, logging, refresh-on-401) — building those by hand on `http` reinvents `dio`.

| | `http` | `dio` |
|---|---|---|
| Interceptors | No | Yes |
| Auto JSON decode | No | Yes |
| Cancellation | No | `CancelToken` |
| Timeouts | Manual `.timeout()` | Built-in per-request |
| Best for | Simple/lightweight, packages | Real apps with cross-cutting concerns |

**4. What is JSON serialization and why can't you just use the decoded map directly?**
`jsonDecode` gives you `Map<String, dynamic>`/`List<dynamic>` — untyped, error-prone, and stringly-keyed. Serialization means converting that into typed Dart objects (`fromJson`) and back (`toJson`). You want typed models so the compiler catches field typos and type mismatches, and so the rest of the app never touches raw maps.

**5. What does a manual `fromJson`/`toJson` look like?**
```dart
class User {
  final int id;
  final String name;
  const User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as int, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```
Fine for a handful of small models. The problems appear at scale: it's tedious, easy to get wrong, and every schema change means hand-editing two methods per model.

**6. What is `shared_preferences` and what should it store?**
A key-value store backed by the platform's native prefs (`NSUserDefaults`/`SharedPreferences`/web `localStorage`). It holds *small, non-sensitive* primitives: a theme flag, onboarding-seen boolean, last tab, feature toggles. It is **not** encrypted, not for large data, and not a database. See [15 Local Storage](../15%20Local%20Storage/README.md).

**7. When do you use `flutter_secure_storage` instead?**
For **secrets**: auth/refresh tokens, API keys, PII. It stores values in the platform Keychain (iOS) / Keystore-backed `EncryptedSharedPreferences` (Android), so data is encrypted at rest and survives outside plain prefs. Never put a JWT in `shared_preferences` — that's the classic security-review finding. See [37 Security].

**8. When would you store data as plain files instead of prefs or a DB?**
For blobs and documents: cached images, downloaded PDFs, exported CSV/Excel, large JSON snapshots. Use `path_provider` to get the right directory (`getApplicationDocumentsDirectory` for user data that persists, `getTemporaryDirectory` for disposable cache the OS can evict). Files are right when the data is large or binary and you don't need to query it.

**9. What is SQLite / `sqflite` and when do you need a database at all?**
SQLite is an embedded relational DB; `sqflite` is the Flutter plugin exposing it via raw SQL. You need a DB (not prefs/files) when you have **structured, queryable, relational data at volume** — lists you filter/sort/paginate, entities with relationships, data you mutate transactionally. If you're serializing a growing list into a prefs string, that's the signal you outgrew prefs.

**10. What's the difference between `jsonDecode` returning a `Map` vs a `List`?**
`jsonDecode` returns `dynamic`: an object `{...}` decodes to `Map<String, dynamic>`, an array `[...]` to `List<dynamic>`. For a list of models you map over it:
```dart
final data = jsonDecode(res.body) as List<dynamic>;
final users = data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
```
Getting the cast wrong (`as Map` on an array) throws at runtime — a common bug.

**11. What is a REST API in one line, and what makes it "RESTful"?**
REST models the server as **resources** addressed by URLs (`/users/1/orders`), manipulated with HTTP verbs, using stateless requests and standard status codes. "RESTful" means using verbs/codes semantically and keeping the server stateless (each request self-contained, auth carried per request), rather than tunneling everything through `POST /doStuff`.

**12. How do you set a request timeout, and why must you?**
Networks stall; without a timeout a request hangs forever and your loading spinner never resolves. With `http`: `future.timeout(Duration(seconds: 10))`. With `dio`: `BaseOptions(connectTimeout:, receiveTimeout:, sendTimeout:)`. Always set both connect and receive timeouts — a fast connection that then stalls mid-body still needs to fail.

## 🟡 Intermediate

**13. Why prefer `json_serializable`/`build_runner` over hand-written serialization?**
Code generation eliminates the tedium and the class of bugs manual mapping creates. You annotate `@JsonSerializable()`, declare fields, and `build_runner` generates `fromJson`/`toJson` in a `.g.dart` part. Benefits: fields and JSON stay in sync automatically, handles nested objects/lists/enums, supports renaming (`@JsonKey(name:)`), defaults, and custom converters — and it's compile-checked, so a schema change surfaces as a build error, not a runtime crash. The cost is a build step; worth it past a few models.

**14. Show a `json_serializable` model and explain the workflow.**
```dart
import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  @JsonKey(name: 'full_name') final String name;
  @JsonKey(defaultValue: false) final bool isActive;
  const User({required this.id, required this.name, required this.isActive});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```
Run `dart run build_runner build --delete-conflicting-outputs` to generate `user.g.dart`. Use `watch` during development to regenerate on save.

**15. What are interceptors and what do you use them for?**
Interceptors are hooks that run on every request/response/error, letting you centralize cross-cutting concerns instead of repeating them per call. Common uses: **attach the auth header**, **log** requests, **transform/normalize errors**, **refresh a token on 401 and retry**, add correlation IDs. In `dio`:
```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (o, h) { o.headers['Authorization'] = 'Bearer $token'; h.next(o); },
  onError: (e, h) async {
    if (e.response?.statusCode == 401) { /* refresh + retry */ }
    h.next(e);
  },
));
```

**16. How do you implement token refresh on a 401 without a stampede?**
In an error interceptor, on 401 you refresh the token and retry the original request. The trap is *concurrent* 401s all firing refresh at once. Fix: serialize refresh with a single in-flight `Future`/lock so parallel failures await the *same* refresh, then retry with the new token. If refresh itself fails, clear the session and route to login. Keep the refresh token in `flutter_secure_storage`.

**17. How do you cancel an in-flight request, and when do you need to?**
With `dio` you pass a `CancelToken`; calling `token.cancel()` aborts the request. You need it when a screen is disposed mid-fetch, or on **search-as-you-type** where each keystroke supersedes the last request (combine with debounce). Cancelling avoids wasted bandwidth, out-of-order responses overwriting newer state, and `setState after dispose`.
```dart
final token = CancelToken();
dio.get('/search', queryParameters: {'q': q}, cancelToken: token);
// on next keystroke / dispose:
token.cancel('superseded');
```

**18. How should you handle and map errors from the network layer?**
Never leak `DioException`/`SocketException`/status codes into UI or business logic. Catch at the data-source/repository boundary and map to a **domain error type** (a sealed class or `Failure`): `NetworkFailure` (no connectivity/timeout), `ServerFailure(code)` (5xx), `UnauthorizedFailure` (401), `NotFoundFailure` (404), `ValidationFailure` (422 with field errors), `UnknownFailure`. The UI then switches on typed failures — testable, localizable, and decoupled from the transport. See [38 Error Handling].

**19. Compare REST, GraphQL, gRPC, and WebSockets — when each?**

| Style | Shape | Best when |
|---|---|---|
| REST | Resource + verbs over HTTP, JSON | Default CRUD APIs, caching via HTTP, broad tooling |
| GraphQL | Single endpoint, client-specified query | Many clients with different data needs; avoid over/under-fetching; aggregating sources |
| gRPC | Binary Protobuf over HTTP/2, contract-first | Low-latency service-to-service, strict schemas, streaming, mobile-to-backend perf |
| WebSockets | Full-duplex persistent connection | Real-time push: chat, live prices, presence, collaborative editing |

REST is the default. GraphQL solves over/under-fetching but you own caching/complexity. gRPC wins on payload size and speed but needs HTTP/2 and codegen. WebSockets are for server-initiated streams, not request/response CRUD.

**20. `sqflite` vs Drift vs Isar vs Hive — what's the trade-off?**

| DB | Model | Type-safety | Relations/queries | Reactive | Best for |
|---|---|---|---|---|---|
| Hive | NoSQL key-value/box | Low (dynamic or adapters) | No joins | Watch boxes | Fast simple local cache, no SQL |
| Isar | NoSQL object DB | High (codegen) | Links, rich queries, indexes | Watchers | High-perf typed store, full-text search |
| sqflite | Raw SQL | Low (manual maps) | Full SQL, manual | No (poll) | You want plain SQL / know SQLite |
| Drift | SQL + typed Dart DSL on SQLite | High (codegen) | Full SQL, typed, joins | Streamed queries | Relational data with compile-safe queries + reactivity |

Rule of thumb: simple key-value cache → Hive; typed object store with speed → Isar; relational/complex queries with SQL comfort and type safety → Drift; thin SQL wrapper → sqflite. See [20 Database](../20%20Database/README.md).

**21. Why not just store everything in `shared_preferences`?**
It's synchronous-feeling but actually async, unindexed, and loads the whole store into memory. There's no querying, no transactions, no relations, and no encryption. Serializing large/growing lists into a JSON string in prefs is an anti-pattern: reads/writes get slower, you lose partial updates, and you race concurrent writes. Past small primitives, move to a DB.

**22. What does "single source of truth" mean and why does it matter for storage?**
Every piece of state has exactly one authoritative owner; everyone else derives from it. For offline-first, the **local database is the source of truth** — the UI reads from the DB (via a stream), and the network only *updates* the DB. This prevents the classic bug of UI reading sometimes-from-cache-sometimes-from-network with divergent shapes, and makes offline behavior automatic: no network just means the DB isn't refreshed. See [19 Offline First](../19%20Offline%20First/README.md).

**23. What is the repository pattern's role in the data layer?**
The repository is the seam between domain and data sources. It exposes domain-typed methods (`Future<List<Order>> getOrders()`), hides *where* data comes from (remote API, local DB, cache), decides the fetch strategy (cache-aside, network-then-cache), and maps DTOs↔domain entities plus errors↔failures. It lets you swap `dio` for something else, test the domain with a fake repo, and centralize caching/offline logic in one place.

**24. What is cache-aside, and how do you implement it?**
Cache-aside (lazy loading): on read, check the cache first; on miss, fetch from source, populate the cache, return. On write, update the source and invalidate/update the cache. In a repository: read local DB → if present and fresh, return it → else fetch remote, write to DB, return. It's the default because it's simple and only caches what's actually requested.

## 🔴 Advanced

**25. Design an offline-first read flow that stays live.**
Make the DB the single source of truth and have the UI subscribe to it, not the network:
1. UI watches a **stream** from the local DB (Drift/Isar watcher) → renders whatever's stored.
2. Repository triggers a background fetch; on success it **writes into the DB**, which pushes a new value down the stream automatically.
3. On network failure, the stream just keeps emitting the last stored data — the app works offline with no special casing.
This decouples "showing data" from "refreshing data" and gives instant loads + eventual freshness. See [19 Offline First](../19%20Offline%20First/README.md).

**26. What is optimistic UI and what must you handle?**
Optimistic UI applies the user's change *locally and immediately* (before the server confirms), then reconciles. E.g. tapping "like" increments instantly, and you queue the network call. You must handle **rollback**: if the request fails, revert the local change and surface an error; and **reconciliation**: replace the optimistic value with the server's authoritative one on success. It makes the app feel instant but requires you to track the pre-change state to undo.

**27. How do you design a sync engine for offline writes?**
Queue mutations locally and replay them when online:
- Persist each local write as a pending operation (op type, payload, timestamp, entity id) in an **outbox** table, and apply it to the local DB optimistically.
- A sync worker (triggered by connectivity regain / periodic / on app resume) drains the outbox in order, calling the API.
- On success, mark the op done and store the server's canonical result; on failure, retry with backoff, and after N failures flag for conflict/manual resolution.
- Use **idempotency keys** (client-generated ids) so retries don't double-create. `connectivity_plus` detects reachability; but treat "connected" as a hint — the request can still fail.

**28. How do you resolve sync conflicts?**
A conflict is when local and server versions of the same record both changed. Strategies: **last-write-wins** (compare timestamps/version numbers — simple, can lose data); **server-wins/client-wins** (policy-based); **field-level merge** (merge non-overlapping field changes); **CRDTs** (conflict-free types that merge deterministically, for collaborative apps); or **surface to the user** to pick. Version each record (monotonic version or `updatedAt`) so you can *detect* the conflict at all — optimistic concurrency: send the version you based your edit on, server rejects with 409 if it moved.

**29. How does TTL-based caching work and where do you store the metadata?**
Attach an expiry to cached data: store `fetchedAt` alongside each record (or per collection). On read, if `now - fetchedAt > ttl`, treat as stale → refetch (either block, or serve-stale-then-revalidate). TTL suits data with a tolerable staleness window (product lists, feeds). Store the timestamp in the same DB row or a metadata table so eviction/freshness is queryable. Combine with cache-aside: cache-aside decides *where* to look, TTL decides *when it's too old*.

**30. Explain ETag / `If-None-Match` conditional requests and their payoff.**
The server returns an `ETag` (a content hash/version) with a response. On the next request you send `If-None-Match: <etag>`; if the resource is unchanged the server replies `304 Not Modified` with **no body**, and you reuse the cached copy. Payoff: you still make the round-trip (so you know it's fresh) but save bandwidth and parsing on unchanged data. `Last-Modified`/`If-Modified-Since` is the timestamp-based equivalent. Great for large, occasionally-changing resources.

**31. How do you implement pagination correctly, and offset vs cursor?**
Fetch pages on demand as the user scrolls (detect near-end via `ScrollController` or a sentinel item). Two schemes:
- **Offset/limit** (`?page=2&limit=20`): simple, allows jumping to a page, but **breaks under inserts/deletes** — items shift, causing duplicates or skips — and gets slow at large offsets.
- **Cursor/keyset** (`?after=<lastId/token>`): pass the last item's stable key; the server returns the next slice. Stable under concurrent writes and efficient — the standard for infinite feeds.
Handle the states explicitly: loading-first-page, loading-more, end-reached, error-on-page (retry just that page). Dedupe by id when merging pages.

**32. How do you keep pagination working offline / with a cache?**
Persist fetched pages into the DB keyed by their position/cursor and serve from the DB while background-refreshing. The UI pages over the local store; the network fills gaps. Tools like `infinite_query`/custom repositories cache page windows and reconcile with pull-to-refresh (which typically invalidates and refetches from the first page/cursor). The single-source-of-truth rule still holds: paginate the DB, sync the DB.

**33. How do you handle large responses and JSON parsing without jank?**
`jsonDecode` on a big payload blocks the UI isolate and drops frames. Options: parse on a background isolate via `compute(parseUsers, body)` (or `Isolate.run` in modern Dart) so decode + model mapping happen off the main thread; stream/paginate so payloads stay small; use binary formats (Protobuf) to cut parse cost; and store parsed results in the DB so you parse once, not every read. Measure first — small payloads don't need an isolate.

**34. How do you make the networking/data layer testable?**
Depend on abstractions and inject them: the repository takes a `RemoteDataSource` and `LocalDataSource` interface. Test with a mocked `dio` (via `MockAdapter`/`http_mock_adapter` or `mockito`) or fakes returning canned JSON/failures. Assert that: 4xx/5xx map to the right `Failure`, cache-aside reads local before remote, offline path serves stored data, and the outbox replays in order. Keeping HTTP details behind the data source means domain tests never touch the wire. See [49 Testing].

**35. What are the security concerns in the networking/storage layer?**
Use HTTPS/TLS always; consider **certificate pinning** for high-value apps (pin in `dio`'s `HttpClientAdapter`, accept rotation). Store tokens in `flutter_secure_storage`, never in prefs or logs. Scrub sensitive fields from logging interceptors. Don't cache sensitive responses to plain files/DB unencrypted (Isar/Drift/SQLCipher support encryption). Validate and treat all server data as untrusted when deserializing. See [37 Security].

**36. Walk through a complete "load a list" flow in a clean, offline-first architecture.**
1. **UI** watches a `Stream<List<Order>>` from the repository → shows cached data instantly.
2. **Repository** returns the DB stream, and kicks off a refresh: calls `RemoteDataSource.fetchOrders()`.
3. **RemoteDataSource** (dio) hits the API; interceptor adds auth; response DTOs are parsed (on an isolate if big).
4. On success, repository writes DTOs→entities into the **local DB** (single source of truth) → the stream re-emits → UI updates.
5. On failure, map to `Failure`; the stream keeps serving stored data, and the UI shows a non-blocking error/retry.
6. TTL/ETag decide whether the refresh was even necessary; pagination appends further pages into the same DB. This is the synthesis interviewers want — networking, serialization, storage, caching, and offline in one coherent path.

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Which HTTP methods are idempotent? | GET, PUT, DELETE (and safe: GET). |
| Does `http.get` throw on 404? | No — check `statusCode` yourself. |
| Main reason to pick `dio`? | Interceptors + built-in timeouts/cancel. |
| Cancel a request in dio? | `CancelToken` → `token.cancel()`. |
| Why codegen for JSON? | Kills boilerplate, stays in sync, compile-checked. |
| Command to generate models? | `dart run build_runner build`. |
| Where do auth tokens go? | `flutter_secure_storage`, never prefs. |
| What's `shared_preferences` for? | Small non-sensitive key-value primitives. |
| Store large binaries? | Files via `path_provider`. |
| Offset vs cursor pagination? | Offset shifts under writes; cursor is stable. |
| Single source of truth in offline-first? | The local database. |
| Cache-aside in one line? | Read cache → miss → fetch → populate → return. |
| What triggers a 304? | Matching `If-None-Match`/`If-Modified-Since`. |
| TTL caching stores what? | `fetchedAt` timestamp per record. |
| Optimistic UI must support? | Rollback on failure. |
| Prevent double-create on retry? | Idempotency key. |
| Real-time push protocol? | WebSockets. |
| Binary contract-first RPC? | gRPC (Protobuf/HTTP2). |
| Relational + typed + reactive DB? | Drift. |
| Fast NoSQL key-value cache? | Hive. |
| Parse huge JSON without jank? | Decode on an isolate (`compute`/`Isolate.run`). |
| Map transport errors to? | Domain `Failure` types at the repo boundary. |

## Follow-up drills

1. **Design** the full data layer for a news-feed app: infinite scroll, offline reading, pull-to-refresh, and article-read state that syncs — specify tables, cache strategy, and sync engine.
2. **Implement** dio token refresh that handles 20 concurrent 401s without firing 20 refresh calls — describe the locking.
3. **Debug** a search bar where fast typing shows results for an earlier query — identify the fix (cancellation + debounce + latest-wins).
4. **Optimize** a screen that janks for 400ms every time it loads a 2 MB JSON list — cut the frame drops without changing the API.
5. **Resolve** a sync conflict where a note was edited offline on two devices — compare last-write-wins, field merge, and CRDT approaches for this case.
6. **Choose** between Hive, Isar, Drift, and sqflite for (a) a 50-field relational reporting app and (b) a simple settings + favorites cache — justify both.
