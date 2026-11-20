---
name: pre-review
description: Pre-review preparation for non-Solidity code (Go for now): verify the build, run static analysis tools, and produce an ordered review checklist. Auto-detects first run vs re-review.
argument-hint: [lang]
allowed-tools: Bash, Read, Write
---

Prepare a code review plan for the project in the current directory.  This is
the `/pre-audit` equivalent for non-Solidity code; Solidity uses `/pre-audit`.

## Step 0: Determine the language

If `$ARGUMENTS` names a language, use it (`go`; `golang` means `go`).

Otherwise detect it from the project root, ignoring `vendor/`, `node_modules/`,
`testdata/`, and `.git/`:
- `go.mod` or `go.work` → `go`
- `Cargo.toml` → `rust`
- `package.json` → `js`

If more than one language is detected, stop and ask the user which one to
review, e.g. `/pre-review go`.  If none is detected, stop and report that no
supported project was found.

Only `go` is supported so far.  For any other language, stop and report:
> ✗ `/pre-review` does not support `<lang>` yet (no `/review-<lang>` skill).

Call the review directory `<dir>` = `review-<lang>` (e.g. `review-go`).  Never
read or write `audit/`; that belongs to the Solidity pipeline.

## Step 1: Detect review state

Check whether `<dir>/AUDIT-CHECKLIST.md` exists.  (The file keeps the
`AUDIT-CHECKLIST.md` name so `/audit-report` and `/audit-brief` can read it.)

- **Not found** → first review.  Proceed to Step 2 (First-run path).
- **Found with unchecked items** (`- [ ]` present in `## Progress`) → stop and
  report which items are still incomplete.  The current round must be
  finished before starting a new one.
- **Found with all items checked off** → re-review.  Skip to Step 5
  (Re-review path).

---

## First-run path (Steps 2–4)

## Step 2: Verify the build

Find the Go modules: the directories containing a `go.mod`, excluding anything
under `vendor/` or `testdata/`.  If a `go.work` exists at the root, use the
modules it lists instead.  Run every command in Steps 2–3 once per module, from
that module's root.

Run `go build ./...`.  If it fails, report the errors and stop.  Do not proceed
until the code compiles cleanly.

## Step 3: Run the static analysis tools

Create `<dir>/` if it does not exist.

Get the versions with `go version`, `staticcheck -version`, `gosec -version`,
and `govulncheck -version`.  If one of the tools is not installed, print:
> ⚠ `<tool>` not found.  It is installed in the `go` lang container; rebuild
> with `./ai-devcontainer.sh update`.  Continuing without it.

and record it as "not installed" in the summary.

Run each available tool and keep its full output and exit status.  A non-zero
exit only means it reported something, so never stop on it:

```bash
go vet ./... 2>&1
staticcheck ./... 2>&1
gosec -quiet -exclude-generated -fmt=text ./... 2>&1
govulncheck ./... 2>&1
timeout 900 go test -race -count=1 ./... 2>&1
```

- `govulncheck` fetches its database from `vuln.go.dev`.  If it fails with a
  network error, record "not run: network error" and continue.
- `go test -race` is best effort.  Test failures, missing services, and the
  15-minute timeout are recorded, not treated as errors.  Any `WARNING: DATA
  RACE` report is significant: list each race's package and the first frames
  of both stacks in the summary notes.

Write `<dir>/tools.md` in this format:

````
# Static Analysis Tools — `<repo or project name>`

**Date:** YYYY-MM-DD
**Commit:** <full git commit hash>

## Summary

| Tool | Version | Result |
|------|---------|--------|
| go vet | go1.26.11 | 2 reports |
| staticcheck | 2026.2.2 (v0.8.2) | 5 reports |
| gosec | 2.30.0 | 3 issues (1 HIGH, 2 MEDIUM) |
| govulncheck | v1.10.0 | 1 vulnerability in called code (GO-2026-1234) |
| go test -race | go1.26.11 | 12 packages ok, 1 failed, no data races |

<Notes, only if needed: a short bullet per data race, per govulncheck
vulnerability that is actually called, and per tool that was not run, with
the reason.  No commentary on whether reports are real; that is for
`/review-go`.>

## go vet
```text
<full output, or "No output.">
```

## staticcheck
...
````

- The `## Summary` section is the only part `/audit-report` puts in the PDF,
  so keep it short: one table row per tool, results in a few words.
- Use one `##` section per tool after the summary, with its full output in a
  `text` fenced block.  Do not truncate.
- With more than one module, prefix each result with the module path, or use
  one row per tool per module if the results differ.

