#!/bin/bash

# Enhanced Dev Box Setup Script
# Installs Docker, tmux, Claude Code, Neovim and other essential tools
# with better error handling and configuration management

set -e  # Exit on any error
set -u  # Exit on unset variables
set -o pipefail  # Exit on pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/dev-setup-$(date +%Y%m%d_%H%M%S).log"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"
}

# Detect OS and Package Manager
detect_system() {
    log "Detecting system configuration..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$NAME
            VERSION=$VERSION_ID
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macOS"
        VERSION=$(sw_vers -productVersion)
    else
        error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    
    log "Detected OS: $OS ($DISTRO $VERSION)"
    
    # Detect package manager
    if [[ "$OS" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        elif command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
        elif command -v pacman &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        elif command -v apk &> /dev/null; then
            PACKAGE_MANAGER="apk"
        else
            error "No supported package manager found"
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            log "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                error "Failed to install Homebrew"
                exit 1
            }
        fi
        PACKAGE_MANAGER="brew"
    fi
    
    log "Package manager: $PACKAGE_MANAGER"
}

# Update package manager
update_package_manager() {
    log "Updating package manager..."
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update || error "Failed to update apt"
            ;;
        yum)
            sudo yum update -y || error "Failed to update yum"
            ;;
        dnf)
            sudo dnf update -y || error "Failed to update dnf"
            ;;
        pacman)
            sudo pacman -Syu --noconfirm || error "Failed to update pacman"
            ;;
        apk)
            sudo apk update || error "Failed to update apk"
            ;;
        brew)
            brew update || error "Failed to update brew"
            ;;
    esac
}

# Generic package installation function
install_package() {
    local package=$1
    local package_alt=${2:-$package}  # Alternative package name for different distros
    
    log "Installing $package..."
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt install -y "$package" || sudo apt install -y "$package_alt"
            ;;
        yum)
            sudo yum install -y "$package" || sudo yum install -y "$package_alt"
            ;;
        dnf)
            sudo dnf install -y "$package" || sudo dnf install -y "$package_alt"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package" || sudo pacman -S --noconfirm "$package_alt"
            ;;
        apk)
            sudo apk add "$package" || sudo apk add "$package_alt"
            ;;
        brew)
            brew install "$package" || brew install "$package_alt"
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        success "$package installed"
    else
        error "Failed to install $package"
        return 1
    fi
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        warning "Docker already installed: $(docker --version)"
        return 0
    fi
    
    case $OS in
        linux)
            case $PACKAGE_MANAGER in
                apt)
                    # Remove old versions
                    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
                    
                    # Install prerequisites
                    sudo apt update
                    sudo apt install -y \
                        ca-certificates \
                        curl \
                        gnupg \
                        lsb-release
                    
                    # Add Docker's official GPG key
                    sudo mkdir -p /etc/apt/keyrings
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    
                    # Set up the repository
                    echo \
                        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                    
                    # Install Docker Engine
                    sudo apt update
                    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                    ;;
                    
                yum|dnf)
                    # Remove old versions
                    sudo yum remove -y docker \
                        docker-client \
                        docker-client-latest \
                        docker-common \
                        docker-latest \
                        docker-latest-logrotate \
                        docker-logrotate \
                        docker-engine 2>/dev/null || true
                    
                    # Install prerequisites
                    sudo yum install -y yum-utils
                    
                    # Add Docker repository
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    
                    # Install Docker Engine
                    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                    
                    # Start Docker
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    ;;
                    
                pacman)
                    sudo pacman -S --noconfirm docker docker-compose
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    ;;
                    
                apk)
                    sudo apk add docker docker-compose
                    sudo rc-update add docker boot
                    sudo service docker start
                    ;;
            esac
            
            # Add current user to docker group
            if [ "$OS" == "linux" ]; then
                sudo usermod -aG docker "$USER" || warning "Failed to add user to docker group"
                warning "You'll need to log out and back in for docker group changes to take effect"
            fi
            ;;
            
        macos)
            # On macOS, install Docker Desktop
            brew install --cask docker
            warning "Docker Desktop installed. Please start it manually from Applications"
            ;;
    esac
    
    if command -v docker &> /dev/null; then
        success "Docker installed successfully"
    else
        error "Docker installation failed"
        return 1
    fi
}

