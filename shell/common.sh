#!/bin/bash
# =============================================================================
# Common Shell Configuration
# Shared between .bashrc and .zshrc for consistent experience across platforms
# =============================================================================

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------
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

DOTFILES_PLATFORM="$(detect_platform)"
DOTFILES_ARCH="$(uname -m)"

# -----------------------------------------------------------------------------
# PATH Configuration (Platform-agnostic)
# -----------------------------------------------------------------------------

# Local binaries (works on all platforms)
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Go
[[ -d "/usr/local/go/bin" ]] && export PATH="$PATH:/usr/local/go/bin"
[[ -d "$HOME/go/bin" ]] && export PATH="$PATH:$HOME/go/bin"

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"

# Bun
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# OpenCode
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"

# Antigravity
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Conda (platform-agnostic initialization)
if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
    __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.bash' 'hook' 2>/dev/null)" || \
    __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__conda_setup"
    else
        [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]] && . "$HOME/miniconda3/etc/profile.d/conda.sh"
    fi
    unset __conda_setup
fi

# -----------------------------------------------------------------------------
# Aliases (Cross-platform)
# -----------------------------------------------------------------------------

# ls with color (platform-specific)
if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# tmux with UTF-8 support
alias tmux='tmux -u'

# Common shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# -----------------------------------------------------------------------------
# Functions (Cross-platform)
# -----------------------------------------------------------------------------

# Git worktree helpers for agent sandboxes (via DHH)
# Usage: `gwa fix` creates ../project--fix worktree, `gwd` removes it
gwa() {
    if [[ -z "$1" ]]; then
        echo "Usage: gwa [branch name]"
        return 1
    fi

    local branch="$1"
    local base="$(basename "$PWD")"
    local worktree_path="../${base}--${branch}"

    git worktree add -b "$branch" "$worktree_path"
    cd "$worktree_path"
}

gwd() {
    # Check if gum is available, otherwise use basic confirm
    if command -v gum &>/dev/null; then
        gum confirm "Remove worktree and branch?" || return 0
    else
        read -p "Remove worktree and branch? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
    fi

    local cwd worktree root branch
    cwd="$(pwd)"
    worktree="$(basename "$cwd")"

    # Split on first `--`
    root="${worktree%%--*}"
    branch="${worktree#*--}"

    # Protect against accidentally nuking a non-worktree directory
    if [[ "$root" != "$worktree" ]]; then
        cd "../$root"
        git worktree remove "$worktree" --force
        git branch -D "$branch"
    else
        echo "Not in a worktree directory (expected 'project--branch' format)"
    fi
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives (platform-agnostic)
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# -----------------------------------------------------------------------------
# Tool Initialization (Cross-platform)
# -----------------------------------------------------------------------------

# Zoxide (smart cd replacement)
if command -v zoxide &>/dev/null; then
    # Shell-specific init is done in .bashrc/.zshrc
    :
fi

# FZF (fuzzy finder)
if command -v fzf &>/dev/null; then
    # Shell-specific init is done in .bashrc/.zshrc
    :
fi

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

# Editor preference
if command -v nvim &>/dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
elif command -v vim &>/dev/null; then
    export EDITOR='vim'
    export VISUAL='vim'
fi

# History settings (shell-agnostic values)
export HISTSIZE=10000
export HISTFILESIZE=20000

# Less options
export LESS='-R'

# -----------------------------------------------------------------------------
# Platform-specific PATH additions
# -----------------------------------------------------------------------------

case "$DOTFILES_PLATFORM" in
    macos)
        # Homebrew
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ;;
    linux|wsl)
        # Linux-specific paths can be added here
        ;;
esac
