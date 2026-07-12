# List & Scroll Performance

> Smooth lists come from **laziness** (`.builder`/slivers build only visible items), **cheap item builds** (const, sized images, light widgets), **pagination** (load more near the end), and **isolation** (`RepaintBoundary`, keys) — the most common real-world performance surface.

## Introduction

Feeds/lists are where users feel jank most (continuous scrolling). This file synthesizes the list-relevant techniques: lazy building, cheap items, pagination/infinite scroll, image handling, and repaint isolation — building on scrolling widgets ([07 · scrolling_and_slivers](../07%20Widgets/05_scrolling_and_slivers.md)) and the rebuild/raster/memory files.

## Why this concept exists

A list can violate every budget at once: building thousands of items (UI), heavy item paints (raster), full-res images (memory). Lazy, cheap, paginated, isolated lists keep all three in check while scrolling — a distinct, high-impact skill.

## Real-world analogy

A **sushi conveyor belt**: plates (items) are prepared just as they reach you (lazy), each plate is quick to make (cheap items), more are ordered as the belt empties (pagination), and heavy dishes are pre-plated/cached so the chef isn't overwhelmed (image/repaint isolation).

## Problem Statement

A 10k-item image feed stutters while scrolling and grows in memory. You'll make it lazy, keep items cheap (sized images, `const`, keys), paginate, and isolate expensive items — verified via frame timings.

## Internal Working

```mermaid
flowchart TD
    List[.builder / Sliver] --> Lazy[build only visible + cacheExtent]
    Lazy --> Item[cheap item: const + sized image + light widgets]
    Scroll[near end] --> Page[load more (pagination)]
    Heavy[expensive item] --> Boundary[RepaintBoundary + keys]
```

- **Laziness (mandatory)**: `ListView.builder`/`GridView.builder`/slivers build items **on demand** as they scroll into view (bounded memory/CPU); never eager `ListView(children: [huge list])` ([07 · scrolling_and_slivers](../07%20Widgets/05_scrolling_and_slivers.md)).
- **Cheap `itemBuilder`**: keep items **light** — `const` where possible, extract item **widget classes**, hoist stable callbacks (avoid per-item closures), avoid heavy layout/effects per item.
- **Images**: size decodes (`cacheWidth`/`cacheHeight`), use disk caching (`cached_network_image`), reserve fixed dimensions (no layout jumps) — image memory is the top list OOM cause ([04_memory_optimization.md](04_memory_optimization.md), [07 · images](../07%20Widgets/07_images_and_assets.md)).
- **Pagination / infinite scroll**: load more when nearing the end (scroll listener / `infinite_scroll_pagination`); never fetch/hold everything.
- **`cacheExtent`**: tune how much off-screen area is pre-built (smoother scroll vs more work) — default is usually fine.
- **Keys**: stable `ValueKey`s for dynamic/reorderable lists so element/state maps correctly ([06 · widgets_elements_render_objects](../06%20Flutter%20Fundamentals/04_widgets_elements_render_objects.md)).
- **`RepaintBoundary`**: isolate expensive/animating items so scrolling one doesn't repaint others ([03_jank_and_raster.md](03_jank_and_raster.md)).
- **`addAutomaticKeepAlives`/`AutomaticKeepAliveClientMixin`**: keep specific items alive when needed (costs memory — use sparingly).

## Memory Representation

Lazy lists keep only visible (+ `cacheExtent`) items in the element/render trees, recycling off-screen ones → bounded memory. Full-res images or keep-alives inflate it ([02 · memory_and_gc](../02%20Advanced%20Dart/13_memory_and_gc.md)).

## Compiler Behavior

`const` items reduce rebuild/allocation. Otherwise not compile-time.

## Runtime Behavior

The viewport requests items in range + cache extent, disposing off-screen ones; heavy `itemBuilder` work or full-res image decodes during scroll cause jank on the relevant thread.

## Flutter Engine Behavior

Scrolling drives repeated layout/paint of the viewport + image decode (IO thread) + raster; smoothness depends on cheap items + sized images ([10 · threading_model](../10%20Flutter%20Architecture/03_threading_model.md)).

## Dart VM Behavior

Not applicable beyond allocation/GC from item building.

## Examples

```dart
import 'package:flutter/material.dart';

class Feed extends StatefulWidget {
  const Feed({super.key});
  @override State<Feed> createState() => _FeedState();
}
class _FeedState extends State<Feed> {
  final _controller = ScrollController();
  final List<String> _items = List.generate(30, (i) => 'Item $i');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore); // pagination
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); } // no leaks

  void _maybeLoadMore() {
    if (!_loading && _controller.position.pixels >
        _controller.position.maxScrollExtent - 400) {
      _loading = true;
      Future.delayed(const Duration(milliseconds: 300), () { // simulate fetch
        setState(() { _items.addAll(List.generate(30, (i) => 'Item ${_items.length + i}')); _loading = false; });
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListView.builder( // LAZY
        controller: _controller,
        itemCount: _items.length,
        itemBuilder: (context, index) => _FeedItem(
          key: ValueKey(_items[index]),   // stable key
          title: _items[index],
        ),
      );
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => RepaintBoundary( // isolate item repaints
        child: ListTile(
          leading: const SizedBox(         // reserve space; size image decode in real use
            width: 56, height: 56, child: ColoredBox(color: Colors.black12),
          ),
          title: Text(title),
        ),
      );
}
```

