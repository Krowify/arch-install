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
    # (was 'kde-standard' -- that's a Debian/Kubuntu package name and
    # doesn't exist in Arch's repos. 'plasma-meta' is the correct Arch
    # equivalent.)
    'plasma-meta'             # KDE Plasma desktop
 
    # --- Display / Login Manager
    # NOTE: 'plasma-meta' does NOT pull sddm in automatically anymore.
    # Its own login-manager dependency is now 'plasma-login-manager'
    # (service name plasmalogin.service), and 'sddm-kcm' -- the package
    # that depends on sddm -- is only an OPTIONAL dependency of
    # plasma-meta, so it's never installed by --needed alone. Since
    # stage 3 installs an SDDM theme and stage 5 enables sddm.service,
    # sddm has to be installed explicitly here.
    'sddm'                    # Display manager (login screen)
 
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
    # NOTE: 'pnmixer' used to be listed here but it's AUR-only -- a plain
    # `pacman -S pnmixer` always fails with "target not found". It's
    # installed in stage 3 (AUR, via yay) instead.
 
    # --- Bluetooth
    'bluez'                   # Bluetooth protocol stack daemons
    'bluez-utils'             # Bluetooth development/debug utilities
    'bluez-libs'              # Bluetooth libraries
    # NOTE: 'bluez-firmware' used to be listed here but it was pulled from
    # the official repos years ago and no longer exists there. If your
    # Bluetooth chip needs firmware, check the AUR (e.g. broadcom-bt-firmware)
    # or see if it's already covered by the 'linux-firmware' package.
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
