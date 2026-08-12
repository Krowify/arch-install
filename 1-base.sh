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
# Stage 1: Base system, display server, desktop, networking, audio, bluetooth
#-------------------------------------------------------------------------
 
echo
echo "Installing Base System"
echo
 
# Works whether this is run as root (typical right after a fresh Arch
# install) or as a regular user that already has sudo configured.
if [[ ${EUID} -eq 0 ]]; then
    PACMAN=(pacman)
else
    PACMAN=(sudo pacman)
fi
 
# Make sure sudo itself exists before later stages rely on it.
"${PACMAN[@]}" -S --noconfirm --needed sudo
 
PKGS=(
    # --- XORG Display Rendering
    'xorg'                    # Base package
    'xorg-drivers'            # Display drivers
    'xterm'                   # Terminal for TTY
    'xorg-server'             # Xorg server
    'xorg-apps'               # Xorg apps group
    'xorg-xinit'              # Xorg init
    'xorg-xinput'             # Xorg xinput
    'mesa'                    # Open source OpenGL implementation
 
    # --- Setup Desktop
    'kde-standard'            # KDE Plasma desktop
 
    # --- Networking Setup
    'dialog'                  # Lets shell scripts trigger dialog boxes
    'networkmanager'          # Network connection manager
    'openvpn'                 # OpenVPN support
    'networkmanager-openvpn'  # OpenVPN plugin for NM
    'network-manager-applet'  # System tray network utility
    'dhclient'                # DHCP client
    'libsecret'               # Library for storing passwords
    'fail2ban'                # Ban IPs after repeated failed logins
    'ufw'                     # Uncomplicated firewall
    'proton-vpn-gtk-app'      # ProtonVPN client
 
    # --- Audio
    'alsa-utils'              # ALSA components
    'alsa-plugins'            # ALSA plugins
    'pipewire'                # Pipewire audio server
    'pnmixer'                 # System tray volume control
 
    # --- Bluetooth
    'bluez'                   # Bluetooth protocol stack daemons
    'bluez-utils'             # Bluetooth development/debug utilities
    'bluez-libs'              # Bluetooth libraries
    'bluez-firmware'          # Firmware for common Bluetooth chips
    'blueberry'               # Bluetooth configuration tool
)
 
echo "NOTE: a GPU driver is NOT installed automatically by this script,"
echo "since the previous hardcoded 'xf86-video-amdgpu' only applies to"
echo "AMD hardware. Install the package matching your GPU separately,"
echo "e.g.:"
echo "  AMD:    sudo pacman -S xf86-video-amdgpu"
echo "  Intel:  sudo pacman -S xf86-video-intel  (or use mesa's modesetting)"
echo "  Nvidia: sudo pacman -S nvidia nvidia-utils"
echo
 
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    "${PACMAN[@]}" -S --noconfirm --needed "${PKG}"
done
 
echo
echo "Done!"
echo
 
