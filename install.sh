# Sanity checks
set -e
if [[ $EUID -ne 0 ]]; then
   echo "Error: no root privileges."
   exit 1
fi
USERNAME=$1
if [[ -z "$USERNAME" ]]; then
    echo "Error: No username provided."
    echo "Usage: ./install.sh <username>"
    exit 1
fi

# Basics
pacman -S --noconfirm --needed base-devel git go sudo
if id "$USERNAME" &>/dev/null; then
    usermod -aG wheel "$USERNAME"
else
    echo "Creating user $USERNAME..."
    useradd -m -G wheel -s /bin/bash "$USERNAME"
    # Optional: Set a default password or force password change on login
    # echo "$USERNAME:password" | chpasswd
fi
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
REPO_DIR=$(pwd)

# System configuration
chown -R "$USERNAME:$USERNAME" "$REPO_DIR/bin"
cd "$REPO_DIR/bin"
chmod +x *.sh
./loader-conf.sh
./cpupower-conf.sh
./logind-conf.sh
./vconsole-conf.sh
./environment-conf.sh
./greetd-conf.sh

# User configuration
sudo -u $USERNAME ./bash-conf.sh
sudo -u $USERNAME ./tmux-conf.sh
sudo -u $USERNAME ./kitty-conf.sh
sudo -u $USERNAME ./neovim-conf.sh
sudo -u $USERNAME ./brave-conf.sh
sudo -u $USERNAME ./hyprland-conf.sh
sudo -u $USERNAME ./waybar-conf.sh

# Packages
BUILD_DIR="$REPO_DIR/tmp"
rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"
chown -R "$USERNAME:$USERNAME" "$BUILD_DIR"
sudo -u "$USERNAME" git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u "$USERNAME" makepkg -s --noconfirm
pacman -U --noconfirm *pkg.tar.zst
cd "$REPO_DIR"
rm -rf "$BUILD_DIR"
./bin/packages.sh
echo "Configuration complete."
