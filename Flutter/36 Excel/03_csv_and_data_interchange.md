# CSV & Data Interchange

> CSV is plain delimited text — **universal, tiny, and streamable** — but deceptively error-prone: fields containing the **delimiter, quotes, or newlines must be quoted** (and embedded quotes doubled), the **delimiter isn't always a comma** (locales use `;`), **encoding** matters (UTF-8 + BOM for Excel to read non-ASCII correctly), and everything is a **string** (no types — you parse/coerce). Use the **`csv`** package (`CsvToListConverter`/`ListToCsvConverter`) rather than naive `split(',')`, which breaks on the first quoted comma.

## Introduction

CSV is the lowest-common-denominator interchange format — every tool reads it, and it streams row-by-row without loading a whole workbook. But "just split on commas" corrupts real data. This file covers correct CSV parsing/generation, the quoting/delimiter/encoding/locale edge cases, and when CSV beats XLSX.

## Why this concept exists

Systems must exchange tabular data simply and universally; CSV is that format. But its simplicity hides rules (RFC 4180 quoting) that naive code ignores, causing silent corruption (a comma in an address splits a field). The `csv` package implements the rules correctly; understanding the edge cases prevents data loss.

## Real-world analogy

CSV is **passing notes with commas between words**: fine until a word itself contains a comma ("Smith, Jr.") — then you must **wrap it in quotes** so the reader doesn't mistake it for two words. Different countries even use a **semicolon** as the separator. And to read accented names, you must agree on the **alphabet (encoding)** first. Naive `split(',')` is a reader who ignores the quotes and mangles the note.

## Problem Statement

Import a user CSV whose fields include commas, quotes, and newlines (addresses, notes), possibly semicolon-delimited and with non-ASCII names, and export data as CSV that Excel opens correctly with accents intact. You'll use the `csv` package with correct quoting/delimiter/encoding.

## Internal Working

```mermaid
flowchart TD
    Parse[CSV text] --> Conv[CsvToListConverter (respects quotes/delimiter/EOL)]
    Conv --> Rows[List<List<dynamic>> (all strings)]
    Rows --> Coerce[coerce/validate types per column]
    Gen[List<List<Object?>>] --> Out[ListToCsvConverter (quotes fields as needed)]
    Out --> Enc[encode UTF-8 (+ BOM for Excel)]
```

- **Use the `csv` package**, not `split(',')`:
  - **Parse**: `const CsvToListConverter().convert(text)` (or `.convert(text, fieldDelimiter: ';', eol: '\n')`) → `List<List<dynamic>>`. It handles **quoted fields**, **embedded delimiters/newlines**, and **doubled quotes** correctly.
  - **Generate**: `const ListToCsvConverter().convert(rows)` — it **quotes fields** that contain the delimiter/quote/newline and **doubles** embedded quotes automatically.
- **Quoting rules (RFC 4180)**: a field with a comma/quote/newline is wrapped in double quotes; an embedded `"` becomes `""`. The package does this — hand-rolling gets it wrong.
- **Delimiter/locale**: comma is common, but **locale/region** may use **`;`** (e.g., where `,` is the decimal separator). Let users/config choose the delimiter for import; pick a safe one for export (or match the target).
- **Encoding**: CSV is bytes → text; use **UTF-8**. For **Excel** to read non-ASCII correctly, prepend a **UTF-8 BOM** (`﻿`) or Excel may misread accents. Handle input encoding (some files are Latin-1/UTF-16).
- **Typeless**: every field is a **string** — you must **coerce** (parse int/double/date) and **validate** per column on import ([04_import_export_large_datasets.md](04_import_export_large_datasets.md)); numbers/dates have no format, and locale affects decimal separators.
- **Streaming**: large CSVs can be processed **row-by-row** (stream the file, convert incrementally) — far lighter than loading a whole XLSX ([Module 34](../34%20File%20Handling/README.md)).
- **CSV vs XLSX**: CSV — universal, tiny, streamable, but no types/styling/formulas/sheets. XLSX — typed/styled/multi-sheet, but heavier. Choose by need.

## Memory Representation

Parsed CSV is a `List<List<dynamic>>` of strings (memory scales with rows unless streamed). Streaming holds only the current row(s). Output is a string → bytes.

## Compiler Behavior

Not applicable.

## Runtime Behavior

Parsing is linear; correct quoting handling means fields with commas/newlines stay intact. Wrong delimiter/encoding causes misparsed columns/garbled text.

## Flutter Engine Behavior

None; pure Dart.

## Dart VM Behavior

Cheap linear processing; stream large files to bound memory; heavy per-row coercion can be isolate-offloaded.

## Examples

```dart
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:typed_data';

// PARSE (handles quoted commas/newlines; configurable delimiter)
List<List<dynamic>> parseCsv(String text, {String delimiter = ','}) {
  return CsvToListConverter(fieldDelimiter: delimiter, eol: '\n').convert(text);
  // ["Smith, Jr.", "note with ""quotes""", ...] parse correctly — NOT split(',')
}

// GENERATE + encode UTF-8 with BOM so Excel reads accents (café, ₹) correctly
Uint8List toCsvBytes(List<List<Object?>> rows) {
  final csv = const ListToCsvConverter().convert(rows); // auto-quotes fields as needed
  const bom = [0xEF, 0xBB, 0xBF];                        // UTF-8 BOM for Excel
  return Uint8List.fromList([...bom, ...utf8.encode(csv)]);
}

// Typeless -> coerce/validate on import
int parseQty(dynamic cell) => int.tryParse('$cell'.trim()) ?? (throw FormatException('bad qty: $cell'));
```

## Diagrams

