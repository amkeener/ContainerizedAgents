#!/bin/bash
# Run Claude Code in a specific agent container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

AGENT="${1:-agent1}"
shift 2>/dev/null || true

# Check if container is running
if ! docker compose ps --status running | grep -q "$AGENT"; then
    echo "Agent '$AGENT' is not running. Starting it..."
    docker compose up -d "$AGENT"
    sleep 2
fi

echo "Starting Claude Code in $AGENT..."
echo ""

# Run claude code interactively
docker compose exec "$AGENT" claude "$@"
