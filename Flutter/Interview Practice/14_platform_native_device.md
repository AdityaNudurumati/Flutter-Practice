# Platform Integration, Native & Device — Interview Questions

> How Flutter talks to the OS: platform channels, Pigeon, FFI, native plugins, device features, notifications, and background work. For depth see [26 Platform Channels](../26%20Platform%20Channels/README.md), [27 Native Android](../27%20Native%20Android/README.md), [28 Native iOS](../28%20Native%20iOS/README.md), [29 Device Features](../29%20Device%20Features/README.md), [32 Notifications](../32%20Notifications/README.md), and [33 Background Services](../33%20Background%20Services/README.md).

This topic tests whether you understand that Flutter renders its own UI but has *no* built-in access to the OS — everything native (camera, sensors, notifications, Bluetooth) crosses a language boundary. Interviewers probe how that bridge works, how it's serialized and threaded, and when to reach for channels vs Pigeon vs FFI.

## 🟢 Basic

**1. Flutter draws its own pixels — so how does it access native OS features at all?**
Through a message-passing bridge called **platform channels**. Dart code and the host (Android/iOS) exchange asynchronous messages over a named channel; the native side runs real Kotlin/Swift (or Java/Obj-C) code that calls the platform SDK and sends a result back. Flutter itself only knows how to rasterize a UI via Skia/Impeller — anything OS-specific (GPS, camera, notifications) goes over this bridge, which is exactly why those features arrive as *plugins* rather than being in the core framework. See [26 Platform Channels](../26%20Platform%20Channels/README.md).

**2. What is a `MethodChannel` and what's the typical flow?**
A `MethodChannel` is a named channel for **request/response** calls: Dart invokes a named method with arguments, the platform handles it and returns a single result (or an error). The name must match exactly on both sides.

```dart
const channel = MethodChannel('app.dev/battery');
final level = await channel.invokeMethod<int>('getBatteryLevel');
```
On the native side you register a handler for that channel and `switch` on `call.method`, then call `result.success(...)`, `result.error(...)`, or `result.notImplemented()`. The Dart call returns a `Future` because the round trip is asynchronous.

**3. What are the three channel types and when do you use each?**

| Channel | Direction / shape | Use for |
|---|---|---|
| `MethodChannel` | Dart ↔ native, one call → one result | Invoking a native function ("get battery level", "scan") |
| `EventChannel` | native → Dart, a **stream** of events | Continuous data: sensor readings, location updates, connectivity changes |
| `BasicMessageChannel` | bidirectional, **arbitrary messages** with a codec | Free-form/continuous two-way messaging, or custom serialization |

`MethodChannel` is really a thin convention on top of `BasicMessageChannel`. `EventChannel` wraps the stream lifecycle (listen/cancel) so native pushes events via an `EventSink`.

**4. How are channel messages serialized?**
By a **message codec**. The default is `StandardMessageCodec` (used by `StandardMethodCodec`), which binary-encodes a fixed set of types: null, bool, int, double, String, `Uint8List`/typed data lists, `List`, and `Map`. You don't send Dart objects — you send these primitives, and the codec maps them to the native equivalents (e.g. Dart `Map` ↔ Kotlin `HashMap` / Swift `Dictionary`). There's also `JSONMessageCodec`, `StringCodec`, and `BinaryCodec`. Anything richer (your own classes) you serialize to maps yourself — or use Pigeon.

**5. Which thread do platform-channel handlers run on?**
By default, the platform side runs its handler on the **host platform's main (UI) thread** (Android main thread / iOS main thread), and the Dart side runs on the **root isolate's UI thread**. So heavy native work in a channel handler will jank the native UI — you must offload it to a background thread/executor natively and post the result back. The messages themselves are marshaled across the boundary asynchronously; your `await` on the Dart side never blocks the Dart UI thread.

