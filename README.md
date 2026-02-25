# dotfiles

My personal configuration files for Arch Linux (EndeavourOS) with Hyprland.

## System

- **OS**: EndeavourOS (Arch Linux)
- **WM**: Hyprland
- **Terminal**: Ghostty
- **Shell**: Fish
- **Bar**: Waybar
- **Launcher**: Hyprlauncher
- **Notifications**: Swaync
- **File Manager**: Dolphin / Yazi
- **Browser**: Brave
- **Theming**: Matugen (dynamic colors from wallpaper)
- **Bluetooth**: bluetui
- **Network Management**: nmtui

## Structure

```
dotfiles/
├── bin/                      # Wallpaper switcher scripts
├── fish/                     # Fish shell config
├── ghostty/                  # Ghostty terminal config
├── hypr/                     # Hyprland, hyprlock, hypridle
│   └── hyprpaper.conf.example   # Copy and update with your wallpaper path
├── matugen/                  # Matugen config and templates
│   └── templates/
│       └── wlogout-colors.css.example  # Copy and update with your wallpaper path
├── swaync/                   # Notification center
├── waybar/                   # Status bar
├── wlogout/
│   ├── layout                # Logout menu layout
│   └── style.css.example     # Copy and update with your wallpaper path
├── wofi/                     # App launcher config
└── packages.txt              # Full package list
```

## Setup

1. Install packages from `packages.txt`:
   ```bash
   sudo pacman -S --needed - < packages.txt
   ```

2. Copy configs to their locations:
   ```bash
   cp -r fish/* ~/.config/fish/
   cp -r ghostty/* ~/.config/ghostty/
   cp -r hypr/* ~/.config/hypr/
   cp -r matugen/* ~/.config/matugen/
   cp -r swaync/* ~/.config/swaync/
   cp -r waybar/* ~/.config/waybar/
   cp wlogout/layout ~/.config/wlogout/
   cp -r wofi/* ~/.config/wofi/
   cp bin/* ~/.local/bin/
   chmod +x ~/.local/bin/wallpaper ~/.local/bin/wallpicker
   ```

3. Set up files that require local path customization (replace `/home/yourusername` with your actual path):
   ```bash
   cp hypr/hyprpaper.conf.example ~/.config/hypr/hyprpaper.conf
   cp hypr/hyprlock.conf.example ~/.config/hypr/hyprlock.conf
   cp matugen/templates/wlogout-colors.css.example ~/.config/matugen/templates/wlogout-colors.css
   cp wlogout/style.css.example ~/.config/wlogout/style.css
   ```
   Then edit each file and replace `/home/yourusername` with your actual home path.

4. Run matugen with your wallpaper of choice to generate all color configs:
   ```bash
   matugen image /path/to/wallpaper.jpg --mode dark -t scheme-tonal-spot
   ```

## Wallpaper Switching

Super + W opens a yazi file picker pointed at `~/photos/wallpapers/`. Selecting an image switches the wallpaper and regenerates the color theme across all apps via matugen.

## Gitignored Files

These files exist locally but are not tracked — use the `.example` versions as a starting point:

| File | Reason |
|------|--------|
| `hypr/hyprpaper.conf` | Contains local wallpaper path |
| `matugen/templates/wlogout-colors.css` | Contains local wallpaper path |
| `wlogout/style.css` | Contains local wallpaper path |
| `fish/fish_variables` | Contains local shell variables |
| `fish/fish_history` | Shell history |

- pavucontrol to dark mode:
    - gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    - gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
