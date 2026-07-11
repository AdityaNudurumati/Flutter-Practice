# Layouts, Tables & Assets (Multi-Page, Fonts, Headers/Footers)

> Real documents need **paginated tables** (`pw.Table` / `TableHelper.fromTextArray` inside a **`MultiPage`** that flows rows across pages), **custom fonts** (load a `.ttf` as a `pw.Font` — the default font lacks bold/unicode), **images** (`pw.Image` from bytes, sized/compressed), and **repeating headers/footers with page numbers** (`MultiPage`'s `header`/`footer` callbacks give `context.pageNumber`/`pagesCount`). Getting these right is the difference between a demo and a printable report.

## Introduction

This file covers the layout building blocks for professional documents: tables that paginate, custom fonts (incl. a fallback/theme), embedding images/logos, and headers/footers with page numbering. These compose into invoices/reports ([data_driven_documents.md](data_driven_documents.md)).

## Why this concept exists

Business documents are long and structured: line-item tables spanning pages, a logo, branded fonts, and "Page X of Y" footers. `pw.MultiPage` handles pagination; `pw.Table` structures rows/columns; `pw.Font`/`ThemeData` handle typography; `pw.Image` embeds assets. Without these you get clipped content, tofu (□) glyphs, or unpaginated walls of text.

## Real-world analogy

This is **typesetting a printed report**: the table is your **spreadsheet grid** that automatically continues onto the next page when it runs off the bottom (pagination), the custom font is your **brand's typeface**, the logo is a **letterhead image**, and the header/footer is the **running title and page number** printed on every sheet.

## Problem Statement

Build a multi-page report with a logo header, a long line-item table that paginates with repeating column headers, branded fonts (incl. bold + a rupee/unicode symbol), and a footer showing "Page X of Y." You'll use `MultiPage`, `Table`, `Font`, `Image`, and header/footer callbacks.

## Internal Working

```mermaid
flowchart TD
    MP[pw.MultiPage] --> Header[header: (ctx) => logo + title (repeats)]
    MP --> Body[build: List<pw.Widget> flows across pages]
    Body --> Table[pw.Table / TableHelper.fromTextArray (rows paginate)]
    MP --> Footer[footer: (ctx) => 'Page ${ctx.pageNumber} of ${ctx.pagesCount}']
    Fonts[load .ttf -> pw.Font] --> Theme[pw.ThemeData(base/bold/italic + fontFallback)]
    Assets[image bytes] --> Img[pw.Image(pw.MemoryImage(bytes))]
```

- **`MultiPage`**: `build` returns a `List<pw.Widget>` that **flows across pages** automatically; `header`/`footer` callbacks (`(pw.Context ctx) => pw.Widget`) **repeat on every page**. Set `maxPages`, `pageTheme`.
- **Tables**: `pw.Table` (rows of `pw.TableRow` with `children`) or the convenience **`TableHelper.fromTextArray(headers:, data:)`** — inside `MultiPage`, table rows **paginate** and you can **repeat the header row** on each page. Control column widths (`columnWidths`, `FixedColumnWidth`/`FlexColumnWidth`), borders, cell alignment/padding.
- **Fonts**: load a `.ttf` (asset/bytes) → `pw.Font.ttf(byteData)`; supply **base/bold/italic** variants and a **`fontFallback`** list (for unicode/emoji/CJK) via a `pw.ThemeData` on the page theme so all text renders correctly (no tofu). `PdfGoogleFonts` (from `printing`) can fetch fonts.
- **Images**: `pw.Image(pw.MemoryImage(bytes))` (PNG/JPEG bytes) — **size/compress** before embedding (raw high-res images bloat the PDF + memory). SVG via `pw.SvgImage`.
- **Headers/footers + page numbers**: in the callbacks use `ctx.pageNumber` and `ctx.pagesCount` for "Page X of Y"; keep them lightweight (they render per page).
- **Layout widgets**: `pw.Column/Row/Wrap/Container/Padding/Align/Spacer/Divider`, `pw.Table`, `pw.GridView` — compose like Flutter but paginate within `MultiPage`.

## Memory Representation

Embedded images live in the document bytes — the biggest size driver; downscale/compress. Fonts are embedded once. Large tables build many widgets — fine, but generation cost scales with rows.

## Compiler Behavior

Not applicable.

## Runtime Behavior

`MultiPage` computes where content breaks at build time; repeating headers/footers render per page. Oversized images/many rows increase generation time and file size.

## Flutter Engine Behavior

None; rendered to PDF, not the engine.

## Dart VM Behavior

CPU-bound layout scales with content; offload large reports to an isolate ([02 · isolates](../02%20Advanced%20Dart/isolates_and_concurrency.md)).

## Examples

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

Future<Uint8List> buildReport(List<List<String>> rows, Uint8List logoBytes,
    Uint8List regular, Uint8List bold) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regular.buffer.asByteData()),
    bold: pw.Font.ttf(bold.buffer.asByteData()),
    // fontFallback: [pw.Font.ttf(unicodeFont)],  // for ₹/emoji/CJK
  );
  final doc = pw.Document(theme: theme);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    header: (ctx) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Sales Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Image(pw.MemoryImage(logoBytes), width: 60),          // sized logo
      ],
    ),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 10)),               // page X of Y
    ),
    build: (ctx) => [
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(                               // paginates + repeats header
        headers: ['#', 'Item', 'Qty', 'Amount'],
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
        columnWidths: {0: const pw.FixedColumnWidth(30)},
      ),
    ],
  ));

  return doc.save();
}
```

## Diagrams

```mermaid
flowchart LR
    Rows[many rows] --> MP[MultiPage]
    MP -->|overflow| P1[Page 1: header + rows 1..n + footer]
    MP --> P2[Page 2: header + rows n+1.. + footer]
    Logo[image bytes] --> Embed[pw.Image (sized/compressed)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Table in a single `Page` | Overflow clipped | `MultiPage` (rows paginate) |
| No repeating table header | Later pages confusing | Repeat header row in `MultiPage` |
| Default font for ₹/emoji/CJK | Tofu (□) glyphs | Load font + `fontFallback` |
| Embedding raw high-res images | Huge file/memory | Downscale/compress first |
| Heavy header/footer | Slow (renders per page) | Keep them light |
| No column widths | Ugly/overflowing columns | Set `columnWidths`/alignments |
| Big report on UI thread | Jank | Isolate |

## Best Practices

- Use **`MultiPage`** with **paginating tables** (`TableHelper.fromTextArray`) and **repeating headers**; set **column widths/alignments**.
- Load **base/bold/italic fonts + `fontFallback`** via `ThemeData` (no tofu); **size/compress images** before embedding.
- Add **headers/footers with `pageNumber`/`pagesCount`**; keep them lightweight; think in **points**.
- **Offload large reports** to an isolate; keep builders **reusable/composable** for [data_driven_documents.md](data_driven_documents.md).

## Performance

File size and generation time are dominated by **images** (compress!) and **row count**. Use `MultiPage` (not manual splitting), keep headers/footers cheap, and isolate large reports. Font embedding is a one-time cost.

## Advantages / Disadvantages

- **+** Professional paginated documents (tables/logos/fonts/page numbers), automatic pagination, print-quality.
- **−** Font/fallback setup, image-size discipline, pagination/column-width tuning, generation cost for large docs.

## Interview Questions

1. **🟢 How do you make a long table span multiple pages?** — Put it in a `MultiPage`; `pw.Table`/`TableHelper` rows paginate automatically (and you can repeat the header row).
2. **🟢 How do you add "Page X of Y"?** — In `MultiPage`'s `footer` callback use `context.pageNumber` and `context.pagesCount`.
3. **🟡 Why load custom fonts + a fallback?** — The default font lacks bold/unicode; base/bold/italic + `fontFallback` prevent missing-glyph "tofu" (₹, emoji, CJK).
4. **🟡 How do you embed a logo and keep the file small?** — `pw.Image(pw.MemoryImage(bytes))`, sized/compressed before embedding (images dominate file size).
5. **🟡 How do repeating headers/footers behave?** — They render on every page via the `header`/`footer` callbacks — keep them lightweight.
6. **🔴 What drives PDF file size and generation time?** — Primarily embedded image resolution and row/content count; compress images and isolate large reports.
7. **🔴 How do you control table columns?** — `columnWidths` (`Fixed`/`Flex`) and `cellAlignments`/borders on `Table`/`TableHelper`.

## Senior Engineer Tips

- Configure a `ThemeData` with proper fonts + fallback once and reuse it across all documents — it eliminates the most common (and embarrassing) PDF bug: missing glyphs.
- Always downscale/compress images before embedding; a single full-res photo can balloon a report to tens of MB.
- Build reusable header/footer/table components; every business document reuses the same letterhead + line-item grid.

## Architect Perspective

Layouts/tables/assets are the reusable component layer of document generation: a themed font setup, a standard header/footer, and a paginating table become the toolkit that data-driven templates compose. Keeping images compressed, generation isolate-offloaded, and components reusable makes reports maintainable and performant — feeding invoices/reports and the capstone service ([data_driven_documents.md](data_driven_documents.md), [pdf_integration.md](pdf_integration.md)).

## Summary

- `MultiPage` + paginating `Table`/`TableHelper` (repeating header) for long structured content; column widths/alignments.
- Custom base/bold/italic fonts + `fontFallback` (no tofu); sized/compressed `pw.Image`; header/footer with `pageNumber`/`pagesCount`.
- Images + row count drive size/time — compress + isolate; keep components reusable.

## Revision Notes

- `pw.MultiPage(header:, footer:, build: → List<pw.Widget>)`; tables paginate; repeat header row; `columnWidths`/`cellAlignments`.
- Fonts: `pw.Font.ttf` base/bold/italic + `fontFallback` via `pw.ThemeData`; `PdfGoogleFonts` optional.
- Images: `pw.Image(pw.MemoryImage(bytes))` sized/compressed; footer page numbers via `ctx.pageNumber`/`pagesCount`; isolate large docs.

## Practice Questions

1. How does a table paginate and keep its header on each page?
2. Why and how do you set up fonts with a fallback?
3. What most affects PDF file size, and how do you control it?

## Coding Questions

1. Build a `MultiPage` report with a logo header + "Page X of Y" footer.
2. Render a long paginating table with a repeating header + column widths.
3. Configure a `ThemeData` with base/bold fonts + fallback.

## Mini Project

**Multi-page report (Flutter):** Build a `MultiPage` A4 report: logo header, a long line-item `TableHelper` table that paginates with a repeating header and right-aligned numeric columns, branded fonts (base/bold + fallback for ₹), and a "Page X of Y" footer — with images compressed and generation isolate-offloaded. Acceptance: table spans pages with repeating header; fonts render bold + ₹ correctly; logo embedded + small; page numbers correct; reusable header/footer/table components; generated off the UI thread.
