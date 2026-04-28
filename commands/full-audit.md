[//]: # (Full audit pipeline: pre-audit, audit each checklist item, then generate the PDF report.)

Run the complete audit pipeline for the project in the current directory.

## Step 1: Detect state

Check whether `audit/AUDIT-CHECKLIST.md` exists and whether it has any
unchecked items (`- [ ]`).

- **No checklist** → proceed to Step 2 (full run from scratch).
- **Checklist exists with unchecked items** → a previous run was interrupted.
  Skip to Step 3 (resume from the first unchecked item). Print a note listing
  the already-completed items so the user knows where resumption begins.
- **Checklist exists, all items checked** → proceed to Step 2 (re-audit run:
  pre-audit will archive the current round and start fresh).

## Step 2: Pre-audit

Invoke the `pre-audit` skill. Wait for it to complete fully before continuing.
If it stops with an error (build failure, etc.), stop here and report the error.

## Step 3: Audit each checklist item

Read `audit/AUDIT-CHECKLIST.md` and collect all unchecked items (`- [ ]`) from
the `## Progress` section, in order.

For each unchecked item:
1. Extract the file or directory path from the backtick-quoted path on that line.
2. Invoke the `audit` skill with that path as the argument.
3. Wait for it to complete fully before moving to the next item.
4. If the audit fails, stop immediately and report which item failed and why.

## Step 4: Generate report

Invoke the `audit-report` skill. Wait for it to complete fully.

## Step 5: Report

Print a summary:
- How many items were audited this run
- Path to the generated PDF
- Total findings (from the checklist's `**Total:**` line)
