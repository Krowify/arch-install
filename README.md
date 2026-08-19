# linux-installation

This repo installs and configures a fully-functional Arch Linux setup:
a Hyprland (Wayland) desktop, support packages (network, bluetooth,
audio, etc.), a firewall/hardening pass, and a set of preferred
applications.

| Category | Component |
|----------|-----------|
| Bootloader / splash | GRUB + Plymouth |
| Display Manager | SDDM (Plasma Login Manager) |
| Compositor | Hyprland |
| Status bar | Waybar |
| Dock | nwg-dock-hyprland |
| Music | Spotify (via spotify-launcher) |
| App launcher | Vicinae |
| Terminal | Alacritty + ZSH |
| Logout menu | Wlogout |
| Widgets | Eww |
| Settings GUI | hyprmod |
| Theme | Catppuccin Mocha (GTK/SDDM) + custom accent palette (Hyprland, Wlogout, Eww, Alacritty) + Athena's Material You palette (Waybar), all dynamically re-themed by Matugen -- see [Credits](#credits) and [Color theming](#color-theming-matugen) |
| Icon theme | Papirus |
| Fonts | Noto Fonts + Nerd Fonts |
| Wallpaper | Waypaper (GUI picker) + swww (renderer) |
| Cursor theme | Bibata |
| File manager | Thunar |
| Clipboard | wl-clipboard + cliphist (history), Vicinae (picker UI) |
| Notifications | SwayNC |
| Network | NetworkManager + nm-applet |
| Audio | PipeWire + WirePlumber + pamixer |
| Power | Brightnessctl |
| GPU driver | mesa (AMD/Intel) or Nvidia proprietary -- picked interactively in stage 1 |
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
5) need to land in a real user's `$HOME`, not root's, so the script
handles both switches for you:

- If you're running it as **root**, it asks for a username to use for
  stages 3 and 5, offers to create the account if it doesn't exist yet,
  then automatically drops into that user (`su -`) for each of those
  stages and switches back to root in between (for stages 4 and 6).
- If you're already running it as a **regular user with sudo**, it
  just uses your current account for stages 3 and 5 and calls `sudo`
  where needed for the rest.

Expect a few interactive prompts along the way (root/sudo password,
account creation if applicable, `makepkg` confirmations, whether to
enable the SSH server in stage 4) -- that's intentional so nothing
installs, creates accounts, or opens a network port silently.

| Stage | Script                  | Runs as                     | Purpose                                                |
|-------|--------------------------|------------------------------|----------------------------------------------------------|
| 0     | `0-install.sh`           | root or sudo user           | Master runner -- executes all stages below in order       |
| 1     | `1-base.sh`              | root                         | Wayland, Hyprland compositor, networking, audio, bluetooth, GPU driver (asks Intel/Nvidia/AMD) |
| 2     | `2-system-software.sh`   | root                         | Everyday software + Hyprland desktop utilities (bar, launcher, etc.) from the official repos |
| 3     | `3-user-software.sh`      | non-root (handled by 0-install.sh) | AUR packages via `yay` (VS Code, Discord, themes, etc.)|
| 4     | `4-firewall.sh`     | root                         | Firewall, sysctl hardening, fail2ban                       |
| 5     | `5-dotfiles.sh`          | non-root (handled by 0-install.sh) | Deploys Hyprland/waybar/etc. config, activates the SDDM/GTK/icon/cursor themes |
| 6     | `6-post-setup.sh`        | root                         | File watcher limit, display manager, bluetooth autostart, Plymouth/GRUB wiring, Nvidia kernel parameter (if applicable) |

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

su <your-username>
sh 5-dotfiles.sh

su
sh 6-post-setup.sh
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

## Dotfiles (stage 5)

Package installed alone don't produce a working desktop -- Hyprland,
waybar, swaync, etc. all need a config to autostart and behave. Stage 5
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
| `Super+D` | App launcher (Vicinae) |
| `Super+Q` | Close focused window |
| `Super+E` | File manager (Thunar) |
| `Super+V` | Clipboard history (Vicinae) |
| `Super+L` | Lock screen (Hyprlock) |
| `Super+Escape` | Logout menu (Wlogout) |
| `Super+W` | Toggle Eww widget panel |
| `Super+N` | Toggle notification center (SwayNC) |
| `Super+Shift+W` | Open wallpaper picker (waypaper) |
| `Alt+Shift+H` | Toggle the dock (nwg-dock-hyprland) |
| `Alt+Tab` | Cycle windows |
| `Print` | Screenshot region to clipboard |

