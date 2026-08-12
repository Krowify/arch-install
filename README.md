# krow-linux-applications

This README contains the steps to install and configure a fully-functional
Arch Linux installation containing a desktop environment, all the support
packages (network, bluetooth, audio, etc.), along with a set of preferred
applications and utilities.

## Arch Linux First Boot

Run as **root**, right after a base Arch install:

```sh
pacman -S --noconfirm pacman-contrib curl git
git clone https://github.com/Krowify/krow-linux-applications
cd krow-setup

sh 1-base.sh
sh 2-software-pacman.sh
```

Stage 3 installs AUR packages, which requires a **non-root** user
(`makepkg` refuses to build as root):

```sh
su <your-username>
sh 3-software-aur.sh
```

Switch back to root for the remaining stages:

```sh
su
sh 4-secure-system.sh
sh 5-post-setup.sh
```

| Stage | Script                  | Run as     | Purpose                                              |
|-------|--------------------------|------------|-------------------------------------------------------|
| 1     | `1-base.sh`              | root       | Xorg, KDE Plasma, networking, audio, bluetooth        |
| 2     | `2-software-pacman.sh`   | root       | Everyday software from the official repos             |
| 3     | `3-software-aur.sh`      | non-root   | AUR packages via `yay` (VS Code, Discord, themes, etc.)|
| 4     | `4-secure-system.sh`     | root       | Firewall, sysctl hardening, fail2ban                  |
| 5     | `5-post-setup.sh`        | root       | File watcher limit, display manager, bluetooth autostart |

All scripts use `set -euo pipefail`, so they stop on the first error
instead of silently continuing with a partially-configured system.

## System Description

This runs KDE Plasma and installs known drivers and applications for a
quick, consistent Linux setup. It also configures the firewall and other
services expected to be running at startup.

## Troubleshooting

- **Stage 3 exits immediately** — you're running it as root. Switch to a
  regular user first (`su <your-username>`) and re-run it.
- **`sudo: command not found` in stage 1 or 2** — this shouldn't happen
  anymore; stage 1 installs `sudo` itself before using it. If you still
  hit this, make sure you're running stage 1 first and as root.
- **A package fails to install** — the script will stop at that line
  (rather than skipping past it). Check the package name is still current
  for your mirrors, then re-run the script; already-installed packages
  are skipped via `--needed`.
- **GPU driver** — stage 1 no longer assumes AMD. Install the driver
  package that matches your hardware separately (see the note the script
  prints, or the Arch Wiki page for your GPU).

Arch Linux Installation Guide: https://wiki.archlinux.org/title/Installation_guide
