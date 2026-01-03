#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_FALLBACK_VERSION="0.10.4"

# Installation choices (set by collect_choices)
INSTALL_TOOLS=false
INSTALL_NEOVIM=false
INSTALL_NEOVIM_HOMEBREW=false
INSTALL_FONTS=false
INSTALL_NODE=false
INSTALL_RUST=false
CREATE_SYMLINKS=false
CONFIGURE_GIT=false
GIT_USER_NAME=""
GIT_USER_EMAIL=""
INSTALL_TPM=false
INSTALL_GHOSTTY=false
INSTALL_UV=false
INSTALL_DOCKER=false
INSTALL_OPENCODE=false

# Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_section() { echo -e "\n${BOLD}${GREEN}=== $1 ===${RESET}\n"; }

check_prerequisites() {
    local missing=()
    
    for cmd in git curl unzip; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[ERROR]${RESET} Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install them first:"
        case "$(uname -s)" in
            Darwin*)
                echo "  brew install ${missing[*]}"
                ;;
            Linux*)
                if [[ -f /etc/debian_version ]]; then
                    echo "  sudo apt update && sudo apt install -y ${missing[*]}"
                elif [[ -f /etc/fedora-release ]]; then
                    echo "  sudo dnf install -y ${missing[*]}"
                elif [[ -f /etc/arch-release ]]; then
                    echo "  sudo pacman -S ${missing[*]}"
                else
                    echo "  Install: ${missing[*]}"
                fi
                ;;
        esac
        exit 1
    fi
}

check_prerequisites

confirm() {
    if command -v gum &>/dev/null; then
        gum confirm "$1"
    else
        echo -e "${BOLD}${YELLOW}$1 [y/N]${RESET}"
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

PLATFORM="$(detect_platform)"
ARCH="$(uname -m)"

log_section "Dotfiles Installer"
log_info "Platform: $PLATFORM"
log_info "Architecture: $ARCH"
log_info "Dotfiles directory: $DOTFILES_DIR"

install_homebrew() {
    if ! command -v brew &>/dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    log_success "Homebrew available"
}

install_apt_packages() {
    log_info "Updating apt and installing packages..."
    sudo apt update
    sudo apt install -y build-essential git curl wget unzip tmux fzf ripgrep fd-find
    log_success "APT packages installed"
}

get_latest_nvim_version() {
    curl -sL "https://api.github.com/repos/neovim/neovim/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' || echo ""
}

install_neovim_tarball() {
    local version="$1"
    local platform_suffix=""
    local archive_name=""
    
    case "$PLATFORM" in
        macos)
            case "$ARCH" in
                arm64|aarch64) platform_suffix="macos-arm64" ;;
                x86_64)        platform_suffix="macos-x86_64" ;;
            esac
            ;;
        linux|wsl)
            case "$ARCH" in
                aarch64|arm64) platform_suffix="linux-arm64" ;;
                x86_64)        platform_suffix="linux-x86_64" ;;
            esac
            ;;
    esac
    
    if [[ -z "$platform_suffix" ]]; then
        log_error "Unsupported platform/arch: $PLATFORM/$ARCH"
        return 1
    fi
    
    archive_name="nvim-${platform_suffix}.tar.gz"
    local url="https://github.com/neovim/neovim/releases/download/v${version}/${archive_name}"
    
    log_info "Downloading Neovim v${version} for ${platform_suffix}..."
    
    mkdir -p ~/.local/bin
    cd /tmp
    
    if ! curl -fLO "$url"; then
        log_error "Failed to download Neovim v${version}"
        return 1
    fi
    
    rm -rf ~/.local/bin/nvim-*
    tar -xzf "$archive_name" -C ~/.local/bin
    rm -f "$archive_name"
    
    local extracted_dir
    extracted_dir=$(ls -d ~/.local/bin/nvim-* 2>/dev/null | head -1)
    
    if [[ -d "$extracted_dir" ]]; then
        ln -sf "$extracted_dir/bin/nvim" ~/.local/bin/nvim
        log_success "Neovim v${version} installed to ~/.local/bin/nvim"
        return 0
    else
        log_error "Failed to extract Neovim"
        return 1
    fi
}

