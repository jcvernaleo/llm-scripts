# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository contains shell scripts and configuration for managing isolated AI coding assistant development containers (Podman/Docker). The primary tool is `ai-devcontainer.sh`.

## Key Commands

```bash
# Container lifecycle
./ai-devcontainer.sh init [--lang LANG] [--backend BACKEND] [project-dir]
./ai-devcontainer.sh build [project-dir]
./ai-devcontainer.sh update [project-dir]   # Rebuild without cache, pull latest
./ai-devcontainer.sh start [--port HOST:CONTAINER]... [--open-network] [project-dir]
./ai-devcontainer.sh code [--port HOST:CONTAINER]... [--open-network] [project-dir]
./ai-devcontainer.sh shell [project-dir]
./ai-devcontainer.sh stop [project-dir]
./ai-devcontainer.sh status
./ai-devcontainer.sh langs

# Multi-repo utilities
./clone-all.sh [repos.txt]   # Clone repos listed in repos.txt into repos/
./status-all.sh              # Show git status for all repos in repos/
./update-all.sh              # Fast-forward all repos in repos/
```

## Architecture

### `ai-devcontainer.sh`

The main script dynamically generates a Dockerfile at `init` time and embeds it in `.devcontainer/Dockerfile`. Key design patterns:

- **Backend abstraction**: `claude` (default) or `opencode`. Backend is persisted to `.devcontainer/.backend` and read on subsequent commands.
- **Network firewall**: Default-deny iptables rules are applied inside the container at start time. Allowed domains are assembled from base + backend-specific + language-specific domain arrays defined at the top of the script (`FIREWALL_DOMAINS_*`). Use `--open-network` to disable.
- **Language modularity**: Language environments (`--lang`) add Alpine packages, ENV variables, and post-install RUN steps via parallel arrays (`lang_packages_*`, `lang_env_*`, `lang_postinstall_*`).
- **Container naming**: Derived from the project directory basename via `container_name_for_project()`.
- **Host integration**: SSH agent socket, git config, and API keys are mounted/passed into the container at start.

### Custom Commands (`commands/`)

Markdown files defining custom Claude Code slash commands for session management:
- `/status`, `/sessions`, `/resume`, `/save-session`

Session state is persisted to `~/.claude/sessions/<project-name>/session-state.md`.

## Supported Languages

`base`, `go`, `rust`, `python`, `node`, `emacs`, `solidity`, `all`

## Supported Backends

- `claude` — Claude Code via Anthropic's installer
- `opencode` — OpenCode (`go install github.com/opencode-ai/opencode@latest`), supports Anthropic/OpenAI/Google/Groq/OpenRouter

## Environment Variables

- `AI_DEVCONTAINER_ENGINE` — Container engine (`podman` default, or `docker`)
- `AI_DEVCONTAINER_IMAGE` — Override image name
- API keys passed through: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `GROQ_API_KEY`, `OPENROUTER_API_KEY`
