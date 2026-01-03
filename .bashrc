#!/bin/bash
# Bash-specific configuration for Linux/WSL

# Exit if not running interactively
case $- in
    *i*) ;;
      *) return;;
esac

# Source shared configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
[[ -f "$DOTFILES_DIR/shell/common.sh" ]] && source "$DOTFILES_DIR/shell/common.sh"

# Bash-specific history settings
HISTCONTROL=ignoreboth
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Debian/Ubuntu chroot indicator
if [[ -z "${debian_chroot:-}" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Prompt configuration
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [[ "$color_prompt" == "yes" ]]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

# Window title for xterm
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# dircolors for ls
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Bash completion
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

# Zoxide initialization (bash-specific)
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd cd bash)"

# FZF key bindings (bash-specific)
if command -v fzf &>/dev/null; then
    [[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
    [[ -f /usr/share/fzf/completion.bash ]] && source /usr/share/fzf/completion.bash
    [[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
fi

# Bun completions (bash-specific)
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
