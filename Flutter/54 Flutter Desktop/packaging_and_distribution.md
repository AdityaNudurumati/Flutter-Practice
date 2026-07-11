# Packaging & Distribution

> Desktop has **no single store flow** — you **package + sign + distribute per platform**: **Windows** → **MSIX** (Microsoft Store or sideload) or an installer (Inno Setup/NSIS), signed with a **code-signing cert** (else SmartScreen warnings); **macOS** → a **`.app`** in a **`.dmg`/`.pkg`**, **code-signed + notarized** by Apple (Gatekeeper blocks unnotarized apps) or shipped via the Mac App Store (sandboxed); **Linux** → **AppImage / Flatpak / Snap / `.deb`/`.rpm`** across distros. Distribution is **stores** (discovery + auto-update, but review/fees/sandbox) **or direct download** (full control, but you handle signing + **auto-updates** yourself). Plan packaging/signing/updates **per OS**, automated in **per-OS CI**.

## Introduction

This file covers turning built binaries into distributable, signed, updatable apps on each OS, and the stores-vs-direct distribution choice. It's the desktop analog of mobile deployment ([Module 51](../51%20Deployment/README.md)) but **three-headed** and store-optional, building on signing concepts ([50 · build_signing](../50%20CI%20CD/build_signing_and_flavors.md)).

## Why this concept exists

Unlike mobile's two stores, desktop is **three OSes with divergent packaging formats, signing/notarization requirements, and distribution channels** — and users can get **security warnings/blocks** for unsigned/unnotarized apps. There's no unified "upload and release." Knowing each platform's packaging + signing + distribution + update story is what gets a trusted, installable, updatable app to users on all three.

## Real-world analogy

Shipping desktop is like **selling a physical product in three countries**, each with its own **packaging regulations, safety certification, and retail rules**: one needs a specific box + a safety seal (MSIX + code sign), another requires **customs inspection/notarization** before it clears (macOS notarization/Gatekeeper), the third accepts several **container types** depending on the shop (AppImage/Flatpak/Snap/deb/rpm). You either sell **through regional retailers** (stores: discovery + returns/updates, but fees/rules) or **ship direct to customers** (you handle certification, delivery, and **product recalls/updates** yourself).

## Internal Working

```mermaid
flowchart TD
    Build[flutter build windows/macos/linux (per OS)] --> Pack{package per platform}
    Pack -->|Windows| Win[MSIX / installer (Inno/NSIS) + code-sign cert]
    Pack -->|macOS| Mac[.app in .dmg/.pkg + codesign + NOTARIZE (Gatekeeper)]
    Pack -->|Linux| Lin[AppImage / Flatpak / Snap / .deb / .rpm]
    Win & Mac & Lin --> Distribute{distribution}
    Distribute -->|stores| Stores[MS Store / Mac App Store / Snap Store (discovery + auto-update; review/fees/sandbox)]
    Distribute -->|direct| Direct[download from your site (full control; you handle signing + auto-update)]
    Note[per-OS packaging/signing/updates; per-OS CI runners]
```

- **Windows packaging**:
  - **MSIX** (modern): for the **Microsoft Store** or sideload; supports clean install/uninstall + Store auto-update. Flutter tooling/`msix` package builds it.
  - **Installer** (Inno Setup / NSIS / WiX): a classic `.exe` installer for **direct download** — common outside the Store.
  - **Code signing**: sign with an **Authenticode certificate** — **unsigned apps trigger SmartScreen/AV warnings** and erode trust; get a cert (OV/EV) and sign the binary/installer.
- **macOS packaging**:
  - Ship the **`.app`** bundle inside a **`.dmg`** (drag-to-Applications) or a **`.pkg`** installer.
  - **Code-sign + notarize (required for direct distribution)**: sign with an **Apple Developer ID** cert and **notarize** with Apple (upload → Apple scans → staple ticket) — else **Gatekeeper blocks** the app ("can't be opened, unidentified developer"). Fastlane/`notarytool` automate it.
  - **Mac App Store** alternative: distribution + auto-update via the Store, but **sandboxed** (entitlements) + review + fees.
