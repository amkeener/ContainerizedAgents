# ContainerizedAgents

Run multiple Claude Code instances in isolated Docker containers. Perfect for working on multiple projects simultaneously with different Claude Code accounts.

## Quick Reference

```bash
# First time setup
./scripts/build.sh                    # Build Docker image (~10GB)
cp .env.example .env                  # Create config file
./scripts/auth.sh --use-host agent1   # Copy host Claude credentials

# Daily usage
./scripts/start.sh agent1 agent2      # Start agents
./scripts/status.sh                   # Check what's running
./scripts/connect.sh agent1           # Open shell in agent
./scripts/claude.sh agent1 "prompt"   # Run Claude with prompt
./scripts/stop.sh --all               # Stop all agents

# Working with projects
./scripts/clone-repo.sh agent1 https://github.com/user/repo
./scripts/launch.sh agent1 --repo URL --prompt "Help me with X"
```

## Features

- **Multiple Agents**: Run 2-4 isolated Claude Code instances
- **Full Dev Environment**: Python, Node.js, Flutter, Rust, Go, GitHub CLI
- **Fast Python**: Uses `uv` for blazing fast package management
- **Isolated Workspaces**: Each agent has its own project directory
- **Multiple Accounts**: Each agent can use a different Claude Code account
- **Docker-in-Docker**: Agents can run Docker commands

## Prerequisites

- Docker Desktop installed and running
- ~10GB disk space for the container image
- Claude Code installed on host (for credential copying)

## Quick Start

### 1. Install Docker Desktop

```bash
# macOS
brew install --cask docker

# Then open Docker Desktop from Applications
```

### 2. Build the Container

```bash
cd ContainerizedAgents
./scripts/build.sh
```

### 3. Authenticate Agents

Claude Code requires browser-based OAuth. There are two ways to authenticate:

#### Option A: Copy Host Credentials (Same Account)

If you want agents to use your existing Claude account:

```bash
# Copy your Mac's Claude credentials to agent1
./scripts/auth.sh --use-host agent1
```

#### Option B: Authenticate Different Accounts

For using multiple Claude accounts (your two accounts):

```bash
# Start agent1 and authenticate
./scripts/start.sh agent1
./scripts/connect.sh agent1

# Inside container, run:
claude login
# This will show a URL - open it in your browser to authenticate
```

Repeat for agent2 with your second account.

### 4. Launch an Agent with a Project

```bash
# Launch with repo URL, git config, and starting prompt
./scripts/launch.sh agent1 \
  --repo https://github.com/user/project \
  --git-name "Your Name" \
  --git-email "you@example.com" \
  --prompt "Help me implement the login feature"
```

### 5. Quick Commands

```bash
# Connect to running agent
./scripts/connect.sh agent1

# Run Claude in agent
./scripts/claude.sh agent1

# Check status
./scripts/status.sh
```

## Directory Structure

```
ContainerizedAgents/
├── Dockerfile              # Container image definition
├── docker-compose.yaml     # Multi-agent orchestration
├── .env                    # Your API keys and config
├── .env.example            # Template for .env
├── agents/                 # Per-agent directories
│   ├── agent1/
│   │   ├── projects/       # Agent1's project files
│   │   └── config/         # Agent1's Claude config
│   └── agent2/
│       ├── projects/
│       └── config/
├── shared/                 # Shared Claude config
└── scripts/                # Helper scripts
    ├── build.sh
    ├── start.sh
    ├── stop.sh
    ├── connect.sh
    ├── claude.sh
    ├── status.sh
    ├── logs.sh
    └── clone-repo.sh
```

## Scripts Reference

### build.sh - Build Docker Image

```bash
./scripts/build.sh              # Standard build
./scripts/build.sh --no-cache   # Force rebuild from scratch
```

### start.sh - Start Agent Containers

```bash
./scripts/start.sh agent1              # Start single agent
./scripts/start.sh agent1 agent2       # Start multiple agents
./scripts/start.sh --all               # Start agent1 and agent2
./scripts/start.sh --extended          # Start all 4 agents (agent1-4)
```

### stop.sh - Stop Agent Containers

```bash
./scripts/stop.sh agent1        # Stop single agent
./scripts/stop.sh --all         # Stop all running agents
```

### connect.sh - Open Shell in Agent

```bash
./scripts/connect.sh agent1     # Open interactive zsh shell
```

### claude.sh - Run Claude Code

```bash
./scripts/claude.sh agent1                    # Start Claude interactively
./scripts/claude.sh agent1 "Fix the bug"      # Run with initial prompt
./scripts/claude.sh agent1 --continue         # Continue previous session
```

### status.sh - Show Container Status

```bash
./scripts/status.sh             # Show all agents, ports, and resource usage
```

### logs.sh - View Agent Logs

```bash
./scripts/logs.sh agent1        # Show agent1 logs
./scripts/logs.sh -f agent1     # Follow logs (live tail)
./scripts/logs.sh --all         # Show logs from all agents
```

### auth.sh - Authenticate Claude Code

