#!/bin/bash
# Stop Claude Code agent containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ "$1" = "--all" ]; then
    echo "Stopping all agents..."
    docker compose --profile extended down
elif [ -n "$1" ]; then
    echo "Stopping: $@"
    docker compose stop "$@"
else
    echo "Stopping default agents..."
    docker compose down
fi

echo ""
echo "Agent status:"
docker compose ps -a
