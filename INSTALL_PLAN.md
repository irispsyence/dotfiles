# Dotfiles Install Script — Plan & Handoff

## Purpose of This Document
This is a handoff document for building a modular, interactive dotfiles install script.
Read this fully before touching any files. Then read the actual dotfiles structure and
reconcile any discrepancies between this plan and reality before writing code.

---

## System Context
- **OS**: EndeavourOS (Arch-based)
- **Compositor**: Hyprland (Wayland only)
- **AUR helper**: paru (not yay)
- **Shell**: fish
- **Terminal**: ghostty (primary), kitty (must-install fallback)
- **Dotfile manager**: GNU stow
- **Repos**: GitHub (public, default) + Forgejo (private, Tailscale-only)
- **Username** (current machine): iris — but all paths must be dynamic via `$USER`

---

## Repository Structure (target)

```
dotfiles/
├── INSTALL_PLAN.md         ← this file
├── install.sh              ← entrypoint
├── modules/
│   ├── bootstrap.sh        ← phase 0 logic
│   ├── packages.sh         ← package installation logic
│   ├── stow.sh             ← conflict detection + stowing
│   ├── services.sh         ← systemd service enablement
│   ├── shell.sh            ← chsh + shell config
│   └── paths.sh            ← hardcoded path replacement
├── lib/
│   ├── helpers.sh          ← shared functions: is_installed(), pkg_install(), log()
│   └── gum-styles.sh       ← shared gum styling variables
├── packages/
│   ├── must-install.txt    ← always installed, no menus, hard stop on failure
│   ├── core.txt            ← tagged packages driving Step 2 menus
│   └── additional.txt      ← tagged packages driving Step 3 menus
├── assets/
│   └── wallpapers/
│       └── default.jpg     ← seeded on fresh install to ~/photos/wallpapers/
└── [stow packages]/
    ← reconcile actual stow dirs from real dotfiles before coding
```

---

## Package Files Format

### must-install.txt
Flat list, no tags. Every package here installs regardless of tier. Hard stop if any fail.
Fonts are NOT listed here — they are pulled from `[font]` tagged entries in core.txt at runtime.

```
pipewire-alsa
pipewire-jack
pipewire-pulse
wireplumber
alsa-firmware
alsa-plugins
alsa-utils
gst-plugin-pipewire
gst-libav
gst-plugins-bad
gst-plugins-ugly
sddm
base-devel
linux-headers
xdg-desktop-portal
xdg-desktop-portal-hyprland
xdg-user-dirs
hyprland
hyprpolkitagent
hyprcursor
kitty
gtk3
qt5-wayland
qt6-wayland
bluez
bluez-utils
networkmanager
openssh
```

### core.txt
Tagged format: `[tag]    packagename`
Fonts auto-appended to must-install at runtime. Everything else shown in Step 2 menus.

```
[hypr]    hyprlock
[hypr]    hypridle
[hypr]    hyprpaper
[hypr]    hyprpicker
[hypr]    hyprsunset
[hypr]    hyprshot
[ui]      waybar
[ui]      rofi
[ui]      wlogout
[ui]      swaync
[ui]      wofi
[ui]      grim
[ui]      slurp
[ui]      cliphist
[ui]      brightnessctl
[ui]      pavucontrol
[ui]      imv
[ui]      dolphin
[font]    ttf-jetbrains-mono-nerd
[font]    ttf-nerd-fonts-symbols
[font]    noto-fonts
[font]    noto-fonts-cjk
[font]    noto-fonts-emoji
[font]    noto-fonts-extra
[font]    ttf-bitstream-vera
[font]    ttf-dejavu
[font]    ttf-liberation
[font]    ttf-opensans
[font]    cantarell-fonts
[font]    woff2-font-awesome
[shell]   fish
[shell]   tmux
[shell]   fastfetch
[tools]   bat
[tools]   btop
[tools]   lsd
[tools]   duf
[tools]   glances
[tools]   tldr
[tools]   yazi
[tools]   git
[tools]   wget
[tools]   rsync
[tools]   unzip
[tools]   unrar
[tools]   stow
[tools]   matugen
[tools]   downgrade
[tools]   power-profiles-daemon
```

### additional.txt
Tagged format. None pre-checked — these are explicit opt-in.

