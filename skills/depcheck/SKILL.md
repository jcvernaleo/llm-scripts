---
name: depcheck
description: Review dependency manifest files for dangerous, deprecated, or vulnerable package patterns
allowed-tools: Read, Glob, Bash(find *), Bash(cat *)
argument-hint: [directory]
---

Review dependency manifests in $ARGUMENTS for security concerns.

Locate and read all dependency files:
- Python: `requirements*.txt`, `Pipfile`, `pyproject.toml`, `setup.py`
- Node: `package.json`, `package-lock.json`, `yarn.lock`
- Ruby: `Gemfile`, `Gemfile.lock`
- Go: `go.mod`, `go.sum`
- PHP: `composer.json`
- Rust: `Cargo.toml`
- Java: `pom.xml`, `build.gradle`

For each, assess:

1. **Pinning hygiene**: unpinned deps (`*`, `^`, `~`, `>=`) that allow silent upgrades to vulnerable versions
2. **Deprecated/abandoned packages**: note packages commonly known to be unmaintained or superseded (e.g., `request` for Node, `pycrypto` for Python, `node-uuid` vs `uuid`)
3. **Known dangerous packages**: packages with histories of supply chain compromise or malicious versions (e.g., `event-stream` era patterns, typosquatting names)
4. **Overly broad permissions in package.json**: `preinstall`/`postinstall` scripts that execute arbitrary code
5. **Dev dependencies in production**: packages that should be devDependencies but aren't
6. **Crypto library choice**: MD5/SHA1 for password hashing, use of `pycrypto` vs `cryptography`, DES/ECB usage

Output a table of concerns with package name, issue type, and recommendation.
Note: this is a pattern-based review, not a CVE lookup — recommend running grype/osv-scanner for CVE matching separately.
