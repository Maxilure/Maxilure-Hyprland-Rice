#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] && err "Do not run this script as root."

packages_installed=0
packages_skipped=0

pacman_install() {
    local pkg=$1
    if pacman -Q "$pkg" &>/dev/null; then
        echo "  ✓ $pkg already installed"
        ((packages_skipped++))
    else
        echo "  → Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
        ((packages_installed++))
    fi
}

aur_install() {
    local pkg=$1
    if pacman -Q "$pkg" &>/dev/null; then
        echo "  ✓ $pkg already installed"
        ((packages_skipped++))
    else
        echo "  → Installing $pkg (AUR)..."
        yay -S --noconfirm "$pkg"
        ((packages_installed++))
    fi
}

# ---- 1. System detection ----
DISTRO=""
if grep -qi "cachyos" /etc/os-release 2>/dev/null; then
    DISTRO="CachyOS"
else
    DISTRO="Arch"
fi
info "Detected: $DISTRO"

# ---- 2. Remove paru if present ----
if pacman -Q paru &>/dev/null; then
    info "Removing paru..."
    sudo pacman -Rns --noconfirm paru
fi

# ---- 3. Install yay ----
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    if [[ "$DISTRO" == "CachyOS" ]]; then
        sudo pacman -S --noconfirm yay
    else
        sudo pacman -S --noconfirm --needed base-devel git
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        (cd /tmp/yay-bin && makepkg -si --noconfirm)
        rm -rf /tmp/yay-bin
    fi
fi

# ---- 4. Install packages ----
info "Installing packages..."
echo "  [official repos]"

pacman_install kitty
pacman_install fastfetch
pacman_install ttf-jetbrains-mono-nerd
pacman_install adwaita-fonts
pacman_install rofimoji
pacman_install wtype
pacman_install python
pacman_install dolphin
pacman_install brightnessctl
pacman_install playerctl
pacman_install wireplumber
pacman_install swappy
pacman_install slurp
pacman_install hyprpicker
pacman_install grim
pacman_install jq
pacman_install dart-sass
pacman_install gtk3
pacman_install gtk-layer-shell
pacman_install gobject-introspection
pacman_install gjs
pacman_install npm

if [[ "$DISTRO" == "CachyOS" ]]; then
    pacman_install rofi
    pacman_install awww
    pacman_install grimblast-git
    pacman_install hyprpolkitagent
else
    pacman_install hyprpolkitagent
    echo "  [AUR packages]"
    aur_install rofi-wayland
    aur_install awww
    aur_install grimblast-git
fi

echo "  [AUR packages]"
aur_install aylurs-gtk-shell-git
aur_install catppuccin-gtk-theme-mocha
aur_install kvantum-theme-catppuccin-git
aur_install ttf-geist
aur_install catppuccin-cursors-mocha
aur_install catppuccin-sddm-theme-mocha

# ---- 5. Backup existing configs ----
info "Backing up existing configs..."
TIMESTAMP=$(date +%s)
for dir in kitty fastfetch rofi ags hypr; do
    if [[ -d "$HOME/.config/$dir" ]]; then
        mv "$HOME/.config/$dir" "$HOME/.config/$dir.bak-$TIMESTAMP"
        info "  ~/.config/$dir → ~/.config/$dir.bak-$TIMESTAMP"
    fi
done

# ---- 6. Copy configs ----
info "Copying configs..."
cp -r "$SCRIPT_DIR/kitty"     "$HOME/.config/kitty"
cp -r "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
cp -r "$SCRIPT_DIR/rofi"      "$HOME/.config/rofi"
cp -r "$SCRIPT_DIR/ags"       "$HOME/.config/ags"
cp -r "$SCRIPT_DIR/hypr"      "$HOME/.config/hypr"
info "  Configs deployed to ~/.config/{kitty,fastfetch,rofi,ags,hypr}"

# ---- 7. Install scripts ----
info "Installing scripts..."
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/scripts/hypralt" "$HOME/.local/bin/hypralt"
chmod +x "$HOME/.local/bin/hypralt"
info "  hypralt → ~/.local/bin/hypralt"

# ---- 8. Install tint ----
info "Installing tint..."
sudo make -C "$SCRIPT_DIR/tint" install
info "  tint → /usr/local/bin/tint"

# ---- 9. Copy wallpapers ----
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
if [[ -d "$WALLPAPER_DIR" ]]; then
    info "Wallpapers already exist at $WALLPAPER_DIR, skipping..."
else
    info "Copying wallpapers..."
    mkdir -p "$WALLPAPER_DIR"
    cp "$SCRIPT_DIR/wallpapers/"* "$WALLPAPER_DIR/"
    count=$(ls -1 "$WALLPAPER_DIR" 2>/dev/null | wc -l)
    info "  $count wallpapers copied to $WALLPAPER_DIR"
    info "  Run 'tint random' to apply one!"
fi

# ---- 10. Configure GTK themes ----
THEME="catppuccin-mocha-pink-standard+default"

info "Writing GTK3 settings..."
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
info "  ~/.config/gtk-3.0/settings.ini"

info "Writing GTK4 settings..."
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
info "  ~/.config/gtk-4.0/settings.ini"

info "Setting up GTK4 theme symlinks..."
rm -rf "$HOME/.config/gtk-4.0/assets" "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
ln -sf "/usr/share/themes/$THEME/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
ln -sf "/usr/share/themes/$THEME/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
ln -sf "/usr/share/themes/$THEME/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
info "  GTK4 symlinks set to $THEME"

info "Applying gsettings..."
gsettings set org.gnome.desktop.interface gtk-theme "$THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-dark-cursors" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
info "  gsettings updated"

# ---- 11. Configure SDDM theme ----
info "Setting up SDDM theme..."
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=catppuccin-mocha-pink
EOF
info "  SDDM theme set to catppuccin-mocha-pink"

# ---- 12. Done ----
echo
info "Installation complete!"
info "Log out and back in, or restart Hyprland to apply."
info "If already in Hyprland, run: hyprctl reload"
echo ""
info "=== Post-install: Configure Kvantum for Qt apps (Dolphin, etc.) ==="
info "  1. Run: kvantummanager"
info "  2. Select 'Catppuccin-Mocha-Pink' → Apply"
