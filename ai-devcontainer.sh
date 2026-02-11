#!/usr/bin/env bash
#
# ai-devcontainer.sh - Manage AI coding assistant development containers with Podman
#
# Usage:
#   ai-devcontainer.sh init [--lang LANG] [--backend BACKEND] [project-dir]
#   ai-devcontainer.sh build [project-dir]
#   ai-devcontainer.sh start [--port PORT]... [--open-network] [project-dir]
#   ai-devcontainer.sh shell [project-dir]
#   ai-devcontainer.sh code [--port PORT]... [--open-network] [project-dir]
#   ai-devcontainer.sh stop [project-dir]
#   ai-devcontainer.sh status
#   ai-devcontainer.sh langs
#
# Supported languages for --lang:
#   base, go, rust, python, node, emacs, all
#
# Supported backends for --backend:
#   claude    Claude Code (default) - Anthropic's AI coding assistant
#   opencode  OpenCode - open-source alternative, supports multiple LLM providers
#
# Port forwarding:
#   --port, -p HOST:CONTAINER   Forward a port (can be specified multiple times)
#
# Network access:
#   --open-network, -O      Disable firewall (allow unrestricted network access)
#                           By default, network is restricted to essential domains only
#
# Environment variables:
#   AI_DEVCONTAINER_ENGINE   Container engine to use (default: podman)
#   AI_DEVCONTAINER_IMAGE    Image name (default: ai-devcontainer-claude or ai-devcontainer-opencode)
#
#

set -euo pipefail

# Configuration
ENGINE="${AI_DEVCONTAINER_ENGINE:-podman}"
DEFAULT_BACKEND="claude"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Generate a container name from the project directory
container_name_for_project() {
    local project_dir="$1"
    local basename
    basename=$(basename "$project_dir")
    # Sanitize: lowercase, replace non-alphanumeric with dash
    echo "ai-dev-${basename//[^a-zA-Z0-9]/-}" | tr '[:upper:]' '[:lower:]'
}

# Check if container exists
container_exists() {
    local name="$1"
    $ENGINE container exists "$name" 2>/dev/null
}

# Check if image exists (works with both Docker and Podman)
image_exists() {
    local name="$1"
    $ENGINE image inspect "$name" &>/dev/null
}

# Check if container is running
container_running() {
    local name="$1"
    local state
    state=$($ENGINE inspect --format '{{.State.Running}}' "$name" 2>/dev/null || echo "false")
    [[ "$state" == "true" ]]
}

# Get project directory (resolve to absolute path)
get_project_dir() {
    local dir="${1:-.}"
    cd "$dir" && pwd
}

# Language-specific package lists
lang_packages_base=""
lang_packages_go="go"
lang_packages_rust="rust cargo"
lang_packages_python="python3 py3-pip py3-virtualenv"
lang_packages_node="nodejs npm"
lang_packages_emacs="emacs emacs-nox"
lang_packages_all="$lang_packages_go $lang_packages_rust $lang_packages_python $lang_packages_node $lang_packages_emacs"

# Language-specific environment variables
lang_env_base=""
lang_env_go="ENV GOPATH=/home/claude/go
ENV PATH=\$PATH:/home/claude/go/bin"
lang_env_rust="ENV CARGO_HOME=/home/claude/.cargo
ENV PATH=\$PATH:/home/claude/.cargo/bin"
lang_env_python=""
lang_env_node="ENV PNPM_HOME=/home/claude/.local/share/pnpm
ENV PATH=\$PNPM_HOME:\$PATH"
lang_env_emacs=""
lang_env_all="$lang_env_go
$lang_env_rust
$lang_env_node"

# Language-specific post-install commands (run as claude user)
lang_postinstall_base=""
lang_postinstall_go=""
lang_postinstall_rust=""
lang_postinstall_python=""
lang_postinstall_node="RUN wget -qO- https://get.pnpm.io/install.sh | ENV=\"\$HOME/.bashrc\" SHELL=/bin/bash sh -"
lang_postinstall_emacs=""
lang_postinstall_all="$lang_postinstall_node"

