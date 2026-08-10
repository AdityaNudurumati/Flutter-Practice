# PDF generator

Rebuilds one PDF per folder under `Flutter/` into the parent directory.

## Run

```bash
cd "Flutter PDFs/_generator"

python build_pdfs.py                      # all folders
python build_pdfs.py "11 State Management"   # just one
```

## Requirements

- `pandoc` on PATH (markdown -> HTML)
- Google Chrome at the default install path (HTML -> PDF)
- Python 3

Mermaid is bundled (`mermaid.min.js`), so the build works offline.

## Files

| File | Role |
|---|---|
| `build_pdfs.py` | orchestrates: concatenate notes -> pandoc -> headless Chrome |
| `mermaid_fix.py` | repairs unquoted labels / stray class-diagram arrows so every diagram parses |
| `header.html` | print stylesheet (A4 layout, code, tables, TOC) |
| `after.html` | renders each mermaid block to inline SVG before printing |

## Notes

- Within each PDF, `README.md` comes first, then the numbered notes; each starts on a new page.
- `mermaid_fix.py` only rewrites the copy handed to mermaid — your `.md` files are never modified.
- If a diagram ever fails to parse, its source is printed as a code block instead of failing the build.
