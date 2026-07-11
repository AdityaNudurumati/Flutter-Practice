# Desktop Fundamentals

> Flutter Desktop compiles your app to a **native executable** for **Windows, macOS, and Linux** — each with a **platform-specific embedder + runner** (Win32/C++, Cocoa/Swift, GTK/C++) hosting the same Flutter engine + your AOT-compiled Dart, rendered via **native Skia/Impeller** (real desktop rendering, not a browser canvas like web). You **must build each platform on its own OS** (Windows for `.exe`, Mac for `.app`, Linux for the binary). Unlike mobile/web, desktop apps get **full OS access** (real filesystem, native libs via FFI, multiple windows) — and desktop **fits** tools/productivity/creative/companion apps, less so where a web app or a truly OS-native app is clearly better.

## Introduction

This file establishes the desktop landscape: the three targets, how each builds (embedder/runner + engine), the difference from web/mobile, and **when desktop is the right choice** — the frame for the UX, native-integration, and packaging files.

## Why this concept exists

Desktop is a first-class Flutter target, but it's **three OSes** with different embedders, build hosts, UX conventions, and distribution — and it differs from mobile (windows/menus/keyboard, full OS access) and web (native rendering, no browser sandbox). Understanding the targets + fit prevents treating desktop like "mobile in a big window" or reaching for it when web/native suits better.

## Real-world analogy

Flutter Desktop is like **manufacturing your product in three regional factories** (Windows/macOS/Linux): the **product design is shared** (your Dart app), but each factory has its **own assembly line + local fittings** (embedder/runner) and you must **run production in each region** (build on each OS). Unlike a mall kiosk (mobile app store) or a web pop-up (browser), a desktop app is a **standalone appliance in the user's home** — it can plug into everything (full OS access) but you distribute + service it yourself per region.

## Internal Working

```mermaid
flowchart TD
    Dart[your Dart app (AOT-compiled)] --> Engine[Flutter engine (native Skia/Impeller)]
    Engine --> Embed{platform embedder + runner}
    Embed -->|Windows| Win[Win32 / C++ runner -> .exe]
    Embed -->|macOS| Mac[Cocoa / Swift runner -> .app]
    Embed -->|Linux| Lin[GTK / C++ runner -> binary]
    Win & Mac & Lin --> Native[native window + full OS access (filesystem, FFI, multi-window)]
    Note[build each platform on its own OS; native rendering (not a browser canvas)]
```

