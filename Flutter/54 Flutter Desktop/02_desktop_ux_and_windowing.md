# Desktop UX & Windowing

> Desktop users expect **desktop conventions**, not a phone UI in a window: a **resizable window** (responsive layout + a sensible **min size** + remembered size/position), a **native menu bar** (`PlatformMenuBar` — File/Edit/View… on macOS the system bar), **keyboard-first workflows** (shortcuts via `Shortcuts`/`Actions`, full focus traversal, Tab/Enter/Esc), **mouse conventions** (hover states, cursors, **right-click context menus**, scroll wheel, visible scrollbars), and often **multi-window/system-tray** behavior (via `window_manager`/`tray_manager`). Getting these right — plus each OS's HIG differences (macOS traffic lights + top menu vs Windows/Linux) — is what makes the app feel native rather than ported.

## Introduction

This file covers desktop-idiomatic UX: window management (size/position/min/multi-window), native menus, keyboard shortcuts + focus, mouse/right-click conventions, and per-OS HIG differences. It applies responsive/adaptive UI ([Module 24](../24%20Responsive%20UI/README.md)/[Module 25](../25%20Adaptive%20UI/README.md)) and web-UX overlap ([53 · responsive_and_web_ux](../53%20Flutter%20Web/04_responsive_and_web_ux.md)) to the desktop context.

## Why this concept exists

Desktop has decades of UX conventions (menu bars, keyboard shortcuts, resizable/multi windows, right-click) users expect and rely on — and mobile-first Flutter code provides none of them. Without desktop UX, the app feels foreign: a fixed phone-sized window, no menus, no shortcuts, no right-click. These patterns bridge the app to the desktop platform.

## Real-world analogy

It's **furnishing an office vs a phone booth**: a desk you can **rearrange to fit the room** (resizable window + min size), a **filing/menu system on the wall** (menu bar), **keyboard shortcuts like a power user's hotkeys**, a **mouse with a right-click menu**, and maybe **multiple desks/monitors** (multi-window). A phone-booth setup (tiny fixed screen, touch-only, no menus/shortcuts) dropped into an office is obviously wrong to anyone who works at a desk.

## Internal Working

```mermaid
flowchart TD
    Window[resizable window: min size + remembered size/position + multi-window] --> WM[window_manager / tray_manager]
    Menu[native menu bar: File/Edit/View...] --> PMB[PlatformMenuBar (system bar on macOS)]
    Keyboard[keyboard-first: shortcuts + focus traversal] --> SA[Shortcuts/Actions + FocusTraversalGroup]
    Mouse[mouse: hover/cursor/right-click/scroll] --> MR[MouseRegion + secondary-tap context menus + Scrollbar]
    HIG[per-OS HIG: macOS top menu/traffic lights vs Win/Linux] --> Adapt[adapt conventions per platform]
```

- **Window management**:
  - **Resizable** windows → **responsive layout** (breakpoints + max content width + desktop patterns like side rails/master-detail — [Module 24](../24%20Responsive%20UI/README.md)); set a **minimum window size** so the UI never breaks.
  - **Remember + restore** window **size/position** (and maximized state) across launches; set **initial size/title**. Use **`window_manager`** for size/position/min/max/fullscreen/always-on-top/frameless/custom title bar.
  - **Multi-window** (opening additional windows) — supported via plugins/newer Flutter multi-window APIs; common for tools (inspectors, detached panels). **System tray** via **`tray_manager`** (background apps, quick actions).
