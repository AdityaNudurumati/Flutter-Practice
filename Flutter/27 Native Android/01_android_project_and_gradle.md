# Android Project Structure & Gradle

> A Flutter app's `android/` folder is a real Android/Gradle project: `build.gradle` files set SDK versions, dependencies, flavors, and signing; `MainActivity` hosts the Flutter engine; and `AndroidManifest.xml` declares the app — you configure these for versions, flavors, and native dependencies.

## Introduction

`flutter create` generates a standard Android project under `android/`. This file maps its structure (Gradle files, `MainActivity`, manifest, resources), the key Gradle config (min/target/compile SDK, dependencies, flavors, signing), and how it connects to Flutter — the foundation for Kotlin code and platform features.

## Why this concept exists

Flutter compiles to a native Android app; Android's build system (Gradle) governs SDK levels, dependencies, permissions, signing, and build variants. You must configure it for compatibility (SDK versions), native libraries, flavors (dev/prod), and release signing — Flutter tooling wraps but doesn't replace it.

## Real-world analogy

The `android/` project is the **chassis and engine mounts** your Flutter "body" bolts onto: Gradle is the **assembly-line spec** (which parts/versions, which trims/flavors, how it's badged/signed). You tune the spec for the market (SDK levels), options (flavors), and certification (signing).

## Problem Statement

You must raise `minSdkVersion` for a plugin, add dev/prod flavors with different app ids, add a native dependency, and understand where `MainActivity`/manifest live. You'll map the project + edit Gradle.

## Internal Working

```mermaid
flowchart TD
    Root[android/] --> AppGradle[app/build.gradle: SDK/deps/flavors/signing]
    Root --> RootGradle[build.gradle + settings.gradle: plugins/repos]
    Root --> Manifest[app/src/main/AndroidManifest.xml]
    Root --> Kotlin[app/src/main/kotlin/.../MainActivity.kt]
    Root --> Res[res/: icons, styles, strings]
    Root --> Gradlew[gradlew + gradle-wrapper.properties (Gradle version)]
```

- **`android/app/build.gradle`** (module): `compileSdk`, `defaultConfig` (`applicationId`, `minSdk`, `targetSdk`, `versionCode/Name`), `buildTypes` (debug/release + `minifyEnabled`/`shrinkResources` for R8), `signingConfigs`, `flavorDimensions`/`productFlavors`, and `dependencies { }` (native libs).
- **`android/build.gradle` + `settings.gradle`**: top-level plugin/repo config (Android Gradle Plugin, Kotlin, Google/Maven repos); newer Flutter uses the declarative plugins block.
- **`gradle-wrapper.properties`**: pins the **Gradle version** (compatibility matters with AGP/Kotlin).
- **`MainActivity`** (`kotlin/.../MainActivity.kt`): usually `class MainActivity : FlutterActivity()` — hosts the Flutter engine; where you register channels/plugins ([02_kotlin_plugin_code.md](02_kotlin_plugin_code.md)).
- **`AndroidManifest.xml`**: app declaration — package, permissions, activities, intent filters, `application` config ([04_permissions_and_manifest.md](04_permissions_and_manifest.md)).
- **`res/`**: launcher icons, `styles.xml` (theme/splash), `strings.xml`, drawables.
- **Flavors**: define `productFlavors` (e.g., `dev`/`prod`) with distinct `applicationId`/config; build with `flutter build apk --flavor prod` + a matching entrypoint (`main_prod.dart`) — pairs with Firebase dev/prod ([18 · firebase_setup_and_core](../18%20Firebase/01_firebase_setup_and_core.md)).
- **SDK versions**: `minSdk` (lowest supported), `targetSdk` (tested-against), `compileSdk` (build API) — plugins often dictate a floor.

## Memory Representation

Not applicable; build-time config. Release builds enable R8 (shrink/obfuscate) — pairs with `--obfuscate`/`--split-debug-info` ([21 · startup_and_app_size](../21%20Performance/06_startup_and_app_size.md)).

## Compiler Behavior

Gradle + AGP compile Kotlin/resources and package the app; Flutter's AOT Dart is embedded. SDK/AGP/Kotlin/Gradle versions must be compatible.

## Runtime Behavior

`MainActivity` (a `FlutterActivity`) starts the engine and runs your Dart `main`. Flavors select config/app id at build.

## Flutter Engine Behavior

`FlutterActivity` is the Android **embedder** hosting the engine + registering plugins ([10 · embedder_and_startup](../10%20Flutter%20Architecture/05_embedder_and_startup.md)).

## Dart VM Behavior

Not applicable.

## Examples

```gradle
// android/app/build.gradle (Groovy) — key config
android {
    namespace "com.example.app"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.app"
        minSdk 23          // plugins often require a floor (e.g., 21/23)
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
    }

    flavorDimensions "env"
    productFlavors {
        dev  { dimension "env"; applicationIdSuffix ".dev"; versionNameSuffix "-dev" }
        prod { dimension "env" }
    }

    buildTypes {
        release {
            minifyEnabled true       // R8 shrink/obfuscate
            shrinkResources true
            signingConfig signingConfigs.release // configure real signing (Module 51)
        }
    }
    dependencies {
        implementation "androidx.core:core-ktx:1.12.0" // native dependency example
    }
}
```

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
package com.example.app
import io.flutter.embedding.android.FlutterActivity
class MainActivity : FlutterActivity()  // hosts the engine; register channels in configureFlutterEngine
```

```text
Build with a flavor + matching entrypoint:
  flutter build apk --flavor prod -t lib/main_prod.dart
  flutter build appbundle --release   # AAB for Play (Module 51)
```

## Diagrams

```mermaid
flowchart LR
    Flutter[Flutter (AOT Dart)] --> Embed[embedded in Android app]
    Gradle[Gradle/AGP] --> Build[compile Kotlin/res + package APK/AAB]
    MainActivity[FlutterActivity] --> Engine[hosts Flutter engine + plugins]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Wrong/low `minSdk` for a plugin | Build/runtime failure | Raise `minSdk` to the plugin's floor |
| Incompatible Gradle/AGP/Kotlin versions | Build errors | Align versions (wrapper + AGP + Kotlin) |
| Editing manifest for permissions ad hoc | Missing/duplicated | Declare properly ([04_permissions_and_manifest.md](04_permissions_and_manifest.md)) |
| No flavors for dev/prod | Config bleed | `productFlavors` + entrypoints |
| Debug signing for release | Rejected/unsigned | Configure release `signingConfig` ([Module 51](../51%20Deployment/README.md)) |
| Ignoring R8 in release | Larger/less safe | `minifyEnabled`/`shrinkResources` + obfuscation |

## Best Practices

- Set **`minSdk`/`targetSdk`/`compileSdk`** deliberately (respect plugin floors; keep `targetSdk` current for Play).
- Keep **Gradle/AGP/Kotlin versions aligned**; use the wrapper.
- Define **dev/prod flavors** (distinct app ids/config) with matching Dart entrypoints; pair with Firebase envs.
- Configure **release signing + R8** (shrink/obfuscate); combine with `--obfuscate`/`--split-debug-info`.
- Register channels/plugins in **`MainActivity.configureFlutterEngine`** ([02_kotlin_plugin_code.md](02_kotlin_plugin_code.md)); keep manifest/permissions correct.

## Performance

Release R8 shrinking + AAB per-device delivery reduce size; correct SDK/flavor config avoids bloat. Build-time only ([21 · startup_and_app_size](../21%20Performance/06_startup_and_app_size.md)).

## Advantages / Disadvantages

- **+** Full Android build control (versions/deps/flavors/signing), standard Gradle project, native dependency support.
- **−** Gradle/version-compatibility complexity, platform-specific config, signing/flavor setup overhead.

## Interview Questions

1. **🟢 Where is the Android project in a Flutter app?** — In the `android/` folder — a standard Gradle project with `MainActivity`, manifest, and `build.gradle` files.
2. **🟢 What does `app/build.gradle` configure?** — SDK versions (`min/target/compileSdk`), `applicationId`, versioning, `buildTypes`, `signingConfigs`, flavors, and native dependencies.
3. **🟡 What is `MainActivity` and its role?** — A `FlutterActivity` that hosts the Flutter engine and where you register channels/plugins (`configureFlutterEngine`).
4. **🟡 `minSdk` vs `targetSdk` vs `compileSdk`?** — Lowest supported OS, the OS version you've tested/targeted (Play requirements), and the API level you compile against.
5. **🟡 How do you set up dev/prod builds?** — `productFlavors` (distinct app ids/config) + matching Dart entrypoints; build with `--flavor`.
6. **🔴 Why do Gradle/AGP/Kotlin versions matter?** — They must be compatible; mismatches cause build failures — align the wrapper, AGP, and Kotlin versions.
7. **🔴 What release config affects size/security?** — R8 (`minifyEnabled`/`shrinkResources`) + signing + `--obfuscate`/`--split-debug-info`, and AAB per-device delivery.

## Senior Engineer Tips

- Pin and align Gradle/AGP/Kotlin versions; upgrade deliberately — version drift is the top Android build headache.
- Set up flavors + entrypoints early (dev/prod), matching Firebase/config envs, to avoid prod data bleed.
- Keep native changes minimal and documented; most native config lives here, so treat `build.gradle`/manifest as reviewed code.

## Architect Perspective

The Android project/Gradle layer is where the Flutter app becomes a shippable Android artifact: SDK targeting, dependencies, flavors, signing, and R8. Configuring it correctly (versions, flavors, release optimization) is a delivery-and-compatibility concern that underpins native integration, deployment, and app size ([Module 51](../51%20Deployment/README.md), [21 · startup_and_app_size](../21%20Performance/06_startup_and_app_size.md)).

## Summary

- `android/` is a Gradle project: `app/build.gradle` (SDKs/deps/flavors/signing), `MainActivity` (hosts engine), manifest, `res/`.
- Set SDK versions per plugin/Play, align Gradle/AGP/Kotlin, use dev/prod flavors + entrypoints, configure release signing + R8.
- Register channels/plugins in `MainActivity`; foundation for Kotlin/platform features.

## Revision Notes

- `android/app/build.gradle`: `compileSdk`, `defaultConfig(applicationId/minSdk/targetSdk/version)`, `buildTypes(release: R8)`, `signingConfigs`, `productFlavors`, `dependencies`.
- `MainActivity : FlutterActivity` hosts engine + registers channels/plugins; manifest declares app/permissions.
- Align Gradle/AGP/Kotlin; flavors + entrypoints for dev/prod; release signing + obfuscation; AAB.
- Respect plugin `minSdk` floors.

## Practice Questions

1. Where do you set `minSdk` and why might a plugin force it higher?
2. What's `MainActivity`'s role?
3. How do you configure dev/prod flavors?

## Coding Questions

1. Edit `app/build.gradle` to add `dev`/`prod` flavors with distinct app ids.
2. Raise `minSdk` and add a native dependency.
3. Enable R8 + configure a release signing placeholder.

## Mini Project

**Android build config (Flutter/Gradle):** Configure `android/app/build.gradle` with sensible SDK versions, dev/prod flavors (distinct app ids) + matching entrypoints, a native dependency, and release R8 + signing placeholder; confirm `MainActivity` hosts the engine. Build both flavors. Acceptance: flavors build; SDKs/deps correct; release optimized; documented; app runs on device.
