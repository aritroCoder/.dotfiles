#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_FALLBACK_VERSION="0.10.4"

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
    if confirm "Install Neovim?"; then
        case "$PLATFORM" in
            macos)
                if confirm "Use Homebrew for Neovim (recommended for macOS)?"; then
                    install_homebrew
                    brew install neovim
                    log_success "Neovim installed via Homebrew"
                    return 0
                fi
                ;;
        esac
        
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
    fi
}

install_fonts() {
    if confirm "Install JetBrainsMono Nerd Font?"; then
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
    fi
}

install_tools() {
    if confirm "Install common tools (tmux, fzf, zoxide, ripgrep, gum)?"; then
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
    fi
}

install_node() {
    if confirm "Install Node.js via NVM?"; then
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
        
        log_info "Installing latest LTS Node.js..."
        nvm install --lts
        
        log_success "Node.js installed: $(node --version)"
    fi
}

install_rust() {
    if confirm "Install Rust?"; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log_success "Rust installed: $(rustc --version)"
    fi
}

create_symlinks() {
    if confirm "Create symlinks for dotfiles?"; then
        log_info "Creating config directory..."
        mkdir -p ~/.config
        
        log_info "Removing old symlinks/configs..."
        rm -rf ~/.config/nvim ~/.config/tmux ~/.config/alacritty ~/.config/ghostty
        rm -f ~/.bashrc ~/.zshrc ~/.gitconfig
        
        log_info "Creating symlinks..."
        
        ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
        ln -sf "$DOTFILES_DIR/tmux" ~/.config/tmux
        ln -sf "$DOTFILES_DIR/alacritty" ~/.config/alacritty
        ln -sf "$DOTFILES_DIR/ghostty" ~/.config/ghostty
        ln -sf "$DOTFILES_DIR/opencode" ~/.config/opencode
        ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
        
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
    fi
}

install_tpm() {
    if [[ ! -d ~/.config/tmux/plugins/tpm ]]; then
        if confirm "Install TPM (Tmux Plugin Manager)?"; then
            git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
            log_success "TPM installed. Press prefix + I in tmux to install plugins."
        fi
    else
        log_info "TPM already installed"
    fi
}

install_ghostty() {
    if confirm "Install Ghostty terminal?"; then
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
    fi
}

install_uv() {
    if confirm "Install uv (fast Python package manager)?"; then
        if command -v uv &>/dev/null; then
            log_info "uv already installed: $(uv --version)"
            if confirm "Update uv to latest?"; then
                uv self update
            fi
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
    fi
}

install_docker() {
    if confirm "Install Docker Desktop?"; then
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
    fi
}

install_opencode() {
    if confirm "Install OpenCode and oh-my-opencode?"; then
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
    fi
}

main() {
    log_section "Platform-specific packages"
    install_tools
    
    log_section "Neovim"
    install_neovim
    
    log_section "Fonts"
    install_fonts
    
    log_section "Development Tools"
    install_node
    install_rust
    
    log_section "Symlinks"
    create_symlinks
    
    log_section "Tmux"
    install_tpm
    
    log_section "Terminal"
    install_ghostty
    
    log_section "Python Tools"
    install_uv
    
    log_section "Containers"
    install_docker
    
    log_section "AI Tools"
    install_opencode
    
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
