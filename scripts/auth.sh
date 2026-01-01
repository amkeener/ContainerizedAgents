#!/bin/bash
# Authenticate Claude Code in an agent container
#
# This script handles Claude Code authentication which requires a browser-based
# OAuth flow. There are two modes:
#
# 1. Use host credentials (recommended for single account):
#    ./scripts/auth.sh --use-host agent1
#
# 2. Authenticate in container (for multiple accounts):
#    ./scripts/auth.sh agent1
#    # Opens browser, you log in, then credentials are saved in container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

USE_HOST=false
AGENT="agent1"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --use-host|-h)
            USE_HOST=true
            shift
            ;;
        agent1|agent2|agent3|agent4)
            AGENT="$1"
            shift
            ;;
        --help)
            echo "Usage: $0 [--use-host] <agent>"
            echo ""
            echo "Options:"
            echo "  --use-host    Copy credentials from host machine"
            echo ""
            echo "Authentication Methods:"
            echo ""
            echo "  1. Use host credentials (single account):"
            echo "     $0 --use-host agent1"
            echo "     Copies ~/.claude from your Mac to the container"
            echo ""
            echo "  2. Authenticate in container (multiple accounts):"
            echo "     $0 agent1"
            echo "     Opens browser for OAuth login"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Ensure container is running
if ! docker compose ps --status running | grep -q "$AGENT"; then
    echo "Starting $AGENT container..."
    docker compose up -d "$AGENT"
    sleep 2
fi

if [ "$USE_HOST" = true ]; then
    echo "============================================"
    echo "  Copying Host Credentials to $AGENT"
    echo "============================================"
    echo ""

    # Check if host has Claude credentials
    if [ ! -d "$HOME/.claude" ]; then
        echo "Error: No Claude credentials found at ~/.claude"
        echo ""
        echo "Please run 'claude' on your host machine first to authenticate."
        exit 1
    fi

    # Copy credentials to agent's config directory
    AGENT_CONFIG="$PROJECT_DIR/agents/$AGENT/config"
    mkdir -p "$AGENT_CONFIG"

    echo "Copying ~/.claude/* to agents/$AGENT/config/"
    cp -r "$HOME/.claude/"* "$AGENT_CONFIG/"

    echo ""
    echo "Done! $AGENT now has your host Claude credentials."
    echo ""
    echo "Note: Any changes in the container will be persisted in:"
    echo "  $AGENT_CONFIG"

else
    echo "============================================"
    echo "  Authenticating $AGENT via Browser"
    echo "============================================"
    echo ""
    echo "This will open a browser for OAuth login."
    echo "Use this for setting up a different Claude account."
    echo ""

    # Run claude login in the container
    # The --no-sandbox might be needed in container environments
    docker compose exec "$AGENT" bash -c '
        echo "Starting Claude Code authentication..."
        echo ""
        echo "A browser window should open for login."
        echo "If it does not, copy the URL shown below into your browser."
        echo ""
        claude login
    '

    echo ""
    echo "Authentication complete for $AGENT!"
fi