- **Three targets + embedders**: Flutter Desktop supports **Windows** (Win32, C++ runner → `.exe`), **macOS** (Cocoa, Swift/Obj-C runner → `.app`), and **Linux** (GTK, C++ runner → native binary). Each has a **platform runner** (in `windows/`, `macos/`, `linux/`) that hosts the **Flutter engine** + your **AOT-compiled Dart**. Enable with `flutter config --enable-<platform>-desktop`; build with `flutter build windows/macos/linux`.
- **Native rendering (unlike web)**: desktop renders via the **real Flutter engine** (Skia/**Impeller**) to a native window — **not a browser canvas** ([Module 53](../53%20Flutter%20Web/README.md)). High fidelity/performance like mobile; no download-size/SEO issues.
- **Build-on-target rule**: you can only build a platform on **that OS** — **Windows for `.exe`, macOS for `.app`, Linux for the binary** (like iOS needing a Mac). CI needs **per-OS runners** ([packaging_and_distribution.md](packaging_and_distribution.md)/[Module 50](../50%20CI%20CD/README.md)).
- **Full OS access (unlike mobile/web)**: desktop apps run **outside a sandbox** (or a looser one — macOS App Store apps are sandboxed) with **full filesystem access** (real paths, not scoped), **native library access via FFI** ([native_integration_desktop.md](native_integration_desktop.md)), **multiple windows**, system tray, native menus, and OS APIs. Far more capable than a mobile sandbox or browser.
- **What differs from mobile** (design accordingly — [desktop_ux_and_windowing.md](desktop_ux_and_windowing.md)): **resizable windows** (responsive layout, not fixed phone screen), **menu bars**, **keyboard-first** workflows/shortcuts, **mouse + right-click**, **multi-window**, larger screens/denser UIs, and no touch-first assumptions.
- **When desktop fits (the decision)**:
  - **Great fit**: **cross-platform productivity/creative tools** (editors, IDEs-like tools, design/media apps), **internal/enterprise tools**, **companion desktop apps** to a mobile product, apps needing **full OS/hardware access + performance** on desktop — where one codebase across 3 OSes is a big win.
  - **Consider alternatives**: if it's **web-deliverable** (no install, SEO/reach) → **web** or **PWA** may fit better; if it needs **deep OS-native look/feel or platform-specific APIs** beyond Flutter's reach → a **native** app (WinUI/SwiftUI/GTK) or Electron-style might suit. Flutter Desktop shines for **shared, custom-UI, cross-platform** apps, not for perfectly OS-native chrome.
  - **Trade-off**: **massive code reuse + consistent custom UI across 3 OSes** vs **not pixel-native to each OS's HIG** + **per-platform packaging/signing/distribution overhead**.
- **Maturity note**: desktop is stable/production-capable, but the **plugin ecosystem** is thinner than mobile — some plugins lack desktop support (check, or use FFI/channels). Factor this in.

## Memory Representation

Not app state — a **native executable per platform** (runner + engine + AOT Dart + assets) plus platform runner projects (`windows/`/`macos/`/`linux/`). At runtime it's a native process with a native window + full OS resources.

## Compiler Behavior

`flutter build <platform>` AOT-compiles Dart + builds the native runner (MSVC/Xcode/GCC-clang) into a platform executable/bundle; you must build on the matching OS. Release is AOT (fast, no VM).

## Runtime Behavior

Runs as a **native desktop process** with a native window; full OS access (filesystem/FFI/multi-window); native rendering (Skia/Impeller) at desktop refresh rates. No sandbox restrictions (except macOS App Store sandbox).

## Flutter Engine Behavior

The **real engine** renders to a native window via the platform embedder (Win32/Cocoa/GTK) — same widget/render trees as mobile ([Module 09](../09%20Rendering%20Pipeline/README.md)); Impeller/Skia backend, not a browser canvas.

## Dart VM Behavior

AOT-compiled (like mobile release) — full **isolates** available (unlike web's limited workers), full `dart:io`/filesystem, FFI to native code.

## Examples

```text
Enable + build (on the matching OS):
  flutter config --enable-windows-desktop   # then: flutter build windows  -> .exe  (on Windows)
  flutter config --enable-macos-desktop     # then: flutter build macos    -> .app  (on macOS)
  flutter config --enable-linux-desktop     # then: flutter build linux    -> binary (on Linux)
  # runners live in windows/ macos/ linux/ ; build each on its own OS (CI needs per-OS runners)
```

```text
When Flutter Desktop FITS:
  cross-platform tools/productivity/creative apps, internal/enterprise tools, companion desktop apps,
  apps needing full OS/hardware access + performance, custom shared UI across 3 OSes
When to consider alternatives:
  web-deliverable/no-install/SEO  -> Flutter Web / PWA
  deep OS-native chrome/APIs       -> native (WinUI/SwiftUI/GTK)
  Trade-off: huge code reuse + consistent custom UI  vs  not pixel-native to each HIG + per-platform packaging/signing
```

## Diagrams

```mermaid
flowchart LR
    Goal{use case}
    Goal -->|cross-platform tool/productivity/companion| Desktop[Flutter Desktop (great fit)]
    Goal -->|web-deliverable/SEO| Web[Flutter Web/PWA]
    Goal -->|deep OS-native| Native[native (WinUI/SwiftUI/GTK)]
    Desktop --> Targets[Windows(.exe) + macOS(.app) + Linux(binary), build per OS]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Treating desktop like "mobile in a window" | Ignores desktop UX (menus/keyboard/resize) | Design desktop-idiomatic UX (Module 2 of this) |
| Trying to build all platforms on one OS | You must build on each target OS | Per-OS build hosts / CI runners |
| Assuming all plugins support desktop | Thinner ecosystem | Check support; FFI/channels for gaps |
| Using Flutter Desktop for a web-deliverable app | Install overhead vs web reach | Consider Flutter Web/PWA |
| Expecting pixel-native OS chrome | Flutter draws its own UI | Fits custom-UI apps; adapt conventions |
| Ignoring per-platform packaging/signing | No single store flow | Plan MSIX/DMG/AppImage + signing (Module 4) |
| Fixed phone-size layout | Breaks on resizable windows | Responsive layout (Module 24/25) |

## Best Practices

- **Choose desktop by use case**: great for **cross-platform tools/productivity/creative/companion** apps with shared custom UI; consider **web/PWA** for web-deliverable, **native** for deep OS-native needs.
- Remember desktop is **native-rendered** (fidelity/performance, no web download/SEO issues) but must be **built on each target OS** (per-OS runners/CI); check **plugin desktop support** (use **FFI/channels** for gaps).
- Design **desktop-idiomatic UX** (resizable windows, menus, keyboard/mouse — [desktop_ux_and_windowing.md](desktop_ux_and_windowing.md)) and leverage **full OS access** (filesystem/FFI/multi-window), not a stretched phone UI.
- Plan **per-platform packaging + signing + distribution** early (no single store — [packaging_and_distribution.md](packaging_and_distribution.md)); accept the **reuse-vs-per-OS-overhead** trade-off deliberately.

## Performance

Native rendering (Skia/Impeller) + AOT + full isolates give **strong desktop performance** (no web download/SEO limits, no mobile sandbox). The concerns are the usual Flutter perf (scoped rebuilds, virtualization — [Module 21](../21%20Performance/README.md)) plus desktop-scale UIs (large windows/lists). Startup is native-fast.

## Advantages / Disadvantages

- **+** One codebase → native Windows/macOS/Linux; native rendering/perf; full OS access (filesystem/FFI/multi-window); consistent custom UI; great for tools/productivity.
- **−** Build-per-OS, thinner plugin ecosystem, not pixel-native to each HIG, per-platform packaging/signing/distribution (no single store), desktop-UX work needed.

## Interview Questions

1. **🟢 What platforms does Flutter Desktop target, and how does each build?** — Windows (Win32/C++ → `.exe`), macOS (Cocoa/Swift → `.app`), Linux (GTK/C++ → binary); each has a platform runner hosting the engine + AOT Dart, and you build on the matching OS.
2. **🟢 How does desktop rendering differ from web?** — Desktop uses the real Flutter engine (Skia/Impeller) to a native window (high fidelity/perf, no download/SEO); web paints to a browser canvas with a large download.
3. **🟡 What full-OS capabilities does desktop gain over mobile/web?** — Real filesystem access (not scoped), native libraries via FFI, multiple windows, system tray, native menus, full isolates — outside the mobile/browser sandbox.
4. **🟡 When is Flutter Desktop the right choice — and when not?** — Right for cross-platform tools/productivity/creative/companion apps with shared custom UI; consider web/PWA for web-deliverable, native for deep OS-native chrome/APIs.
5. **🟡 Why must you build each platform on its own OS?** — Each uses the platform's native toolchain (MSVC/Xcode/GCC) — like iOS needing a Mac; CI needs per-OS runners.
6. **🔴 What's the plugin-ecosystem caveat?** — It's thinner than mobile; some plugins lack desktop support — check, and fill gaps with FFI/platform channels.
7. **🔴 What's the core trade-off of Flutter Desktop?** — Huge code reuse + consistent custom UI across 3 OSes vs not being pixel-native to each HIG + per-platform packaging/signing/distribution overhead.

## Senior Engineer Tips

- Decide desktop vs web/native by the use case (shared custom-UI tool vs web reach vs deep OS-native), not by "we have Flutter"; the wrong target ships an install-heavy app where web fit, or a non-native-feeling one where users expected native.
- Set up per-OS CI build hosts and check plugin desktop support early; "we'll build all three on one machine" and "this plugin has no desktop impl" are the two first surprises.
- Design for resizable windows + desktop UX from the start, and plan per-platform packaging/signing — retrofitting menus/keyboard and figuring out MSIX/DMG/AppImage at the end is painful.

## Architect Perspective

Flutter Desktop extends the single-codebase promise to native Windows/macOS/Linux with full OS access and native rendering — a strong fit for cross-platform tools/productivity/companion apps. The architect's job is the **fit decision** (desktop vs web/native), designing for **desktop UX + full OS integration**, and planning the **fragmented per-platform build/package/sign/distribute** reality (no single store). Get those right and desktop is a big reuse win; treat it as "mobile in a window" or ignore packaging and it disappoints ([desktop_ux_and_windowing.md](desktop_ux_and_windowing.md), [packaging_and_distribution.md](packaging_and_distribution.md), [Module 53](../53%20Flutter%20Web/README.md)).

## Summary

- Flutter Desktop builds native Windows (`.exe`)/macOS (`.app`)/Linux (binary) apps via per-OS embedders/runners + the real engine (Skia/Impeller) — native rendering, not a browser canvas; build each on its own OS.
- Gains full OS access (filesystem/FFI/multi-window/isolates) beyond mobile/web sandboxes; requires desktop-idiomatic UX + per-platform packaging/signing/distribution.
- Fits cross-platform tools/productivity/creative/companion apps; consider web/PWA (web-deliverable) or native (deep OS-native); mind thinner plugin support.

## Revision Notes

- Targets: Windows (Win32/C++, `.exe`), macOS (Cocoa/Swift, `.app`), Linux (GTK/C++, binary); runners in `windows/`/`macos/`/`linux/` host engine + AOT Dart; `flutter config --enable-<platform>-desktop` + `flutter build <platform>`; build on matching OS (CI per-OS runners).
- Native rendering (Skia/Impeller, not browser canvas); full OS access (real filesystem, FFI, multi-window, system tray, native menus, full isolates) vs mobile/web sandbox (macOS App Store sandboxed).
- Fits cross-platform tools/productivity/creative/companion/enterprise; web/PWA for web-deliverable, native for deep OS-native. Trade-off: reuse + consistent custom UI vs not-pixel-native HIG + per-platform packaging/signing. Thinner plugin ecosystem (FFI/channels for gaps).

## Practice Questions

1. How do the three desktop targets build, and why per-OS?
2. What OS capabilities does desktop gain over mobile/web?
3. When would you choose Flutter Desktop vs web vs native?

## Coding Questions

1. Enable + build a desktop target on its OS and run it.
2. Identify a plugin lacking desktop support and the FFI/channel fallback.
3. Decide + justify desktop vs web/native for two scenarios.

## Mini Project

**Desktop target + fit analysis (Flutter Desktop):** Enable and build one desktop target (on its OS), confirm native rendering + full OS access (e.g., real filesystem), and write a fit-analysis doc: which desktop targets, why Flutter Desktop fits (or web/native would be better) for two scenarios, the build-per-OS + plugin-ecosystem caveats, and the reuse-vs-per-OS-overhead trade-off. Acceptance: a desktop target builds/runs (native, full OS access); fit decision justified per scenario (vs web/native); build-per-OS + plugin caveats noted; trade-off documented; desktop framed as native (not web canvas) and not "mobile in a window."
