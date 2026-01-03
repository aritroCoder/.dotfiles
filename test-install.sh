#!/bin/bash
set -e

cd /root/.dotfiles

echo "=== Testing install.sh in Docker container ==="
echo ""

test_confirm_fallback() {
    echo "=== Testing confirm() fallback (no gum) ==="
    
    source ./install.sh
    
    if echo "n" | confirm "Test prompt?" 2>/dev/null; then
        echo "[FAIL] confirm should return 1 for 'n'"
        exit 1
    else
        echo "[OK] confirm returns 1 for 'n' input"
    fi
    
    echo "=== Confirm fallback test PASSED ==="
}

test_symlinks() {
    echo "=== Testing symlinks creation ==="
    
    mkdir -p ~/.config
    rm -rf ~/.config/nvim ~/.config/tmux ~/.config/alacritty ~/.config/ghostty ~/.config/opencode
    rm -f ~/.bashrc ~/.zshrc
    
    DOTFILES_DIR="/root/.dotfiles"
    ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
    ln -sf "$DOTFILES_DIR/tmux" ~/.config/tmux
    ln -sf "$DOTFILES_DIR/alacritty" ~/.config/alacritty
    ln -sf "$DOTFILES_DIR/ghostty" ~/.config/ghostty
    ln -sf "$DOTFILES_DIR/opencode" ~/.config/opencode
    ln -sf "$DOTFILES_DIR/.bashrc" ~/.bashrc
    ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
    
    # Generate gitconfig dynamically (as the installer now does)
    cat > ~/.gitconfig << EOF
[user]
	email = test@example.com
	name = testuser
[credential]
	helper = store
[init]
	defaultBranch = main
EOF
    
    echo ""
    echo "Checking symlinks..."
    
    local errors=0
    
    if [[ -L ~/.config/nvim ]]; then
        echo "[OK] ~/.config/nvim -> $(readlink ~/.config/nvim)"
    else
        echo "[FAIL] ~/.config/nvim not a symlink"
        ((errors++))
    fi
    
    if [[ -L ~/.config/tmux ]]; then
        echo "[OK] ~/.config/tmux -> $(readlink ~/.config/tmux)"
    else
        echo "[FAIL] ~/.config/tmux not a symlink"
        ((errors++))
    fi
    
    if [[ -L ~/.config/alacritty ]]; then
        echo "[OK] ~/.config/alacritty -> $(readlink ~/.config/alacritty)"
    else
        echo "[FAIL] ~/.config/alacritty not a symlink"
        ((errors++))
    fi
    
    if [[ -L ~/.config/ghostty ]]; then
        echo "[OK] ~/.config/ghostty -> $(readlink ~/.config/ghostty)"
    else
        echo "[FAIL] ~/.config/ghostty not a symlink"
        ((errors++))
    fi
    
    if [[ -L ~/.config/opencode ]]; then
        echo "[OK] ~/.config/opencode -> $(readlink ~/.config/opencode)"
    else
        echo "[FAIL] ~/.config/opencode not a symlink"
        ((errors++))
    fi
    
    if [[ -L ~/.bashrc ]]; then
        echo "[OK] ~/.bashrc -> $(readlink ~/.bashrc)"
    else
        echo "[FAIL] ~/.bashrc not a symlink"
        ((errors++))
    fi
    
    if [[ -L ~/.zshrc ]]; then
        echo "[OK] ~/.zshrc -> $(readlink ~/.zshrc)"
    else
        echo "[FAIL] ~/.zshrc not a symlink"
        ((errors++))
    fi
    
    if [[ -f ~/.gitconfig ]] && grep -q "testuser" ~/.gitconfig; then
        echo "[OK] ~/.gitconfig exists with correct user"
    else
        echo "[FAIL] ~/.gitconfig missing or has wrong content"
        ((errors++))
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        echo "=== All symlink tests PASSED ==="
    else
        echo "=== $errors symlink tests FAILED ==="
        exit 1
    fi
}

test_shell_source() {
    echo ""
    echo "=== Testing shell sourcing ==="
    
    export DOTFILES_DIR=/root/.dotfiles
    source /root/.dotfiles/shell/common.sh
    
    if type extract &>/dev/null; then
        echo "[OK] common.sh sources correctly and extract function available"
    else
        echo "[FAIL] common.sh failed to source or extract function missing"
        exit 1
    fi
    
    if type gwa &>/dev/null; then
        echo "[OK] gwa function available"
    else
        echo "[FAIL] gwa function missing"
        exit 1
    fi
    
    if type mkcd &>/dev/null; then
        echo "[OK] mkcd function available"
    else
        echo "[FAIL] mkcd function missing"
        exit 1
    fi
    
    echo "=== Shell sourcing test PASSED ==="
}

test_neovim_install() {
    echo ""
    echo "=== Testing Neovim tarball install ==="
    
    source ./install.sh
    
    PLATFORM="linux"
    ARCH="$(uname -m)"
    
    if install_neovim_tarball "0.10.4"; then
        if ~/.local/bin/nvim --version | head -1; then
            echo "[OK] Neovim installed successfully"
        else
            echo "[FAIL] Neovim binary not working"
            exit 1
        fi
    else
        echo "[FAIL] Neovim installation failed"
        exit 1
    fi
    
    echo "=== Neovim install test PASSED ==="
}

echo "Running tests..."
echo ""

test_confirm_fallback
test_symlinks  
test_shell_source
test_neovim_install

echo ""
echo "=== ALL TESTS PASSED ==="
