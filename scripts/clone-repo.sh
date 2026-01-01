#!/bin/bash
# Clone a repository into an agent's workspace

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

usage() {
    echo "Usage: $0 <agent> <repo-url> [directory-name]"
    echo ""
    echo "Examples:"
    echo "  $0 agent1 https://github.com/user/repo"
    echo "  $0 agent1 git@github.com:user/repo.git my-project"
    echo "  $0 agent2 https://github.com/user/repo custom-name"
}

if [ -z "$1" ] || [ -z "$2" ]; then
    usage
    exit 1
fi

AGENT="$1"
REPO_URL="$2"
DIR_NAME="${3:-}"

# Create agent projects directory if it doesn't exist
mkdir -p "agents/$AGENT/projects"

# Clone the repository
if [ -n "$DIR_NAME" ]; then
    echo "Cloning $REPO_URL into agents/$AGENT/projects/$DIR_NAME..."
    git clone "$REPO_URL" "agents/$AGENT/projects/$DIR_NAME"
else
    echo "Cloning $REPO_URL into agents/$AGENT/projects/..."
    git clone "$REPO_URL" "agents/$AGENT/projects/"
fi

echo ""
echo "Done! The repository is now available in the agent at:"
echo "  /workspace/projects/$(basename ${DIR_NAME:-$REPO_URL} .git)"
