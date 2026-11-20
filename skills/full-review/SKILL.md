---
name: full-review
description: Run the complete code review pipeline for non-Solidity code (Go for now): pre-review, review each checklist item, generate the full and brief PDF reports.
argument-hint: [lang]
allowed-tools: Bash, Read, Write
---

Run the complete code review pipeline for the project in the current
directory.  This is the `/full-audit` equivalent for non-Solidity code;
Solidity uses `/full-audit`.

## Step 0: Determine the language

Determine `<lang>` exactly as `/pre-review` Step 0 does: from `$ARGUMENTS`
(`golang` means `go`), or by detection (`go.mod`/`go.work` → `go`,
`Cargo.toml` → `rust`, `package.json` → `js`).  If more than one language is
detected, stop and ask which one to review.  If the language has no
`/review-<lang>` skill (only `go` so far), stop and report that it is not
supported yet.

Set `<dir>` = `review-<lang>`.

## Step 1: Detect state

Check whether `<dir>/AUDIT-CHECKLIST.md` exists and whether it has any
unchecked items (`- [ ]`).

- **No checklist** → proceed to Step 2 (full run from scratch).
- **Checklist exists with unchecked items** → a previous run was interrupted.
  Skip to Step 3 (resume from the first unchecked item).  Print a note listing
  the already-completed items so the user knows where resumption begins.
- **Checklist exists, all items checked** → proceed to Step 2 (re-review run:
  pre-review will archive the current round and start fresh).

## Step 2: Pre-review

Invoke the `pre-review` skill with `<lang>` as the argument.  Wait for it to
complete fully before continuing.  If it stops with an error (build failure,
etc.), stop here and report the error.

## Step 3: Review each checklist item

Read `<dir>/AUDIT-CHECKLIST.md` and collect all unchecked items (`- [ ]`) from
the `## Progress` section, in order.

For each unchecked item:
1. Extract the package directory from the backtick-quoted path on that line.
2. Invoke the `review-<lang>` skill with that path as the argument.
3. Wait for it to complete fully before moving to the next item.
4. If the review fails, stop immediately and report which item failed and why.

## Step 4: Generate report

Invoke the `audit-report` skill with `<dir>` as the argument.  Wait for it to
complete fully.  If it fails, stop here and report the error.

## Step 5: Generate brief report

Invoke the `audit-brief` skill with `<dir>` as the argument.  Wait for it to
complete fully.  If it fails, report the error, but still print the Step 6
summary (the full report was already generated).

## Step 6: Report

Print a summary:
- The language and review directory
- How many items were reviewed this run
- Path to the generated full PDF
- Path to the generated brief PDF (or the error, if Step 5 failed)
- Total findings (from the checklist's `**Total:**` line)
