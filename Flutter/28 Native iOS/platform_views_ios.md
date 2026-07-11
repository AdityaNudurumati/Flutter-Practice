# Platform Views (Embedding Native iOS Views — `UiKitView`)

> Platform views embed a native iOS `UIView` (MapKit, WKWebView, AVFoundation camera preview, SDK views) inside the Flutter tree via **`UiKitView`** + a native **`FlutterPlatformViewFactory`** — powerful but heavier than Flutter widgets (compositing overhead), so use them only when a Flutter widget can't do the job.

## Introduction

To show a genuine native iOS view (a `WKWebView`, `MKMapView`, camera preview, or third-party SDK view) inside Flutter, use a platform view. This file covers the iOS mechanism (`UiKitView` + `FlutterPlatformViewFactory`/`FlutterPlatformView`), creation params, and the performance tradeoffs — the iOS mirror of Android platform views ([27 · platform_views_android](../27%20Native%20Android/platform_views_android.md)).

## Why this concept exists

Flutter renders its own UI and can't natively draw a `WKWebView`/`MKMapView`. Platform views composite a native `UIView` into the Flutter surface — the mechanism behind plugins like `webview_flutter`, `google_maps_flutter`, and `camera` on iOS.

## Real-world analogy

A platform view is a **window into the native room** cut through your Flutter-painted wall — you see a real `UIView` through it. The window/compositing costs more than painting the wall, so add them only where you truly need the real native view.

## Problem Statement

Embed a native iOS `WKWebView` (or custom `UIView`) inside a Flutter screen, register its factory, pass creation params, and understand the cost. You'll register a `FlutterPlatformViewFactory` and use `UiKitView`.

## Internal Working

```mermaid
flowchart TD
    Dart[UiKitView(viewType, creationParams)] --> Register[FlutterPlatformViewFactory registered by viewType]
    Register --> Create[create native UIView (FlutterPlatformView)]
    Create --> Composite[composite UIView into Flutter surface]
```

- **Dart side**: `UiKitView(viewType: 'app/native-webview', creationParams: {...}, creationParamsCodec: StandardMessageCodec())` — or `PlatformViewLink` for gesture control. `viewType` matches a registered factory.
- **Native side (Swift)**: implement a **`FlutterPlatformView`** (returns your `UIView`) and a **`FlutterPlatformViewFactory`** (creates it with args); register via `registrar.register(factory, withId: viewType)` in your plugin.
- **Composition**: iOS composites the native `UIView` with Flutter content (hybrid composition); heavier than pure Flutter layers.
- **Cost**: platform views add compositing/texture overhead and gesture/keyboard/z-order complexity — use **sparingly**, avoid in fast-scrolling lists.
- **Gestures/keyboard**: input routing to the native view is mostly handled by the platform-view system; complex cases use `PlatformViewLink`/gesture recognizers.
- **Cleanup**: release native resources (e.g., `WKWebView`) when the view is removed.

## Memory Representation

A native `UIView` + compositing/texture buffers live alongside Flutter's layer tree — memory cost; release the native view when disposed.

## Compiler Behavior

Not applicable; factory/view are Swift, registered at plugin setup.

## Runtime Behavior

The native view renders and composites each frame with Flutter content; heavy native views (maps/webview) add compositing/raster cost; removal disposes the native view.

## Flutter Engine Behavior

The engine composites the native view into its surface (hybrid composition) — extra work vs pure Flutter layers ([09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md)).

## Dart VM Behavior

Not applicable.

