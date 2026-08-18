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
# Stage 2: Everyday software from the official repositories
#-------------------------------------------------------------------------
 
echo
echo "INSTALLING SOFTWARE"
echo
 
if [[ ${EUID} -eq 0 ]]; then
    PACMAN=(pacman)
else
    PACMAN=(sudo pacman)
fi
 
PKGS=(
    # SYSTEM ----------------------------------------------------------
    'linux-lts'                # Long term support kernel
    'base-devel'                # Needed to build AUR packages in stage 3
 
    # TERMINAL UTILITIES ------------------------------------------------
    'bleachbit'                  # File deletion utility
    'cmatrix'                    # The Matrix screen animation
    'cronie'                     # cron jobs
    'curl'                       # Remote content retrieval
    'file-roller'                # Archive utility
    'gufw'                       # Firewall manager
    # NOTE: 'hardinfo' used to be listed here but it was pulled from the
    # official repos -- a plain `pacman -S hardinfo` fails with "target
    # not found". Its replacement, 'hardinfo2', isn't reliably in the
    # stable 'extra' repo yet at the time of writing (it's been sitting
    # in extra-testing), so it's installed via AUR in stage 3 instead.
    'htop'                       # Process viewer
    'ntp'                        # Network Time Protocol
    'p7zip'                      # 7z compression program
    'rsync'                      # Remote file sync utility
    'speedtest-cli'              # Internet speed via terminal
    'unrar'                      # RAR compression program
    'unzip'                      # Zip compression program
    'wget'                       # Remote content retrieval
    'vim'                        # Terminal editor
    'zenity'                     # Graphical dialog boxes from shell scripts
    'zsh'                        # Interactive shell
    'zsh-autosuggestions'        # Zsh plugin
    'zsh-syntax-highlighting'    # Zsh plugin
 
    # GENERAL UTILITIES --------------------------------------------------
    'clamav'                     # Anti-virus
 
    # DEVELOPMENT ----------------------------------------------------------
    'cmake'                      # Cross-platform open-source make system
    'electron'                   # Cross-platform development using JS
    'git'                        # Version control system
    'gcc'                        # C/C++ compiler
    'glibc'                      # C libraries
    'meld'                       # File/directory comparison
    'nodejs'                     # JavaScript runtime environment
    'npm'                        # Node package manager
    'python'                     # Scripting language
    'yarn'                       # Dependency management
 
    # MEDIA -----------------------------------------------------------------
    'celluloid'                  # Video player
    'feh'                        # Image viewer (X11-native, runs fine via
                                  # the xorg-xwayland installed in stage 1)
 
    # PRODUCTIVITY --------------------------------------------------------------
    'libreoffice-still'          # LibreOffice
    'torbrowser-launcher'        # Tor Browser
 
    # WAYLAND / HYPRLAND DESKTOP ---------------------------------------------
    # (was THEMES: 'breeze-gtk' / 'breeze-icons' / 'plasma-workspace'. Those
    # needed plasma-workspace's KDE config modules to actually apply, which
    # no longer makes sense without Plasma. Replaced with a DE-agnostic
    # icon theme plus the bar/launcher/notification/tray stack Hyprland
    # doesn't provide on its own -- KDE Plasma used to supply all of this.)
    'waybar'                      # Status bar
    'wofi'                        # Application launcher (Wayland-native)
    'mako'                        # Notification daemon (Wayland-native)
    'grim'                        # Screenshot utility
    'slurp'                       # Region/window selector, used with grim
    'wl-clipboard'                # Wayland clipboard CLI (wl-copy/wl-paste)
    'brightnessctl'               # Screen brightness control
    'pamixer'                     # CLI volume control (pipewire-pulse aware)
    'pavucontrol'                 # GUI volume mixer, invoked directly rather
                                   # than via a tray icon
    'kitty'                       # Terminal emulator, replaces 'xterm'
    'blueman'                     # Bluetooth GUI manager + tray applet --
                                   # Plasma no longer supplies one
    'papirus-icon-theme'          # Icon theme (works standalone, no KDE
                                   # config modules required)
    'ttf-nerd-fonts-symbols'      # Icon glyphs most waybar/wofi configs
                                   # assume are available
)
 
echo "NOTE: 'code' (VS Code) has been removed from this list -- it is not"
echo "available in the official Arch repos. It's installed from the AUR"
echo "instead in stage 3 (visual-studio-code-bin)."
echo
 
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    "${PACMAN[@]}" -S --noconfirm --needed "${PKG}"
done
 
echo
echo "Done!"
echo
