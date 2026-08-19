#!/usr/bin/env bash
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
    # --- WAYLAND CORE
    'wayland'                 # Core Wayland display server protocol libs
    'wayland-protocols'       # Additional/staging Wayland protocol extensions
    'xorg-xwayland'           # Runs X11-only apps inside a Wayland session
                               # (was 'xorg-server-xwayland' years ago; the
                               # current package name is 'xorg-xwayland')
    'mesa'                    # Open source OpenGL/Vulkan implementation --
                               # Hyprland renders through this directly via
                               # DRM/KMS, no separate xf86-video-* driver
                               # needed for AMD/Intel the way Xorg required
    # NOTE: no standalone 'wlroots' package here on purpose. Hyprland used
    # to be built on system wlroots, but as of 0.42 it ships its own
    # rendering backend ('aquamarine') instead and pulls it in automatically
    # as a dependency of the 'hyprland' package below -- there's nothing
    # separate to install for it.

    # --- Boot splash (Plymouth, requires GRUB as the bootloader)
    'plymouth'                 # Graphical boot splash daemon

    # --- Setup Desktop
    # (was 'plasma-meta' / KDE Plasma running on Xorg. Replaced with
    # Hyprland, a standalone Wayland compositor, plus the support packages
    # it needs -- these used to be pulled in transitively by plasma-meta.)
    'hyprland'                    # Wayland compositor / window manager
    'uwsm'                        # Universal Wayland Session Manager --
                                   # current recommended way to launch
                                   # Hyprland; wires the session into a
                                   # systemd graphical-session target, which
                                   # xdg-desktop-portal and friends expect
    'xdg-desktop-portal-hyprland'  # Portal backend for Hyprland (screen
                                    # share, screenshots, native file pickers)
    'xdg-desktop-portal-gtk'      # Fallback portal backend for GTK apps
                                   # (e.g. file-roller's, LibreOffice's file
                                   # picker dialogs)
    'qt5-wayland'                 # Wayland support for Qt5 apps
    'qt6-wayland'                 # Wayland support for Qt6 apps
    'hyprpolkitagent'             # GUI polkit auth-prompt agent -- with
                                   # Plasma gone there's nothing else
                                   # supplying one
    'hypridle'                    # Idle daemon (screen-off / lock / suspend
                                   # on timeout)
    'hyprlock'                    # Screen locker
    'swaybg'                      # Wallpaper daemon (wlroots-protocol based,
                                   # works under Hyprland the same as it does
                                   # under Sway)
 
    # --- Display / Login Manager
    # The 'hyprland' package ships wayland-sessions .desktop entries
    # automatically (a plain "Hyprland" entry, plus a "Hyprland
    # (uwsm-managed)" entry once uwsm is present), so SDDM picks it up with
    # nothing extra to configure. SDDM's own greeter still renders in X11
    # by default even when launching a Wayland session underneath -- that's
    # expected and doesn't affect the session you actually log into.
    'sddm'                    # Display manager (login screen)
 
    # --- Networking Setup
    'dialog'                  # Lets shell scripts trigger dialog boxes
    'networkmanager'          # Network connection manager
    'openvpn'                 # OpenVPN support
    'networkmanager-openvpn'  # OpenVPN plugin for NM
    'network-manager-applet'  # System tray network utility -- under Hyprland
                               # this needs a tray host to actually be
                               # visible; waybar's tray module (stage 2)
                               # covers that
    'dhclient'                # DHCP client
    'libsecret'               # Library for storing passwords
    'fail2ban'                # Ban IPs after repeated failed logins
    'ufw'                     # Uncomplicated firewall
    'proton-vpn-gtk-app'      # ProtonVPN client
 
    # --- Audio
    'alsa-utils'              # ALSA components
    'alsa-plugins'            # ALSA plugins
    'pipewire'                # Pipewire audio server
    'wireplumber'             # Pipewire's session/policy manager -- required
                               # for pipewire to actually route audio;
                               # pipewire-media-session (the old alternative)
                               # is deprecated
    'pipewire-pulse'          # PulseAudio-compatible server on top of
                               # pipewire, so Pulse-only apps keep working
    'pipewire-alsa'           # ALSA client support routed through pipewire
    # NOTE: 'pnmixer' used to be listed here but it's AUR-only -- a plain
    # `pacman -S pnmixer` always fails with "target not found". It's been
    # dropped from stage 3 too: it's a legacy GtkStatusIcon tray app, which
    # is one of the more unreliable tray-icon types under Wayland. Use
    # waybar's built-in pulseaudio module or the `pamixer` CLI instead
    # (both stage 2), or `pavucontrol` for a full GUI mixer.
 
    # --- Bluetooth
    'bluez'                   # Bluetooth protocol stack daemons
    'bluez-utils'             # Bluetooth development/debug utilities
    'bluez-libs'              # Bluetooth libraries
    # NOTE: 'bluez-firmware' used to be listed here but it was pulled from
    # the official repos years ago and no longer exists there. If your
    # Bluetooth chip needs firmware, check the AUR (e.g. broadcom-bt-firmware)
    # or see if it's already covered by the 'linux-firmware' package.
    # A GUI/tray manager ('blueman') is installed in stage 2, since Plasma
    # no longer provides one automatically.
)
 
