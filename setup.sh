WORK=$PWD

# Add formatting variables at the top
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"
LINE="======================================"

# Function to ask for confirmation
confirm() {
    echo -e "${BOLD}${YELLOW}Do you want to $1? [y/N]${RESET}"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Install build essentials
if confirm "install build essentials (C/C++)"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing build essentials...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    sudo apt update
    sudo apt install build-essential -y
    source ~/.bashrc
    gcc --version
    g++ --version
    make --version
    echo -e "${BOLD}${GREEN}Done installing build essentials.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping build essentials installation${RESET}"
fi

# Removing old versions of nvim
if confirm "remove old versions of nvim"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Removing old versions of nvim${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    sudo apt-get remove -y --purge neovim
    sudo apt-get remove -y --purge neovim-qt
    sudo apt-get remove -y --purge python3-neovim
    sudo apt-get remove -y --purge python-neovim
    cd ~/.local/bin
    rm -fr nvim
    cd $WORK
else
    echo -e "${BOLD}${RED}Skipping removal of old nvim versions${RESET}"
fi

# Installing neovim
if confirm "install neovim"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing neovim >= 0.9.0${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    wget https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.tar.gz
    mkdir -p ~/.local/bin
    mv nvim-linux-x86_64.tar.gz ~/.local/bin
    cd ~/.local/bin
    rm -fr nvim
    tar -xzvf nvim-linux-x86_64.tar.gz
    rm -fr nvim-linux-x86_64.tar.gz
    ln -s ./nvim-linux-x86_64/bin/nvim ./nvim
    echo -e "${BOLD}${GREEN}Done installing neovim.${RESET}"
    source ~/.bashrc
    nvim --version
else
    echo -e "${BOLD}${RED}Skipping neovim installation${RESET}"
fi

# Getting JetBrains Mono Nerd Font
if confirm "install JetBrains Mono Nerd Font"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Getting JetBrains Mono Nerd Font...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    cd $WORK
    sudo apt install unzip
    bash getNerdFont.sh
else
    echo -e "${BOLD}${RED}Skipping Nerd Font installation${RESET}"
fi

# Installing node version manager
if confirm "install nvm"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing nvm...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    source ~/.bashrc
    nvm --version
    echo -e "${BOLD}${GREEN}Done installing nvm.${RESET}"
    nvm install node --lts
    echo -e "${BOLD}${GREEN}Done installing node.${RESET}"
    corepack enable
    yarn -v
    echo -e "${BOLD}${GREEN}Done enabling corepack.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping nvm installation${RESET}"
fi

# Installing python using conda
if confirm "install conda"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing conda...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm ~/miniconda3/miniconda.sh
    source ~/miniconda3/bin/activate
    conda init --all
    python --version
    echo -e "${BOLD}${GREEN}Done installing conda.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping conda installation${RESET}"
fi

# Installing rust
if confirm "install rust"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing rust...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.bashrc
    echo -e "${BOLD}${GREEN}Done installing rust.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping rust installation${RESET}"
fi

# Setting up symlinks
if confirm "set up symlinks"; then
    echo -e "${BOLD}${GREEN}Cleaning up old symlinks...${RESET}"
    echo "Check if config directory exists"
    if [ -d ~/.config ]; then
        echo "Config directory exists"
    else
        echo "Config directory does not exist"
        mkdir ~/.config
    fi
    rm -f ~/.bashrc
    rm -f ~/.gitconfig
    rm -f ~/.git-credentials
    rm -f ~/.config/alacritty
    rm -f ~/.config/nvim
    rm -f ~/.config/tmux
    rm -f ~/.config/kitty
    rm -f ~/.ssh
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Setting up symlinks...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    ln -s ~/.dotfiles/.bashrc ~/.bashrc
    ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
    ln -s ~/.dotfiles/.git-credentials ~/.git-credentials
    ln -s ~/.dotfiles/alacritty/ ~/.config/alacritty
    ln -s ~/.dotfiles/nvim/ ~/.config/nvim
    ln -s ~/.dotfiles/tmux/ ~/.config/tmux
    ln -s ~/.dotfiles/kitty/ ~/.config/kitty
    ln -s ~/.dotfiles/.ssh/ ~/.ssh
    echo -e "${BOLD}${GREEN}Done creating symlinks.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping symlink creation${RESET}"
fi

# Installing alacritty
if confirm "install alacritty"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing alacritty...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    sudo apt update && sudo apt upgrade
    sudo add-apt-repository ppa:aslatter/ppa -y
    sudo apt install alacritty -y
    echo -e "${BOLD}${GREEN}Done installing alacritty.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping alacritty installation${RESET}"
fi

# Installing tmux
if confirm "install tmux"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing tmux...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    sudo apt install tmux -y
    echo -e "${BOLD}${GREEN}Done installing tmux.${RESET}"
    echo -e "${BOLD}${GREEN}Visit https://github.com/tmux-plugins/tpm to install tmux plugins.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping tmux installation${RESET}"
fi

# Installing zoxide
if confirm "install zoxide and fzf"; then
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    echo -e "${BOLD}${GREEN}Installing zoxide...${RESET}"
    echo -e "${BOLD}${GREEN}${LINE}${RESET}"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    echo -e "${BOLD}${GREEN}Done installing zoxide.${RESET}"
    sudo apt install fzf
    echo -e "${BOLD}${GREEN}Done installing fzf.${RESET}"
else
    echo -e "${BOLD}${RED}Skipping zoxide installation${RESET}"
fi

echo -e "${BOLD}${GREEN}${LINE}${RESET}"
echo -e "${BOLD}${GREEN}All Done :)${RESET}"
echo -e "${BOLD}${GREEN}Start hacking now!${RESET}"
echo -e "${BOLD}${GREEN}${LINE}${RESET}"
