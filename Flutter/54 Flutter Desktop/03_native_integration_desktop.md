# Native Integration on Desktop

> Desktop gives your Flutter app **full OS power** and three ways to reach it: **`dart:io` / plugins** for ordinary OS access (**real, unrestricted filesystem** — actual paths, not scoped storage — plus native file dialogs via `file_selector`/`file_picker`), **platform channels** to call **native code in the platform runner** (Win32/C++, Cocoa/Swift, GTK/C++) when a plugin doesn't exist, and **FFI (`dart:ffi`)** to call **C/C++ native libraries directly** (no channel round-trip) — ideal for reusing existing native libs or high-performance native work. Desktop's native surface is far larger than mobile's; use the lightest tool that fits (io/plugin → FFI → channel).

## Introduction

This file covers desktop native integration: unrestricted filesystem + native dialogs, platform channels on desktop, and FFI to native libraries — and how to choose among them. It applies platform-channel concepts ([Module 26](../26%20Platform%20Channels/README.md)) and file handling ([Module 34](../34%20File%20Handling/README.md)) to the desktop's full-OS context.

## Why this concept exists

Desktop apps routinely need real OS access — read/write anywhere the user chooses, call system libraries, integrate with native tooling — well beyond a mobile sandbox or browser. Flutter provides layered mechanisms (`dart:io`/plugins, channels, FFI) so you can access the OS at the right level. Knowing which to use avoids over-engineering (a channel where `dart:io` suffices) or under-reaching (missing FFI for a native lib).

## Real-world analogy

Desktop native access is like having **full keys to the building** (vs a mobile guest pass): most rooms you enter directly (`dart:io`/plugins — real filesystem), for a **specialized machine you already own** you plug straight into it (**FFI** to a C/C++ library), and for **custom on-site work** you hire a local contractor who speaks the building's language (**platform channel** to native runner code). You use the **simplest access that gets the job done**, not a contractor for opening a door.

## Internal Working

```mermaid
flowchart TD
    Need{native need}
    Need -->|ordinary OS/filesystem| IO[dart:io + plugins (real paths, native file dialogs)]
    Need -->|call a C/C++ library directly| FFI[dart:ffi -> native .dll/.dylib/.so]
    Need -->|custom native code, no plugin| Channel[platform channel -> runner (Win32/Cocoa/GTK)]
    IO & FFI & Channel --> OS[full desktop OS: filesystem, native libs, system APIs]
    Note[pick the lightest tool: io/plugin -> FFI -> channel]
```

- **Full filesystem access (the big desktop win)**:
  - Desktop has **real, unrestricted filesystem** via **`dart:io`** (`File`/`Directory` at actual OS paths) — **not** mobile's scoped/sandboxed storage. Read/write user-chosen locations (Documents, arbitrary paths).
  - **Native file dialogs**: use **`file_selector`**/`file_picker` for **open/save dialogs** returning real paths; `path_provider` for standard dirs. Users pick files/folders anywhere (a core desktop expectation).
  - (macOS **App Store** builds are **sandboxed** with entitlements — plan file access accordingly; direct-download macOS + Windows/Linux are unsandboxed.)
- **Platform channels on desktop** ([Module 26](../26%20Platform%20Channels/README.md)):
  - Same `MethodChannel`/`EventChannel` mechanism as mobile, but the native side is the **desktop runner**: **Win32/C++** (`windows/`), **Cocoa/Swift-ObjC** (`macos/`), **GTK/C++** (`linux/`).
  - Use when you need **custom native code** the platform provides but no plugin exposes (e.g., a Windows registry call, a macOS API). You implement the handler in each platform's runner.
