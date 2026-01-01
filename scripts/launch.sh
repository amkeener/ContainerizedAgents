#!/bin/bash
# Launch a Claude Code agent with configuration
#
# Usage:
#   ./scripts/launch.sh agent1 --repo https://github.com/user/repo --prompt "Help me implement feature X"
#   ./scripts/launch.sh agent1 --git-name "John Doe" --git-email "john@example.com" --api-key sk-ant-xxx

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Default values
AGENT="agent1"
GIT_NAME=""
GIT_EMAIL=""
API_KEY=""
GITHUB_TOKEN=""
REPO_URL=""
PROMPT=""
INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        agent1|agent2|agent3|agent4)
            AGENT="$1"
            shift
            ;;
        --git-name)
            GIT_NAME="$2"
            shift 2
            ;;
        --git-email)
            GIT_EMAIL="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --prompt|-p)
            PROMPT="$2"
            shift 2
            ;;
        --github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --detach|-d)
            INTERACTIVE=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 <agent> [options]"
            echo ""
            echo "Agents: agent1, agent2, agent3, agent4"
            echo ""
            echo "Options:"
            echo "  --git-name NAME       Git user name"
            echo "  --git-email EMAIL     Git user email"
            echo "  --github-token TOKEN  GitHub Personal Access Token (for HTTPS)"
            echo "  --api-key KEY         Anthropic API key"
            echo "  --repo URL            Repository URL to clone"
            echo "  --prompt, -p TEXT     Starting prompt for Claude Code"
            echo "  --detach, -d          Run in background (don't attach)"
            echo "  --help, -h            Show this help"
            echo ""
            echo "Git Authentication:"
            echo "  SSH keys from ~/.ssh are auto-mounted (use git@github.com:user/repo)"
            echo "  Or pass --github-token for HTTPS repos"
            echo ""
            echo "Examples:"
            echo "  $0 agent1 --repo git@github.com:user/repo.git --prompt 'Fix bug'"
            echo "  $0 agent1 --repo https://github.com/user/repo --github-token ghp_xxx"
            echo "  $0 agent2 --git-name 'John Doe' --git-email 'john@example.com'"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "  Launching Claude Code Agent: $AGENT"
echo "============================================"
echo ""

# Build environment overrides
ENV_ARGS=""

if [ -n "$GIT_NAME" ]; then
    ENV_ARGS="$ENV_ARGS -e GIT_USER_NAME=$GIT_NAME"
    echo "Git Name: $GIT_NAME"
fi

if [ -n "$GIT_EMAIL" ]; then
    ENV_ARGS="$ENV_ARGS -e GIT_USER_EMAIL=$GIT_EMAIL"
    echo "Git Email: $GIT_EMAIL"
fi

if [ -n "$API_KEY" ]; then
    # Set the appropriate key variable
    case $AGENT in
        agent1) ENV_ARGS="$ENV_ARGS -e ANTHROPIC_API_KEY=$API_KEY -e ANTHROPIC_API_KEY_1=$API_KEY" ;;
        agent2) ENV_ARGS="$ENV_ARGS -e ANTHROPIC_API_KEY=$API_KEY -e ANTHROPIC_API_KEY_2=$API_KEY" ;;
        agent3) ENV_ARGS="$ENV_ARGS -e ANTHROPIC_API_KEY=$API_KEY -e ANTHROPIC_API_KEY_3=$API_KEY" ;;
        agent4) ENV_ARGS="$ENV_ARGS -e ANTHROPIC_API_KEY=$API_KEY -e ANTHROPIC_API_KEY_4=$API_KEY" ;;
    esac
    echo "API Key: ****${API_KEY: -4}"
fi

if [ -n "$GITHUB_TOKEN" ]; then
    echo "GitHub Token: ****${GITHUB_TOKEN: -4}"
fi

if [ -n "$REPO_URL" ]; then
    echo "Repo URL: $REPO_URL"
fi

if [ -n "$PROMPT" ]; then
    echo "Prompt: ${PROMPT:0:50}..."
fi

echo ""

# Check if image exists, build if not
if ! docker images | grep -q "containerizedagents"; then
    echo "Building container image (first time setup)..."
    docker compose build
    echo ""
fi

# Create startup script for this session
STARTUP_SCRIPT=$(mktemp)
cat > "$STARTUP_SCRIPT" << 'STARTUP_EOF'
#!/bin/bash
set -e

# Clone repo if specified
if [ -n "$REPO_URL" ]; then
    REPO_NAME=$(basename "$REPO_URL" .git)
    if [ ! -d "/workspace/projects/$REPO_NAME" ]; then
        echo "Cloning repository..."
        git clone "$REPO_URL" "/workspace/projects/$REPO_NAME"
    fi
    cd "/workspace/projects/$REPO_NAME"
    echo "Working in: $(pwd)"
    echo ""
fi

# Start Claude Code with prompt if specified
if [ -n "$PROMPT" ]; then
    exec claude --yes "$PROMPT"
else
    exec claude
fi
STARTUP_EOF
chmod +x "$STARTUP_SCRIPT"

# Copy startup script to temp location that will be mounted
STARTUP_DIR="$PROJECT_DIR/agents/$AGENT/.startup"
mkdir -p "$STARTUP_DIR"
cp "$STARTUP_SCRIPT" "$STARTUP_DIR/run.sh"
rm "$STARTUP_SCRIPT"

# Start/restart the container
echo "Starting container..."
docker compose up -d "$AGENT"

# Wait for container to be ready
sleep 2

# Execute the startup script in the container
if [ "$INTERACTIVE" = true ]; then
    docker compose exec \
        -e REPO_URL="$REPO_URL" \
        -e PROMPT="$PROMPT" \
        -e GITHUB_TOKEN="$GITHUB_TOKEN" \
        $AGENT bash -c '
            # Setup GitHub token if provided (for HTTPS repos)
            if [ -n "$GITHUB_TOKEN" ]; then
                git config --global credential.helper store
                echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
                chmod 600 ~/.git-credentials
            fi

            # Clone repo if specified
            if [ -n "$REPO_URL" ]; then
                REPO_NAME=$(basename "$REPO_URL" .git)
                if [ ! -d "/workspace/projects/$REPO_NAME" ]; then
                    echo "Cloning repository..."
                    git clone "$REPO_URL" "/workspace/projects/$REPO_NAME"
                fi
                cd "/workspace/projects/$REPO_NAME"
                echo ""
                echo "Working in: $(pwd)"
                echo ""
            fi

            # Start Claude Code
            if [ -n "$PROMPT" ]; then
                exec claude "$PROMPT"
            else
                exec claude
            fi
        '
else
    echo "Container started in detached mode."
    echo ""
    echo "Connect with: ./scripts/connect.sh $AGENT"
    echo "Run Claude:   ./scripts/claude.sh $AGENT"
fi
