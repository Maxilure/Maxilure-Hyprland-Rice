# Maxilure's Hyprland Rice

A personally curated [Hyprland](https://hyprland.org/) dotfiles setup with a clean, functional workflow — themed around [Catppuccin Mocha](https://github.com/catppuccin/catppuccin).

## What's Included

| Component | Role |
|---|---|
| [Kitty](https://sw.kovidgoyal.net/kitty/) | Terminal emulator |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info fetch |
| [Rofi](https://github.com/davatorium/rofi) | App launcher (`rofi -show drun`) |
| [RofiMoji](https://github.com/fdw/rofimoji) | Emoji picker (`SUPER + .`) |
| [AGS](https://github.com/Aylur/ags) | Aylur's GTK Shell (top bar / widgets) |
| [Tint](https://github.com/Maxilure/Maxilure-Hyprland-Rice/tree/main/tint) | Wallpaper randomizer using `awww` |
| [Hypralt](https://github.com/Maxilure/Maxilure-Hyprland-Rice/tree/main/scripts) | `ALT + TAB` window switcher (Python) |

## Keybinds

| Key | Action |
|---|---|
| `SUPER + Return` | Open terminal (Kitty) |
| `SUPER + Space` | Open app launcher (Rofi) |
| `SUPER + .` | Open emoji picker (RofiMoji) |
| `SUPER + W` | Random wallpaper (Tint) |
| `ALT + TAB` | Window switcher (Hypralt) |
| `SUPER + Q` | Kill focused window |
| `SUPER + V` | Toggle window float |
| `SUPER + ALT + F` | Toggle fullscreen |
| `Print` | Screenshot (area → clipboard + Swappy) |
| `SUPER + Escape` | Kill stuck screenshot processes |

See [binds.lua](hypr/binds.lua) for the full list.

## Installation

> **Requires:** Arch Linux or CachyOS

```bash
git clone https://github.com/Maxilure/Maxilure-Hyprland-Rice.git
cd Maxilure-Hyprland-Rice
./install.sh
```

What the script does:
1. Detects your distro (CachyOS / Arch), installs `yay`, removes `paru` if found
2. Installs all required packages (skips already-installed ones)
3. Backs up any existing configs in `~/.config/`
4. Deploys all configs to `~/.config/{kitty,fastfetch,rofi,ags,hypr}`
5. Installs `hypralt` to `~/.local/bin/` and `tint` to `/usr/local/bin/`

After install, log out and back in, or reload Hyprland with `hyprctl reload`.

Before using, add your monitors in `~/.config/hypr/monitors.lua` (it comes with a template).

## Theme

This rice uses **Catppuccin Mocha** — a warm, low-contrast color palette. Check them out at [catppuccin.com](https://catppuccin.com/).

## Credits

- [Hyprland](https://hyprland.org/) — the Wayland compositor
- [Catppuccin](https://github.com/catppuccin/catppuccin) — color palette
- [Aylur's GTK Shell](https://github.com/Aylur/ags) — widget system
- [awww](https://codeberg.org/LGFae/awww) — wallpaper daemon
