#!/usr/bin/env bash
set -euo pipefail
#-------------------------------------------------------------------------
# Stage 3: AUR software -- must be run as a regular, non-root user
#-------------------------------------------------------------------------
 
echo
echo "INSTALLING AUR SOFTWARE"
echo
 
if [[ ${EUID} -eq 0 ]]; then
    echo "This script must be run as a normal (non-root) user -- makepkg"
    echo "refuses to build packages as root."
    echo "Run: su <your-username>   then re-run this script."
    exit 1
fi
 
# --- Install yay (AUR helper) if it isn't already present
if ! command -v yay >/dev/null 2>&1; then
    YAY_DIR="${HOME}/yay"
    if [[ -d "${YAY_DIR}" ]]; then
        echo "Existing ${YAY_DIR} found, updating instead of re-cloning"
        git -C "${YAY_DIR}" pull
        # Drop any build artifacts (src/, pkg/, old .pkg.tar.*) left over from a
        # prior run -- makepkg reusing these can produce a package pacman
        # refuses to install, which makepkg only reports as a non-fatal
        # "WARNING: Failed to install built package(s)." (it doesn't exit
        # non-zero), so a stale build silently slips past `set -e` here.
        git -C "${YAY_DIR}" clean -xdf
    else
        echo "CLONING: yay"
        git clone "https://aur.archlinux.org/yay-bin.git" "${YAY_DIR}"
    fi
    (cd "${YAY_DIR}" && makepkg -si --noconfirm)

    # makepkg's own install-failure warning above isn't fatal, so verify
    # yay actually landed on PATH instead of trusting its exit code.
    if ! command -v yay >/dev/null 2>&1; then
        echo "ERROR: yay build finished but 'yay' is not on PATH -- the" >&2
        echo "install step failed. Check the makepkg output above (a" >&2
        echo "'WARNING: Failed to install built package(s).' line is the" >&2
        echo "usual sign) and re-run this script." >&2
        exit 1
    fi
else
    echo "yay is already installed, skipping build"
fi
 
PKGS=(
    # UTILITIES -------------------------------------------------------
    'timeshift'                          # Backup and restore
    'autojump'                           # Zsh plugin
    # NOTE: 'pnmixer' used to be listed here as a tray volume control, but
    # it's a legacy GtkStatusIcon app -- one of the tray-icon types most
    # likely to not show up at all under a Wayland tray. Dropped in favor
    # of 'pamixer' (CLI) and 'pavucontrol' (GUI), both installed in stage 2.
    'hardinfo2-git'                      # Hardware info app (replacement for
                                          # 'hardinfo', removed from the official
                                          # repos -- moved here from stage 2)
    'paru-bin'                           # Second AUR helper/pacman wrapper,
                                          # alongside yay above -- prebuilt so
                                          # it doesn't need a Rust toolchain

    # BROWSERS / COMMUNICATIONS ------------------------------------------
    'brave-bin'                          # Brave browser
    'discord'                            # Chat for gamers
    'vencord-installer'                  # Discord client mod installer

    # EDITORS ---------------------------------------------------------------
    'visual-studio-code-bin'             # VS Code (not in official repos)

    # WAYLAND / HYPRLAND DESKTOP ------------------------------------------
    'eww-wayland'                        # Widget system (Wayland-only build --
                                          # plain 'eww' also pulls in the X11
                                          # backend, which this Wayland-only
                                          # setup doesn't need)

    # THEMES -----------------------------------------------------------------
    # This only themes the SDDM login screen itself, independent of the
    # Hyprland session you log into afterward -- it doesn't need Plasma and
    # nothing above changes how it works.
    'sddm-theme-elegant-archlinux-git'   # SDDM login theme
    'catppuccin-gtk-theme-mocha'         # GTK app theme (Catppuccin, Mocha
                                          # flavor -- see the AUR for the
                                          # Latte/Frappe/Macchiato variants)
    'bibata-cursor-theme-bin'            # Cursor theme, prebuilt

    # HARDWARE -----------------------------------------------------------------
           # Proton Mail Application
    'obsidian'                           # Obsidean Note Taking
)
 
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    yay -S --noconfirm --needed "${PKG}"
done
 
# --- Change default shell to zsh
echo
echo "Changing default shell to zsh"
chsh -s "$(command -v zsh)"
 
echo
echo "Done!"
echo
