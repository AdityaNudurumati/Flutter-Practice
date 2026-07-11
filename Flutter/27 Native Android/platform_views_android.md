# Platform Views (Embedding Native Android Views)

> Platform views embed a **native Android `View`** (Google Maps, WebView, camera preview, ad banners) inside the Flutter widget tree via `AndroidView`/`PlatformViewLink` — powerful but comparatively expensive, so use them only when a Flutter widget can't do the job.

## Introduction

Sometimes you must show a genuine native view (a `MapView`, `WebView`, camera `SurfaceView`, or a third-party SDK view) inside Flutter. Platform views composite a native `View` into the Flutter surface. This file covers how they work on Android (hybrid composition / virtual display), the widget API, a `PlatformViewFactory`, and the performance tradeoffs.

## Why this concept exists

Flutter draws its own UI, so it can't natively render a `WebView`/`MapView`. Platform views bridge that: the native view renders and is composited with Flutter content. It's the mechanism behind plugins like `google_maps_flutter`, `webview_flutter`, and `camera`.

## Real-world analogy

A platform view is a **window cut into your custom-painted wall** through which you see a **real object from the other room** (a native view). It works, but the window/compositing costs more than just painting on your wall — so you add windows only where you truly need to show the real thing.

## Problem Statement

Embed a native Android `WebView` (or a custom native `View`) inside a Flutter screen, register its factory, pass creation params, and understand the perf implications. You'll register a `PlatformViewFactory` and use `AndroidView`.

## Internal Working

```mermaid
flowchart TD
    Dart[AndroidView(viewType, creationParams)] --> Register[PlatformViewFactory registered by viewType]
    Register --> Create[create native View (PlatformView)]
    Create --> Composite[composite native View into Flutter surface]
    Composite --> Modes[Hybrid Composition / Virtual Display / TLHC]
```

- **Dart side**: `AndroidView(viewType: 'my-native-view', creationParams: {...}, creationParamsCodec: StandardMessageCodec())` — or `PlatformViewLink` for finer control/gesture handling. `viewType` matches a registered factory.
- **Native side**: implement a **`PlatformView`** (wraps your `android.view.View`) and a **`PlatformViewFactory`** (creates it with creation params); register it in your plugin via `registerViewFactory(viewType, factory)`.
- **Composition modes** (Android): **Hybrid Composition** (composites native views with Flutter — better correctness/compat, some overhead), **Virtual Display** (renders the view to a texture — older), and newer **Texture Layer Hybrid Composition (TLHC)**. Flutter picks/uses these under the hood; you mostly choose the widget.
- **Cost**: platform views are **heavier** than Flutter widgets (extra compositing, potential texture copies, gesture/keyboard/z-order complexity). Use **sparingly** and only when necessary.
- **Gestures/keyboard**: input must be routed correctly to the native view (the platform-view system handles most; complex cases need `PlatformViewLink`/gesture recognizers).

## Memory Representation

A native `View` + its texture/surface live alongside Flutter's layer tree; compositing/texture buffers cost memory. Dispose the native view when removed (`PlatformView.dispose`).

## Compiler Behavior

Not applicable; factory/view are Kotlin registered at plugin/engine setup.

## Runtime Behavior

The native view renders and composites each frame with Flutter content; heavy native views (maps/webview) add raster/compositing cost. Removing the widget disposes the native view.

## Flutter Engine Behavior

The engine composites the native view into its surface via the platform-view system (hybrid/virtual display/TLHC) — extra work vs pure Flutter layers ([09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md)).

## Dart VM Behavior

Not applicable.

