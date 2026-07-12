# 35 · PDF

## Introduction

This module covers generating, viewing, and printing PDFs in Flutter with the **`pdf`** package (document/page/widget model — a **separate widget tree** from Flutter's) and the **`printing`** package (preview, print, share, save). It walks from **generation basics** (text, styling, the `pw.*` widgets), through **layouts/tables/assets** (multi-page tables, images, custom fonts, headers/footers), **viewing & printing** (preview dialog, OS print, share/save), **data-driven documents** (invoices/reports from your models, reusable templates), to a capstone invoice generator. It builds on file handling ([Module 34](../34%20File%20Handling/README.md)) and sharing.

## Why this module exists

Business apps constantly produce documents: invoices, receipts, reports, tickets, certificates. Users expect to preview, print, share, and save them as PDFs. The `pdf` package uses its **own widget system** (`pw.Widget`, not Flutter widgets) rendered to a page-based, paginated document — a distinct mental model. Generating correct, paginated, styled documents from live data (and wiring print/share/save) is a common, high-value skill that's easy to get subtly wrong (pagination, fonts, memory).

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_pdf_generation_basics.md](01_pdf_generation_basics.md) | `pdf` package model: `Document`/`Page`/`pw.*` widgets, text/styling | 🔵 |
| 2 | [02_layouts_tables_and_assets.md](02_layouts_tables_and_assets.md) | Multi-page tables, images, custom fonts, headers/footers | 🟡 |
| 3 | [03_viewing_and_printing.md](03_viewing_and_printing.md) | `printing`: preview, OS print, share, save PDFs | 🟡 |
| 4 | [04_data_driven_documents.md](04_data_driven_documents.md) | Invoices/reports from models, reusable templates, dynamic content | 🔴 |
| 5 | [05_pdf_integration.md](05_pdf_integration.md) | Capstone: invoice generator behind a service | 🔴 |

> **Cross-references:** File saving/sharing: [Module 34](../34%20File%20Handling/README.md). Isolates (heavy generation): [02 · isolates](../02%20Advanced%20Dart/04_isolates.md). Excel/spreadsheets: [Module 36](../36%20Excel/README.md). Networking (fetch report data): [Module 16](../16%20Networking/README.md). Custom painting (for comparison): [Module 23](../23%20Custom%20Painting/README.md).

## Prerequisites

[34 File Handling](../34%20File%20Handling/README.md) (save/share), basic layout intuition (Flutter widgets help — the `pw.*` API mirrors them), [02 Advanced Dart](../02%20Advanced%20Dart/README.md) (async/isolates for heavy docs).

## What you'll be able to do after this module

- Generate PDFs with the `pdf` package's document/page/widget model and style text.
- Build multi-page documents with paginated tables, images, custom fonts, and headers/footers.
- Preview, print (OS dialog), share, and save PDFs with the `printing` package.
- Produce data-driven documents (invoices/reports) from your models via reusable templates.
- Wrap PDF generation behind a service, generating heavy docs off the UI thread.

## Capstone

**Invoice slice:** An invoice generator that builds a styled, multi-page PDF from order data (logo, line-item table with pagination, totals, header/footer with page numbers, custom fonts), then lets the user preview, print, share, and save it — generation offloaded to an isolate and wrapped behind a `PdfService`.

## Summary

PDF work = the `pdf` package's own paginated widget tree (`pw.*`) for generation + the `printing` package for preview/print/share/save. Build reusable, data-driven templates (invoices/reports), mind pagination/fonts/memory, offload heavy generation, and wrap it behind a service.