**6. Are platform channel calls synchronous or asynchronous, and why does that matter?**
Asynchronous — every `invokeMethod` returns a `Future`. This is deliberate: the message is serialized, sent over the bridge, handled, and the reply serialized back, all without blocking either UI thread. It matters because you cannot treat a channel call like a local function that returns instantly; you `await` it and handle latency/errors. Rapid or chatty calls add up in serialization overhead, which is one reason FFI exists for hot paths.

**7. What is a Flutter *plugin* and how does it differ from a package?**
A **package** is pure Dart, reusable code (e.g. a formatting util). A **plugin** is a package that *also* contains platform-specific native code and wires it up over channels/FFI (e.g. `camera`, `geolocator`, `shared_preferences`). Plugins declare their native entry points in `pubspec.yaml` under `flutter.plugin.platforms`. You reach for a plugin whenever you need OS functionality Flutter doesn't provide itself.

**8. How do you request runtime permissions, and why can't you just declare them?**
Declaring a permission only tells the OS you *might* use it — Android needs it in `AndroidManifest.xml`, iOS needs a usage-description key in `Info.plist`. But dangerous permissions (camera, location, mic, contacts) must *also* be granted by the user at runtime. The `permission_handler` package unifies this: you check `.status`, call `.request()`, and handle `granted`/`denied`/`permanentlyDenied` (the last forces you to send the user to app settings). Missing the `Info.plist` string on iOS is an instant App Store rejection / crash. See [29 Device Features](../29%20Device%20Features/README.md).

**9. What's the difference between a local notification and a push (FCM) notification?**
A **local notification** is scheduled and fired by the app on-device (via `flutter_local_notifications`) — a reminder, a timer, a download-complete alert; no server, no network. A **push notification** originates from a server via **FCM** (Firebase Cloud Messaging) / APNs and is delivered by the OS even when your app is closed. Push needs backend + tokens + platform setup; local needs neither. Many apps use both: FCM delivers the data, and you render it with local notifications for richer control. See [32 Notifications](../32%20Notifications/README.md).

