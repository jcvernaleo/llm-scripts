# llm-scripts

Helper scripts for using LLMs (Claude Code, OpenCode) to work on code. Written with the help of Claude.

## Contents

- **`ai-devcontainer.sh`** — Main tool. Manages isolated container environments for AI coding assistants, with network firewall, language toolchains, and session management.
- **`clone-all.sh`** / **`status-all.sh`** / **`update-all.sh`** — Multi-repo utilities.
- **`misc/slither-constraints.sh`** — Regenerates the pinned Slither dependency list used by the `solidity` image.
- **`skills/`** — Custom Claude Code skills (session management, workspace scaffolding, smart contract audit, code review, web security).

---

## ai-devcontainer.sh

Spins up a Podman (or Docker) container with an AI coding assistant and a controlled environment for working on a project. By default, outbound network access is restricted to a whitelist of essential domains only.

### Quick start

```bash
# First time — initializes, builds, and launches in one step
./ai-devcontainer.sh code --lang go ~/projects/myapp

# Resume an existing project — same command, no flags needed
./ai-devcontainer.sh code ~/projects/myapp
```

For projects that need extra Alpine packages beyond the language defaults:

```bash
./ai-devcontainer.sh init --lang rust ~/projects/myapp
echo "libvirt-dev python3" > ~/projects/myapp/.devcontainer/.extra-packages
./ai-devcontainer.sh code ~/projects/myapp
```

### Commands

| Command | Description |
|---------|-------------|
| `init [--lang LANG] [--backend BACKEND] [dir]` | Create `.devcontainer/` with a generated Dockerfile |
| `build [dir]` | Build the container image |
| `update [dir]` | Regenerate Dockerfile, then rebuild from scratch (no cache, pulls latest base) |
| `start [--port HOST:CONTAINER]... [--open-network] [dir]` | Start container |
| `code [--lang LANG] [--backend BACKEND] [--port HOST:CONTAINER]... [--open-network] [dir]` | Start container and launch the AI assistant (auto-inits on first run) |
| `shell [--lang LANG] [--backend BACKEND] [--port HOST:CONTAINER]... [--open-network] [dir]` | Open an interactive shell in the container (auto-inits on first run) |
| `stop [dir]` | Stop and remove the container |
| `status` | List all ai-dev containers |
| `langs` | Show supported languages and backends |

### Languages (`--lang`)

| Value | Adds |
|-------|------|
| `base` | Minimal: common tools only (default) |
| `go` | Go toolchain + staticcheck, gosec, govulncheck + pandoc/weasyprint (for review PDFs) |
| `rust` | Rust + Cargo |
| `python` | Python 3 + pip + virtualenv |
| `node` | Node.js + npm + pnpm |
| `emacs` | Emacs (for elisp development) |
| `solidity` | Foundry (forge, cast, anvil, chisel) + Slither |
| `terraform` | Terraform |
| `android` | OpenJDK 21 + Android SDK (platform-tools, build-tools 35, API 35) |
| `all` | Go (with its review tools) + Rust + Python + Node.js + Emacs + Solidity/Foundry/Slither (terraform and android excluded — both are large, purpose-specific installs) |

#### Updating Slither

Slither and all of its Python dependencies are pinned in `ai-devcontainer.sh` (`SLITHER_VERSION` and `SLITHER_CONSTRAINTS`).  To move to a new release, run this on the host (it needs Podman or Docker):

```bash
misc/slither-constraints.sh 0.11.7
```

It installs that version in a throwaway `alpine:3.24` container and prints the resolved `name==version` list.  Paste the output into `SLITHER_CONSTRAINTS`, set `SLITHER_VERSION` to match, then rebuild existing projects with `./ai-devcontainer.sh update`.

#### Updating the Go review tools

`staticcheck`, `gosec`, and `govulncheck` are pinned in `ai-devcontainer.sh` (`STATICCHECK_VERSION`, `GOSEC_VERSION`, `GOVULNCHECK_VERSION`); `go install` pins their dependencies through each tool's `go.sum`.  staticcheck's module tags (`v0.8.2`) differ from its release names (`2026.2.2`); use the module tag.  Set the new versions, then rebuild with `./ai-devcontainer.sh update`.  `govulncheck` fetches its database from `vuln.go.dev`, which is in the `go` firewall allowlist.

### Backends (`--backend`)

| Value | Description |
|-------|-------------|
| `claude` | Claude Code — Anthropic's AI coding assistant (default) |
| `opencode` | OpenCode — open-source, supports Anthropic, OpenAI, Google, Groq, OpenRouter |

