[//]: # (Smart contract audit command using the SCAR methodology.)
[//]: # (Inspired by: https://aurpay.net/aurspace/smart-contract-auditing-claude-code-security-workflow/)

Perform a smart contract security audit using the SCAR methodology on $ARGUMENTS.

## Role
You are a senior smart contract security auditor. Your task is to identify
vulnerabilities, assess severity, and recommend fixes for all Solidity contracts
in scope.

## Methodology: SCAR
Follow this sequence for every audit:
1. **Scan** all in-scope contracts for known vulnerability patterns
2. **Classify** each finding by severity (Critical/High/Medium/Low/Info)
3. **Analyze** Critical and High findings with execution path tracing
4. **Report** all findings in the structured format below

## Vulnerability Checklist
Scan for these patterns in every contract:
- [ ] Reentrancy (state changes after external calls, cross-function, read-only)
- [ ] Access control (missing modifiers, unprotected init, privilege escalation)
- [ ] Unchecked external calls (low-level .call without return value checks)
- [ ] Integer issues (unchecked blocks, unsafe casting between types)
- [ ] Oracle manipulation (spot price dependencies, short TWAP windows)
- [ ] Front-running (sandwich-vulnerable operations, predictable state outcomes)
- [ ] Denial of service (unbounded loops, block gas limit, grief vectors)
- [ ] Timestamp dependence (block.timestamp manipulation)
- [ ] tx.origin authentication
- [ ] Delegatecall to untrusted contracts
- [ ] Cross-contract interaction chains (trust assumption failures)

## Severity Definitions
- **Critical**: Direct fund loss, no preconditions required
- **High**: Fund loss with specific conditions, state corruption
- **Medium**: Conditional loss, griefing, value leakage over time
- **Low**: Best practice violations, no direct fund risk
- **Informational**: Code quality, gas optimization, documentation gaps

## Report Format
For each finding, provide:
1. Severity tag and title (e.g., `[CRITICAL] Reentrancy in Vault.withdraw()`)
2. Affected contract, function, and line numbers
3. Description of the vulnerability
4. Step-by-step proof of concept
5. Recommended fix with code
6. Foundry test case for regression testing

## Output File

When the audit is complete, write the full report to a markdown file named
`audit-<scope>-<date>.md` in the current directory, where `<scope>` is the
base name of the file or directory audited (e.g. `Vault` for `contracts/Vault.sol`
or `src` for `src/`) and `<date>` is the current date in `YYYYMMDD` format
(e.g. `audit-Vault-20260421.md`).

The file must be structured as a professional audit report:

```
# Smart Contract Security Audit
**Date:** YYYY-MM-DD
**Auditor:** Claude (SCAR Methodology)
**Scope:** <file or directory audited>
**Repository:** <git remote origin URL>
**Commit:** <full git commit hash>

## Executive Summary
<overall risk rating, brief description of what was audited, high-level findings>

## Findings Summary
| ID | Severity | Title |
|----|----------|-------|
| F-01 | Critical | ... |
| F-02 | High | ... |
...

## Findings

### F-01 [CRITICAL] <Title>
**Contract:** `...`
**Function:** `...`
**Lines:** ...

**Description**
...

**Proof of Concept**
...

**Recommended Fix**
```solidity
...
```

**Regression Test**
```solidity
...
```

---
(repeat for each finding)

## Summary
**Total findings:** N (X Critical, X High, X Medium, X Low, X Informational)
**Overall risk:** Critical / High / Medium / Low
**Top 3 recommendations:**
1. ...
2. ...
3. ...
```

After writing the file, print the path to the report.

## Rules
- Never skip a contract file, even if it looks simple
- Always check cross-contract interactions, not just individual files
- Flag any function callable by arbitrary addresses
- If a finding is uncertain, mark it as "Needs Manual Review"
- The markdown file is mandatory — always write it, even if there are no findings