echo "NOTE: a GPU driver is NOT installed automatically by this script."
echo "Wayland/Hyprland render through mesa using the kernel's own DRM/KMS"
echo "drivers, so AMD and Intel need nothing further -- mesa above already"
echo "covers them. Nvidia is the exception:"
echo "  AMD:    (mesa, already installed above, is enough)"
echo "  Intel:  (mesa, already installed above, is enough)"
echo "  Nvidia: sudo pacman -S nvidia-open nvidia-utils egl-wayland"
echo "          (use 'nvidia' instead of 'nvidia-open' on older/unsupported"
echo "          cards), then add 'nvidia_drm.modeset=1' to your kernel"
echo "          parameters -- see the Arch Wiki's Hyprland and NVIDIA pages."
echo
 
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    "${PACMAN[@]}" -S --noconfirm --needed "${PKG}"
done

if [[ ${EUID} -eq 0 ]]; then
    SUDO=()
else
    SUDO=(sudo)
fi

echo
echo "Configuring Plymouth boot splash"
if grep -q '\bplymouth\b' /etc/mkinitcpio.conf 2>/dev/null; then
    echo "plymouth hook already present in /etc/mkinitcpio.conf, skipping"
else
    # Plymouth needs to hook in before any hook that might print to the
    # console (e.g. 'block'/'filesystems'/'fsck'), and after 'udev' so
    # device nodes exist -- 'base udev ... ' is what a stock, freshly
    # installed mkinitcpio.conf starts with.
    "${SUDO[@]}" sed -i 's/^HOOKS=(base udev/HOOKS=(base udev plymouth/' /etc/mkinitcpio.conf
    if grep -q '\bplymouth\b' /etc/mkinitcpio.conf; then
        "${SUDO[@]}" mkinitcpio -P
    else
        echo "WARNING: could not find 'HOOKS=(base udev ...' in" >&2
        echo "/etc/mkinitcpio.conf to patch -- it's been customized from the" >&2
        echo "stock layout. Add 'plymouth' to the HOOKS array yourself (right" >&2
        echo "after 'udev') and run 'mkinitcpio -P'." >&2
    fi
fi

if command -v grub-mkconfig >/dev/null 2>&1 && [[ -f /etc/default/grub ]]; then
    if grep -q 'splash' /etc/default/grub; then
        echo "GRUB already has 'splash' on the kernel command line, skipping"
    else
        "${SUDO[@]}" sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 splash"/' /etc/default/grub
        "${SUDO[@]}" grub-mkconfig -o /boot/grub/grub.cfg
    fi
else
    echo "NOTE: GRUB not detected (no grub-mkconfig / /etc/default/grub) --"
    echo "Plymouth is installed but nothing added 'splash' to the kernel"
    echo "command line. If you're on a different bootloader (systemd-boot,"
    echo "rEFInd, etc.), add 'splash' (and optionally 'quiet') to its kernel"
    echo "parameters yourself -- see the Arch Wiki's Plymouth page."
fi

echo
echo "Done!"
echo
