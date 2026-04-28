[//]: # (Pre-audit preparation command: verify build and produce an ordered audit checklist. Auto-detects first run vs re-audit.)

Prepare a smart contract audit plan for the project in the current directory.

## Step 1: Detect audit state

Check whether `audit/AUDIT-CHECKLIST.md` exists.

- **Not found** → this is a first-time audit. Proceed to Step 2 (First-run path).
- **Found with unchecked items** (`- [ ]` present in `## Progress`) → stop and
  report which items are still incomplete. The current audit round must be
  finished before starting a new one.
- **Found with all items checked off** → this is a re-audit. Skip to Step 6
  (Re-audit path).

---

## First-run path (Steps 2–5)

## Step 2: Verify the build

Run `forge build`. If it fails, report the errors and stop — do not proceed until
the code compiles cleanly.

## Step 3: Trail of Bits — Audit Preparation

Create the `audit/` directory if it does not exist.

Check whether the `building-secure-contracts:audit-prep-assistant` skill is
available. If it is not, print a warning:
> ⚠ Trail of Bits `audit-prep-assistant` skill not found. Install the plugin
> with `/plugin marketplace add trailofbits/skills` and re-run `/pre-audit`
> to include static analysis. Continuing without it.

If available, invoke the skill. When it completes, write its full output to
`audit/tob-prep.md`.

## Step 4: Trail of Bits — Code Maturity Assessment

Check whether the `building-secure-contracts:code-maturity-assessor` skill is
available. If it is not, print a warning:
> ⚠ Trail of Bits `code-maturity-assessor` skill not found. Install the plugin
> with `/plugin marketplace add trailofbits/skills` and re-run `/pre-audit`
> to include the maturity assessment. Continuing without it.

If available, invoke the skill. When it completes, write its full output to
`audit/tob-maturity.md`.

## Step 5: Inspect, plan, and write checklist

Read all Solidity source files (typically under `src/`, `contracts/`, or as
configured in `foundry.toml`). For each contract, note:

- Contract name and file path
- Contract type (interface, abstract, library, base contract, core contract)
- What it does (one sentence)
- What it imports / inherits from
- Whether it handles funds, access control, or external calls

Order contracts so that dependencies are audited before the contracts that use
them:
- Interfaces and libraries first (lowest risk, establish shared types)
- Base/abstract contracts before their children
- Core/critical contracts (fund custody, access control, entry points) last
- Each entry must be a single file path or directory path — exactly what will
  be passed as the argument to `/audit`
- If two files are tightly coupled, give each its own line and note the
  coupling in the description (e.g. "— pairs with `src/Foo.sol`")

Use findings from `audit/tob-prep.md` (if present) to inform the ordering and
flag files that already have known issues.

Write `audit/AUDIT-CHECKLIST.md` using this exact format:

```
# Audit Checklist — `<repo or project name>`

Scope: <brief description of what is in scope, e.g. "all `src/` files changed relative to `main`">
Order: <one line describing the ordering rationale, e.g. "foundational → outward (storage → interfaces → utilities → core logic)">

---

## Progress

- [ ] `<single-file-or-dir>` — <contract name and one-phrase description>
- [ ] `<single-file-or-dir>` — <contract name and one-phrase description>
```

Rules for the checklist:
- One line per file or directory — the path must be usable directly as `/audit <path>`
- Never group multiple files on one line with `+` or similar
- Each line: checkbox, path in backticks, em dash, brief description only
- No headers beyond `## Progress`
- No tables, no "Why this group" prose, no Notes section
- No findings, observations, or risk commentary — those belong in the audit reports
- As audit reports are completed, lines get checked off and the report filename
  plus finding counts are appended to that line, e.g.:
  `- [x] \`src/Foo.sol\` — Foo contract (\`audit-Foo-2026-04-22.md\`) — 1 Medium, 2 Low`
- A totals line is added at the end once all items are checked off

Print the paths of all files written and a one-sentence summary of the scope.
Then stop — do not continue to Step 6.

---

## Re-audit path (Steps 6–10)

## Step 6: Determine the round number

Look for existing `audit/round-*/` directories. The new round number is one
higher than the highest existing round (e.g. if `audit/round-1/` exists, archive
to `audit/round-2/`). If no round directories exist, archive to `audit/round-1/`.

## Step 7: Archive the current round

Create the `audit/round-N/` directory. Move into it:
- `audit/AUDIT-CHECKLIST.md`
- All `audit/audit-*.md` files
- All `audit/audit-*.pdf` files
- `audit/tob-prep.md` (if present)
- `audit/tob-maturity.md` (if present)

Do not move the `audit/round-*/` subdirectories themselves.

## Step 8: Verify the build

Run `forge build`. If it fails, report the errors and stop — do not proceed
until the code compiles cleanly.

## Step 9: Trail of Bits — Audit Preparation and Maturity Assessment

Check whether the `building-secure-contracts:audit-prep-assistant` skill is
available. If it is not, print a warning:
> ⚠ Trail of Bits `audit-prep-assistant` skill not found. Install the plugin
> with `/plugin marketplace add trailofbits/skills` and re-run `/pre-audit`
> to include static analysis. Continuing without it.

If available, invoke the skill. When it completes, write its full output to
`audit/tob-prep.md`.

Check whether the `building-secure-contracts:code-maturity-assessor` skill is
available. If it is not, print a warning:
> ⚠ Trail of Bits `code-maturity-assessor` skill not found. Install the plugin
> with `/plugin marketplace add trailofbits/skills` and re-run `/pre-audit`
> to include the maturity assessment. Continuing without it.

If available, invoke the skill. When it completes, write its full output to
`audit/tob-maturity.md`.

## Step 10: Inspect, plan, and write annotated checklist

Read all Solidity source files as in Step 5. For each file, also scan all
archived round checklists (`audit/round-*/AUDIT-CHECKLIST.md`) to find the most
recent checked-off entry matching that file and extract its findings summary
(e.g. `1 High, 2 Low`). If a file has no prior entry, note `No prior findings`.

Apply the same ordering rules as Step 5. Use findings from `audit/tob-prep.md`
(if present) to inform the ordering.

Write `audit/AUDIT-CHECKLIST.md` using this format:

```
# Audit Checklist — `<repo or project name>`

Scope: <brief description of what is in scope>
Order: <one line describing the ordering rationale>
Round: <N> (prior round archived to `audit/round-<N-1>/`)

---

## Progress

- [ ] `<single-file-or-dir>` — <contract name and one-phrase description>  ← Round <N-1>: <prior findings summary>
- [ ] `<single-file-or-dir>` — <contract name and one-phrase description>  ← Round <N-1>: No prior findings
```

Rules:
- One line per file or directory — the path must be usable directly as `/audit <path>`
- Never group multiple files on one line with `+` or similar; note coupling in the description instead
- Always include the `← Round N:` suffix for every item, even if there were no findings
- Use the findings summary from the most recent archived round for that file
- The `← Round N:` annotation is read-only context for the auditor; it is not part of the
  checked-off format (which remains: `- [x] \`path\` — description (\`report.md\`) — findings`)

Print the path, the round number, and a one-sentence summary of what was archived.