install_neovim() {
    [[ "$INSTALL_NEOVIM" != "true" ]] && return 0
    
    if [[ "$INSTALL_NEOVIM_HOMEBREW" == "true" ]]; then
        install_homebrew
        brew install neovim
        log_success "Neovim installed via Homebrew"
        return 0
    fi
    
    log_info "Fetching latest Neovim version..."
    local latest_version
    latest_version="$(get_latest_nvim_version)"
    
    if [[ -n "$latest_version" ]]; then
        log_info "Latest stable version: v${latest_version}"
        
        if install_neovim_tarball "$latest_version"; then
            ~/.local/bin/nvim --version | head -1
            return 0
        else
            log_warn "Failed to install latest, falling back to v${NVIM_FALLBACK_VERSION}"
        fi
    else
        log_warn "Could not fetch latest version, using fallback v${NVIM_FALLBACK_VERSION}"
    fi
    
    if install_neovim_tarball "$NVIM_FALLBACK_VERSION"; then
        ~/.local/bin/nvim --version | head -1
        return 0
    else
        log_error "Failed to install Neovim"
        return 1
    fi
}

install_fonts() {
    [[ "$INSTALL_FONTS" != "true" ]] && return 0
    
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
    local font_dir=""
    
    case "$PLATFORM" in
        macos)      font_dir="$HOME/Library/Fonts" ;;
        linux|wsl)  font_dir="$HOME/.local/share/fonts" ;;
    esac
    
    mkdir -p "$font_dir"
    
    log_info "Downloading JetBrainsMono Nerd Font..."
    curl -fLo /tmp/JetBrainsMono.zip "$font_url"
    unzip -o /tmp/JetBrainsMono.zip -d "$font_dir"
    rm /tmp/JetBrainsMono.zip
    
    if [[ "$PLATFORM" != "macos" ]]; then
        fc-cache -fv
    fi
    
    log_success "JetBrainsMono Nerd Font installed to $font_dir"
}

install_tools() {
    [[ "$INSTALL_TOOLS" != "true" ]] && return 0
    
    case "$PLATFORM" in
        macos)
            install_homebrew
            brew install tmux fzf zoxide ripgrep fd gum
            ;;
        linux|wsl)
            install_apt_packages
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            
            if [[ -f /etc/debian_version ]]; then
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
                sudo apt update && sudo apt install -y gum
            elif [[ -f /etc/fedora-release ]]; then
                echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
                sudo yum install -y gum
            elif [[ -f /etc/arch-release ]]; then
                sudo pacman -S gum
            fi
            ;;
    esac
    log_success "Tools installed"
}

install_node() {
    [[ "$INSTALL_NODE" != "true" ]] && return 0
    
    log_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    
    export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    [[ ! -d "$NVM_DIR" ]] && export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    
    log_info "Installing latest LTS Node.js..."
    nvm install --lts
    
    log_success "Node.js installed: $(node --version)"
}

install_rust() {
    [[ "$INSTALL_RUST" != "true" ]] && return 0
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    log_success "Rust installed: $(rustc --version)"
}

create_symlinks() {
    [[ "$CREATE_SYMLINKS" != "true" ]] && return 0
    
    log_info "Creating config directory..."
    mkdir -p ~/.config
    
    log_info "Removing old symlinks/configs..."
    rm -rf ~/.config/nvim ~/.config/tmux ~/.config/alacritty ~/.config/ghostty
    rm -f ~/.bashrc ~/.zshrc
    
    log_info "Creating symlinks..."
    
    ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
    ln -sf "$DOTFILES_DIR/tmux" ~/.config/tmux
    ln -sf "$DOTFILES_DIR/alacritty" ~/.config/alacritty
    ln -sf "$DOTFILES_DIR/ghostty" ~/.config/ghostty
    ln -sf "$DOTFILES_DIR/opencode" ~/.config/opencode
    
    case "$PLATFORM" in
        macos)
            ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
            log_info "Linked .zshrc (macOS default shell)"
            ;;
        linux|wsl)
            ln -sf "$DOTFILES_DIR/.bashrc" ~/.bashrc
            ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
            log_info "Linked .bashrc and .zshrc"
            ;;
    esac
    
    log_success "Symlinks created"
}

install_tpm() {
    if [[ -d ~/.config/tmux/plugins/tpm ]]; then
        log_info "TPM already installed"
        return 0
    fi
    
    [[ "$INSTALL_TPM" != "true" ]] && return 0
    
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    log_success "TPM installed. Press prefix + I in tmux to install plugins."
}