```
[hypr]     hyprlauncher
[dev]      neovim
[dev]      go
[dev]      python
[dev]      nano-syntax-highlighting
[browser]  brave-bin
[browser]  firefox
[comms]    discord
[media]    spotify
[media]    mpv
[media]    obs-studio
[creative] pureref
[creative] meld
[creative] blender
[creative] gimp
[creative] krita
[gaming]   steam
```

**AUR packages** (need paru, not pacman): `brave-bin`, `spotify`, `pureref`, `wlogout`, `hyprlauncher`
Check `pacman -Qm` on the machine to verify current AUR list before coding packages.sh.

---

## Phase 0 — Bootstrap (silent, no gum yet)

### 0a. Pre-flight
- Refuse to run as root — exit with clear message
- Check internet: `ping -c1 archlinux.org` — exit if none
- Detect Arch/EOS — warn if not but don't exit

### 0b. Prerequisites
Install via pacman if missing (in this order):
1. `git`
2. `gum`
3. `stow`

### 0c. Paru
- If `paru` present: skip
- If missing:
  - Install `base-devel` if needed
  - `git clone https://aur.archlinux.org/paru.git /tmp/paru`
  - `cd /tmp/paru && makepkg -si --noconfirm`
  - Exit with clear error message if build fails

### 0d. Tailscale (optional, early)
- `gum confirm "Set up Tailscale now? (Required for Forgejo access)"`
- If yes:
  - Install `tailscale` via paru
  - `systemctl enable --now tailscale`
  - `tailscale up` — opens browser auth URL, user authenticates
  - Wait for connection, confirm before continuing
- If no: continue — Forgejo will be unavailable, GitHub only

### 0e. Dotfiles Repo
- Check if repo already cloned (re-run detection)
- If fresh install:
  - Single-select: clone from `GitHub` or `Forgejo`
  - Forgejo only available if Tailscale connected (check before showing option)
  - If SSH selected: check for existing keys, offer `ssh-keygen` if none
  - Clone selected remote
  - Set up both remotes post-clone if not already configured:
    - `origin` → GitHub
    - `forgejo` → Forgejo instance
- If re-run: `git pull` to update

### 0f. Must-Install Packages
- Read `packages/must-install.txt`
- Extract `[font]` entries from `packages/core.txt` and append to list
- For each package: `pacman -Q packagename` to check — skip if installed
- Install missing via pacman/paru as appropriate
- `systemctl enable sddm`
- `xdg-user-dirs-update`
- **Hard stop** if anything fails — log error and exit

---

## Phase 1 — Welcome Screen

- Gum banner with script name
- Display: current user, hostname, fresh vs re-run detection
- Single-select — choose tier:
  - `⚡ Opinionated` — complete personal setup, skips all menus, runs everything
  - `🔧 Custom` — section-by-section interactive walkthrough
  - `📦 Minimal` — installs [hypr] + [ui] + [font] tags from core.txt, no prompts
  - `👁 Dry Run` — prints all planned actions, installs nothing

---

## Phase 2 — Custom Flow

Implemented as a `while` loop with `$STEP` variable (1–6).
Every screen shows step indicator e.g. `[ Step 2 of 6 ]`.
**Next** on all steps. **Back** on steps 2–6 only.

### Step 1 — Terminal Choice
- Single-select: `ghostty` or `kitty`
- Sets `$TERMINAL_CHOICE` variable used throughout execution
- Info shown: kitty is already installed via must-install
- Ghostty choice: installs ghostty, stows ghostty config, replaces kitty references
  in hyprland.conf keybinds with ghostty at execution time

### Step 2 — Main Packages
Three multi-select groups, all pre-checked, populated dynamically from core.txt:
- **Hyprland ecosystem** — all `[hypr]` tagged packages
- **Core UI** — all `[ui]` tagged packages
- **Shell + Tools** — all `[shell]` and `[tools]` tagged packages
- Fonts shown as informational only — already locked in via must-install

### Step 3 — Additional Packages
Multi-select per category, **none pre-checked** (explicit opt-in).
Populated dynamically from additional.txt, grouped by tag:
- Hypr extras, Dev, Browsers, Communication, Media, Creative

### Step 4 — Scripts
- Auto-discover all files in `scripts/` stow directory at runtime
- Multi-select, all pre-checked
- User deselects anything unwanted
- No hardcoded list — new scripts appear automatically as dotfiles evolve

### Step 5 — Path Replacement
- `gum confirm` — "Replace hardcoded home paths in configs with /home/$USER/?"
- Show preview: what will change before touching anything
- Skippable — if skipped, flagged in Phase 4 summary as manual follow-up