# Firewall allowed domains (base domains always allowed)
FIREWALL_DOMAINS_BASE=(
    # GitHub
    "github.com"
    "api.github.com"
    "raw.githubusercontent.com"
    "objects.githubusercontent.com"
    "codeload.github.com"
    "ssh.github.com"
)

# Claude Code specific domains
FIREWALL_DOMAINS_BACKEND_CLAUDE=(
    "api.anthropic.com"
    "anthropic.com"
    "claude.ai"
    "api.statsig.com"
    "statsigapi.net"
    "sentry.io"
)

# OpenCode specific domains (supports multiple LLM providers)
FIREWALL_DOMAINS_BACKEND_OPENCODE=(
    # Anthropic
    "api.anthropic.com"
    # OpenAI
    "api.openai.com"
    # Google
    "generativelanguage.googleapis.com"
    # Groq
    "api.groq.com"
    # OpenRouter
    "openrouter.ai"
)

FIREWALL_DOMAINS_GO=(
    "proxy.golang.org"
    "sum.golang.org"
    "storage.googleapis.com"
)

FIREWALL_DOMAINS_RUST=(
    "crates.io"
    "static.crates.io"
    "index.crates.io"
)

FIREWALL_DOMAINS_PYTHON=(
    "pypi.org"
    "files.pythonhosted.org"
    "pypi.python.org"
)

FIREWALL_DOMAINS_NODE=(
    "registry.npmjs.org"
    "registry.yarnpkg.com"
    "registry.npmmirror.com"
)

FIREWALL_DOMAINS_EMACS=(
    "elpa.gnu.org"
    "melpa.org"
    "stable.melpa.org"
    "elpa.nongnu.org"
)

# Get firewall domains for a language and backend
get_firewall_domains() {
    local lang="$1"
    local backend="${2:-claude}"
    local domains=("${FIREWALL_DOMAINS_BASE[@]}")
    
    # Add backend-specific domains
    case "$backend" in
        claude)
            domains+=("${FIREWALL_DOMAINS_BACKEND_CLAUDE[@]}")
            ;;
        opencode)
            domains+=("${FIREWALL_DOMAINS_BACKEND_OPENCODE[@]}")
            ;;
    esac
    
    # Add language-specific domains
    case "$lang" in
        go)
            domains+=("${FIREWALL_DOMAINS_GO[@]}")
            ;;
        rust)
            domains+=("${FIREWALL_DOMAINS_RUST[@]}")
            ;;
        python)
            domains+=("${FIREWALL_DOMAINS_PYTHON[@]}")
            ;;
        node)
            domains+=("${FIREWALL_DOMAINS_NODE[@]}")
            ;;
        emacs)
            domains+=("${FIREWALL_DOMAINS_EMACS[@]}")
            ;;
        all)
            domains+=("${FIREWALL_DOMAINS_GO[@]}")
            domains+=("${FIREWALL_DOMAINS_RUST[@]}")
            domains+=("${FIREWALL_DOMAINS_PYTHON[@]}")
            domains+=("${FIREWALL_DOMAINS_NODE[@]}")
            domains+=("${FIREWALL_DOMAINS_EMACS[@]}")
            ;;
    esac
    
    printf '%s\n' "${domains[@]}"
}

# Generate firewall setup script
generate_firewall_script() {
    local lang="$1"
    local backend="${2:-claude}"
    local domains
    domains=$(get_firewall_domains "$lang" "$backend")
    
    cat << 'FIREWALL_HEADER'
#!/bin/bash
#
# Network firewall setup for AI coding assistant container
# Restricts outbound connections to whitelisted domains only
#

set -e

# Flush existing rules
iptables -F OUTPUT 2>/dev/null || true
ip6tables -F OUTPUT 2>/dev/null || true

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (needed for domain resolution)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
ip6tables -A OUTPUT -p udp --dport 53 -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allowed domains (resolved at firewall setup time)
ALLOWED_DOMAINS=(
FIREWALL_HEADER

    # Add domains
    while IFS= read -r domain; do
        echo "    \"$domain\""
    done <<< "$domains"
    
    cat << 'FIREWALL_FOOTER'
)

# Resolve and allow each domain
for domain in "${ALLOWED_DOMAINS[@]}"; do
    # Get IPv4 addresses
    ips=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]+\.' || true)
    for ip in $ips; do
        iptables -A OUTPUT -d "$ip" -j ACCEPT 2>/dev/null || true
    done
    
    # Get IPv6 addresses
    ip6s=$(dig +short AAAA "$domain" 2>/dev/null | grep -E '^[0-9a-f:]+$' || true)
    for ip6 in $ip6s; do
        ip6tables -A OUTPUT -d "$ip6" -j ACCEPT 2>/dev/null || true
    done