# Backup existing config
backup_config() {
    local config_file=$1
    
    if [ -f "$config_file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name=$(basename "$config_file")
        cp "$config_file" "$BACKUP_DIR/$backup_name"
        log "Backed up $config_file to $BACKUP_DIR/$backup_name"
    fi
}

# Update shell configuration
update_shell_config() {
    local line_to_add=$1
    local comment=${2:-""}
    
    # Determine shell config files
    local configs=()
    [ -f "$HOME/.bashrc" ] && configs+=("$HOME/.bashrc")
    [ -f "$HOME/.zshrc" ] && configs+=("$HOME/.zshrc")
    [ -f "$HOME/.config/fish/config.fish" ] && configs+=("$HOME/.config/fish/config.fish")
    
    # If no config files found, use default based on current shell
    if [ ${#configs[@]} -eq 0 ]; then
        case "$SHELL" in
            */zsh)
                configs=("$HOME/.zshrc")
                touch "$HOME/.zshrc"
                ;;
            */bash)
                configs=("$HOME/.bashrc")
                touch "$HOME/.bashrc"
                ;;
            *)
                configs=("$HOME/.profile")
                touch "$HOME/.profile"
                ;;
        esac
    fi
    
    for config in "${configs[@]}"; do
        if ! grep -Fxq "$line_to_add" "$config" 2>/dev/null; then
            backup_config "$config"
            {
                echo ""
                [ -n "$comment" ] && echo "# $comment"
                echo "$line_to_add"
            } >> "$config"
            log "Added to $config: $line_to_add"
        fi
    done
}

# Install Bun with proper PATH setup
install_bun() {
    log "Installing Bun..."
    
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash || {
            error "Failed to install Bun"
            return 1
        }
        
        # Add Bun to PATH for all shells
        update_shell_config 'export PATH="$HOME/.bun/bin:$PATH"' "Bun"
        
        # Add to current session
        export PATH="$HOME/.bun/bin:$PATH"
        
        success "Bun installed"
    else
        warning "Bun already installed: $(bun --version)"
    fi
}

# Install Node.js via package manager or NodeSource
install_nodejs() {
    log "Installing Node.js..."
    
    if command -v node &> /dev/null; then
        warning "Node.js already installed: $(node --version)"
        return 0
    fi
    
    case $PACKAGE_MANAGER in
        apt)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || {
                error "Failed to add NodeSource repository"
                return 1
            }
            sudo apt install -y nodejs
            ;;
        brew)
            brew install node
            ;;
        *)
            install_package nodejs npm
            ;;
    esac
}

# Create configuration files
create_configs() {
    log "Creating configuration files..."
    
    # Pull Neovim configuration from GitHub
    if [ ! -d "$HOME/.config/nvim" ]; then
        log "Cloning Neovim configuration from GitHub..."
        
        # Ensure .config directory exists
        mkdir -p "$HOME/.config"
        
        # Clone the dotfiles repository
        if git clone https://github.com/DustyPolk/dotfiles.git "$HOME/.config/dotfiles-temp" 2>/dev/null; then
            # Rename to nvim
            mv "$HOME/.config/dotfiles-temp" "$HOME/.config/nvim"
            success "Neovim configuration cloned from GitHub"
            
            # Run install.sh if it exists in the cloned repository
            if [ -f "$HOME/.config/nvim/install.sh" ]; then
                log "Running Neovim configuration install script..."
                cd "$HOME/.config/nvim"
                if bash install.sh; then
                    success "Neovim install script completed successfully"
                else
                    error "Neovim install script failed"
                fi
                cd - > /dev/null  # Return to previous directory
            else
                warning "No install.sh found in Neovim configuration"
            fi
        else
            error "Failed to clone Neovim configuration from GitHub"
            # Create basic nvim directory as fallback
            mkdir -p "$HOME/.config/nvim"
        fi
    else
        warning "Neovim configuration directory already exists"
        # Optionally backup existing config
        if [ -f "$HOME/.config/nvim/init.lua" ] || [ -f "$HOME/.config/nvim/init.vim" ]; then
            backup_config "$HOME/.config/nvim"
        fi
    fi
    
    # tmux configuration
    if [ ! -f "$HOME/.tmux.conf" ]; then
        cat > "$HOME/.tmux.conf" << 'EOF'
# Enhanced tmux configuration

# Set prefix to Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Enable mouse
set -g mouse on

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows on close
set -g renumber-windows on

# Increase history limit
set -g history-limit 10000

# Faster key repetition
set -s escape-time 0

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Colors and styling
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Status bar
set -g status-bg black
set -g status-fg white
set -g status-interval 60
set -g status-left-length 30
set -g status-left '#[fg=green](#S) #(whoami)'
set -g status-right '#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[default] #[fg=white]%H:%M#[default]'

# Copy mode
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
EOF
        success "Created tmux configuration"
    else
        warning "tmux configuration already exists"
        backup_config "$HOME/.tmux.conf"
    fi
}

