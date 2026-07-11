# Camera & Gallery (Capture and Pick Media)

> Capture photos/video with the **`camera`** plugin (live preview via a `CameraController`) or, for the common "just get an image" case, pick/capture with **`image_picker`** (launches the system UI) — both require permissions ([Android](../27%20Native%20Android/permissions_and_manifest.md)/[iOS](../28%20Native%20iOS/infoplist_and_permissions.md)), return files you must manage, and belong behind a repository.

## Introduction

Two levels of camera access: `image_picker` (simplest — hand off to the OS camera/gallery UI, get a file back) and `camera` (full control — live preview, resolution, flash, custom capture UI). This file covers when to use each, the controller lifecycle, permissions, and file handling.

## Why this concept exists

Apps constantly attach images (avatars, receipts, KYC, posts). Flutter can't access the camera sensor directly, so plugins bridge to the native camera/gallery via platform channels ([Module 26](../26%20Platform%20Channels/README.md)). `image_picker` covers 90% of cases cheaply; `camera` handles custom capture experiences (scanners, filters).

## Real-world analogy

`image_picker` is **ordering a photo from a photo booth** — you press a button, the booth handles everything, you get a print. `camera` is **operating your own studio camera** — you control the lens, preview, and shutter, and you're responsible for setting up and tearing down the equipment (the `CameraController`).

## Problem Statement

Let the user attach a profile photo — either pick from the gallery or take a new one — and (for a document scanner) show a live preview with a custom capture button. You'll use `image_picker` for the simple case and `camera` for the custom one, behind a repository, with permissions handled.

## Internal Working

```mermaid
flowchart TD
    Simple[image_picker] --> OSUI[launches system camera/gallery UI] --> File1[returns XFile]
    Custom[camera] --> Ctrl[CameraController.initialize] --> Preview[CameraPreview widget]
    Preview --> Capture[takePicture] --> File2[returns XFile]
    Ctrl --> Dispose[dispose() on teardown]
```

- **`image_picker`**: `pickImage(source: ImageSource.camera | .gallery)` / `pickVideo` returns an `XFile` (or null if cancelled). No preview/controller — the OS handles the UI. Best default for attach-a-photo.
- **`camera`**: `availableCameras()` → construct a `CameraController(camera, ResolutionPreset)` → `await controller.initialize()` → show `CameraPreview(controller)` → `controller.takePicture()`/`startVideoRecording()`. You **must `dispose()`** the controller and handle app lifecycle (release on pause, reinit on resume — [08 · lifecycle](../08%20Widget%20Lifecycle/app_lifecycle_state.md)).
- **Permissions**: camera needs runtime permission + usage strings; gallery/photos too on iOS. Handle denied/restricted → Settings ([28 · infoplist_and_permissions](../28%20Native%20iOS/infoplist_and_permissions.md)).
- **Files**: returned `XFile` points to a temp/cache path — copy to app storage if you need to keep it ([Module 34](../34%20File%20Handling/README.md)); compress large images before upload.
- **Repository**: expose `Future<File?> pickAvatar()` / `captureDocument()`; the UI never touches the plugin directly (testable, swappable).

## Memory Representation

Camera preview holds native buffers + a texture; full-resolution images are large in memory — compress/resize. The `CameraController` owns native resources until disposed.

## Compiler Behavior

Not applicable; plugin bridges to native at runtime.

## Runtime Behavior

`image_picker` suspends your app while the OS UI runs, then resumes with the file. `camera` streams preview frames continuously (battery/heat) — release when not visible.

## Flutter Engine Behavior

`CameraPreview` uses a texture/platform view composited into the Flutter surface ([28 · platform_views_ios](../28%20Native%20iOS/platform_views_ios.md)); preview is engine-composited each frame.

## Dart VM Behavior

Not applicable; capture/encoding happen natively, results marshalled over channels.

## Examples

```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Simple, most common case: pick or capture a single image
class MediaRepository {
  final _picker = ImagePicker();

  Future<File?> pickImage({required bool fromCamera}) async {
    final XFile? x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,          // downscale to keep memory/upload small
      imageQuality: 85,        // compress
    );
    return x == null ? null : File(x.path); // null = user cancelled
  }
}
```

```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Full control: live preview + custom capture (e.g., a document scanner)
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    final c = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
    await c.initialize();
    if (mounted) setState(() => _controller = c);
  }

  @override
  void dispose() {
    _controller?.dispose();           // MUST release native resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(children: [
      CameraPreview(c),
      Align(
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(
          onPressed: () async {
            final XFile shot = await c.takePicture();
            // hand shot.path to the repository / next screen
          },
          child: const Icon(Icons.camera),
        ),
      ),
    ]);
  }
}
```

## Diagrams

