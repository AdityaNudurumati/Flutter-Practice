# PDF Generation Basics (The `pdf` Package Model)

> The `pdf` package builds documents with its **own widget tree** — `pw.Widget` (not Flutter's `Widget`) — laid out onto fixed-size **pages**: you create a `pw.Document`, `addPage()` a `pw.Page` (or `MultiPage`) whose `build` returns `pw.*` widgets (`Text`, `Column`, `Row`, `Container`, `Table`), style with `pw.TextStyle`/`PdfColor`, and finally `doc.save()` to bytes. It *looks* like Flutter but is a **parallel API** rendered to paginated, print-resolution output — so import it prefixed (`as pw`) and don't mix it with `material`/`widgets`.

## Introduction

Before layouts or printing, you must grasp the `pdf` package's model: a document of pages, each built from `pw.*` widgets, producing bytes. This file covers the core objects, text/styling, the Flutter-lookalike-but-separate API, and generating a first document — the foundation for everything else.

## Why this concept exists

A PDF is a fixed-layout, paginated, print-oriented format — fundamentally different from Flutter's dynamic screen UI. The `pdf` package provides a familiar widget-style API (so Flutter devs feel at home) but targets pages/points/print resolution, with its own layout/pagination rules. The separation avoids conflating on-screen widgets with document widgets.

## Real-world analogy

Flutter widgets are for a **living, resizable display board**; `pw.*` widgets are for **typesetting a printed page** — same vocabulary (columns, rows, text), different medium with fixed page sizes and margins. It's like using a word processor whose toolbar mirrors your design app's, but the output is paper, not a screen.

## Problem Statement

Generate a one-page PDF with a title, a styled paragraph, and a two-column layout, then produce its bytes to save/share. You'll create a `Document`, add a `Page` with `pw.*` widgets, style text, and `save()`.

## Internal Working

```mermaid
flowchart TD
    Doc[pw.Document] --> Add[doc.addPage(pw.Page/MultiPage)]
    Add --> Build[build: (context) => pw.Widget tree]
    Build --> Widgets[pw.Text / Column / Row / Container / Table ...]
    Widgets --> Style[pw.TextStyle / PdfColor / pw.EdgeInsets]
    Doc --> Save[doc.save() -> Uint8List (PDF bytes)]
```

- **`pw.Document`**: the container; you `addPage(...)` one or more pages, then `await doc.save()` → `Uint8List` (the PDF bytes) to write/share/print.
- **Pages**: `pw.Page` (single, fixed page) vs **`pw.MultiPage`** (auto-paginates overflowing content across pages — essential for long content/tables — [02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md)). Set `pageFormat` (`PdfPageFormat.a4`, `.letter`), `margin`, orientation.
- **`pw.*` widgets** mirror Flutter: `Text`, `RichText`, `Column`, `Row`, `Container`, `Padding`, `Center`, `Expanded`, `SizedBox`, `Divider`, `Table`, `Wrap`, `Stack`. **Not interchangeable** with `material`/`widgets` — import `package:pdf/widgets.dart as pw`.
- **Styling**: `pw.TextStyle(fontSize, fontWeight, color: PdfColors.blue900, font: ...)`, `PdfColor`/`PdfColors`, `pw.EdgeInsets`, `pw.BoxDecoration`. Units are **PDF points** (72/inch), not logical pixels.
- **`build` callback**: `(pw.Context context) => ...` returns the page's widget tree; `MultiPage` build returns a `List<pw.Widget>` it flows across pages.
- **Fonts**: the default font is limited (often no bold/unicode); load a real font for proper text ([02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md)).
- **Async + bytes**: `save()` is async; the resulting bytes are what you persist ([Module 34](../34%20File%20Handling/README.md)) or hand to `printing` ([03_viewing_and_printing.md](03_viewing_and_printing.md)).

## Memory Representation

The document builds an in-memory widget tree, then serializes to a `Uint8List`. Large docs (many pages/images) hold significant memory during generation — generate off the UI thread for big ones ([04_data_driven_documents.md](04_data_driven_documents.md)).

## Compiler Behavior

Not applicable; `pw.*` is a normal Dart API.

## Runtime Behavior

`save()` lays out all pages and serializes to bytes (can be slow for large/complex docs). `MultiPage` computes pagination at build time.

## Flutter Engine Behavior

None directly — the `pdf` package renders to the PDF format, not the Flutter engine. (Viewing a PDF on screen is a separate concern — [03_viewing_and_printing.md](03_viewing_and_printing.md).)

## Dart VM Behavior

Pure Dart layout/serialization; heavy generation is CPU-bound → offload to an isolate for large docs ([02 · isolates](../02%20Advanced%20Dart/04_isolates.md)).

## Examples

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;      // NOTE: separate widget API, prefixed `pw`
import 'dart:typed_data';

Future<Uint8List> buildSimplePdf() async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Report Title',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900)),
            pw.SizedBox(height: 12),
            pw.Text('This is a styled paragraph rendered to a PDF page. '
                'The pw.* widgets mirror Flutter but target print output.'),
            pw.SizedBox(height: 16),
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Left column')),
              pw.Expanded(child: pw.Text('Right column')),
            ]),
          ],
        );
      },
    ),
  );

  return doc.save();                            // async -> PDF bytes (save/share/print)
}
```

## Diagrams

```mermaid
flowchart LR
    Data[content] --> PW[pw.* widget tree]
    PW --> Page[pw.Page / MultiPage]
    Page --> Save[doc.save() -> bytes]
    Save --> Use[save / share / print]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Mixing Flutter widgets with `pw.*` | Different, incompatible APIs | Use only `pw.*` (import `as pw`) |
