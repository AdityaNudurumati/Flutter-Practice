# Flutter Desktop Integration (Capstone: A Production Desktop App)

> Assemble a production desktop app: **confirm fit** (cross-platform tool/productivity/companion), build **native** on each OS, deliver **desktop-idiomatic UX** (window management + native menu bar + keyboard shortcuts + mouse/right-click + responsive layout), integrate **natively** (full filesystem via native dialogs, one FFI/channel native call), and **package + sign + distribute per platform** (MSIX/notarized-DMG/AppImage; stores vs direct + auto-updates) via **per-OS CI** — plus a documented **fit + platform-difference analysis**. This turns "our app also builds for desktop" into a real, native-feeling, distributable Windows/macOS/Linux product — where desktop genuinely fits.

## Introduction

This module capstone composes fundamentals/fit, desktop UX/windowing, native integration, and packaging/distribution into one coherent production desktop app + analysis. It's the "put it all together for desktop" deliverable.

## Why this concept exists

The desktop pieces only yield a good product when **assembled coherently**: fit + UX + native integration + per-platform packaging/signing/distribution, with an honest **fit decision**. This capstone provides that integrated exemplar and cements when/how Flutter Desktop works well.

## Real-world analogy

It's **launching a physical appliance across three regions**: confirm there's demand for the appliance (fit), manufacture it **natively in each region** (per-OS build), design it for **desk use** (windows/menus/keyboard/mouse), let it **plug into the home's systems** (filesystem/FFI/native), and **package + certify + ship + service (updates)** per region's rules (MSIX/notarized/AppImage; stores vs direct). Assembled, it's a real product line; half-done, it's a phone gadget awkwardly sold as a desktop appliance.

## Internal Working

```mermaid
flowchart TD
    Fit[1. Fit: is desktop right? which OSes?] --> Build[2. Build native per OS (Win/mac/Linux runners)]
    Build --> UX[3. Desktop UX: window mgmt + menu bar + shortcuts + mouse/right-click + responsive]
    UX --> Native[4. Native integration: filesystem + native dialogs + FFI/channel]
    Native --> Package[5. Package + sign + distribute per platform (MSIX / notarized DMG / AppImage; stores vs direct + auto-update)]
    Package --> CI[per-OS CI automates build->package->sign->distribute]
    CI --> Analyze[6. Document: fit + platform-difference analysis]
```

- **1. Fit** ([desktop_fundamentals.md](desktop_fundamentals.md)): confirm desktop **fits** (cross-platform tool/productivity/creative/companion/enterprise with shared custom UI); pick target OSes; consider **web/native** alternatives where they'd fit better.
- **2. Build native per OS**: enable + build **Windows/macOS/Linux** on their **own OS runners** (native rendering, full OS access); check **plugin desktop support** (FFI/channels for gaps).
- **3. Desktop UX** ([desktop_ux_and_windowing.md](desktop_ux_and_windowing.md)): **window management** (resizable + min size + remembered position, `window_manager`; maybe multi-window/tray), a **native menu bar** (`PlatformMenuBar`) with **keyboard shortcuts** (platform-aware Cmd/Ctrl) + focus traversal, **mouse conventions** (hover/cursor/right-click/scrollbars), **responsive layout** (breakpoints + max width + desktop patterns), selectable text, and **per-OS HIG** adaptation.
- **4. Native integration** ([native_integration_desktop.md](native_integration_desktop.md)): **full filesystem** via `dart:io` + **native open/save dialogs** (`file_selector`); one **FFI** call to a native lib (isolate-offloaded, memory-safe) **or** a **platform channel** for custom OS code — lightest mechanism per need.
- **5. Package + sign + distribute** ([packaging_and_distribution.md](packaging_and_distribution.md)): **Windows** MSIX/installer + **Authenticode**; **macOS** `.app`/`.dmg` **signed + notarized**; **Linux** AppImage/Flatpak/etc.; choose **stores vs direct** (+ **auto-update** for direct); automate in **per-OS CI** with secrets encrypted ([Module 50](../50%20CI%20CD/README.md)).
- **6. Document fit + differences**: a short analysis — **why desktop fits here**, **which OSes + why**, **platform differences handled** (HIG/shortcuts/packaging/sandbox), plugin-ecosystem gaps + FFI/channel fallbacks, and **accepted trade-offs** (reuse vs not-pixel-native + per-OS overhead).
- **The payoff**: a native-feeling, fully-integrated, signed, distributable, updatable Windows/macOS/Linux app from your shared Flutter codebase — genuinely production-quality **where desktop fits**.
- **Right-sizing**: an internal single-OS tool needs fit+build+basic UX+direct-distribution; a public cross-OS product adds full UX polish, per-OS packaging/signing/notarization, store presence, and auto-updates. Scale effort to the product.

