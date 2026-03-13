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
- **Multiplexer**: tmux + tmux-sessionizer
- **Editor**: Neovim
- **Widgets**: AGS (calendar)
- **Bluetooth**: bluetui
- **Network Management**: nmtui

## Structure

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package. The internal path mirrors where the files land in `$HOME`, so stow can manage everything from a single target.

```
dotfiles/
├── ags/                      # AGS widgets (calendar)
│   └── .config/ags/
├── applications/             # Custom .desktop files for TUI apps (bluetui, tmux, yazi)
│   └── .local/share/applications/
├── bin/                      # Scripts: wallpaper, wallpicker, tmux-sessionizer
│   └── .local/bin/
├── fish/                     # Fish shell config
│   └── .config/fish/
├── ghostty/                  # Ghostty terminal config
│   └── .config/ghostty/
├── hypr/                     # Hyprland, hypridle, hyprlock, hyprpaper
│   └── .config/hypr/
├── matugen/                  # Matugen config and color templates
│   └── .config/matugen/
│       └── templates/        # Templates for ags, fish, ghostty, hyprland, waybar, rofi, wofi, wlogout, yazi
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
├── yazi/                     # Yazi file manager config
│   └── .config/yazi/
├── wallpapers/               # Wallpaper images — seeded to ~/photos/wallpapers/ on install
├── install.sh                # Install script entrypoint
├── modules/                  # Install script phases (bootstrap, packages, stow, etc.)
├── lib/                      # Shared helpers and gum styling
├── packages/                 # Package lists (must-install, core, additional)
├── applications.md           # Notes on fixing app launcher issues
└── packages.txt              # Full package list (generated with pacman -Qe)
```

## Fresh Install

The install script runs in two phases — a silent TTY bootstrap first, then the full interactive install from within a Hyprland session.

**Step 1 — TTY bootstrap**

Do a minimal base install of EndeavourOS, reboot into TTY, and log in. EndeavourOS does not include `git` by default, so install it first:

```bash
sudo pacman -S --noconfirm git
git clone https://github.com/irispsyence/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script detects it's running in a TTY (no display server) and silently installs the minimum needed to get a graphical session: `git`, `gum`, `stow`, `yay`, `kitty`, and `hyprland`. It then exits with instructions.

**Step 2 — Full install**

Start Hyprland from the TTY:

```bash
Hyprland
```

Open a kitty terminal (`Super + Return` or run `kitty` from a Hyprland keybind), then re-run the install script:

```bash
cd ~/dotfiles && ./install.sh
```

The script now has a proper terminal and runs the full interactive gum UI:
- Presents a menu to choose install tier and select packages
- Stows all configs, replaces hardcoded paths with your username, enables services
- Runs matugen with the default wallpaper so everything is themed on first boot
- Enables SDDM — reboot when done to land in the login screen

**Install tiers:**
- `⚡ Opinionated` — full personal setup, no prompts
- `🔧 Custom` — step-by-step interactive walkthrough
- `📦 Minimal` — Hyprland + UI + fonts only
- `👁 Dry Run` — preview all actions without installing anything

## Manual Setup

If you prefer to set things up by hand:

1. Install packages from `packages.txt`:
   ```bash
   sudo pacman -S --needed - < packages.txt
   ```

2. Stow all packages:
   ```bash
   stow ags fish ghostty hypr matugen nvim rofi swaync tmux waybar wlogout wofi yazi bin applications
   ```
   Make the scripts executable:
   ```bash
   chmod +x ~/.local/bin/wallpaper ~/.local/bin/wallpicker ~/.local/bin/wallpaper-boot ~/.local/bin/tmux-sessionizer
   ```

3. Set up files that require local path customization (replace `/home/yourusername` with your actual path):
   ```bash
   cp hypr/.config/hypr/hyprpaper.conf.example ~/.config/hypr/hyprpaper.conf
   cp rofi/.config/rofi/launcher.rasi.example ~/.config/rofi/launcher.rasi
   cp wlogout/.config/wlogout/style.css.example ~/.config/wlogout/style.css
   ```
   Then edit each file and replace `/home/yourusername` with your actual home path.

4. Run matugen with your wallpaper of choice to generate all color configs:
   ```bash
   matugen image ~/photos/wallpapers/your-wallpaper.jpg --mode dark -t scheme-tonal-spot
   ```
   This generates colors for ags, fish, ghostty, hyprland, hyprlock, waybar, rofi, wofi, wlogout, and yazi.

> **Note:** Stow will refuse to create a symlink if a real file already exists at the target path.
> Remove existing config directories before stowing, or use `stow --adopt` to pull existing files
> into the repo first (then review with `git diff` before committing).

## Migrating on an existing machine

If you previously used `cp` to install these configs, remove the real files first so stow can replace them with symlinks:

```bash
rm -rf ~/.config/ags ~/.config/fish ~/.config/ghostty ~/.config/hypr ~/.config/matugen \
       ~/.config/nvim ~/.config/rofi ~/.config/swaync ~/.config/tmux \
       ~/.config/waybar ~/.config/wlogout ~/.config/wofi ~/.config/yazi
rm -f ~/.local/bin/wallpaper ~/.local/bin/wallpicker ~/.local/bin/wallpaper-boot ~/.local/bin/tmux-sessionizer
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
| `wlogout/.config/wlogout/style.css` | Generated by matugen |
| `fish/.config/fish/fish_variables` | Contains local shell variables |
| `fish/.config/fish/fish_history` | Shell history |
| `ags/.config/ags/node_modules/` | AGS npm dependencies — install with `npm install` inside `~/.config/ags/` |

## Screenshots

> TODO: Add screenshots of the desktop, waybar, rofi launcher, and wlogout screen.
