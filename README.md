# linux-installation

This repo installs and configures a fully-functional Arch Linux setup:
a Hyprland (Wayland) desktop, support packages (network, bluetooth,
audio, etc.), a firewall/hardening pass, and a set of preferred
applications.

| Category | Component |
|----------|-----------|
| Bootloader / splash | GRUB + Plymouth |
| Login screen | SDDM |
| Compositor | Hyprland |
| Status bar | Waybar |
| Dock | Plank |
| App launcher | Wofi |
| Terminal | Alacritty + ZSH |
| Logout menu | Wlogout |
| Widgets | Eww |
| Theme | Catppuccin (GTK, Mocha) |
| Icon theme | Papirus |
| Fonts | Noto Fonts + Nerd Fonts |
| Wallpaper | Swaybg |
| Cursor theme | Bibata |
| File manager | Thunar |
| Clipboard | wl-clipboard + cliphist |
| Notifications | Mako |
| Network | NetworkManager + nm-applet |
| Audio | PipeWire + WirePlumber + pamixer |
| Power | Brightnessctl |
| Package manager | pacman + yay + paru |
| VPN | ProtonVPN |
| Privacy browser | Tor Browser |

## Arch Linux First Boot

Run as **root**, right after a base Arch install:

```sh
pacman -S --noconfirm pacman-contrib curl git
git clone https://github.com/Krowify/linux-installation
cd linux-installation
bash 0-install.sh
```

`0-install.sh` runs all six stages with a single command. AUR builds
(stage 3) can't run as root -- `makepkg` refuses -- and dotfiles (stage
6) need to land in a real user's `$HOME`, not root's, so the script
handles both switches for you:

- If you're running it as **root**, it asks for a username to use for
  stages 3 and 6, offers to create the account if it doesn't exist yet,
  then automatically drops into that user (`su -`) for each of those
  stages and switches back to root in between (for stages 4 and 5).
- If you're already running it as a **regular user with sudo**, it
  just uses your current account for stages 3 and 6 and calls `sudo`
  where needed for the rest.

Expect a few interactive prompts along the way (root/sudo password,
account creation if applicable, `makepkg` confirmations, whether to
enable the SSH server in stage 4) -- that's intentional so nothing
installs, creates accounts, or opens a network port silently.

| Stage | Script                  | Runs as                     | Purpose                                                |
|-------|--------------------------|------------------------------|----------------------------------------------------------|
| 0     | `0-install.sh`           | root or sudo user           | Master runner -- executes all stages below in order       |
| 1     | `1-base.sh`              | root                         | Wayland, Hyprland compositor, networking, audio, bluetooth |
| 2     | `2-system-software.sh`   | root                         | Everyday software + Hyprland desktop utilities (bar, launcher, etc.) from the official repos |
| 3     | `3-user-software.sh`      | non-root (handled by 0-install.sh) | AUR packages via `yay` (VS Code, Discord, themes, etc.)|
| 4     | `4-firewall.sh`     | root                         | Firewall, sysctl hardening, fail2ban                       |
| 5     | `5-post-setup.sh`        | root                         | File watcher limit, display manager, bluetooth autostart, Plymouth/GRUB wiring |
| 6     | `6-dotfiles.sh`          | non-root (handled by 0-install.sh) | Deploys Hyprland/waybar/etc. config, activates the SDDM/GTK/icon/cursor themes |

All scripts use `set -euo pipefail`, so they stop on the first error
instead of silently continuing with a partially-configured system.

## Running stages manually (optional)

If you'd rather step through each stage yourself instead of using
`0-install.sh`, you can still run them individually:

```sh
sh 1-base.sh
sh 2-system-software.sh

su <your-username>
sh 3-user-software.sh

su
sh 4-firewall.sh
sh 5-post-setup.sh

su <your-username>
sh 6-dotfiles.sh
```

## System Description

This runs Hyprland, a tiling Wayland compositor, and installs known
drivers and applications for a quick, consistent Linux setup. It also
configures the firewall and other services expected to be running at
startup.

SDDM is used as the login manager. Once stage 1 finishes, the
`hyprland` package's own `.desktop` entries make Hyprland selectable
from SDDM's session dropdown with nothing further to configure -- pick
"Hyprland (uwsm-managed)" if it's offered, otherwise plain "Hyprland".

## Dotfiles (stage 6)

Package installed alone don't produce a working desktop -- Hyprland,
waybar, mako, etc. all need a config to autostart and behave. Stage 6
deploys `dotfiles/` (source templates in this repo) into `~/.config`,
and activates the installed themes:

