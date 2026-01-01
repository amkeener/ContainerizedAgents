#!/bin/bash
# View logs from Claude Code agent containers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

AGENT="${1:-agent1}"
FOLLOW="${2:---tail=100}"

if [ "$1" = "--all" ]; then
    docker compose logs -f --tail=50
elif [ "$1" = "-f" ] || [ "$1" = "--follow" ]; then
    AGENT="${2:-agent1}"
    docker compose logs -f "$AGENT"
else
    docker compose logs $FOLLOW "$AGENT"
fi
