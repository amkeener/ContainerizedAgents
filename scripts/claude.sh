#!/bin/bash
# Run Claude Code in a specific agent container
#
# Usage:
#   ./claude.sh <agent> [options] [prompt]
#   ./claude.sh <agent> --auto [prompt]    # Autonomous mode (skips permissions)
#
# Examples:
#   ./claude.sh agent1                      # Interactive Claude
#   ./claude.sh agent1 "Fix the bug"        # With prompt
#   ./claude.sh agent1 --auto "Add tests"   # Autonomous mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

AGENT="${1:-agent1}"
shift 2>/dev/null || true

# Check for --auto flag
AUTO_MODE=""
if [ "$1" = "--auto" ] || [ "$1" = "-a" ]; then
    AUTO_MODE="--dangerously-skip-permissions"
    shift
fi

# Check if container is running
if ! docker compose ps --status running | grep -q "$AGENT"; then
    echo "Agent '$AGENT' is not running. Starting it..."
    docker compose up -d "$AGENT"
    sleep 2
fi

echo "Starting Claude Code in $AGENT..."
if [ -n "$AUTO_MODE" ]; then
    echo "Mode: Autonomous (--dangerously-skip-permissions)"
fi
echo ""

# Run claude code
if [ -n "$AUTO_MODE" ]; then
    docker compose exec -T "$AGENT" claude $AUTO_MODE "$@"
else
    docker compose exec "$AGENT" claude "$@"
fi
