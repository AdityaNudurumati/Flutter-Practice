# Web Performance & Loading

> Flutter Web's defining performance problem is the **initial load**: the app must **download the engine (esp. CanvasKit/WASM, several MB) + your compiled app + assets** before anything interactive appears — so first paint can be slow, and a blank screen loses users. The levers: **shrink what's shipped** (renderer choice, tree-shaking, `--dart-define` config, compressed/right-sized assets, subset fonts), **defer what isn't needed yet** (**deferred imports** for heavy features/libraries → lazy-loaded chunks), **cache aggressively** (service worker + CDN + immutable hashed assets + gzip/brotli), and **show a loading indicator** in `index.html` so first paint feels instant. Runtime perf then follows the usual rules (scoped rebuilds, virtualization) plus web specifics.

## Introduction

This file covers the web-specific performance story — dominated by initial download/first-paint — and its levers (size, deferral, caching, loading UX), plus runtime notes. It applies performance discipline ([Module 21](../21%20Performance/README.md)) and app-size techniques ([51 · app_size](../51%20Deployment/04_app_size_and_build_optimization.md)) to the web target.

## Why this concept exists

On mobile the app is pre-installed; on web it's **downloaded on first visit**, and Flutter's engine (CanvasKit/WASM) is **large** relative to a typical web page. Without optimization, first paint is a multi-second blank screen — fatal for conversion. Web performance is therefore mostly about **getting to interactive fast**: minimize + defer + cache the download, and mask latency with a loading UI.

## Real-world analogy

A native web page is a **light pamphlet** that renders as it streams in. Flutter Web is more like **downloading a small application installer before you can use it** — so you make the **installer as small as possible** (shrink/defer), **cache it so repeat visits are instant** (service worker/CDN), and show a **progress screen** so the wait doesn't feel like a broken page. First impression = how fast something meaningful appears.

## Internal Working

```mermaid
flowchart TD
    Visit[first visit] --> Download[download: engine (CanvasKit/WASM) + compiled app + assets]
    Download --> FirstPaint[first paint / interactive]
    Shrink[shrink: renderer, tree-shake, compress/right-size assets, subset fonts] --> Download
    Defer[defer: deferred imports -> lazy chunks for heavy features/libs] --> Download
    Cache[cache: service worker + CDN + immutable hashed assets + gzip/brotli] --> Repeat[repeat visits ~instant]
    LoadUI[loading indicator in index.html] --> FirstPaint
```

- **The initial-download cost (the core issue)**:
  - Shipped = **engine** (CanvasKit WASM ~several MB, or HTML renderer smaller; skwasm/WASM varies) + **compiled app** (dart2js/dart2wasm, minified/tree-shaken) + **assets/fonts**.
  - First visit must download + boot this before interactive → **slow first paint** if unmanaged. **Repeat visits** are fast **if cached**.
- **Shrink what's shipped**:
  - **Renderer**: **HTML renderer** is smaller (text/size-sensitive apps); **CanvasKit/skwasm** is bigger but higher-fidelity — choose per goal ([01_web_fundamentals_and_renderers.md](01_web_fundamentals_and_renderers.md)).
  - **Build `--release`** (tree-shaking + minification; `--tree-shake-icons`); pass config via **`--dart-define`** (no dead config).
  - **Assets**: compress/right-size images (WebP), **subset fonts**, remove unused assets, prefer **network/CDN images** over bundling large media ([51 · app_size](../51%20Deployment/04_app_size_and_build_optimization.md)).
- **Defer what isn't needed yet (deferred imports)**:
  - Flutter Web supports **`deferred as` imports** → the deferred library compiles to a **separate chunk** loaded **on demand** (`await lib.loadLibrary()`), not in the initial bundle. Use for **heavy/rarely-used features or libraries** so the **initial download stays small** and the rest loads when navigated to ([Module 47](../47%20Scalable%20Applications/README.md)).
  - Route-level deferral: lazy-load a feature's code on first navigation.
