# Reading & Writing Files (`dart:io` `File`)

> Read/write with `dart:io` `File`: `readAsString`/`writeAsString` (text/JSON), `readAsBytes`/`writeAsBytes` (binary), always **async** (never the `...Sync` variants on the UI thread). For **large files**, don't load the whole thing into memory — use **streams** (`file.openRead()` / `openWrite()`) and offload heavy parsing to an **isolate**; write **atomically** (temp file + rename) so a crash mid-write can't corrupt data.

## Introduction

Once you have a path ([app_directories_and_paths.md](app_directories_and_paths.md)), you read/write bytes or text. This file covers the `File` API for text/bytes/JSON, async vs sync, streaming large files, atomic writes, and offloading heavy work — the mechanics of not blocking the UI or losing data.

## Why this concept exists

File I/O is blocking and can be slow (large files, slow storage). Dart's `File` offers async APIs so I/O doesn't jank the UI, and streaming so you don't OOM on big files. Atomic writes exist because a partial write (crash/kill mid-write) otherwise corrupts the file.

## Real-world analogy

Reading a small file is **grabbing a note off the desk** (`readAsString`). A huge file is a **library you read page-by-page** (stream) rather than photocopying the whole thing into your arms (loading into memory → OOM). An atomic write is **writing the final copy on a fresh sheet, then swapping it for the old one in one move** — so no one ever sees a half-written page.

## Problem Statement

Persist a JSON app-state index (small), append log lines efficiently, and import/parse a 200 MB data file without freezing the app or running out of memory — safely against crashes. You'll use text/bytes APIs, streaming, and atomic writes.

## Internal Working

```mermaid
flowchart TD
    Size{file size}
    Size -->|small| Whole[readAsString/Bytes + writeAsString/Bytes (async)]
    Size -->|large| Stream[openRead() / openWrite() streaming]
    Whole --> JSON[jsonDecode/Encode for JSON]
    Stream --> Iso[heavy parse -> isolate (compute)]
    Write[safe write] --> Atomic[write temp -> rename over target]
```

- **Small files (whole)**: `await file.writeAsString(jsonEncode(data))` / `final s = await file.readAsString()`; `writeAsBytes`/`readAsBytes` for binary (images/blobs). JSON = `dart:convert` `jsonEncode`/`jsonDecode`.
- **Async only**: use the async methods; the **`...Sync`** variants block the calling isolate (UI jank) — avoid on the UI thread. Handle `FileSystemException` (missing/permission/full).
- **Existence/dirs**: `await file.exists()`, `await file.create(recursive: true)` (creates parent dirs), `file.delete()`, `dir.list()` to enumerate.
- **Append**: `writeAsString(s, mode: FileMode.append)` or an `IOSink` (`file.openWrite(mode: append)`) for many appends (logs) — flush/close it.
- **Large files (stream)**: `file.openRead()` yields `Stream<List<int>>` — process chunk-by-chunk (decode lines, hash, upload) without loading all into memory; `file.openWrite()` gives an `IOSink` to write incrementally.
- **Offload heavy CPU** (parsing/transform of big data) to an **isolate** via `compute()`/`Isolate.run` so decoding doesn't jank ([02 · isolates](../02%20Advanced%20Dart/isolates_and_concurrency.md)).
- **Atomic write**: write to a temp file, then `rename()` over the target (rename is atomic on the same volume) — prevents corruption if interrupted; pair with the right directory.
- **Encoding**: default UTF-8 for text; specify explicitly if needed.

## Memory Representation

`readAsBytes`/`readAsString` load the **entire** file into memory (fine for small, fatal for huge). Streaming holds only a chunk at a time. An `IOSink` buffers writes until flushed/closed.

## Compiler Behavior

Not applicable.

## Runtime Behavior

Async I/O runs off the main thread (event loop resumes on completion); sync I/O blocks. Streaming processes incrementally. A crash mid-non-atomic-write leaves a corrupt/partial file.

## Flutter Engine Behavior

Not applicable; `dart:io` talks to the OS file system directly.

## Dart VM Behavior

Async file ops use the VM's I/O thread pool; heavy CPU parsing still runs on the calling isolate unless you offload to another isolate.

## Examples

```dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // compute

// Small JSON: read/write whole (async)
Future<void> saveIndex(File file, Map<String, dynamic> index) async {
  await _atomicWriteString(file, jsonEncode(index));    // safe write
}
Future<Map<String, dynamic>> loadIndex(File file) async {
  if (!await file.exists()) return {};
  return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
}

// Atomic write: temp -> rename (no corruption on crash)
Future<void> _atomicWriteString(File target, String contents) async {
  final tmp = File('${target.path}.tmp');
  await tmp.writeAsString(contents, flush: true);
  await tmp.rename(target.path);                        // atomic swap
}

// Append logs efficiently with an IOSink
Future<void> appendLog(File logFile, String line) async {
  final sink = logFile.openWrite(mode: FileMode.append);
  sink.writeln(line);
  await sink.flush();
  await sink.close();
}

// Large file: stream line-by-line, offload heavy parse to an isolate
Future<int> countMatches(File big, String needle) async {
  var count = 0;
  final lines = big.openRead().transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {                     // one line at a time (low memory)
    if (line.contains(needle)) count++;
  }
  return count;
}
Future<Report> parseHeavy(String path) => compute(_parseInIsolate, path); // off UI thread
```

## Diagrams

