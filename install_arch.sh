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
  git ghostty stow hyprland hyprlock hypridle swaync neovim openssh \
  ttf-jetbrains-mono wireplumber wiremix lazygit lazydocker go fastfetch wl-clipboard \
  waybar emptty unzip fd

echo "==> Setting up Chaotic-AUR..."
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U --noconfirm \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Add Chaotic-AUR repo if not already present
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
  echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
fi

echo "==> Syncing and updating..."
sudo pacman -Syu --noconfirm

echo "==> Installing Brave..."
if ! pacman -Qi brave-bin &>/dev/null; then
  sudo pacman -S --noconfirm chaotic-aur/brave-bin
fi

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

# Copy SSH key to clipboard
wl-copy < ~/.ssh/id_ed25519.pub
echo "SSH public key generated and copied to clipboard!"

echo
echo "======================================================"
echo " Success..."
echo "======================================================"