- Detects the actual installed folder name for the Catppuccin GTK
  theme, Papirus icon theme, Bibata cursor theme, and the SDDM theme
  under `/usr/share/...` (rather than hardcoding a name that might not
  match what got installed), and wires them into
  `~/.config/gtk-3.0|gtk-4.0/settings.ini`, `~/.icons/default`, and
  `/etc/sddm.conf.d/10-theme.conf`.
- Any existing file/directory it would overwrite gets moved to
  `<name>.bak` first instead of silently clobbered.
- Appends zsh plugin sourcing (`zsh-autosuggestions`,
  `zsh-syntax-highlighting`, `autojump`) to `~/.zshrc`, guarded by a
  marker comment so re-running the stage doesn't duplicate it.

Default keybinds (`$mod` = Super):

| Keybind | Action |
|---------|--------|
| `Super+Return` | Terminal (Alacritty) |
| `Super+D` | App launcher (Wofi) |
| `Super+Q` | Close focused window |
| `Super+E` | File manager (Thunar) |
| `Super+V` | Clipboard history (cliphist + Wofi) |
| `Super+L` | Lock screen (Hyprlock) |
| `Super+Escape` | Logout menu (Wlogout) |
| `Super+W` | Toggle Eww widget panel |
| `Alt+Tab` | Cycle windows |
| `Print` | Screenshot region to clipboard |

`swaybg` defaults to a solid Catppuccin Mocha color (no wallpaper image
ships in this repo) -- swap the `exec-once = swaybg` line in
`~/.config/hypr/hyprland.conf` for `swaybg -i /path/to/image -m fill`
once you have one.

## Troubleshooting

- **Stage 3 or 6 exits immediately** (running it manually) -- you're
  running it as root. Switch to a regular user first
  (`su <your-username>`) and re-run it, or just use `0-install.sh`,
  which handles this automatically.
- **`sudo: command not found` in stage 1 or 2** -- shouldn't happen;
  stage 1 installs `sudo` itself before using it. If you still hit
  this, make sure stage 1 runs first, as root.
- **A package fails to install** -- the script stops at that line
  instead of skipping past it. Check the package name is still
  current for your mirrors, then re-run; already-installed packages
  are skipped via `--needed`.
- **Plymouth splash doesn't show, or GRUB config wasn't touched** --
  stage 5 (not stage 1 -- it runs last, after every package install, so
  it always sees the final kernel/package set) wires up the `splash`
  kernel parameter and the mkinitcpio hook automatically for GRUB, since
  that's what this repo assumes as the bootloader. If you booted with
  something else (systemd-boot, rEFInd, etc.), add `splash` (and
  optionally `quiet`) to its kernel parameters yourself -- see the Arch
  Wiki's Plymouth page.
- **SSH isn't reachable after install** -- that's by design. Stage 4
  asks whether to enable it and defaults to no if you just hit enter;
  it installs the `openssh` package either way but only starts/enables
  `sshd.service` and opens port 22 in ufw if you opt in. Enable it later
  with `sudo systemctl enable --now sshd.service` and
  `sudo ufw limit 22/tcp comment 'SSH (rate-limited)'`.
- **SDDM/GTK/icon/cursor theme didn't apply after stage 6** -- stage 6
  detects the installed theme folder under `/usr/share/...` and prints
  what it found (or `<not found>`) before applying anything. If a
  theme shows as not found, its stage 2/3 package install likely
  failed or was skipped -- re-run that stage, then re-run
  `6-dotfiles.sh`. For SDDM specifically, restart it to see the change:
  `sudo systemctl restart sddm` (this kills your current graphical
  session, so only do it from a TTY or before logging in).
- **Plank isn't behaving like a normal dock** (wrong position,
  overlapping windows, disappearing) -- Plank is an X11-only app with
  no native Wayland support. Under Hyprland it runs via Xwayland,
  where auto-hide and window-avoidance don't work the way they do
  under X11/other DEs. This is a known limitation, not a broken
  install; `nwg-dock-hyprland` (AUR) is the Wayland-native
  alternative if it bothers you.
- **GPU driver** -- stage 1 doesn't install one. AMD and Intel work
  out of the box through mesa; Nvidia needs the proprietary driver
  (`nvidia-open` or `nvidia`, plus `nvidia-utils` and `egl-wayland`)
  and `nvidia_drm.modeset=1` on the kernel command line. The script
  prints a reminder -- see the Arch Wiki's Hyprland and NVIDIA pages
  for details.
- **Hyprland session doesn't appear in SDDM, or crashes back to the
  login screen** -- launching Hyprland from a display manager isn't
  officially supported upstream, though SDDM works for most people.
  Check `journalctl -u sddm -b` and confirm
  `/usr/share/wayland-sessions/hyprland.desktop` exists; if not,
  reinstall the `hyprland` package.

Arch Linux Installation Guide: https://wiki.archlinux.org/title/Installation_guide
