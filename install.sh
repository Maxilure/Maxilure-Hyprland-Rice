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

# ---- 9. Download wallpapers ----
WALLPAPER_REPO="https://github.com/orangci/walls-catppuccin-mocha.git"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
BLACKLIST=(
    astronaut.png     beach-path.jpg
    beach.jpg
    berries-1.jpg biking-sunset.jpg
    black-hole.png blueberries.jpg blue-kaiju.png blueprint.png
    bsod.png car-1.png cat-in-clouds.png cat-street.jpg
    cat-vibin.png city-harbor.png     city-horizon.jpg
    city-on-water.jpg
    city.png
    cloud-coffee.jpg coffee-shop.png compass.jpg danbo.jpg
    dark-star.jpg degirled.png desolate-city-2.jpg desolate-city.jpg
    dino.jpg dominik-mayer-10.jpg dominik-mayer-11.jpg dominik-mayer-12.jpg
    dominik-mayer-13.jpg dominik-mayer-14.jpg dominik-mayer-15.jpg dominik-mayer-16.jpg
    dominik-mayer-17.jpg dominik-mayer-18.png dominik-mayer-19.jpg dominik-mayer-1.jpg
    dominik-mayer-20.jpg dominik-mayer-21.jpg dominik-mayer-22.jpg dominik-mayer-23.jpg
    dominik-mayer-24.jpg dominik-mayer-25.jpg dominik-mayer-26.jpg dominik-mayer-2.jpg
    dominik-mayer-4.jpg dominik-mayer-5.jpg dominik-mayer-6.jpg dominik-mayer-7.jpg
    dominik-mayer-8.jpg dominik-mayer-9.jpg dragon.jpg droplets.png
    dwarf-saber.jpg fantasy-city.jpg fight.jpg flower-branch.png
    flower-field-2.png flower-field-3.png flower-field.jpg flowering-rain.png
    flowers-14.jpg flowers-16.jpg flowers-17.png flowers-18.jpg
    flowers-19.jpg flowers-20.jpg flowers-8.jpg flying-boat.jpg
    fox.png fumo-fumo.jpg genshin-landscape.png gentlemen-sunset.png
    gingerbread-house.jpg girl-stars.png grassy-well.jpg green-bridge.jpg
    greenbus.jpg harbor-3.png harbor.jpg hollow.jpg
    hollow-knight.jpg hollow-knight.png ice-cream.jpg idk-tbh.png
    i-touch-this.jpg jellyfish.jpg jupiter.png kaiju.png
    keyboard-2.png keyboard.png kfc.jpg kitchen.png
    kitty.jpg kiwis.jpg knight-building.png knight-sit.png
    knights-radiant.jpg knight-templar.jpg koishi.jpg kusuriya.png
    lantern-light-room.png laundry.jpg lightbulbs.jpg lighthouse-2.png
    linux-communism.jpg lovely-summer.jpg mage.jpg maji-no-tabitabi-2.jpg
    majo-no-tabitabi.jpg map.png math.png minimalist-black-hole.png
    mushishi.jpg my-neighbor-totoro-sunflowers.png old-computer.png one-legged-herdazian.jpg
    orange.jpg oranges.jpg oversized-cat.jpg painting.jpg
    painting-standing.jpg pink-clouds.jpg pistachio-tea.jpg     pitstop.png
    pixel-castle.png
    pixel-earth.png pixel-galaxy.png     pixel-napping.png
    pixel-planet.png pixel-prairie.jpg
    pixel-reading.png     pizza.jpg
    plane-purple.png
    platform.jpg
    pompeii.png
    purple-horizon.jpg     railroad-cat.png
    river-city.jpg
    road.jpg rocket-schematics.jpg
    sakura-aura.jpg sakura-trees-over-river.jpg salty-suburban.jpg samurai.jpg
        satellite.png
    scifi.jpg
    shadow-shape-holo.jpeg shrimp-fried-rice.jpg soaring-off.jpg
    space.jpg space-piano.png space.png stay-vigil-by-pndora.jpg
        stormlight-archive.png
    street-4.png
    subway.jpg
    sunlit-ruins.png sushi.jpg
    swirls.jpg sword.jpg tank.jpg toast.png
    tora.jpg touhou-house.jpg touhou-lake.jpg tux-socialism.jpg
    underwater-deep.jpg van-chilling.png vibrant-gate.png voyager-10.jpg
        voyager-11.jpg
    voyager-15.jpg
    voyager-16.jpg voyager-17.jpg voyager-18.jpg
    voyager-1.jpg     voyager-21.jpg
    voyager-22.jpg
    voyager-5.jpg voyager-7.jpg
    voyager-8.jpg wallhaven-vqoo1p.jpg wall.jpg wanderer.jpg
    waterfall.png yohoho.jpg zuchold-archtecture.jpg
)

if [[ -d "$WALLPAPER_DIR" ]]; then
    info "Wallpapers already exist at $WALLPAPER_DIR, skipping download..."
    info "  Delete the folder and re-run if you want to redownload."
else
    info "Downloading Catppuccin Mocha wallpapers..."
    git clone --depth 1 "$WALLPAPER_REPO" /tmp/walls-catppuccin-mocha
    mkdir -p "$WALLPAPER_DIR"
    mv /tmp/walls-catppuccin-mocha/*.{jpg,jpeg,png} "$WALLPAPER_DIR/" 2>/dev/null
    rm -rf /tmp/walls-catppuccin-mocha

    info "  Removing blacklisted wallpapers..."
    for file in "${BLACKLIST[@]}"; do
        rm -f "$WALLPAPER_DIR/$file"
    done

    count=$(ls -1 "$WALLPAPER_DIR" 2>/dev/null | wc -l)
    info "  $count wallpapers downloaded to $WALLPAPER_DIR"
    info "  Run 'tint random' to apply one!"
fi

# ---- 10. Set up GTK4 theme symlinks ----
info "Setting up GTK4 theme symlinks..."
rm -rf "$HOME/.config/gtk-4.0/assets" "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
ln -sf /usr/share/themes/catppuccin-mocha-pink-standard+default/gtk-4.0/assets "$HOME/.config/gtk-4.0/assets"
ln -sf /usr/share/themes/catppuccin-mocha-pink-standard+default/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css"
ln -sf /usr/share/themes/catppuccin-mocha-pink-standard+default/gtk-4.0/gtk-dark.css "$HOME/.config/gtk-4.0/gtk-dark.css"
info "  GTK4 symlinks set to catppuccin-mocha-pink"

# ---- 11. Done ----
echo
info "Installation complete!"
info "Log out and back in, or restart Hyprland to apply."
info "If already in Hyprland, run: hyprctl reload"
