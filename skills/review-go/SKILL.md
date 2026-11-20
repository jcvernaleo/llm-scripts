---
name: review-go
description: Security-focused code review of one Go package, with findings at Critical through Informational severity.
argument-hint: <package-dir>
allowed-tools: Bash(git *), Bash(go *), Bash(grep *), Read, Write
---

Perform a security-focused code review of the Go package in $ARGUMENTS.

## Role
You are a senior Go security reviewer.  Your task is to find bugs that matter
(security vulnerabilities first, then reliability and correctness problems),
assess their severity, and recommend fixes for the package in scope.

## Scope and context
- `$ARGUMENTS` is one package directory, relative to the repository root (as
  listed in `review-go/AUDIT-CHECKLIST.md`).  If it does not exist or has no
  `.go` files, stop and report the error.
- In scope: every non-test `.go` file in that directory (not
  subdirectories, which are separate packages).  Generated files
  (`// Code generated ... DO NOT EDIT.`) are context only.
- Read the package's `_test.go` files to learn intended behavior and what is
  already tested, but do not report findings against test code.
- Trace data across package boundaries: read the in-repo packages this one
  imports, and find its callers (`grep -rn '"<import path>"' --include=*.go`)
  to learn which inputs are untrusted when they reach it.
- If `review-go/tools.md` exists, read the parts of each tool's output that
  mention files in this package.  Treat them as leads: confirm each against the
  code before reporting it, and report only the ones that hold up.
  `govulncheck` vulnerabilities reported as called from this package are
  findings in this package.

## Methodology
1. **Scan** the package for the patterns in the checklist below, and for
   logic errors specific to what the package does
2. **Classify** each finding by severity (Critical/High/Medium/Low/Info)
3. **Analyze** Critical and High findings by tracing the path from an
   untrusted input (network request, file, CLI argument, environment, message
   from another service) to the problem
4. **Report** all findings in the structured format below

## Vulnerability Checklist
Scan for these patterns in every package:
- [ ] Injection: SQL built with `fmt.Sprintf`/string concatenation, `os/exec`
      with user-controlled arguments or `sh -c`, `text/template` used for HTML,
      header/log injection
- [ ] Path traversal: user input in `filepath.Join`/`os.Open` without
      `filepath.IsLocal`/`os.Root` or an equivalent check; archive extraction
      (zip slip)
- [ ] SSRF and open redirects: user-controlled URLs in outbound requests or
      redirects
- [ ] Authentication and authorization: missing or bypassable checks,
      comparing secrets without `crypto/subtle`, IDOR
- [ ] Crypto and TLS misuse: `math/rand` for secrets or tokens,
      `InsecureSkipVerify`, weak `MinVersion`, weak or homemade crypto,
      hardcoded keys
- [ ] Ignored errors: discarded `error` returns that skip a check or leave
      state inconsistent (`_ =`, unchecked `Close` on writes, unchecked
      `rows.Err()`)
- [ ] Panics reachable from input: nil maps/pointers, out-of-range index or
      slice, unchecked type assertions, division by zero, `panic` in request
      paths without `recover`
- [ ] Concurrency: data races on shared maps/slices/fields, missing or
      inconsistent locking, goroutine leaks, missing `context` cancellation,
      `sync.WaitGroup` misuse, closed-channel sends
- [ ] Resource exhaustion: `io.ReadAll` or decoding of unbounded input,
      missing `http.MaxBytesReader`, missing server/client timeouts,
      unbounded allocations, maps or goroutines sized by input
- [ ] Integer issues: overflow, truncating conversions (`int64` → `int32`,
      signed ↔ unsigned) used for sizes, indexes, or limits
- [ ] `unsafe` and cgo: pointer arithmetic, lifetime and aliasing errors
- [ ] Secrets and sensitive data: secrets in logs, errors, or responses;
      overly broad file permissions (`0644`/`0777` for secrets)
- [ ] Known-vulnerable dependencies used by this package (`govulncheck`)

## Severity Definitions
- **Critical**: Remote code execution, authentication or authorization
  bypass, or remote data loss or corruption, with no preconditions
- **High**: The same harms with preconditions; a remotely triggerable crash
  or panic; exposure of secrets or sensitive data
- **Medium**: Denial of service under load, resource leaks, data races with
  real impact, weak crypto or TLS settings
- **Low**: Best-practice violations with no direct impact
- **Informational**: Code quality and documentation

## Report Format
Keep the report concise.  Scale the detail of each finding to its severity:

| Severity | Description | Proof of concept | Recommended fix | Regression test |
|---|---|---|---|---|
| Critical / High | Full | Step-by-step | With code | Go test |
| Medium | Full | Short | With code | Only if the PoC is not obvious |
| Low | Brief | Brief numbered steps, only if needed to show the issue is real | One or two sentences; code only if a few lines | None |
| Informational | — | — | — | — |

