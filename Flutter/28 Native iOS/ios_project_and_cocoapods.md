# iOS Project Structure, CocoaPods & Xcode

> A Flutter app's `ios/` folder is a real Xcode project: the `Runner` app (with `AppDelegate`, `Info.plist`, assets), a **`Podfile`** managing native dependencies via **CocoaPods**, and Xcode **schemes/build configs** for signing, deployment target, and flavors — you configure these to build, sign, and add native libraries.

## Introduction

`flutter create` generates a standard iOS project under `ios/` (opened in Xcode via `Runner.xcworkspace`). This file maps its structure (`Runner`, `AppDelegate`, `Info.plist`, `Assets.xcassets`, `Podfile`), CocoaPods dependency management, and key Xcode config (deployment target, signing, schemes/flavors) — the foundation for Swift code and iOS features.

## Why this concept exists

Flutter compiles to a native iOS app; iOS uses Xcode + CocoaPods for building, dependencies, signing, and capabilities. You must set the deployment target, manage pods (installed by Flutter tooling), configure signing/team, and (optionally) schemes for flavors. Flutter wraps but doesn't replace Xcode/CocoaPods.

## Real-world analogy

The `ios/` project is the **iOS chassis** your Flutter body mounts onto; **CocoaPods** is the **parts supplier** delivering native dependencies; **Xcode schemes/configs** are the **build/trim/certification specs** (deployment target, signing team, flavor). You tune these for the platform and App Store.

## Problem Statement

You must raise the iOS deployment target for a plugin, understand where `AppDelegate`/`Info.plist` live, add a native pod, set the signing team, and add dev/prod schemes. You'll map the project + configure Xcode/CocoaPods.

## Internal Working

```mermaid
flowchart TD
    Root[ios/] --> Workspace[Runner.xcworkspace (open this, not .xcodeproj)]
    Root --> Runner[Runner/: AppDelegate.swift, Info.plist, Assets.xcassets]
    Root --> Podfile[Podfile + Podfile.lock (CocoaPods deps)]
    Root --> Config[Runner.xcodeproj: build settings, deployment target, signing, schemes]
```

- **`Runner.xcworkspace`**: open this in Xcode (CocoaPods requires the workspace, not the `.xcodeproj`).
- **`Runner/`**: `AppDelegate.swift` (hosts the Flutter engine / registers plugins — [swift_plugin_code.md](swift_plugin_code.md)), `Info.plist` (app config, permissions/usage strings — [infoplist_and_permissions.md](infoplist_and_permissions.md)), `Assets.xcassets` (icons/launch), `Base.lproj` (launch storyboard).
- **CocoaPods**: `Podfile` declares native dependencies; `flutter pub get` + build runs `pod install` (creating `Podfile.lock`). Plugins add their pods automatically. Set the **platform version** in the `Podfile` (e.g., `platform :ios, '13.0'`).
- **Xcode build config**: **iOS Deployment Target** (min iOS version — plugins often dictate a floor), **Signing & Capabilities** (team, bundle id, provisioning — [Module 51](../51%20Deployment/README.md)), **build configurations** (Debug/Release/Profile), and **schemes**.
- **Flavors/schemes**: iOS uses **schemes + `xcconfig`/build configs** (and sometimes multiple targets) for dev/prod (distinct bundle ids/config); build with `flutter build ios --flavor prod -t lib/main_prod.dart` (requires matching schemes/configs). More manual than Android flavors.
- **Deployment target**: raise it if a plugin/pod requires a newer minimum iOS.

## Memory Representation

Not applicable; build-time config. Release builds AOT-compile Dart + strip symbols (pair with `--obfuscate`/`--split-debug-info` — [21 · startup_and_app_size](../21%20Performance/startup_and_app_size.md)).

## Compiler Behavior

Xcode (clang/Swift) compiles native code + links pods; Flutter's AOT Dart is embedded. Deployment target/Swift/pod versions must be compatible.

## Runtime Behavior

`AppDelegate` (a `FlutterAppDelegate`) starts the engine and runs your Dart `main`. Schemes select config/bundle id at build.

## Flutter Engine Behavior

`FlutterAppDelegate`/`FlutterViewController` is the iOS **embedder** hosting the engine + registering plugins ([10 · embedder_and_startup](../10%20Flutter%20Architecture/embedder_and_startup.md)).

## Dart VM Behavior

Not applicable.

## Examples

```ruby
# ios/Podfile — set platform version; plugins add their pods automatically
platform :ios, '13.0'   # raise for plugins that require a newer minimum

target 'Runner' do
  use_frameworks!
  # Flutter installs plugin pods here; add custom pods if needed:
  # pod 'SomeNativeSDK', '~> 2.0'
end
```

```swift
// ios/Runner/AppDelegate.swift — hosts the Flutter engine; register channels/plugins here
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self) // registers plugins
    // register custom channels here (see swift_plugin_code.md)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

```text
Build with a flavor/scheme + entrypoint (requires matching Xcode schemes/configs):
  flutter build ios --flavor prod -t lib/main_prod.dart
  flutter build ipa --release   # for App Store (Module 51)
CocoaPods (run automatically by Flutter build, or manually):
  cd ios && pod install
```

## Diagrams

```mermaid
flowchart LR
    Flutter[Flutter (AOT Dart)] --> Embed[embedded in iOS Runner app]
    CocoaPods[CocoaPods] --> Pods[native dependencies (plugins + custom)]
    Xcode[Xcode] --> Build[compile Swift/link pods -> .app/.ipa]
    AppDelegate[FlutterAppDelegate] --> Engine[hosts Flutter engine + plugins]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Opening `.xcodeproj` not `.xcworkspace` | Pods not linked | Open `Runner.xcworkspace` |