- **Native menu bar**: desktop apps expect a **menu bar** (File/Edit/View/Help…). Flutter's **`PlatformMenuBar`** renders a **native menu bar** — on **macOS the system top menu bar** (required convention), on Windows/Linux an in-window menu. Wire menu items to actions/shortcuts. (Context menus + app menu also matter.)
- **Keyboard-first workflows** (desktop essential):
  - **Shortcuts** via **`Shortcuts` + `Actions`** (or `CallbackShortcuts`): Ctrl/**Cmd**+S/C/V/Z, Esc, F-keys, arrows — and **map them in the menu bar** (users discover shortcuts via menus). Respect **platform modifier** (Cmd on macOS, Ctrl on Windows/Linux).
  - **Focus traversal**: full **Tab/Shift+Tab** order (`FocusTraversalGroup`, correct focus), Enter/Space activation, Esc to cancel — desktop users navigate by keyboard.
- **Mouse conventions**:
  - **Hover states** + **cursors** (`MouseRegion` — pointer over clickables, text cursor over text) — desktop expects hover feedback.
  - **Right-click context menus** (`GestureDetector.onSecondaryTap` / `ContextMenuController` / menu builders) — a core desktop interaction.
  - **Scroll wheel/trackpad** + **visible scrollbars** (`Scrollbar`), **double-click**, drag-and-drop where relevant.
- **Text + selection**: selectable text (`SelectionArea`/`SelectableText`), standard copy/paste/cut, and native-feeling text fields.
- **Per-OS HIG differences (adapt)**:
  - **macOS**: system **top menu bar**, **traffic-light** window controls, Cmd-based shortcuts, distinct look/feel; consider **`macos_ui`** for native-styled widgets.
  - **Windows**: in-window menu, Ctrl shortcuts, title bar controls; **`fluent_ui`** for Fluent-styled widgets.
  - **Linux**: varies by desktop environment (GTK); in-window menu, Ctrl shortcuts; **`yaru`** (GNOME/Ubuntu) styling.
  - **Adapt conventions per platform** (shortcut modifiers, menu placement, window controls) — one codebase, platform-aware behavior/styling.
- **Density + sizing**: desktop UIs are often **denser** (more info, smaller touch targets acceptable) and **mouse-precise** — adapt from mobile's touch-sized targets ([Module 25](../25%20Adaptive%20UI/README.md)).

## Memory Representation

Not app state beyond UI: window size/position (persisted to storage/prefs), focus/hover state, shortcut→action mappings, menu structure, multi-window handles. `window_manager`/`tray_manager` hold native window/tray state.

## Compiler Behavior

Not applicable (standard widgets/plugins). `PlatformMenuBar`/`Shortcuts`/`Actions`/`MouseRegion` are cross-platform widgets; platform-conditional code (`Platform.isMacOS`) branches conventions.

## Runtime Behavior

Window resizes → responsive rebuilds (min-size enforced); size/position restored on launch; native menu + shortcuts fire actions; hover/cursor/right-click respond to mouse; multi-window/tray managed via plugins.

## Flutter Engine Behavior

The desktop embedder reports mouse (hover/wheel/secondary-click) + keyboard events and hosts the native window; `PlatformMenuBar` bridges to the OS menu (native macOS menu bar).

## Dart VM Behavior

Not applicable (AOT native); window/input handled by framework + plugins + embedder.

## Examples

```dart
// Window: min size + remembered size/position (window_manager)
Future<void> setupWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(800, 600));   // don't break below this
  await windowManager.setTitle('My Tool');
  // restore saved size/position from prefs; save on resize/move
}

// Native menu bar + keyboard shortcut (platform-aware modifier)
PlatformMenuBar(menus: [
  PlatformMenu(label: 'File', menus: [
    PlatformMenuItem(label: 'Save',
      shortcut: SingleActivator(LogicalKeyboardKey.keyS,
        meta: Platform.isMacOS, control: !Platform.isMacOS),  // Cmd on mac, Ctrl elsewhere
      onSelected: save),
  ]),
], child: appBody);

// Mouse: hover cursor + right-click context menu + visible scrollbar
MouseRegion(cursor: SystemMouseCursors.click, child:
  GestureDetector(onSecondaryTapDown: (d) => showContextMenu(d.globalPosition), child: item));
Scrollbar(child: ListView.builder(/* ... */));

// Keyboard focus traversal + Esc/Enter (Shortcuts/Actions)
Shortcuts(shortcuts: {const SingleActivator(LogicalKeyboardKey.escape): const CancelIntent()},
  child: Actions(actions: {CancelIntent: CallbackAction(onInvoke: (_) => cancel())}, child: form));
