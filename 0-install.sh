#!/usr/bin/env bash
set -euo pipefail

#-------------------------------------------------------------------------
#   Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------
# Master runner: executes stages 1-5 with a single command.
#
# Stage 3 (AUR builds) must run as a non-root user -- makepkg refuses to
# build packages as root. This script handles that switch internally via
# `su - <user> -c ...` so you don't have to manually re-invoke anything.
#-------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Arch Linux Setup: running all stages ==="
echo

if [[ ${EUID} -eq 0 ]]; then
    # Running as root -- need a non-root user on hand for stage 3.
    read -rp "Username to use for stage 3 (AUR builds): " AUR_USER

    if ! id "${AUR_USER}" &>/dev/null; then
        echo "User '${AUR_USER}' does not exist."
        read -rp "Create it now? [y/N] " CREATE_USER
        if [[ "${CREATE_USER,,}" == "y" ]]; then
            useradd -m -G wheel "${AUR_USER}"
            echo "Set a password for ${AUR_USER}:"
            passwd "${AUR_USER}"
            # Make sure the wheel group can actually sudo
            if grep -q '^# %wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
                sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
            fi
        else
            echo "A non-root user is required for stage 3. Exiting."
            exit 1
        fi
    fi
else
    # Already running as a regular user -- use ourselves for stage 3.
    AUR_USER="${USER}"
fi

echo
echo ">>> Stage 1: Base system"
bash "${SCRIPT_DIR}/1-base.sh"

echo
echo ">>> Stage 2: Software (pacman)"
bash "${SCRIPT_DIR}/2-software-pacman.sh"

echo
echo ">>> Stage 3: AUR software (running as ${AUR_USER})"
if [[ ${EUID} -eq 0 ]]; then
    su - "${AUR_USER}" -c "bash '${SCRIPT_DIR}/3-software-aur.sh'"
else
    bash "${SCRIPT_DIR}/3-software-aur.sh"
fi

echo
echo ">>> Stage 4: Secure system"
if [[ ${EUID} -eq 0 ]]; then
    bash "${SCRIPT_DIR}/4-secure-system.sh"
else
    sudo bash "${SCRIPT_DIR}/4-secure-system.sh"
fi

echo
echo ">>> Stage 5: Post setup"
bash "${SCRIPT_DIR}/5-post-setup.sh"

echo
echo "=== All stages complete ==="
