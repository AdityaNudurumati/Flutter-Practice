# Data-Driven Documents (Invoices/Reports from Models & Templates)

> Real documents are **pure functions of your domain data**: `PdfDocument buildInvoice(Invoice data)` maps a typed model → a `pw.*` tree, so the same **reusable template** (header/line-item table/totals/footer components) produces any invoice/report. Keep generation **deterministic and side-effect-free** (data in → bytes out), **format numbers/dates/currency** correctly (locale + `intl`), handle **empty/overflow/long-text** cases, and **offload** heavy generation — then the document layer is testable and every report shares one branded template.

## Introduction

This file is where generation meets your app's data: turning `Invoice`/`Report` models into documents via reusable, composable templates. It covers the pure-function design, template composition, formatting/i18n, edge cases, and testing — the pattern that makes document generation maintainable rather than a pile of one-off builders.

## Why this concept exists

Businesses generate many documents from structured data, all sharing branding/layout. Hardcoding each is unmaintainable. Modeling generation as `data → pw.* tree` with shared components (letterhead, table, totals block) gives consistency, reuse, and testability — the same separation-of-concerns discipline as widgets-from-state, applied to documents.

## Real-world analogy

A template is a **mail-merge form letter**: the layout (letterhead, table grid, signature block) is fixed and branded; you **pour in the record's data** (customer, line items, totals) and out comes a personalized document. You don't redraw the letterhead for each customer — you reuse the form.

## Problem Statement

Generate a branded invoice from an `Invoice` model (customer, line items, tax, totals) that renders correctly whether it has 1 or 500 items, formats currency/dates by locale, handles a long customer name, and reuses the same header/footer/table as your reports. You'll design a pure template + shared components.

## Internal Working

```mermaid
flowchart TD
    Model[typed model: Invoice/Report] --> Template[buildInvoice(data): pure function]
    Template --> Components[reusable pw.* components]
    Components --> Header[letterhead(company, logo)]
    Components --> Table[lineItemsTable(items) — paginates]
    Components --> Totals[totalsBlock(subtotal, tax, total)]
    Components --> Footer[footer(pageNumber/pagesCount, terms)]
    Template --> Format[format money/dates via intl + locale]
    Template --> Save[save() -> bytes (offload if heavy)]
```

- **Pure function generation**: `Future<Uint8List> buildInvoice(Invoice data, {PdfPageFormat format})` — **no I/O, no globals**; same input → same bytes. Makes it testable and isolate-safe.
- **Reusable components**: factor the document into `pw.Widget` builders — `letterhead(company)`, `lineItemsTable(items)`, `totalsBlock(totals)`, `footer(...)` — shared across invoices/receipts/reports for one branded look ([02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md)).
- **Formatting/i18n**: format **currency** (`NumberFormat.currency(locale, symbol)`), **dates** (`DateFormat`), and numbers with **`intl`** — never `toString()` raw doubles for money; align numeric columns; respect the document's locale.
- **Data mapping**: map model → rows/cells explicitly; compute derived values (subtotal/tax/total) either in the model/domain (preferred) or a formatter — keep the template presentational.
- **Edge cases**: **empty** list (show "No items"), **very long** text (wrap/truncate), **many items** (MultiPage pagination — [02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md)), missing optional fields, huge totals (column width). Design for real data, not the happy demo.
- **Localization/RTL**: support the needed locales/fonts (fallback for scripts) and RTL if required.
- **Offload**: large/complex generation → isolate ([02 · isolates](../02%20Advanced%20Dart/04_isolates.md)); pass only serializable data into the isolate.
- **Testing**: because it's pure, unit-test that `buildInvoice` returns non-empty bytes for representative + edge inputs, and (optionally) golden-test rasterized pages.

## Memory Representation

The template builds a `pw.*` tree from the model, serialized to bytes; size scales with items/images. No hidden state — inputs fully determine output.

## Compiler Behavior

Not applicable.

## Runtime Behavior

Generation cost scales with data size (rows/images). Deterministic output enables caching/regeneration. Edge cases (empty/huge) exercise different layout paths.

## Flutter Engine Behavior

None; rendered to PDF.

## Dart VM Behavior

CPU-bound; offload large docs to an isolate (pass serializable model data, not live objects with closures).

## Examples

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:typed_data';

// Pure function: Invoice model -> PDF bytes (no I/O, no globals)
Future<Uint8List> buildInvoice(Invoice inv, {PdfPageFormat format = PdfPageFormat.a4}) async {
  final money = NumberFormat.currency(locale: inv.locale, symbol: inv.currencySymbol);
  final doc = pw.Document(theme: _brandTheme);          // shared fonts/theme

  doc.addPage(pw.MultiPage(
    pageFormat: format,
    header: (ctx) => _letterhead(inv.company),          // reusable component
    footer: (ctx) => _footer(ctx, inv.terms),
    build: (ctx) => [
      _billTo(inv.customer, money),
      pw.SizedBox(height: 12),
      inv.items.isEmpty
          ? pw.Text('No items')                          // empty-state edge case
          : _lineItemsTable(inv.items, money),           // paginates
      pw.SizedBox(height: 12),
      _totalsBlock(inv.subtotal, inv.tax, inv.total, money),
    ],
  ));
  return doc.save();
}

pw.Widget _lineItemsTable(List<LineItem> items, NumberFormat money) =>
    pw.TableHelper.fromTextArray(
      headers: ['Item', 'Qty', 'Unit', 'Amount'],
      data: [
        for (final i in items)
          [i.name, '${i.qty}', money.format(i.unitPrice), money.format(i.amount)]
      ],
      cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
    );
