FROM alpine:3.24

# Backend: Claude Code

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    sudo \
    ca-certificates \
    ripgrep \
    bash \
    openssh-client \
    mg \
    github-cli \
    gcompat \
    libgcc \
    libstdc++ \
    iptables \
    ip6tables \
    bind-tools


# Set up non-root user
ARG USERNAME=ai
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN addgroup -g $USER_GID $USERNAME \
    && adduser -D -u $USER_UID -G $USERNAME -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create workspace directory
RUN mkdir -p /workspace && chown $USER_UID:$USER_GID /workspace

# Switch to ai user for installations
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Claude Code via native installer
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add Claude to PATH (installed to ~/.local/bin)
ENV PATH="/home/ai/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# Use system ripgrep (required on Alpine/musl — libgcc/libstdc++ already installed)
ENV USE_BUILTIN_RIPGREP=0
RUN echo 'export PATH="/home/ai/.local/bin:$PATH"' >> /home/ai/.bashrc

# Pre-populate SSH known_hosts with GitHub keys to avoid fingerprint prompts
RUN /bin/mkdir -p /home/ai/.ssh && \
    /usr/bin/ssh-keyscan -t ed25519,rsa,ecdsa github.com >> /home/ai/.ssh/known_hosts 2>/dev/null && \
    /bin/chmod 700 /home/ai/.ssh && \
    /bin/chmod 600 /home/ai/.ssh/known_hosts

# Install gh extensions
RUN gh extension install github/gh-stack --pin v0.1.0

# Set environment
ENV SHELL=/bin/bash
ENV EDITOR=mg
ENV VISUAL=mg
ENV CLAUDE_CODE_DISABLE_MOUSE=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ENV DISABLE_AUTOUPDATER=1

WORKDIR /workspace
