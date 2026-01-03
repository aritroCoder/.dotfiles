# AGENTS.md - Dotfiles Repository Guide

This document provides instructions for AI coding agents working in this repository.

## ⚠️ CRITICAL: Always Run Tests After Changes

**After EVERY modification to any file in this repository, you MUST run the Docker tests to verify nothing is broken.**

```bash
# Build and test on Debian (Ubuntu 24.04)
docker build -t dotfiles-deb -f Dockerfile.deb . && \
docker run --rm dotfiles-deb /root/.dotfiles/test-install.sh

# Build and test on Fedora
docker build -t dotfiles-fedora -f Dockerfile.fedora . && \
docker run --rm dotfiles-fedora /root/.dotfiles/test-install.sh
```

**Quick verification (summary only):**
```bash
docker run --rm dotfiles-deb /root/.dotfiles/test-install.sh 2>&1 | grep -E "(PASSED|FAILED|ALL TESTS)"
docker run --rm dotfiles-fedora /root/.dotfiles/test-install.sh 2>&1 | grep -E "(PASSED|FAILED|ALL TESTS)"
```

Both platforms must show `=== ALL TESTS PASSED ===` before committing.

---

## Repository Structure

```
.dotfiles/
├── install.sh           # Cross-platform installer (main entry point)
├── test-install.sh      # Test suite for Docker validation
├── shell/
│   └── common.sh        # Shared shell config (bash + zsh)
├── .bashrc              # Linux/WSL bash config (sources common.sh)
├── .zshrc               # macOS/Linux zsh config (sources common.sh)
├── nvim/                # Neovim config (NvChad-based)
├── tmux/                # tmux config with TPM
├── alacritty/           # Alacritty terminal config
├── ghostty/             # Ghostty terminal config
├── opencode/            # OpenCode AI config
├── git/                 # Global git config
├── Dockerfile.deb       # Ubuntu test container
└── Dockerfile.fedora    # Fedora test container
```

---

## Build/Lint/Test Commands

### Shell Scripts (Bash)
```bash
# Syntax check (ALWAYS run before committing shell changes)
bash -n install.sh
bash -n shell/common.sh
bash -n test-install.sh

# ShellCheck (if available)
shellcheck install.sh shell/common.sh
```

### Lua (Neovim)
```bash
# Format with stylua (config in nvim/.stylua.toml)
stylua nvim/

# Check syntax
luacheck nvim/lua/ --no-unused-args
```

### Single Test Runs
```bash
# Run specific test function in Docker
docker run --rm dotfiles-deb bash -c "
  source /root/.dotfiles/install.sh
  # Call specific function, e.g.:
  install_neovim_tarball '0.10.4'
"
```

---

## Code Style Guidelines

### Shell Scripts (Bash)

**File Header:**
```bash
#!/bin/bash
set -e  # Exit on error (required for install.sh)
```

**Naming Conventions:**
- Functions: `snake_case` (e.g., `install_neovim`, `detect_platform`)
- Variables: `UPPER_SNAKE_CASE` for globals, `lower_snake` for locals
- Use `local` for function-scoped variables

**Formatting:**
- Indent: 4 spaces
- Line length: ~100 chars soft limit
- Use `[[ ]]` for conditionals (not `[ ]`)
- Quote variables: `"$var"` not `$var`

**Error Handling:**
```bash
# Check command existence before use
command -v nvim &>/dev/null && nvim --version

# Use || for fallbacks
some_command || log_error "Command failed"

# Use conditional checks
if [[ -f "$file" ]]; then
    # ...
fi
```

**Logging (install.sh pattern):**
```bash
log_info "Message"      # Blue [INFO]
log_success "Message"   # Green [OK]
log_warn "Message"      # Yellow [WARN]
log_error "Message"     # Red [ERROR]
log_section "Title"     # Section header
```

**User Prompts:**
```bash
# Use confirm() - auto-detects gum availability
if confirm "Install package?"; then
    # install...
fi
```

### Lua (Neovim)

**Stylua Config (nvim/.stylua.toml):**
- Column width: 120
- Indent: 4 spaces
- Quote style: double quotes preferred
- Line endings: Unix

**Pattern:**
```lua
local M = {}

M.setup = function()
    -- config
end

return M
```

**Imports:**
```lua
-- Use require with quotes
local utils = require "core.utils"
require "custom.configs.lspconfig"
```

---

## Platform Handling

The installer supports: **macOS**, **Linux** (Debian/Ubuntu, Fedora, Arch), **WSL**

**Detection Pattern:**
```bash
case "$PLATFORM" in
    macos)
        # macOS-specific (Homebrew)
        ;;
    linux|wsl)
        # Linux-specific (apt, dnf, pacman)
        ;;
esac
```

**Architecture:** Check `$ARCH` for `x86_64` vs `arm64/aarch64`.

---

## Security Rules

**NEVER commit:**
- Private SSH keys (`.ssh/keys/*` except `*.pub`)
- OAuth tokens, API keys
- `.git-credentials`
- `gcloud/`, `github-copilot/`, `uv/`, `yarn/` directories

**Safe to commit:**
- Public SSH keys (`*.pub`)
- Config files without secrets
- OpenCode config (excluding `antigravity-accounts.json`)

---

## Adding New Features

1. **Add to install.sh:** Create `install_<feature>()` function
2. **Wire into main():** Add under appropriate section with `log_section`
3. **Handle all platforms:** macOS (brew), Debian (apt), Fedora (dnf), Arch (pacman)
4. **Check if already installed:** Skip redundant installs
5. **Test in Docker:** Run both Dockerfile.deb and Dockerfile.fedora tests

**Template:**
```bash
install_mytool() {
    if confirm "Install mytool?"; then
        if command -v mytool &>/dev/null; then
            log_info "mytool already installed"
            return 0
        fi
        
        case "$PLATFORM" in
            macos)
                install_homebrew
                brew install mytool
                ;;
            linux|wsl)
                if [[ -f /etc/debian_version ]]; then
                    sudo apt install -y mytool
                elif [[ -f /etc/fedora-release ]]; then
                    sudo dnf install -y mytool
                fi
                ;;
        esac
        log_success "mytool installed"
    fi
}
```

---

## Common Gotchas

1. **Interactive check in .bashrc:** Lines 5-8 exit early for non-interactive shells. Test shell functions by sourcing `common.sh` directly.

2. **Docker ARM64 limitation:** Arch Linux Docker image doesn't support ARM64 (Apple Silicon). Only test on Debian/Fedora.

3. **Symlink paths:** Always use `$DOTFILES_DIR` variable, never hardcode paths.

4. **TPM plugins:** The `tmux/plugins/` directory is gitignored except for `tpm` itself.

5. **Neovim plugins:** Managed by lazy.nvim, lock file is `nvim/lazy-lock.json`.
