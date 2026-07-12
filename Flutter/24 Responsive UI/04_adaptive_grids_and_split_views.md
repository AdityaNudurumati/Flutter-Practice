# Adaptive Grids & Split Views (Master-Detail)

> On large screens, reflow content into **responsive grids** (`SliverGridDelegateWithMaxCrossAxisExtent`) and switch single-page navigation into **master-detail split views** (list + detail side-by-side) — the two highest-impact large-screen patterns.

## Introduction

The signature tablet/desktop upgrades: grids that pick their column count by width, and master-detail layouts that show list + detail together instead of navigating between them. This file covers responsive grids and the split-view (master-detail) pattern, including how navigation adapts.

## Why this concept exists

Wide screens waste space with phone layouts (single column, full-screen detail). Grids fill width with more columns; master-detail uses the extra width to show context (list) + content (detail) simultaneously — the expected large-screen experience (mail, settings, file browsers).

## Real-world analogy

A **filing cabinet vs a desk**: on a phone you pull one folder at a time (navigate to detail); on a wide desk you lay the index (list) on the left and the open document (detail) on the right — see both at once (master-detail). A grid is arranging items to fill the desk's width in as many columns as fit.

## Problem Statement

A products screen: a grid whose columns grow with width, and — on tablet/desktop — a master-detail where tapping a list item shows its detail in the right pane (instead of pushing a new screen on phones). You'll build a responsive grid and an adaptive split view.

## Internal Working

```mermaid
flowchart TD
    Width[available width] --> Grid[GridView: max-extent delegate -> columns fit width]
    Width --> BP{expanded width?}
    BP -->|no (compact)| Nav[tap -> push detail screen]
    BP -->|yes (expanded)| Split[list pane + detail pane side-by-side]
    Split --> Sel[selection state drives detail pane]
```

