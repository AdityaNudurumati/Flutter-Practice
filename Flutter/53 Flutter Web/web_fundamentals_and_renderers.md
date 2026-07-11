# Web Fundamentals & Renderers

> Flutter Web compiles your Dart to **JavaScript (dart2js)** or **WASM (dart2wasm)** and renders the same widget tree through one of two paths: **HTML renderer** (lighter download, uses HTML/CSS/Canvas — smaller initial size, better text/SEO-ish, but lower-fidelity/slower for complex graphics) or **CanvasKit** (Skia compiled to WASM — pixel-identical to mobile, high-fidelity/consistent, but a **larger download** as it fetches the CanvasKit WASM). The newer **skwasm/WASM** path (dart2wasm + Skia via WASM) improves performance. Crucially, Flutter Web **paints a canvas, not a DOM of your widgets** (especially CanvasKit) — which is why **SEO, text selection, and accessibility need special handling**, and why Flutter Web fits **app-like experiences** far better than **content/SEO sites**.

## Introduction

This file explains how Flutter runs on the web (compilation + renderers), the trade-offs between HTML/CanvasKit/WASM, and — most importantly — **when Flutter Web is the right choice**. It's the foundation for the web-specific concerns, performance, and UX files.

## Why this concept exists

The web is a fundamentally different platform (DOM, JS, browser, SEO, download-on-demand) than mobile. Flutter Web bridges it by compiling to JS/WASM and rendering via HTML or a WASM canvas — but each renderer trades size/fidelity/text differently, and the "canvas, not DOM" model has real consequences. Understanding this prevents shipping a bloated, unindexable, un-web-like app to the wrong use case.

## Real-world analogy

Flutter Web is like **shipping your own rendering runtime to the browser** instead of using the browser's native building blocks. **HTML renderer** = using the browser's existing furniture (HTML/CSS) where possible — lighter, more "native web," but constrained. **CanvasKit** = bringing your own high-end easel + paints (Skia/WASM) — pixel-perfect and consistent, but you must **ship the easel first** (bigger download). Either way, for CanvasKit you're **painting a picture on a canvas**, so a search engine or screen reader sees a painting, not labeled furniture — hence the SEO/accessibility caveats.

## Internal Working

```mermaid
flowchart TD
    Dart[your Dart app] --> Compile{compile}
    Compile -->|dart2js| JS[JavaScript]
    Compile -->|dart2wasm| WASM[WebAssembly]
    JS & WASM --> Render{renderer}
    Render -->|HTML| Html[HTML/CSS/Canvas: smaller, better text/SEO-ish, lower fidelity]
    Render -->|CanvasKit (Skia/WASM)| CK[pixel-identical, high fidelity, LARGER download]
    Render -->|skwasm (dart2wasm + Skia WASM)| Skw[improved perf]
    Note[renders a CANVAS (esp. CanvasKit), not a DOM of your widgets -> SEO/text/a11y need help]
```

- **Compilation**: `flutter build web` compiles Dart to **JavaScript (dart2js)** (default, broad support) or **WASM (dart2wasm)** (newer, faster, needs modern browsers). The engine + your app ship as web assets served by a web server.
- **Renderers (the key choice)**:
  - **HTML renderer**: draws with **HTML elements + CSS + Canvas 2D**. **Smaller initial download**, better **text rendering/selection** and marginally friendlier to the DOM, but **lower fidelity + slower** for complex graphics/animations; some inconsistencies vs mobile.
  - **CanvasKit**: **Skia compiled to WASM** — renders **exactly like mobile/desktop** (pixel-consistent, high performance for graphics), but **downloads the CanvasKit WASM (~several MB)** → bigger initial load. Best fidelity/consistency.
  - **skwasm / WASM path**: **dart2wasm + Skia-via-WASM** — the modern direction, improving performance; Flutter's renderer story is **consolidating toward CanvasKit/skwasm** (historically you could pick `--web-renderer html|canvaskit|auto`; newer Flutter defaults have shifted — check your version's options).
  - Choose per goal: **HTML** for text-heavy/size-sensitive/simpler UIs; **CanvasKit/skwasm** for fidelity/graphics/consistency (accept the download — mitigate with caching/loading UI — [web_performance_and_loading.md](web_performance_and_loading.md)).
