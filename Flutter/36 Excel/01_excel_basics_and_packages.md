# Excel Basics & Package Choice

> Three tools for three needs: **`excel`** (free, pure-Dart read+write of `.xlsx` — the default for most apps), **Syncfusion XlsIO** (richer styling/formulas/charts/large-file APIs, but commercial-licensed), and **`csv`** (plain comma-separated text — simplest, universal, but no types/styling). All share a **workbook → sheet → cell (by row/column)** model. Pick by need — and remember XLSX is a **zipped XML** format, so large files are memory-heavy: parse/generate them **off the UI thread**.

## Introduction

Before reading or writing anything, choose the right package and understand the shared model. This file compares `excel`, Syncfusion, and `csv`, explains the workbook/sheet/cell structure and coordinate systems (A1 vs row/col indices), and shows a basic read and write — the foundation for the rest of the module.

## Why this concept exists

"Excel support" spans free basic read/write, rich formatting/formulas, and trivial CSV — with very different tradeoffs (licensing, features, memory). A single package doesn't fit all cases, so knowing the landscape avoids over-engineering (Syncfusion for a CSV export) or hitting walls (`excel` for advanced charts). The shared workbook/sheet/cell model unifies how you address data.

## Real-world analogy

Choosing a package is like choosing a **document tool**: `csv` is a **plain text notepad** (universal, no formatting), `excel` is a **free spreadsheet app** (real cells, basic styling), and Syncfusion is the **pro suite** (advanced formatting/charts/formulas — but you pay for the license). A workbook is a **binder**, each **sheet a tabbed page**, each **cell a labeled box** (A1, B2…).

## Problem Statement

Decide which package to use for: a simple data export, a styled report with formulas, and a bulk CSV import — then read an uploaded XLSX and write a new one. You'll compare options and do a basic read/write with `excel`.

## Internal Working

```mermaid
flowchart TD
    Need{what do you need?}
    Need -->|basic .xlsx read/write, free| Excel[excel package]
    Need -->|rich styling/formulas/charts/large files| Sync[Syncfusion XlsIO (licensed)]
    Need -->|simple universal text| Csv[csv package]
    Excel & Sync --> Model[Workbook -> Sheet -> Cell (row/col or A1)]
    Model --> Bytes[.xlsx = zipped XML (memory-heavy)]
```

- **`excel`** (free, pure Dart): read + write `.xlsx`; `Excel.decodeBytes(bytes)` to read, `excel.save()`/`encode()` to write. Cells addressed by `CellIndex.indexByColumnRow` or A1 (`'A1'`). Good default; limited advanced styling/charts, and large files are memory-heavy (loads the whole workbook).
- **Syncfusion XlsIO** (`syncfusion_flutter_xlsio`, **commercial license**): richer — cell styles, number formats, **formulas**, merged cells, conditional formatting, charts, images, and better large-file handling. Use when you need Excel-grade output; mind the license.
- **`csv`** (free): encode/decode delimited text (`ListToCsvConverter`/`CsvToListConverter`). No types/styling/multiple sheets — but universal, tiny, streamable ([03_csv_and_data_interchange.md](03_csv_and_data_interchange.md)).
- **Shared model**: **Workbook** (the file) → one or more **Sheets** (tabs) → **Cells** at (row, column). Coordinates are commonly **0-based indices** in code but **A1** in Excel UI — mind the mapping (A=col 0, row1=index 0).
- **XLSX = zipped XML (OOXML)**: a `.xlsx` is a ZIP of XML parts. Reading/writing decompresses/serializes lots of XML → **memory + CPU heavy** for large files → do it in an **isolate** ([02 · isolates](../02%20Advanced%20Dart/04_isolates.md)); CSV is far lighter.
- **Bytes in/out**: all produce/consume bytes you save/share/pick via the file layer ([Module 34](../34%20File%20Handling/README.md)).

## Memory Representation

`excel`/Syncfusion load the workbook object graph into memory (cells, styles) — scales with size. CSV can be processed row-by-row (streamable). Output is bytes (`Uint8List`) → file layer.

## Compiler Behavior

Not applicable; normal Dart packages. Syncfusion requires a license key registration.

## Runtime Behavior

Decoding/encoding XLSX parses/serializes XML (slow for large files). CSV parsing is linear and cheap. Cell access by index/A1 is direct.

## Flutter Engine Behavior

None; pure Dart processing. UI stays smooth only if heavy work is offloaded.

## Dart VM Behavior

CPU/memory-bound parsing/serialization → offload large operations to an isolate.

## Examples

```dart
import 'package:excel/excel.dart';
import 'dart:typed_data';

// READ an uploaded .xlsx
List<List<dynamic>> readSheet(Uint8List bytes, {String? sheetName}) {
  final excel = Excel.decodeBytes(bytes);
  final name = sheetName ?? excel.tables.keys.first;   // first sheet by default
  final sheet = excel.tables[name]!;
  return sheet.rows.map((row) => row.map((c) => c?.value).toList()).toList();
}

// WRITE a new .xlsx and return bytes (save/share via Module 34)
Uint8List writeSheet(List<String> headers, List<List<Object?>> rows) {
  final excel = Excel.createExcel();                   // creates a default sheet
  final sheet = excel['Data'];
  sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
  for (final r in rows) {
    sheet.appendRow(r.map<CellValue?>((v) => v == null
        ? null
        : v is num ? DoubleCellValue(v.toDouble()) : TextCellValue('$v')).toList());
  }
  return Uint8List.fromList(excel.encode()!);          // bytes -> file
}
```

## Diagrams

