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
# Stage 5: Final setup and configuration
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
"${SUDO[@]}" sed -i 's|#AutoEnable=false|AutoEnable=true|g' /etc/bluetooth/main.conf
"${SUDO[@]}" systemctl enable --now bluetooth.service
 
# ------------------------------------------------------------------------
echo "
###############################################################################
# Done
###############################################################################
"
