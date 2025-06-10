# Dev Setup Script

Automated development environment setup for Linux and macOS systems with Docker, Neovim, tmux, and essential development tools.

## Quick Start

```bash
# Run the setup script
bash dev.sh
```

## What Gets Installed

### Core Tools
- **Git** - Version control with preconfigured user settings
- **GitHub CLI** - Command-line interface for GitHub
- **tmux** - Terminal multiplexer
- **Neovim** - Modern text editor with custom configuration from GitHub
- **ripgrep** - Fast text search tool

### Development Environment
- **Node.js** - JavaScript runtime (LTS version)
- **Bun** - Fast JavaScript runtime and package manager
- **Docker** - Containerization platform with compose plugin
- **Claude Code** - AI-powered coding assistant

### Utilities
- **htop** - Interactive process viewer
- **tree** - Directory structure display
- **jq** - JSON processor
- **wget** - File downloader
- **curl** - Data transfer tool

## Features

### ✅ Cross-Platform Support
- **Linux**: Ubuntu, CentOS, RHEL, Fedora, Arch Linux, Alpine
- **macOS**: Automatic Homebrew installation

### ✅ Smart Package Management
- Auto-detects system package manager (apt/yum/dnf/pacman/apk/brew)
- Fallback package names for different distributions
- Comprehensive error handling

### ✅ Configuration Management
- Automatic config backups to `~/.config-backups/`
- Multi-shell support (bash/zsh/fish)
- Custom Neovim config from GitHub repository
- Useful aliases for all tools

### ✅ Docker Integration
- Platform-specific installation
- User added to docker group (Linux)
- Docker Desktop support (macOS)
- Pre-configured aliases

## Cheat Sheet

### Installation Commands
```bash
# Basic setup
bash dev.sh

# Check what's installed
tmux -V && nvim --version && docker --version
```

### Docker Commands
```bash
# Container management
dps          # docker ps
dpsa         # docker ps -a
dimg         # docker images
dexec <id>   # docker exec -it <id> /bin/bash
```

### Editor Commands
```bash
# Neovim
vim <file>   # Opens with nvim
vi <file>    # Opens with nvim
nvim <file>  # Direct nvim call
```

### File Navigation
```bash
# Directory listing
ll           # ls -alF (detailed)
la           # ls -A (show hidden)
l            # ls -CF (compact)

# Search files
rg "pattern" # Fast text search
tree         # Show directory structure
```

### tmux Essentials
```bash
# Session management
tmux new -s <name>    # New named session
tmux attach -t <name> # Attach to session
tmux list-sessions    # List all sessions

# Inside tmux (Ctrl-b prefix)
Ctrl-b c             # New window
Ctrl-b n             # Next window
Ctrl-b p             # Previous window
Ctrl-b d             # Detach session
```

### Git Configuration
```bash
# Pre-configured settings
git config --global user.email "dpolk213@gmail.com"
git config --global user.name "dustypolk"

# Override with environment variables
export GIT_USER_EMAIL="your@email.com"
export GIT_USER_NAME="yourname"
```

### Claude Code Setup
```bash
# First-time authentication
claude auth

# Basic usage
claude chat          # Start interactive chat
claude --help        # Show all commands
```

## System Requirements

### Linux
- Ubuntu 18.04+ / Debian 9+
- CentOS 7+ / RHEL 7+ / Fedora 30+
- Arch Linux / Alpine Linux
- sudo privileges

### macOS
- macOS 10.14+
- Xcode Command Line Tools

## Troubleshooting

### Docker Permission Issues (Linux)
```bash
# If docker commands require sudo
sudo usermod -aG docker $USER
# Then log out and back in
```

### PATH Issues
```bash
# Reload shell configuration
source ~/.bashrc  # or ~/.zshrc
```

### Neovim Configuration Issues
```bash
# Reset Neovim config
rm -rf ~/.config/nvim
# Re-run setup script
```

### Package Installation Failures
```bash
# Check system package manager
which apt || which yum || which brew

# Update package lists
sudo apt update  # Ubuntu/Debian
sudo yum update  # CentOS/RHEL
brew update      # macOS
```

## Logs and Backups

### Log Files
- Setup logs: `/tmp/dev-setup-YYYYMMDD_HHMMSS.log`
- View logs: `tail -f /tmp/dev-setup-*.log`

### Backup Location
- Config backups: `~/.config-backups/YYYYMMDD_HHMMSS/`
- Automatic backup before any config changes

## Customization

### Override Git Settings
```bash
# Set before running script
export GIT_USER_EMAIL="custom@email.com"
export GIT_USER_NAME="customname"
```

### Skip Certain Tools
Edit the script and comment out unwanted installations in the `install_tools()` function.

## Security Notes

- Script runs with `set -e` (exit on error)
- Config files are backed up before modification
- Downloads use HTTPS with verification
- No sensitive data is logged or stored