```mermaid
flowchart LR
    File[.xlsx bytes] --> Decode[Excel.decodeBytes]
    Decode --> WB[Workbook]
    WB --> Sheets[Sheets]
    Sheets --> Cells[Cells (row,col / A1)]
    Cells --> Read[read values]
    Write[createExcel -> appendRow] --> Encode[encode() -> bytes]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Syncfusion for a simple CSV/export | Overkill + license cost | Use `excel`/`csv` |
| `excel` for charts/advanced formats | Not supported | Use Syncfusion |
| Loading huge XLSX on UI thread | Jank/OOM | Isolate; consider CSV/streaming |
| Confusing A1 vs 0-based indices | Off-by-one/wrong cells | Map A1↔index carefully |
| Assuming CSV = Excel | CSV has no types/styling/sheets | Choose format by need |
| Ignoring license (Syncfusion) | Legal/compliance | Register key / pick free option |

## Best Practices

- **Default to `excel`** for basic `.xlsx` read/write; use **Syncfusion** only when you need rich styling/formulas/charts (mind the **license**); use **`csv`** for simple/universal interchange.
- Understand the **workbook→sheet→cell** model and the **A1↔0-based index** mapping; access cells explicitly.
- Treat XLSX as **memory/CPU heavy** (zipped XML) — **offload large parse/generate to an isolate**; prefer **CSV/streaming** for very large data.
- Produce/consume **bytes** and route through the **file layer** ([Module 34](../34%20File%20Handling/README.md)); wrap behind a service.

## Performance

XLSX decode/encode is the cost center (XML + zip) — scales with cells/sheets; isolate it. CSV is linear and streamable (cheap). Cell access is O(1). For big datasets, CSV or Syncfusion's streaming beats loading a huge `excel` workbook.

## Advantages / Disadvantages

- **+** Options for every need (free basic, rich commercial, universal CSV); familiar workbook model; standard bytes output.
- **−** Package tradeoffs (features vs license vs memory), XLSX heavy for large files, A1/index mapping, CSV lacks types/styling.

## Interview Questions

1. **🟢 Which package for basic free XLSX read/write?** — The `excel` package (pure Dart, read + write).
2. **🟢 When would you choose Syncfusion or CSV instead?** — Syncfusion for rich styling/formulas/charts/large files (commercial license); CSV for simple, universal, lightweight interchange.
3. **🟡 What's the shared spreadsheet model?** — Workbook → sheets → cells addressed by (row, column) or A1 — mind the 0-based-index vs A1 mapping.
4. **🟡 Why are large XLSX files memory-heavy?** — `.xlsx` is zipped XML (OOXML); decoding/encoding parses/serializes lots of XML and loads the workbook into memory.
5. **🟡 Why offload spreadsheet work to an isolate?** — Decode/encode is CPU/memory-bound and would jank the UI on large files.
6. **🔴 CSV vs XLSX — key differences?** — CSV is plain typeless text (no styling/formulas/multiple sheets) but tiny/streamable; XLSX has types/styling/sheets but is heavier.
7. **🔴 What do these packages produce/consume, and how does that integrate?** — Bytes (`Uint8List`) you read from a picked file and write to save/share via the file layer.

## Senior Engineer Tips

- Start with `excel` or `csv`; only reach for Syncfusion when a real requirement (charts, complex formatting, huge files) justifies the license — don't pay for a data dump.
- Assume large files and isolate parse/generate from the start; the "works on 10 rows, freezes on 100k" bug is the classic spreadsheet regression.
- Nail the A1↔index mapping in a tiny helper and reuse it; off-by-one cell bugs are endless otherwise.

## Architect Perspective

Package choice is a requirements/licensing/performance decision, not a default. Encapsulating the chosen library behind a `SpreadsheetService` (bytes in/out, isolate-offloaded) lets you swap `excel`↔Syncfusion↔CSV without touching features, and keeps the memory/CPU concerns in one place. The workbook/sheet/cell model and bytes-based I/O integrate cleanly with the file and import/export layers ([05_excel_integration.md](05_excel_integration.md), [Module 34](../34%20File%20Handling/README.md)).

## Summary

- `excel` (free basic), Syncfusion (rich, licensed), `csv` (simple/universal) — pick by need; all use workbook→sheet→cell.
- XLSX is zipped XML → memory/CPU heavy → isolate large ops; CSV is light/streamable; mind A1↔0-index.
- Bytes in/out via the file layer; wrap behind a service.

## Revision Notes

- `excel`: `Excel.decodeBytes(bytes)` read, `createExcel`/`appendRow`/`encode()` write; cells by `CellIndex`/A1.
- Syncfusion XlsIO (licensed): styles/formulas/charts/large files; `csv`: `CsvToListConverter`/`ListToCsvConverter` (no types/styling).
- Workbook→sheet→cell; A1↔0-based mapping; XLSX = zipped XML (heavy) → isolate; bytes → file layer (Module 34).

## Practice Questions

1. Which package for a styled report with formulas and charts?
2. Why isolate XLSX decode/encode for large files?
3. How do A1 references map to code indices?

## Coding Questions

1. Read the first sheet of a picked `.xlsx` into rows with `excel`.
2. Write a new `.xlsx` from headers + rows, returning bytes.
3. Offload a large decode to an isolate via `compute`.

## Mini Project

**Read & write XLSX (Flutter):** Using `excel`, read an uploaded `.xlsx` (first sheet → rows) and write a new `.xlsx` from headers + rows returning bytes (saved/shared via Module 34), with large operations offloaded to an isolate. Add a short doc justifying `excel` vs Syncfusion vs `csv` for three scenarios. Acceptance: reads + writes correct cells (A1/index handled); bytes routed to file layer; heavy ops off the UI thread; package-choice rationale documented.
