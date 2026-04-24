[//]: # (Pre-audit preparation command: verify build and produce an ordered audit checklist.)

Prepare a smart contract audit plan for the project in the current directory.

## Step 1: Verify the build

Run `forge build`. If it fails, report the errors and stop — do not proceed until
the code compiles cleanly.

## Step 2: Trail of Bits — Audit Preparation

Create the `audit/` directory if it does not exist.

Invoke the `building-secure-contracts:audit-prep-assistant` skill. When it
completes, write its full output to `audit/tob-prep.md`.

## Step 3: Trail of Bits — Code Maturity Assessment

Invoke the `building-secure-contracts:code-maturity-assessor` skill. When it
completes, write its full output to `audit/tob-maturity.md`.

## Step 4: Inspect the codebase

Read all Solidity source files (typically under `src/`, `contracts/`, or as
configured in `foundry.toml`). For each contract, note:

- Contract name and file path
- Contract type (interface, abstract, library, base contract, core contract)
- What it does (one sentence)
- What it imports / inherits from
- Whether it handles funds, access control, or external calls

## Step 5: Build an ordered audit plan

Order contracts so that dependencies are audited before the contracts that use
them. Apply these principles:

- Interfaces and libraries first (lowest risk, establish shared types)
- Base/abstract contracts before their children
- Core/critical contracts (fund custody, access control, entry points) last so
  they receive the most focused attention
- Keep tightly coupled contracts together when their interactions matter
- Each entry should be a manageable scope for a single `/audit` run — prefer
  smaller focused entries over one large group

Use findings from `audit/tob-prep.md` (Slither output, static analysis) to
inform the ordering and flag files that already have known issues.

## Step 6: Write the checklist

Write `audit/AUDIT-CHECKLIST.md` using this exact format — a lean progress
tracker, nothing more:

```
# Audit Checklist — `<repo or project name>`

Scope: <brief description of what is in scope, e.g. "all `src/` files changed relative to `main`">
Order: <one line describing the ordering rationale, e.g. "foundational → outward (storage → interfaces → utilities → core logic)">

---

## Progress

- [ ] `<file-or-path>` — <contract name(s) and one-phrase description>
- [ ] `<file-or-path>` — <contract name(s) and one-phrase description>
```

Rules for the checklist:
- One line per file (or tightly coupled file group) to audit
- Each line: checkbox, file path in backticks, em dash, brief description only
- No headers beyond `## Progress`
- No tables, no "Why this group" prose, no Notes section
- No findings, observations, or risk commentary — those belong in the audit reports
- As audit reports are completed, lines get checked off and the report filename
  plus finding counts are appended to that line, e.g.:
  `- [x] \`src/Foo.sol\` — Foo contract (`audit-Foo-2026-04-22.md`) — 1 Medium, 2 Low`
- A totals line is added at the end once all items are checked off

After writing the file, print the paths of all files written and a one-sentence
summary of the scope.