done

# Allow SSH (port 22) for git operations
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTPS (port 443) to resolved IPs only is already covered above
# Allow HTTP (port 80) for some package registries
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport 80 -j ACCEPT

# Default deny all other outbound
iptables -A OUTPUT -j REJECT --reject-with icmp-net-prohibited
ip6tables -A OUTPUT -j REJECT

echo "Firewall configured. Allowed domains:"
printf '  %s\n' "${ALLOWED_DOMAINS[@]}"
FIREWALL_FOOTER
}

# Setup firewall in container
setup_container_firewall() {
    local container_name="$1"
    local lang="$2"
    local backend="${3:-claude}"
    
    log_info "Setting up network firewall (restricted mode)"
    
    # Generate and execute firewall script
    local firewall_script
    firewall_script=$(generate_firewall_script "$lang" "$backend")
    
    # Run as root to set up iptables
    echo "$firewall_script" | $ENGINE exec -i "$container_name" sudo bash
    
    log_info "Network restricted to whitelisted domains only"
}

# List supported languages
cmd_langs() {
    cat << 'EOF'
Supported languages for --lang:

  base     Minimal setup with AI coding assistant and common tools
  go       Base + Go toolchain
  rust     Base + Rust + Cargo
  python   Base + Python 3 + pip + virtualenv
  node     Base + Node.js + npm + pnpm
  emacs    Base + Emacs (for elisp development)
  all      Everything: Go + Rust + Python + Node.js/pnpm + Emacs

Supported backends for --backend:

  claude    Claude Code (default) - Anthropic's AI coding assistant
  opencode  OpenCode - open-source, supports multiple LLM providers

Examples:
  ai-devcontainer.sh init --lang go ~/projects/mygoapp
  ai-devcontainer.sh init --lang node --backend opencode ~/projects/webapp
  ai-devcontainer.sh init --backend opencode --lang python .
EOF
}

# Initialize a .devcontainer directory in a project
cmd_init() {
    local lang="base"
    local backend="$DEFAULT_BACKEND"
    local project_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lang|-l)
                lang="$2"
                shift 2
                ;;
            --lang=*)
                lang="${1#*=}"
                shift
                ;;
            --backend|-b)
                backend="$2"
                shift 2
                ;;
            --backend=*)
                backend="${1#*=}"
                shift
                ;;
            *)
                project_dir="$1"
                shift
                ;;
        esac
    done

    project_dir=$(get_project_dir "${project_dir:-.}")
    local devcontainer_dir="$project_dir/.devcontainer"

    # Validate language
    case "$lang" in
        base|go|rust|python|node|emacs|all) ;;
        *)
            log_error "Unknown language: $lang"
            log_error "Run '$0 langs' to see supported languages"
            exit 1
            ;;
    esac

    # Validate backend
    case "$backend" in
        claude|opencode) ;;
        *)
            log_error "Unknown backend: $backend"
            log_error "Supported: claude, opencode"
            exit 1
            ;;
    esac

    if [[ -d "$devcontainer_dir" ]]; then
        log_error "Directory $devcontainer_dir already exists"
        exit 1
    fi

    log_info "Creating .devcontainer in $project_dir (language: $lang, backend: $backend)"
    mkdir -p "$devcontainer_dir"

    # Get language-specific additions
    local lang_packages_var="lang_packages_$lang"
    local lang_env_var="lang_env_$lang"
    local lang_postinstall_var="lang_postinstall_$lang"
    local extra_packages="${!lang_packages_var}"
    local extra_env="${!lang_env_var}"
    local extra_postinstall="${!lang_postinstall_var}"

    # Build the apk add line
    local apk_extras=""
    if [[ -n "$extra_packages" ]]; then
        apk_extras="