The selected backend and language are saved to `.devcontainer/.backend` and `.devcontainer/.lang`, port mappings to `.devcontainer/.ports`, and project-specific packages to `.devcontainer/.extra-packages`. All are committed with the project and used automatically on subsequent commands.

### Network firewall

By default, the container applies iptables rules that restrict outbound connections to a domain whitelist. The allowed set is assembled from:

- **Base**: GitHub, raw.githubusercontent.com, etc.
- **Backend**: `api.anthropic.com`, or the relevant LLM provider APIs
- **Language**: Package registries for the selected language (PyPI, crates.io, npmjs.org, etc.)

To disable the firewall:

```bash
./ai-devcontainer.sh code --open-network ~/projects/myapp
```

### Port forwarding

```bash
./ai-devcontainer.sh code --port 3000:3000 --port 8080:8080 ~/projects/myapp
```

Port mappings are saved to `.devcontainer/.ports` and reused automatically on subsequent starts, so you don't need to re-specify them when returning to a project:

```bash
# First time — sets ports and saves them
./ai-devcontainer.sh code --port 3000:3000 --port 8080:8080 ~/projects/myapp

# Later — ports are restored automatically
./ai-devcontainer.sh code ~/projects/myapp
```

Passing `--port` again replaces the saved list entirely.

### Project-specific packages

To add Alpine packages beyond what the selected language provides, create `.devcontainer/.extra-packages` in the project directory (one package per line, `#` comments supported):

```
# needed for libvirt Rust bindings
libvirt-dev
python3
```

```bash
# Pick up changes to .extra-packages by rebuilding
./ai-devcontainer.sh update ~/projects/myapp
```

The package list is incorporated into the image name (via a short content hash), so projects with different extra packages never share an image. Projects with no `.extra-packages` file are unaffected.

### Project-specific firewall domains

To allow additional domains beyond the built-in list for the selected language and backend, create `.devcontainer/.extra-domains` (one domain or CIDR per line, `#` comments supported):

```
# internal npm registry
registry.example.com
# Fastly CDN range used by a private package host
203.0.113.0/24
```

The file is read at container start time — no rebuild needed. Stop and restart the container to apply changes:

```bash
./ai-devcontainer.sh stop ~/projects/myapp
./ai-devcontainer.sh code ~/projects/myapp
```

### Environment variables

| Variable | Description |
|----------|-------------|
| `AI_DEVCONTAINER_ENGINE` | Container engine (`podman` default, or `docker`) |
| `AI_DEVCONTAINER_IMAGE` | Override the image name |
| `ANTHROPIC_API_KEY` | Passed through to container |
| `OPENAI_API_KEY` | Passed through to container |
| `GOOGLE_API_KEY` | Passed through to container |
| `GROQ_API_KEY` | Passed through to container |
| `OPENROUTER_API_KEY` | Passed through to container |

SSH agent socket, git configuration, and `gh` CLI credentials (`~/.config/gh`) are also forwarded from the host automatically.

---

## Multi-repo utilities

```bash
./clone-all.sh [repos.txt]   # Clone repos listed in repos.txt into repos/
./status-all.sh              # Show branch, dirty state, ahead/behind for all repos
./update-all.sh              # Fast-forward all repos in repos/
```

---

## Claude Code skills

The `skills/` directory contains custom Claude Code skills installable to `~/.claude/skills/`.

### Workspace management

| Skill | Description |
|-------|-------------|
| `/status` | Show current project state (reads CLAUDE.md, TODO.md, session state) |
| `/new-workspace` | Scaffold a new multi-repo umbrella workspace in the current directory |

#### `/new-workspace`

Bootstraps a new umbrella workspace for managing multiple related repos together:

- Initializes a git repo with a standard `.gitignore`
- Creates `repos.txt` for listing component repo URLs (used by `clone-all.sh`)
- Creates `PLAN.md` (goal, components table, architecture, milestones, decisions log)
- Creates `TODO.md` for cross-repo task tracking
- Creates a `repos/` directory (gitignored) for cloned components
- Makes an initial commit

Usage: run `/new-workspace <project-name>` in an empty directory. If no name is given, it will prompt you.

### Session management

| Skill | Description |
|-------|-------------|
| `/resume` | Reload context from the last saved session and suggest next steps |
| `/save-session` | Write a session log and state snapshot to `~/.claude/sessions/<project>/` |
| `/sessions` | List recent sessions across all projects |

Session notes are stored globally at `~/.claude/sessions/<project-name>/` so context persists across terminal sessions and machines.

### Smart contract audit

