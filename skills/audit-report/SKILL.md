---
name: audit-report
description: Generate a combined PDF report from all audit markdown files.
allowed-tools: Bash, Read, Write
---

Generate a combined PDF audit report from all markdown files in the `audit/` directory.

## Step 1: Check checklist completion

Read `audit/AUDIT-CHECKLIST.md`. If it does not exist, stop and report that no
checklist was found.

Scan the `## Progress` section for any unchecked items (`- [ ]`). If any are
found, stop and explain which items are still incomplete and that the PDF will
not be generated until all audit items are checked off.

## Step 2: Locate audit files

Look for the following in the `audit/` directory:
- `AUDIT-CHECKLIST.md` — progress tracker (used for the completeness check and
  severity totals only; it is NOT included in the PDF)
- `audit-*.md` — individual audit reports (include in filename order)
- `tob-maturity.md`, `tob-prep.md` — Trail of Bits output (appendices, if present)

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

## Step 4: Build the combined markdown document

Never include any `AUDIT-CHECKLIST.md` (current or archived) in the combined
document.

Build a single combined markdown document in this order:

1. **Report header** (generated):

   Read the metadata lines (`**Date:**`, `**Auditor:**`, `**Scope:**`,
   `**Repository:**`, `**Commit:**`) from the top of every current-round
   `audit-*.md` file and produce:

   ```
   | | |
   |---|---|
   | **Report date** | <today, YYYY-MM-DD> |
   | **Audit date(s)** | <distinct dates, ascending, comma-separated> |
   | **Auditor** | <distinct auditors> |
   | **Repository** | <distinct repository URLs> |
   | **Commit** | <distinct full commit hashes> |
   | **Scope** | <every scope, comma-separated, in report filename order> |
   | **Audit round** | <N, where N = 1 + number of audit/round-*/ directories> |
   ```

   For any field where reports disagree, list every distinct value (one per
   line, separated with `<br>`). Do NOT add a top-level `#` title here — pandoc
   renders the document title from the `--metadata title` option.

2. **Findings summary** (generated): a `# Findings Summary` section containing:

   - A severity count table built from the `**Total:**` line of the current
     `audit/AUDIT-CHECKLIST.md`. Treat any severity not mentioned as 0, and
     list all five severities in order:

     ```
     | Severity | Count |
     |----------|-------|
     | Critical | 0 |
     | High | 0 |
     | Medium | 1 |
     | Low | 2 |
     | Informational | 3 |
     | **Total** | **6** |
     ```

   - A combined findings table listing every finding from every current-round
     `audit-*.md` file, taken from each report's `## Findings Summary` table.
     Each per-file report numbers its findings from F-01, so prefix each ID
     with the report's scope to keep IDs unique (e.g. `Vault F-01`). Sort by
     severity (Critical → Informational), then by report filename, then by ID:

     ```
     | ID | Severity | Title |
     |----|----------|-------|
     | Vault F-01 | Medium | ... |
     | Router F-02 | Low | ... |
     ```

     If there are no findings at all, write `No findings.` instead of the table.

3. **Round-over-round comparison** (only if at least one `audit/round-*/`
   directory exists):

   Generate a `# Round-over-Round Comparison` section. Build it as follows:

   - Read the `**Total:**` line from the current round's `AUDIT-CHECKLIST.md`
     and from the most recently archived round's `AUDIT-CHECKLIST.md` (the
     highest-numbered `audit/round-*/` directory).
   - Parse out the per-severity counts from each total line. Treat any severity
     not mentioned as 0.
   - Produce a markdown table with columns: Severity, Previous Round, Current
     Round, Change. For Change, use `+N` (red) or `-N` (green) or `—` for no
     change. List severities in order: Critical, High, Medium, Low, Informational.
   - Below the table, add a brief plain-English summary, e.g.:
     > Round 2 resolved 1 High and 2 Low findings from Round 1. 1 new Medium
     > finding was identified.

4. **Detailed findings**: each current-round `audit-*.md` file in alphabetical
   filename order. Before appending each file, transform its content in the
   combined document only:
   - Replace the leading `# Smart Contract Security Audit` heading with
     `# Detailed Findings: <scope>`
   - Remove the `**Date:**`, `**Auditor:**`, `**Scope:**`, `**Repository:**`,
     and `**Commit:**` lines (already shown in the report header)

5. **Appendices**:
   - If `audit/tob-maturity.md` exists, append it under the heading
     `# Appendix: Code Maturity Assessment (Trail of Bits)`
   - If `audit/tob-prep.md` exists, append it under the heading
     `# Appendix: Audit Preparation (Trail of Bits)`
   - If either file begins with a `#` top-level heading, replace that heading
     with the appendix heading rather than adding a second one.
   - Prior rounds (if any `audit/round-*/` directories exist), in ascending
     round order (`round-1/`, `round-2/`, etc.). For each round, insert a
     top-level heading `# Appendix: Round N Audit`, then append that round's
     `audit-*.md` files in alphabetical order (with the same header-stripping
     transform as step 4, but using `## Round N Findings: <scope>` as the
     heading), then its `tob-maturity.md` and `tob-prep.md` (if present),
     replacing any leading `#` heading in those with
     `## Round N: Code Maturity Assessment` or `## Round N: Audit Preparation`
     respectively. Do not include the round's `AUDIT-CHECKLIST.md`.

Insert a page break before each top-level section after the findings summary
(each detailed findings report, the round-over-round comparison, and each
appendix) by placing this line, followed by a blank line, before its heading:

```
<div class="page-break"></div>
```

Use `---` as the separator between documents only where no page break is
inserted.

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

- Preserve the order: report header, findings summary, round-over-round
  comparison, detailed findings, appendices
- Never include `AUDIT-CHECKLIST.md` in the PDF
- Do not modify any source markdown files; all transforms apply only to the
  combined document in `/tmp`
- If pandoc or weasyprint is not available, report the missing tool and remind
  the user to rebuild the container (`./ai-devcontainer.sh update`)