### Step 6 — Confirmation
- Full summary of all selections, grouped by section
- `gum confirm` — "Proceed with install?"
- Back available

---

## Phase 3 — Execution

Sequential. Each step uses `gum spin` for feedback.
All output logged to `~/.dotfiles-install.log`.
Failed packages are logged but do NOT halt execution — noted in summary.

### 3a. System Update
```bash
paru -Syu --noconfirm
```

### 3b. Package Installation
- Separate pass: pacman packages first, then AUR packages via paru
- Each package: check if installed before attempting
- Log failures, continue

### 3c. Terminal Config Swap (if ghostty selected)
- Install ghostty
- Stow ghostty config
- `sed` replace kitty references in hyprland.conf with ghostty
- Leave kitty installed but do not stow its config

### 3d. Stow — Pre-flight Conflict Scan
Before stowing anything:
- File exists where symlink would go → rename to `filename.bak.TIMESTAMP`
- Directory exists where symlink would go → handle recursively
- Log all backed-up files

### 3e. Stow Dotfiles
- Stow only configs relevant to what was selected
- Match stow package names to actual directory names in repo
- **Reconcile actual stow dir names from real dotfiles before coding this module**

### 3f. Font Cache
```bash
fc-cache -fv
```

### 3g. Wallpaper Bootstrap
- Check if `~/photos/wallpapers/` exists
- If not: create directory, copy `assets/wallpapers/default.jpg` into it
- Ensures hyprpaper doesn't launch with a broken path on fresh install
- Wallpaper path in hyprpaper.conf: `~/photos/wallpapers/`

### 3h. Path Replacement (if selected)
- Pattern: `/home/[^/]*/` → `/home/$USER/`
- Dry-run first: log all files and lines that will change
- Then apply with sed
- Scope: all stowed config files

### 3i. Services
Check current state before enabling — idempotent:
- `pipewire`, `wireplumber` — enable for user (not system): `systemctl --user enable`
- `bluetooth` — `systemctl enable bluetooth` if bluez installed
- `docker` — `systemctl enable docker` if docker installed
- `NetworkManager` — `systemctl enable NetworkManager`

### 3j. Shell
- Check current shell: `echo $SHELL`
- If already fish: skip
- If not: `chsh -s $(which fish)`
- Stow fish config

---

## Phase 4 — Summary

- Gum-styled results table:
  - ✓ Installed / already present (green)
  - ↓ Skipped by user (yellow)
  - ✗ Failed with reason (red)
- List of any `.bak` files created during stow
- If path replacement skipped: show as manual follow-up item
- If shell changed: prompt to log out to apply
- If sddm freshly enabled: prompt to reboot
- Link to dotfiles repo README

---

## Execution Order Summary

```
Phase 0   pre-flight → prereqs → paru → tailscale (optional) → repo → must-install
Phase 1   tier selection
Phase 2   custom menus (Custom tier only, steps 1–6)
Phase 3   sysupdate → packages → terminal → stow-preflight → stow → fonts
          → wallpaper → paths → services → shell
Phase 4   summary
```

---

## Key Implementation Rules

1. **Never hardcode username** — always use `$USER` or `$(whoami)`
2. **All package lists are read from txt files** — nothing hardcoded in scripts
3. **Scripts are auto-discovered** — never maintain a hardcoded script list
4. **Every install step is idempotent** — safe to re-run on existing system
5. **paru only, not yay** — yay is an EOS default but not preferred
6. **AUR packages go through paru** — check `pacman -Qm` to identify AUR packages
7. **Tailscale is optional** — script must function fully without it (GitHub as default)
8. **Forgejo is secondary remote only** — never a hard dependency
9. **Hard stop only on must-install failures** — everything else logs and continues
10. **gum-styles.sh defines all colors/borders** — never inline gum styling in modules

---

## Before Writing Any Code — Checklist

- [ ] Read actual stow directory structure and reconcile with plan
- [ ] Check actual hyprland.conf for kitty keybind references (for ghostty swap)
- [ ] Check hyprpaper.conf for wallpaper path (confirmed: `~/photos/wallpapers/`)
- [ ] Run `pacman -Qm` to confirm current AUR package list
- [ ] Verify `scripts/` stow directory name and contents
- [ ] Confirm fish config stow directory name
- [ ] Note any stow directory names that differ from package names