## Diagrams

```mermaid
flowchart LR
    Eager[ListView(children:[10k]) ] --> Jank[build all -> jank/memory]
    Builder[ListView.builder + cheap items + paging] --> Smooth[bounded, smooth]
    FullImg[full-res images] --> OOM[memory spikes]
    Sized[sized decodes + disk cache] --> OK[bounded]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Eager `ListView(children:[huge])` | Builds all → jank/memory | `ListView.builder`/slivers |
| Heavy work/closures in `itemBuilder` | Per-item cost during scroll | `const` items, hoist callbacks, light widgets |
| Full-res images in items | Memory spikes/OOM | Size decodes + disk cache |
| No pagination | Fetch/hold everything | Load more near the end |
| No/unstable keys on dynamic lists | State jumps on reorder | Stable `ValueKey`s |
| Overusing keep-alives | Memory bloat | Use sparingly, only where needed |

## Best Practices

- **Always `.builder`/slivers** for growable lists; never eager children for large data.
- Keep `itemBuilder` **cheap**: `const`, item **widget classes**, hoisted callbacks, minimal layout/effects.
- **Size image decodes** + disk-cache; reserve fixed item/image dimensions (no jumps).
- **Paginate** (load near end); avoid holding all data in memory.
- Use **stable keys** for dynamic lists; **`RepaintBoundary`** around expensive/animating items; keep-alives only where necessary.
- **Profile scrolling** (UI + raster) on a low-end device in release.

## Performance

Laziness bounds CPU/memory to the visible window; cheap items + sized images keep per-frame cost under budget; pagination bounds data. Jank almost always traces to heavy items or full-res images during scroll ([01_profiling_and_frame_budget.md](01_profiling_and_frame_budget.md)).

## Advantages / Disadvantages

- **+** Smooth, memory-bounded lists at any size; instant first paint; scalable feeds.
- **−** Pagination/keys/boundary bookkeeping; keep-alive memory tradeoffs; image sizing vs quality.

## Interview Questions

1. **🟢 Why use `ListView.builder` for large lists?** — It builds items lazily (only visible + cache extent), bounding CPU/memory; eager `children` builds everything.
2. **🟢 What makes list scrolling janky?** — Heavy `itemBuilder` work, full-res images, and per-item allocations during scroll.
3. **🟡 How do you keep items cheap?** — `const`, extract item widget classes, hoist stable callbacks, size images, minimize layout/effects.
4. **🟡 How do you implement infinite scroll?** — Load more when the scroll position nears the end (listener/pagination package); never fetch all.
5. **🟡 Why stable keys on dynamic lists?** — So elements/state map to the right items across insertions/reorders (no state jumping).
6. **🔴 When and why use `RepaintBoundary`/keep-alives in lists?** — Boundary to isolate expensive/animating item repaints; keep-alive to preserve specific item state — both cost memory, so use judiciously.
7. **🔴 What's the top list OOM cause and fix?** — Full-resolution image decodes; fix with `cacheWidth`/`cacheHeight` + disk caching.

## Senior Engineer Tips

- Treat eager `children:[]` for data-driven lists as a bug; default to `.builder`/slivers.
- Profile scroll on a **low-end device in release**; high-end debug hides item/image cost.
- The usual jank fix is "cheaper items + sized images + fewer per-item allocations," not exotic tricks.

## Architect Perspective

Lists are the highest-traffic performance surface in feed/commerce/media apps. A lazy, cheap-item, paginated, image-sized, repaint-isolated list pattern (behind a reusable item widget + pagination utility) is a core scalability decision, tying together rendering internals, memory, and networking/caching ([Modules 09, 16, 15](../09%20Rendering%20Pipeline/README.md)).

## Summary

- Lazy `.builder`/slivers + cheap items + sized images + pagination + isolation (keys/`RepaintBoundary`).
- Bounds CPU/memory to the visible window; jank traces to heavy items/full-res images.
- Profile scrolling in release on low-end devices; verify improvements.

## Revision Notes

- Lazy `.builder`/slivers (never eager for large data); cheap `itemBuilder` (const, widget classes, hoisted callbacks).
- Size image decodes + disk cache + fixed dimensions; paginate near end.
- Stable keys; `RepaintBoundary` for expensive/animating items; keep-alives sparingly.
- Profile scroll in release/low-end; top OOM = full-res images.

## Practice Questions

1. Why is `.builder` required for a 10k list?
2. What are the top two causes of list jank and their fixes?
3. When do you add `RepaintBoundary`/keep-alives to items?

## Coding Questions

1. Build a lazy paginated feed (load near end) with cheap `const` items + stable keys.
2. Size image decodes for a grid and measure memory reduction.
3. Isolate an animating item with `RepaintBoundary`; verify with Highlight Repaints.

## Mini Project

**Smooth feed (Flutter):** Build a 10k-item image feed with `ListView.builder`, cheap `const` item widgets, sized/disk-cached images, pagination near the end, stable keys, and `RepaintBoundary` on items. Profile scrolling (UI + raster + memory) before/after on a low-end release build. Acceptance: lazy + paginated; bounded memory; smooth scroll; measured improvement; no leaks (controller disposed); runs.