No wallpaper image ships in this repo -- pick one with `waypaper`
(`Super+Shift+W`), which sets it via `swww` and re-themes the desktop via
Matugen. See [Color theming](#color-theming-matugen) below. Until you pick
one, Hyprland/Waybar/SwayNC/Alacritty stay on the static fallback palette
baked into their dotfiles.

## Multi-monitor layout (optional)

`hypr-monitor-layout.sh` is a standalone helper for arranging multiple
monitors -- e.g. a portrait monitor beside a normal one, or one mounted
upside down -- without hand-computing pixel offsets. It's not wired into
`0-install.sh` or any numbered stage on purpose: it drives `hyprctl`, which
only works from inside an already-running Hyprland session, so there's no
point in the install pipeline where it could run. Use it once you've
finished the install and logged in, from inside a terminal running under
Hyprland (e.g. Alacritty), from wherever you cloned/extracted this repo:

```sh
cd linux-installation
chmod +x hypr-monitor-layout.sh
./hypr-monitor-layout.sh
```

(`chmod +x` is only needed once -- git already tracks the file as
executable, but a zip download can lose that bit. If you'd rather skip it,
`bash hypr-monitor-layout.sh` works without it.)

It reads your connected monitors from `hyprctl monitors`, asks which one
plays which role, applies the layout immediately via `hyprctl keyword
monitor`, and saves it to `~/.config/hypr/monitors.conf`. Add
`source = ~/.config/hypr/monitors.conf` to `~/.config/hypr/hyprland.conf`
(and remove/comment out the `monitor = , preferred, auto, auto` line) to
make it stick across restarts. Currently supports one layout shape: a
vertical monitor on the left, a normal monitor as the main/bottom one, and
an upside-down monitor above it.

## Color theming (Matugen)

Picking a wallpaper through `waypaper` doesn't just set the background --
`waypaper`'s `post_command` (`dotfiles/waypaper/config.ini`) runs
`matugen image "$wallpaper"`, which generates a Material You color scheme
from that image and rewrites the color files for Hyprland, Waybar, SwayNC,
and Alacritty's background/foreground/cursor from it:

| App | Generated file | Picked up via |
|-----|-----------------|----------------|
| Hyprland | `~/.config/hypr/colors.conf` | `hyprctl reload` (Matugen's post_hook) |
| Waybar | `~/.config/waybar/tokens/colors.css` | `killall -SIGUSR2 waybar` (Matugen's post_hook) |
| SwayNC | `~/.config/swaync/colors.css` | `swaync-client -rs` (Matugen's post_hook) |
| Alacritty | `~/.config/alacritty/colors.toml` | live-reloads on file change by itself |

Each of those files ships with a static fallback (the same Catppuccin
Mocha + custom accent palette used everywhere else in this repo -- see
[Credits](#credits)) so things look right before you've ever picked a
wallpaper. Matugen overwrites them in place once you do.

Alacritty's ANSI 16-color palette (`[colors.normal]`/`[colors.bright]` in
`alacritty.toml` itself) is deliberately **not** Matugen-templated --
Material You doesn't define semantic roles for "ANSI green"/"ANSI cyan"
etc., and remapping them per-wallpaper would make `ls`/`diff`/etc. output
unpredictable. Only background/foreground/cursor (`colors.toml`) move with
the wallpaper.

The template sources live in `dotfiles/matugen/templates/`, wired up in
`dotfiles/matugen/config.toml`. To theme another app, add a
`[templates.name]` block there and a matching template file -- see the
[Matugen wiki](https://github.com/InioX/matugen/wiki) for the full list of
generated color roles.

Note: none of this Matugen wiring has been verified against a live
install (unlike most of the rest of this repo, which has been fixed up
against real error messages over time) -- if a template fails or a color
role name doesn't exist, run `matugen image <path> --dry-run` to see what
it actually generates and adjust the role names in
`dotfiles/matugen/templates/*` and `dotfiles/matugen/config.toml`
accordingly.

## Troubleshooting

- **Vicinae/SwayNC/waypaper/swww don't behave as documented** -- these
  four (plus the whole Matugen pipeline) were wired up from documentation
  and community examples, not verified against a live install, unlike the
  rest of this repo's dotfiles (which have all been fixed up against real
  error messages over a lot of back-and-forth). `vicinae toggle`,
  `swaync-client -t -sw`, and the `vicinae://launch/clipboard/history`
  deeplink in particular are the least certain bits -- if a keybind does
  nothing or errors, run the command directly in a terminal to see what
  it actually says, and check that app's own `--help`/docs for the
  current invocation.
- **Waybar's temperature module shows nothing/wrong, or the CPU
  temperature looks off** -- `dotfiles/waybar/modules/system.jsonc` hard
  codes `"thermal-zone": 8`, copied from Athena's author's own machine
  (see [Credits](#credits)). Run `for z in /sys/class/thermal/thermal_zone*;
  do echo "$z: $(cat $z/type)"; done` and find the zone whose type looks
  like your CPU package (e.g. `x86_pkg_temp`, `k10temp`), then use that
  number instead.
- **Waybar's clock is in the wrong timezone** -- it uses your system
  timezone by default now (the upstream config hardcoded Jakarta). Add a
  `"timezone": "..."` key to `dotfiles/waybar/modules/clock.jsonc` if you
  want the bar to show something other than your system clock.
- **Waybar's power-profile icon/tooltip does nothing** -- it needs
  `power-profiles-daemon.service` running; stage 6 enables it
  automatically, but if you added the package after the fact, run
  `sudo systemctl enable --now power-profiles-daemon.service` yourself.
- **Stage 3 or 5 exits immediately** (running it manually) -- you're
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
  stage 6 (not stage 1 -- it runs last, after every package install, so
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
- **SDDM/GTK/icon/cursor theme didn't apply after stage 5** -- stage 5
  detects the installed theme folder under `/usr/share/...` and prints
  what it found (or `<not found>`) before applying anything. If a
  theme shows as not found, its stage 2/3 package install likely
  failed or was skipped -- re-run that stage, then re-run
  `5-dotfiles.sh`. Stage 5 now runs before stage 6 enables `sddm.service`,
  so on a normal `0-install.sh` run the login screen already picks up the
  theme on its first start; you'd only need to restart it by hand
  (`sudo systemctl restart sddm` -- this kills your current graphical
  session, so only do it from a TTY or before logging in) if you re-ran
  stage 5 after SDDM was already running.
- **GPU driver** -- stage 1 asks which GPU you have (pre-filling its
  guess from `lspci` if it can tell). AMD and Intel need nothing beyond
  the `mesa` already installed. Nvidia gets `nvidia-open` (swap for
  `nvidia` yourself if you're on a pre-Turing card and it fails to boot
  into Hyprland), `nvidia-utils`, and `egl-wayland` installed there and
  then; stage 6 detects the installed driver and adds
  `nvidia_drm.modeset=1` to the GRUB kernel command line automatically
  -- see the Arch Wiki's Hyprland and NVIDIA pages for anything beyond
  that.
- **Hyprland session doesn't appear in SDDM, or crashes back to the
  login screen** -- launching Hyprland from a display manager isn't
  officially supported upstream, though SDDM works for most people.
  Check `journalctl -u sddm -b` and confirm
  `/usr/share/wayland-sessions/hyprland.desktop` exists; if not,
  reinstall the `hyprland` package.

Arch Linux Installation Guide: https://wiki.archlinux.org/title/Installation_guide

## Credits

- The accent color palette used across Hyprland, Wlogout, Eww, and
  Alacritty is ported from
  [notusknot/dotfiles-nix](https://github.com/notusknot/dotfiles-nix)
  (it's also the static fallback/default the Matugen templates for those
  apps in `dotfiles/matugen/` are based on -- see
  [Color theming](#color-theming-matugen)).
- The nwg-dock-hyprland style (`dotfiles/nwg-dock-hyprland/style.css`) and
  its launch flags/layer rules in `hyprland.conf` are from
  [AnkurAlpha/nwg-dock-hyprland-configs-by-AnkurAlpha](https://github.com/AnkurAlpha/nwg-dock-hyprland-configs-by-AnkurAlpha).
- Waybar's whole config (`dotfiles/waybar/`: `config.jsonc`, the
  `modules/` and `tokens/` directories, and their default Material You
  color scheme) is ported from Muhammad Haikal Hakim's
  [haikal-hakim/athena](https://github.com/haikal-hakim/athena) (MIT
  licensed), trimmed and adjusted to the apps/icon theme this repo
  actually installs -- see the comments in
  `dotfiles/waybar/modules/distro.jsonc`,
  `dotfiles/waybar/modules/workspace.jsonc`, and
  `dotfiles/waybar/modules/tray-notif.jsonc` for what changed.
