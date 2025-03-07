WORK=$PWD
echo "remove old versions of nvim"
sudo apt-get remove -y --purge neovim
sudo apt-get remove -y --purge neovim-qt
sudo apt-get remove -y --purge python3-neovim
sudo apt-get remove -y --purge python-neovim

echo "Install neovim >= 0.9.0"
wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
mkdir -p ~/.local/bin
mv nvim-linux64.tar.gz ~/.local/bin
cd ~/.local/bin
tar -xzvf nvim-linux64.tar.gz
rm -fr nvim-linux64.tar.gz
ln -s ./nvim-linux64/bin/nvim ./nvim
echo "Done installing neovim."
nvim --version

echo "getting jetbrains mono nerd font..."
cd $WORK
sudo apt install unzip
bash getNerdFont.sh

echo "Setting up symlinks..."
ln -s ~/.dotfiles/.bashrc ~/.bashrc
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/.git-credentials ~/.git-credentials
ln -s ~/.dotfiles/alacritty/ ~/.config/alacritty
ln -s ~/.dotfiles/nvim/ ~/.config/nvim
ln -s ~/.dotfiles/tmux/ ~/.config/tmux
ln -s ~/.dotfiles/kitty/ ~/.config/kitty
ln -s ~/.dotfiles/.ssh/ ~/.ssh
echo "Done creating symlinks."

echo "Installing alacritty..."
sudo apt update && sudo apt upgrade
sudo add-apt-repository ppa:aslatter/ppa -y
sudo apt install alacritty -y
echo "Done installing alacritty."

echo "Installing tmux..."
sudo apt install tmux -y
echo "Done installing tmux."

echo "All Done :)"
echo "Start hacking now!"
