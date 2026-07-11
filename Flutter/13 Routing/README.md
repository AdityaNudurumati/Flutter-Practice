# 13 · Routing

## Introduction

Routing is production-grade navigation: URL-driven, deep-link-capable, guarded, and nested. This module focuses on **`go_router`** (the officially-recommended package built on Navigator 2.0) — declarative routes, path/query params, deep linking, redirects/guards, shell routes for tabs, and type-safe routes.

## Why this module exists

Module 12 covered the mechanics; real apps need URL sync (web), deep links, auth redirects, and tabbed shells that survive links. `go_router` provides these ergonomically. Getting routing right is critical for UX (shareable links, back behavior), web SEO, and maintainability.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [go_router_fundamentals.md](go_router_fundamentals.md) | Setup, routes, path/query params, `go`/`push` | 🔵 |
| 2 | [deep_linking_and_url_strategy.md](deep_linking_and_url_strategy.md) | Deep links (mobile/web), URL strategy | 🔴 |
| 3 | [guards_and_redirects.md](guards_and_redirects.md) | `redirect`, auth guards, `refreshListenable` | 🔴 |
| 4 | [shell_routes_and_nested.md](shell_routes_and_nested.md) | `ShellRoute`/`StatefulShellRoute` (tabs + deep links) | 🔴 |
| 5 | [type_safe_and_error_handling.md](type_safe_and_error_handling.md) | Typed routes (codegen), `errorBuilder`, `extra` | 🔵 |

> **Cross-references:** Navigator/stack + declarative basics: [Module 12](../12%20Navigation/README.md). Auth: [Module 17](../17%20Authentication/README.md). State (auth listenable): [Module 11](../11%20State%20Management/README.md). Web URL/SEO: [Module 53](../53%20Flutter%20Web/README.md). App entry/`MaterialApp.router`: [06 · app_entry_point](../06%20Flutter%20Fundamentals/app_entry_point.md).

## Prerequisites

[12 Navigation](../12%20Navigation/README.md) — especially declarative navigation and nested navigators/tabs.

## What you'll be able to do after this module

- Configure `go_router` with path/query params and navigate declaratively.
- Handle deep links on mobile and web with the right URL strategy.
- Implement auth guards/redirects that react to auth-state changes.
- Build tabbed shells (`StatefulShellRoute`) that preserve state and support deep links.
- Use type-safe routes and handle route errors.

## Capstone

**Routed app with auth + tabs:** A `go_router` app with a login guard (redirect), deep-linkable detail pages (`/product/:id`), and a bottom-nav `StatefulShellRoute` where each tab keeps its stack and is deep-linkable — the routing backbone of a real app.

## Summary

`go_router` turns Navigator 2.0 into a declarative, URL-first router with params, deep links, guards, and shells. It's the production default; master it and your navigation is shareable, guarded, testable, and web-ready.
