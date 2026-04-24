[//]: # (Re-audit preparation command: archive the current audit round and produce a new checklist informed by prior findings.)

Prepare a new audit round for a project that has already been audited.

## Step 1: Verify existing audit artifacts

Check that `audit/AUDIT-CHECKLIST.md` exists. If it does not, stop and tell the
user to run `/pre-audit` instead — there is no prior round to build on.

Check that all items in the `## Progress` section are checked off (`- [x]`). If
any are incomplete, stop and list the outstanding items — the prior round must
be finished before archiving it.

## Step 2: Determine the round number

Look for existing `audit/round-*/` directories. The new round number is one
higher than the highest existing round (e.g. if `audit/round-1/` exists, archive
to `audit/round-2/`). If no round directories exist, archive to `audit/round-1/`.

## Step 3: Archive the current round

Create the `audit/round-N/` directory. Move into it:
- `audit/AUDIT-CHECKLIST.md`
- All `audit/audit-*.md` files
- All `audit/audit-*.pdf` files
- `audit/tob-prep.md` (if present)
- `audit/tob-maturity.md` (if present)

Do not move the `audit/round-*/` subdirectories themselves.

## Step 4: Verify the build

Run `forge build`. If it fails, report the errors and stop — do not proceed
until the code compiles cleanly.

## Step 4a: Trail of Bits — Audit Preparation

Invoke the `building-secure-contracts:audit-prep-assistant` skill. When it
completes, write its full output to `audit/tob-prep.md`.

## Step 4b: Trail of Bits — Code Maturity Assessment

Invoke the `building-secure-contracts:code-maturity-assessor` skill. When it
completes, write its full output to `audit/tob-maturity.md`.

## Step 5: Inspect the codebase

Read all Solidity source files (typically under `src/`, `contracts/`, or as
configured in `foundry.toml`). For each contract, note:

- Contract name and file path
- Contract type (interface, abstract, library, base contract, core contract)
- What it does (one sentence)
- What it imports / inherits from
- Whether it handles funds, access control, or external calls

## Step 6: Collect prior findings per file

For each source file identified in Step 5, scan all archived round checklists
(`audit/round-*/AUDIT-CHECKLIST.md`) to find the most recent checked-off entry
matching that file. Extract the findings summary (e.g. `1 High, 2 Low`) from
that entry. If a file has no prior findings, note `No prior findings`.

## Step 7: Build the new checklist

Write `audit/AUDIT-CHECKLIST.md` using the same ordering rules as `/pre-audit`
(dependencies first, critical contracts last). Use this format:

```
# Audit Checklist — `<repo or project name>`

Scope: <brief description of what is in scope>
Order: <one line describing the ordering rationale>
Round: <N> (prior round archived to `audit/round-<N-1>/`)

---

## Progress

- [ ] `<file-or-path>` — <contract name(s) and one-phrase description>  ← Round <N-1>: <prior findings summary>
- [ ] `<file-or-path>` — <contract name(s) and one-phrase description>  ← Round <N-1>: No prior findings
```

Rules for the prior-findings annotation:
- Always include the `← Round N:` suffix for every item, even if there were no findings
- Use the findings summary from the most recent archived round for that file
- This annotation is read-only context for the auditor; it is not part of the
  checked-off format (which remains: `- [x] \`path\` — description (\`report.md\`) — findings`)

After writing the file, print the path, the round number, and a one-sentence
summary of what was archived.
