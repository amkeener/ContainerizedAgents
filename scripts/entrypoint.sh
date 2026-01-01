#!/bin/bash
# Entrypoint script for Claude Code Agent container
# Runs as agent user (non-root) for security

set -e

# ============================================
# Fix ownership of mounted volumes (if needed)
# ============================================
# The entrypoint runs as agent user, but sudo is available if needed
if [ ! -w "/workspace/projects" ] 2>/dev/null; then
    sudo chown -R agent:agent /workspace 2>/dev/null || true
fi

if [ ! -w "$HOME/.claude" ] 2>/dev/null; then
    sudo chown -R agent:agent "$HOME/.claude" 2>/dev/null || true
fi

# ============================================
# SSH Agent forwarding setup
# ============================================
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "SSH Agent detected, setting up forwarding..."
fi

# ============================================
# Git configuration
# ============================================
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Safe directory for mounted volumes
git config --global --add safe.directory '*'

# ============================================
# Claude Code configuration
# ============================================
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Anthropic API key detected"
fi

# Create claude config directory if it doesn't exist
mkdir -p "$HOME/.claude"

# Link shared claude config if mounted
if [ -d "/workspace/.claude" ] && [ "$(ls -A /workspace/.claude 2>/dev/null)" ]; then
    echo "Linking shared Claude configuration..."
    for file in /workspace/.claude/*; do
        if [ -f "$file" ]; then
            ln -sf "$file" "$HOME/.claude/$(basename $file)" 2>/dev/null || true
        fi
    done
fi

# ============================================
# Environment info
# ============================================
echo ""
echo "============================================"
echo "  Claude Code Agent Container"
echo "============================================"
echo ""
echo "User: $(whoami) (non-root)"
echo ""
echo "Environment:"
echo "  - Python: $(python3 --version 2>/dev/null || echo 'not found')"
echo "  - Node.js: $(node --version 2>/dev/null || echo 'not found')"
echo "  - npm: $(npm --version 2>/dev/null || echo 'not found')"
echo "  - Flutter: $(flutter --version 2>/dev/null | head -1 || echo 'not found')"
echo "  - Rust: $(rustc --version 2>/dev/null || echo 'not found')"
echo "  - Go: $(go version 2>/dev/null || echo 'not found')"
echo "  - GitHub CLI: $(gh --version 2>/dev/null | head -1 || echo 'not found')"
echo "  - Claude Code: $(claude --version 2>/dev/null || echo 'not found')"
echo ""
echo "Workspace: /workspace/projects"
echo "Claude config: $HOME/.claude"
echo ""

# ============================================
# Run command or interactive shell
# ============================================
if [ "$1" = "claude" ] || [ "$1" = "claude-code" ]; then
    # Run Claude Code directly
    shift
    exec claude "$@"
elif [ "$1" = "claude-auto" ]; then
    # Run Claude Code with auto-approve permissions (for autonomous operation)
    shift
    exec claude --dangerously-skip-permissions "$@"
elif [ "$1" = "tmux-session" ]; then
    # Start a named tmux session
    SESSION_NAME="${2:-agent}"
    exec tmux new-session -s "$SESSION_NAME"
else
    # Run provided command or default shell
    exec "$@"
fi