install_ghostty() {
    [[ "$INSTALL_GHOSTTY" != "true" ]] && return 0
    
    case "$PLATFORM" in
        macos)
            install_homebrew
            brew install --cask ghostty
            log_success "Ghostty installed via Homebrew"
            ;;
        linux)
            if [[ -f /etc/arch-release ]]; then
                sudo pacman -S ghostty
            elif [[ -f /etc/debian_version ]]; then
                log_info "Installing Ghostty via community script (Ubuntu/Debian)..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
            elif [[ -f /etc/fedora-release ]]; then
                sudo dnf copr enable scottames/ghostty -y
                sudo dnf install ghostty -y
            elif command -v snap &>/dev/null; then
                sudo snap install ghostty --classic
            else
                log_warn "No package available for your distro. See https://ghostty.org/docs/install"
                return 1
            fi
            log_success "Ghostty installed"
            ;;
        wsl)
            log_warn "Ghostty should be installed on Windows host, not WSL"
            log_info "Download from: https://ghostty.org/download"
            ;;
    esac
}

install_uv() {
    [[ "$INSTALL_UV" != "true" ]] && return 0
    
    if command -v uv &>/dev/null; then
        log_info "uv already installed: $(uv --version)"
        return 0
    fi
    
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
    
    if command -v uv &>/dev/null; then
        log_success "uv installed: $(uv --version)"
    else
        log_warn "uv installed but not on PATH. Add ~/.local/bin to PATH"
    fi
}

install_docker() {
    [[ "$INSTALL_DOCKER" != "true" ]] && return 0
    
    case "$PLATFORM" in
        macos)
            install_homebrew
            brew install --cask docker
            log_success "Docker Desktop installed"
            log_info "Start Docker Desktop: open -a Docker"
            ;;
        linux)
            log_info "Setting up Docker repository..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg
            
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            
            log_info "Downloading Docker Desktop..."
            curl -fsSL https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -o /tmp/docker-desktop.deb
            sudo apt-get install -y /tmp/docker-desktop.deb
            rm /tmp/docker-desktop.deb
            
            log_success "Docker Desktop installed"
            log_info "Start with: systemctl --user start docker-desktop"
            ;;
        wsl)
            log_warn "Docker Desktop should be installed on Windows host"
            log_info "Download from: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
            log_info "Then enable WSL2 backend in Docker Desktop Settings"
            ;;
    esac
}

prompt_input() {
    local prompt_text="$1"
    local default_value="$2"
    local result=""
    
    if command -v gum &>/dev/null; then
        result=$(gum input --placeholder "$default_value" --prompt "$prompt_text: ")
    else
        echo -en "${BOLD}${YELLOW}$prompt_text${RESET}"
        if [[ -n "$default_value" ]]; then
            echo -en " [${default_value}]: "
        else
            echo -en ": "
        fi
        read -r result
    fi
    
    if [[ -z "$result" && -n "$default_value" ]]; then
        result="$default_value"
    fi
    
    echo "$result"
}

collect_choices() {
    log_section "Select Components to Install"
    
    if confirm "Install common tools (tmux, fzf, zoxide, ripgrep, gum)?"; then
        INSTALL_TOOLS=true
    fi
    
    if confirm "Install Neovim?"; then
        INSTALL_NEOVIM=true
        if [[ "$PLATFORM" == "macos" ]]; then
            if confirm "Use Homebrew for Neovim (recommended for macOS)?"; then
                INSTALL_NEOVIM_HOMEBREW=true
            fi
        fi
    fi
    
    if confirm "Install JetBrainsMono Nerd Font?"; then
        INSTALL_FONTS=true
    fi
    
    if confirm "Install Node.js via NVM?"; then
        INSTALL_NODE=true
    fi
    
    if confirm "Install Rust?"; then
        INSTALL_RUST=true
    fi
    
    if confirm "Create symlinks for dotfiles?"; then
        CREATE_SYMLINKS=true
    fi
    
    if confirm "Configure Git user settings?"; then
        CONFIGURE_GIT=true
        echo ""
        log_info "Enter your Git configuration:"
        
        GIT_USER_NAME=$(prompt_input "GitHub username" "")
        while [[ -z "$GIT_USER_NAME" ]]; do
            log_warn "Username cannot be empty"
            GIT_USER_NAME=$(prompt_input "GitHub username" "")
        done
        
        GIT_USER_EMAIL=$(prompt_input "GitHub email" "")
        while [[ -z "$GIT_USER_EMAIL" ]]; do
            log_warn "Email cannot be empty"
            GIT_USER_EMAIL=$(prompt_input "GitHub email" "")
        done
    fi
    
    if [[ ! -d ~/.config/tmux/plugins/tpm ]]; then
        if confirm "Install TPM (Tmux Plugin Manager)?"; then
            INSTALL_TPM=true
        fi
    fi
    
    if confirm "Install Ghostty terminal?"; then
        INSTALL_GHOSTTY=true
    fi
    
    if confirm "Install uv (fast Python package manager)?"; then
        INSTALL_UV=true
    fi
    
    if confirm "Install Docker Desktop?"; then
        INSTALL_DOCKER=true
    fi
    
    if confirm "Install OpenCode and oh-my-opencode?"; then
        INSTALL_OPENCODE=true
    fi
    
    echo ""
    log_section "Starting Installation"
}

