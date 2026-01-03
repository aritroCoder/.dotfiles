#!/bin/zsh
# Zsh-specific configuration for macOS/Linux

# Source shared configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
[[ -f "$DOTFILES_DIR/shell/common.sh" ]] && source "$DOTFILES_DIR/shell/common.sh"

# Zsh-specific history settings
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Zsh options
setopt AUTO_CD
setopt CORRECT
setopt NO_BEEP

# Completion system
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Prompt (simple, works everywhere)
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_}$ '

# Zoxide initialization (zsh-specific)
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd cd zsh)"

# FZF key bindings (zsh-specific)
if command -v fzf &>/dev/null; then
    # Try multiple locations for fzf integration
    if [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
        source /usr/share/fzf/completion.zsh
    else
        # macOS/Homebrew: use fzf's built-in shell integration
        source <(fzf --zsh) 2>/dev/null || true
    fi
fi

# Bun completions (zsh-specific)
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
