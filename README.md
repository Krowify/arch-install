# Arch Installer

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
| Theme | Tokyo Night (default), Decay Green, or Graphite Mono, switchable with `theme.sh` (`Super+Shift+T`) -- see [Theme switching](#theme-switching) and [Credits](#credits) |
| Icon theme | Tela-circle-purple (Tokyo Night) / Tela-circle-green (Decay Green) / Tela-circle-grey (Graphite Mono) |
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
git clone https://github.com/Krowify/arch-install
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
then runs `theme.sh set tokyo-night` to apply the default theme
(see [Theme switching](#theme-switching) below for what that actually
does):

- Any existing file/directory it would overwrite gets moved to
  `<name>.bak` first instead of silently clobbered.
- Appends zsh plugin sourcing (`zsh-autosuggestions`,
  `zsh-syntax-highlighting`, `autojump`) to `~/.zshrc`, guarded by a
  marker comment so re-running the stage doesn't duplicate it.

Default keybinds (`$mod` = Super) -- see [`KEYBINDINGS.md`](KEYBINDINGS.md)
for the exact copy-pasteable `bind` lines. Keyed to match
[HyDE-Project/HyDE's own KEYBINDINGS.md](https://github.com/HyDE-Project/HyDE/blob/master/KEYBINDINGS.md)
wherever this repo has an equivalent app or Hyprland dispatcher for it --
see the comment above the keybinds section in `dotfiles/hypr/hyprland.conf`
for what wasn't ported (HyDE features that call into its own
`~/.local/lib/hyde/` helper scripts, which this repo doesn't install) and
why. A couple of this repo's own pre-existing binds (`Super+Return`,
`Super+F`) are kept as extra aliases alongside HyDE's key for the same
action.

Grouped into Super binds, Alt binds, window-movement binds (focus/resize/
move/group-cycle -- these all happen to use Super too, but get their own
table since they're a distinct category), and everything else (hardware,
media, and the handful of binds with neither modifier).

### Super

| Keybind | Action |
|---------|--------|
| `Super+Return` / `Super+T` | Terminal (Alacritty) |
| `Super+Alt+T` | Dropdown terminal (own special workspace) |
| `Super+A` / `Super+Tab` | App launcher (Rofi) |
| `Super+Q` | Close focused window |
| `Super+Alt+F4` | Force-kill focused window |
| `Super+Delete` | Exit Hyprland session |
| `Super+E` | File manager (Thunar) |
| `Super+Shift+E` | File finder (Rofi) |
| `Super+C` | Text editor (VS Code) |
| `Super+B` | Web browser (Brave) |
| `Super+V` / `Super+Shift+V` | Clipboard history (cliphist + Rofi) |
| `Super+Shift+/` | Web search (Rofi prompt) |
| `Super+L` | Lock screen (Hyprlock) |
| `Super+Escape` | Logout menu (Wlogout) |
| `Super+W` / `Super+F` | Toggle floating |
| `Super+M` | Toggle Eww widget panel |
| `Super+G` | Toggle group |
| `Super+Shift+F` | Toggle pin on focused window |
| `Super+Ctrl+B` | Toggle waybar |
| `Super+J` | Toggle split |
| `Super+N` | Toggle notification center (SwayNC) |
| `Super+Shift+W` | Open wallpaper picker (waypaper) |
| `Super+Shift+T` | Open theme picker (`theme.sh menu`) |
| `Super+P` | Screenshot region to clipboard |
| `Super+Alt+P` | Screenshot focused monitor to clipboard |
| `Super+1` .. `Super+0` | Switch to workspace 1-10 |
| `Super+Shift+1` .. `Super+Shift+0` | Move window to workspace 1-10 |
| `Super+Alt+1` .. `Super+Alt+0` | Move window to workspace 1-10 (silent) |
| `Super+Ctrl+Right/Left` | Next/previous workspace (relative) |
| `Super+Ctrl+Down` | Go to nearest empty workspace |
| `Super+S` | Toggle scratchpad |
| `Super+Shift+S` / `Super+Alt+S` | Move window to scratchpad / silently |

### Alt

| Keybind | Action |
|---------|--------|
| `Alt+F4` | Close focused window |
| `Alt+P` | Toggle pseudotile |
| `Alt+Ctrl+Delete` | Logout menu (Wlogout) |
| `Alt+Tab` / `Alt+Shift+Tab` | Cycle windows forward/backward |
| `Alt+Shift+H` | Toggle the dock (nwg-dock-hyprland) |

### Window movement

| Keybind | Action |
|---------|--------|
| `Super+Ctrl+H` / `Super+Ctrl+L` | Cycle window group backward/forward |
| `Super+Left/Right/Up/Down` | Focus window in direction |
| `Super+Shift+Left/Right/Up/Down` | Resize active window |
| `Super+Ctrl+Shift+Left/Right/Up/Down` | Move active window between tiles |
| `Super+Z` / `Super+X` | Hold to move / resize window (no mouse) |

### Other (hardware, media, no modifier)

| Keybind | Action |
|---------|--------|
| `Ctrl+Shift+Escape` | System monitor (`top` in Alacritty) |
| `Shift+F11` | Toggle fullscreen |
| `Print` | Screenshot all monitors to clipboard |
| `F10` / `F11` / `F12` | Mute / lower / raise volume |
| `XF86Audio*`, `XF86MonBrightness*` | Media, mic mute, and brightness keys |

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

`dotfiles/hypr/hyprland.conf` ships a single default `monitor =
,preferred,auto,auto` line (auto-detect, preferred mode, for every
monitor). For anything beyond that -- e.g. a portrait monitor beside a
normal one, or one mounted upside down -- use hyprmod's GUI (in your app
launcher) instead of hand-editing `hyprland.conf`: it live-previews monitor
position/rotation/mode changes via `hyprctl` and persists them to its own
config, independently of this repo's dotfiles, so a future re-run of
`5-dotfiles.sh` never reverts your layout.

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

The unit passes `--protondrive-enable-caching=false`: rclone's protondrive
backend docs warn its own caching (on by default) isn't invalidated by
changes made outside the mount (e.g. the Proton web app or another
device) yet, and to disable it for VFS mounts specifically -- otherwise
`~/ProtonDrive` can silently show stale directory listings.

After that, `~/ProtonDrive` mounts automatically on login (`After=
network-online.target`) and shows up in Thunar's sidebar. To unmount:
`systemctl --user stop protondrive-mount.service`.

## Theme switching

This repo ships three themes -- Tokyo Night (the default), Decay Green,
and Graphite Mono -- and a small switcher, `theme.sh`, deployed by stage 5
to `~/.config/hyde-themes/`. Run it directly, or press `Super+Shift+T` for
a Rofi picker:

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
  then `~/.local/share/{themes,icons}`). None of the three themes here
  have official-repo or known-good AUR packages for their GTK/icon
  themes, so `theme.sh` downloads all of them straight from
  [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes)
  (the same assets HyDE itself ships) the first time you switch to each
  one, and extracts them into `~/.local/share/{themes,icons}` -- no
  `sudo`, no AUR package name to guess. **This means switching to a theme
  for the first time needs a network connection.**
