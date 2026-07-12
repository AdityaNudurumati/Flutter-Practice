# Cells, Styles & Formulas

> Cells carry a **typed value** (text/number/bool/date/formula) — not just a string — and getting the **type + number/date format** right is what makes Excel treat "1,000" as a number and "2026-07-09" as a date rather than text. On top of that you can apply **styles** (font/fill/borders/alignment), **merge cells**, set **column widths**, and write **formulas** (`=SUM(B2:B10)`) that Excel evaluates on open. `excel` handles types + basic styling; **Syncfusion** is the tool when you need real formulas, number formats, and rich formatting.

## Introduction

A spreadsheet's value is its structure: numbers you can sum, dates you can sort, currency that displays right, and formulas that compute. This file covers cell types, number/date formatting, styling, merged cells/widths, and formulas — plus which package supports what — the difference between a data dump and a usable Excel file.

## Why this concept exists

If everything is text, Excel can't sum, sort by date, or format currency — the export is useless for analysis. Cells therefore have **types** and **number formats**, and formulas let the sheet compute live. Styling makes reports readable. These features distinguish a real spreadsheet from CSV, and require correct typing (a common bug source).

## Real-world analogy

A cell isn't just ink on paper — it's a **labeled container that knows what it holds**: a number bin, a date bin, a money bin. Put a number as text and it's like writing "1000" on a sticky note the calculator won't add. **Number formats** are the display mask (₹1,000.00), **styles** are the formatting (bold header, shaded row), and a **formula** is a **live calculator taped into the cell** that recomputes when data changes.

## Problem Statement

Export a sales report where amounts are real numbers formatted as currency, dates are real dates, the header row is bold with a fill, a "Total" cell uses `=SUM(...)`, and the title spans merged cells with sensible column widths. You'll set cell types, formats, styles, merges, and a formula.

## Internal Working

```mermaid
flowchart TD
    Cell[cell] --> Type{value type}
    Type --> Text[text]
    Type --> Num[number]
    Type --> Date[date]
    Type --> Bool[bool]
    Type --> Formula[formula '=SUM(...)']
    Num & Date --> Fmt[number/date format mask]
    Cell --> Style[font/fill/border/alignment]
    Cell --> Merge[merged range]
    Sheet --> Width[column widths / row heights]
```