```

```dart
// Pure -> easy to unit-test (representative + edge inputs)
test('invoice generates non-empty bytes, even when empty', () async {
  expect((await buildInvoice(sampleInvoice)).isNotEmpty, true);
  expect((await buildInvoice(sampleInvoice.copyWith(items: []))).isNotEmpty, true);
});
```

## Diagrams

```mermaid
flowchart LR
    Invoice[Invoice model] --> Fn[buildInvoice (pure)]
    Report[Report model] --> Fn2[buildReport (pure)]
    Fn & Fn2 --> Shared[shared components: letterhead/table/totals/footer]
    Shared --> Bytes[PDF bytes]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Side effects/globals in generation | Untestable, isolate-unsafe | Pure function: data → bytes |
| `toString()` for money | Wrong formatting/precision | `intl` `NumberFormat.currency` |
| Only testing the happy path | Empty/huge/long-text break layout | Handle + test edge cases |
| Duplicating layout per document | Inconsistent branding, drift | Shared components/template |
| Computing totals in the template | Mixes domain + presentation | Compute in model/domain |
| Passing live objects to isolate | Not serializable | Pass plain data |
| No pagination for big lists | Clipping | `MultiPage` table |

## Best Practices

- Model generation as a **pure function** (`data → bytes`, no I/O/globals) built from **reusable components/templates** shared across documents.
- Format **money/dates/numbers with `intl`** (locale-aware); keep the template **presentational** (compute derived values in the domain/model).
- Handle **edge cases** (empty, many, long text, missing fields) and **paginate** large lists; support needed **locales/fonts/RTL**.
- **Offload heavy generation** to an isolate (pass serializable data); **unit-test** representative + edge inputs (optionally golden-test).

## Performance

Cost scales with data (rows/images) — paginate and compress. Determinism enables caching regenerated docs. Isolate large reports. Formatting is cheap; the win is reuse + testability preventing rework.

## Advantages / Disadvantages

- **+** Consistent branding, reuse across document types, testable (pure), locale-correct, handles real data.
- **−** Upfront template/component design, i18n/edge-case handling, isolate serialization discipline.

## Interview Questions

1. **🟢 Why model PDF generation as a pure function?** — `data → bytes` with no side effects is testable, deterministic, cacheable, and safe to run in an isolate.
2. **🟢 How do you format currency in a document?** — `intl` `NumberFormat.currency(locale, symbol)` — never `toString()` a double for money.
3. **🟡 How do you keep branding consistent across invoices and reports?** — Factor shared `pw.*` components (letterhead/table/totals/footer) into a reusable template used by all documents.
4. **🟡 What edge cases must a data-driven document handle?** — Empty lists, very long text, many items (pagination), missing optional fields, large totals — not just the happy path.
5. **🟡 Where should totals be computed?** — In the domain/model (presentation-free template) — keep the builder presentational.
6. **🔴 What must you consider when generating in an isolate?** — Pass only serializable data (no live objects/closures); the pure function makes this natural.
7. **🔴 How do you test document generation?** — Unit-test that representative + edge inputs produce valid non-empty bytes; optionally golden-test rasterized pages for layout regressions.

## Senior Engineer Tips

- Keep generation pure and presentational — domain computes totals, the template just lays them out; this is what makes documents testable and reusable.
- Build a small component library (letterhead/table/totals/footer) first; every document type then composes it, and rebranding is one change.
- Always format money/dates through `intl` and test the empty/huge cases — raw `toString()` and happy-path-only are the classic invoice bugs.

## Architect Perspective

Data-driven documents apply the "view is a function of state" principle to PDFs: pure builders over domain models, composed from shared branded components, formatted via i18n, isolate-offloaded, and unit-tested. This makes the document layer maintainable, consistent, and CI-testable — the same discipline as UI-from-state, and the foundation the capstone service orchestrates ([05_pdf_integration.md](05_pdf_integration.md), [02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md)).

## Summary

- Generate documents as pure functions `data → bytes` from reusable, branded components/templates shared across invoices/reports.
- Format money/dates/numbers with `intl`; compute derived values in the domain; handle empty/huge/long-text; paginate; support locales.
- Offload heavy generation (serializable data); unit-test representative + edge inputs.

## Revision Notes

- Pure `buildInvoice(data) → bytes` (no I/O/globals) from shared components (letterhead/table/totals/footer); one branded template.
- `intl` `NumberFormat.currency`/`DateFormat`; domain computes totals; handle empty/many/long/missing; `MultiPage` pagination; locales/fonts/RTL.
- Isolate large docs (serializable data); unit-test + optional golden tests.

## Practice Questions

1. Why keep generation pure and presentational?
2. How do you ensure consistent branding across document types?
3. Which edge cases must a data-driven template handle?

## Coding Questions

1. Write a pure `buildInvoice(Invoice)` from shared components with `intl` formatting.
2. Handle empty-items and long-name edge cases.
3. Unit-test generation for representative + edge inputs.

## Mini Project

**Invoice template (Flutter):** Build a pure `buildInvoice(Invoice, {format})` from reusable branded components (letterhead, paginating line-item table, totals block, footer), formatting money/dates via `intl`, handling empty/many/long-text cases, and offloading to an isolate. Add unit tests for representative + edge inputs. Acceptance: pure (data→bytes, no I/O/globals); shared components reused; correct locale formatting; edge cases handled; paginates large item lists; isolate-offloaded; unit-tested.