configure_git() {
    [[ "$CONFIGURE_GIT" != "true" ]] && return 0
    
    log_info "Creating ~/.gitconfig..."
    cat > ~/.gitconfig << EOF
[user]
	email = $GIT_USER_EMAIL
	name = $GIT_USER_NAME
[credential]
	helper = store
[init]
	defaultBranch = main
EOF
    
    log_success "Git configured for $GIT_USER_NAME <$GIT_USER_EMAIL>"
}

show_ssh_instructions() {
    log_section "GitHub SSH Authentication Setup"
    
    echo -e "${BOLD}To authenticate with GitHub using SSH, follow these steps:${RESET}"
    echo ""
    
    case "$PLATFORM" in
        macos)
            echo -e "${BOLD}1. Generate an SSH key:${RESET}"
            echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
            echo ""
            echo -e "${BOLD}2. Start the SSH agent and add your key:${RESET}"
            echo "   eval \"\$(ssh-agent -s)\""
            echo "   ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
            echo ""
            echo -e "${BOLD}3. Add SSH config for Keychain persistence:${RESET}"
            echo "   Create/edit ~/.ssh/config with:"
            echo "   Host github.com"
            echo "       AddKeysToAgent yes"
            echo "       UseKeychain yes"
            echo "       IdentityFile ~/.ssh/id_ed25519"
            echo ""
            echo -e "${BOLD}4. Copy the public key to clipboard:${RESET}"
            echo "   pbcopy < ~/.ssh/id_ed25519.pub"
            echo ""
            echo -e "${BOLD}5. Add the key to GitHub:${RESET}"
            echo "   - Go to https://github.com/settings/keys"
            echo "   - Click 'New SSH key', paste your key, and save"
            echo ""
            echo -e "${BOLD}6. Test the connection:${RESET}"
            echo "   ssh -T git@github.com"
            ;;
        linux)
            echo -e "${BOLD}1. Generate an SSH key:${RESET}"
            echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
            echo ""
            echo -e "${BOLD}2. Start the SSH agent and add your key:${RESET}"
            echo "   eval \"\$(ssh-agent -s)\""
            echo "   ssh-add ~/.ssh/id_ed25519"
            echo ""
            echo -e "${BOLD}3. Copy the public key to clipboard:${RESET}"
            echo "   # Using xclip:"
            echo "   xclip -selection clipboard < ~/.ssh/id_ed25519.pub"
            echo "   # Or using xsel:"
            echo "   xsel --clipboard < ~/.ssh/id_ed25519.pub"
            echo "   # Or just print it:"
            echo "   cat ~/.ssh/id_ed25519.pub"
            echo ""
            echo -e "${BOLD}4. Add the key to GitHub:${RESET}"
            echo "   - Go to https://github.com/settings/keys"
            echo "   - Click 'New SSH key', paste your key, and save"
            echo ""
            echo -e "${BOLD}5. Test the connection:${RESET}"
            echo "   ssh -T git@github.com"
            echo ""
            echo -e "${BOLD}Optional - Auto-start ssh-agent:${RESET}"
            echo "   Add to your ~/.bashrc or ~/.zshrc:"
            echo "   eval \"\$(ssh-agent -s)\" > /dev/null 2>&1"
            echo "   ssh-add ~/.ssh/id_ed25519 2>/dev/null"
            ;;
        wsl)
            echo -e "${BOLD}1. Generate an SSH key:${RESET}"
            echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
            echo ""
            echo -e "${BOLD}2. Start the SSH agent and add your key:${RESET}"
            echo "   eval \"\$(ssh-agent -s)\""
            echo "   ssh-add ~/.ssh/id_ed25519"
            echo ""
            echo -e "${BOLD}3. Copy the public key to clipboard:${RESET}"
            echo "   # Copy to Windows clipboard:"
            echo "   cat ~/.ssh/id_ed25519.pub | clip.exe"
            echo ""
            echo -e "${BOLD}4. Add the key to GitHub:${RESET}"
            echo "   - Go to https://github.com/settings/keys"
            echo "   - Click 'New SSH key', paste your key, and save"
            echo ""
            echo -e "${BOLD}5. Test the connection:${RESET}"
            echo "   ssh -T git@github.com"
            echo ""
            echo -e "${BOLD}Optional - Use Windows SSH agent (recommended):${RESET}"
            echo "   1. Enable OpenSSH Agent in Windows:"
            echo "      - Open Services (services.msc)"
            echo "      - Find 'OpenSSH Authentication Agent'"
            echo "      - Set startup type to 'Automatic' and start it"
            echo "   2. Configure SSH to use Windows agent in ~/.ssh/config:"
            echo "      Host github.com"
            echo "          IdentityFile ~/.ssh/id_ed25519"
            ;;
    esac
    
    echo ""
}

