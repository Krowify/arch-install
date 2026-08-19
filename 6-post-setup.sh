#!/usr/bin/env bash
set -euo pipefail
#-------------------------------------------------------------------------
# Stage 6: Final setup and configuration
#-------------------------------------------------------------------------
 
if [[ ${EUID} -eq 0 ]]; then
    SUDO=()
else
    SUDO=(sudo)
fi
 
echo
echo "FINAL SETUP AND CONFIGURATION"
 
# ------------------------------------------------------------------------
echo
echo "Increasing file watcher count"
echo "(prevents a 'too many files' error in editors like VS Code)"
echo "fs.inotify.max_user_watches=524288" | "${SUDO[@]}" tee /etc/sysctl.d/40-max-user-watches.conf > /dev/null
"${SUDO[@]}" sysctl --system
 
# ------------------------------------------------------------------------
echo
echo "Enabling login display manager"
"${SUDO[@]}" systemctl enable --now sddm.service
echo "NOTE: at the SDDM login screen, pick 'Hyprland (uwsm-managed)' from"
echo "the session dropdown if it's offered -- that's the currently"
echo "recommended way to launch it. A plain 'Hyprland' entry is also"
echo "available if you'd rather not use uwsm."
echo
echo "NOTE: pipewire/wireplumber run as user (not system) services and are"
echo "generally auto-started on login via socket activation. If audio isn't"
echo "working after your first login, check with:"
echo "  systemctl --user status pipewire wireplumber pipewire-pulse"
echo "and enable them yourself if needed:"
echo "  systemctl --user enable --now pipewire wireplumber pipewire-pulse"
 
# ------------------------------------------------------------------------
echo
echo "Enabling bluetooth daemon and setting it to auto-start"
if [[ -f /etc/bluetooth/main.conf ]]; then
    "${SUDO[@]}" sed -i 's|#AutoEnable=false|AutoEnable=true|g' /etc/bluetooth/main.conf
else
    # bluez normally ships this file -- if it's missing (partial/odd
    # install), don't let that abort the rest of this stage (Plymouth/
    # GRUB, Nvidia) under set -e. bluetooth.service still starts fine
    # with default settings; it just won't auto-power-on adapters.
    echo "WARNING: /etc/bluetooth/main.conf not found -- skipping the" >&2
    echo "AutoEnable tweak. Enabling bluetooth.service anyway." >&2
fi
"${SUDO[@]}" systemctl enable --now bluetooth.service

# ------------------------------------------------------------------------
# Plymouth boot splash wiring (mkinitcpio hook + GRUB kernel param). This
# runs here, as the last root-level stage, rather than in stage 1, so it
# always sees the final set of installed kernels/packages instead of
# depending on install ordering within stages 1-2.
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

GRUB_PARAMS_TO_ADD=()
if command -v grub-mkconfig >/dev/null 2>&1 && [[ -f /etc/default/grub ]]; then
    if grep -q 'splash' /etc/default/grub; then
        echo "GRUB already has 'splash' on the kernel command line, skipping"
    else
        GRUB_PARAMS_TO_ADD+=('splash')
    fi
else
    echo "NOTE: GRUB not detected (no grub-mkconfig / /etc/default/grub) --"
    echo "Plymouth is installed but nothing added 'splash' to the kernel"
    echo "command line. If you're on a different bootloader (systemd-boot,"
    echo "rEFInd, etc.), add 'splash' (and optionally 'quiet') to its kernel"
    echo "parameters yourself -- see the Arch Wiki's Plymouth page."
fi

# ------------------------------------------------------------------------
# Nvidia kernel parameter -- only if stage 1's GPU prompt actually
# installed the Nvidia driver (checked here, rather than passed in from
# stage 1, since each numbered stage runs as its own process).
echo
echo "Checking for an installed Nvidia driver"
if pacman -Qq nvidia-open &>/dev/null || pacman -Qq nvidia &>/dev/null; then
    echo "Nvidia driver detected"
    if command -v grub-mkconfig >/dev/null 2>&1 && [[ -f /etc/default/grub ]]; then
        if grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
            echo "GRUB already has 'nvidia_drm.modeset=1', skipping"
        else
            GRUB_PARAMS_TO_ADD+=('nvidia_drm.modeset=1')
        fi
    else
        echo "NOTE: GRUB not detected -- add 'nvidia_drm.modeset=1' to your"
        echo "bootloader's kernel parameters yourself."
    fi
else
    echo "No Nvidia driver installed, nothing to do"
fi

if [[ ${#GRUB_PARAMS_TO_ADD[@]} -gt 0 ]]; then
    "${SUDO[@]}" sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"/\1 ${GRUB_PARAMS_TO_ADD[*]}\"/" /etc/default/grub
    "${SUDO[@]}" grub-mkconfig -o /boot/grub/grub.cfg
fi

# ------------------------------------------------------------------------
echo "
###############################################################################
# Done
###############################################################################
"
