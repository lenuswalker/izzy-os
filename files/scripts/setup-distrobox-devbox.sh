#!/bin/bash

set -ouex pipefail

# Create devbox
distrobox create --name devbox --image ubuntu:latest --home $HOME/distrobox/home/devbox
distrobox enter devbox

# Update distrobox
sudo apt update && sudo apt upgrade
sudo apt install software-properties-common gnome-keyring nano

# Install fastfetch
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch

# Install nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo tar -C /opt -xzf nvim-linux64.tar.gz
cat >> .bashrc << EOF

# neovim
export PATH="$PATH:/opt/nvim-linux64/bin"
EOF

# Install vscode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install apt-transport-https code
distrobox-export --app code

# Install dotnet
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x ./dotnet-install.sh
./dotnet-install.sh --version latest
cat >> .bashrc << EOF

# .NET export
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
EOF

# Install Starship
curl -sS https://starship.rs/install.sh | sh
cat >> .bashrc << EOF
# Starship
eval "$(starship init bash)"
fastfetch
EOF

exit