**10. What is an Android notification channel and why is it mandatory?**
Since Android 8 (API 26), every notification must belong to a **notification channel** — a category (e.g. "Messages", "Promotions") the user can independently configure (sound, importance, whether it's blocked). If you post a notification without creating its channel first, it silently won't show. You create channels once at startup with an id, name, and importance level. iOS has no channels but has the equivalent of authorization + categories.

**11. Why do you need to request notification permission explicitly now?**
iOS always required the user to *authorize* notifications. Android added the same with **Android 13 (API 33)**: the `POST_NOTIFICATIONS` runtime permission. So on both platforms you must request permission before notifications appear — you can't assume they'll show just because you posted them. Web push also requires an explicit browser permission prompt.

**12. Can you run Dart code in the background when the app is killed, and what's the catch?**
Partly — and the platforms differ sharply. Android allows real background execution via **`WorkManager`** (through `workmanager`) and background isolates; iOS is *far* more restrictive — it only grants short, OS-scheduled windows (BGTaskScheduler / background fetch) and will not let you run arbitrary long-lived work. The universal catch: background work runs in a **separate isolate** with no access to your app's in-memory state, so you must re-init plugins and pass data via serializable arguments or storage. See [33 Background Services](../33%20Background%20Services/README.md).

## 🟡 Intermediate

**13. Walk through the full round trip of a `MethodChannel` call, boundary by boundary.**
(1) Dart calls `invokeMethod('m', args)`; the `StandardMethodCodec` serializes the method name + args into a binary `ByteData`. (2) The message is handed to the engine and delivered to the platform side on its main thread via the `BinaryMessenger`. (3) Native decodes it, runs your handler, and produces a result (or error/notImplemented). (4) The result is re-encoded and sent back across the bridge. (5) The Dart `Future` completes with the decoded value, or throws a `PlatformException` if native returned an error. Every step is async and every payload must be codec-supported.

**14. What's the difference between the root isolate and other isolates when it comes to channels?**
Platform channels are bound to the **root isolate** (the one Flutter starts). Historically, only the root isolate could use channels, so a spawned isolate couldn't call native code directly. Modern Flutter adds `BackgroundIsolateBinaryMessenger` (root isolate token) so a background isolate can register its own messenger and talk to plugins — you pass the `RootIsolateToken` into the isolate and call `ensureInitialized`. This is exactly what background-notification and WorkManager handlers must do.

**15. What is Pigeon and what problem does it solve?**
Hand-written channels are **stringly-typed and fragile**: a typo in the method name or a mismatched argument type fails only at runtime, and you serialize objects into maps by hand on both sides. **Pigeon** is a code generator: you define your API in a Dart file (abstract classes with typed methods and data classes), run Pigeon, and it emits type-safe Dart + Kotlin/Swift/Obj-C glue. You then just implement the generated interface. Benefits: compile-time type safety, no string channel names to misspell, auto (de)serialization of your data classes, and refactor-safety. See [26 Platform Channels](../26%20Platform%20Channels/README.md).

**16. When would you use `dart:ffi` instead of platform channels?**
FFI (Foreign Function Interface) calls **C ABI functions directly** — no message serialization, no bridge hop, near-native speed, and *synchronous* by default. Use it when: you're integrating an existing C/C++ library (SQLite, image codecs, crypto, ML kernels), or you have a hot path where per-call channel serialization overhead is unacceptable. Use channels instead when you need platform *SDK* features (which are Kotlin/Swift APIs, not C) or push-style event streams. Rule of thumb: **channels for platform APIs, FFI for native libraries and performance-critical numeric code.**

**17. Compare channels vs FFI directly.**

| Aspect | Platform channels | `dart:ffi` |
|---|---|---|
| Talks to | Kotlin/Swift/Java/Obj-C | C ABI (C/C++/Rust via C) |
| Sync/async | Asynchronous | Synchronous (can be made async) |
| Serialization | Codec marshals every message | None — direct memory/pointers |
| Overhead | Per-call encode/decode + bridge | Very low |
| Best for | Platform SDK APIs, event streams | Native libs, hot numeric paths |
| Thread safety | Runs on platform main thread | Runs on the calling isolate's thread |

FFI's cost is manual memory management (`malloc`/`free`, `Pointer`, `Struct`) and losing access to platform SDKs.

**18. How does an `EventChannel` actually stream data from native to Dart?**
Dart calls `.receiveBroadcastStream().listen(...)`. Under the hood this sends an `onListen` message to native, which hands you an `EventSink`/`EventChannel.StreamHandler`. Native pushes values by calling `sink.success(event)` (or `sink.error`), each of which is codec-encoded and delivered as a stream event to Dart. When Dart cancels the subscription, an `onCancel` message tells native to stop producing (e.g. unregister the sensor listener). Forgetting to release the native resource in `onCancel` is a classic leak — sensors keep firing and draining battery.

**19. What is a platform view and what's the cost of using one?**
A **platform view** embeds a *native* view (a Google Map, a WebView, a camera preview, an ad view) inside the Flutter widget tree via `AndroidView` / `UiKitView` (or `PlatformViewLink`). It exists because some things are genuinely native views you can't reproduce as Flutter widgets. The cost: composing a native view into Flutter's rendering is expensive — Android uses hybrid composition / texture layers, which adds overhead and can cause synchronization/jank, and it breaks the "everything is a Flutter widget" performance model. Use them only when necessary and keep them small/few.

**20. On the native Android side, what do you touch to add a feature and wire a channel?**
You edit `AndroidManifest.xml` (permissions, `<service>`/`<receiver>`, metadata), and write Kotlin in the plugin/app that registers a channel in the `FlutterPlugin`'s `onAttachedToEngine` via `flutterPluginBinding.binaryMessenger`, setting a `MethodCallHandler`. Runtime permissions, foreground services, and background components are all declared here. Gradle config (min SDK, dependencies) lives in `build.gradle`. See [27 Native Android](../27%20Native%20Android/README.md).

**21. And on the native iOS side?**
You edit `Info.plist` (usage-description strings like `NSCameraUsageDescription`, background modes, URL schemes) and write Swift/Obj-C that registers a `FlutterMethodChannel` with the `registrar.messenger()` in the plugin's `register(with:)`. Capabilities (push, background fetch) are toggled in Xcode and reflected in the entitlements file. APNs setup lives here for push. See [28 Native iOS](../28%20Native%20iOS/README.md).

**22. What are federated plugins and why do they exist?**
A **federated plugin** splits a plugin into separate packages: an **app-facing** package (the API you import), a **platform-interface** package (an abstract contract), and one **platform implementation** per platform (android, ios, web, windows...). This lets *different authors* add platform support without touching the core, lets an app override one platform's implementation, and keeps each platform's native code isolated. It's how big plugins like `url_launcher` and `camera` scale across 6 platforms — you can add desktop support by publishing just an endorsed implementation package.

**23. How do you handle a deep link that arrives via a notification tap?**
The notification carries a payload (a route/URL). Two entry cases matter: the app is (a) foreground/background but alive, or (b) terminated. For a live app, the tap callback (`onDidReceiveNotificationResponse` / FCM `onMessageOpenedApp`) fires and you navigate. For a *terminated* app launched by the tap, you must read the launch payload at startup (`getNotificationAppLaunchDetails()` / FCM `getInitialMessage()`) and route accordingly *after* the navigator is ready. Missing the terminated-state path is the most common deep-link bug. See [32 Notifications](../32%20Notifications/README.md).

**24. How do FCM messages behave in foreground vs background vs terminated states?**
It depends on message type. A **notification message** is auto-displayed by the OS when the app is backgrounded/terminated; in the foreground it is *not* shown automatically — `onMessage` fires and you render it yourself (usually via a local notification). A **data-only message** always invokes your handler and never auto-displays. Background/terminated data messages run in `onBackgroundMessage`, a top-level function in a **background isolate** — so it must be a top-level/static function and re-initialize anything it needs.

**25. Why must the FCM background handler be a top-level or static function?**
Because it runs in a **separate background isolate** with a fresh memory space — it has none of your app's singletons, providers, or `main()` setup. Flutter needs a function it can look up and invoke standalone (annotated `@pragma('vm:entry-point')` so tree-shaking doesn't strip it). Inside it you must call `Firebase.initializeApp()` again and re-create any dependencies. Trying to reference app-level state from it simply won't work.

