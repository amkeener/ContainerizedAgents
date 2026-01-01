#!/bin/bash
# Start Claude Code agent containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Warning: .env file not found!"
    echo "Copy .env.example to .env and configure your API keys."
    echo ""
fi

# Parse arguments
if [ "$1" = "--all" ]; then
    echo "Starting all agents..."
    docker compose up -d
elif [ "$1" = "--extended" ]; then
    echo "Starting all agents including extended profile..."
    docker compose --profile extended up -d
elif [ -n "$1" ]; then
    echo "Starting: $@"
    docker compose up -d "$@"
else
    echo "Usage: $0 [agent1] [agent2] ... | --all | --extended"
    echo ""
    echo "Examples:"
    echo "  $0 agent1           # Start agent1 only"
    echo "  $0 agent1 agent2    # Start agent1 and agent2"
    echo "  $0 --all            # Start agent1 and agent2"
    echo "  $0 --extended       # Start all agents (1-4)"
    exit 1
fi

echo ""
echo "Agent status:"
docker compose ps