```

## Diagrams

```mermaid
flowchart LR
    PhoneUI[phone UI in a window] -->|feels foreign| DesktopUX[desktop UX]
    DesktopUX --> Win[resizable + min size + remembered + multi-window/tray]
    DesktopUX --> Menu2[native menu bar (macOS system bar)]
    DesktopUX --> KB[keyboard: shortcuts + focus traversal]
    DesktopUX --> Ms[mouse: hover/cursor/right-click/scrollbars]
    DesktopUX --> HIG2[per-OS conventions (macOS/Win/Linux)]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Fixed phone-size window | Breaks on resize; not desktop | Responsive layout + min size + remembered size |
| No menu bar | Un-desktop, no shortcut discovery | `PlatformMenuBar` (system bar on macOS) |
| No keyboard shortcuts/focus | Power users blocked | `Shortcuts`/`Actions` + focus traversal |
| Same modifier on all OSes | Wrong (Cmd vs Ctrl) | Platform-aware modifiers |
| No right-click context menu | Missing core desktop interaction | Secondary-tap context menus |
| No hover/cursor/scrollbars | Feels un-native | `MouseRegion` + `Scrollbar` |
| Unselectable text | Basic expectation broken | `SelectionArea`/`SelectableText` |
| Ignoring per-OS HIG | Feels foreign on each | Adapt conventions (menus/controls/styling) |

## Best Practices

- Support **resizable windows** (responsive layout + **min size** + **remembered size/position**, `window_manager`) and **multi-window/system tray** where the app needs it; never a fixed phone-sized window.
- Provide a **native menu bar** (`PlatformMenuBar` — system bar on macOS) with menu items **mapped to keyboard shortcuts** (platform-aware modifiers: **Cmd**/Ctrl), and full **focus traversal** (Tab/Enter/Esc).
- Implement **mouse conventions** (hover states/cursors, **right-click context menus**, scroll wheel, visible **scrollbars**) and **selectable text**.
- **Adapt per-OS HIG** (menu placement/window controls/shortcuts/styling — `macos_ui`/`fluent_ui`/`yaru`) and **density** for mouse-precise desktop UIs.

## Performance

Not primarily perf; responsive rebuilds on resize should be scoped/efficient, and large lists virtualized ([Module 21](../21%20Performance/README.md)). The concern is **UX fidelity** to desktop conventions. Menus/shortcuts/hover add negligible cost.

## Advantages / Disadvantages

- **+** Native desktop feel (windows/menus/keyboard/mouse), power-user efficiency (shortcuts/keyboard), platform-appropriate conventions, one codebase adapting per OS.
- **−** Real work beyond mobile (windowing/menus/shortcuts/right-click/per-OS HIG), plugin reliance (`window_manager`/`tray_manager`), per-OS adaptation + testing.

## Interview Questions

1. **🟢 Why doesn't a mobile UI work on desktop?** — Desktop has resizable windows, menu bars, keyboard-first workflows, mouse/right-click, and multi-window — a fixed phone UI provides none and feels foreign.
2. **🟢 How do you add a native menu bar in Flutter?** — `PlatformMenuBar` with `PlatformMenu`/`PlatformMenuItem` — rendering the system top menu bar on macOS and an in-window menu on Windows/Linux, wired to actions/shortcuts.
3. **🟡 How do keyboard shortcuts work, and what's the platform gotcha?** — Via `Shortcuts`/`Actions` (or `CallbackShortcuts`), mapped in the menu bar; use platform-aware modifiers (Cmd on macOS, Ctrl on Windows/Linux).
4. **🟡 What window-management behaviors do desktop apps need?** — Resizable + min size + remembered size/position (via `window_manager`), possibly multi-window + system tray — with responsive layout inside.
5. **🟡 What mouse conventions must you support?** — Hover states + cursors, right-click context menus, scroll wheel, visible scrollbars, double-click/drag where relevant.
6. **🔴 How do you adapt to per-OS HIG?** — Branch conventions (menu placement/window controls/shortcut modifiers) and optionally use OS-styled widget packages (`macos_ui`/`fluent_ui`/`yaru`) — one codebase, platform-aware.
7. **🔴 Why enforce a minimum window size + remember position?** — To keep the responsive UI from breaking when resized small, and to respect the desktop expectation that windows restore where/how you left them.

