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
    'gtop'                       # System monitoring via terminal
    'gufw'                       # Firewall manager
    'hardinfo'                   # Hardware info app
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
    'feh'                        # Image viewer
 
    # PRODUCTIVITY --------------------------------------------------------------
    'hunspell'                   # Spellcheck libraries
    'hunspell-en'                # English spellcheck library
    'libreoffice-still'          # LibreOffice
    'torbrowser-launcher'        # Tor Browser
 
    # THEMES -----------------------------------------------------------------------
    'breeze-gtk'                 # Breeze GTK theme
    'breeze-icons'               # Breeze GTK cursors
    'plasma-workspace'           # Ensures the above are usable
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