## Examples

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Embed a native iOS view by its registered viewType
class NativeWebViewIOS extends StatelessWidget {
  final String url;
  const NativeWebViewIOS({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'app/native-webview',                 // matches the registered factory
      creationParams: {'url': url},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
```

```swift
// iOS: FlutterPlatformView + Factory, registered by viewType
import Flutter
import WebKit

class NativeWebView: NSObject, FlutterPlatformView {
  private let webView: WKWebView
  init(frame: CGRect, viewId: Int64, args: Any?) {
    webView = WKWebView(frame: frame)
    super.init()
    if let params = args as? [String: Any], let url = params["url"] as? String,
       let u = URL(string: url) { webView.load(URLRequest(url: u)) }
  }
  func view() -> UIView { webView }   // return the native UIView
}

class NativeWebViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    NativeWebView(frame: frame, viewId: viewId, args: args)
  }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
}
// Register in the plugin/AppDelegate:
// registrar.register(NativeWebViewFactory(), withId: "app/native-webview")
```

## Diagrams

```mermaid
flowchart LR
    NeedNative{need a real native iOS view?}
    NeedNative -- yes (map/webview/camera/SDK) --> PV[UiKitView + FlutterPlatformViewFactory]
    NeedNative -- no --> Flutter[use a Flutter widget (cheaper)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Platform views for things Flutter can do | Needless cost/complexity | Use Flutter widgets |
| Not releasing the native view | Leak (WKWebView/MapView) | Release on removal |
| Many/large platform views (esp. in lists) | Compositing/memory cost, jank | Minimize count/size; avoid in scroll |
| Gesture/keyboard conflicts | Input not reaching native view | Route gestures (`PlatformViewLink`) |
| `viewType` mismatch | View not created | Match Dart `viewType` to registered factory |
| Params without codec | Params not received | Use `creationParamsCodec` both sides |

## Best Practices

- Use platform views **only when necessary** (map/webview/camera/SDK views); prefer Flutter widgets otherwise.
- **Release native resources** when the view is disposed; keep platform views **few/small** and out of fast lists.
- Match **`viewType`** and use a **codec** for creation params; route gestures/keyboard for complex views.
- Prefer maintained **plugins** (`webview_flutter`, `google_maps_flutter`, `camera`) over hand-rolling; they handle the platform-view/gesture/lifecycle complexity.
- Profile compositing/raster when adding them ([21 · jank_and_raster](../21%20Performance/jank_and_raster.md)).

## Performance

Platform views add native-view compositing overhead vs Flutter layers — heavier, can jank if many/large or in lists. Use sparingly; profile ([21 · jank_and_raster](../21%20Performance/jank_and_raster.md)).

## Advantages / Disadvantages

- **+** Embed real native iOS views (map/webview/camera/SDKs) inside Flutter.
- **−** More expensive than Flutter widgets (compositing/memory), gesture/keyboard/z-order complexity, Swift code, disposal responsibility.

## Interview Questions

1. **🟢 What embeds a native iOS view in Flutter?** — `UiKitView` on the Dart side, backed by a registered `FlutterPlatformViewFactory` creating a `FlutterPlatformView`.
2. **🟢 When should you use a platform view?** — Only for genuinely native views (map/webview/camera/SDK); use Flutter widgets otherwise.
3. **🟡 Why are platform views more expensive than Flutter widgets?** — They add native-view compositing/texture overhead beyond Flutter's own layers (hybrid composition).
4. **🟡 How do you pass creation params?** — Via `creationParams` + `creationParamsCodec` on Dart, read from `args` in the factory/view on Swift.
5. **🟡 How do you avoid leaking the native view?** — Release native resources (e.g., the `WKWebView`) when the platform view is removed.
6. **🔴 What complexities do platform views add?** — Gesture/keyboard routing, z-ordering with Flutter content, compositing cost — especially in scrolling lists.
7. **🔴 iOS vs Android platform views — same idea?** — Yes: `UiKitView`/`FlutterPlatformViewFactory` (iOS) mirrors `AndroidView`/`PlatformViewFactory` (Android); both composite native views at extra cost.

## Senior Engineer Tips

- Prefer existing plugins (webview/maps/camera) — they encapsulate the platform-view + gesture/lifecycle work on both platforms.
- Keep platform views small/few and out of fast scroll views; always release the native view on disposal.
- Profile compositing/raster when embedding; native views are the usual suspects for iOS/Android jank in mixed UIs.

## Architect Perspective

`UiKitView` is the iOS "embed a real native view" escape hatch — essential for maps/webview/camera/SDKs but costlier than Flutter rendering. Minimize and encapsulate (behind widgets/plugins), release resources, and prefer Flutter widgets — mirroring the Android approach for a consistent cross-platform strategy ([27 · platform_views_android](../27%20Native%20Android/platform_views_android.md), [09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md)).

## Summary

- iOS platform views: `UiKitView` + `FlutterPlatformViewFactory`/`FlutterPlatformView` embed a native `UIView`.
- Heavier than Flutter widgets (compositing/memory) — use sparingly, release resources, mind gestures/lists.
- Prefer Flutter widgets/maintained plugins; mirrors Android platform views.

## Revision Notes

- Dart: `UiKitView(viewType, creationParams, creationParamsCodec)`; Swift: `FlutterPlatformView` + `FlutterPlatformViewFactory` registered by `viewType`.
- Hybrid composition; heavier than Flutter layers; release native view on disposal; minimize/avoid in lists.
- Match `viewType`, use codec for params, route gestures; prefer plugins (webview/maps/camera).

## Practice Questions

1. When is a platform view justified vs a Flutter widget?
2. Why are platform views more expensive?
3. How do you prevent leaking an embedded native iOS view?

## Coding Questions

1. Embed a `WKWebView` via `UiKitView` + a `FlutterPlatformViewFactory`.
2. Pass creation params (url) with a codec and read them in Swift.
3. Release the native view on disposal.

## Mini Project

**Native iOS view embed (Flutter + iOS):** Embed a native `UIView` (e.g., `WKWebView` or a simple custom view) via `UiKitView` + a registered `FlutterPlatformViewFactory`/`FlutterPlatformView`, pass creation params with a codec, and release it correctly. Keep it single/small, out of a list. Acceptance: native view renders inside Flutter; params passed; released (no leak); minimal/encapsulated; runs on device/simulator.
