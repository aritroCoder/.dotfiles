# Dotfiles

Personal dotfiles for macOS, Linux, and WSL. Includes configs for Neovim, tmux, Alacritty, Ghostty, Git, and shell.

## Supported Platforms

- **macOS** (Intel & Apple Silicon)
- **Linux** (Ubuntu/Debian, Arch, Fedora)
- **WSL** (Windows Subsystem for Linux)

## Quick Install

```bash
git clone https://github.com/aritroCoder/.dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

The installer will prompt for each component. Press `y` to install or `n` to skip.

## What's Included

### Shell Configuration
- **`shell/common.sh`** - Shared config (aliases, PATH, functions) sourced by both bash and zsh
- **`.bashrc`** - Linux bash configuration
- **`.zshrc`** - macOS/zsh configuration

### Editor
- **`nvim/`** - Neovim config based on NvChad with custom plugins (Copilot, LSP, formatters, linters)

### Terminal
- **`alacritty/`** - Alacritty config with Catppuccin Mocha theme
- **`ghostty/`** - Ghostty config with Catppuccin Mocha theme
- **`tmux/`** - tmux config with TPM plugins

### Git
- **`git/ignore`** - Global gitignore patterns
- **`.gitconfig`** - Git configuration

### AI Tools
- **`opencode/`** - OpenCode configuration with oh-my-opencode plugin

## Installer Options

The interactive installer can set up:

| Category | Components |
|----------|------------|
| **Core** | Neovim, JetBrainsMono Nerd Font, symlinks |
| **Tools** | tmux, fzf, zoxide, ripgrep, fd |
| **Dev** | Node.js (via NVM), Rust (via rustup), uv (Python) |
| **Terminal** | Ghostty, Alacritty |
| **Containers** | Docker Desktop |
| **AI** | OpenCode + oh-my-opencode |

## Post-Install

1. **Restart your shell** or run `source ~/.zshrc` (macOS) / `source ~/.bashrc` (Linux)
2. **Install tmux plugins**: Open tmux and press `prefix + I`
3. **Install Neovim plugins**: Open nvim and let lazy.nvim install automatically

## Shell Functions

Available after installation:

```bash
# Git worktree helpers
gwa <branch>     # Add new worktree
gwd <branch>     # Remove worktree

# Utilities
extract <file>   # Extract any archive format
mkcd <dir>       # Create directory and cd into it
```

## Requirements

- **macOS**: Homebrew (installed automatically if needed)
- **Linux**: apt package manager (Ubuntu/Debian) or equivalent
- **All platforms**: curl, git

## Manual Steps

Some tools require additional setup after installation:

- **Docker Desktop**: Start with `open -a Docker` (macOS) or `systemctl --user start docker-desktop` (Linux)
- **WSL**: Install Docker Desktop and Ghostty on Windows host, not inside WSL