```bash
./scripts/auth.sh agent1              # Browser-based OAuth login
./scripts/auth.sh --use-host agent1   # Copy credentials from host Mac
./scripts/auth.sh --use-host --all    # Copy credentials to all agents
```

### clone-repo.sh - Clone Repository

```bash
./scripts/clone-repo.sh agent1 https://github.com/user/repo
./scripts/clone-repo.sh agent1 https://github.com/user/repo custom-name
```

### launch.sh - Full Agent Launch

```bash
./scripts/launch.sh agent1 \
  --repo https://github.com/user/project \
  --git-name "Your Name" \
  --git-email "you@example.com" \
  --prompt "Help me implement feature X"
```

## Working with Projects

### Clone a Repository

```bash
# Clone into agent1's workspace
./scripts/clone-repo.sh agent1 https://github.com/user/repo

# Clone with custom name
./scripts/clone-repo.sh agent1 https://github.com/user/repo my-project
```

### Access Projects

Inside the container, projects are at `/workspace/projects/`:

```bash
./scripts/connect.sh agent1
cd /workspace/projects/my-project
claude
```

### Mount Existing Projects

Edit `docker-compose.yaml` to add additional volume mounts:

```yaml
agent1:
  volumes:
    - /path/to/local/project:/workspace/projects/project-name
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY_1` | API key for agent1 |
| `ANTHROPIC_API_KEY_2` | API key for agent2 |
| `GIT_USER_NAME` | Git commit author name |
| `GIT_USER_EMAIL` | Git commit author email |
| `GITHUB_TOKEN` | GitHub CLI authentication |
| `TZ` | Timezone (default: America/New_York) |

## Included Tools

### Languages & Runtimes
- Python 3.12 with uv
- Node.js 22 LTS with npm, pnpm, yarn
- Flutter (stable channel)
- Rust with cargo
- Go 1.22

### Development Tools
- Claude Code (npm package)
- GitHub CLI (gh)
- Docker CLI
- Git, tmux, vim, zsh
- ripgrep, fd, fzf, jq, bat
- lazygit (TUI for git)

### Package Managers
- uv (Python)
- npm, pnpm, yarn (Node.js)
- cargo (Rust)

## Port Mappings

Each agent exposes development ports:

| Agent | Web (3000) | API (8080) | Flask (5000) |
|-------|------------|------------|--------------|
| agent1 | 3001 | 8081 | 5001 |
| agent2 | 3002 | 8082 | 5002 |
| agent3 | 3003 | 8083 | 5003 |
| agent4 | 3004 | 8084 | 5004 |

## Tips

### Using SSH Keys

For GitHub SSH access, you can mount your SSH directory:

```yaml
# In docker-compose.yaml
volumes:
  - ~/.ssh:/root/.ssh:ro
```

### Persisting npm/cargo Cache

Add shared cache volumes to speed up installs:

```yaml
volumes:
  - npm-cache:/root/.npm
  - cargo-cache:/root/.cargo/registry

volumes:
  npm-cache:
  cargo-cache:
```

### Running Multiple Claude Code Accounts

1. Get API keys for each account
2. Set `ANTHROPIC_API_KEY_1`, `ANTHROPIC_API_KEY_2`, etc. in `.env`
3. Each agent uses its own key

## Common Workflows

### Workflow 1: Quick Start with Existing Project

```bash
# Start agent and clone your repo
./scripts/start.sh agent1
./scripts/clone-repo.sh agent1 https://github.com/you/project
./scripts/connect.sh agent1

# Inside container
cd /workspace/projects/project
claude
```

### Workflow 2: Parallel Development on Multiple Projects

```bash
# Start multiple agents
./scripts/start.sh agent1 agent2

# Clone different projects to each
./scripts/clone-repo.sh agent1 https://github.com/you/frontend
./scripts/clone-repo.sh agent2 https://github.com/you/backend

# Work in separate terminals
./scripts/connect.sh agent1   # Terminal 1: Frontend work
./scripts/connect.sh agent2   # Terminal 2: Backend work
```

### Workflow 3: Launch Agent with Task

```bash
# One command to start agent, clone repo, and begin working
./scripts/launch.sh agent1 \
  --repo https://github.com/you/project \
  --git-name "Your Name" \
  --git-email "you@example.com" \
  --prompt "Add user authentication with JWT"
```

## Inside the Container

Once connected to an agent, you have a full development environment:

```bash
# Navigate to projects
cd /workspace/projects/my-project

# Start Claude Code
claude

# Or run Claude with a prompt
claude "Explain this codebase"

# Available tools
python --version      # Python 3.12
node --version        # Node.js 22
flutter --version     # Flutter stable
cargo --version       # Rust
go version            # Go 1.22
gh --version          # GitHub CLI

# Useful aliases (pre-configured)
ll                    # ls -la
gs                    # git status
gd                    # git diff
```

## Troubleshooting

### Container won't start
```bash
# Check logs
./scripts/logs.sh agent1

# Rebuild image
./scripts/build.sh --no-cache
```

### Out of disk space
```bash
# Clean up Docker
docker system prune -a
```

### Permission issues
```bash
# Fix ownership of agent directories
sudo chown -R $USER:$USER agents/
```