## Examples

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Embed a native Android view by its registered viewType
class NativeWebView extends StatelessWidget {
  final String url;
  const NativeWebView({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'app/native-webview',                 // matches the registered factory
      creationParams: {'url': url},
      creationParamsCodec: const StandardMessageCodec(),
      // gestureRecognizers: {...} // if the native view needs specific gestures
    );
  }
}
```

```kotlin
// Android: PlatformView + Factory, registered by viewType
class NativeWebViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val params = args as? Map<*, *>
    return NativeWebViewImpl(context, params?.get("url") as? String ?: "")
  }
}
class NativeWebViewImpl(context: Context, url: String) : PlatformView {
  private val webView = android.webkit.WebView(context).apply { loadUrl(url) }
  override fun getView(): android.view.View = webView
  override fun dispose() { webView.destroy() } // release native resource
}
// Register in FlutterPlugin.onAttachedToEngine:
// binding.platformViewRegistry.registerViewFactory("app/native-webview", NativeWebViewFactory())
```

## Diagrams

```mermaid
flowchart LR
    NeedNative{need a real native view?}
    NeedNative -- yes (map/webview/camera/SDK) --> PV[AndroidView + PlatformViewFactory]
    NeedNative -- no --> Flutter[use a Flutter widget (cheaper)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Using platform views for things Flutter can do | Unnecessary cost/complexity | Use Flutter widgets; reserve for real native views |
| Not disposing the native view | Leak (WebView/Map/camera) | Implement `PlatformView.dispose` |
| Many/large platform views | Compositing/memory cost, jank | Minimize count/size; avoid in scrolling lists |
| Gesture/keyboard conflicts | Input not reaching native view | Route gestures (`PlatformViewLink`/recognizers) |
| Wrong `viewType` mismatch | View not created | Match Dart `viewType` to registered factory |
| Passing params without a codec | Params not received | Use `creationParamsCodec` on both sides |

## Best Practices

- Use platform views **only when necessary** (maps/webview/camera/native SDK views); prefer Flutter widgets otherwise (cheaper, simpler).
- Implement `PlatformView.dispose` to **release native resources** (destroy WebView, remove observers).
- **Minimize** platform-view count/size; avoid them inside heavy scrolling lists; be mindful of compositing/raster cost.
- Match **`viewType`** and use a **codec** for creation params; route gestures/keyboard correctly.
- Prefer maintained **plugins** (`webview_flutter`, `google_maps_flutter`, `camera`) over hand-rolling platform views.

## Performance

Platform views add compositing/texture overhead vs Flutter layers — heavier and can jank if many/large or in lists. Use sparingly; profile raster/compositing ([21 · jank_and_raster](../21%20Performance/jank_and_raster.md)).

## Advantages / Disadvantages

- **+** Embed real native views (maps/webview/camera/SDKs) inside Flutter; access native rendering.
- **−** More expensive than Flutter widgets (compositing/memory), gesture/keyboard/z-order complexity, per-platform native code, disposal responsibility.

## Interview Questions

1. **🟢 What are platform views for?** — Embedding a native platform `View` (map/webview/camera/SDK) inside the Flutter widget tree.
2. **🟢 How do you embed one on Android?** — `AndroidView(viewType, creationParams, codec)` on the Dart side, backed by a registered `PlatformViewFactory` creating a `PlatformView`.
3. **🟡 Why are platform views more expensive than Flutter widgets?** — They add native-view compositing/texture overhead (hybrid composition/virtual display/TLHC) beyond Flutter's own layers.
4. **🟡 How do you avoid leaking a native view?** — Implement `PlatformView.dispose` to release resources (e.g., `WebView.destroy`).
5. **🟡 When should you NOT use a platform view?** — When a Flutter widget can do it — reserve platform views for genuinely native views.
6. **🔴 What are the Android composition modes?** — Hybrid Composition, Virtual Display, and Texture Layer Hybrid Composition (TLHC) — different tradeoffs in correctness/perf; Flutter selects/uses them.
7. **🔴 What complexities do platform views add?** — Gesture/keyboard routing, z-ordering with Flutter content, disposal, and compositing cost — especially in lists.

## Senior Engineer Tips

- Prefer existing plugins (webview/maps/camera) — they handle the platform-view + gesture/lifecycle complexity for you.
- Keep platform views small, few, and out of fast scroll views; profile compositing/raster when you add them.
- Always dispose native views; leaked WebViews/MapViews are memory-heavy and common.

## Architect Perspective

Platform views are the "embed a real native view" escape hatch — essential for maps/webview/camera/SDKs but costlier than Flutter's own rendering. Architecturally, minimize and encapsulate them (behind widgets/plugins), dispose native resources, and prefer Flutter widgets — reserving platform views for what truly requires native rendering ([09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md), [Module 29](../29%20Device%20Features/README.md)).

## Summary

- Platform views embed native Android `View`s via `AndroidView` + a `PlatformViewFactory`/`PlatformView`.
- Heavier than Flutter widgets (compositing/memory) — use sparingly, dispose native resources, mind gestures/lists.
- Prefer Flutter widgets/maintained plugins; reserve for genuinely native views (map/webview/camera/SDK).

## Revision Notes

- Dart: `AndroidView(viewType, creationParams, creationParamsCodec)`; native: `PlatformView` + `PlatformViewFactory` registered by `viewType`.
- Composition: Hybrid/Virtual Display/TLHC (Flutter-managed); heavier than Flutter layers.
- Dispose native view (`PlatformView.dispose`); minimize count/size; route gestures/keyboard.
- Prefer plugins (webview/maps/camera); use only for real native views.

## Practice Questions

1. When is a platform view justified vs a Flutter widget?
2. Why are platform views more expensive, and where do you avoid them?
3. How do you prevent leaking an embedded native view?

## Coding Questions

1. Embed a native `WebView` via `AndroidView` + a `PlatformViewFactory`.
2. Pass creation params (url) with a codec and read them natively.
3. Implement `dispose` to release the native view.

## Mini Project

**Native view embed (Flutter + Android):** Embed a native Android view (e.g., a simple custom `View` or `WebView`) via `AndroidView` + a registered `PlatformViewFactory`/`PlatformView`, pass creation params with a codec, and dispose it correctly. Keep it single/small and out of a list. Acceptance: native view renders inside Flutter; params passed; disposed (no leak); minimal/encapsulated; runs on device.