**26. How do you get continuous location or sensor updates, and what's the resource concern?**
Via a stream — `geolocator`'s position stream or `sensors_plus`' accelerometer/gyroscope streams (both backed by `EventChannel`s). The concern is **battery and lifecycle**: high-accuracy GPS and high-frequency sensors drain battery fast, and you must cancel the subscription when the screen/app is no longer using it (in `dispose`) so the native listener unregisters. Request the *minimum* accuracy/frequency you need, and for background location you need extra permissions (`ACCESS_BACKGROUND_LOCATION` / iOS "Always") that trigger stricter store review.

## 🔴 Advanced

**27. Your channel handler does heavy work (image processing) and the native UI freezes. Diagnose and fix.**
Channel handlers run on the platform **main thread**, so blocking work there janks native UI (and can ANR on Android). Fix natively: dispatch the work to a background executor/`DispatchQueue.global()`, then post the result back **on the main thread** before calling `result.success(...)` (the reply must return on the platform thread the handler was invoked on). Alternatively, if it's pure computation with no platform SDK, move it to a Dart `Isolate`/`compute`, or drop to FFI so it runs off the message pipeline entirely. The anti-pattern is doing CPU-bound work synchronously inside the handler.

**28. You're sending large binary data (a captured frame) over a channel every frame and it's slow. What are your options?**
Per-frame channel serialization of large buffers is a known bottleneck — the `StandardMessageCodec` copies and encodes each payload. Options, best first: (1) use **`Texture`/external texture** so native writes pixels to a GPU texture Flutter composites directly, avoiding copying frames over the channel at all (this is how `camera`/video render previews); (2) use **FFI with shared memory / a `Pointer`** so Dart reads the buffer without a copy; (3) if you must use a channel, send `Uint8List` (which `BinaryCodec` passes efficiently) rather than lists of ints, and reduce resolution/frequency. Sending raw pixel `List<int>` per frame is the worst case.

