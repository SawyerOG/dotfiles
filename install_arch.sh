#!/usr/bin/env bash
# Arch Linux setup script with Chaotic-AUR, Git config, and SSH keygen

set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Ensure required commands exist
#for cmd in sudo pacman git ssh-keygen; do
#  command -v $cmd >/dev/null 2>&1 || { echo "Missing required command: $cmd"; exit 1; }
#done

# Prompt for Git configuration
read -rp "Enter your Git username: " GIT_USERNAME
read -rp "Enter your Git email: " GIT_EMAIL

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

echo "==> Installing packages..."
sudo pacman -S --needed --noconfirm \
  git fish ghostty stow hyprland hyprlock hypridle hyprsunset hypershot swaync neovim openssh \
  ttf-jetbrains-mono wireplumber wiremix lazygit lazydocker go fastfetch wl-clipboard \
  waybar emptty unzip fd ripgrep networkmanager networkmanager-openconnect openconnect \
  network-manager-applet libreoffice-fresh noto-fonts noto-fonts-emoji ttf-dejavu ttf-liberation \
  grim slurp yazi brave

# virtual machine
# sudo pacman -S qemu-full virt-manager libvirt dnsmasq bridge-utils \
 #            edk2-ovmf vde2 openbsd-netcat

# also need noto fonts

echo "==> Configuring Git..."
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

for cmd in sudo ssh-keygen; do
  command -v $cmd >/dev/null 2>&1 || { echo "Missing required command: $cmd"; exit 1; }
done

echo "==> Generating SSH key for $GIT_EMAIL..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519 -N "" <<<y >/dev/null 2>&1
fi

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo
echo "======================================================"
echo " Success..."
echo "======================================================"
