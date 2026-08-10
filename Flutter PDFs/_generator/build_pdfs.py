"""Build one PDF per topic folder from its markdown notes.

Pipeline: markdown files -> concatenated md -> pandoc (standalone HTML + TOC)
-> headless Chrome --print-to-pdf.
"""
import os
import re
import subprocess
import sys
import shutil

from mermaid_fix import fix as fix_mermaid

ROOT = r"c:\Users\Aditya\Desktop\Flutter Practice\Flutter"
OUT = r"c:\Users\Aditya\Desktop\Flutter Practice\Flutter PDFs"
WORK = os.path.dirname(os.path.abspath(__file__))
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
PANDOC = shutil.which("pandoc")

HEADER = os.path.join(WORK, "header.html")
AFTER = os.path.join(WORK, "after.html")


def md_files(folder):
    """README.md first, then the numbered notes in order."""
    names = [n for n in os.listdir(folder) if n.lower().endswith(".md")]
    readme = [n for n in names if n.lower() == "readme.md"]
    rest = sorted(n for n in names if n.lower() != "readme.md")
    return readme + rest


MERMAID_FENCE = re.compile(r"(```mermaid\n)(.*?)(\n```)", re.S)


def normalize(text, first):
    """Make every file a top-level chapter and repair its diagrams."""
    text = text.replace("\r\n", "\n").strip("\n")
    # relative links between notes are dead in a PDF -> keep the label only
    text = re.sub(r"\[([^\]]+)\]\((?!https?:)[^)]*\.md[^)]*\)", r"\1", text)
    # the notes write in-label line breaks as a literal \n; mermaid wants <br/>
    text = MERMAID_FENCE.sub(
        lambda m: m.group(1) + fix_mermaid(m.group(2).replace("\\n", "<br/>")) + m.group(3),
        text)
    if not first:
        text = '<div class="chapter"></div>\n\n' + text
    return text


def build(folder_name):
    folder = os.path.join(ROOT, folder_name)
    files = md_files(folder)
    if not files:
        return None, "no markdown files"

    parts = []
    for i, name in enumerate(files):
        with open(os.path.join(folder, name), encoding="utf-8", errors="replace") as f:
            body = f.read()
        if not re.match(r"\s*#\s", body):  # ensure the chapter has a heading to anchor the TOC
            body = "# " + os.path.splitext(name)[0].replace("_", " ").title() + "\n\n" + body
        parts.append(normalize(body, i == 0))

    md_path = os.path.join(WORK, "_doc.md")
    html_path = os.path.join(WORK, "_doc.html")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("\n\n".join(parts) + "\n")

    title = re.sub(r"^(\d+)\s+", r"\1 · ", folder_name)
    cmd = [
        PANDOC, md_path, "-f", "gfm", "-t", "html5", "--standalone",
        "--toc", "--toc-depth=1", "--highlight-style=tango",
        "-H", HEADER, "-A", AFTER,
        "--metadata", "title=" + title,
        "--metadata", "subtitle=Flutter Practice Notes",
        "-o", html_path,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return None, "pandoc: " + r.stderr.strip()[:300]

    pdf_path = os.path.join(OUT, folder_name + ".pdf")
    if os.path.exists(pdf_path):
        os.remove(pdf_path)
    r = subprocess.run([
        CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
        "--no-pdf-header-footer", "--run-all-compositor-stages-before-draw",
        "--virtual-time-budget=45000", "--allow-file-access-from-files",
        "--print-to-pdf=" + pdf_path, html_path,
    ], capture_output=True, text=True, timeout=300)
    if not os.path.exists(pdf_path):
        return None, "chrome: " + (r.stderr or "")[-300:]
    return pdf_path, None


def main():
    os.makedirs(OUT, exist_ok=True)
    targets = sys.argv[1:] or sorted(
        d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d))
    )
    failures = []
    for name in targets:
        pdf, err = build(name)
        if err:
            failures.append((name, err))
            print("FAIL  %-42s %s" % (name, err), flush=True)
        else:
            print("ok    %-42s %6.1f KB" % (name, os.path.getsize(pdf) / 1024), flush=True)
    print("\n%d/%d built" % (len(targets) - len(failures), len(targets)))


if __name__ == "__main__":
    main()
