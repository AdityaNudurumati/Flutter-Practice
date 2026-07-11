# Kotlin Plugin Code (Channels, Activity, Context, Lifecycle)

> On Android, native channel handlers are Kotlin: register them in `configureFlutterEngine`, use the right **`Context`** (application vs activity), get the **`Activity`** for UI/permission work via `ActivityAware` (in plugins), and offload heavy work off the main thread — returning results on it.

## Introduction

This file covers writing the Android/Kotlin side of platform channels/plugins: where to register handlers, `Context` vs `Activity` (and why it matters), the plugin lifecycle (`FlutterPlugin`/`ActivityAware`), threading, and returning results/errors — the practical Kotlin patterns behind Module 26's channels.

## Why this concept exists

Channels need a native implementation. On Android, that's Kotlin with Android-specific concerns: which `Context` to use (leaks/capabilities), getting the `Activity` (needed for permissions, `startActivityForResult`, UI), and lifecycle (activity attach/detach). Getting these wrong causes crashes, leaks, or missing capabilities.

## Real-world analogy

Writing Kotlin channel code is being the **local branch office** that fulfills requests from HQ (Dart). You need the right **credentials/keys** (`Context`/`Activity`) to access different resources, must **hand back through the correct window** (reply on main thread), and **check out when the branch closes** (lifecycle cleanup).

## Problem Statement

Implement a Kotlin `MethodChannel` that reads a system service (application `Context`) and one that launches an activity/requests a permission (needs the `Activity`), with correct lifecycle and threading. You'll register handlers and use the right context/activity.

## Internal Working

```mermaid
flowchart TD
    Register[configureFlutterEngine / onAttachedToEngine] --> Handler[setMethodCallHandler]
    Handler --> Ctx{needs Activity?}
    Ctx -->|no (system service)| AppCtx[applicationContext]
    Ctx -->|yes (UI/permissions/startActivity)| Act[Activity via ActivityAware]
    Handler --> Work[offload heavy work] --> Reply[result on MAIN thread]
    Lifecycle[FlutterPlugin/ActivityAware] --> Cleanup[detach: clear channel/activity refs]
```

- **Registering handlers**:
  - **App-embedded**: override `configureFlutterEngine(flutterEngine)` in `MainActivity` and set up `MethodChannel(binaryMessenger, name).setMethodCallHandler { ... }`.
  - **Plugin**: implement **`FlutterPlugin`** (`onAttachedToEngine`/`onDetachedFromEngine`) to create/dispose the channel with the plugin's binary messenger.
- **`Context` vs `Activity`**:
  - Use **`applicationContext`** for system services (BatteryManager, connectivity), app resources — long-lived, **no leak** of an activity.
  - Use the **`Activity`** for UI (dialogs, `startActivity`/`startActivityForResult`), runtime **permissions**, window operations — required for those APIs.
  - Get the Activity in a **plugin** via **`ActivityAware`** (`onAttachedToActivity`/`onDetachedFromActivity...`); **don't hold** a stale Activity reference (leak) — clear on detach.
- **Threading**: handlers run on the **platform main thread**; do heavy work on a background thread/coroutine and call **`result.success/error` on the main thread** (post back) to avoid ANRs ([26 · platform_channel_fundamentals](../26%20Platform%20Channels/platform_channel_fundamentals.md)).
- **Results/errors**: `result.success(value)`, `result.error(code, message, details)`, `result.notImplemented()`; supported types only (codec).
- **Lifecycle/cleanup**: null out channel/activity references and unregister receivers on detach to avoid leaks.

## Memory Representation

Holding an `Activity`/`Context` reference beyond its lifecycle **leaks** it; use `applicationContext` where possible and clear activity refs on detach ([08 · dispose_and_leaks](../08%20Widget%20Lifecycle/dispose_and_leaks.md) analog for native).

## Compiler Behavior

