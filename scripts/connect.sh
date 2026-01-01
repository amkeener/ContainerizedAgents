#!/bin/bash
# Connect to a running Claude Code agent container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

AGENT="${1:-agent1}"
SHELL="${2:-zsh}"

# Check if container is running
if ! docker compose ps --status running | grep -q "$AGENT"; then
    echo "Agent '$AGENT' is not running."
    echo ""
    echo "Running agents:"
    docker compose ps --status running
    echo ""
    echo "Start with: ./scripts/start.sh $AGENT"
    exit 1
fi

echo "Connecting to $AGENT..."
docker compose exec "$AGENT" "$SHELL"