Regression tests are ordinary Go tests (a `_test.go` file in the package,
using `testing`, and `net/http/httptest` where useful) that fail before the
fix and pass after it.

Informational findings get no section of their own.  They appear only as rows in
the `## Informational` table (ID, location, issue, suggestion), with each cell a
single short sentence or less.

Every finding (all severities) gets an ID (`F-01`, `F-02`, …) and a row in the
`## Findings Summary` table.  Number Critical first, then High, Medium, Low, and
Informational last.

Do not include:
- A description of what the package does or how it is structured
- A per-check verification table, or a walk through the vulnerability checklist
  item by item.  The "Areas verified" list replaces both.
- A list of tool reports that did not hold up.  At most, one "Areas verified"
  bullet summarizing them (e.g. "4 gosec reports checked; none exploitable").
- A closing summary, totals section, or "Top N recommendations" list.  The
  Findings Summary table already covers this.

## Output File

When the review is complete, write the full report to a markdown file named
`audit-<scope>-<date>.md` in the `review-go/` directory, where:
- `<scope>` is the package directory with `/` replaced by `-` (e.g.
  `internal-rpc` for `internal/rpc`).  For the root package (`.`), use the
  last element of the module path in `go.mod`.  This keeps scopes unique when
  two packages share a name.
- `<date>` is the current date in `YYYYMMDD` format (e.g.
  `review-go/audit-internal-rpc-20261120.md`).

The `audit-` prefix is required: `/audit-report` and `/audit-brief` read
`audit-*.md`.  Create the `review-go/` directory if it does not exist.

Before writing the file, run `git config user.email` to get the calling user's
email for the Reviewer field.

The file must be structured as follows:

````
# Go Code Security Review
**Date:** YYYY-MM-DD
**Reviewer:** <git config user.email> & Claude
**Scope:** <package directory reviewed>
**Repository:** <git remote origin URL>
**Commit:** <full git commit hash>

## Executive Summary
**Overall risk:** Critical / High / Medium / Low

<2–4 sentences: the most important result and anything the reader must know.
Do not describe what the package does.>

**Areas verified:**
- <one line per area, at most about 6 bullets, e.g. "Every handler bounds
  request body size", "All shared state is accessed under `mu`">

## Findings Summary
| ID | Severity | Title |
|----|----------|-------|
| F-01 | High | ... |
| F-02 | Low | ... |
| F-03 | Informational | ... |
...

## Findings

### F-01 [HIGH] <Title>
**File:** `...`
**Function:** `...`
**Lines:** ...

**Description**
...

**Proof of Concept**
...

**Recommended Fix**
```go
...
```

**Regression Test**
```go
...
```

---
(repeat for each Critical, High, Medium, and Low finding, omitting the parts
the Report Format table says to leave out for that severity)

## Informational
| ID | Location | Issue | Suggestion |
|----|----------|-------|------------|
| F-03 | `handler.go:42` | ... | ... |
````

Omit the `## Findings` section if there are no Critical, High, Medium, or Low
findings, and omit the `## Informational` section if there are no Informational
findings.

If there are no findings at all, the report is just the header block,
`**Overall risk:**`, one sentence giving the result, and `## Findings Summary`
containing `No findings.`

After writing the file, print the path to the report.

## Checklist Update

After writing the report, check whether `review-go/AUDIT-CHECKLIST.md` exists.
If it does:

1. Find the checklist item matching the reviewed package directory (the
   backtick-quoted path equals `$ARGUMENTS`, ignoring a leading `./` or a
   trailing `/`).
2. Mark it complete and append the report filename and findings summary:
   - Change `- [ ]` to `- [x]`
   - Append ` (\`<report-filename>\`) — <summary>` at the end of the line, where
     `<report-filename>` is the basename of the report file (e.g.
     `audit-internal-rpc-20261120.md`) and `<summary>` lists only severities
     with at least one finding, in order Critical → High → Medium → Low →
     Informational, e.g. `— 1 High, 2 Low, 3 Informational`, or
     `— No findings` if there are none.  If the line has a `← Round N: ...`
     annotation, insert the appended text before it.
3. Tally all findings across every checked-off item and update the total line
   at the end of the file.  The total line must be the last line and have the
   format:
   `**Total: X Critical, X High, X Medium, X Low, X Informational**`
   listing only severities with at least one finding across all completed
   items.  If no item has findings, use `**Total: No findings**`.  If the total
   line does not yet exist, append it.  If it does exist, replace it.

## Rules
- Never skip a file in the package, even if it looks simple
- Always follow untrusted input across package boundaries, not just within
  this package
- Flag every exported function or handler that acts on untrusted input
  without validation
- If a finding is uncertain, mark it as "Needs Manual Review"
- Do not modify any source or test files; Recommended Fix and Regression Test
  code goes in the report only
- The markdown file is mandatory: always write it, even if there are no
  findings
- Check everything thoroughly, but write only what the reader needs.  Thorough
  analysis does not mean a long report.