- Optionally a bundled `wallpaper.*`, set directly via `awww img` when
  you switch to that theme. Tokyo Night has one; Decay Green and
  Graphite Mono don't (no verified wallpaper asset was found for either
  while adding them -- see the disclaimer in each one's `theme.conf`),
  so switching to them leaves whatever wallpaper was already set.

`~/.config/hyde-themes/global.conf` (not per-theme) covers the two bits
of chrome that stay the same across every theme: the cursor theme and the
SDDM login theme.

**Palette fidelity:** Tokyo Night's color files were ported from HyDE's
actual published theme source (see [Credits](#credits)). Decay Green and
Graphite Mono's GTK/icon *theme assets* are likewise the real ones HyDE
ships, but their *color files* in this repo are this repo's own
construction -- HyDE's exact source hex values for those two wouldn't
reliably fetch while adding them here, so they're coherent, same-shape
palettes built to match each theme's name/intent, not pixel-matched to
HyDE's live rendering. Each one's `theme.conf` says so and links to where
to pull the real values from if you want an exact match.

**No file manager swap needed.** Thunar is a GTK app and already reads
its icons/colors from the GTK theme `theme.sh` sets in
`~/.config/gtk-3.0/gtk-4.0/settings.ini` (plus `gsettings`, for anything
that reads theme names that way instead) -- switching themes re-themes
Thunar for free, the same way it re-themes every other GTK app.

**How this interacts with Matugen:** all three themes here are *curated*
palettes, not ones derived from a wallpaper -- `theme.sh` sets each
one's colors directly and sets its wallpaper via `awww` directly too (if
it has one bundled), bypassing `waypaper`'s Matugen hook on purpose. If
you then open `waypaper` and pick a wallpaper yourself, that **will**
re-run Matugen and overwrite the active theme's curated colors with a
wallpaper-derived palette -- that's expected, not a bug: picking a
wallpaper through `waypaper` is itself an opt-in "go dynamic" action,
orthogonal to which theme you last switched to. Re-run
`theme.sh set <name>` to restore the curated palette.

**Adding another theme:** copy `dotfiles/hyde-themes/tokyo-night/` (drop
`wallpaper.png` and its `WALLPAPER=` line in `theme.conf` if you don't
have one to bundle -- see `decay-green/`/`graphite-mono/` for that
pattern) to a new `dotfiles/hyde-themes/<name>/`, edit its color files
and `theme.conf`, re-run stage 5 (or just `cp -r` it into
`~/.config/hyde-themes/<name>/` directly) -- it'll show up in
`theme.sh list`/`menu` immediately, no other wiring needed.

Not covered by any of this: Qt/Kvantum theming for `kate`/`pavucontrol`
(no theme configures Kvantum, so Qt apps keep using your system Qt
style regardless of which theme is active), and the SDDM login theme
(shared across every theme on purpose -- see `global.conf` above).

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

Each of those files ships with a static fallback matching the default
theme (Tokyo Night -- see [Credits](#credits)) so things look right
before you've ever picked a wallpaper. Matugen overwrites them in place
once you do, for whichever theme happens to be active -- see [How this
interacts with Matugen](#theme-switching) above; `theme.sh set <name>`
restores the curated palette afterward.

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

- **`chsh: PAM: Authentication failure` at the end of stage 3** -- fixed
  as of this repo's current version (stage 3 now runs `chsh` through
  `sudo`, with `0-install.sh` granting it a scoped NOPASSWD rule so it
  doesn't need a password when running non-interactively). If you're
  still seeing it, you're likely on an older checkout -- `git pull` and
  re-run. The root cause: running the whole installer via `0-install.sh`
  as root executes stage 3 as `su - <user> -c ...`, which doesn't
  reliably keep a controlling terminal attached, so plain `chsh`'s PAM
  password prompt has nowhere to go and fails immediately.
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
  ends by running `theme.sh set tokyo-night`, which detects the
  installed theme folder under `/usr/share/...` (or `~/.local/share/...`)
  and prints what it found (falling back to `Adwaita` if nothing
  matched) before applying anything. If it printed `Adwaita` for
  something that should be installed, its stage 2/3 package install
  likely failed or was skipped -- re-run that stage, then
  `~/.config/hyde-themes/theme.sh set tokyo-night` (no need to
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
  `dotfiles/waybar/modules/tray-notif.jsonc` for what changed. The
  `modules-left`/`-center`/`-right` layout is now shaped to match
  [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE)'s own
  `Configs/.local/share/waybar/layouts/hyprdots/11.jsonc` (left=3 pills,
  center=1, right=3) -- HyDE's layout files only define pill *counts*,
  not which widgets fill them, so the module-to-pill mapping (app
  launcher/window-title/connections left; workspaces center; system
  monitor/controls/clock right) is this repo's own, picked to roughly
  match what's in HyDE's module catalog. See the comment at the top of
  `dotfiles/waybar/config.jsonc` for the full mapping. Colors are
  untouched by this repo's own theme.sh/Matugen pipeline regardless of
  which layout is in use. Two earlier revisions instead matched
  [00Darxk/dotfiles](https://github.com/00Darxk/dotfiles)'s waybar, and
  before that [Hyde-project/hyde](https://github.com/Hyde-project/hyde)'s
  own waybar (workspaces isolated on the far left); see that same comment
  for why HyDE's script-backed custom modules (weather, gpuinfo/cpuinfo/
  sensorsinfo, hyde-menu, etc.) weren't ported in any of the three.
- The keybind scheme in `dotfiles/hypr/hyprland.conf` is keyed to match
  [HyDE-Project/HyDE's KEYBINDINGS.md](https://github.com/HyDE-Project/HyDE/blob/master/KEYBINDINGS.md)
  wherever this repo has an equivalent app/dispatcher -- see the comment
  above the keybinds section for what wasn't ported and why.
- Tokyo Night's, Decay Green's, and Graphite Mono's GTK/icon theme
  archives, and Tokyo Night's color palette and bundled wallpaper
  ("Illustration by Sayybils", credited in-image), are from
  [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes)
  -- see [Theme switching](#theme-switching) for how `theme.sh` fetches
  them, and [Palette fidelity](#theme-switching) above for what is and
  isn't a verified port of that repo for Decay Green/Graphite Mono.
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