- **Cache aggressively**:
  - **Service worker** (shipped by Flutter Web) caches the app shell/assets → **repeat visits load from cache** (near-instant) + offline shell; manage **versioning** to avoid stale caches (hashed filenames + clean update).
  - **CDN + HTTP caching**: serve assets from a CDN with **long cache TTLs on immutable (hashed) files** and **gzip/brotli compression** (WASM/JS compress well) — a big first-load win over the wire.
- **Mask latency (loading UX)**: put a **loading indicator/splash in `index.html`** (shown while the engine/app download + boot) so first paint feels immediate instead of a blank white screen; optionally show **progress**. This is table stakes for perceived performance.
- **Runtime performance** (after load): the usual Flutter rules apply — **scoped rebuilds** ([Module 43](../43%20MVVM/README.md)/[Module 11](../11%20State%20Management/README.md)), **list virtualization**, `const`, **avoid heavy work on the main thread** (web isolates = limited web workers) — plus web specifics (CanvasKit is GPU-accelerated; HTML renderer can be slower for complex graphics/animations). Profile with browser devtools + Flutter DevTools.
- **Measure + budget**: measure first-load size + time (Lighthouse, network panel, `--analyze-size`), set a **web-load budget**, and enforce it in CI ([Module 50](../50%20CI%20CD/README.md)); watch for regressions as features/deps land.

## Memory Representation

Not app state — a **shipped-bundle composition** (engine + app + assets + deferred chunks) and a **cache** (service worker + CDN/HTTP). Deferred chunks load into memory on demand; cached assets avoid re-download on repeat visits.

## Compiler Behavior

`--release` tree-shakes + minifies; deferred imports produce **separate lazy chunks**; hashed filenames enable immutable caching; dart2wasm/dart2js + renderer determine engine size. `--tree-shake-icons` drops unused glyphs.

## Runtime Behavior

First visit: download + boot (slow if unoptimized) → interactive; deferred chunks fetch on demand; repeat visits hit the service-worker/CDN cache (fast). Loading UI masks the boot wait.

## Flutter Engine Behavior

CanvasKit/skwasm is GPU-accelerated (good runtime perf, larger download); the HTML renderer uses browser primitives (smaller, can be slower for complex graphics). Frame scheduling uses the browser's rAF.

## Dart VM Behavior

No VM — JS/WASM (AOT-like); deferred imports = lazy code loading; heavy compute can't easily go to isolates (web workers are limited) → keep the main thread light or offload via web workers where feasible.

## Examples

```dart
// Deferred import — heavy feature loads on demand (kept out of the initial bundle)
import 'package:myapp/features/reports/reports.dart' deferred as reports;

Future<void> openReports(BuildContext context) async {
  await reports.loadLibrary();                 // fetch the lazy chunk now
  if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => reports.ReportsScreen()));
}
// Keeps the FIRST download small; reports code arrives only when navigated to.
```

```html
<!-- web/index.html — loading indicator so first paint isn't a blank screen -->
<body>
  <div id="loading" style="display:flex;height:100vh;align-items:center;justify-content:center">
    <div class="spinner">Loading…</div>
  </div>
  <script>
    window.addEventListener('flutter-first-frame', () =>
      document.getElementById('loading').remove());   // remove splash when app is ready
  </script>
  <!-- flutter_bootstrap.js / build output loads here -->
</body>
```

```text
Load-optimization checklist:
  renderer choice (HTML vs CanvasKit/skwasm) | --release tree-shake + --tree-shake-icons | --dart-define config
  compress/right-size images (WebP) + subset fonts + CDN images
  deferred imports for heavy/rare features (lazy chunks)
  service worker + CDN + immutable hashed assets + gzip/brotli
  loading indicator in index.html (mask boot)
  measure (Lighthouse/network/--analyze-size) + enforce a web-load budget in CI
```

