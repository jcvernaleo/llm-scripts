[//]: # (Pre-audit preparation command: verify build and produce an ordered audit checklist.)

Prepare a smart contract audit plan for the project in the current directory.

## Step 1: Verify the build

Run `forge build`. If it fails, report the errors and stop — do not proceed until
the code compiles cleanly.

## Step 2: Inspect the codebase

Read all Solidity source files (typically under `src/`, `contracts/`, or as
configured in `foundry.toml`). For each contract, note:

- Contract name and file path
- Contract type (interface, abstract, library, base contract, core contract)
- What it does (one sentence)
- What it imports / inherits from
- Whether it handles funds, access control, or external calls

## Step 3: Build an ordered audit plan

Group contracts into audit batches, ordered so that dependencies are audited
before the contracts that use them. Apply these principles:

- Interfaces and libraries first (lowest risk, establish shared types)
- Base/abstract contracts before their children
- Core/critical contracts (fund custody, access control, entry points) last and in
  their own group so they receive the most focused attention
- Keep tightly coupled contracts in the same group when their interactions matter
- Each group should be a manageable scope for a single `/audit` run — prefer
  smaller focused groups over one large group

## Step 4: Write the checklist

Create the `audit/` directory if it does not exist. Write `audit/AUDIT-CHECKLIST.md`
with the following structure:

```
# Audit Checklist

**Repository:** <git remote origin URL>
**Commit:** <full git commit hash>
**Date:** YYYY-MM-DD
**Build:** Passed

## Contracts in Scope

| Contract | File | Type | Description |
|----------|------|------|-------------|
| ...      | ...  | ...  | ...         |

## Audit Plan

Work through the groups below in order. Run `/audit <path>` (or list individual
files) for each group. Check off each group when its audit report is complete.

### Group 1 — <descriptive name, e.g. "Libraries & Interfaces">
- [ ] `/audit <file-or-path>`
- [ ] `/audit <file-or-path>`

*Why this group:* <one sentence on what these share and why they come first>

### Group 2 — <descriptive name>
- [ ] `/audit <file-or-path>`

*Why this group:* ...

(continue for all groups)

## Notes

<any observations from the inspection worth flagging before the audit begins:
unusual patterns, complex inheritance chains, areas of elevated risk, etc.>
```

After writing the file, print the path and a brief summary of the plan.