| Deployment target too low for a plugin | Build/pod failure | Raise iOS deployment target + Podfile platform |
| Editing pods by hand | Drift/lock conflicts | Let `pod install` manage; commit `Podfile.lock` |
| No signing team/provisioning | Can't run on device/ship | Configure Signing & Capabilities ([Module 51](../51%20Deployment/README.md)) |
| Expecting Android-style flavors | iOS uses schemes/configs | Set up schemes + build configs for dev/prod |
| Skipping Info.plist usage strings | Permission crashes/rejection | Add usage descriptions ([infoplist_and_permissions.md](infoplist_and_permissions.md)) |

## Best Practices

- Open the **`.xcworkspace`**; let Flutter/CocoaPods manage pods; **commit `Podfile.lock`** for reproducible builds.
- Set the **iOS deployment target** (and `Podfile platform`) to satisfy plugins/pods; keep Xcode/Swift/CocoaPods compatible.
- Configure **Signing & Capabilities** (team, bundle id) early; enable capabilities as needed ([ios_integration.md](ios_integration.md)).
- Set up **schemes + build configs** for dev/prod (distinct bundle ids); build with `--flavor` + entrypoint.
- Register channels/plugins in **`AppDelegate`** ([swift_plugin_code.md](swift_plugin_code.md)); add **Info.plist usage strings** for permissions.

## Performance

Release AOT + symbol stripping + app thinning (per-device via App Store) reduce size; correct target/config avoids issues. Build-time only ([21 · startup_and_app_size](../21%20Performance/startup_and_app_size.md)).

## Advantages / Disadvantages

- **+** Full iOS build control (target/deps/signing/capabilities/schemes), standard Xcode/CocoaPods, native dependency support.
- **−** Xcode/CocoaPods/signing complexity, Mac required, flavors more manual than Android, provisioning/capabilities overhead.

## Interview Questions

1. **🟢 Where is the iOS project in a Flutter app, and what do you open?** — In `ios/`; open `Runner.xcworkspace` (not the `.xcodeproj`) so CocoaPods deps are linked.
2. **🟢 What manages native iOS dependencies?** — CocoaPods (`Podfile`/`Podfile.lock`); Flutter runs `pod install`, and plugins add pods automatically.
3. **🟡 What is `AppDelegate`'s role?** — A `FlutterAppDelegate` that hosts the engine and registers plugins/channels (in `didFinishLaunchingWithOptions`).
4. **🟡 What's the iOS deployment target and why raise it?** — The minimum iOS version supported; plugins/pods may require a newer floor.
5. **🟡 How do iOS flavors differ from Android?** — iOS uses schemes + build configs/`xcconfig` (and sometimes targets), which is more manual than Android's `productFlavors`.
6. **🔴 Why must `Podfile.lock` be committed?** — For reproducible builds (pins pod versions across the team/CI).
7. **🔴 What's required to run on a device / ship?** — Signing & Capabilities (team, bundle id, provisioning profile) — [Module 51](../51%20Deployment/README.md).

## Senior Engineer Tips

- Always open the **workspace**, commit `Podfile.lock`, and let Flutter manage pods; hand-editing causes lock/version pain.
- Align iOS deployment target with your plugins; set signing/team early to avoid device/CI blockers.
- Set up dev/prod schemes + configs (matching Firebase/entrypoints) to prevent config bleed — accept it's more manual than Android.

## Architect Perspective

The iOS project/Xcode/CocoaPods layer turns the Flutter app into a shippable iOS artifact: deployment target, dependencies, signing, capabilities, and schemes. Configuring it correctly (versions, signing, flavors, capabilities) is a delivery/compatibility concern underpinning native integration and App Store deployment ([Module 51](../51%20Deployment/README.md)).

## Summary

- `ios/` is an Xcode project: `Runner` (`AppDelegate`/`Info.plist`/assets), `Podfile` (CocoaPods), build configs/schemes; open the `.xcworkspace`.
- Set deployment target/pods, signing/team, schemes for dev/prod; register plugins in `AppDelegate`; add Info.plist usage strings.
- More manual (schemes/signing) than Android; commit `Podfile.lock`.

## Revision Notes

- Open `Runner.xcworkspace`; `Runner/` = `AppDelegate.swift`/`Info.plist`/assets; CocoaPods `Podfile`/`Podfile.lock` (commit it).
- Deployment target (+ `Podfile platform`) per plugins; Signing & Capabilities (team/bundle id); schemes+configs for dev/prod flavors.
- Register channels/plugins in `AppDelegate.didFinishLaunchingWithOptions`; Info.plist usage strings for permissions.
- Release AOT + thinning; more manual than Android.

## Practice Questions

1. Why open `.xcworkspace` and commit `Podfile.lock`?
2. What is `AppDelegate`'s role and where do you register plugins?
3. How do iOS flavors differ from Android's?

## Coding Questions

1. Set the iOS deployment target + Podfile platform and add a custom pod.
2. Register a plugin/channel in `AppDelegate`.
3. Configure a dev/prod scheme + build config (outline).

## Mini Project

**iOS build config (Flutter/Xcode):** Configure the iOS project — set deployment target + Podfile platform, add a native pod, configure signing/team, and set up dev/prod schemes + entrypoints; confirm `AppDelegate` hosts the engine. Build both schemes. Acceptance: workspace opens with pods; target/deps correct; schemes build; signing configured; runs on device.