## Diagrams

```mermaid
flowchart LR
    Default2[default build (large, blank first paint)] --> Shrink2[shrink: renderer + tree-shake + assets]
    Shrink2 --> Defer2[defer heavy features (lazy chunks)]
    Defer2 --> Cache2[cache: service worker + CDN + compression + immutable hashes]
    Cache2 --> LoadUX[loading indicator masks boot]
    LoadUX --> Fast2[fast first/repeat paint -> higher conversion]
```

## Common Mistakes

| Mistake | Why it hurts | Fix |
|---------|-------------|-----|
| Ignoring initial download size | Slow first paint, lost users | Shrink + defer + cache + loading UI |
| Blank white screen while booting | Looks broken | Loading indicator in `index.html` |
| Everything in the initial bundle | Huge first load | Deferred imports for heavy/rare features |
| No CDN/compression/immutable caching | Slow first + repeat loads | CDN + gzip/brotli + hashed long-TTL assets |
| Bundling large images/full fonts | Bloat | WebP/right-size + subset fonts + CDN images |
| Wrong renderer for the goal | Size/perf mismatch | HTML (size) vs CanvasKit/skwasm (fidelity) |
| Heavy compute on main thread | Jank (limited web isolates) | Keep main thread light / web workers |
| No load budget/measurement | Silent regression | Measure (Lighthouse/`--analyze-size`) + CI budget |

## Best Practices

- **Minimize the initial download**: choose the renderer by goal, build **`--release`** (tree-shake + icons), inject config via `--dart-define`, and **compress/right-size assets + subset fonts** (CDN images).
- **Defer heavy/rarely-used features** with **deferred imports** (lazy chunks) so the initial bundle stays small; lazy-load per route.
- **Cache aggressively**: service worker (shell/offline + clean versioned updates) + **CDN + gzip/brotli + immutable hashed assets** (fast first + repeat visits).
- **Mask boot** with a **loading indicator in `index.html`**; apply normal **runtime perf** (scoped rebuilds/virtualization); **measure + budget** first-load size/time in CI.

## Performance

This file *is* the web performance story: first-load download/first-paint dominates (esp. CanvasKit/WASM); shrink + defer + cache + loading-UI address it; runtime follows standard Flutter perf ([Module 21](../21%20Performance/README.md)) with web caveats (limited isolates, renderer differences). A measured web-load budget prevents regressions ([Module 50](../50%20CI%20CD/README.md)).

## Advantages / Disadvantages

- **+** Fast first + repeat loads (caching), small initial bundle (defer/shrink), masked boot (loading UI), good runtime perf (CanvasKit GPU), measurable/budgeted.
- **−** Large baseline engine download (esp. CanvasKit) to fight, deferred-loading + service-worker-versioning complexity, limited web isolates, renderer trade-offs.

## Interview Questions

1. **🟢 What's the main performance problem with Flutter Web?** — The large initial download (engine — esp. CanvasKit/WASM — + app + assets) must load before interactive, causing slow first paint if unmanaged.
2. **🟢 How do you keep the initial bundle small?** — Choose the renderer, build `--release` (tree-shaking + `--tree-shake-icons`), compress/right-size assets + subset fonts, use CDN images, and defer heavy features (deferred imports).
3. **🟡 What are deferred imports, and when do you use them?** — `deferred as` imports compile a library to a lazy chunk loaded on demand (`loadLibrary()`) — use for heavy/rarely-used features to shrink the initial download.
4. **🟡 How does caching help web performance?** — Service worker + CDN + immutable hashed assets + gzip/brotli make repeat visits near-instant and speed first load (compressed engine/app) + offline shell.
5. **🟡 Why show a loading indicator in `index.html`?** — To mask the engine/app boot with a splash instead of a blank white screen — improving perceived first-paint.
6. **🔴 What runtime perf constraints are web-specific?** — Limited web isolates (heavy compute janks the main thread), renderer differences (CanvasKit GPU-accelerated vs HTML slower for complex graphics) — plus standard scoped-rebuild/virtualization rules.
7. **🔴 How do you prevent web-load regressions?** — Measure first-load size/time (Lighthouse/network/`--analyze-size`), set a web-load budget, and enforce it in CI as features/deps land.