## Step 4: Inspect, plan, and write the checklist

List the packages with their in-repo imports:

```bash
go list -f '{{.Dir}}|{{.ImportPath}}|{{join .Imports " "}}' ./...
```

Skip packages under `vendor/` or `testdata/`, and packages whose non-test files
are all generated (first comment line matches `// Code generated ... DO NOT
EDIT.`).  Within a package that is kept, generated files are context only.

Read the non-test source of every remaining package.  For each package, note:
- Its directory, relative to the repository root (`.` for the root package)
- What it does (one phrase)
- Which in-repo packages it imports
- Whether it handles untrusted input (network, files, CLI, environment),
  authentication or authorization, secrets or crypto, concurrency, or
  `unsafe`/cgo

Order the packages so that dependencies are reviewed before the packages that
use them:
- Packages that import no other in-repo package first (utilities, types)
- Then up the import graph
- Entry points last: `main` packages (`cmd/...`) and packages that expose
  HTTP/RPC/gRPC handlers or other network listeners
- Use `<dir>/tools.md` to flag packages with tool reports, but put no
  findings in the checklist
- Each entry is a single package directory, exactly what will be passed to
  `/review-go`.  Never group packages on one line; note coupling in the
  description instead (e.g. "— pairs with `internal/store`")

Write `<dir>/AUDIT-CHECKLIST.md` using this exact format:

```
# Review Checklist — `<repo or project name>`

Scope: <what is in scope, and what was skipped, e.g. "all Go packages; skipped `vendor/`, `testdata/`, and generated `internal/pb`">
Order: <one line describing the ordering rationale, e.g. "import graph, leaves first; `cmd/` entry points last">

---

## Progress

- [ ] `<package-dir>` — <package name and one-phrase description>
- [ ] `<package-dir>` — <package name and one-phrase description>
```

Rules for the checklist:
- One line per package directory; the path must be usable directly as
  `/review-go <path>`
- Each line: checkbox, path in backticks, em dash, brief description only
- No headers beyond `## Progress`
- No tables, no "Why" prose, no Notes section
- No findings, observations, or risk commentary; those belong in the review
  reports
- As reviews are completed, `/review-go` checks lines off and appends the
  report filename and finding counts, e.g.:
  `- [x] \`internal/rpc\` — rpc: JSON-RPC handlers (\`audit-internal-rpc-20261120.md\`) — 1 High, 2 Low`
- A totals line is added at the end once items are checked off

Print the paths of all files written, the tool summary table, and a
one-sentence summary of the scope.  Then stop; do not continue to Step 5.

---

## Re-review path (Steps 5–8)

## Step 5: Determine the round number

Look for existing `<dir>/round-*/` directories.  The new round number is one
higher than the highest existing round (e.g. if `<dir>/round-1/` exists,
archive to `<dir>/round-2/`).  If no round directories exist, archive to
`<dir>/round-1/`.

## Step 6: Archive the current round

Create the `<dir>/round-N/` directory.  Move into it:
- `<dir>/AUDIT-CHECKLIST.md`
- All `<dir>/audit-*.md` files
- All `<dir>/*.pdf` files
- `<dir>/tools.md` (if present)

Do not move the `<dir>/round-*/` subdirectories themselves.

## Step 7: Verify the build and run the tools

Repeat Steps 2 and 3 (build must pass; write a new `<dir>/tools.md`).

## Step 8: Inspect, plan, and write the annotated checklist

Inspect and order the packages as in Step 4.  For each package, also scan all
archived round checklists (`<dir>/round-*/AUDIT-CHECKLIST.md`) to find the
most recent checked-off entry for that package directory and extract its
findings summary (e.g. `1 High, 2 Low`).  If a package has no prior entry,
note `No prior findings`.

Write `<dir>/AUDIT-CHECKLIST.md` using this format:

```
# Review Checklist — `<repo or project name>`

Scope: <what is in scope, and what was skipped>
Order: <one line describing the ordering rationale>
Round: <N> (prior round archived to `<dir>/round-<N-1>/`)

---

## Progress

- [ ] `<package-dir>` — <package name and one-phrase description>  ← Round <N-1>: <prior findings summary>
- [ ] `<package-dir>` — <package name and one-phrase description>  ← Round <N-1>: No prior findings
```

Rules:
- The same rules as Step 4
- Always include the `← Round N:` suffix for every item, even with no
  findings
- The `← Round N:` annotation is read-only context for the reviewer; it is not
  part of the checked-off format

Print the path, the round number, the tool summary table, and a one-sentence
summary of what was archived.