# Language-specific packages ($lang)
RUN apk add --no-cache $extra_packages"
    fi

    # Build the env section
    local env_extras=""
    if [[ -n "$extra_env" ]]; then
        env_extras="
# Language-specific environment ($lang)
$extra_env"
    fi

    # Build the post-install section
    local postinstall_extras=""
    if [[ -n "$extra_postinstall" ]]; then
        postinstall_extras="
# Language-specific post-install ($lang)
$extra_postinstall"
    fi

    # Backend-specific installation commands
    local backend_install=""
    local backend_path=""
    local backend_name=""
    case "$backend" in
        claude)
            backend_name="Claude Code"
            backend_install="# Install Claude Code via native installer (with retry)
RUN curl -fsSL https://claude.ai/install.sh | bash || \\
    (sleep 5 && curl -fsSL https://claude.ai/install.sh | bash --force)

# Add Claude to PATH (installed to ~/.local/bin)
ENV PATH=\"/home/claude/.local/bin:\\\$PATH\"
RUN echo 'export PATH=\"/home/claude/.local/bin:\\\$PATH\"' >> /home/claude/.bashrc"
            ;;
        opencode)
            backend_name="OpenCode"
            backend_install="# Install OpenCode via go install
RUN go install github.com/opencode-ai/opencode@latest

# Add Go bin to PATH
ENV PATH=\"/home/claude/go/bin:\\\$PATH\"
RUN echo 'export PATH=\"/home/claude/go/bin:\\\$PATH\"' >> /home/claude/.bashrc"
            # OpenCode requires Go
            if [[ "$lang" != "go" && "$lang" != "all" ]]; then
                apk_extras="
# Go (required for OpenCode)
RUN apk add --no-cache go
$apk_extras"
                env_extras="ENV GOPATH=/home/claude/go
$env_extras"
            fi
            ;;
    esac

    # Create Dockerfile
    cat > "$devcontainer_dir/Dockerfile" << DOCKERFILE
FROM alpine:3.21

# Backend: $backend_name

# Install system dependencies
RUN apk add --no-cache \\
    git \\
    curl \\
    sudo \\
    ca-certificates \\
    ripgrep \\
    fd \\
    fzf \\
    jq \\
    tree \\
    htop \\
    unzip \\
    bash \\
    bash-completion \\
    mandoc \\
    man-pages \\
    less \\
    procps \\
    openssh-client \\
    mg \\
    github-cli \\
    gcompat \\
    libstdc++ \\
    iptables \\
    ip6tables \\
    bind-tools
$apk_extras
# Set up non-root user
ARG USERNAME=claude
ARG USER_UID=1000
ARG USER_GID=\$USER_UID

RUN addgroup -g \$USER_GID \$USERNAME \\
    && adduser -D -u \$USER_UID -G \$USERNAME -s /bin/bash \$USERNAME \\
    && echo "\$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create workspace directory
RUN mkdir -p /workspace && chown \$USER_UID:\$USER_GID /workspace

# Switch to claude user for installations
USER \$USERNAME
WORKDIR /home/\$USERNAME

$backend_install

# Pre-populate SSH known_hosts with GitHub keys to avoid fingerprint prompts
RUN mkdir -p /home/claude/.ssh && \\
    ssh-keyscan -t ed25519,rsa,ecdsa github.com >> /home/claude/.ssh/known_hosts 2>/dev/null && \\
    chmod 700 /home/claude/.ssh && \\
    chmod 600 /home/claude/.ssh/known_hosts
$postinstall_extras
# Set environment
ENV SHELL=/bin/bash
ENV EDITOR=mg
ENV VISUAL=mg
$extra_env
WORKDIR /workspace
DOCKERFILE

    # Create a simple devcontainer.json for reference
    local config_dir=".claude"
    [[ "$backend" == "opencode" ]] && config_dir=".opencode"
    
    cat > "$devcontainer_dir/devcontainer.json" << DEVCONTAINER
{
  "name": "$backend_name Dev Container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "workspaceFolder": "/workspace",
  "remoteUser": "claude",
  "mounts": [
    "source=\${localEnv:HOME}/$config_dir,target=/home/claude/$config_dir,type=bind"
  ],
  "containerEnv": {
    "EDITOR": "mg",
    "VISUAL": "mg"
  }
}
DEVCONTAINER

    # Store backend choice for later commands
    echo "$backend" > "$devcontainer_dir/.backend"

    # Create .gitignore additions
    cat > "$devcontainer_dir/.gitignore" << 'GITIGNORE'
