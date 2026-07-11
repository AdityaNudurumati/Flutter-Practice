# App Directories & Paths (`path_provider`)

> You never hardcode paths on mobile — the app is **sandboxed**, so you ask **`path_provider`** for the right directory, and *which* one matters: **documents** (persistent, user data, may be backed up), **application support** (persistent, hidden app data), **cache/temporary** (the **OS can delete these anytime** — never store anything you can't re-fetch there), and **external storage** (Android, shared/large files). Choosing wrong means data lost on cleanup, bloated iCloud/Google backups, or files you can't recover.

## Introduction

Every file operation starts with "where do I put this?" `path_provider` returns platform-correct, sandboxed directories with different **persistence guarantees, backup behavior, and visibility**. This file maps those directories, their lifetimes, and platform differences — the foundation for all file work.

## Why this concept exists

Mobile OSes sandbox each app and manage storage aggressively (clearing caches under pressure, backing up user data, hiding internals). Paths differ per platform and OS version, so `path_provider` abstracts them into semantic directories. Picking the directory by **intent** (persistent user data vs disposable cache) is how you cooperate with the OS instead of fighting it.

## Real-world analogy

The directories are different **storage rooms**: **documents** is your **filing cabinet** (kept, sometimes copied to off-site backup), **application support** is a **locked back office** (kept, staff-only), **cache/temp** is a **recycling bin the janitor empties whenever** (don't leave anything important), and **external storage** is a **shared warehouse** for bulky/shareable goods. Putting your tax records in the recycling bin (cache) means they're gone next cleanup.

## Problem Statement

Decide where to store: a user's saved documents, an app config/index, downloaded images that can be re-fetched, and a large exported file to share — on both platforms, respecting backup and cleanup. You'll call the right `path_provider` API per case.

## Internal Working

```mermaid
flowchart TD
    Need{what kind of file?}
    Need -->|persistent user data| Docs[getApplicationDocumentsDirectory (backed up)]
    Need -->|persistent hidden app data| Support[getApplicationSupportDirectory]
    Need -->|re-fetchable cache| Cache[getApplicationCacheDirectory / temp (OS may clear)]
    Need -->|scratch/short-lived| Temp[getTemporaryDirectory (OS may clear)]
    Need -->|large/shared (Android)| Ext[getExternalStorageDirectory / external cache]
```

- **Documents** (`getApplicationDocumentsDirectory`): **persistent** user-generated/important data. On **iOS** it maps to the app's Documents (often **included in iCloud/iTunes backup**) — don't dump large re-downloadable blobs here (bloats backups); mark large caches as excluded if you must. On Android, app-private files dir.
- **Application support** (`getApplicationSupportDirectory`): **persistent** app data **not** meant to be user-visible (config, databases). Preferred over Documents for internal files on iOS.
- **Cache** (`getApplicationCacheDirectory`) / **temporary** (`getTemporaryDirectory`): **the OS may delete these at any time** (low storage, cleanup). Use for **re-fetchable** downloads, thumbnails, scratch — **never** the sole copy of anything important. Temp is the shortest-lived.
- **External storage** (Android only: `getExternalStorageDirectory`, `getExternalCacheDirectories`): larger/shared storage. Scoped storage (Android 10+) limits access; for user-visible files prefer the system pickers/`MediaStore` ([file_picker_and_sharing.md](file_picker_and_sharing.md)). iOS has no direct equivalent.
- **Rule of thumb**: **persistent user data → documents/support; disposable → cache/temp.** Always build paths with `path.join(dir.path, name)` (via the `path` package), never string concatenation.
- **Async**: all these return `Future<Directory>` — cache the resolved dir; don't call repeatedly.

## Memory Representation

Directories are just paths (strings). The persistence/backup/cleanup semantics are OS policy, not in-memory state. Cache the resolved `Directory` to avoid repeated async lookups.

## Compiler Behavior

Not applicable; resolved at runtime per platform.

## Runtime Behavior

Cache/temp contents can vanish between launches (OS cleanup). Documents/support persist across launches/updates (until uninstall). Backup restores may repopulate documents on a new device.

## Flutter Engine Behavior

Not applicable; `path_provider` bridges to native directory APIs via platform channels ([26](../26%20Platform%20Channels/README.md)).

## Dart VM Behavior

Not applicable.

## Examples

```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AppPaths {
  // Persistent user documents (careful: iOS backs these up)
  Future<File> documentFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, name));                 // always use path.join
  }

  // Persistent, hidden app data (config/db) — preferred for internal files
  Future<File> supportFile(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, name));
  }

  // Re-fetchable cache — OS may delete anytime; never the only copy
  Future<File> cacheFile(String name) async {
    final dir = await getTemporaryDirectory();           // or getApplicationCacheDirectory
    return File(p.join(dir.path, name));
  }
}
```

```text
Directory decision cheat-sheet:
  user-saved document / important export -> documents (persistent, backed up)
  app config / sqlite db / internal index -> application support (persistent, hidden)
  downloaded image/pdf you can re-fetch   -> cache/temporary (OS may clear)  <-- NOT the only copy
  scratch during an operation             -> temporary
  large shared file (Android)             -> external storage / system picker
```

## Diagrams

```mermaid
flowchart LR
    Persistent[persistent?] -->|yes, user-facing| Docs[documents]
    Persistent -->|yes, internal| Support[app support]
    Persistent -->|no, re-fetchable| Cache[cache/temp (OS-cleared)]
```

## Common Mistakes

| Mistake | Why it's bad | Fix |
|---------|-------------|-----|
| Storing important data in cache/temp | OS deletes it anytime | Use documents/support for persistent data |
| Large re-downloadable blobs in documents (iOS) | Bloats iCloud backup | Use cache, or exclude from backup |
| Hardcoding paths | Sandbox/platform differences | Use `path_provider` + `path.join` |
| String-concatenating paths | Separator/edge bugs | `p.join(dir.path, name)` |
| Repeated async dir lookups | Wasteful | Cache the resolved directory |
| Assuming external storage on iOS | iOS has none | Guard Android-only APIs |
| Expecting cache to persist | It won't | Design for re-fetch |

## Best Practices

- Choose the directory by **intent**: **documents** (persistent user data), **application support** (persistent internal), **cache/temporary** (re-fetchable, OS may clear).
- Never store the **only copy** of important data in cache/temp; avoid **large re-downloadable blobs in iOS documents** (backup bloat) — cache or exclude from backup.
- Build paths with **`path.join`**; **cache** resolved directories; guard **Android-only** external-storage APIs.
- For user-visible/shared files, prefer **system pickers/share** over raw external paths (scoped storage) ([file_picker_and_sharing.md](file_picker_and_sharing.md)).

## Performance

Directory resolution is a cheap async call — cache it. The real cost is misplacement (re-downloading cleared "persistent" data, or bloated backups); correct directory choice is a performance/UX decision.

## Advantages / Disadvantages

- **+** Correct sandboxed, platform-safe paths with clear persistence/backup/cleanup semantics.
- **−** Must understand each directory's lifetime, platform differences (external storage, iOS backup), scoped-storage limits.

## Interview Questions

1. **🟢 Why use `path_provider` instead of hardcoding paths?** — Apps are sandboxed and paths differ per platform/version; `path_provider` returns semantic, platform-correct directories.
2. **🟢 Which directory for re-fetchable downloads vs important user data?** — Cache/temporary for re-fetchable (OS may clear); documents/support for persistent important data.
3. **🟡 What's special about the temporary/cache directory?** — The OS can delete its contents anytime (storage pressure/cleanup) — never store the only copy of anything there.
4. **🟡 Why avoid large blobs in the iOS documents directory?** — It's typically backed up to iCloud, so large re-downloadable files bloat backups — use cache or exclude from backup.
5. **🟡 documents vs application support?** — Both persistent; documents is user-facing (backed up), application support is hidden internal data (preferred for db/config on iOS).
6. **🔴 How does Android scoped storage affect file handling?** — Direct external-storage access is restricted (Android 10+); use app-private dirs or system pickers/`MediaStore` for user-visible files.
7. **🔴 Why build paths with `path.join`?** — To handle separators/platform differences correctly and avoid concatenation bugs.

## Senior Engineer Tips

- Decide the directory strategy per file type up front and document it; "why did my data disappear" is almost always cache-vs-documents confusion.
- On iOS, keep big caches out of Documents (or set the do-not-backup flag) — backup bloat is a real user complaint and review concern.
- Cache resolved directories in your file repository and never concatenate paths by hand.

## Architect Perspective

Directory choice is a data-lifecycle policy decision, not a detail. Encoding it once in a `FileRepository`/`AppPaths` (persistent vs cache vs temp per file type, platform-guarded, backup-aware) prevents an entire class of bugs — vanished data, bloated backups, scoped-storage failures — and gives the rest of the app intent-based file access ([file_integration.md](file_integration.md), [Module 15](../15%20Local%20Storage/README.md)).

## Summary

- `path_provider` gives sandboxed, platform-correct directories: documents (persistent, user, backed up), application support (persistent, internal), cache/temporary (re-fetchable, OS may clear), external (Android).
- Choose by intent; never keep the only copy in cache/temp; avoid large blobs in iOS documents; use `path.join`.
- Cache resolved dirs; guard Android-only APIs; use system pickers for shared files.

## Revision Notes

- `getApplicationDocumentsDirectory` (persistent, user, iOS-backed-up), `getApplicationSupportDirectory` (persistent, hidden), `getTemporaryDirectory`/`getApplicationCacheDirectory` (OS may clear), `getExternalStorageDirectory` (Android).
- Persistent → documents/support; disposable/re-fetchable → cache/temp; large iOS blobs → cache/exclude from backup.
- Build with `path.join`; cache resolved dirs; scoped storage (Android 10+) → system pickers for user files.

## Practice Questions

1. Where do you store data the OS must never delete vs data it may?
2. Why avoid large downloads in the iOS documents directory?
3. Why use `path.join` instead of string concatenation?

## Coding Questions

1. Build an `AppPaths` helper returning documents/support/cache file handles.
2. Decide + justify the directory for five different file types.
3. Guard an Android-only external-storage path.

## Mini Project

**Directory strategy (Flutter):** Build an `AppPaths` helper exposing `documentFile`, `supportFile`, and `cacheFile` (via `path_provider` + `path.join`, cached dirs), and write a short doc mapping five file types (user doc, app config, re-fetchable download, scratch, large export) to directories with justification (persistence/backup/cleanup). Acceptance: correct APIs per intent; paths via `path.join`; dirs cached; iOS-backup + cache-clearing considerations documented; Android-only APIs guarded.