```mermaid
flowchart LR
    Need{need custom preview/capture UI?}
    Need -- no (attach a photo) --> IP[image_picker (simplest)]
    Need -- yes (scanner/filter) --> CAM[camera + CameraController]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Not disposing `CameraController` | Native leak, camera stays busy | `dispose()` in State; release on pause |
| Ignoring app lifecycle | Preview breaks on resume | Reinit on resume, release on pause |
| Not handling cancellation | Null crash | `XFile?` can be null (user cancelled) |
| Keeping full-res images in memory | OOM / jank | `maxWidth`/`imageQuality`, resize/compress |
| Using `camera` for a simple pick | Needless complexity | Use `image_picker` |
| Assuming the temp file persists | File lost/cleared | Copy to app storage if keeping ([Module 34](../34%20File%20Handling/README.md)) |
| Skipping permissions/usage strings | Crash/denied | Handle permissions + usage strings |

## Best Practices

- Default to **`image_picker`**; use **`camera`** only for custom preview/capture; always **`dispose()`** the controller and handle **lifecycle** (release on pause).
- **Compress/resize** (`maxWidth`, `imageQuality`) before keeping/uploading; copy temp files to app storage if persisting ([Module 34](../34%20File%20Handling/README.md)).
- Handle **permissions** + denied/restricted (Settings fallback) and **cancellation** (nullable result); degrade gracefully.
- Wrap in a **repository** (`pickAvatar`/`captureDocument`) so UI/tests don't touch the plugin.

## Performance

Live preview streams frames (battery/heat) — release when off-screen. Full-res images are memory-heavy; downscale. `image_picker` is cheap (OS handles capture).

## Advantages / Disadvantages

- **+** Rich media capture/selection with little code; `camera` gives full control; cross-platform.
- **−** Permissions/lifecycle/disposal responsibility, native resource + memory cost, temp-file management, custom capture complexity.

## Interview Questions

1. **🟢 When use `image_picker` vs `camera`?** — `image_picker` for the common attach-a-photo (OS handles UI); `camera` when you need a live preview/custom capture (scanner/filter).
2. **🟢 What does `pickImage` return and what if the user cancels?** — An `XFile?`; it's `null` on cancellation, so handle that.
3. **🟡 Why must you dispose the `CameraController`?** — It holds native camera resources/texture; not disposing leaks and keeps the camera busy.
4. **🟡 How do you handle app lifecycle with the camera?** — Release the controller on pause and reinitialize on resume ([08 · lifecycle](../08%20Widget%20Lifecycle/app_lifecycle_state.md)).
5. **🟡 How do you avoid OOM with large images?** — Downscale/compress (`maxWidth`, `imageQuality`) and don't hold full-res in memory.
6. **🔴 Where do captured files live and how do you persist them?** — In temp/cache; copy to app storage ([Module 34](../34%20File%20Handling/README.md)) if you need to keep them.
7. **🔴 How does `CameraPreview` render in Flutter?** — Via a texture/platform view composited into the Flutter surface by the engine.

## Senior Engineer Tips

- Reach for `image_picker` first — most "camera" tickets are really "attach an image."
- Treat the `CameraController` like a native resource: dispose it, and wire `WidgetsBindingObserver` to release/reinit across lifecycle.
- Compress at capture time; shipping full-res images silently bloats uploads and memory.

## Architect Perspective

Camera/gallery is a device-capability + permission + file-lifecycle concern. Wrapping it behind a repository (returning domain files/paths), compressing early, and handling permissions/lifecycle keeps the feature testable, battery-friendly, and swappable — integrating with file handling, uploads, and offline queues ([Module 34](../34%20File%20Handling/README.md), [Module 19](../19%20Offline%20First/README.md)).

## Summary

- `image_picker` = simple pick/capture (OS UI, `XFile?`); `camera` = full control (controller + preview + `takePicture`, must dispose).
- Handle permissions, lifecycle, cancellation; compress/resize; persist temp files if needed.
- Wrap behind a repository; degrade gracefully.

## Revision Notes

- `image_picker`: `pickImage(source, maxWidth, imageQuality)` → `XFile?` (null = cancelled). Default choice.
- `camera`: `availableCameras()` → `CameraController(...).initialize()` → `CameraPreview` → `takePicture()`; **dispose** + lifecycle.
- Permissions + usage strings; temp files → copy to persist; compress before upload; repository wrapper.

## Practice Questions

1. When would you choose `camera` over `image_picker`?
2. What resources does a `CameraController` hold and how do you release them?
3. How do you keep captured images from bloating memory/uploads?

## Coding Questions

1. Implement `MediaRepository.pickImage(fromCamera)` returning a compressed `File?`.
2. Build a camera preview screen with capture that disposes correctly.
3. Handle lifecycle: release the controller on pause, reinit on resume.

## Mini Project

**Photo attach feature (Flutter):** Build a `MediaRepository` that picks from gallery or captures via `image_picker` (compressed), plus an optional custom-capture screen using `camera` (preview + capture, proper disposal + lifecycle). Handle permissions/cancellation and copy kept files to app storage. Acceptance: pick + capture both work; images compressed; controller disposed + lifecycle-safe; cancellation handled; feature behind a repository; runs on device.
