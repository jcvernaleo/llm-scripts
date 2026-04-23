[//]: # (Generate a combined PDF report from all audit markdown files.)

Generate a combined PDF audit report from all markdown files in the `audit/` directory.

## Step 1: Check checklist completion

Read `audit/AUDIT-CHECKLIST.md`. If it does not exist, stop and report that no
checklist was found.

Scan the `## Progress` section for any unchecked items (`- [ ]`). If any are
found, stop and explain which items are still incomplete and that the PDF will
not be generated until all audit items are checked off.

## Step 2: Locate audit files

Look for the following in the `audit/` directory:
- `AUDIT-CHECKLIST.md` — progress tracker (include first)
- `audit-*.md` — individual audit reports (include in filename order)

If no `audit-*.md` files are found, stop and report the error.

## Step 3: Write a CSS stylesheet

Write the following stylesheet to `/tmp/audit-report.css`:

```css
body {
    font-family: "DejaVu Sans", sans-serif;
    font-size: 11pt;
    line-height: 1.5;
    color: #1a1a1a;
    max-width: 900px;
    margin: 0 auto;
    padding: 2em;
}

h1 { font-size: 2em; border-bottom: 2px solid #333; padding-bottom: 0.3em; }
h2 { font-size: 1.4em; border-bottom: 1px solid #ccc; padding-bottom: 0.2em; margin-top: 2em; }
h3 { font-size: 1.1em; margin-top: 1.5em; }

code {
    font-family: "DejaVu Sans Mono", monospace;
    font-size: 0.9em;
    background: #f4f4f4;
    padding: 0.1em 0.3em;
    border-radius: 3px;
}

pre {
    background: #f4f4f4;
    border-left: 3px solid #ccc;
    padding: 1em;
    overflow-x: auto;
    font-size: 0.85em;
}

pre code {
    background: none;
    padding: 0;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin: 1em 0;
}

th, td {
    border: 1px solid #ccc;
    padding: 0.4em 0.8em;
    text-align: left;
}

th { background: #f0f0f0; font-weight: bold; }
tr:nth-child(even) { background: #fafafa; }

hr { border: none; border-top: 1px solid #ccc; margin: 2em 0; }

.page-break { page-break-before: always; }
```

## Step 4: Concatenate the markdown files

Build a single combined markdown document:
1. Start with `audit/AUDIT-CHECKLIST.md` (if present)
2. Add a `---` separator between documents
3. Append each `audit-*.md` file in alphabetical filename order, separated by `---`

Write the combined content to `/tmp/audit-combined.md`.

## Step 5: Convert to PDF

Run pandoc to produce an HTML file, then weasyprint to produce the PDF:

```bash
pandoc /tmp/audit-combined.md \
  --from markdown \
  --to html \
  --standalone \
  --css /tmp/audit-report.css \
  --metadata title="Smart Contract Audit Report" \
  -o /tmp/audit-combined.html
```

```bash
python3 -m weasyprint /tmp/audit-combined.html audit/audit-report-<date>.pdf
```

Where `<date>` is today's date in `YYYYMMDD` format.

After running weasyprint, check whether the output PDF file exists and has
non-zero size — this is the only success criterion. Warnings and non-zero exit
codes from weasyprint can be ignored as long as the file was produced.

If the PDF file was not produced, or if pandoc failed, stop immediately, clean
up temp files, and tell the user what failed. Do NOT attempt any fallback tools
(no latex, no chromium, no pip installs, no apt-get). Instruct the user to
rebuild the container with `./ai-devcontainer.sh update`.

## Step 6: Clean up

Remove the temporary files:

```bash
rm -f /tmp/audit-report.css /tmp/audit-combined.md /tmp/audit-combined.html
```

## Step 7: Report

Print the path to the generated PDF and the list of source files it includes.

## Rules

- Preserve the order: checklist first, then audit reports chronologically
- Do not modify any source markdown files
- If pandoc or weasyprint is not available, report the missing tool and remind
  the user to rebuild the container (`./ai-devcontainer.sh update`)