# Local overrides
devcontainer.local.json
Dockerfile.local
GITIGNORE

    log_info "Created .devcontainer directory"
    log_info "Files created:"
    log_info "  - $devcontainer_dir/Dockerfile"
    log_info "  - $devcontainer_dir/devcontainer.json"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review and customize the Dockerfile for your project"
    log_info "  2. Run: $0 build $project_dir"
    log_info "  3. Run: $0 code $project_dir"
}

# Build the container image
cmd_build() {
    local project_dir
    project_dir=$(get_project_dir "${1:-.}")
    local dockerfile="$project_dir/.devcontainer/Dockerfile"
    local backend_file="$project_dir/.devcontainer/.backend"

    if [[ ! -f "$dockerfile" ]]; then
        log_error "No Dockerfile found at $dockerfile"
        log_error "Run '$0 init $project_dir' first, or create your own .devcontainer/Dockerfile"
        exit 1
    fi

    # Read backend from stored file
    local backend="claude"
    if [[ -f "$backend_file" ]]; then
        backend=$(cat "$backend_file")
    fi
    
    local image_name="${AI_DEVCONTAINER_IMAGE:-ai-devcontainer-$backend}"

    log_info "Building image from $dockerfile"
    $ENGINE build \
        -t "$image_name" \
        -f "$dockerfile" \
        "$project_dir/.devcontainer"

    log_info "Image $image_name built successfully"
}