| Single `Page` for long content | Overflow clipped | Use `pw.MultiPage` (auto-paginate) |
| Relying on the default font | Missing bold/unicode/glyphs | Load a real font |
| Assuming logical pixels | PDF uses points (72/in) | Size in points; use `PdfPageFormat` |
| Generating huge docs on UI thread | Jank/freeze | Offload to an isolate |
| Forgetting `await save()` | Bytes not produced | `await doc.save()` |

## Best Practices

- Import the PDF API prefixed (`as pw`) and use **only `pw.*`** widgets; never mix with `material`/`widgets`.
- Use **`MultiPage`** for anything that can overflow; set `pageFormat`/`margin` explicitly; think in **points**.
- **Load real fonts** for correct bold/unicode; keep the widget tree simple/reusable.
- Treat `save()` as **async + potentially heavy** — **offload large docs to an isolate**; hand the bytes to file/print/share layers.

## Performance

Generation is CPU/memory-bound and scales with pages/images/complexity. Small docs are instant; large ones (long tables, many images) should be built in an isolate to avoid jank, and images should be sized/compressed ([02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md)).

## Advantages / Disadvantages

- **+** Familiar widget-style API, precise paginated print output, cross-platform, produces standard PDF bytes.
- **−** Separate/parallel API (not Flutter widgets), points-not-pixels, default-font limitations, memory/CPU for large docs, pagination nuances.

## Interview Questions

1. **🟢 Are `pdf` package widgets the same as Flutter widgets?** — No — `pw.*` is a separate, parallel widget API for paginated print output; import it `as pw` and don't mix with `material`/`widgets`.
2. **🟢 What does `doc.save()` return?** — The PDF as a `Uint8List` (bytes) you save, share, or print — it's async.
3. **🟡 `Page` vs `MultiPage`?** — `Page` is a single fixed page (content can overflow/clip); `MultiPage` auto-paginates overflowing content across pages.
4. **🟡 Why load a custom font?** — The default font is limited (no bold/unicode/many glyphs); a real font ensures correct text rendering.
5. **🟡 What units does the `pdf` package use?** — PDF points (72 per inch) via `PdfPageFormat`, not logical pixels.
6. **🔴 When and why offload generation to an isolate?** — For large/complex docs — layout+serialization is CPU-bound and would jank the UI thread.
7. **🔴 What's the overall generation flow?** — Build a `pw.*` tree → add to `pw.Page`/`MultiPage` in a `Document` → `save()` to bytes → hand to file/print/share.

## Senior Engineer Tips

- Keep the mental separation crisp: `pw.*` for documents, Flutter widgets for screens; a `pw` prefix everywhere prevents accidental mixing.
- Default to `MultiPage` and load a font on day one — the two most common "it worked in the demo, broke in prod" PDF bugs are clipped content and missing glyphs.
- Wrap generation so large docs go to an isolate transparently; users notice a frozen UI while a 50-page report renders.

## Architect Perspective

The `pdf` package is a document-rendering domain with its own model; treating it as such (separate `pw.*` trees, reusable builders, isolate-offloaded generation, bytes handed to file/print layers) keeps document generation clean and testable, and sets up data-driven templates. It's the generation half; the `printing` package is the presentation half ([03_viewing_and_printing.md](03_viewing_and_printing.md), [04_data_driven_documents.md](04_data_driven_documents.md)).

## Summary

- `pdf` package: `pw.Document` + `addPage(pw.Page/MultiPage)` whose `build` returns `pw.*` widgets; style with `pw.TextStyle`/`PdfColor`; `save()` → bytes.
- Separate API from Flutter (import `as pw`), points not pixels, `MultiPage` for overflow, load real fonts.
- Generation is CPU/memory-bound — offload large docs; hand bytes to file/print/share.

## Revision Notes

- `import 'package:pdf/widgets.dart' as pw;` — `pw.Document`, `pw.Page`/`pw.MultiPage`, `pw.Text/Column/Row/Container/Table`.
- Style: `pw.TextStyle(fontSize, fontWeight, color)`, `PdfColors`, `pw.EdgeInsets`; `PdfPageFormat.a4/.letter`; units = points.
- `await doc.save()` → `Uint8List`; `MultiPage` for pagination; custom fonts for bold/unicode; isolate for big docs.

## Practice Questions

1. Why can't you use Flutter widgets in a PDF `build`?
2. When must you use `MultiPage`?
3. Why load a custom font?

## Coding Questions

1. Generate a one-page A4 PDF with a styled title + paragraph, returning bytes.
2. Add a two-column row layout with `Expanded`.
3. Offload generation to an isolate via `compute`.

## Mini Project

**First PDF (Flutter):** Generate a styled one-page A4 document (title, paragraph, two-column layout) with explicit margins/format, returning bytes via `save()`, and offload generation to an isolate. Acceptance: uses only `pw.*` (prefixed); A4 + margins set; styled text; returns `Uint8List`; generation off the UI thread; renders correctly (verify by saving/opening).
