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
| App launcher | Rofi |
| Terminal | Alacritty + ZSH + Starship (prompt) + fzf/zoxide (fuzzy search/smarter cd) |
| System info banner | fastfetch |
| Logout menu | Wlogout |
| Widgets | Eww |
| Settings GUI | hyprmod |
| Theme | Catppuccin Mocha (default) or Tokyo Night, switchable with `theme.sh` (`Super+Shift+T`) -- see [Theme switching](#theme-switching) and [Credits](#credits) |
| Icon theme | Papirus (Catppuccin Mocha) / Tela-circle-purple (Tokyo Night) |
| Fonts | Noto Fonts + Nerd Fonts |
| Wallpaper | Waypaper (GUI picker) + awww (renderer, renamed from swww) |
| Cursor theme | Bibata |
| File manager | Thunar |
| Clipboard | wl-clipboard + cliphist (history), Rofi (picker UI) |
| Notifications | SwayNC |
| Network | NetworkManager + nm-applet |
| Audio | PipeWire + WirePlumber + pamixer |
| Power | Brightnessctl |
| GPU driver | mesa (AMD/Intel) or Nvidia proprietary -- picked interactively in stage 1 |
| Package manager | pacman + yay + paru |
| VPN | ProtonVPN |
| Privacy browser | Tor Browser |
| Cloud storage | Proton Drive (via rclone's `protondrive` backend -- see [Proton Drive](#proton-drive)) |

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
| 5     | `5-dotfiles.sh`          | non-root (handled by 0-install.sh) | Deploys Hyprland/waybar/etc. config, applies the default theme via `theme.sh` |
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
then runs `theme.sh set catppuccin-mocha` to apply the default theme
(see [Theme switching](#theme-switching) below for what that actually
does):

- Any existing file/directory it would overwrite gets moved to
  `<name>.bak` first instead of silently clobbered.
- Appends zsh plugin sourcing (`zsh-autosuggestions`,
  `zsh-syntax-highlighting`, `autojump`) to `~/.zshrc`, guarded by a
  marker comment so re-running the stage doesn't duplicate it.

Default keybinds (`$mod` = Super):

| Keybind | Action |
|---------|--------|
| `Super+Return` | Terminal (Alacritty) |
| `Super+D` | App launcher (Rofi) |
| `Super+Q` | Close focused window |
| `Super+E` | File manager (Thunar) |
| `Super+V` | Clipboard history (cliphist + Rofi) |
| `Super+L` | Lock screen (Hyprlock) |
| `Super+Escape` | Logout menu (Wlogout) |
| `Super+W` | Toggle Eww widget panel |
| `Super+N` | Toggle notification center (SwayNC) |
| `Super+Shift+W` | Open wallpaper picker (waypaper) |
| `Super+Shift+T` | Open theme picker (`theme.sh menu`) |
| `Alt+Shift+H` | Toggle the dock (nwg-dock-hyprland) |
| `Alt+Tab` | Cycle windows |
| `Print` | Screenshot region to clipboard |

No wallpaper image ships with the default theme -- pick one with `waypaper`
(`Super+Shift+W`), which sets it via `awww` and re-themes the desktop via
Matugen. See [Color theming](#color-theming-matugen) below. Until you pick
one, Hyprland/Waybar/SwayNC/Alacritty stay on the static fallback palette
baked into the active theme's dotfiles. (Tokyo Night is the exception --
it ships its own wallpaper, set automatically when you switch to it; see
[Theme switching](#theme-switching).)

waypaper's `folder` setting points at `~/Pictures/wallpapers` (created by
stage 5), and `use_xdg_state = true` moves your actual wallpaper/folder/
monitor picks out of `~/.config/waypaper/config.ini` and into
`~/.local/state/waypaper/state.ini`. That split matters because stage 5
redeploys `~/.config/waypaper/config.ini` from this repo's template on
every run (like most of this repo's dotfiles) -- with state kept
separately, re-running `5-dotfiles.sh` (e.g. after pulling a repo update)
can never wipe out your current wallpaper.

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
monitor`, and saves it to `~/.config/hypr/monitors.conf`, which
`hyprland.conf` already sources by default -- it sticks across restarts
with no manual wiring, and survives a future re-run of `5-dotfiles.sh` too
(that script preserves an existing `monitors.conf` instead of overwriting
it). Currently supports one layout shape: a vertical monitor on the left,
a normal monitor as the main/bottom one, and an upside-down monitor above
it.

## Proton Drive

There's no official Proton Drive client for Linux, so this repo uses
[rclone](https://rclone.org/protondrive/)'s built-in `protondrive`
backend, via a systemd `--user` unit (`protondrive-mount.service`,
deployed by stage 5 but left **disabled**) that mounts it at
`~/ProtonDrive` with `rclone mount`. A Thunar sidebar bookmark for
`~/ProtonDrive` is deployed too (`~/.config/gtk-3.0/bookmarks`).

Setup is a one-time, interactive step this repo deliberately doesn't
script -- rclone needs your Proton credentials and a 2FA code, which
can't be handled non-interactively/safely:

```sh
rclone config
# n) New remote -> name it "protondrive" -> type "protondrive"
# follow the prompts for your Proton username/password and 2FA code

systemctl --user enable --now protondrive-mount.service
```

After that, `~/ProtonDrive` mounts automatically on login (`After=
network-online.target`) and shows up in Thunar's sidebar. To unmount:
`systemctl --user stop protondrive-mount.service`.

## Theme switching

This repo ships two themes -- Catppuccin Mocha (the default) and Tokyo
Night -- and a small switcher, `theme.sh`, deployed by stage 5 to
`~/.config/hyde-themes/`. Run it directly, or press `Super+Shift+T` for a
Rofi picker:

```sh
~/.config/hyde-themes/theme.sh set tokyo-night   # apply a theme
~/.config/hyde-themes/theme.sh menu              # Rofi picker
~/.config/hyde-themes/theme.sh list              # list available themes
~/.config/hyde-themes/theme.sh current           # show the active theme
```

Each theme lives in its own directory under `~/.config/hyde-themes/`
(sourced from `dotfiles/hyde-themes/<name>/` in this repo) and holds:

- One color file per themed app (`hypr-colors.conf`,
  `waybar-accent-colors.css` + `waybar-colors.css`,
  `swaync-accent-colors.css` + `swaync-variables.css`,
  `wlogout-colors.css`, `alacritty-colors.toml`, `rofi-colors.rasi`,
  `eww-colors.scss`) -- every app's own config now just `@import`s (or,
  for Hyprland/Alacritty/Wlogout, `source`s) a stable filename in its
  `~/.config/<app>/` directory, and `theme.sh set` is what copies the
  chosen theme's version of each file into place and reloads that app
  (`hyprctl reload`, `killall -SIGUSR2 waybar`, `swaync-client -rs`,
  `eww reload` -- Alacritty/Wlogout need no reload, see
  [Color theming](#color-theming-matugen) below).
- `theme.conf`, naming the GTK theme + icon theme this desktop theme
  needs (as case-insensitive glob patterns, same idea as stage 5's old
  folder detection) and, optionally, a URL to fetch them from if they
  aren't installed anywhere `theme.sh` looks (`/usr/share/{themes,icons}`,
  then `~/.local/share/{themes,icons}`). Catppuccin Mocha's GTK/icon
  themes come from stage 3's AUR packages, so it needs no URL. Tokyo
  Night's don't exist as official-repo or known-good AUR packages, so
  `theme.sh` downloads them straight from
  [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes)
  (the same assets HyDE itself ships) the first time you switch to it,
  and extracts them into `~/.local/share/{themes,icons}` -- no `sudo`,
  no AUR package name to guess. **This means switching to Tokyo Night
  for the first time needs a network connection.**
- Optionally a bundled `wallpaper.*`, set directly via `awww img` when
  you switch to that theme (Tokyo Night has one; Catppuccin Mocha
  doesn't, since it's meant to be re-themed dynamically from whatever
  wallpaper you pick -- see below).

`~/.config/hyde-themes/global.conf` (not per-theme) covers the two bits
of chrome that stay the same across every theme: the cursor theme and the
SDDM login theme.

**No file manager swap needed.** Thunar is a GTK app and already reads
its icons/colors from the GTK theme `theme.sh` sets in
`~/.config/gtk-3.0/gtk-4.0/settings.ini` (plus `gsettings`, for anything
that reads theme names that way instead) -- switching themes re-themes
Thunar for free, the same way it re-themes every other GTK app.

**How this interacts with Matugen:** Catppuccin Mocha is designed to be
re-themed dynamically by Matugen as you change wallpapers (see below) --
`theme.sh set catppuccin-mocha` just applies its own static fallback
colors, same as always. Tokyo Night is a *curated* palette, not one
derived from its wallpaper, so `theme.sh` sets its colors directly and
sets its wallpaper via `awww` directly too, bypassing `waypaper`'s
Matugen hook on purpose. If you then open `waypaper` and pick a (new or
even the same) wallpaper yourself, that **will** re-run Matugen and
overwrite Tokyo Night's curated colors with a wallpaper-derived
palette -- that's expected, not a bug: picking a wallpaper through
`waypaper` is itself an opt-in "go dynamic" action, orthogonal to which
theme you last switched to. Re-run `theme.sh set tokyo-night` to restore
the curated palette.

**Adding another theme:** copy `dotfiles/hyde-themes/tokyo-night/` (or
`catppuccin-mocha/`, if you don't want a bundled wallpaper) to a new
`dotfiles/hyde-themes/<name>/`, edit its color files and `theme.conf`,
re-run stage 5 (or just `cp -r` it into `~/.config/hyde-themes/<name>/`
directly) -- it'll show up in `theme.sh list`/`menu` immediately, no
other wiring needed.

Not covered by any of this: Qt/Kvantum theming for `kate`/`pavucontrol`
(neither theme configures Kvantum, so Qt apps keep using your system Qt
style regardless of which theme is active), and the SDDM login theme
(shared across both themes on purpose -- see `global.conf` above).

## Color theming (Matugen)

Picking a wallpaper through `waypaper` doesn't just set the background --
`waypaper`'s `post_command` (`dotfiles/waypaper/config.ini`) runs
`matugen image "$wallpaper"`, which generates a Material You color scheme
from that image and rewrites the color files for Hyprland, Waybar, SwayNC,
Alacritty's background/foreground/cursor, and Wlogout from it:

| App | Generated file | Picked up via |
|-----|-----------------|----------------|
| Hyprland | `~/.config/hypr/colors.conf` | `hyprctl reload` (Matugen's post_hook) |
| Waybar | `~/.config/waybar/tokens/colors.css` | `killall -SIGUSR2 waybar` (Matugen's post_hook) |
| SwayNC | `~/.config/swaync/tokens/variables.css` | `swaync-client -rs` (Matugen's post_hook) |
| Alacritty | `~/.config/alacritty/colors.toml` | live-reloads on file change by itself |
| Wlogout | `~/.config/wlogout/colors.css` | none needed -- launched fresh each time (Super+Escape), not a running daemon |

Each of those files ships with a static fallback (the same Catppuccin
Mocha + custom accent palette used everywhere else in this repo -- see
[Credits](#credits)) so things look right before you've ever picked a
wallpaper. Matugen overwrites them in place once you do. This whole
pipeline is specific to Catppuccin Mocha -- Tokyo Night's version of
these same files is a fixed palette `theme.sh` applies directly instead;
see [Theme switching](#theme-switching) above.

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

- **SwayNC/waypaper don't behave as documented** -- these two (plus the
  whole Matugen pipeline) were wired up from documentation and community
  examples, not verified against a live install, unlike the rest of this
  repo's dotfiles (which have all been fixed up against real error
  messages over a lot of back-and-forth). `swaync-client -t -sw` in
  particular is one of the least certain bits -- if a keybind does
  nothing or errors, run the command directly in a terminal to see what
  it actually says, and check that app's own `--help`/docs for the
  current invocation.
- **`swww-daemon`/`swww` not found, or waypaper can't set a wallpaper**
  -- the `swww` project was renamed to `awww` in October 2025 (moved to
  Codeberg). If you're on an older guide/tutorial that still says
  `swww`, use `awww`/`awww-daemon` instead -- this repo already does
  (`2-system-software.sh`, official repo, no AUR needed anymore).
- **Rofi launches under Xwayland, or `-show drun` errors/does nothing**
  -- Rofi only merged native Wayland support upstream in 2025; if your
  mirror still has an older build, either wait for a pacman sync or swap
  the `rofi` package (2-system-software.sh) for the AUR `rofi-wayland`
  package instead (same config, no other changes needed).
- **"Rofi is unsure what to show"** -- this means rofi's `modi` list
  never got applied, so `-show drun` has no mode to launch. Two things
  guard against it: `Super+D`'s bind passes `-modi` explicitly on the
  command line rather than relying only on `config.rasi`'s `modi` line,
  and `config.rasi` no longer has the `me-select-entry`/`me-accept-entry`
  lines Athena's original had (they aren't real rofi options -- an
  unrecognized key can make rofi discard the whole `configuration`
  block, `modi` included). If you still hit this, run `rofi -show drun`
  directly in a terminal to see the actual parse error.
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
- **SwayNC's backlight slider is missing/broken** -- same class of issue
  as the Waybar temperature module above: `dotfiles/swaync/config.json`'s
  `"backlight": {"device": "intel_backlight"}` is hardware-specific
  (Athena's author's own laptop -- see [Credits](#credits)). Run
  `ls /sys/class/backlight/` to find your device name, or delete the
  `"backlight"` entries from `widget-config` and `widgets` in that file
  if your machine has no backlight-controllable display at all (most
  desktops).
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
  ends by running `theme.sh set catppuccin-mocha`, which detects the
  installed theme folder under `/usr/share/...` (or `~/.local/share/...`)
  and prints what it found (falling back to `Adwaita` if nothing
  matched) before applying anything. If it printed `Adwaita` for
  something that should be installed, its stage 2/3 package install
  likely failed or was skipped -- re-run that stage, then
  `~/.config/hyde-themes/theme.sh set catppuccin-mocha` (no need to
  re-run all of stage 5). Stage 5 now runs before stage 6 enables
  `sddm.service`, so on a normal `0-install.sh` run the login screen
  already picks up the theme on its first start; you'd only need to
  restart it by hand (`sudo systemctl restart sddm` -- this kills your
  current graphical session, so only do it from a TTY or before logging
  in) if you re-ran stage 5 (or `theme.sh`) after SDDM was already
  running.
- **Switching to Tokyo Night does nothing to the GTK theme/icons, or
  `theme.sh` prints a `curl`/`tar` warning** -- the first switch to
  Tokyo Night needs to download its GTK theme + icon theme (no
  official-repo/AUR package for either exists -- see
  [Theme switching](#theme-switching)); that needs a working network
  connection and `curl`. If it fails, `theme.sh` falls back to `Adwaita`
  and prints a `WARNING`, but still applies everything else (colors,
  wallpaper) -- fix your network and re-run
  `~/.config/hyde-themes/theme.sh set tokyo-night` to pick up the actual
  GTK/icon theme.
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

- The accent color palette used across Hyprland, Eww, and Alacritty is
  ported from
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
- SwayNC's `config.json`, `style.css`, and `tokens/` (button grid,
  slider, MPRIS, notification, title/DND styling) are also from
  [haikal-hakim/athena](https://github.com/haikal-hakim/athena), with
  the `buttons-grid` actions repointed to tools this repo actually
  installs (grim+slurp screenshot, hyprlock, waypaper) instead of
  Athena's placeholder scripts and apps (a screen recorder, hyprpicker,
  galculator) this repo doesn't have. Also fixed a handful of what look
  like copy-paste bugs in the original CSS while porting it: a missing
  `--accent-hover` variable referenced but never defined, three spots
  using a background-role variable as a text color, and a
  `10px solid` notification-action border that should have been `1px`
  to match every other border in the file.
- Wlogout's color scheme (`dotfiles/wlogout/colors.css`) is templated
  from the same Athena/Matugen palette as Waybar/SwayNC above, for
  visual consistency -- the layout/button structure itself stays this
  repo's own (Athena's version needs bundled PNG icon files and an
  unverified `hyprshutdown` helper tool that didn't fit this repo's
  text-only, no-binary-assets dotfiles).
- `dotfiles/fastfetch/config.jsonc` and `dotfiles/starship.toml` are
  also from [haikal-hakim/athena](https://github.com/haikal-hakim/athena),
  used as-is (both are visual/prompt configs with no app-specific paths
  to adapt). Starship's palette is a static Catppuccin Mocha scheme, not
  Matugen-templated -- same reasoning as Alacritty's ANSI colors (see
  [Color theming](#color-theming-matugen)): a prompt should stay
  readable and stable, not shift with every wallpaper. zoxide and fzf
  aren't from Athena -- they're just common shell quality-of-life tools,
  wired up directly in the zshrc snippet (no external config to credit).
- Rofi's `config.rasi` and `clipboard.rasi` are also from
  [haikal-hakim/athena](https://github.com/haikal-hakim/athena) --
  `icon-theme` was hardcoded to `"Papirus cirle light"` in the original
  (a typo'd name, and a light-variant icon theme this repo doesn't
  install and wouldn't suit the dark theme here anyway), swapped for the
  `__ICON_THEME__` placeholder this repo already uses elsewhere (GTK
  settings) so it matches whatever Papirus variant actually got
  installed.
- The Tokyo Night theme (`dotfiles/hyde-themes/tokyo-night/`) is ported
  from [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes)
  (Tokyo-Night branch): the base accent/surface hexes (Hyprland border
  colors, Waybar/Rofi accents) come from that branch's `hypr.theme`,
  `waybar.theme`, and `rofi.theme`; Alacritty's colors are lifted from
  its `kitty.theme`, itself credited there to
  [davidmathers/tokyo-night-kitty-theme](https://github.com/davidmathers/tokyo-night-kitty-theme)
  and [enkia/tokyo-night-vscode-theme](https://github.com/enkia/tokyo-night-vscode-theme);
  and the GTK theme + Tela-circle-purple icon theme `theme.sh` downloads
  on first use are the exact `Source/Gtk_TokyoNight.tar.gz` and
  `Source/Icon_TelaPurple.tar.gz` archives that repo ships. The extended
  Material-You-shaped token set in `waybar-colors.css` (surface/container
  scale, on-* roles, etc. -- HyDE's theme files only give a handful of
  base colors, not this repo's full Waybar token set) is this repo's own
  derivation from the same Tokyo Night Storm palette. The bundled
  wallpaper (`dotfiles/hyde-themes/tokyo-night/wallpaper.png`) is also
  from that branch's `wallpapers/lowpoly_street.png` -- "Illustration by
  Sayybils" per the credit baked into the image itself.