**29. Explain the threading model precisely: UI thread, platform thread, raster thread, and where channel messages flow.**
Flutter's engine uses several task runners: the **UI (Dart) thread** runs your Dart + builds the layer tree; the **raster thread** turns layers into GPU commands; the **platform thread** is the host's main thread (Android/iOS UI thread) where plugins and channel handlers execute. A channel message originates on the Dart UI thread, crosses to the platform thread for handling, and the reply comes back to the Dart UI thread. This is why: channel calls can't block either UI thread (they're async), heavy native handler work janks the *platform* thread, and platform-view composition (on the platform/raster boundary) is expensive to synchronize.

**30. When would you choose Pigeon over hand-written channels *and* over FFI — give the decision boundary.**
Pigeon vs hand-written channels: almost always prefer **Pigeon** for any non-trivial channel API — you get type safety and eliminate string/type-mismatch bugs for free, at the cost of a codegen step. Hand-written channels are fine only for a one-off single method. Pigeon vs FFI: Pigeon still generates *channel* code, so it targets **platform SDK APIs** (Kotlin/Swift). Choose **FFI** when the target is a **C library** or a performance-critical synchronous path where you can't afford serialization. So: C library / hot path → FFI; structured platform-API bridge → Pigeon; trivial single call → raw channel.

**31. How does FFI manage memory, and what are the leak/safety pitfalls?**
FFI works with raw `Pointer`s into native memory. You allocate with `malloc.allocate` / `calloc`, must `free` it yourself, and marshal strings via `toNativeUtf8()` / `.toDartString()`. Pitfalls: **leaking** allocations you forgot to free; **use-after-free** if native frees memory Dart still holds a pointer to; passing a Dart-managed buffer that the GC may move; and blocking the isolate on a long native call (FFI is synchronous — use `Isolate`/async FFI for long calls). You also lose Dart's safety net: a bad pointer crashes the process, not a catchable exception. Wrap allocations in try/finally and prefer `ffigen` to generate correct bindings.

**32. Design a robust FCM + local-notification pipeline that handles all app states and deep links.**
Layers: (1) request `POST_NOTIFICATIONS` (Android 13+) and iOS authorization on first launch; (2) obtain and refresh the FCM token, send it to your backend, and listen to `onTokenRefresh`; (3) create Android notification channels at startup; (4) foreground: `onMessage` → render via `flutter_local_notifications` with a payload; (5) background/terminated: a top-level `onBackgroundMessage` handler (re-init Firebase) for data messages; (6) taps: handle `onMessageOpenedApp` for warm starts and `getInitialMessage()` + `getNotificationAppLaunchDetails()` for cold starts, routing only after the navigator exists; (7) make routing idempotent so a re-delivered message doesn't double-navigate. See [32 Notifications](../32%20Notifications/README.md).

**33. Why is iOS background execution so limited, and how do you architect around it?**
iOS aggressively suspends apps to preserve battery; it does **not** allow arbitrary long-running background work. You get: silent push (`content-available`) to wake briefly, `BGAppRefreshTask`/`BGProcessingTask` scheduled *by the OS* (no guaranteed timing), and specific background modes (audio, location, VoIP). Architect around it by making the server authoritative: push data down, do minimal work in the short window, and **defer heavy processing to next foreground**. Don't design a feature that assumes periodic background execution on iOS — Android's `WorkManager` can honor it but iOS can't, so the cross-platform design must tolerate "runs only when the OS allows." See [33 Background Services](../33%20Background%20Services/README.md).

**34. How does `WorkManager`-style background work interact with isolates and plugins?**
A scheduled task runs in a **background isolate** spawned by the engine, entered through a top-level `@pragma('vm:entry-point')` callback (`callbackDispatcher`). That isolate has no `BuildContext`, no app state, and — until you initialize it — no channel access. You must `WidgetsFlutterBinding.ensureInitialized()`, register the `RootIsolateToken` / `BackgroundIsolateBinaryMessenger`, and re-create any plugins you call. Constraints (network, charging, unmetered, periodic ≥15 min on Android) are enforced by the OS scheduler, not you. Work must be idempotent because the OS may retry it.

