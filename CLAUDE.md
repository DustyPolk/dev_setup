# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains development environment setup scripts that automate the installation of essential developer tools on Linux and macOS systems.

## Key Commands

### Running the Setup Scripts
```bash
# Original basic setup
bash dev.sh

# Enhanced setup with Docker and additional tools
bash dev-enhanced.sh
```

## Architecture

### dev.sh (Original Script)
A basic setup script that installs core development tools with simple error handling.

### dev-enhanced.sh (Enhanced Script)
A robust, modular setup script with advanced features:

1. **System Detection**: 
   - Detects OS (Linux/macOS) with distribution details
   - Supports package managers: apt, yum, dnf, pacman, apk, brew
   - Automatic Homebrew installation on macOS

2. **Modular Functions**:
   - `detect_system()`: OS and package manager detection
   - `install_package()`: Generic package installation with fallbacks
   - `install_docker()`: Platform-specific Docker installation
   - `install_bun()`: Bun installation with persistent PATH setup
   - `backup_config()`: Creates timestamped backups before modifications
   - `update_shell_config()`: Multi-shell configuration updates

3. **Tools Installed**:
   - Core: curl, unzip, git, wget
   - Development: tmux, ripgrep, neovim, htop, tree, jq
   - Languages: Node.js (via NodeSource), Bun
   - Containers: Docker with docker-compose plugin
   - CLI Tools: Claude Code (via Bun)

4. **Configuration Management**:
   - Backs up existing configs to `~/.config-backups/`
   - Creates enhanced Neovim config with leader key, clipboard integration
   - Creates feature-rich tmux config with vim-style navigation
   - Sets up useful aliases for all tools
   - Updates multiple shell configs (bash, zsh, fish)

5. **Error Handling**:
   - Comprehensive error checking with colored output
   - Logging to `/tmp/dev-setup-*.log`
   - Graceful fallbacks for package names
   - Network operation error handling

6. **Docker Features**:
   - Platform-specific installation (apt/yum/dnf/pacman/apk/brew)
   - Automatic user addition to docker group (Linux)
   - Docker Desktop installation (macOS)
   - Docker command aliases

The enhanced script is idempotent, supports more platforms, and provides better user feedback throughout the installation process.