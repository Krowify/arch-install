# linux-installation

This repo installs and configures a fully-functional Arch Linux setup:
a desktop environment, support packages (network, bluetooth, audio,
etc.), a firewall/hardening pass, and a set of preferred applications.

## Arch Linux First Boot

Run as **root**, right after a base Arch install:

```sh
pacman -S --noconfirm pacman-contrib curl git
git clone https://github.com/Krowify/linux-installation
cd linux-installation
bash 0-install.sh
```

`0-install.sh` runs all five stages with a single command. AUR builds
(stage 3) can't run as root -- `makepkg` refuses -- so the script
handles that switch for you:

- If you're running it as **root**, it asks for a username to use for
  the AUR stage, offers to create the account if it doesn't exist yet,
  then automatically drops into that user (`su -`) for stage 3 and
  switches back to root afterward.
- If you're already running it as a **regular user with sudo**, it
  just uses your current account for stage 3 and calls `sudo` where
  needed for the rest.

Expect a few interactive prompts along the way (root/sudo password,
account creation if applicable, `makepkg` confirmations) -- that's
intentional so nothing installs or creates accounts silently.

| Stage | Script                  | Runs as                     | Purpose                                                |
|-------|--------------------------|------------------------------|----------------------------------------------------------|
| 0     | `0-install.sh`           | root or sudo user           | Master runner -- executes all stages below in order       |
| 1     | `1-base.sh`              | root                         | Xorg, KDE Plasma, networking, audio, bluetooth            |
| 2     | `2-software-pacman.sh`   | root                         | Everyday software from the official repos                 |
| 3     | `3-software-aur.sh`      | non-root (handled by 0-install.sh) | AUR packages via `yay` (VS Code, Discord, themes, etc.)|
| 4     | `4-secure-system.sh`     | root                         | Firewall, sysctl hardening, fail2ban                       |
| 5     | `5-post-setup.sh`        | root                         | File watcher limit, display manager, bluetooth autostart   |

All scripts use `set -euo pipefail`, so they stop on the first error
instead of silently continuing with a partially-configured system.

## Running stages manually (optional)

If you'd rather step through each stage yourself instead of using
`0-install.sh`, you can still run them individually:

```sh
sh 1-base.sh
sh 2-software-pacman.sh

su <your-username>
sh 3-software-aur.sh

su
sh 4-secure-system.sh
sh 5-post-setup.sh
```

## System Description

This runs KDE Plasma and installs known drivers and applications for a
quick, consistent Linux setup. It also configures the firewall and
other services expected to be running at startup.

## Troubleshooting

- **Stage 3 exits immediately** (running it manually) -- you're
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
- **GPU driver** -- stage 1 doesn't assume AMD. Install the driver
  package matching your hardware separately (the script prints a
  reminder, or see the Arch Wiki page for your GPU).

Arch Linux Installation Guide: https://wiki.archlinux.org/title/Installation_guide
