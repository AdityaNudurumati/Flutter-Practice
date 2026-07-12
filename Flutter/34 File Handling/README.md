# 34 · File Handling

## Introduction

This module covers working with the file system in Flutter: **app directories & paths** (`path_provider` — temp vs documents vs support vs cache, and their platform meanings/lifetimes), **reading & writing files** (`dart:io` `File`, text/bytes/JSON, streaming large files off the UI thread), **picking & sharing files** (`file_picker`, `share_plus`, saving picked files into app storage), and **downloading & caching** (streamed downloads, cache directories, eviction/cleanup), tied together in a capstone. It builds on storage concepts ([Module 15](../15%20Local%20Storage/README.md)), networking ([Module 16](../16%20Networking/README.md)), and permissions ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)).

## Why this module exists

Apps constantly touch files — cached images, downloaded PDFs, exported reports, user-picked attachments, offline data. But mobile sandboxing makes *where* you write critical: the OS backs up some directories, clears others without warning, and hides most from the user. Writing to the wrong directory means data lost on cleanup, bloated backups, or files the user can't find. Getting directory choice, large-file streaming, and cleanup right is what separates robust file handling from silent data loss.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_app_directories_and_paths.md](01_app_directories_and_paths.md) | `path_provider`: temp/documents/support/cache dirs, lifetimes, platforms | 🔵 |
| 2 | [02_reading_writing_files.md](02_reading_writing_files.md) | `dart:io` `File`: text/bytes/JSON, streaming, async off-UI-thread | 🔵 |
| 3 | [03_file_picker_and_sharing.md](03_file_picker_and_sharing.md) | `file_picker`, `share_plus`, saving picked files, save dialogs | 🟡 |
| 4 | [04_downloads_and_caching.md](04_downloads_and_caching.md) | Streamed downloads, cache dirs, TTL/eviction, cleanup | 🔴 |
| 5 | [05_file_integration.md](05_file_integration.md) | Capstone: file repository, directory strategy, lifecycle | 🔴 |

> **Cross-references:** Storage overview (prefs/secure/files): [Module 15](../15%20Local%20Storage/README.md). Networking/downloads (`dio`): [Module 16](../16%20Networking/README.md). Camera/gallery files: [29 · camera_and_gallery](../29%20Device%20Features/01_camera_and_gallery.md). Isolates (heavy file work): [02 · isolates](../02%20Advanced%20Dart/04_isolates.md). PDF/Excel generation: [Module 35](../35%20PDF/README.md), [Module 36](../36%20Excel/README.md). Offline caching: [Module 19](../19%20Offline%20First/README.md).

## Prerequisites

[15 Local Storage](../15%20Local%20Storage/README.md), [16 Networking](../16%20Networking/README.md), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (async/isolates), permissions basics ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)).

## What you'll be able to do after this module

- Choose the correct app directory for each file (persistent vs cache vs temp) per platform.
- Read/write text, bytes, and JSON — and stream large files without blocking the UI.
- Let users pick and share files, and save picked files into app storage.
- Download files with progress, cache them, and implement eviction/cleanup.
- Wrap file access behind a repository with a clear directory & lifecycle strategy.

## Capstone

**File slice:** A document manager that downloads PDFs with progress into the cache dir, saves user-picked attachments into the documents dir, reads/writes a JSON index, streams large files off the UI thread, lets the user share files, and evicts stale cache — all behind a `FileRepository` with an explicit directory strategy.

## Summary

File handling = choosing the right sandboxed directory (`path_provider`), reading/writing efficiently (streaming large files off the UI thread), picking/sharing (`file_picker`/`share_plus`), and downloading/caching with cleanup. The core discipline is a deliberate directory & lifecycle strategy behind a repository so nothing is lost, bloated, or blocking.
