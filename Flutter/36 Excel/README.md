# 36 · Excel

## Introduction

This module covers reading and writing spreadsheets in Flutter: the **package landscape** (`excel` for free read/write of `.xlsx`, Syncfusion XlsIO for richer styling/formulas/charts, `csv` for CSV) and their **workbook → sheet → cell** model; **cells, styling & formulas** (types, number/date formats, styles, merged cells, formulas); **CSV & data interchange** (when CSV beats XLSX, parsing/quoting edge cases); and **import/export of app data at scale** (mapping models ↔ rows, memory/streaming concerns for large datasets), tied together in a capstone. It builds on file handling ([Module 34](../34%20File%20Handling/README.md)) and pairs with PDF ([Module 35](../35%20PDF/README.md)).

## Why this module exists

Business and data apps constantly import/export spreadsheets: users upload an XLSX/CSV to bulk-load data, or export reports/tables to open in Excel/Sheets. But spreadsheets are deceptively tricky — cell type coercion, date serial numbers, locale/quoting in CSV, formula vs value, and memory blow-ups on large files. Choosing the right package and handling these correctly (off the UI thread) is a common, high-value skill.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [excel_basics_and_packages.md](excel_basics_and_packages.md) | Package choice (`excel`/Syncfusion/`csv`), workbook/sheet/cell model, read/write | 🔵 |
| 2 | [cells_styles_and_formulas.md](cells_styles_and_formulas.md) | Cell types, number/date formats, styling, merged cells, formulas | 🟡 |
| 3 | [csv_and_data_interchange.md](csv_and_data_interchange.md) | CSV read/write, quoting/locale edge cases, CSV vs XLSX | 🟡 |
| 4 | [import_export_large_datasets.md](import_export_large_datasets.md) | Model↔row mapping, validation, memory/streaming, large files | 🔴 |
| 5 | [excel_integration.md](excel_integration.md) | Capstone: import/export behind a service, off-UI-thread | 🔴 |

> **Cross-references:** File save/share/pick: [Module 34](../34%20File%20Handling/README.md). PDF (the other export format): [Module 35](../35%20PDF/README.md). Isolates (heavy parse/generate): [02 · isolates](../02%20Advanced%20Dart/isolates_and_concurrency.md). Networking (fetch export data): [Module 16](../16%20Networking/README.md). Models/serialization: [02 · json_serialization](../02%20Advanced%20Dart/json_and_serialization.md).

## Prerequisites

[34 File Handling](../34%20File%20Handling/README.md) (read/write/pick/share), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (async/isolates), basic model/serialization knowledge.

## What you'll be able to do after this module

- Choose the right spreadsheet package (`excel` vs Syncfusion vs `csv`) for the job.
- Read and write XLSX workbooks/sheets/cells and understand the cell model.
- Apply cell types, number/date formats, styles, merged cells, and formulas.
- Parse and generate CSV correctly (quoting, delimiters, locale, encoding).
- Import/export app data at scale, mapping models ↔ rows with validation, off the UI thread.

## Capstone

**Import/export slice:** A data manager that imports a user-picked XLSX/CSV (validate + map rows → models, report row errors), exports a filtered dataset to a styled XLSX (headers, number/date formats, totals formula) and to CSV, handles a large file without freezing the UI (isolate), and lets the user share the result — behind a `SpreadsheetService`.

## Summary

Excel work = pick the right package (`excel`/Syncfusion/`csv`) for the workbook→sheet→cell model, handle cell types/formats/formulas and CSV quoting correctly, map models ↔ rows with validation, and do heavy parse/generate off the UI thread — wrapped behind a service, complementing PDF export.