| Skill | Description |
|-------|-------------|
| `/pre-audit` | Verify build, run ToB analysis, and produce an ordered audit checklist; auto-detects re-audits |
| `/audit` | Smart contract security audit using the SCAR methodology |
| `/audit-report` | Combine all audit rounds into a single formatted PDF |
| `/audit-brief` | Short PDF with the basic info table and only Critical, High, and Medium findings |
| `/full-audit` | Run the complete pipeline: pre-audit, audit every checklist item, generate the full and brief PDFs |

#### `/pre-audit`

Run before `/audit` to verify the project builds and produce a structured audit plan.
Auto-detects whether this is a first-time audit or a follow-up:

- **No prior checklist** → first-time path: build check, ToB analysis, codebase
  inspection, and a fresh `audit/AUDIT-CHECKLIST.md`
- **Checklist incomplete** → stops and lists the outstanding items
- **Checklist complete** → re-audit path: archives the current round to
  `audit/round-N/`, re-runs ToB analysis on the updated code, and generates a
  new checklist annotated with prior findings (e.g. `← Round 1: 1 High, 2 Low`)

Both paths run the Trail of Bits `audit-prep-assistant` (Slither, static analysis;
Slither is preinstalled in the `solidity` container) and `code-maturity-assessor` (9-category scorecard) if the plugin is installed,
saving output to `audit/tob-prep.md` and `audit/tob-maturity.md`.

Usage: run `/pre-audit` from the project root with no arguments — before the first
audit and again after the author has addressed findings.

#### `/audit`

Performs a smart contract security audit using the SCAR methodology (Scan, Classify, Analyze, Report):

- Scans all in-scope contracts for known vulnerability patterns (reentrancy, access control, integer issues, oracle manipulation, etc.)
- Classifies each finding by severity: Critical, High, Medium, Low, or Informational
- Traces execution paths for Critical and High findings
- Produces a concise report whose detail scales with severity: Critical/High findings get a proof of concept, a code fix, and a Foundry regression test; Medium and Low are progressively shorter; Informational findings are one-line table rows
- Opens with a short executive summary and an "Areas verified" list, with no per-check tables or closing recommendations section

Usage: pass a single Solidity file or a directory of contracts as the argument.

```
/audit contracts/Vault.sol
/audit src/
```

#### `/audit-report`

Generates a single combined PDF from all audit rounds once the current round is complete:

- Checks that every item in `audit/AUDIT-CHECKLIST.md` is checked off; stops with an explanation if any remain incomplete
- Lays out the PDF as:
  1. Report header: date, auditor, repository, commit, scope, and audit round
  2. Findings summary: severity counts and one combined table of every finding
  3. Round-over-round comparison (re-audits only)
  4. Detailed findings from each `/audit` report
  5. Appendices: excerpts of the Trail of Bits output (maturity executive summary, scorecard and roadmap; prep static analysis and checklist), then prior rounds in order
- Leaves the checklist out of the PDF; it is only used for the completeness check and severity totals
- Converts to a formatted A4 PDF via pandoc and weasyprint (available in the `solidity` and `go` containers); long code, paths and table cells wrap so nothing runs past the page margins
- Writes `audit/audit-report-<date>.pdf` and cleans up all temporary files

Usage: run `/audit-report` from the project root after all `/audit` runs are complete.  It defaults to `audit/`; pass a review directory to build a code review report instead, e.g. `/audit-report review-go` writes `review-go/review-go-report-<date>.pdf` titled "Go Code Review Report", with the static analysis tool summary (`tools.md`) as an appendix in place of the Trail of Bits excerpts.

#### `/audit-brief`

Generates a short companion PDF to the full `/audit-report` PDF, for readers who only need the key results:

- Has the same completeness check as `/audit-report`, and also needs the full report: uses the newest `audit/audit-report-*.pdf`, and stops if there is none.  Warns (but continues) if any `audit-*.md` is newer than that PDF
- Lays out the PDF as:
  1. The basic info table from the full report, plus a **Full report** row naming the full PDF
  2. Critical, High, and Medium counts, and a table of those findings, with the same IDs as the full report (e.g. `Vault F-01`)
  3. The full write-up of each Critical, High, and Medium finding
  4. A closing note pointing to the full report for Low and Informational findings, executive summaries, the round-over-round comparison, and appendices
- Covers the current round only
- Uses the same A4 layout as `/audit-report`, and writes `audit/audit-brief-<date>.pdf`

Usage: run `/audit-brief` from the project root after `/audit-report`, with the same directory argument (none for `audit/`; e.g. `/audit-brief review-go` writes `review-go/review-go-brief-<date>.pdf`).

#### `/full-audit`

Runs the entire audit pipeline in one command:

- **No prior checklist** → runs `/pre-audit`, audits every checklist item in order, then generates the PDFs
- **Incomplete checklist** → resumes from the first unchecked item (skips pre-audit), then generates the PDFs
- **Complete checklist** → runs `/pre-audit` (re-audit path: archives round, fresh checklist), audits every item, then generates the PDFs

The PDFs are the full report (`/audit-report`) followed by the brief report (`/audit-brief`).

If anything fails (build error, audit error, full report error), stops immediately and reports the failure.  If only the brief report fails, it reports the error but still prints the summary, since the full PDF was already written.

Usage: run `/full-audit` from the project root with no arguments.

### Code review (non-Solidity)

The `/full-audit` pipeline for general code, Go first.  Each language writes to its own `review-<lang>/` directory (e.g. `review-go/`), so a repo can also have a Solidity `audit/` directory without collisions.  The PDFs come from `/audit-report` and `/audit-brief` with the directory as the argument.

| Skill | Description |
|-------|-------------|
| `/pre-review` | Verify build, run the language's static analysis tools, and produce an ordered review checklist; auto-detects re-reviews |
| `/review-go` | Security-focused review of one Go package, with findings at Critical through Informational severity |

#### `/pre-review`

The `/pre-audit` equivalent.  Takes the language as an argument (`/pre-review go`), or detects it from `go.mod`/`go.work`, `Cargo.toml`, or `package.json`; if it finds more than one, it asks.  Only Go is supported so far.

- **No prior checklist** → builds every Go module (`go build ./...`, stops on failure), runs the tools, and writes `review-go/AUDIT-CHECKLIST.md`
- **Checklist incomplete** → stops and lists the outstanding items
- **Checklist complete** → archives the current round to `review-go/round-N/`, re-runs the build and tools, and writes a new checklist annotated with prior findings

Tools: `go vet`, `staticcheck`, `gosec`, `govulncheck`, and `go test -race` (best effort, 15-minute limit; test failures are recorded, not errors).  All are in the `go` container.  The output goes to `review-go/tools.md`: a short `## Summary` table (which `/audit-report` puts in the PDF as an appendix), then each tool's full output.

Checklist items are package directories, not files, ordered up the import graph: packages with no in-repo imports first, `cmd/` and network-facing handler packages last.  `vendor/`, `testdata/`, and fully generated packages are skipped.

#### `/review-go`

The `/audit` equivalent for one Go package directory, e.g. `/review-go internal/rpc`:

- Reviews every non-test file in the package, following untrusted input across package boundaries (it reads the packages it imports and finds its callers)
- Uses `review-go/tools.md` as leads: tool reports are confirmed against the code, and only the ones that hold up are reported
- Checks for injection (SQL, `os/exec`, templates), path traversal, SSRF, auth bypass, crypto/TLS misuse, ignored errors, panics reachable from input, data races and goroutine/context leaks, unbounded reads and missing timeouts, integer conversions, `unsafe`/cgo, leaked secrets, and vulnerable dependencies
- Severity: Critical = RCE, auth bypass, or remote data loss with no preconditions; High = the same with preconditions, a remotely triggerable crash, or secret exposure; Medium = DoS under load, leaks, races with real impact, weak crypto/TLS; Low = best practice; Informational = code quality
- Same report layout and severity-scaled detail as `/audit`; Critical/High regression tests are Go tests
- Writes `review-go/audit-<scope>-<date>.md`, where `<scope>` is the package path with `/` → `-` (e.g. `audit-internal-rpc-20261120.md`), and checks the item off in `review-go/AUDIT-CHECKLIST.md` with its finding counts and the running total

### Web security

Each skill restricts itself to read-only tools and accepts a file or directory as an argument, e.g. `/vuln-scan src/`.

| Skill | Description |
|-------|-------------|
| `/vuln-scan` | General web vulnerability scan (XSS, SQLi, SSRF, path traversal, command injection, insecure deserialization, etc.) |
| `/sqli-deep` | Taint-analysis-style deep-dive SQL injection review: traces user input from entry points to query sinks |
| `/authz-review` | Broken access control, IDOR, and privilege escalation review |
| `/secrets-audit` | Hunt for hardcoded secrets, credentials, API keys, and tokens (includes git history check) |
| `/depcheck` | Dependency manifest review for dangerous, deprecated, or vulnerable packages |

To install all skills:

```bash
cp -r skills/* ~/.claude/skills/
```

---

## Requirements

- Podman (or Docker)
- Bash
- An `ANTHROPIC_API_KEY` (for Claude) or the relevant API key for your chosen backend

## License

ISC — see [LICENSE](LICENSE).