- **Responsive grid**: prefer `GridView.builder` with **`SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent:)`** — it fits as many columns as the width allows (columns auto-adjust) — over a fixed `crossAxisCount` (which doesn't adapt). Set `childAspectRatio`/spacing.
- **Master-detail (split view)**:
  - **Compact**: a list; tapping **navigates** to a detail screen ([12 · imperative_navigation](../12%20Navigation/02_imperative_navigation.md)).
  - **Expanded**: a `Row` with a **list pane** (fixed/flex width) + **detail pane** (`Expanded`), both visible; tapping updates a **selection** that the detail pane renders — no navigation.
  - Decide the split by width (`LayoutBuilder`/`MediaQuery` — [02_mediaquery_vs_layoutbuilder.md](02_mediaquery_vs_layoutbuilder.md)); keep **selection state** lifted so both layouts share it ([11](../11%20State%20Management/README.md)).
- **Navigation adapts**: bottom nav (compact) → **navigation rail** (expanded); list-push → split-select.
- Route-integrated version: `go_router` `StatefulShellRoute` for deep-linkable panes ([13 · shell_routes_and_nested](../13%20Routing/04_shell_routes_and_nested.md)).

## Memory Representation

Grid uses lazy building (only visible cells) — bounded ([07 · scrolling_and_slivers](../07%20Widgets/05_scrolling_and_slivers.md)). Split view keeps both panes alive; selection state is small/lifted.

## Compiler Behavior / Runtime Behavior

Layout branches by width; grid recomputes columns on resize; the detail pane rebuilds on selection change (scope it).

## Flutter Engine Behavior / Dart VM Behavior

Not applicable.

## Examples

```dart
import 'package:flutter/material.dart';

// Responsive grid: columns fit the width via max cross-axis extent
class ProductGrid extends StatelessWidget {
  final List<String> items;
  const ProductGrid({super.key, required this.items});
  @override
  Widget build(BuildContext context) => GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200, // as many ~200px columns as fit
          childAspectRatio: 3 / 4, mainAxisSpacing: 8, crossAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => Card(child: Center(child: Text(items[i]))),
      );
}

// Master-detail: split on wide screens, navigate on narrow
class Catalog extends StatefulWidget {
  const Catalog({super.key});
  @override State<Catalog> createState() => _CatalogState();
}
class _CatalogState extends State<Catalog> {
  final _items = List.generate(20, (i) => 'Item $i');
  String? _selected; // lifted selection shared by both layouts

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final expanded = c.maxWidth >= 900;
      final list = ListView(
        children: _items.map((it) => ListTile(
          title: Text(it),
          selected: it == _selected,
          onTap: () {
            setState(() => _selected = it);
            if (!expanded) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _Detail(it))); // compact: navigate
            }
          },
        )).toList(),
      );

      if (!expanded) return Scaffold(appBar: AppBar(title: const Text('Catalog')), body: list);

      // Expanded: list pane + detail pane side-by-side (no navigation)
      return Scaffold(
        body: Row(children: [
          SizedBox(width: 320, child: list),
          const VerticalDivider(width: 1),
          Expanded(child: _selected == null
              ? const Center(child: Text('Select an item'))
              : _Detail(_selected!)),
        ]),
      );
    });
  }
}
class _Detail extends StatelessWidget {
  final String item; const _Detail(this.item);
  @override Widget build(_) => Scaffold(appBar: AppBar(title: Text(item)), body: Center(child: Text('Detail: $item')));
}
```

## Diagrams

```mermaid
flowchart LR
    Compact[phone] --> ListPush[list -> push detail screen]
    Expanded[tablet/desktop] --> SplitPane[list pane + detail pane (shared selection)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Fixed `crossAxisCount` grid | Doesn't adapt to width | `SliverGridDelegateWithMaxCrossAxisExtent` |
| Separate state for list vs split layouts | Selection lost on resize | Lift shared selection state |
| Eager grid children | Jank/memory | `GridView.builder` (lazy) |
| Split view on narrow screens | Cramped panes | Switch to navigate on compact |
| Detail pane rebuilding whole screen | Perf | Scope detail-pane rebuild to selection |
| No empty/placeholder detail state | Blank pane | Show "select an item" placeholder |

## Best Practices

- Use **max-cross-axis-extent grids** so column count adapts to width (over fixed counts); lazy `GridView.builder`.
- Build **master-detail**: navigate on compact, split panes on expanded; **lift the selection state** so both share it.
- Adapt **navigation** (bottom nav → rail) alongside the layout switch.
- Provide a **placeholder** for the empty detail pane; scope detail rebuilds to selection.
- For deep-linkable panes, use `go_router` `StatefulShellRoute` ([13](../13%20Routing/04_shell_routes_and_nested.md)).

## Performance

Lazy grids bound memory/CPU; split view keeps both panes alive (fine for two panes) — scope detail rebuilds. Resize recomputes columns/branch cheaply ([21 · list_and_scroll_performance](../21%20Performance/05_list_and_scroll_performance.md)).

## Advantages / Disadvantages

- **+** Uses large-screen space well (more columns, context+content), expected tablet/desktop UX, one codebase.
- **−** More layout branches + shared-state management; split view adds complexity vs single-page; must handle empty/selection states.

## Interview Questions

1. **🟢 How do you make a grid's columns adapt to width?** — Use `GridView.builder` with `SliverGridDelegateWithMaxCrossAxisExtent` (fits as many columns as the width allows) instead of a fixed `crossAxisCount`.
2. **🟢 What is a master-detail (split view)?** — A layout showing a list (master) and the selected item's detail side-by-side on large screens, instead of navigating to a separate detail screen.
3. **🟡 How does navigation differ between compact and expanded in master-detail?** — Compact: tapping pushes a detail screen; expanded: tapping updates a selection that the detail pane renders (no navigation).
4. **🟡 Why lift the selection state?** — So the same selection drives both the navigate-based (compact) and split (expanded) layouts, surviving resize between them.
5. **🟡 Why prefer max-extent over fixed column count?** — Column count then adapts to any width automatically; fixed counts don't respond to size.
6. **🔴 How do you make split-view panes deep-linkable?** — Use `go_router`'s `StatefulShellRoute` (nested navigators + URLs) so each pane/route is addressable.
7. **🔴 How do you keep the split view performant?** — Lazy grid, scoped detail-pane rebuilds on selection, and placeholders for empty state.

## Senior Engineer Tips

- Standardize a reusable adaptive-scaffold (list↔split + nav bar↔rail) driven by a breakpoint helper; screens plug content in.
- Keep the master-detail selection in a shared store/state so resizing between phone/tablet doesn't lose it.
- Use max-extent grids by default; they "just work" across sizes without magic column numbers.

## Architect Perspective

Responsive grids + master-detail are the defining large-screen patterns; combined with adaptive navigation and deep-linkable shells ([13](../13%20Routing/04_shell_routes_and_nested.md)), they deliver a first-class tablet/desktop/web experience from one codebase. Centralizing the adaptive scaffold + shared selection state is the scalable way to apply them across an app ([01_responsive_fundamentals.md](01_responsive_fundamentals.md)).

## Summary

- Responsive grids (max-cross-axis-extent, lazy) fill width with adaptive columns.
- Master-detail: navigate on compact, split panes on expanded, with lifted shared selection and adaptive navigation.
- Provide placeholders, scope detail rebuilds, and consider `StatefulShellRoute` for deep-linkable panes.

## Revision Notes

- Grid: `GridView.builder` + `SliverGridDelegateWithMaxCrossAxisExtent` (adaptive columns), lazy.
- Master-detail: compact→push detail; expanded→list pane + `Expanded` detail; lift selection state.
- Adapt nav (bottom→rail); placeholder detail; scope detail rebuild.
- Deep-linkable panes → `go_router` `StatefulShellRoute` (Module 13).

## Practice Questions

1. Why use max-extent over fixed `crossAxisCount`?
2. How does master-detail behave differently on compact vs expanded?
3. Why lift the selection state?

## Coding Questions

1. Build a responsive grid with adaptive columns via max cross-axis extent.
2. Build a master-detail that navigates on narrow and splits on wide (shared selection).
3. Add adaptive navigation (bottom nav ↔ rail) to the split scaffold.

## Mini Project

**Adaptive catalog (Flutter):** Build a catalog with a responsive product grid (adaptive columns) and a master-detail layout — navigate to detail on phones, split panes on tablet/desktop — with lifted selection state, adaptive navigation (bottom nav ↔ rail), and an empty-detail placeholder. Acceptance: adaptive grid columns; split on wide/navigate on narrow; shared selection survives resize; runs across sizes.
