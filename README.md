# llm-scripts

Helper scripts for using LLMs (Claude Code, OpenCode) to work on code. Written with the help of Claude.

## Contents

- **`ai-devcontainer.sh`** — Main tool. Manages isolated container environments for AI coding assistants, with network firewall, language toolchains, and session management.
- **`clone-all.sh`** / **`status-all.sh`** / **`update-all.sh`** — Multi-repo utilities.
- **`commands/`** — Custom Claude Code slash commands for session state persistence and workspace scaffolding.

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

For projects where you want to customize the generated Dockerfile before building:

```bash
./ai-devcontainer.sh init --lang go ~/projects/myapp
# ... edit .devcontainer/Dockerfile ...
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
| `go` | Go toolchain |
| `rust` | Rust + Cargo |
| `python` | Python 3 + pip + virtualenv |
| `node` | Node.js + npm + pnpm |
| `emacs` | Emacs (for elisp development) |
| `solidity` | Foundry (forge, cast, anvil, chisel) |
| `terraform` | Terraform |
| `all` | Everything above (except solidity and terraform) |

### Backends (`--backend`)

| Value | Description |
|-------|-------------|
| `claude` | Claude Code — Anthropic's AI coding assistant (default) |
| `opencode` | OpenCode — open-source, supports Anthropic, OpenAI, Google, Groq, OpenRouter |

The selected backend and language are saved to `.devcontainer/.backend` and `.devcontainer/.lang` and used automatically on subsequent commands.

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

SSH agent socket and git configuration are also forwarded from the host automatically.

---

## Multi-repo utilities

```bash
./clone-all.sh [repos.txt]   # Clone repos listed in repos.txt into repos/
./status-all.sh              # Show branch, dirty state, ahead/behind for all repos
./update-all.sh              # Fast-forward all repos in repos/
```

---

## Claude Code commands

The `commands/` directory contains custom slash command definitions to install in `~/.claude/commands/`. They provide session state persistence across Claude Code sessions:

| Command | Description |
|---------|-------------|
| `/status` | Show current project state (reads CLAUDE.md, TODO.md, session state) |
| `/resume` | Reload context from the last saved session and suggest next steps |
| `/save-session` | Write a session log and state snapshot to `~/.claude/sessions/<project>/` |
| `/sessions` | List recent sessions across all projects |
| `/new-workspace` | Scaffold a new multi-repo umbrella workspace in the current directory |
| `/pre-audit` | Verify build, run ToB analysis, and produce an ordered audit checklist; auto-detects re-audits |
| `/audit` | Smart contract security audit using the SCAR methodology |
| `/audit-report` | Combine all audit rounds into a single formatted PDF |

Session notes are stored globally at `~/.claude/sessions/<project-name>/` so context persists across terminal sessions and machines.

### `/new-workspace`

Bootstraps a new umbrella workspace for managing multiple related repos together:

- Initializes a git repo with a standard `.gitignore`
- Creates `repos.txt` for listing component repo URLs (used by `clone-all.sh`)
- Creates `PLAN.md` (goal, components table, architecture, milestones, decisions log)
- Creates `TODO.md` for cross-repo task tracking
- Creates a `repos/` directory (gitignored) for cloned components
- Makes an initial commit

Usage: run `/new-workspace <project-name>` in an empty directory. If no name is given, it will prompt you.

### `/pre-audit`

Run before `/audit` to verify the project builds and produce a structured audit plan.
Auto-detects whether this is a first-time audit or a follow-up:

- **No prior checklist** → first-time path: build check, ToB analysis, codebase
  inspection, and a fresh `audit/AUDIT-CHECKLIST.md`
- **Checklist incomplete** → stops and lists the outstanding items
- **Checklist complete** → re-audit path: archives the current round to
  `audit/round-N/`, re-runs ToB analysis on the updated code, and generates a
  new checklist annotated with prior findings (e.g. `← Round 1: 1 High, 2 Low`)

Both paths run the Trail of Bits `audit-prep-assistant` (Slither, static analysis)
and `code-maturity-assessor` (9-category scorecard) if the plugin is installed,
saving output to `audit/tob-prep.md` and `audit/tob-maturity.md`.

Usage: run `/pre-audit` from the project root with no arguments — before the first
audit and again after the author has addressed findings.

### `/audit`

Performs a smart contract security audit using the SCAR methodology (Scan, Classify, Analyze, Report):

- Scans all in-scope contracts for known vulnerability patterns (reentrancy, access control, integer issues, oracle manipulation, etc.)
- Classifies each finding by severity: Critical, High, Medium, Low, or Informational
- Traces execution paths for Critical and High findings
- Produces a structured report with proof of concept, recommended fix, and a Foundry regression test for each finding

Usage: pass a single Solidity file or a directory of contracts as the argument.

```
/audit contracts/Vault.sol
/audit src/
```

### `/audit-report`

Generates a single combined PDF from all audit rounds once the current round is complete:

- Checks that every item in `audit/AUDIT-CHECKLIST.md` is checked off; stops with an explanation if any remain incomplete
- Concatenates the current round's checklist and reports, then appends all prior rounds as appendices in order
- Converts to a formatted PDF via pandoc and weasyprint (available in the `solidity` container)
- Writes `audit/audit-report-<date>.pdf` and cleans up all temporary files

Usage: run `/audit-report` from the project root with no arguments after all `/audit` runs are complete.

To install the commands:

```bash
cp commands/*.md ~/.claude/commands/
```

---

## Requirements

- Podman (or Docker)
- Bash
- An `ANTHROPIC_API_KEY` (for Claude) or the relevant API key for your chosen backend

## License

ISC — see [LICENSE](LICENSE).