```mermaid
flowchart LR
    Naive[split(',')] -->|breaks on quoted comma| Corrupt[mangled fields]
    Pkg[csv package] -->|RFC 4180 quoting| Correct[intact fields]
    Export[rows] --> Quote[auto-quote] --> BOM[UTF-8 + BOM] --> Excel[Excel reads accents]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| `split(',')` to parse | Breaks on quoted commas/newlines | Use `CsvToListConverter` |
| Hand-rolling quoting | Wrong for quotes/newlines | Use `ListToCsvConverter` |
| Assuming comma delimiter | Locales use `;` | Configurable/known delimiter |
| No UTF-8 BOM for Excel | Accents garbled | Prepend BOM for Excel |
| Treating fields as typed | CSV is all strings | Coerce + validate per column |
| Loading huge CSV whole | Memory | Stream row-by-row |
| Ignoring input encoding | Garbled text | Detect/handle UTF-8/Latin-1/UTF-16 |

## Best Practices

- **Always use the `csv` package** (never `split(',')`); it handles **quoting, embedded delimiters/newlines, doubled quotes** on both read and write.
- Make the **delimiter configurable** (comma/semicolon by locale); **encode UTF-8** and **prepend a BOM** for Excel to read non-ASCII correctly; handle input encoding.
- Treat fields as **strings** → **coerce + validate types per column** on import ([04_import_export_large_datasets.md](04_import_export_large_datasets.md)); mind **locale decimal separators**.
- **Stream** large CSVs row-by-row (memory); choose **CSV vs XLSX** by need (universal/light vs typed/styled).

## Performance

CSV is linear and streamable — far lighter than XLSX for large datasets (no XML/zip). Stream to bound memory; isolate heavy per-row coercion. Generation is cheap. CSV is the go-to for very large exports/imports.

## Advantages / Disadvantages

- **+** Universal, tiny, streamable, human-readable, great for large datasets.
- **−** No types/styling/formulas/sheets, quoting/delimiter/encoding pitfalls, locale issues, manual coercion/validation.

## Interview Questions

1. **🟢 Why not parse CSV with `split(',')`?** — It breaks on fields containing quoted commas, newlines, or quotes; the `csv` package implements the quoting rules correctly.
2. **🟢 What are CSV's core limitations vs XLSX?** — No types, styling, formulas, or multiple sheets — everything is a string you must coerce.
3. **🟡 How do you make Excel read a UTF-8 CSV with accents correctly?** — Prepend a UTF-8 BOM (and encode UTF-8); otherwise Excel may garble non-ASCII.
4. **🟡 Why might the delimiter not be a comma?** — Locales where comma is the decimal separator use `;` — make it configurable/known.
5. **🟡 How are fields with commas/quotes/newlines represented?** — Quoted with double quotes, embedded quotes doubled (`""`) — RFC 4180; the package handles it.
6. **🔴 When do you choose CSV over XLSX?** — Large datasets, universal interchange, streaming, or when types/styling aren't needed; XLSX when you need types/formatting/formulas/sheets.
7. **🔴 How do you process a very large CSV without OOM?** — Stream it row-by-row (incremental convert), coercing/validating as you go, rather than loading it all.

## Senior Engineer Tips

- Standardize on the `csv` package everywhere and ban `split(',')` in review — hand-parsing CSV is a guaranteed data-corruption bug on real-world fields.
- Add the UTF-8 BOM for Excel exports and make the delimiter configurable; the two most common "the file looks wrong in Excel" complaints are garbled accents and semicolon locales.
- For big data, prefer streaming CSV over loading XLSX; it's the difference between a snappy export and an OOM.

## Architect Perspective

CSV is the interchange boundary: simple bytes/text that every system speaks, at the cost of typelessness and edge-case rules. Encapsulating correct parsing/generation (package-based, encoding/BOM/delimiter-aware, streamable) plus a per-column coercion/validation layer behind the spreadsheet service gives robust, lightweight interchange — complementing typed XLSX and integrating with import/export mapping ([04_import_export_large_datasets.md](04_import_export_large_datasets.md), [05_excel_integration.md](05_excel_integration.md)).

## Summary

- Use the `csv` package (correct quoting/delimiter/newline handling) — never `split(',')`; make delimiter configurable; UTF-8 + BOM for Excel.
- CSV is typeless (coerce/validate per column), locale-sensitive, but universal/tiny/streamable.
- Choose CSV (light/universal/large) vs XLSX (typed/styled) by need; stream large files.

## Revision Notes

- `CsvToListConverter`/`ListToCsvConverter` (handle quotes/embedded delimiters/newlines, doubled quotes); never `split(',')`.
- Delimiter configurable (`,`/`;`), UTF-8 encode + BOM for Excel, handle input encoding; fields are strings → coerce + validate; locale decimals.
- Stream large CSVs; CSV (universal/light/large) vs XLSX (typed/styled/sheets); behind the service.

## Practice Questions

1. What breaks when you `split(',')` real CSV data?
2. Why add a UTF-8 BOM for Excel, and when?
3. When is CSV preferable to XLSX?

## Coding Questions

1. Parse a CSV with quoted commas/newlines using the `csv` package.
2. Generate CSV bytes with a UTF-8 BOM for Excel.
3. Coerce + validate a numeric/date column from string fields.

## Mini Project

**Robust CSV interchange (Flutter):** Build CSV import/export: parse a picked CSV (configurable delimiter, quoted commas/newlines, encoding-aware) into rows and coerce/validate typed columns (reporting bad rows); export data as CSV bytes with a UTF-8 BOM so Excel reads accents/₹ correctly — streaming large files. Acceptance: quoted/edge-case fields parse intact (no `split`); delimiter configurable; export opens correctly in Excel (accents intact); columns coerced + validated; large files streamed; behind the service.