# Install all tools
install_tools() {
    # Essential dependencies
    install_package curl
    install_package unzip
    install_package git
    install_package gh github-cli
    
    # Development tools
    install_package tmux
    install_package ripgrep rg
    install_package neovim nvim
    
    # Additional useful tools
    install_package htop
    install_package tree
    install_package jq
    install_package wget
    
    # Programming languages and tools
    install_nodejs
    install_bun
    install_docker
    
    # Install Claude Code via Bun
    if command -v bun &> /dev/null; then
        log "Installing Claude Code..."
        bun install -g @anthropic-ai/claude-code || {
            error "Failed to install Claude Code"
        }
    fi
}

# Setup aliases
setup_aliases() {
    log "Setting up aliases..."
    
    # Neovim aliases
    update_shell_config "alias vim='nvim'" "Neovim aliases"
    update_shell_config "alias vi='nvim'"
    
    # Useful aliases
    update_shell_config "alias ll='ls -alF'" "Useful aliases"
    update_shell_config "alias la='ls -A'"
    update_shell_config "alias l='ls -CF'"
    
    # Docker aliases
    if command -v docker &> /dev/null; then
        update_shell_config "alias dps='docker ps'" "Docker aliases"
        update_shell_config "alias dpsa='docker ps -a'"
        update_shell_config "alias dimg='docker images'"
        update_shell_config "alias dexec='docker exec -it'"
    fi
}

# Verify installations
verify_installations() {
    log "Verifying installations..."
    echo ""
    
    local tools=(
        "tmux:tmux -V"
        "ripgrep:rg --version | head -n1"
        "neovim:nvim --version | head -n1"
        "node:node --version"
        "bun:bun --version"
        "docker:docker --version"
        "claude:claude --version 2>/dev/null || echo 'installed'"
        "git:git --version"
        "gh:gh --version | head -n1"
    )
    
    for tool_check in "${tools[@]}"; do
        IFS=':' read -r tool check_cmd <<< "$tool_check"
        if command -v "${tool%% *}" &> /dev/null; then
            version=$(eval "$check_cmd" 2>/dev/null || echo "version unknown")
            success "$tool: $version"
        else
            error "$tool: not installed"
        fi
    done
}

# Main installation flow
main() {
    echo "🚀 Enhanced Dev Box Setup Script"
    echo "================================"
    log "Starting setup... (Log: $LOG_FILE)"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Run setup steps
    detect_system
    update_package_manager
    install_tools
    create_configs
    setup_aliases
    
    echo ""
    verify_installations
    
    echo ""
    success "Dev box setup complete!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Log out and back in for Docker group changes (Linux only)"
    echo "3. Initialize Claude Code: claude auth"
    echo "4. Start Docker Desktop (macOS only)"
    echo ""
    echo "📁 Backups saved to: $BACKUP_DIR"
    echo "📄 Setup log: $LOG_FILE"
    
    # Warnings for Docker
    if command -v docker &> /dev/null && [ "$OS" == "linux" ]; then
        warning "Remember to log out and back in for Docker permissions to take effect"
    fi
}

# Run main function
main "$@"