- **"Canvas, not DOM" (crucial consequence)**: especially with CanvasKit, Flutter **paints pixels onto a canvas** rather than emitting a semantic DOM of your widgets. Therefore:
  - **SEO**: crawlers see little meaningful HTML → **poor for content/SEO-driven public sites** ([web_specific_concerns.md](web_specific_concerns.md)).
  - **Text selection / find-in-page / accessibility**: need **special handling** (Flutter's semantics layer for a11y; SelectionArea for selection).
  - **Deep browser integration** (native form autofill, some browser behaviors) is limited.
- **No platform channels on web**: instead use **JS interop** (`dart:js_interop`/`package:web`) to call browser/JS APIs; no `MethodChannel`/native plugins the mobile way ([Module 26](../26%20Platform%20Channels/README.md)).
- **When Flutter Web fits (the decision)**:
  - **Great fit**: **logged-in, app-like experiences** — dashboards, internal tools, admin panels, design/creative tools, complex interactive apps, PWAs — where SEO doesn't matter and consistency/velocity (one codebase) do.
  - **Poor fit**: **content/marketing/SEO-driven public sites, blogs, e-commerce landing pages** — where SEO, tiny fast first paint, and DOM semantics are essential → a **web-native framework (React/Next/Svelte/plain HTML)** is better.
  - **Trade-off**: Flutter Web buys **code reuse + pixel consistency** at the cost of **download size + SEO + web-nativeness**. Decide by use case, not by "we already have Flutter."
- **Deployment**: static web assets (`build/web`) served by any host/CDN; enable proper **caching + compression** ([web_performance_and_loading.md](web_performance_and_loading.md)); PWA support via a manifest + service worker ([web_specific_concerns.md](web_specific_concerns.md)).

## Memory Representation

Not app state — a **build artifact**: compiled JS/WASM + engine + assets. CanvasKit adds the Skia WASM blob. At runtime the browser runs the JS/WASM and Flutter paints to a canvas (CanvasKit) or HTML/Canvas (HTML renderer).

## Compiler Behavior

`dart2js` (JS) or `dart2wasm` (WASM); tree-shaking + minification reduce size; renderer choice affects the shipped engine + whether CanvasKit WASM is fetched. Release builds are optimized ([web_performance_and_loading.md](web_performance_and_loading.md)).

## Runtime Behavior

The browser downloads + runs the app (initial load can be **multi-MB**, esp. CanvasKit) then renders via the chosen path; CanvasKit gives mobile-identical rendering; HTML renderer uses browser primitives. Frame rendering uses the browser's rAF/vsync.

## Flutter Engine Behavior

On web the "engine" is the **web engine** (CanvasKit/Skia-WASM or the HTML backend) rendering the same widget/render-object trees ([Module 09](../09%20Rendering%20Pipeline/README.md)); no Skia native binary — it's WASM (CanvasKit) or DOM/Canvas (HTML).

## Dart VM Behavior

**No Dart VM on web** — code is compiled to JS/WASM (AOT-like); no JIT. Isolates map to **web workers** (limited). Runtime behavior mirrors AOT.

## Examples

```text
Build for web (renderer flags vary by Flutter version — check `flutter build web --help`):
  flutter build web --release                        # default renderer for your version
  flutter build web --web-renderer html              # (older) smaller download, better text/SEO-ish, lower fidelity
  flutter build web --web-renderer canvaskit         # (older) pixel-identical, high fidelity, larger download
  # newer Flutter: WASM/skwasm path (dart2wasm) — verify current options for your SDK

Renderer decision:
  text-heavy / size-sensitive / simpler UI  -> HTML renderer
  fidelity / graphics / mobile-consistency  -> CanvasKit / skwasm (mitigate download via caching + loading UI)
```

```text
When Flutter Web FITS:
  logged-in app-like: dashboards, internal tools, admin panels, creative/interactive apps, PWAs
When it DOESN'T:
  SEO/content-driven public sites, blogs, marketing/landing, e-commerce SEO pages -> use React/Next/Svelte/HTML
Trade-off: code reuse + pixel consistency  vs  download size + SEO + web-nativeness
```

## Diagrams

```mermaid
flowchart LR
    Goal{use case}
    Goal -->|app-like, logged-in, no SEO| Flutter[Flutter Web (great fit)]
    Goal -->|content/SEO/marketing| WebNative[web-native framework (better)]
    Flutter --> Renderer{renderer}
    Renderer -->|size/text| HTMLr[HTML]
    Renderer -->|fidelity| CKr[CanvasKit/skwasm]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Using Flutter Web for an SEO/content site | Canvas rendering → poor SEO | Use a web-native framework for SEO/content |
| Ignoring the initial-download size | Slow first load (esp. CanvasKit) | Optimize load (size/deferred/caching) + loading UI |
| Assuming platform channels work | Web has none | JS interop (`dart:js_interop`/`package:web`) |
| Expecting DOM semantics for free | Flutter paints a canvas | Use semantics (a11y) + SelectionArea (text) |
| Picking a renderer without thinking | Wrong size/fidelity trade-off | Choose HTML vs CanvasKit/skwasm per goal |
| Assuming a Dart VM/JIT on web | Web is JS/WASM (AOT-like) | Design for compiled web behavior |
| "We have Flutter, so use it for the site" | Wrong tool for SEO/content | Decide by use case, not existing stack |

## Best Practices

- **Choose Flutter Web by use case**: great for **logged-in, app-like** experiences (dashboards/tools/PWAs, no SEO need); use a **web-native framework** for **SEO/content-driven public sites**.
- **Pick the renderer deliberately**: **HTML** (smaller/text/size-sensitive) vs **CanvasKit/skwasm** (fidelity/graphics/consistency, larger download) — verify current options for your SDK version.
- Plan for the **"canvas, not DOM"** consequences: **SEO limits**, and special handling for **accessibility (semantics)** and **text selection (SelectionArea)**; use **JS interop** for browser APIs (no platform channels).
- **Optimize the initial load** (size/deferred/caching + loading UI — [web_performance_and_loading.md](web_performance_and_loading.md)); deploy static assets to a CDN with caching/compression + PWA support.

## Performance

The dominant concern is **initial download** (multi-MB, esp. CanvasKit + WASM) → slow first paint if unmanaged; HTML renderer is smaller, CanvasKit is faster for graphics. WASM/skwasm improves runtime perf. Mitigations (deferred loading, caching, compression, loading UI) are essential ([web_performance_and_loading.md](web_performance_and_loading.md)/[Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** One codebase across web + mobile + desktop, pixel-consistent UI (CanvasKit), great for app-like/PWA experiences, high dev velocity.
- **−** Large initial download, poor SEO (canvas), text-selection/accessibility need work, not web-native feel, no platform channels (JS interop), heavier than a web-native framework for content sites.

## Interview Questions

1. **🟢 How does Flutter run on the web?** — Dart compiles to JS (dart2js) or WASM (dart2wasm), rendering the same widget tree via the HTML renderer or CanvasKit/skwasm (Skia-WASM) — often painting to a canvas rather than a semantic DOM.
2. **🟢 HTML renderer vs CanvasKit — trade-offs?** — HTML: smaller download, better text/SEO-ish, lower fidelity; CanvasKit: pixel-identical/high-fidelity but larger download (fetches CanvasKit WASM). skwasm/WASM improves perf.
3. **🟡 Why does Flutter Web have SEO/accessibility/text-selection issues?** — It paints a canvas (esp. CanvasKit) instead of a DOM of your widgets, so crawlers/screen-readers/selection need special handling (semantics layer, SelectionArea).
4. **🟡 When is Flutter Web the right choice — and when not?** — Right for logged-in, app-like experiences (dashboards/tools/PWAs, no SEO); wrong for SEO/content-driven public sites (use a web-native framework).
5. **🟡 How do you access browser APIs on web?** — Via JS interop (`dart:js_interop`/`package:web`) — there are no platform channels/native plugins the mobile way.
6. **🔴 What's the main performance concern, and how do you mitigate it?** — The large initial download (esp. CanvasKit/WASM) → slow first paint; mitigate with size optimization, deferred loading, caching/compression, and a loading indicator.
7. **🔴 Is there a Dart VM on web?** — No — code is compiled to JS/WASM (AOT-like, no JIT); isolates map to web workers (limited).

## Senior Engineer Tips

- Decide Flutter Web vs a web-native framework by the use case (app-like vs SEO/content), not by "we already use Flutter" — the wrong choice ships a slow, unindexable site.
- Choose the renderer for the goal (HTML for size/text, CanvasKit/skwasm for fidelity) and always budget for the initial download with caching + a loading UI; CanvasKit's multi-MB fetch is the first thing users feel.
- Plan accessibility + text selection from the start (semantics, SelectionArea) since the canvas model won't give them for free — retrofitting a11y on a Flutter Web app is painful.

## Architect Perspective

Flutter Web extends the single-codebase promise to the browser by compiling to JS/WASM and rendering via HTML or a WASM canvas — a powerful fit for app-like, logged-in experiences and PWAs, and a poor one for SEO/content sites. The architect's job is the **use-case decision** (Flutter Web vs web-native), the **renderer trade-off** (size vs fidelity), and planning for the **canvas-model consequences** (SEO/a11y/text) + the **initial-download** cost. Get those right and web becomes a genuine reuse win; ignore them and you ship a heavy, un-web-like app ([web_specific_concerns.md](web_specific_concerns.md), [web_performance_and_loading.md](web_performance_and_loading.md), [Module 54](../54%20Flutter%20Desktop/README.md)).

## Summary

- Flutter Web compiles Dart → JS/WASM, rendering via **HTML** (smaller/text) or **CanvasKit/skwasm** (fidelity/consistency, larger download); it paints a canvas, not a DOM.
- Consequences: SEO limits + special handling for accessibility/text selection; browser APIs via JS interop (no platform channels); no Dart VM (AOT-like).
- Fits logged-in app-like experiences/PWAs; not SEO/content sites (use web-native). Choose renderer by goal; budget the initial download.

## Revision Notes

- Compile: dart2js (JS) / dart2wasm (WASM, newer/faster); render via HTML renderer (smaller, text/SEO-ish, lower fidelity) or CanvasKit (Skia-WASM: pixel-identical, high fidelity, larger download) / skwasm (dart2wasm+Skia, improved perf). Renderer options vary by SDK version.
- Paints a canvas (esp. CanvasKit), not a DOM → SEO poor; accessibility (semantics) + text selection (SelectionArea) need handling; browser APIs via JS interop (no platform channels); no Dart VM (AOT-like), isolates→web workers.
- Fits: logged-in app-like (dashboards/tools/PWAs, no SEO); not: SEO/content sites (use React/Next/Svelte/HTML). Trade-off: reuse + pixel consistency vs download size + SEO + web-nativeness. Choose renderer by goal; budget initial download (caching/deferred/compression/loading UI).

## Practice Questions

1. What are the two renderers, and how do their trade-offs differ?
2. Why does Flutter Web struggle with SEO, and what fits instead?
3. When is Flutter Web the right tool vs a web-native framework?

## Coding Questions

1. Build for web with each renderer and compare download size/fidelity.
2. Use JS interop to call a browser API (no platform channel available).
3. Decide + justify Flutter Web vs a web-native framework for two scenarios.

## Mini Project

**Renderer + fit analysis (Flutter Web):** Build a small app for web with each renderer (HTML vs CanvasKit/skwasm per your SDK), compare initial download size + text/fidelity, and write a decision doc: which renderer for which goal, and a "Flutter Web vs web-native" fit analysis for two scenarios (a logged-in dashboard vs an SEO marketing site). Acceptance: builds with each renderer + measured size/fidelity comparison; renderer chosen by goal; fit decision (app-like vs SEO/content) justified per scenario; canvas-model consequences (SEO/a11y/text) + initial-download cost noted; JS-interop (not platform channels) for any browser API.