## Memory Representation

Not app state — a **native product per OS**: platform runners + engine + AOT Dart + assets, packaged (MSIX/DMG/AppImage) + signed/notarized, with an update channel (direct) and a fit/difference doc. Runtime = native processes with windows + full OS resources.

## Compiler Behavior

`flutter build <platform>` (per OS) AOT-compiles + builds the native runner; packaging tools wrap + sign; macOS adds notarization. Per-OS CI runners; FFI binds native libs (bundled); conditional code branches per OS.

## Runtime Behavior

Runs as a native desktop app: resizable window + menus + shortcuts + mouse; full filesystem/FFI/native access; signed/notarized (no warnings); store or direct-updated. Full isolates for heavy work.

## Flutter Engine Behavior

Real engine (Skia/Impeller) → native window via the platform embedder; `PlatformMenuBar` → native menu; the semantics layer supports accessibility.

## Dart VM Behavior

AOT native with full isolates + `dart:io` + FFI (unlike web) — heavy native work offloaded to isolates.

## Examples

```dart
// Bootstrap: window mgmt + native menu + shortcut + native file access
Future<void> main() async {
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(900, 600));   // desktop window
  runApp(const DesktopApp());
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});
  @override
  Widget build(BuildContext context) => PlatformMenuBar(
    menus: [PlatformMenu(label: 'File', menus: [
      PlatformMenuItem(label: 'Open…',
        shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: Platform.isMacOS, control: !Platform.isMacOS),
        onSelected: _openFile),                                // native dialog + dart:io
    ])],
    child: MaterialApp(home: LayoutBuilder(builder: (c, cns) =>
      cns.maxWidth >= 900 ? const _DesktopShell() : const _CompactShell())),  // responsive
  );
}
Future<void> _openFile() async {
  final f = await openFile();                                  // native open dialog (file_selector)
  if (f != null) await File(f.path).readAsString();            // full filesystem
}
```

```text
Ship checklist (per OS):
  fit confirmed + target OSes chosen
  build native per OS (own runners) + plugin support checked (FFI/channel fallback)
  UX: window (min size/remembered/multi/tray) + menu bar + shortcuts + mouse/right-click + responsive + selectable text + per-OS HIG
  native: full filesystem + native dialogs + one FFI/channel integration (isolate for heavy)
  package+sign: Windows MSIX/installer + Authenticode; macOS .dmg sign+notarize+staple; Linux AppImage/Flatpak/...
  distribute: stores vs direct (+ auto-update for direct); per-OS CI (secrets encrypted)
  document: fit + platform differences + trade-offs
```

## Diagrams

