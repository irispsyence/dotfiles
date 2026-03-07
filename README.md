# dotfiles

My personal configuration files for Arch Linux (EndeavourOS) with Hyprland.

## System

- **OS**: EndeavourOS (Arch Linux)
- **WM**: Hyprland
- **Terminal**: Ghostty
- **Shell**: Fish
- **Bar**: Waybar
- **Launcher**: Rofi (primary, hotkeybound) / Wofi (also configured)
- **Notifications**: Swaync
- **File Manager**: Dolphin / Yazi
- **Browser**: Brave
- **Theming**: Matugen (dynamic colors from wallpaper)
- **Multiplexer**: tmux
- **Editor**: Neovim
- **Bluetooth**: bluetui
- **Network Management**: nmtui

## Structure

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package. The internal path mirrors where the files land in `$HOME`, so stow can manage everything from a single target.

```
dotfiles/
├── applications/             # Custom .desktop files for TUI apps (bluetui, tmux, yazi)
│   └── .local/share/applications/
├── bin/                      # Wallpaper scripts (wallpaper + wallpicker)
│   └── .local/bin/
├── fish/                     # Fish shell config
│   └── .config/fish/
├── ghostty/                  # Ghostty terminal config
│   └── .config/ghostty/
├── hypr/                     # Hyprland, hypridle, hyprlock, hyprpaper
│   └── .config/hypr/
├── matugen/                  # Matugen config and color templates
│   └── .config/matugen/
│       └── templates/        # Templates for fish, ghostty, hyprland, waybar, rofi, wofi, wlogout
├── nvim/                     # Neovim config (uses sorbet colorscheme — opinionated)
│   └── .config/nvim/
├── rofi/                     # App launcher
│   └── .config/rofi/
├── swaync/                   # Notification center
│   └── .config/swaync/
├── tmux/                     # tmux config
│   └── .config/tmux/
├── waybar/                   # Status bar
│   └── .config/waybar/
├── wlogout/                  # Logout menu
│   └── .config/wlogout/
├── wofi/                     # Secondary launcher (matugen-integrated)
│   └── .config/wofi/
├── wallpapers/               # Wallpaper images — must live here for wallpicker to work
├── applications.md           # Notes on fixing app launcher issues
└── packages.txt              # Full package list (generated with pacman -Qe)
```

## Setup (new machine)

1. Install packages from `packages.txt`:
   ```bash
   sudo pacman -S --needed - < packages.txt
   ```

2. Clone the repo to your home directory:
   ```bash
   git clone <repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

3. Set up files that require local path customization (replace `/home/yourusername` with your actual path):
   ```bash
   cp hypr/.config/hypr/hyprpaper.conf.example ~/.config/hypr/hyprpaper.conf
   cp rofi/.config/rofi/launcher.rasi.example ~/.config/rofi/launcher.rasi
   cp wlogout/.config/wlogout/style.css.example ~/.config/wlogout/style.css
   ```
   Then edit each file and replace `/home/yourusername` with your actual home path.

4. Stow all packages:
   ```bash
   stow fish ghostty hypr matugen nvim rofi swaync tmux waybar wlogout wofi bin applications
   ```
   Make the scripts executable:
   ```bash
   chmod +x ~/.local/bin/wallpaper ~/.local/bin/wallpicker
   ```

5. Run matugen with your wallpaper of choice to generate all color configs:
   ```bash
   matugen image ~/dotfiles/wallpapers/your-wallpaper.jpg --mode dark -t scheme-tonal-spot
   ```
   This generates colors for fish, ghostty, hyprland, hyprlock, waybar, rofi, wofi, and wlogout.

> **Note:** Stow will refuse to create a symlink if a real file already exists at the target path.
> Remove existing config directories before stowing, or use `stow --adopt` to pull existing files
> into the repo first (then review with `git diff` before committing).

## Migrating on an existing machine

If you previously used `cp` to install these configs, remove the real files first so stow can replace them with symlinks:

```bash
rm -rf ~/.config/fish ~/.config/ghostty ~/.config/hypr ~/.config/matugen \
       ~/.config/nvim ~/.config/rofi ~/.config/swaync ~/.config/tmux \
       ~/.config/waybar ~/.config/wlogout ~/.config/wofi
rm -f ~/.local/bin/wallpaper ~/.local/bin/wallpicker
```

Then run the stow command from step 4 above.

## Adding a new package

1. Create the package directory with the full path structure mirroring `$HOME`:
   ```
   dotfiles/newpackage/.config/newpackage/config-file
   ```
2. Run `stow newpackage` from `~/dotfiles`.

## Wallpaper Switching

`Super + W` opens a Yazi file picker pointed at `~/dotfiles/wallpapers/`. Selecting an image switches the wallpaper and regenerates the color theme across all apps via matugen. Wallpaper images must be kept in the `wallpapers/` directory for the script to work.

## GTK Dark Mode

GTK apps (e.g. pavucontrol) are set to dark mode via gsettings:
```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
```

## Gitignored Files

These files exist locally but are not tracked — use the `.example` versions as a starting point:

| File | Reason |
|------|--------|
| `hypr/.config/hypr/hyprpaper.conf` | Contains local wallpaper path |
| `hypr/.config/hypr/hyprlock.conf` | Generated by matugen |
| `rofi/.config/rofi/launcher.rasi` | Contains local path customization |
| `matugen/.config/matugen/templates/wlogout-colors.css` | Contains local wallpaper path |
| `wlogout/.config/wlogout/style.css` | Contains local wallpaper path |
| `fish/.config/fish/fish_variables` | Contains local shell variables |
| `fish/.config/fish/fish_history` | Shell history |

## Screenshots

> TODO: Add screenshots of the desktop, waybar, rofi launcher, and wlogout screen.