**35. A plugin works on Android but throws `MissingPluginException` on a background isolate / add-to-app / a new platform. What's happening?**
`MissingPluginException` means the Dart side sent a channel message but **no handler is registered** on the receiving end. Common causes: (1) a **background isolate** that never registered its binary messenger (needs the root isolate token dance); (2) **add-to-app** where the engine wasn't set up so plugins never registered; (3) calling before `WidgetsFlutterBinding.ensureInitialized()`; (4) the plugin **doesn't implement that platform** (federated impl missing) so it's genuinely not there; (5) a hot-restart that lost native registration. Diagnose by checking whether native registration ran and whether the platform is actually supported.

**36. How do you make a channel bridge testable and resilient to native errors?**
On the Dart side, wrap channel calls to translate `PlatformException`/`MissingPluginException` into your domain errors, and hide the channel behind a repository interface so business logic doesn't know about `MethodChannel`. Test it with `TestDefaultBinaryMessengerBinding` / `setMockMethodCallHandler` (or Pigeon's generated mocks) to fake native responses — no device needed. Always handle `notImplemented`, timeouts, and malformed payloads defensively, and prefer **Pigeon** so the contract is typed and both sides can't silently drift. This mirrors the "hide platform behind a repo" DI principle — see [14 Dependency Injection](../14%20Dependency%20Injection/README.md).

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Bridge Dart ↔ native? | Platform channels. |
| One call, one result channel? | `MethodChannel`. |
| Stream native → Dart? | `EventChannel`. |
| Free-form two-way + custom codec? | `BasicMessageChannel`. |
| Default channel codec? | `StandardMessageCodec` (binary). |
| Which thread runs channel handlers? | The platform main/UI thread. |
| Type-safe channel codegen tool? | Pigeon. |
| Direct C-library calls from Dart? | `dart:ffi`. |
| Channels vs FFI rule? | Platform APIs → channels; native libs / hot path → FFI. |
| Package vs plugin? | Plugin adds native platform code. |
| Split-by-platform plugin design? | Federated plugin. |
| Embed a native view? | Platform view (`AndroidView`/`UiKitView`). |
| iOS permission strings live where? | `Info.plist` (usage-description keys). |
| Android permission ≥API 26 grouping? | Notification channels. |
| Android 13 notification permission? | `POST_NOTIFICATIONS`. |
| Local vs push notification? | On-device app-fired vs server via FCM/APNs. |
| FCM data-message background entry? | Top-level `onBackgroundMessage` isolate. |
| Cold-start notification route source? | `getInitialMessage()` / launch details. |
| Android periodic background work? | `WorkManager` (min ~15 min). |
| Why background isolate can't see app state? | Separate isolate, fresh memory. |
| Efficiently render native camera frames? | External `Texture`, not per-frame channel copies. |
| `MissingPluginException` means? | No handler registered on the receiving side. |

## Follow-up drills

1. **Design** a cross-platform Bluetooth-scanner plugin: pick `MethodChannel` vs `EventChannel` per operation, define the Pigeon API, and lay out the federated package split.
2. **Optimize** a live camera-preview + real-time filter feature that drops frames — decide between platform view + texture, FFI image processing, and channel payloads, and justify.
3. **Debug** a notification that opens the correct screen when the app is warm but lands on the home screen when launched from a killed state.
4. **Architect** a "sync my data every hour" feature that behaves correctly on both Android `WorkManager` and iOS's restricted background model.
5. **Integrate** an existing C++ image-codec library via `dart:ffi` — specify the memory-management strategy, error handling, and how you'd keep long calls off the UI isolate.
6. **Justify** choosing Pigeon over hand-written channels to a team lead worried about the extra codegen step — quantify the failure modes it removes.