## Senior Engineer Tips

- Add a native menu bar with shortcut-annotated items + full keyboard traversal early; desktop power users live in menus and shortcuts, and it's the clearest "this is a real desktop app" signal.
- Enforce a min window size, remember size/position, and design responsively; a fixed phone-sized or breaking-on-resize window is the instant "ported mobile app" tell.
- Use platform-aware modifiers (Cmd vs Ctrl) and adapt per-OS conventions/styling; the same Ctrl+S on macOS or a Windows-style menu on macOS feels immediately wrong to users of that OS.

## Architect Perspective

Desktop UX & windowing is what makes a Flutter Desktop app belong on the desktop: resizable windows + responsive layout, native menus, keyboard-first workflows, mouse/right-click conventions, and per-OS HIG adaptation. It's the responsive/adaptive discipline extended to the desktop's window+menu+keyboard+mouse context — and combined with fit/native-integration/packaging, it separates a genuine desktop product from a phone UI stretched to a window ([Module 24](../24%20Responsive%20UI/README.md), [Module 25](../25%20Adaptive%20UI/README.md), [03_native_integration_desktop.md](03_native_integration_desktop.md)).

## Summary

- Desktop UX = resizable windows (responsive + min size + remembered position + multi-window/tray via `window_manager`/`tray_manager`), a native menu bar (`PlatformMenuBar`, system bar on macOS), keyboard-first workflows (`Shortcuts`/`Actions` + focus traversal), and mouse conventions (hover/cursor/right-click/scrollbars).
- Adapt per-OS HIG (Cmd vs Ctrl, menu placement/controls, styling via `macos_ui`/`fluent_ui`/`yaru`) + desktop density; selectable text.
- Not a phone UI in a window — bridge to desktop conventions.

## Revision Notes

- Window: responsive layout + min size + remembered size/position (+ maximized) via `window_manager`; multi-window + system tray (`tray_manager`); initial size/title.
- Menu bar: `PlatformMenuBar`/`PlatformMenu`/`PlatformMenuItem` (native; system top bar on macOS) mapped to shortcuts. Keyboard: `Shortcuts`/`Actions`/`CallbackShortcuts` (platform modifier: Cmd macOS / Ctrl Win-Linux), focus traversal (`FocusTraversalGroup`, Tab/Enter/Esc).
- Mouse: hover/cursor (`MouseRegion`), right-click context menus (`onSecondaryTap`/`ContextMenuController`), scroll wheel, `Scrollbar`, double-click/drag. Text: `SelectionArea`/`SelectableText`. Per-OS HIG: adapt menus/controls/shortcuts/styling (`macos_ui`/`fluent_ui`/`yaru`) + desktop density.

## Practice Questions

1. What desktop conventions must you add beyond a mobile UI?
2. How do menus + keyboard shortcuts + focus work, and the platform-modifier gotcha?
3. How do you adapt UX per OS (macOS vs Windows vs Linux)?

## Coding Questions

1. Set a min window size + remember size/position with `window_manager`.
2. Build a `PlatformMenuBar` with shortcut-annotated items (platform-aware modifiers).
3. Add hover cursor + a right-click context menu + a visible scrollbar.

## Mini Project

**Desktop-idiomatic UX (Flutter Desktop):** Make an app feel native on desktop: window management (responsive layout + min size + remembered size/position via `window_manager`), a native menu bar (`PlatformMenuBar` File/Edit/View with shortcut-annotated items, platform-aware Cmd/Ctrl), keyboard focus traversal + Esc/Enter, mouse conventions (hover/cursor + right-click context menu + visible scrollbars), selectable text, and per-OS adaptation (modifiers/menu placement/optional OS-styled widgets). Acceptance: resizable window with min size + remembered position; native menu bar + shortcuts (correct modifiers) discoverable via menus; keyboard traversal + right-click menu + hover/cursor/scrollbars; selectable text; per-OS conventions adapted; not a fixed phone UI.
