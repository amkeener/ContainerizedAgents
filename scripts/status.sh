#!/bin/bash
# Show status of Claude Code agent containers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "============================================"
echo "  Claude Code Agent Status"
echo "============================================"
echo ""

docker compose ps -a

echo ""
echo "============================================"
echo "  Resource Usage"
echo "============================================"
echo ""

docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker compose ps -q 2>/dev/null) 2>/dev/null || echo "No running containers"