- **Cell types** (not strings!): text, **number** (int/double), **bool**, **date/time**, and **formula**. In `excel`, use the typed `CellValue`s (`TextCellValue`, `IntCellValue`, `DoubleCellValue`, `DateCellValue`, `BoolCellValue`, `FormulaCellValue`). Wrong type = wrong behavior (numbers as text won't sum).
- **Number/date formats**: a cell's **display format** (e.g., `#,##0.00`, `₹#,##0.00`, `dd-mmm-yyyy`, `0%`) is separate from its value. Dates are stored as **serial numbers** (days since an epoch) with a date format applied — a frequent gotcha when reading (you may get a serial number, not a `DateTime`).
- **Styling**: font (bold/size/color), fill/background, borders, alignment, wrap. `excel` supports **basic `CellStyle`**; **Syncfusion** supports the full range (plus conditional formatting, themes).
- **Merged cells**: merge a range for titles/headers (`sheet.merge(CellIndex..., CellIndex...)`); the value lives in the top-left cell.
- **Column widths / row heights**: set for readability (`setColumnWidth`), auto-fit in Syncfusion.
- **Formulas**: write `=SUM(B2:B10)`, `=AVERAGE(...)`, `=A2*B2` as a **formula cell**; Excel evaluates on open (the file stores the formula, and often a cached result). `excel` has limited formula support; **Syncfusion** evaluates/handles them robustly.
- **Package split**: `excel` → types + basic styling + simple formulas; **Syncfusion** → rich number formats, full styling, reliable formulas, conditional formatting, charts.

## Memory Representation

Each cell stores a value + optional style/format reference. Styles are often shared/interned. Formulas store the expression (and possibly a cached value). More styles/formulas = larger file.

## Compiler Behavior

Not applicable.

## Runtime Behavior

Formulas evaluate when Excel/Sheets opens the file (the app writes the expression, not the computed value, unless it also caches it). Number formats affect display only; the underlying value is what's stored/summed.

## Flutter Engine Behavior

None; pure Dart generation.

## Dart VM Behavior

Not applicable beyond generation cost (isolate large/complex sheets).

## Examples

```dart
import 'package:excel/excel.dart';

void writeStyledReport(Excel excel) {
  final sheet = excel['Sales'];

  // Merged, bold title spanning A1:D1
  sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
  final title = sheet.cell(CellIndex.indexByString('A1'));
  title.value = TextCellValue('Sales Report');
  title.cellStyle = CellStyle(bold: true, fontSize: 16,
      horizontalAlign: HorizontalAlign.Center);

  // Bold, filled header row
  final headers = ['Item', 'Qty', 'Date', 'Amount'];
  for (var c = 0; c < headers.length; c++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
    cell.value = TextCellValue(headers[c]);
    cell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.blue100);
  }

  // Typed data: number + date (NOT text) so Excel can sum/sort/format
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Widget');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = IntCellValue(5);
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3)).value =
      DateCellValue(year: 2026, month: 7, day: 9);
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3)).value = DoubleCellValue(1499.00);

  // Formula: total of the Amount column (evaluated by Excel on open)
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 10)).value =
      FormulaCellValue('SUM(D4:D9)');
}
```

## Diagrams

```mermaid
flowchart LR
    Value[typed value] --> Store[cell value]
    Format[number/date format] --> Display[how it shows]
    Formula[=SUM(...)] --> Eval[Excel evaluates on open]
    Style[bold/fill/border] --> Look[readable report]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Numbers/dates as text | Can't sum/sort/format | Use typed cell values |
| Confusing value vs number format | Wrong display or math | Set value + format separately |
| Reading a date, getting a serial | Dates are serial numbers | Convert serial → `DateTime` |
| Expecting `excel` to do rich formulas/charts | Limited support | Use Syncfusion |
| Writing computed value instead of formula | Not "live" in Excel | Write a formula cell |
| Over-styling every cell | Bloats file/slow | Reuse styles; style selectively |
| Not merging for titles | Ugly layout | Merge title/header ranges |

## Best Practices

- Write **typed cells** (number/date/bool/formula), not strings, so Excel can sum/sort/format; set **number/date formats** for display (separate from value).
- Use **formulas** (`=SUM/AVERAGE/...`) for computed cells (evaluated on open); when **reading dates**, convert **serial numbers → `DateTime`**.
- Apply **styles/merges/widths** for readability but **reuse styles** and style selectively (avoid bloat); use **Syncfusion** for rich formats/formulas/charts.
- Offload complex/large sheet generation to an **isolate**; keep the styling/format logic reusable ([05_excel_integration.md](05_excel_integration.md)).

## Performance

More styles/formulas/cells → larger file + slower encode. Interned/reused styles help. Formulas are cheap to write (Excel evaluates on open). Large styled sheets should be isolate-generated. Number formats are free (display metadata).

## Advantages / Disadvantages

- **+** Real spreadsheet semantics (types, formats, formulas, styling, merges) — analysis-ready, readable exports.
- **−** Type/format correctness is fiddly (date serials!), `excel` limited for advanced needs, styling bloat, Syncfusion license for full features.

## Interview Questions

1. **🟢 Why must you set cell types instead of writing everything as text?** — So Excel can sum numbers, sort/format dates, and evaluate formulas — text cells break all of that.
2. **🟢 How are dates stored in a spreadsheet?** — As serial numbers (days since an epoch) with a date format applied; when reading you often get a serial to convert to `DateTime`.
3. **🟡 What's the difference between a cell's value and its number format?** — The value is the stored data; the number format is a display mask (e.g., `₹#,##0.00`) — the math uses the value, not the display.
4. **🟡 How do formulas behave in a generated file?** — You write the expression (`=SUM(...)`) as a formula cell; Excel/Sheets evaluates it when the file opens.
5. **🟡 When do you need Syncfusion over `excel`?** — For rich number formats, reliable formulas, conditional formatting, charts, and large-file handling.
6. **🔴 How do you make an exported report readable and analysis-ready?** — Typed cells + number/date formats + a bold/filled header + merged title + column widths + total formulas.
7. **🔴 Why can over-styling hurt?** — Every distinct style/format bloats the file and slows encoding; reuse styles and style selectively.

## Senior Engineer Tips

- Type your cells religiously and handle the date-serial conversion on read — "my sums are zero" and "dates show as 46000" are the two evergreen spreadsheet bugs.
- Write formulas rather than pre-computed values when the user should see live calculations; write cached values when they must match a snapshot exactly.
- Reuse a small set of styles (header/currency/date) instead of styling per cell; it keeps files small and generation fast.

## Architect Perspective

Cells/styles/formulas are the semantic layer that makes exports useful. Encapsulating typed-cell mapping, reusable styles, and date/format handling in reusable helpers (behind the spreadsheet service) yields consistent, analysis-ready outputs and confines the fiddly type/serial logic to one tested place — the spreadsheet analog of PDF's reusable components ([05_excel_integration.md](05_excel_integration.md), [Module 35](../35%20PDF/04_data_driven_documents.md)).

## Summary

- Cells are typed (text/number/date/bool/formula); set number/date formats (separate from value); dates are serial numbers.
- Use formulas (evaluated on open), styles/merges/widths (reuse styles); `excel` = basic, Syncfusion = rich.
- Type correctness (esp. dates) is the main pitfall; isolate large/complex generation.

## Revision Notes

- Typed cells: `TextCellValue`/`IntCellValue`/`DoubleCellValue`/`DateCellValue`/`BoolCellValue`/`FormulaCellValue`; value ≠ number format (display mask).
- Dates = serial numbers (convert on read); formulas (`=SUM(...)`) evaluated on open; styles (`CellStyle`)/merge/`setColumnWidth`.
- `excel` basic styling/formulas; Syncfusion for rich formats/formulas/charts/conditional; reuse styles; isolate large sheets.

## Practice Questions

1. Why write a number as `DoubleCellValue` not `TextCellValue`?
2. How are dates represented, and what must you do when reading them?
3. When do you need Syncfusion instead of `excel`?

## Coding Questions

1. Write a styled header row + typed data row (number/date) with `excel`.
2. Add a merged title and a `SUM` total formula.
3. Convert a read date serial into a `DateTime`.

## Mini Project

**Styled report sheet (Flutter):** Generate a sales report XLSX with a merged bold title, a bold/filled header row, typed number/date cells with number/date formats, sensible column widths, and a `=SUM(...)` total — reusing a small set of styles and offloading generation to an isolate. Acceptance: numbers/dates are typed (sum/sort work in Excel); formats display correctly; header/title styled + merged; total formula evaluates on open; styles reused (no bloat); generated off the UI thread.
