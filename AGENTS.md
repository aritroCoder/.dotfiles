# AGENTS.md - Dotfiles Repository Guide

## ⚠️ CRITICAL: Run Tests After Every Change

```bash
# Full test (both platforms must pass before committing)
docker build -t dotfiles-deb -f Dockerfile.deb . && docker run --rm dotfiles-deb /root/.dotfiles/test-install.sh
docker build -t dotfiles-fedora -f Dockerfile.fedora . && docker run --rm dotfiles-fedora /root/.dotfiles/test-install.sh

# Quick verification
docker run --rm dotfiles-deb /root/.dotfiles/test-install.sh 2>&1 | grep -E "(PASSED|FAILED|ALL TESTS)"
```

## Repository Structure

```
.dotfiles/
├── install.sh          # Cross-platform installer (main entry point)
├── test-install.sh     # Docker test suite
├── shell/common.sh     # Shared shell config (sourced by .bashrc/.zshrc)
├── .bashrc / .zshrc    # Shell configs (Linux/macOS)
├── nvim/               # Neovim config (NvChad-based, lazy.nvim)
├── tmux/               # tmux config with TPM
├── alacritty/          # Alacritty terminal config
├── ghostty/            # Ghostty terminal config
├── opencode/           # OpenCode AI config
└── Dockerfile.*        # Test containers (deb, fedora)
```

## Build/Lint/Test Commands

### Shell Scripts
```bash
bash -n install.sh                    # Syntax check (always run before commit)
bash -n shell/common.sh
shellcheck install.sh shell/common.sh # Lint (if available)
```

### Lua (Neovim)
```bash
stylua nvim/                          # Format (config: nvim/.stylua.toml)
luacheck nvim/lua/ --no-unused-args   # Lint
```

### Single Test Run
```bash
docker run --rm dotfiles-deb bash -c "source /root/.dotfiles/install.sh && install_neovim_tarball '0.10.4'"
```

## Code Style

### Bash

**Header:** `#!/bin/bash` + `set -e`

**Naming:**
- Functions: `snake_case` → `install_neovim`, `detect_platform`
- Globals: `UPPER_SNAKE` → `PLATFORM`, `DOTFILES_DIR`
- Locals: `lower_snake` with `local` keyword

**Formatting:**
- Indent: 4 spaces
- Conditionals: `[[ ]]` not `[ ]`
- Variables: always quote `"$var"`

**Logging:**
```bash
log_info "..."     # Blue [INFO]
log_success "..."  # Green [OK]
log_warn "..."     # Yellow [WARN]
log_error "..."    # Red [ERROR]
log_section "..."  # Section header
```

**User Input:**
```bash
if confirm "Install X?"; then ...    # Auto-detects gum
value=$(prompt_input "Enter name" "default")
```

**Error Handling:**
```bash
command -v tool &>/dev/null && tool --version  # Check before use
some_command || log_error "Failed"             # Fallback on error
```

### Lua (Neovim)

**Style:** 4 spaces, 120 char width, double quotes, Unix line endings

**Module Pattern:**
```lua
local M = {}
M.setup = function()
    -- config
end
return M
```

**Imports:** `local utils = require "core.utils"`

## Platform Handling

Supports: **macOS**, **Linux** (Debian, Fedora, Arch), **WSL**

```bash
case "$PLATFORM" in
    macos)      # Homebrew
        ;;
    linux|wsl)  # apt/dnf/pacman
        if [[ -f /etc/debian_version ]]; then
            sudo apt install -y pkg
        elif [[ -f /etc/fedora-release ]]; then
            sudo dnf install -y pkg
        fi
        ;;
esac
```

Architecture: `$ARCH` → `x86_64` or `arm64/aarch64`

## Adding New Features

1. Create `install_<feature>()` function in `install.sh`
2. Add to `main()` under appropriate `log_section`
3. Handle all platforms (brew/apt/dnf/pacman)
4. Check if already installed before installing
5. Run Docker tests on both Debian and Fedora

**Template:**
```bash
install_mytool() {
    if confirm "Install mytool?"; then
        command -v mytool &>/dev/null && { log_info "Already installed"; return 0; }
        case "$PLATFORM" in
            macos) brew install mytool ;;
            linux|wsl)
                [[ -f /etc/debian_version ]] && sudo apt install -y mytool
                [[ -f /etc/fedora-release ]] && sudo dnf install -y mytool
                ;;
        esac
        log_success "mytool installed"
    fi
}
```

## Security

**Never commit:** Private SSH keys, API tokens, `.git-credentials`, `gcloud/`, `github-copilot/`

**Safe:** Public keys (`*.pub`), config files without secrets

## Gotchas

1. **Non-interactive shells:** `.bashrc` exits early; test by sourcing `common.sh` directly
2. **ARM64 Docker:** Arch image doesn't support Apple Silicon; test on Debian/Fedora only
3. **Symlink paths:** Use `$DOTFILES_DIR`, never hardcode
4. **Git config:** Generated dynamically by `configure_git()`, not symlinked
5. **Plugin managers:** TPM for tmux, lazy.nvim for Neovim (lock: `nvim/lazy-lock.json`)

## After Every Change

1. Run Docker tests (see top)
2. Update this file if structure/behavior changed