## Senior Engineer Tips

- Budget the first-load number and defend it in CI; Flutter Web bloats first-load silently as features/deps land, and first paint is where you lose or keep users.
- Always ship a loading indicator + aggressive caching (service worker/CDN/compression/immutable hashes) and defer heavy features — those three give the biggest perceived + real load wins.
- Pick the renderer for the goal and keep heavy compute off the main thread; CanvasKit's download and web's limited isolates are the two web-specific traps.

## Architect Perspective

Web performance is fundamentally about **time-to-interactive on first visit**: Flutter's large engine download makes shrink-defer-cache-mask the core discipline, backed by a measured load budget. It's app-size/performance thinking ([Module 21](../21%20Performance/README.md)/[51 · app_size](../51%20Deployment/04_app_size_and_build_optimization.md)) applied to a download-on-demand platform, with web-specific tools (deferred imports, service worker, CDN/compression, loading UI). Get it right and Flutter Web loads acceptably fast; ignore it and the large baseline makes it feel heavy — reinforcing the app-like (not content-site) fit ([01_web_fundamentals_and_renderers.md](01_web_fundamentals_and_renderers.md)).

## Summary

- The dominant web perf issue is the initial download (engine + app + assets, esp. CanvasKit/WASM) → slow first paint if unmanaged.
- Levers: shrink (renderer/`--release`/tree-shake/assets/fonts/CDN images), defer (deferred imports → lazy chunks), cache (service worker + CDN + compression + immutable hashes), and mask (loading indicator in `index.html`).
- Runtime follows standard Flutter perf (scoped rebuilds/virtualization) + web caveats (limited isolates, renderer differences); measure + budget first-load in CI.

## Revision Notes

- Initial download = engine (CanvasKit/WASM several MB / HTML smaller) + compiled app (dart2js/wasm, minified/tree-shaken) + assets → slow first paint unless optimized; repeat visits fast if cached.
- Shrink: renderer choice, `--release` (tree-shake + `--tree-shake-icons`), `--dart-define` config, compress/right-size images (WebP) + subset fonts + CDN images. Defer: `deferred as` imports → lazy chunks (`loadLibrary()`) for heavy/rare features/routes.
- Cache: service worker (shell/offline + versioning) + CDN + gzip/brotli + immutable hashed assets. Mask boot: loading indicator in `index.html`. Runtime: scoped rebuilds/virtualization/const + limited web isolates + renderer perf differences. Measure (Lighthouse/`--analyze-size`) + CI web-load budget.

## Practice Questions

1. Why is first-visit performance the core Flutter Web challenge?
2. How do deferred imports + caching improve load?
3. What runtime perf constraints are web-specific?

## Coding Questions

1. Add a deferred import for a heavy feature loaded on navigation.
2. Add a loading indicator in `index.html` removed on first frame.
3. Configure service-worker/CDN caching + measure first-load size.

## Mini Project

**Web load optimization (Flutter Web):** Optimize an app's first load: choose the renderer for the goal, build `--release` (tree-shake + icons), optimize assets (WebP/subset fonts/CDN images), defer a heavy feature via deferred imports, configure aggressive caching (service worker + CDN + compression + immutable hashed assets), and add a loading indicator in `index.html` — then measure first-load size/time (Lighthouse/`--analyze-size`) before/after and add a CI web-load budget. Acceptance: shrink + defer + cache + loading-UI applied; measurable first-load improvement (before/after); deferred feature loads on demand; caching (SW/CDN/compression/immutable) configured; CI web-load budget; runtime perf (scoped rebuilds) noted.