```mermaid
flowchart LR
    Small[small file] --> WholeIO[readAsString/writeAsString]
    Large[large file] --> StreamIO[openRead/openWrite chunks]
    Heavy[heavy parse] --> Isolate[compute()/Isolate.run]
    Safe[must not corrupt] --> AtomicW[temp + rename]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| `...Sync` on the UI thread | Jank/ANR | Use async APIs |
| `readAsBytes` on a huge file | OOM | Stream with `openRead()` |
| Non-atomic write | Corruption on crash | temp + `rename` |
| Heavy parse on UI isolate | Jank | Offload via `compute`/isolate |
| Not handling `FileSystemException` | Crash (missing/full/perm) | try/catch + fallbacks |
| Not closing `IOSink` | Data not flushed/leak | `flush()` + `close()` |
| Reopening file per append | Slow | Keep an `IOSink` / batch |

## Best Practices

- Use **async** `File` APIs; **stream** large files (`openRead`/`openWrite`) instead of loading them whole; **offload heavy parsing** to an isolate.
- Write **atomically** (temp + `rename`) for anything important; handle **`FileSystemException`** (missing/full/permission).
- Use **`IOSink`** for many appends (logs), flushing/closing it; JSON via `dart:convert`; specify **encoding** when needed.
- Create parent dirs with `create(recursive: true)`; check `exists()`; pair with the correct directory ([app_directories_and_paths.md](app_directories_and_paths.md)).

## Performance

Async keeps I/O off the UI thread; streaming caps memory at one chunk; isolates keep CPU-heavy parsing from janking. The wins are avoiding OOM (stream), avoiding jank (async + isolate), and avoiding corruption (atomic).

## Advantages / Disadvantages

- **+** Flexible text/binary/streaming I/O, async non-blocking, atomic safety, JSON support.
- **−** Must manage memory (large files), sinks (flush/close), atomicity, exceptions, and isolate offloading yourself.

## Interview Questions

1. **🟢 Why prefer async file APIs over the `Sync` variants?** — Sync I/O blocks the isolate (UI jank/ANR); async runs off-thread and resumes via the event loop.
2. **🟢 How do you read a very large file without OOM?** — Stream it with `openRead()` and process chunk/line by line rather than `readAsBytes`/`readAsString`.
3. **🟡 What is an atomic write and why?** — Write to a temp file then `rename` over the target so an interrupted write can't corrupt the real file.
4. **🟡 How do you efficiently append many log lines?** — Keep an `IOSink` (`openWrite(mode: append)`), write, then flush/close — avoid reopening per line.
5. **🟡 How do you keep heavy parsing from janking the UI?** — Offload CPU-bound work to an isolate (`compute`/`Isolate.run`).
6. **🔴 What exceptions must you handle and when?** — `FileSystemException` for missing files, permission denials, and full disks — with fallbacks.
7. **🔴 What does `readAsBytes` do to memory vs streaming?** — Loads the whole file into memory (risky for large files); streaming holds only one chunk at a time.

## Senior Engineer Tips

- Make important writes atomic by default (a tiny helper) — partial-write corruption is rare but catastrophic and easy to prevent.
- Reach for streaming + isolates the moment files get large; loading a big file whole is the classic OOM/jank bug.
- Wrap file ops in try/catch for `FileSystemException` (disk full/permission) and degrade gracefully rather than crashing.

## Architect Perspective

Reading/writing is where correctness (atomicity, exceptions) and performance (async, streaming, isolates) meet. Encapsulating these in a `FileRepository` (atomic writes, streamed large-file helpers, isolate offloading) gives the app safe, non-blocking file access and keeps the tricky memory/corruption concerns in one tested place — feeding caching, downloads, and export features ([downloads_and_caching.md](downloads_and_caching.md), [file_integration.md](file_integration.md), [02 · isolates](../02%20Advanced%20Dart/isolates_and_concurrency.md)).

## Summary

- `dart:io` `File`: async text/bytes/JSON; stream large files (`openRead`/`openWrite`); offload heavy parse to isolates.
- Write atomically (temp + rename); handle `FileSystemException`; use `IOSink` for appends (flush/close).
- Async + streaming + isolates avoid jank/OOM; atomicity avoids corruption.

## Revision Notes

- Small: `readAsString`/`writeAsString`, `readAsBytes`/`writeAsBytes` (async); JSON via `dart:convert`.
- Large: `openRead()` (Stream<List<int>>) / `openWrite()` (IOSink) chunked; heavy parse → `compute`/isolate.
- Atomic write = temp + `rename`; handle `FileSystemException`; `create(recursive:true)`; flush/close sinks; avoid `...Sync` on UI.

## Practice Questions

1. When must you stream a file instead of reading it whole?
2. How do you prevent file corruption on a crash mid-write?
3. How do you append log lines efficiently?

## Coding Questions

1. Implement atomic JSON save/load helpers.
2. Stream a large file line-by-line counting matches (low memory).
3. Offload a heavy parse to an isolate with `compute`.

## Mini Project

**Safe file I/O helpers (Flutter):** Build a small file utility: atomic JSON `saveIndex`/`loadIndex`, an `IOSink`-based `appendLog`, and a streamed large-file processor that offloads heavy parsing to an isolate — with `FileSystemException` handling. Acceptance: writes are atomic (temp+rename); large file processed with low memory (streamed); heavy parse off the UI thread; appends via a flushed/closed sink; exceptions handled; all async.
