# FFI (`dart:ffi` — Direct C Interop)

> FFI lets Dart call **C** functions directly — synchronously, in-process, with no channel/serialization overhead — ideal for using native C/C++ libraries (crypto, compression, image processing, existing SDKs); `ffigen` generates the Dart bindings from C headers.

## Introduction

`dart:ffi` (Foreign Function Interface) binds Dart to native C ABIs: load a shared library, look up functions, and call them with C-compatible types — no platform channels, no serialization. This file covers when to use FFI vs channels, the binding mechanics, `ffigen`, memory management, and threading.

## Why this concept exists

Channels are great for platform APIs but add async + serialization overhead and can't directly use C libraries. Many high-performance or existing native libraries are C/C++; FFI calls them **directly and synchronously**, avoiding the channel round-trip — the right tool for heavy computation or reusing C code.

## Real-world analogy

Channels are **mailing a request to another department** (async, serialized); FFI is **calling a colleague's function directly in the same office** — instant, in-process, no envelopes. But you must speak their exact language (C types) and manage shared resources (memory) yourself.

## Problem Statement

You need to use a C crypto/compression library (or hand-written C) from Dart with minimal overhead — not a platform API. You'll load a shared lib, bind a function (via `ffigen`), call it, and manage native memory correctly.

## Internal Working

```mermaid
flowchart TD
    Lib[DynamicLibrary.open('libx.so/.dylib/.dll')] --> Lookup[lookupFunction<C, Dart>('name')]
    Lookup --> Call[call directly (sync, in-process)]
    Call --> Types[C-compatible types: Int32/Pointer/Struct...]
    Ffigen[ffigen: C headers -> Dart bindings] --> Lookup
    Memory[malloc/free native memory] --> Manual[manage manually]
```

- **Load the library**: `DynamicLibrary.open('libfoo.so')` (Android), `.process()`/framework on iOS/macOS, `.dll` on Windows — bundle the native lib with the app/plugin.
- **Bind functions**: `lookupFunction<NativeSig, DartSig>('c_name')` maps a C function to a callable Dart function; types must be **C-compatible** (`Int32`, `Double`, `Pointer<Utf8>`, `Pointer<Struct>`, etc. from `dart:ffi`/`package:ffi`).
- **`ffigen`**: generates Dart bindings from C headers automatically (types, structs, functions) — the practical way to bind non-trivial libraries.
- **Memory management**: you **allocate/free native memory** (`malloc`/`calloc`/`free` from `package:ffi`) for strings/structs/buffers passed to C; Dart's GC doesn't manage native memory — leaks/UAF are on you. Convert strings via `toNativeUtf8`/`toDartString`.
- **Synchronous + in-process**: FFI calls run **on the calling isolate synchronously** — long C calls **block** that isolate (jank if UI isolate). Run heavy FFI on a **background isolate** (`Isolate.run`) ([02 · isolates](../02%20Advanced%20Dart/isolates.md)).
- **Callbacks**: C can call back into Dart via `NativeCallable`/`Pointer.fromFunction` (with constraints).
- **Not for platform APIs**: use channels/plugins for OS/platform features; FFI is for C/C++ libraries and perf-critical code.

## Memory Representation

Native (C) memory is **outside** the Dart heap — manually allocated/freed; Dart objects wrap pointers. Mismanagement leaks or crashes (use-after-free). Big buffers avoid channel serialization cost.

## Compiler Behavior

`ffigen` generates typed bindings at build; FFI signatures are checked against declared C/Dart types (mismatches are your responsibility and can crash if wrong). AOT-compatible (no reflection).

## Runtime Behavior

FFI calls execute synchronously in-process; wrong types/ABI or bad pointers crash natively. No async unless you offload to an isolate. Native memory must be freed.

## Flutter Engine Behavior

FFI is independent of the platform-channel/embedder path — it's the Dart runtime calling C directly ([10 · engine_internals](../10%20Flutter%20Architecture/engine_internals.md)).

## Dart VM Behavior

FFI runs on the calling isolate; long calls block it — use `Isolate.run` for heavy work ([02 · isolates](../02%20Advanced%20Dart/isolates.md)).

## Examples

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart'; // malloc, Utf8

// C: int32_t add(int32_t a, int32_t b);
typedef _AddC = Int32 Function(Int32, Int32);
typedef _AddDart = int Function(int, int);

// C: int32_t str_len(const char* s);
typedef _StrLenC = Int32 Function(Pointer<Utf8>);
typedef _StrLenDart = int Function(Pointer<Utf8>);

class NativeMath {
  late final DynamicLibrary _lib;
  late final _AddDart add;
  late final _StrLenDart _strLen;

  NativeMath() {
    _lib = DynamicLibrary.open('libnativemath.so'); // load shared lib
    add = _lib.lookupFunction<_AddC, _AddDart>('add'); // bind (sync, direct)
    _strLen = _lib.lookupFunction<_StrLenC, _StrLenDart>('str_len');
  }

  int stringLength(String s) {
    final ptr = s.toNativeUtf8();        // allocate native memory
    try {
      return _strLen(ptr);
    } finally {
      malloc.free(ptr);                  // MUST free native memory
    }
  }
}

