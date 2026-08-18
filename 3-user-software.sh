#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------
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
    else
        echo "CLONING: yay"
        git clone "https://aur.archlinux.org/yay.git" "${YAY_DIR}"
    fi
    (cd "${YAY_DIR}" && makepkg -si --noconfirm)
else
    echo "yay is already installed, skipping build"
fi
 
PKGS=(
    # UTILITIES -------------------------------------------------------
    'timeshift'                          # Backup and restore
    'autojump'                           # Zsh plugin
    'pnmixer'                            # System tray volume control (AUR-only,
                                          # moved here from stage 1)
    'hardinfo2-git'                      # Hardware info app (replacement for
                                          # 'hardinfo', removed from the official
                                          # repos -- moved here from stage 2)
 
    # BROWSERS / COMMUNICATIONS ------------------------------------------
    'brave-bin'                          # Brave browser
    'discord'                            # Chat for gamers
    'vencord-installer'                  # Discord client mod installer
 
    # EDITORS ---------------------------------------------------------------
    'visual-studio-code-bin'             # VS Code (not in official repos)
 
    # THEMES -----------------------------------------------------------------
    'sddm-theme-elegant-archlinux-git'   # SDDM login theme
 
    # HARDWARE -----------------------------------------------------------------
    
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
