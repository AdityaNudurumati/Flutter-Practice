# 53 · Flutter Web

## Introduction

This module covers running Flutter on the **web**: the **rendering model** (HTML vs CanvasKit vs WASM/skwasm renderers, how Flutter compiles to JS/WASM, and **when Flutter Web fits**), **web-specific concerns** (URL strategy, routing/deep links, SEO, PWA, browser APIs, platform differences), **performance & loading** (the big initial-download problem, deferred loading, caching, first paint), and **responsive + web UX** (mouse/keyboard/hover, text selection, accessibility, web conventions) — tied together in a capstone. It applies responsive/adaptive UI ([Module 24](../24%20Responsive%20UI/README.md)/[Module 25](../25%20Adaptive%20UI/README.md)), performance ([Module 21](../21%20Performance/README.md)), and routing ([Module 13](../13%20Routing/README.md)) to the web target.

## Why this module exists

"Write once, run on web" is real but **not free**: Flutter Web has a **different rendering model**, a **large initial download**, **SEO limitations**, and **web UX expectations** (URLs, back button, hover, text selection, right-click) that mobile-first code ignores. It shines for **logged-in app-like experiences** (dashboards, tools, internal apps) and struggles for **content/SEO-driven public sites**. Knowing the renderers, the web-specific gotchas, and **when Flutter Web is the right tool** is what separates a good web deployment from a slow, unindexable, un-web-like one.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [web_fundamentals_and_renderers.md](web_fundamentals_and_renderers.md) | Renderers (HTML/CanvasKit/WASM), how it works, when Flutter Web fits | 🔴 |
| 2 | [web_specific_concerns.md](web_specific_concerns.md) | URL strategy, routing/deep links, SEO, PWA, browser APIs, platform differences | 🔴 |
| 3 | [web_performance_and_loading.md](web_performance_and_loading.md) | Initial load size, deferred loading, caching, first paint, optimization | 🔴 |
| 4 | [responsive_and_web_ux.md](responsive_and_web_ux.md) | Responsive web, mouse/keyboard/hover, text selection, accessibility, conventions | 🟡 |
| 5 | [web_integration.md](web_integration.md) | Capstone: a production-ready Flutter Web app | 🔴 |

> **Cross-references:** Responsive/adaptive UI: [Module 24](../24%20Responsive%20UI/README.md)/[Module 25](../25%20Adaptive%20UI/README.md). Performance/app size: [Module 21](../21%20Performance/README.md)/[51 · app_size](../51%20Deployment/app_size_and_build_optimization.md). Routing/deep links: [Module 13](../13%20Routing/README.md). Platform channels (web has none — JS interop): [Module 26](../26%20Platform%20Channels/README.md). Desktop (sibling target): [Module 54](../54%20Flutter%20Desktop/README.md). Rendering pipeline: [Module 09](../09%20Rendering%20Pipeline/README.md).

## Prerequisites

[24 Responsive UI](../24%20Responsive%20UI/README.md), [25 Adaptive UI](../25%20Adaptive%20UI/README.md), [21 Performance](../21%20Performance/README.md), [13 Routing](../13%20Routing/README.md), [09 Rendering Pipeline](../09%20Rendering%20Pipeline/README.md).

## What you'll be able to do after this module

- Explain the web renderers (HTML/CanvasKit/WASM) and choose deliberately.
- Judge when Flutter Web is the right tool (and when a JS framework fits better).
- Handle web-specific concerns: URL strategy, deep links, SEO limits, PWA, browser APIs.
- Optimize initial load (size, deferred loading, caching) and first paint.
- Deliver responsive, web-idiomatic UX (mouse/keyboard/hover, text selection, accessibility).

## Capstone

**Production Flutter Web app:** A responsive Flutter Web app (dashboard-style) with clean URLs (path strategy + `go_router` deep links), an optimized initial load (renderer choice, deferred loading, caching, loading indicator), PWA support, web-idiomatic UX (hover/keyboard/text selection/accessibility), and a documented "why Flutter Web fits here" + SEO/platform-limitation analysis.

## Summary

Flutter Web compiles your app to JS/WASM rendered via HTML or CanvasKit/skwasm — great for logged-in, app-like experiences, weak for SEO/content sites. Success means choosing the renderer, handling web concerns (URLs/deep links/SEO/PWA), taming the initial download, and delivering web-idiomatic responsive UX — applied where Flutter Web actually fits.
