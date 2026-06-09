# Maxilure's Hyprland Rice

A personal Hyprland dotfiles and configs setup, themed around [Catppuccin Mocha](https://github.com/catppuccin/catppuccin).

## Components

| Component | Description |
|---|---|
| **Hyprland** | Window manager — modular Lua config (hyprland.lua + sourced sub-files) |
| **Kitty** | Terminal emulator — Catppuccin Mocha colors, JetBrainsMono Nerd Font |
| **AGS** | Aylur's GTK Shell — custom bar/widget system (TypeScript + SCSS) |
| **Rofi** | App launcher — Catppuccin-themed `drun` menu |
| **RofiMoji** | Emoji picker — custom `emoji-picker.sh` wrapper, bound to `SUPER + .` |
| **Fastfetch** | System info — custom logo + Catppuccin-accented output |
| **Tint** | Wallpaper randomizer — picks random wallpapers with `awww` transitions |
| **hypralt** | Alt-Tab window switcher — custom Python script |

### Keybinds

| Shortcut | Action |
|---|---|
| `SUPER + Return` | Open Kitty |
| `SUPER + Space` | Open Rofi (app launcher) |
| `SUPER + .` | Open RofiMoji emoji picker |
| `SUPER + W` | Random wallpaper via Tint |
| `ALT + Tab` | Window switcher (hypralt) |
| `SUPER + Q` | Close focused window |
| `SUPER + V` | Toggle float |
| `Print` | Screenshot (grimblast + swappy) |
| `SUPER + Escape` | Kill stuck screenshot processes |

## Installation

```bash
git clone https://github.com/Maxilure/Maxilure-Hyprland-Rice.git
cd Maxilure-Hyprland-Rice
./install.sh
```

The script will:

1. Detect your distro (CachyOS or Arch Linux)
2. Install yay (AUR helper), remove paru if present
3. Install all required packages (skips already-installed ones)
4. Back up your existing configs to `.bak-<timestamp>`
5. Deploy all configs to `~/.config/`
6. Install `hypralt` to `~/.local/bin/`
7. Install `tint` to `/usr/local/bin/`

### Prerequisites

- **Arch Linux** or **CachyOS**
- An existing Hyprland installation recommended (script handles dependencies)

### Post-install

- Log out and back in, or restart Hyprland
- If already in Hyprland: `hyprctl reload`
- Run `tint set-folder /path/to/wallpapers` to configure Tint
- Edit `~/.config/hypr/monitors.lua` with your display setup

## Manual config locations

```
~/.config/kitty/
~/.config/fastfetch/
~/.config/rofi/
~/.config/ags/
~/.config/hypr/
~/.local/bin/hypralt
/usr/local/bin/tint
```

## Credits

- [Catppuccin](https://github.com/catppuccin/catppuccin) — color scheme
- [Hyprland](https://hyprland.org/) — Wayland compositor
- [Aylur's GTK Shell](https://github.com/Aylur/ags) — widget system
- [Rofi](https://github.com/davatorium/rofi) — app launcher
- [RofiMoji](https://github.com/fdw/rofimoji) — emoji picker