# Start a container for the project
cmd_start() {
    local ports=()
    local project_dir=""
    local open_network=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port|-p)
                ports+=("$2")
                shift 2
                ;;
            --port=*)
                ports+=("${1#*=}")
                shift
                ;;
            -p*)
                ports+=("${1:2}")
                shift
                ;;
            --open-network|-O)
                open_network=true
                shift
                ;;
            *)
                project_dir="$1"
                shift
                ;;
        esac
    done

    project_dir=$(get_project_dir "${project_dir:-.}")
    local container_name
    container_name=$(container_name_for_project "$project_dir")
    
    # Read backend from stored file
    local backend="claude"
    local backend_file="$project_dir/.devcontainer/.backend"
    if [[ -f "$backend_file" ]]; then
        backend=$(cat "$backend_file")
    fi
    
    local image_name="${AI_DEVCONTAINER_IMAGE:-ai-devcontainer-$backend}"
    local config_dir="$HOME/.claude"
    [[ "$backend" == "opencode" ]] && config_dir="$HOME/.opencode"

    # Check if already running
    if container_running "$container_name"; then
        log_info "Container $container_name is already running"
        if [[ ${#ports[@]} -gt 0 ]] || [[ "$open_network" == "true" ]]; then
            log_warn "Container already running - changes require restart"
            log_warn "Run '$0 stop $project_dir' first to apply changes"
        fi
        return 0
    fi

    # Remove existing stopped container
    if container_exists "$container_name"; then
        log_info "Removing stopped container $container_name"
        $ENGINE rm "$container_name"
    fi

    # Check if image exists
    if ! image_exists "$image_name"; then
        log_warn "Image $image_name not found, building..."
        cmd_build "$project_dir"
    fi

    # Ensure config directory exists
    mkdir -p "$config_dir"

    log_info "Starting container $container_name for $project_dir (backend: $backend)"

    local config_basename
    config_basename=$(basename "$config_dir")
    
    local run_args=(
        -d
        --name "$container_name"
        -v "$project_dir:/workspace:Z"
        -v "$config_dir:/home/claude/$config_basename:Z"
        -w /workspace
        -e "TERM=${TERM:-xterm-256color}"
    )

    # Add port mappings
    for port in "${ports[@]}"; do
        run_args+=(-p "$port")
        log_info "Forwarding port $port"
    done

    # Add CAP_NET_ADMIN for firewall (unless --open-network)
    if [[ "$open_network" != "true" ]]; then
        run_args+=(--cap-add=NET_ADMIN)
    fi

    # Podman rootless mode needs userns mapping
    run_args+=(--userns=keep-id)

    # Mount .claude.json if it exists (Claude-specific)
    if [[ "$backend" == "claude" && -f "$HOME/.claude.json" ]]; then
        run_args+=(-v "$HOME/.claude.json:/home/claude/.claude.json:Z")
    fi

    # Add any SSH agent socket for git operations
    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        run_args+=(
            -v "$SSH_AUTH_SOCK:/ssh-agent:Z"
            -e "SSH_AUTH_SOCK=/ssh-agent"
        )
    fi

    $ENGINE run "${run_args[@]}" "$image_name" sleep infinity

    # Fix permissions on mounted directories (needed for macOS/Podman VM)
    $ENGINE exec "$container_name" sh -c "sudo chown -R claude:claude /home/claude/$config_basename 2>/dev/null || true"

    # Pass through git config from host
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || true)
    git_email=$(git config --global user.email 2>/dev/null || true)
    if [[ -n "$git_name" ]]; then
        $ENGINE exec "$container_name" git config --global user.name "$git_name"
    fi
    if [[ -n "$git_email" ]]; then
        $ENGINE exec "$container_name" git config --global user.email "$git_email"
    fi

    # Set up firewall by default (unless --open-network)
    if [[ "$open_network" != "true" ]]; then
        # Detect language from Dockerfile
        local lang="base"
        local dockerfile="$project_dir/.devcontainer/Dockerfile"
        if [[ -f "$dockerfile" ]]; then
            if grep -q "nodejs" "$dockerfile"; then
                lang="node"
            elif grep -q "^RUN apk add.*python3" "$dockerfile"; then
                lang="python"
            elif grep -q "^RUN apk add.*\bgo\b" "$dockerfile"; then
                lang="go"
            elif grep -q "^RUN apk add.*rust" "$dockerfile"; then
                lang="rust"
            elif grep -q "^RUN apk add.*\bemacs\b" "$dockerfile"; then
                lang="emacs"
            fi
            # Check for "all"
            if grep -q "nodejs" "$dockerfile" && grep -q "python3" "$dockerfile"; then
                lang="all"
            fi
        fi
        setup_container_firewall "$container_name" "$lang" "$backend"
    else
        log_warn "Network restrictions disabled - container has full internet access"
    fi

    log_info "Container $container_name started"
    log_info "Run '$0 shell $project_dir' to get a shell"
    log_info "Run '$0 code $project_dir' to start the AI assistant"
}

# Get a shell in the container
cmd_shell() {
    local project_dir
    project_dir=$(get_project_dir "${1:-.}")
    local container_name
    container_name=$(container_name_for_project "$project_dir")

    if ! container_running "$container_name"; then
        log_error "Container $container_name is not running"
        log_error "Run '$0 start $project_dir' first"
        exit 1
    fi

    log_info "Entering shell in $container_name"
    $ENGINE exec -it "$container_name" bash
}

# Run AI coding assistant directly
cmd_code() {
    local ports=()
    local project_dir=""
    local open_network=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port|-p)
                ports+=("$2")
                shift 2
                ;;
            --port=*)
                ports+=("${1#*=}")
                shift
                ;;
            -p*)
                ports+=("${1:2}")
                shift
                ;;
            --open-network|-O)
                open_network=true
                shift
                ;;
            *)
                project_dir="$1"
                shift
                ;;
        esac
    done

    project_dir=$(get_project_dir "${project_dir:-.}")
    local container_name
    container_name=$(container_name_for_project "$project_dir")

    # Read backend from stored file
    local backend="claude"
    local backend_file="$project_dir/.devcontainer/.backend"
    if [[ -f "$backend_file" ]]; then
        backend=$(cat "$backend_file")
    fi

    # Start if not running, passing port and network args
    if ! container_running "$container_name"; then
        local start_args=()
        for port in "${ports[@]}"; do
            start_args+=(--port "$port")
        done
        if [[ "$open_network" == "true" ]]; then
            start_args+=(--open-network)
        fi
        start_args+=("$project_dir")
        cmd_start "${start_args[@]}"
    elif [[ ${#ports[@]} -gt 0 ]] || [[ "$open_network" == "true" ]]; then
        log_warn "Container already running - changes require restart"
        log_warn "Run '$0 stop $project_dir' first to apply changes"
    fi

    # Run the appropriate backend
    case "$backend" in
        claude)
            log_info "Starting Claude Code in $container_name"
            log_warn "Running with --dangerously-skip-permissions (container provides isolation)"
            $ENGINE exec -it "$container_name" /home/claude/.local/bin/claude --dangerously-skip-permissions
            ;;
        opencode)
            log_info "Starting OpenCode in $container_name"
            $ENGINE exec -it "$container_name" /home/claude/go/bin/opencode
            ;;
    esac
}

