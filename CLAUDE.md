# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a comprehensive development environment setup script (`dev.sh`) that automates the installation of essential developer tools on Linux and macOS systems. The script is production-ready with robust error handling, cross-platform support, and intelligent configuration management.

## Key Files

- `dev.sh` - Main setup script (enhanced version)
- `README.md` - User documentation with installation guide and cheat sheets
- `CLAUDE.md` - This file (AI assistant context)

## Key Commands

### Running the Setup Script
```bash
# Main setup script
bash dev.sh

# Check installations
tmux -V && nvim --version && docker --version
```

### Environment Variables
```bash
# Override default git configuration
export GIT_USER_EMAIL="custom@email.com"
export GIT_USER_NAME="customname"
```

## Script Architecture (`dev.sh`)

The script follows a modular, defensive programming approach with comprehensive error handling:

### Core Functions

1. **System Detection (`detect_system`)**:
   - Auto-detects OS (Linux/macOS) and distribution
   - Identifies package manager: apt, yum, dnf, pacman, apk, brew
   - Installs Homebrew on macOS if missing

2. **Package Management (`install_package`)**:
   - Generic installation with distribution-specific fallbacks
   - Error handling for package name variations
   - Success/failure logging

3. **Docker Installation (`install_docker`)**:
   - Platform-specific Docker installation
   - Repository setup for apt/yum systems
   - User group management (Linux)
   - Docker Desktop for macOS

4. **Configuration Management**:
   - `backup_config()`: Timestamped backups to `~/.config-backups/`
   - `update_shell_config()`: Multi-shell support (bash/zsh/fish)
   - `create_configs()`: Clones Neovim config from GitHub

5. **Node.js/Bun Setup**:
   - `install_nodejs()`: NodeSource LTS installation
   - `install_bun()`: Direct installation with PATH configuration

### Tools Installed

**Core Development**:
- git, gh (GitHub CLI)
- tmux (terminal multiplexer)
- neovim (with custom config from GitHub: DustyPolk/dotfiles)
- ripgrep (fast text search)

**Languages & Runtimes**:
- Node.js (LTS via NodeSource)
- Bun (JavaScript runtime/package manager)
- Docker (with compose plugin)

**Utilities**:
- htop, tree, jq, wget, curl, unzip

**AI Tools**:
- Claude Code (installed via Bun)

### Configuration Features

1. **Neovim Setup**:
   - Clones configuration from `https://github.com/DustyPolk/dotfiles.git`
   - Runs `install.sh` if present in the cloned config
   - Falls back to basic setup if GitHub clone fails

2. **Shell Configuration**:
   - Adds aliases for vim/vi → nvim
   - Docker command shortcuts (dps, dpsa, dimg, dexec)
   - Standard ls aliases (ll, la, l)
   - Bun PATH configuration

3. **Git Configuration**:
   - Default: dpolk213@gmail.com / dustypolk
   - Overrideable via GIT_USER_EMAIL/GIT_USER_NAME environment variables

### Error Handling & Logging

- **Bash Options**: `set -e -u -o pipefail` for strict error handling
- **Colored Output**: RED/GREEN/YELLOW/BLUE for different message types
- **Logging**: All actions logged to `/tmp/dev-setup-YYYYMMDD_HHMMSS.log`
- **Backup Strategy**: All config files backed up before modification
- **Verification**: Post-install verification of all tools

### Platform Support

**Linux Distributions**:
- Ubuntu/Debian (apt)
- CentOS/RHEL/Fedora (yum/dnf)
- Arch Linux (pacman)
- Alpine Linux (apk)

**macOS**:
- Automatic Homebrew installation
- Docker Desktop installation
- Xcode Command Line Tools assumed

## Development Practices

When modifying this script:
1. **Test across platforms** - The script supports multiple Linux distributions and macOS
2. **Maintain idempotency** - Script should be safe to run multiple times
3. **Preserve error handling** - Don't remove the strict bash options or error checking
4. **Update verification** - Add new tools to the `verify_installations()` function
5. **Document changes** - Update both CLAUDE.md and README.md for user-facing changes

## Common Troubleshooting

- **Docker permissions**: Script adds user to docker group, but requires logout/login
- **PATH issues**: Script updates shell configs, may require terminal restart
- **Package failures**: Script includes fallback package names for different distributions
- **Neovim config**: If GitHub clone fails, basic nvim directory is created as fallback

## Testing Commands

```bash
# Verify script syntax
bash -n dev.sh

# Test system detection
bash -c "source dev.sh; detect_system"

# Check log files
tail -f /tmp/dev-setup-*.log
```