```mermaid
flowchart LR
    Fit2[fit + OSes] --> BuildN[native build per OS]
    BuildN --> UX2[desktop UX (window/menu/keyboard/mouse/responsive)]
    UX2 --> Nat[native integration (filesystem/FFI/channel)]
    Nat --> Dist[package+sign+distribute per OS (+ auto-update)]
    Dist --> Prod[production desktop app]
    Prod --> Doc[fit + platform-difference analysis]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Shipping a mobile build unchanged to desktop | Un-desktop UX, no packaging | Do fit/UX/native/packaging work |
| Wrong use case (web-deliverable) | Install overhead vs web reach | Consider Flutter Web/PWA |
| Fixed phone-size window, no menus/shortcuts | Feels ported | Window mgmt + menu bar + shortcuts + responsive |
| Unsigned/unnotarized distribution | SmartScreen/Gatekeeper blocks | Sign (Win) + sign/notarize (mac) |
| Building all OSes on one machine | Must build per OS | Per-OS CI runners |
| No auto-update for direct distribution | Users stranded | Ship an updater |
| Ignoring plugin gaps | Missing functionality | Check support; FFI/channel fallback |
| No fit/difference analysis | Wrong-tool surprises | Document fit + platform differences + trade-offs |

## Best Practices

- **Confirm fit + target OSes** first; **build native per OS** (per-OS runners; check plugin support, FFI/channel fallbacks).
- Deliver **desktop-idiomatic UX** (window management + native menu bar + keyboard shortcuts + mouse/right-click + responsive + selectable text + per-OS HIG) and **native integration** (full filesystem/native dialogs + one FFI/channel, isolate heavy work).
- **Package + sign + distribute per platform** (MSIX/notarized-DMG/AppImage; stores vs direct + auto-update for direct); **automate in per-OS CI** with encrypted secrets.
- **Document the fit + platform-difference + trade-off analysis**; **right-size** effort (internal single-OS tool vs public cross-OS product).

## Performance

Native rendering + AOT + full isolates give strong desktop performance; usual Flutter perf (scoped rebuilds/virtualization) applies at desktop scale, with heavy native work offloaded to isolates ([Module 21](../21%20Performance/README.md)). Startup is native-fast; no web download/SEO issues.

## Advantages / Disadvantages

- **+** Native-feeling, fully-integrated, signed/distributable Windows/macOS/Linux product from a shared codebase; full OS access + performance; great for tools/productivity.
- **−** Real effort across all dimensions (per-OS build/UX/native/packaging/signing/distribution/updates), thinner plugin ecosystem, not pixel-native to each HIG, no single store; must right-size + document trade-offs.

## Interview Questions

1. **🟢 What are the steps to a production Flutter Desktop app?** — Confirm fit + OSes → build native per OS → desktop UX (window/menu/keyboard/mouse/responsive) → native integration (filesystem/FFI/channel) → package+sign+distribute per platform (+ auto-update) → document fit/differences.
2. **🟢 How do you make it feel native on desktop?** — Window management (resizable + min size + remembered), native menu bar + platform-aware shortcuts + focus traversal, mouse/right-click conventions, responsive layout, selectable text, per-OS HIG adaptation.
3. **🟡 How do you integrate with the OS on desktop?** — Full filesystem via `dart:io` + native dialogs (`file_selector`); FFI to call C/C++ libraries directly; platform channels for custom OS code — lightest tool per need, heavy work on isolates.
4. **🟡 How do you distribute across three OSes?** — Package per platform (MSIX/installer, notarized `.dmg`, AppImage/Flatpak), sign (Authenticode / Developer ID + notarize), choose stores vs direct (+ auto-update for direct), automate in per-OS CI.
5. **🟡 What must the fit/difference analysis cover?** — Why desktop fits (vs web/native), which OSes, platform differences handled (HIG/shortcuts/packaging/sandbox), plugin gaps + FFI/channel fallbacks, and accepted trade-offs.
6. **🔴 Why per-OS CI runners?** — Each platform builds + packages + signs with its native toolchain (like iOS→Mac); CI needs Windows/macOS/Linux runners.
7. **🔴 How do you right-size the effort?** — Internal single-OS tool: fit+build+basic UX+direct distribution; public cross-OS product: full UX polish + per-OS packaging/signing/notarization + store presence + auto-updates.

## Senior Engineer Tips

- Do the fit decision honestly (desktop vs web/native) and pick target OSes deliberately; the biggest failures are shipping desktop for a web-deliverable app or dumping an unmodified mobile build into a window.
- Front-load desktop UX (window/menu/keyboard/mouse) + signing/notarization + auto-update strategy; those are exactly what "just builds for desktop" skips, and they're what make it feel real and trustworthy.
- Automate the three per-OS package→sign→(notarize)→distribute pipelines in CI and plan for the thinner plugin ecosystem (FFI/channel fallbacks); manual three-OS releases and missing-plugin surprises are the recurring pain.

## Architect Perspective

Flutter Desktop integration is the synthesis that turns cross-platform reuse into genuine native Windows/macOS/Linux products: the right fit, per-OS native builds, desktop-idiomatic UX, full OS/native integration, and per-platform packaging/signing/distribution/updates — with an honest limitation analysis. Done fully and where it fits, it delivers a native-feeling, integrated, distributable app from one codebase; done partially or for the wrong use case, it disappoints. The architect's contribution is the fit decision + coherent assembly + per-OS distribution strategy + documented trade-offs ([desktop_fundamentals.md](desktop_fundamentals.md), [packaging_and_distribution.md](packaging_and_distribution.md), [Module 53](../53%20Flutter%20Web/README.md)).

## Summary

- Production Flutter Desktop = fit + OSes → native build per OS → desktop UX (window/menu/keyboard/mouse/responsive) → native integration (filesystem/FFI/channel) → per-platform package+sign+distribute (+ auto-update) via per-OS CI → documented fit/difference analysis.
- Delivers a native-feeling, integrated, signed, distributable Windows/macOS/Linux app from a shared codebase — where desktop fits (tools/productivity/companion, not web-deliverable).
- Right-size effort to the product; document platform differences + trade-offs (reuse vs not-pixel-native + per-OS overhead).

## Revision Notes

- Steps: (1) fit + target OSes (vs web/native) (2) build native per OS (own runners; check plugin support, FFI/channel fallback) (3) desktop UX (window_manager min-size/remembered/multi/tray + `PlatformMenuBar` + shortcuts (Cmd/Ctrl) + focus + mouse/right-click/scrollbars + responsive + selectable + per-OS HIG) (4) native (full filesystem + native dialogs `file_selector` + FFI/channel, isolate heavy) (5) package+sign+distribute (Win MSIX/installer + Authenticode; mac .dmg sign+notarize+staple; Linux AppImage/Flatpak/...; stores vs direct + auto-update for direct; per-OS CI, encrypted secrets) (6) document fit + platform differences + trade-offs.
- Payoff: native-feeling, integrated, signed, distributable, updatable cross-OS app from shared codebase where it fits; right-size; not for web-deliverable use cases.

## Practice Questions

1. Walk the steps from fit decision to a distributed desktop app.
2. How do you make it feel native + integrate with the OS?
3. How do you package/sign/distribute + update across three OSes?

## Coding Questions

1. Bootstrap window mgmt + a native menu bar + a shortcut + native file access.
2. Add one FFI or platform-channel native integration (isolate for heavy).
3. Write a per-OS CI matrix that builds+packages+signs (+notarizes macOS).

## Mini Project

**Production desktop app (capstone — Flutter Desktop):** Ship a cross-platform tool: confirm fit + target OSes; build native per OS; deliver desktop UX (window management + native menu bar + shortcuts + mouse/right-click + responsive + selectable text + per-OS HIG); integrate natively (full filesystem via native dialogs + one FFI/channel call, isolate for heavy); package + sign + distribute per platform (MSIX/Authenticode, notarized DMG, AppImage/Flatpak; stores vs direct + auto-update for direct) via per-OS CI; and write a fit + platform-difference + trade-off analysis. Acceptance: native builds per OS; desktop-idiomatic UX (not phone-in-window); full-OS native integration (filesystem + FFI/channel); per-platform packaging + signing (+ macOS notarization) + distribution + auto-update plan; per-OS CI with encrypted secrets; documented fit/differences/trade-offs; right-sized.
