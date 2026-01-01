#!/bin/bash
# Build the Claude Code agent container image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "============================================"
echo "  Building Claude Code Agent Container"
echo "============================================"
echo ""

# Check for --no-cache flag
NO_CACHE=""
if [ "$1" = "--no-cache" ]; then
    NO_CACHE="--no-cache"
    echo "Building without cache..."
fi

# Build the image
docker compose build $NO_CACHE

echo ""
echo "Build complete!"
echo ""
echo "To start agents:"
echo "  ./scripts/start.sh agent1"
echo "  ./scripts/start.sh agent1 agent2"
echo "  ./scripts/start.sh --all"