Kotlin compiled by Gradle/AGP; channel names/types are stringly-typed (Pigeon adds Kotlin type-safety — [26 · plugins_and_pigeon](../26%20Platform%20Channels/plugins_and_pigeon.md)).

## Runtime Behavior

Handlers dispatch by method; wrong context for an API throws/misbehaves; heavy main-thread work causes ANRs. Activity may be absent (background) — guard.

## Flutter Engine Behavior

`MainActivity`/plugin attaches to the engine's binary messenger; the engine marshals channel messages ([10 · engine_internals](../10%20Flutter%20Architecture/engine_internals.md)).

## Dart VM Behavior

Not applicable.

## Examples

```kotlin
package com.example.app
import android.content.Context
import android.os.BatteryManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryLevel" -> {
                        // system service -> applicationContext (no activity leak)
                        val bm = applicationContext.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                        result.success(bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
                    }
                    "heavyCompute" -> {
                        // offload heavy work, reply on MAIN thread
                        scope.launch {
                            val value = withContext(Dispatchers.Default) { doHeavyWork() }
                            result.success(value) // back on main
                        }
                    }
                    "openSettings" -> {
                        // needs the Activity (this is FlutterActivity -> is an Activity)
                        startActivity(android.content.Intent(android.provider.Settings.ACTION_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun doHeavyWork(): Int = (1..1_000_000).sum()

    override fun onDestroy() { scope.cancel(); super.onDestroy() } // cleanup
}
```

```kotlin
// Plugin form (FlutterPlugin + ActivityAware) — sketch:
// class MyPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
//   private var channel: MethodChannel? = null
//   private var activity: Activity? = null
//   override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
//     channel = MethodChannel(b.binaryMessenger, "my_plugin").also { it.setMethodCallHandler(this) }
//   }
//   override fun onDetachedFromEngine(b: ...) { channel?.setMethodCallHandler(null); channel = null }
//   override fun onAttachedToActivity(b: ActivityPluginBinding) { activity = b.activity }
//   override fun onDetachedFromActivity() { activity = null } // clear to avoid leak
// }
```

## Diagrams