- **FFI (`dart:ffi`) — direct native calls**:
  - Call **C/C++ (and C-ABI) libraries directly** from Dart — no channel serialization/round-trip. Load a **`.dll`/`.dylib`/`.so`**, bind functions/structs, call them synchronously.
  - **Ideal for**: reusing an **existing native library** (image codecs, crypto, hardware SDKs, computation), **high-performance** native work, or wrapping a C API. **`ffigen`** generates bindings from C headers.
  - Runs on the **calling thread** (blocking) — offload heavy/long FFI calls to an **isolate** (desktop has full isolates) to avoid jank. Manage native memory (allocate/free) carefully — FFI is unsafe if mishandled.
  - FFI works on mobile too, but is **especially common on desktop** for reusing native libs.
- **Choosing the mechanism** (lightest that fits):
  - **`dart:io`/existing plugin** → ordinary OS/filesystem needs (first choice).
  - **FFI** → calling a **C/C++ library** directly (reuse/perf) — no per-platform native code to write.
  - **Platform channel** → **custom platform code** with **no library/plugin** and needing OS-specific APIs — most work (write native per OS).
- **System integration** (via plugins/channels): system tray, notifications, clipboard, global shortcuts, single-instance, launch-at-startup, deep links — many via community desktop plugins (check support; FFI/channel for gaps — [01_desktop_fundamentals.md](01_desktop_fundamentals.md)).
- **Isolates for heavy native work**: desktop has **full isolates** — run heavy FFI/native computation off the UI isolate ([Module 02](../02%20Advanced%20Dart/README.md)).

## Memory Representation

`dart:io` uses OS file handles at real paths. FFI holds pointers to native memory (you allocate/free) + loaded library handles — mismanagement leaks/crashes. Channel calls marshal data to the runner. Desktop's full OS resources are available (no sandbox except macOS App Store).

## Compiler Behavior

FFI binds against native symbols (via `ffigen`/manual); native libs must be **bundled/linked** for the target. Channels compile Dart↔native (runner) code per platform. `dart:io` is fully available (unlike web).

## Runtime Behavior

`dart:io` reads/writes real paths; native dialogs return real paths; FFI calls execute native code synchronously on the calling thread (isolate for heavy); channels round-trip to the runner. Full OS access at runtime.

## Flutter Engine Behavior

The desktop embedder hosts the runner (where channel handlers live) + the engine; FFI bypasses the engine (direct Dart↔native). Native windows/menus/tray integrate via embedder/plugins.

## Dart VM Behavior

AOT with **full isolates + FFI + `dart:io`** (unlike web). Heavy FFI/native work → isolate to keep the UI isolate responsive; FFI is synchronous on its thread.

## Examples

```dart
// Full filesystem — real paths + native open/save dialogs (desktop)
import 'dart:io';
import 'package:file_selector/file_selector.dart';

Future<void> saveReport(String content) async {
  final path = await getSaveLocation(suggestedName: 'report.txt');   // native save dialog
  if (path != null) await File(path.path).writeAsString(content);    // real path, unrestricted
}
final file = await openFile(acceptedTypeGroups: [XTypeGroup(extensions: ['csv'])]); // native open
```

```dart
// FFI — call a C library directly (e.g., a native computation lib)
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _NativeAdd = Int32 Function(Int32 a, Int32 b);
typedef _DartAdd = int Function(int a, int b);
final _lib = DynamicLibrary.open(Platform.isWindows ? 'native.dll'
    : Platform.isMacOS ? 'libnative.dylib' : 'libnative.so');
final int Function(int, int) nativeAdd =
    _lib.lookupFunction<_NativeAdd, _DartAdd>('add');
// Heavy FFI work -> run in an isolate (Isolate.run/compute) to avoid blocking the UI.
```

```text
Choose the mechanism (lightest that fits):
  ordinary OS/filesystem  -> dart:io + plugins (file_selector/path_provider)   [first choice]
  reuse a C/C++ library / high-perf native  -> FFI (dart:ffi, ffigen)          [no per-OS native code]
  custom OS API, no plugin  -> platform channel -> runner (Win32/Cocoa/GTK)    [write native per OS]
  # heavy native work -> offload to an isolate (desktop has full isolates)
```

## Diagrams

