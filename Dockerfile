# Claude Code Agent Container
# Multi-purpose development environment for running Claude Code instances

FROM ubuntu:24.04

LABEL maintainer="Andrew Keener"
LABEL description="Containerized Claude Code development environment"
LABEL version="1.1"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set up locale
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install base dependencies
RUN apt-get update && apt-get install -y \
    # Essential tools
    curl \
    wget \
    git \
    unzip \
    zip \
    xz-utils \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    # Development essentials
    build-essential \
    pkg-config \
    libssl-dev \
    libffi-dev \
    # Terminal utilities
    tmux \
    screen \
    vim \
    nano \
    htop \
    tree \
    jq \
    fzf \
    ripgrep \
    fd-find \
    bat \
    # Network tools
    openssh-client \
    netcat-openbsd \
    iputils-ping \
    dnsutils \
    # Process management
    supervisor \
    # Misc
    sudo \
    zsh \
    file \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Create non-root agent user
# ============================================
# Remove existing ubuntu user (UID 1000) and create agent user
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g 1000 agent && \
    useradd -m -u 1000 -g 1000 -s /bin/zsh agent && \
    echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# Node.js LTS (via NodeSource) - install as root
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g \
    @anthropic-ai/claude-code \
    typescript \
    ts-node \
    pnpm \
    yarn \
    eslint \
    prettier

# ============================================
# GitHub CLI
# ============================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Flutter SDK (shared installation)
# ============================================
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME && \
    chmod -R a+rw $FLUTTER_HOME && \
    flutter precache && \
    flutter config --no-analytics && \
    dart --disable-analytics

# Flutter dependencies for Linux builds
RUN apt-get update && apt-get install -y \
    clang \
    cmake \
    ninja-build \
    libgtk-3-dev \
    libblkid-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# Docker CLI (for Docker-in-Docker if needed)
# ============================================
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# Go (shared installation)
# ============================================
RUN wget -q https://go.dev/dl/go1.22.0.linux-arm64.tar.gz -O /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# ============================================
# Switch to agent user for user-specific installs
# ============================================
USER agent
WORKDIR /home/agent

# Environment for agent user
ENV HOME=/home/agent
ENV GOPATH="$HOME/go"
ENV PATH="$GOPATH/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ============================================
# Python with uv (for agent user)
# ============================================
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python 3.12 via uv
RUN /home/agent/.local/bin/uv python install 3.12

# ============================================
# Rust (for agent user)
# ============================================
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup target add wasm32-unknown-unknown

# ============================================
# lazygit (TUI for git)
# ============================================
RUN mkdir -p $GOPATH && go install github.com/jesseduffield/lazygit@latest

# ============================================
# Shell configuration for agent user
# ============================================
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Configure shell
RUN echo 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"' >> ~/.zshrc && \
    echo 'alias ll="ls -la"' >> ~/.zshrc && \
    echo 'alias gs="git status"' >> ~/.zshrc && \
    echo 'alias gd="git diff"' >> ~/.zshrc

# ============================================
# Working directory setup
# ============================================
WORKDIR /workspace

# Switch back to root briefly to set up workspace permissions
USER root
RUN mkdir -p /workspace/projects /workspace/.claude /home/agent/.claude && \
    chown -R agent:agent /workspace /home/agent/.claude

# Switch back to agent user
USER agent

# Volume mount points
VOLUME ["/workspace/projects", "/workspace/.claude", "/home/agent/.claude"]

# ============================================
# Entrypoint
# ============================================
USER root
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node --version && python3 --version && flutter --version || exit 1

# Run as agent user
USER agent

# Default command - start interactive shell
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh"]