- **Linux packaging (most fragmented)**:
  - **AppImage** (single portable file, runs across distros — easy direct download), **Flatpak** (sandboxed, Flathub distribution), **Snap** (Snap Store), or native **`.deb`/`.rpm`** packages. Choose based on target distros/audience; AppImage/Flatpak are common for broad reach.
  - Signing/trust is less centralized than Windows/macOS.
- **Distribution: stores vs direct** (the choice):
  - **Stores** (MS Store / Mac App Store / Snap Store / Flathub): **discovery + trusted install + auto-update handled**, but **review, fees, sandboxing (esp. Mac App Store)**, and platform rules.
  - **Direct download** (your website): **full control + no fees/review + no forced sandbox**, but **you handle signing/notarization + auto-updates + trust** yourself. Common for pro tools/internal apps.
  - Often **both** (Store for reach + direct for control).
- **Auto-updates (you own it for direct distribution)**: stores auto-update; **direct downloads need your own updater** — check-for-update + download + apply (e.g., an updater framework, **Sparkle** on macOS, custom on Windows/Linux, or a package like `auto_updater`). Plan versioning + update UX; mobile-style "forward-fix" applies (can't force instant update).
- **Signing/notarization = trust**: unsigned/unnotarized apps get **OS warnings/blocks** (SmartScreen/Gatekeeper) that scare users off — signing (+ macOS notarization) is **essential for direct distribution**, not optional.
- **Automate in per-OS CI** ([Module 50](../50%20CI%20CD/README.md)): build each platform on its **own OS runner**, package + sign (secrets in encrypted store) + notarize (macOS) + upload to store/hosting — per-platform jobs. iOS-style secret handling for certs/keys.

## Memory Representation

Not app state — **per-platform distributable artifacts** (MSIX/installer `.exe`, signed+notarized `.app`/`.dmg`, AppImage/Flatpak/`.deb`) + signing material (certs/keys in encrypted CI secrets) + an update channel/manifest (for direct auto-update).

## Compiler / Build Behavior

`flutter build <platform>` (on its OS) → the native binary; packaging tools wrap + sign it; macOS notarization is a post-sign upload/scan/staple step. CI needs per-OS runners + secret-held signing material.

## Runtime Behavior

Signed/notarized apps install + launch without OS warnings; unsigned ones trigger SmartScreen/Gatekeeper. Store apps auto-update; direct apps update via your updater. macOS App Store apps run sandboxed.

## Flutter Engine Behavior

Not applicable (distribution wraps the built app). The packaged app runs the native engine as built.

## Dart VM Behavior

Not applicable (AOT native binary distributed).

## Examples

```text
Per-platform packaging + signing + distribution:
  Windows: flutter build windows -> MSIX (`msix` pkg) [MS Store/sideload] OR Inno/NSIS installer [direct]
           -> sign with Authenticode cert (avoid SmartScreen/AV warnings)
  macOS:   flutter build macos -> .app in .dmg/.pkg -> codesign (Developer ID) + NOTARIZE (notarytool)
           -> staple ticket (else Gatekeeper blocks) OR Mac App Store (sandboxed + review)
  Linux:   flutter build linux -> AppImage (portable) / Flatpak (Flathub) / Snap / .deb / .rpm (by audience)

Distribution choice:
  stores  = discovery + auto-update handled, but review/fees/sandbox
  direct  = full control + no fees, but YOU handle signing/notarization + AUTO-UPDATES + trust
  often BOTH.
```

```yaml
# CI (per-OS runners) — build + package + sign per platform (secrets encrypted)
jobs:
  windows: { runs-on: windows-latest, steps: [ build windows, make MSIX, sign (cert from secret) ] }
  macos:   { runs-on: macos-latest,   steps: [ build macos, codesign (Developer ID), notarize (notarytool), staple, make dmg ] }
  linux:   { runs-on: ubuntu-latest,  steps: [ build linux, make AppImage/Flatpak ] }
# signing certs/keys/notary creds -> encrypted CI secrets (like mobile signing, Module 50)
```

## Diagrams

```mermaid
flowchart LR
    PerOS[build per OS] --> Package[package per platform (MSIX / dmg+notarize / AppImage...)]
    Package --> Sign[sign (+ macOS notarize) — trust/no warnings]
    Sign --> Dist{distribute}
    Dist -->|store| StoreCh[MS Store / Mac App Store / Snap/Flathub (auto-update, review/fees/sandbox)]
    Dist -->|direct| DirectCh[your site (control; you own signing + auto-update)]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| Shipping unsigned Windows apps | SmartScreen/AV warnings scare users | Authenticode code-sign the binary/installer |
| Skipping macOS notarization | Gatekeeper blocks the app | codesign (Developer ID) + notarize + staple |
| Assuming a single store/flow | Desktop is 3 OSes, store-optional | Per-platform packaging + distribution plan |
| Ignoring auto-update for direct distribution | Users stuck on old versions | Ship an updater (Sparkle/custom/auto_updater) |
| Building all platforms on one OS | Must build on each | Per-OS CI runners |
| One Linux format for everyone | Distro fragmentation | Choose AppImage/Flatpak/Snap/deb by audience |
| Secrets/certs in the repo | Security breach | Encrypted CI secrets (like mobile signing) |
| Forgetting Mac App Store sandbox | File/feature access blocked | Entitlements / plan sandbox |

## Best Practices

- **Package per platform**: Windows **MSIX/installer** (Store/direct), macOS **`.app` in `.dmg`/`.pkg`**, Linux **AppImage/Flatpak/Snap/deb/rpm** (by audience) — built on **per-OS runners**.
- **Sign for trust**: Windows **Authenticode**, macOS **Developer ID sign + notarize + staple** (avoid SmartScreen/Gatekeeper blocks); store signing material in **encrypted CI secrets**.
- Choose **distribution deliberately**: **stores** (discovery + auto-update, but review/fees/sandbox) vs **direct** (control, but you own **signing/notarization + auto-updates + trust**) — often **both**.
- Provide **auto-updates** for direct distribution (Sparkle/custom/`auto_updater`) with versioning + forward-fix UX; **automate** the whole package→sign→notarize→distribute pipeline in CI ([Module 50](../50%20CI%20CD/README.md)).

## Performance

Not runtime perf — the concern is **install trust + updatability + distribution reach**. Signing/notarization prevent warnings (adoption); auto-updates keep users current; format choice affects install size/portability. Automation (CI) makes releasing repeatable across three OSes.

## Advantages / Disadvantages

- **+** Native installers per OS, trusted installs (signing/notarization), store reach + auto-update, or full control via direct + custom updater; automatable in CI.
- **−** Three divergent packaging/signing/distribution flows (no single store), macOS notarization + Linux fragmentation, you own auto-updates for direct, per-OS CI runners + secret management.

## Interview Questions

1. **🟢 How is desktop distribution different from mobile?** — No single store: you package/sign/distribute per OS (Windows MSIX/installer, macOS .dmg + notarize, Linux AppImage/Flatpak/etc.), via stores or direct download.
2. **🟢 Why sign (and on macOS notarize) desktop apps?** — Unsigned Windows apps trigger SmartScreen/AV warnings and unnotarized macOS apps are blocked by Gatekeeper — signing/notarization = trust + no scary warnings.
3. **🟡 What are the Windows/macOS/Linux packaging options?** — Windows: MSIX (Store/sideload) or Inno/NSIS installer; macOS: `.app` in `.dmg`/`.pkg` (or Mac App Store); Linux: AppImage/Flatpak/Snap/`.deb`/`.rpm`.
4. **🟡 Stores vs direct distribution — trade-offs?** — Stores: discovery + auto-update handled, but review/fees/sandbox; direct: full control + no fees, but you handle signing/notarization + auto-updates + trust — often both.
5. **🟡 Who handles auto-updates, and how?** — Stores auto-update; for direct distribution you ship your own updater (Sparkle on macOS, custom/`auto_updater` elsewhere) with versioning + forward-fix.
6. **🔴 Why must you build + package on each OS with CI runners?** — Each platform uses its native toolchain (like iOS needing a Mac); CI needs Windows/macOS/Linux runners to build + package + sign per platform.
7. **🔴 What's the macOS App Store caveat vs direct?** — App Store distribution is sandboxed (entitlements) + reviewed + fees; direct distribution is unsandboxed but requires Developer ID signing + notarization yourself.

## Senior Engineer Tips

- Code-sign Windows and sign+notarize macOS from the first release; unsigned/unnotarized apps hit SmartScreen/Gatekeeper and users assume malware — it's the biggest adoption killer for direct distribution.
- Decide stores vs direct (or both) per audience and plan auto-updates accordingly; for direct distribution, ship an updater early — a desktop app with no update path strands users on old versions.
- Automate the three per-OS package→sign→notarize→distribute pipelines in CI with secrets in the encrypted store; doing three OSes by hand each release is slow and error-prone.

## Architect Perspective

Packaging & distribution is desktop's fragmented last mile: three OSes with divergent formats, signing/notarization for trust, and a stores-vs-direct choice (often both) where direct means owning auto-updates. Unlike mobile's two-store flow, it demands per-OS packaging/signing/CI and a deliberate distribution+update strategy. Getting it right (signed/notarized, updatable, per-audience formats, automated) turns built binaries into trusted, maintainable products; ignoring it yields warning-blocked, un-updatable downloads ([desktop_fundamentals.md](desktop_fundamentals.md), [Module 51](../51%20Deployment/README.md), [Module 50](../50%20CI%20CD/README.md)).

## Summary

- No single store: package per OS (Windows MSIX/installer, macOS `.app`+`.dmg` notarized, Linux AppImage/Flatpak/Snap/deb/rpm), built on per-OS runners.
- Sign for trust (Windows Authenticode; macOS Developer ID sign + notarize + staple — avoid SmartScreen/Gatekeeper); secrets in encrypted CI.
- Distribute via stores (discovery + auto-update, review/fees/sandbox) or direct (control, but you own signing/notarization + auto-updates), often both; automate the per-OS pipeline in CI.

## Revision Notes

- Windows: MSIX (`msix` pkg — Store/sideload) or Inno/NSIS installer (direct); **Authenticode code-sign** (else SmartScreen/AV warnings).
- macOS: `.app` in `.dmg`/`.pkg`; **codesign (Developer ID) + notarize (notarytool) + staple** (else Gatekeeper blocks) OR Mac App Store (sandboxed + review + fees).
- Linux: AppImage (portable) / Flatpak (Flathub) / Snap / `.deb`/`.rpm` by audience. Distribution: stores (discovery + auto-update; review/fees/sandbox) vs direct (control; YOU own signing/notarization + **auto-updates** — Sparkle/custom/`auto_updater`), often both.
- Build + package + sign per OS (CI per-OS runners; certs/keys/notary creds in encrypted secrets); automate package→sign→notarize→distribute.

## Practice Questions

1. What are the packaging formats + signing needs per OS?
2. Why sign/notarize, and what happens if you don't?
3. Stores vs direct distribution — trade-offs and who handles updates?

## Coding Questions

1. Build + package a Windows MSIX (and note code-signing).
2. Codesign + notarize a macOS `.dmg` (outline notarytool steps).
3. Write a per-OS CI matrix that builds + packages + signs each platform.

## Mini Project

**Desktop packaging + distribution plan (Flutter Desktop):** For an app, produce a per-platform packaging/signing/distribution plan: Windows (MSIX or installer + Authenticode signing), macOS (`.app`/`.dmg` + Developer ID sign + notarize + staple, or Mac App Store), Linux (chosen format(s) by audience); a stores-vs-direct distribution decision (with auto-update strategy for direct — Sparkle/custom); and a per-OS CI pipeline (build+package+sign+notarize, secrets encrypted). Acceptance: correct per-OS packaging + signing (notarization for macOS); stores-vs-direct decision + auto-update plan for direct; per-OS CI with encrypted secrets; SmartScreen/Gatekeeper trust addressed; Linux-fragmentation + macOS-sandbox caveats noted.