```mermaid
flowchart LR
    App[Dart app] --> Choose2{native need}
    Choose2 -->|filesystem/OS| IO2[dart:io + plugins (real paths + dialogs)]
    Choose2 -->|C/C++ lib| FFI2[dart:ffi -> .dll/.dylib/.so]
    Choose2 -->|custom OS code| Ch[channel -> runner per OS]
    IO2 & FFI2 & Ch --> OSAccess[full desktop OS]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Using scoped-storage mobile patterns | Desktop has real filesystem | Use `dart:io` real paths + native dialogs |
| Writing a channel where `dart:io`/plugin suffices | Over-engineering | Use `dart:io`/existing plugin first |
| Ignoring FFI for a native C/C++ lib | Reinventing / slow round-trips | FFI to call the library directly |
| Blocking the UI on heavy FFI/native | Jank/freeze | Offload to an isolate |
| Mismanaging FFI native memory | Leaks/crashes (FFI is unsafe) | Allocate/free carefully; wrap safely |
| Assuming a plugin supports desktop | Thinner ecosystem | Check; FFI/channel fallback |
| Forgetting macOS App Store sandbox | File access blocked | Entitlements / plan sandbox |
| Not bundling native libs | FFI load fails | Bundle/link `.dll`/`.dylib`/`.so` for the target |

## Best Practices

- Use the **lightest mechanism that fits**: **`dart:io`/plugins** for ordinary OS/filesystem (real paths + **native file dialogs**), **FFI** to call **C/C++ libraries** directly (reuse/perf, no per-OS native code), **platform channels** only for **custom OS code with no plugin** (write native per runner).
- Leverage **full, unrestricted filesystem** (real paths, not scoped) — but handle the **macOS App Store sandbox** (entitlements) when applicable.
- **Offload heavy FFI/native work to isolates** (desktop has full isolates) and **manage FFI native memory carefully** (allocate/free; FFI is unsafe if mishandled); **bundle native libs** for each target.
- **Check plugin desktop support**; fall back to **FFI/channels** for gaps; use `ffigen` to generate FFI bindings.

## Performance

FFI is **fast** (direct native calls, no serialization) — ideal for heavy computation/native libs — but **synchronous/blocking** on its thread, so isolate heavy calls. `dart:io` is native-fast. Channels have marshaling overhead (fine for occasional calls). Desktop's full isolates keep the UI responsive during native work ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Full OS power (real filesystem/native dialogs), direct native-library reuse + performance (FFI), custom OS code (channels), full isolates — far beyond mobile/web.
- **−** Thinner plugin ecosystem (more FFI/channel work), FFI is unsafe (memory/threading discipline), per-OS native code for channels, macOS sandbox nuance, must bundle native libs.

## Interview Questions

1. **🟢 What are the three ways to access native functionality on desktop?** — `dart:io`/plugins (ordinary OS/filesystem + native dialogs), FFI (call C/C++ libraries directly), and platform channels (custom native runner code) — pick the lightest that fits.
2. **🟢 How does desktop filesystem access differ from mobile?** — Desktop has real, unrestricted filesystem (actual paths via `dart:io` + native open/save dialogs), not mobile's scoped/sandboxed storage (macOS App Store builds are the sandboxed exception).
3. **🟡 When do you use FFI vs a platform channel?** — FFI to call an existing C/C++ library directly (reuse/high perf, no per-OS native code, no round-trip); a channel for custom OS-specific code with no library/plugin (write native per runner).
4. **🟡 What are FFI's risks and how do you handle them?** — It's synchronous/blocking (offload heavy calls to an isolate) and unsafe with native memory (allocate/free carefully; wrap safely); bundle the native lib for each target.
5. **🟡 Why prefer `dart:io`/plugins first?** — They're the simplest for ordinary OS/filesystem needs; a channel/FFI there is over-engineering.
6. **🔴 How do platform channels differ on desktop vs mobile?** — Same mechanism, but the native side is the desktop runner (Win32/C++, Cocoa/Swift, GTK/C++) — you implement handlers per OS.
7. **🔴 How do you keep the UI responsive during heavy native work?** — Offload to an isolate (desktop has full isolates) since FFI/native calls can block the calling thread.

## Senior Engineer Tips

- Reach for FFI when you have an existing C/C++ library or need real native performance; it avoids per-OS channel code and channel round-trips — but isolate heavy calls and manage native memory rigorously, because FFI mistakes crash the app.
- Use `dart:io` + native file dialogs (`file_selector`) for the common desktop case (real filesystem); porting mobile scoped-storage patterns to desktop is both unnecessary and worse UX.
- Check plugin desktop support early and plan the FFI/channel fallback; the thinner desktop ecosystem is where "there's no plugin for that" surprises happen.

## Architect Perspective

Native integration is where desktop's full-OS power pays off: layered mechanisms (`dart:io`/plugins → FFI → channels) let you access the filesystem, reuse native libraries, and call OS APIs at the right level, with isolates keeping the UI responsive. Choosing the lightest tool, handling FFI's unsafety, and planning for the thinner plugin ecosystem are the architect's calls — enabling desktop apps to do real system work (a key reason to pick desktop over web) while staying maintainable ([01_desktop_fundamentals.md](01_desktop_fundamentals.md), [Module 26](../26%20Platform%20Channels/README.md), [Module 34](../34%20File%20Handling/README.md)).

## Summary

- Desktop gives full OS access via three mechanisms: `dart:io`/plugins (real unrestricted filesystem + native dialogs), FFI (`dart:ffi` — call C/C++ libraries directly, reuse/perf), and platform channels (custom native runner code) — pick the lightest that fits.
- FFI is fast but synchronous/unsafe → isolate heavy calls + manage native memory + bundle libs; channels are per-OS native code; `dart:io` is the first choice for filesystem/OS.
- Check thinner plugin support (FFI/channel fallback); mind the macOS App Store sandbox; use full isolates for heavy native work.

## Revision Notes

- Filesystem: real/unrestricted via `dart:io` (actual paths) + native open/save dialogs (`file_selector`/`file_picker`) + `path_provider` — not mobile scoped storage (macOS App Store = sandboxed exception, entitlements).
- FFI (`dart:ffi`): call C/C++ (C-ABI) libraries directly (`DynamicLibrary.open`, `lookupFunction`, `ffigen`); fast (no round-trip) but synchronous/blocking (isolate heavy) + unsafe native memory (allocate/free); bundle `.dll`/`.dylib`/`.so`. Ideal for reuse/perf.
- Channels: same as mobile but native side = desktop runner (Win32/C++, Cocoa/Swift, GTK/C++) for custom OS code w/o plugin. Choose lightest: `dart:io`/plugin → FFI → channel. Full isolates; thinner plugin ecosystem (FFI/channel fallback); system tray/notifications/clipboard/global-shortcuts via plugins.

## Practice Questions

1. When do you use `dart:io`, FFI, and platform channels respectively?
2. How does desktop filesystem access differ from mobile, and what dialogs do you use?
3. What are FFI's performance benefits and risks?

## Coding Questions

1. Read/write a user-chosen file via native open/save dialogs + `dart:io`.
2. Call a C function via FFI (load lib + `lookupFunction`), offloading heavy work to an isolate.
3. Add a platform channel handler in a desktop runner for a custom OS call.

## Mini Project

**Desktop native integration (Flutter Desktop):** Build a tool that (a) opens/saves user-chosen files via native dialogs + `dart:io` (real filesystem), (b) calls a native C/C++ function via **FFI** (with heavy work offloaded to an isolate + safe native-memory handling), and (c) uses a **platform channel** for one custom OS call with no plugin — choosing the lightest mechanism for each and checking plugin desktop support. Acceptance: real filesystem access via native dialogs (`dart:io`); FFI call to a native lib (bundled, isolate-offloaded, memory-safe); one channel for custom OS code (per-runner); lightest-tool-per-need justified; macOS-sandbox + plugin-ecosystem caveats noted.