// Heavy FFI work off the UI isolate:
// final result = await Isolate.run(() => NativeMath().add(2, 3));
```

```yaml
# For non-trivial libs, generate bindings with ffigen (dev dependency):
# dart run ffigen --config ffigen.yaml   # reads C headers -> Dart bindings
```

## Diagrams

```mermaid
flowchart LR
    Channel[Platform channel] --> Async[async + serialized (platform APIs)]
    FFI[dart:ffi] --> Direct[sync + in-process, no serialization (C libraries)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Not freeing native memory | Leaks / crashes | `malloc.free` in `finally`; own the lifecycle |
| Heavy FFI on the UI isolate | Blocks/janks (synchronous) | Run on a background isolate |
| Wrong C/Dart type signatures/ABI | Native crash/corruption | Match types exactly; use `ffigen` |
| Using FFI for platform APIs | Wrong tool | Use channels/plugins for OS features |
| Forgetting to bundle the native lib | `DynamicLibrary.open` fails | Include/build the lib per platform |
| Use-after-free on pointers | Crash | Careful pointer lifetime management |

## Best Practices

- Use FFI for **C/C++ libraries and perf-critical code**, not platform APIs (use channels for those).
- Generate bindings with **`ffigen`** for anything non-trivial (types/structs/functions from headers).
- **Manage native memory** explicitly (`malloc`/`free`, `finally`); convert strings via `toNativeUtf8`/`toDartString`.
- Run **heavy/blocking FFI on a background isolate** (`Isolate.run`) to keep the UI responsive.
- **Bundle/build** the native library per platform; wrap FFI behind a **repository/service** (safe Dart API, memory handled internally).

## Performance

FFI is **fast** (no serialization/async round-trip) — ideal for heavy computation/large buffers. But it's synchronous: offload long calls to an isolate. Native memory management avoids leaks that would degrade the app ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Direct, synchronous, low-overhead C interop; reuse existing C/C++ libs; great performance; no serialization.
- **−** Manual memory management (leaks/UAF), synchronous (blocks isolate), C-type/ABI matching, per-platform native builds, more error-prone than channels.

## Interview Questions

1. **🟢 What is `dart:ffi`?** — A foreign function interface letting Dart call C functions directly (in-process, synchronous), without platform channels.
2. **🟢 FFI vs platform channels — when each?** — FFI for C/C++ libraries and perf-critical code (direct/sync); channels for platform/OS APIs (async/serialized).
3. **🟡 How do you bind a C function?** — Load the lib (`DynamicLibrary.open`) and `lookupFunction<NativeSig, DartSig>('name')` with C-compatible types (or use `ffigen`).
4. **🟡 How is memory managed?** — Manually: allocate with `malloc`/`calloc`, free with `free` (native memory is outside Dart's GC); mismanagement leaks or crashes.
5. **🟡 Why offload heavy FFI to an isolate?** — FFI calls are synchronous on the calling isolate; long calls block it (UI jank) — run them via `Isolate.run`.
6. **🔴 What does `ffigen` do?** — Generates Dart bindings (types/structs/functions) from C headers, automating non-trivial FFI binding.
7. **🔴 What are FFI's main risks vs channels?** — Manual memory (leaks/use-after-free), synchronous blocking, and C-type/ABI mismatches (native crashes) — more error-prone.

## Senior Engineer Tips

- Wrap FFI behind a Dart repository/service that owns memory (allocate/free internally) and exposes a safe, typed Dart API — callers never touch pointers.
- Use `ffigen` for real libraries; hand-writing bindings for many functions/structs is error-prone.
- Always offload heavy/blocking FFI to an isolate; treat native memory like a resource with a strict acquire/free lifecycle (`finally`).

## Architect Perspective

FFI is the high-performance/native-library integration tier, distinct from channels (platform APIs). It enables reusing C/C++ ecosystems (crypto/media/ML) and speeding up hot paths, at the cost of manual memory/threading discipline. Encapsulated behind safe repositories with isolate offloading, it composes with the rest of native integration for a complete interop story ([platform_channel_fundamentals.md](platform_channel_fundamentals.md), [Module 21](../21%20Performance/README.md)).

## Summary

- `dart:ffi` calls C directly (sync, in-process, no serialization) — for C/C++ libraries and perf-critical code, not platform APIs.
- Load lib + `lookupFunction` (or `ffigen`); manage native memory manually; offload heavy calls to an isolate.
- Wrap behind a safe repository; bundle native libs per platform.

## Revision Notes

- FFI = direct C calls (sync/in-process); vs channels (async/serialized, platform APIs).
- `DynamicLibrary.open` + `lookupFunction<NativeSig, DartSig>`; `ffigen` for bindings; C-compatible types.
- Manual memory (`malloc`/`free`, `toNativeUtf8`); offload heavy FFI to `Isolate.run`; bundle native lib.
- Wrap behind repository (owns memory, safe API); AOT-compatible.

## Practice Questions

1. When choose FFI over a platform channel?
2. Who manages native memory, and how?
3. Why offload heavy FFI to an isolate?

## Coding Questions

1. Bind and call a C `add(int,int)` via `lookupFunction`.
2. Pass/return a C string with proper `malloc`/`free`.
3. Wrap FFI in a repository (memory-safe) and run a heavy call via `Isolate.run`.

## Mini Project — Module capstone

**C library bridge (Flutter + C):** Build a small C library (e.g., a fast hash/compress function), bind it via `ffigen`/`lookupFunction`, and wrap it in a `NativeCryptoRepository` that owns native memory (allocate/free), exposes a safe Dart API, and runs heavy calls on a background isolate. Contrast with a `MethodChannel` approach in notes. Acceptance: direct C call works; no memory leaks (freed in `finally`); heavy work off UI isolate; repository-wrapped; runs on device. (Completes the native-integration story: channels + Pigeon/plugins + FFI.)
