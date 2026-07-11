# 54 · Flutter Desktop

## Introduction

This module covers running Flutter on the **desktop** — **Windows, macOS, and Linux**: the **fundamentals** (how desktop targets work, and **when desktop fits**), **desktop UX & windowing** (window management, menu bars, keyboard shortcuts, mouse conventions, multi-window), **native integration** (FFI, platform channels on desktop, full filesystem/OS access), and **packaging & distribution** (MSIX/DMG/AppImage, code signing, stores vs direct download, updates) — tied together in a capstone. It's the sibling target to Flutter Web ([Module 53](../53%20Flutter%20Web/README.md)), building on responsive/adaptive UI ([Module 24](../24%20Responsive%20UI/README.md)/[Module 25](../25%20Adaptive%20UI/README.md)), platform channels ([Module 26](../26%20Platform%20Channels/README.md)), and deployment ([Module 51](../51%20Deployment/README.md)).

## Why this module exists

Flutter Desktop turns one codebase into native Windows/macOS/Linux apps — genuinely useful for **internal tools, cross-platform productivity/creative apps, and companion desktop apps** — but desktop has its **own UX conventions** (menu bars, keyboard-first workflows, resizable windows, right-click), **full OS access** (real filesystem, FFI to native libs), and **fragmented distribution** (three platforms, different packaging/signing/stores). Unlike mobile, there's no single store flow. Knowing the targets, desktop UX, native integration, and per-platform packaging is what makes a real desktop app rather than a phone UI stretched to a window.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [desktop_fundamentals.md](desktop_fundamentals.md) | Windows/macOS/Linux targets, how it works, when desktop fits | 🔵 |
| 2 | [desktop_ux_and_windowing.md](desktop_ux_and_windowing.md) | Window management, menus, keyboard shortcuts, mouse, multi-window | 🟡 |
| 3 | [native_integration_desktop.md](native_integration_desktop.md) | FFI, platform channels, filesystem/OS access on desktop | 🔴 |
| 4 | [packaging_and_distribution.md](packaging_and_distribution.md) | MSIX/DMG/AppImage, signing, stores vs direct, updates | 🔴 |
| 5 | [desktop_integration.md](desktop_integration.md) | Capstone: a production desktop app | 🔴 |

> **Cross-references:** Web (sibling target): [Module 53](../53%20Flutter%20Web/README.md). Responsive/adaptive UI: [Module 24](../24%20Responsive%20UI/README.md)/[Module 25](../25%20Adaptive%20UI/README.md). Platform channels/native: [Module 26](../26%20Platform%20Channels/README.md)/[Module 27](../27%20Native%20Android/README.md)/[Module 28](../28%20Native%20iOS/README.md). File handling: [Module 34](../34%20File%20Handling/README.md). Deployment/signing: [Module 51](../51%20Deployment/README.md)/[50 · build_signing](../50%20CI%20CD/build_signing_and_flavors.md).

## Prerequisites

[24 Responsive UI](../24%20Responsive%20UI/README.md), [25 Adaptive UI](../25%20Adaptive%20UI/README.md), [26 Platform Channels](../26%20Platform%20Channels/README.md), [34 File Handling](../34%20File%20Handling/README.md), [51 Deployment](../51%20Deployment/README.md). A machine of the target OS to build/test each platform.

## What you'll be able to do after this module

- Explain the desktop targets, how they build, and when desktop is the right choice.
- Implement desktop UX: window management, menu bars, keyboard shortcuts, mouse conventions, multi-window.
- Integrate natively: FFI to native libraries, platform channels, full filesystem/OS access.
- Package + sign + distribute per platform (MSIX/DMG/AppImage; stores vs direct; updates).
- Ship a production desktop app that feels native on Windows/macOS/Linux.

## Capstone

**Production desktop app:** A cross-platform desktop app (e.g., a productivity/tool app) with proper window management + a native menu bar + keyboard shortcuts, mouse/right-click conventions, full filesystem access (native file dialogs), one FFI or platform-channel native integration, and per-platform packaging + signing + a distribution/update plan — with a documented "why desktop fits + platform differences" analysis.

## Summary

Flutter Desktop builds native Windows/macOS/Linux apps from one codebase — strong for tools/productivity/companion apps. Success means desktop-idiomatic UX (windowing/menus/keyboard/mouse), full OS/native integration (FFI/channels/filesystem), and per-platform packaging + signing + distribution (no single store) — applied where desktop genuinely fits.