```mermaid
flowchart LR
    Need{what does the API need?}
    Need -->|system service/resources| AppContext[applicationContext (safe, long-lived)]
    Need -->|UI/permissions/startActivity| Activity[Activity via ActivityAware (clear on detach)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Holding a stale `Activity`/`Context` | Memory leak | Use `applicationContext`; clear activity on detach |
| Using app context for Activity-only APIs | Crash (e.g., can't `startActivityForResult`) | Get Activity via `ActivityAware` |
| Heavy work on the main thread | ANR/jank | Offload (coroutine/thread); reply on main |
| Replying off the main thread | Errors | Post `result` to main |
| Not cleaning up on detach | Leaks (channel/activity/receivers) | Null refs + unregister in detach |
| Assuming an Activity always exists | Null in background | Guard/handle absence |

## Best Practices

- Register handlers in **`configureFlutterEngine`** (app) or **`onAttachedToEngine`** (plugin, `FlutterPlugin`).
- Use **`applicationContext`** for system services/resources; get the **`Activity`** via **`ActivityAware`** only when needed (UI/permissions/startActivity), and **clear it on detach**.
- **Offload heavy work** off the main thread (coroutines/`Dispatchers.Default`); **reply on the main thread**.
- Return via `result.success/error/notImplemented`; use **codec-supported types**; consider **Pigeon** for type-safety.
- **Clean up** on detach (null channel/activity, unregister receivers); handle a missing Activity (background).

## Performance

Main-thread handlers must return quickly — offload heavy work to avoid ANRs; keep messages small ([26 · platform_channel_fundamentals](../26%20Platform%20Channels/platform_channel_fundamentals.md), [Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Full access to Android APIs/SDKs from Kotlin, proper lifecycle integration, coroutine-friendly offloading.
- **−** Context/Activity/lifecycle pitfalls (leaks/crashes), main-thread discipline, stringly-typed channels (Pigeon helps), Kotlin/Android knowledge required.

## Interview Questions

1. **🟢 Where do you register Android channel handlers?** — In `MainActivity.configureFlutterEngine` (app) or a plugin's `onAttachedToEngine` (`FlutterPlugin`).
2. **🟢 `applicationContext` vs `Activity` — when each?** — App context for system services/resources (long-lived, no leak); the Activity for UI, permissions, and `startActivity`/`ForResult`.
3. **🟡 How does a plugin get the Activity?** — Implement `ActivityAware` (`onAttachedToActivity`/`onDetachedFromActivity`) and clear the reference on detach.
4. **🟡 Why offload heavy work, and how do you reply?** — Main-thread handlers must return fast (ANR risk); offload to a coroutine/thread and call `result` back on the main thread.
5. **🟡 How do you return errors/values?** — `result.success(v)`, `result.error(code,msg,details)`, `result.notImplemented()`; codec-supported types only.
6. **🔴 What causes native memory leaks here?** — Holding a stale `Activity`/`Context` (or unregistered receivers) past its lifecycle; use app context and clear refs on detach.
7. **🔴 How do you make Kotlin channel code type-safe?** — Use Pigeon-generated Kotlin interfaces instead of stringly-typed `setMethodCallHandler`.

## Senior Engineer Tips

- Default to `applicationContext`; reach for the `Activity` only for APIs that require it, and always clear it on detach to avoid leaks.
- Wrap heavy native work in a coroutine (`Dispatchers.Default`) and marshal the result to main — a common ANR source otherwise.
- Prefer Pigeon for anything beyond a couple of methods; it removes Kotlin-side name/type mismatches.

## Architect Perspective

The Kotlin channel layer is the Android implementation of your native features; correct context/activity/lifecycle/threading handling makes it leak-free, crash-free, and responsive. Packaged as a plugin with `FlutterPlugin`/`ActivityAware` (and Pigeon types), it's reusable and maintainable — the Android side of the repository-fronted native integration ([Module 26](../26%20Platform%20Channels/README.md)).

## Summary

- Register handlers in `configureFlutterEngine`/`onAttachedToEngine`; use `applicationContext` for services, `Activity` (via `ActivityAware`) for UI/permissions — clear it on detach.
- Offload heavy work; reply on the main thread; return via `result.*`; clean up on detach.
- Use codec types (or Pigeon); this is the Android side of channels/plugins.

## Revision Notes

- Register: `configureFlutterEngine` (app) / `FlutterPlugin.onAttachedToEngine` (plugin).
- `applicationContext` (services, no leak) vs `Activity` (UI/permissions/startActivity, via `ActivityAware`, clear on detach).
- Offload heavy work (coroutine/`Dispatchers.Default`), reply on main; `result.success/error/notImplemented`.
- Clean up on detach (channel/activity/receivers); Pigeon for type-safety.

## Practice Questions

1. When do you need the `Activity` vs `applicationContext`?
2. Why/how do you offload heavy native work and reply?
3. What causes leaks in Kotlin channel code?

## Coding Questions

1. Write a Kotlin `MethodChannel` handler using `applicationContext` for a system service.
2. Add a method needing the `Activity` (via `ActivityAware`) and clear the ref on detach.
3. Offload heavy work with a coroutine and reply on the main thread.

## Mini Project

**Kotlin channel service (Flutter + Android):** Implement a Kotlin `MethodChannel` with `getBatteryLevel` (applicationContext), `heavyCompute` (coroutine offload → main-thread reply), and `openSettings` (Activity), registered in `MainActivity` (or a `FlutterPlugin`+`ActivityAware`), with proper cleanup. Wrap the Dart side in a repository. Acceptance: correct context/activity usage; no leaks; heavy work off main; results/errors returned; runs on device.