install_opencode() {
    [[ "$INSTALL_OPENCODE" != "true" ]] && return 0
    
    if command -v opencode &>/dev/null; then
        log_info "OpenCode already installed: $(opencode --version 2>/dev/null || echo 'version check failed')"
    else
        log_info "Installing OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
        export PATH="$HOME/.opencode/bin:$PATH"
        
        if command -v opencode &>/dev/null; then
            log_success "OpenCode installed: $(opencode --version 2>/dev/null || echo 'version check failed')"
        else
            log_error "OpenCode installation failed"
            return 1
        fi
    fi
    
    local omo_config="$HOME/.config/opencode/oh-my-opencode.json"
    if [[ -f "$omo_config" ]]; then
        log_info "oh-my-opencode already installed (config exists at $omo_config)"
    else
        log_info "Installing oh-my-opencode plugin..."
        if command -v bunx &>/dev/null; then
            bunx oh-my-opencode install
            log_success "oh-my-opencode installed"
        elif command -v npx &>/dev/null; then
            npx oh-my-opencode install
            log_success "oh-my-opencode installed"
        else
            log_warn "Neither bunx nor npx found. Install Node.js first, then run:"
            log_info "  npx oh-my-opencode install"
            return 1
        fi
    fi
}

main() {
    collect_choices
    
    [[ "$INSTALL_TOOLS" == "true" ]] && { log_section "Platform-specific packages"; install_tools; }
    [[ "$INSTALL_NEOVIM" == "true" ]] && { log_section "Neovim"; install_neovim; }
    [[ "$INSTALL_FONTS" == "true" ]] && { log_section "Fonts"; install_fonts; }
    [[ "$INSTALL_NODE" == "true" || "$INSTALL_RUST" == "true" ]] && log_section "Development Tools"
    install_node
    install_rust
    [[ "$CREATE_SYMLINKS" == "true" ]] && { log_section "Symlinks"; create_symlinks; }
    [[ "$CONFIGURE_GIT" == "true" ]] && { log_section "Git Configuration"; configure_git; }
    [[ "$INSTALL_TPM" == "true" ]] && { log_section "Tmux"; install_tpm; }
    [[ "$INSTALL_GHOSTTY" == "true" ]] && { log_section "Terminal"; install_ghostty; }
    [[ "$INSTALL_UV" == "true" ]] && { log_section "Python Tools"; install_uv; }
    [[ "$INSTALL_DOCKER" == "true" ]] && { log_section "Containers"; install_docker; }
    [[ "$INSTALL_OPENCODE" == "true" ]] && { log_section "AI Tools"; install_opencode; }
    
    [[ "$CONFIGURE_GIT" == "true" ]] && show_ssh_instructions
    
    log_section "Installation Complete"
    log_success "Dotfiles installed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc  # or ~/.zshrc"
    echo "  2. Open tmux and press prefix + I to install plugins"
    echo "  3. Open nvim and let lazy.nvim install plugins"
    echo ""
}

main "$@"