# Stop and remove the container
cmd_stop() {
    local project_dir
    project_dir=$(get_project_dir "${1:-.}")
    local container_name
    container_name=$(container_name_for_project "$project_dir")

    if container_exists "$container_name"; then
        log_info "Stopping container $container_name"
        $ENGINE stop "$container_name" 2>/dev/null || true
        $ENGINE rm "$container_name" 2>/dev/null || true
        log_info "Container $container_name removed"
    else
        log_info "Container $container_name does not exist"
    fi
}

# Show status of all ai-dev containers
cmd_status() {
    log_info "AI dev containers:"
    $ENGINE ps -a --filter "name=ai-dev-" --format "table {{.Names}}\t{{.Status}}\t{{.Mounts}}"
}

# Show usage
usage() {
    cat << EOF
Usage: $(basename "$0") <command> [options] [project-dir]

Commands:
  init    Initialize a .devcontainer directory in a project
  build   Build the container image
  start   Start a container for the project
  shell   Get a shell in the running container
  code    Run the AI coding assistant directly
  stop    Stop and remove the container
  status  List all ai-dev containers
  langs   List supported languages and backends

Options for init:
  --lang, -l LANG       Language environment (default: base)
                        Supported: base, go, rust, python, node, emacs, all
  --backend, -b BACKEND AI backend (default: claude)
                        Supported: claude, opencode

Options for start/code:
  --port, -p PORT       Forward a port (HOST:CONTAINER format)
                        Can be specified multiple times
  --open-network, -O    Disable firewall restrictions (allow full internet access)
                        By default, network is restricted to essential domains

General options:
  project-dir   Path to the project (default: current directory)

Environment variables:
  AI_DEVCONTAINER_ENGINE   Container engine (default: podman)
  AI_DEVCONTAINER_IMAGE    Override image name

Examples:
  # Initialize with Claude Code (default)
  $(basename "$0") init --lang go ~/projects/mygoapp
  $(basename "$0") init --lang python .

  # Initialize with OpenCode
  $(basename "$0") init --backend opencode --lang node ~/projects/webapp
  $(basename "$0") init -b opencode -l rust .

  # Build and run (network restricted by default)
  $(basename "$0") build ~/projects/mygoapp
  $(basename "$0") code ~/projects/mygoapp

  # Start with port forwarding for web development
  $(basename "$0") start --port 3000:3000 --port 8080:8080 .
  $(basename "$0") code -p 3000:3000 ~/projects/webapp

  # Run with unrestricted network access (less secure)
  $(basename "$0") code --open-network .

  # Quick start in current directory
  $(basename "$0") init
  $(basename "$0") build
  $(basename "$0") code
EOF
}

# Main entry point
main() {
    local command="${1:-}"

    case "$command" in
        init)
            shift
            cmd_init "$@"
            ;;
        build)
            cmd_build "${2:-}"
            ;;
        start)
            shift
            cmd_start "$@"
            ;;
        shell)
            cmd_shell "${2:-}"
            ;;
        code)
            shift
            cmd_code "$@"
            ;;
        stop)
            cmd_stop "${2:-}"
            ;;
        status)
            cmd_status
            ;;
        langs)
            cmd_langs
            ;;
        -h|--help|help|"")
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
