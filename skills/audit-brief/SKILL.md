---
name: audit-brief
description: Generate a brief PDF audit or review report with only the basic info table and the Critical, High, and Medium findings.
argument-hint: [directory]
allowed-tools: Bash, Read, Write
---

Generate a brief PDF report from the current round's markdown files in an
audit or review directory.  The brief report is a short companion to the full
`/audit-report` PDF: it holds only the basic info table and the Critical, High,
and Medium findings, and names the full report file for everything else.

## Step 0: Resolve the report directory

Take the directory from `$ARGUMENTS`, dropping any trailing `/`.  If
`$ARGUMENTS` is empty, use `audit`.  Call it `<dir>` below.

`<dir>` must be `audit` (Solidity, written by `/audit`) or `review-<lang>`
(written by `/review-<lang>`, e.g. `review-go`).  If it is anything else, or the
directory does not exist, stop and report the error.

Set these from `<dir>` (the same values `/audit-report` uses):

| `<dir>` | `<title>` | `<kind>` | `<auditor label>` |
|---|---|---|---|
| `audit` | `Smart Contract Audit Report` | `Audit` | `Auditor` |
| `review-go` | `Go Code Review Report` | `Review` | `Reviewer` |
| `review-rust` | `Rust Code Review Report` | `Review` | `Reviewer` |
| `review-js` | `JavaScript Code Review Report` | `Review` | `Reviewer` |

For any other `review-<lang>`, use `<Lang> Code Review Report` with the
language name capitalized, `Review`, and `Reviewer`.

All files below are read from and written to `<dir>/`.  The per-file reports
are named `audit-*.md` and the checklist `AUDIT-CHECKLIST.md` in every
directory, including review directories.

## Step 1: Check checklist completion

Read `<dir>/AUDIT-CHECKLIST.md`. If it does not exist, stop and report that no
checklist was found.

Scan the `## Progress` section for any unchecked items (`- [ ]`). If any are
found, stop and explain which items are still incomplete and that the PDF will
not be generated until all audit items are checked off.

## Step 2: Locate files

Look for the following in the `<dir>/` directory (not in `<dir>/round-*/`):
- `AUDIT-CHECKLIST.md` — used for the completeness check and severity totals
  only; it is NOT included in the PDF
- `audit-*.md` — the current round's individual audit reports
- `<dir>-report-*.pdf` — the full report.  Use the newest one (the highest
  `YYYYMMDD` in the filename).  Call its filename (without the `<dir>/`
  directory) the *full report filename*, e.g. `audit-report-20261103.pdf` or
  `review-go-report-20261103.pdf`.

If no `audit-*.md` files are found, stop and report the error.

If no `<dir>-report-*.pdf` is found, stop and tell the user to run
`/audit-report <dir>` first (plain `/audit-report` for `audit`), since the
brief report must name the full report.

If any current-round `audit-*.md` file is newer (by modification time) than
the full report PDF, warn the user that the full report may be out of date and
suggest re-running `/audit-report <dir>`, then continue.

## Step 3: Write a CSS stylesheet

Write the following stylesheet to `/tmp/audit-brief.css` (the same stylesheet
as `/audit-report`):

```css
@page {
    size: A4;
    margin: 2cm;
}

body {
    font-family: "DejaVu Sans", sans-serif;
    font-size: 11pt;
    line-height: 1.5;
    color: #1a1a1a;
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
    overflow-wrap: anywhere;
}

pre {
    background: #f4f4f4;
    border-left: 3px solid #ccc;
    padding: 1em;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
    font-size: 0.85em;
}

pre code {
    background: none;
    padding: 0;
    white-space: pre-wrap;
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
    overflow-wrap: anywhere;
}

th { background: #f0f0f0; font-weight: bold; }
tr:nth-child(even) { background: #fafafa; }

hr { border: none; border-top: 1px solid #ccc; margin: 2em 0; }

.page-break { page-break-before: always; }
```

## Step 4: Build the brief markdown document

Use only the current round's files.  Never include anything from
`AUDIT-CHECKLIST.md`, `<dir>/round-*/`, `tob-maturity.md`, `tob-prep.md`, or
`tools.md` other than the counts and checks described below.

Build a single markdown document in this order:

1. **Basic info table** (generated):

   Read the metadata lines (`**Date:**`, `**Auditor:**` or `**Reviewer:**`,
   `**Scope:**`, `**Repository:**`, `**Commit:**`) from the top of every
   current-round `audit-*.md` file and produce:

   ```
   | | |
   |---|---|
   | **Report date** | <today, YYYY-MM-DD> |
   | **<kind> date(s)** | <distinct dates, ascending, comma-separated> |
   | **<auditor label>** | <distinct auditors> |
   | **Repository** | <distinct repository URLs> |
   | **Commit** | <distinct full commit hashes> |
   | **Scope** | <every scope, comma-separated, in report filename order> |
   | **<kind> round** | <N, where N = 1 + number of <dir>/round-*/ directories> |
   | **Full report** | `<full report filename>` |
   ```

   For any field where reports disagree, list every distinct value (one per
   line, separated with `<br>`). Do NOT add a top-level `#` title here — pandoc
   renders the document title from the `--metadata title` option.

   Directly below the table, add this line:

   ```
   *This brief report covers Critical, High, and Medium findings only.  See the full report, `<full report filename>`, for all findings and details.*
   ```

2. **Findings summary** (generated): a `# Findings Summary` section containing:

   - A severity count table built from the `**Total:**` line of
     `<dir>/AUDIT-CHECKLIST.md`, listing only Critical, High, and Medium.
     Treat any severity not mentioned as 0:

     ```
     | Severity | Count |
     |----------|-------|
     | Critical | 0 |
     | High | 1 |
     | Medium | 2 |
     | **Total** | **3** |
     ```

   - A combined findings table listing every Critical, High, and Medium
     finding from every current-round `audit-*.md` file, taken from each
     report's `## Findings Summary` table.  Prefix each ID with the report's
     scope, exactly as `/audit-report` does (e.g. `Vault F-01`), so the IDs
     match the full report.  Sort by severity (Critical → Medium), then by
     report filename, then by ID:

     ```
     | ID | Severity | Title |
     |----|----------|-------|
     | Vault F-01 | High | ... |
     | Router F-01 | Medium | ... |
     ```

     If there are no Critical, High, or Medium findings, write
     `No Critical, High, or Medium findings.` instead of the table, and skip
     section 3.

3. **Findings** (only if there is at least one Critical, High, or Medium
   finding):

   Insert a page break, then a `# Findings` heading.  Then, in the same order
   as the combined findings table, copy each finding's write-up from its
   report's `## Findings` section.  A write-up starts at its
   `### F-NN [SEVERITY] <Title>` heading and runs up to the next `###` or `##`
   heading (ignore lines inside fenced code blocks when looking for headings).
   Copy it verbatim, with these changes in the brief document only:
   - Change the heading to `## <scope> F-NN [SEVERITY] <Title>`, using the same
     scope-prefixed ID as the findings table.
   - Drop any trailing `---` separator line.

   Separate consecutive write-ups with a `---` line.

   Do not include any Low or Informational write-up, any `## Informational`
   table, or any `## Executive Summary`.

4. **Closing note**: end the document with:

   ```
   ---

   *Low and Informational findings, the per-scope executive summaries, the
   round-over-round comparison, and the appendices are in the full report,
   `<dir>/<full report filename>`.*
   ```

Insert page breaks by placing this line, followed by a blank line, before the
heading:

```
<div class="page-break"></div>
```

Write the combined content to `/tmp/audit-brief.md`.

## Step 5: Convert to PDF

Run pandoc to produce an HTML file, then weasyprint to produce the PDF:

```bash
pandoc /tmp/audit-brief.md \
  --from markdown \
  --to html \
  --standalone \
  --css /tmp/audit-brief.css \
  --metadata title="<title> (Brief)" \
  -o /tmp/audit-brief.html
```

```bash
python3 -m weasyprint /tmp/audit-brief.html <dir>/<dir>-brief-<date>.pdf
```

Where `<date>` is today's date in `YYYYMMDD` format (e.g.
`audit/audit-brief-20261120.pdf`, `review-go/review-go-brief-20261120.pdf`).

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
rm -f /tmp/audit-brief.css /tmp/audit-brief.md /tmp/audit-brief.html
```

## Step 7: Report

Print the path to the generated PDF, the full report filename it refers to,
and the number of Critical, High, and Medium findings it includes.

## Rules

- Preserve the order: basic info table, findings summary, findings, closing
  note
- Never include Low or Informational findings, executive summaries, the
  round-over-round comparison, prior rounds, ToB output, `tools.md`, or
  `AUDIT-CHECKLIST.md`
- Finding IDs must match the full report (`<scope> F-NN`)
- Do not modify any source markdown files or the full report PDF; all
  transforms apply only to the brief document in `/tmp`
- If pandoc or weasyprint is not available, report the missing tool and remind
  the user to rebuild the container (`./ai-devcontainer.sh update`)
