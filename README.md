# llm-scripts

Helper scripts for using LLMs (Claude Code, OpenCode) to work on code. Written with the help of Claude.

## Contents

- **`ai-devcontainer.sh`** — Main tool. Manages isolated container environments for AI coding assistants, with network firewall, language toolchains, and session management.
- **`clone-all.sh`** / **`status-all.sh`** / **`update-all.sh`** — Multi-repo utilities.
- **`commands/`** — Custom Claude Code slash commands for session state persistence.

---

## ai-devcontainer.sh

Spins up a Podman (or Docker) container with an AI coding assistant and a controlled environment for working on a project. By default, outbound network access is restricted to a whitelist of essential domains only.

### Quick start

```bash
# Initialize a container config in your project
./ai-devcontainer.sh init --lang go ~/projects/myapp

# Build the container image
./ai-devcontainer.sh build ~/projects/myapp

# Launch the AI assistant
./ai-devcontainer.sh code ~/projects/myapp
```

### Commands

| Command | Description |
|---------|-------------|
| `init [--lang LANG] [--backend BACKEND] [dir]` | Create `.devcontainer/` with a generated Dockerfile |
| `build [dir]` | Build the container image |
| `update [dir]` | Rebuild from scratch (no cache, pulls latest base) |
| `start [--port HOST:CONTAINER]... [--open-network] [dir]` | Start container |
| `code [--port HOST:CONTAINER]... [--open-network] [dir]` | Start container and launch the AI assistant |
| `shell [dir]` | Open an interactive shell in the running container |
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
| `all` | Everything above |

### Backends (`--backend`)

| Value | Description |
|-------|-------------|
| `claude` | Claude Code — Anthropic's AI coding assistant (default) |
| `opencode` | OpenCode — open-source, supports Anthropic, OpenAI, Google, Groq, OpenRouter |

The selected backend is saved to `.devcontainer/.backend` and used automatically on subsequent commands.

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

Session notes are stored globally at `~/.claude/sessions/<project-name>/` so context persists across terminal sessions and machines.

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
