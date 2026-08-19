#!/usr/bin/env bash
set -euo pipefail

#-------------------------------------------------------------------------
#   Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------
# Master runner: executes stages 1-6 with a single command.
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
bash "${SCRIPT_DIR}/2-system-software.sh"

echo
echo ">>> Stage 3: AUR software (running as ${AUR_USER})"
if [[ ${EUID} -eq 0 ]]; then
    # If you followed the README, this repo was cloned as root, which
    # almost always means SCRIPT_DIR is under /root -- mode 700, so a
    # non-root user can't even traverse into it to read the script.
    # Stage a throwaway copy inside the AUR user's own home directory
    # instead, owned by them, so the `su -` below always works regardless
    # of where the repo actually lives.
    AUR_USER_HOME="$(getent passwd "${AUR_USER}" | cut -d: -f6)"
    if [[ -z "${AUR_USER_HOME}" || ! -d "${AUR_USER_HOME}" ]]; then
        echo "Could not resolve a home directory for '${AUR_USER}'. Aborting."
        exit 1
    fi
    AUR_BUILD_DIR="${AUR_USER_HOME}/.linux-installation-stage3"

    rm -rf "${AUR_BUILD_DIR}"
    cp -r "${SCRIPT_DIR}" "${AUR_BUILD_DIR}"
    chown -R "${AUR_USER}:" "${AUR_BUILD_DIR}"

    # `su -c` below runs non-interactively and doesn't reliably keep a
    # controlling terminal attached, so if makepkg's internal `sudo pacman
    # -U` (when it installs a just-built AUR package) needs to prompt for a
    # password, it fails immediately with "a terminal is required to read
    # the password" -- even though the rest of this flow is interactive.
    # Grant NOPASSWD for pacman only, just for this user, just for stage 3,
    # so that install step never needs to prompt at all.
    AUR_SUDOERS_DROPIN="/etc/sudoers.d/99-linux-installation-aur-build"
    echo "${AUR_USER} ALL=(ALL) NOPASSWD: /usr/bin/pacman" > "${AUR_SUDOERS_DROPIN}"
    chmod 0440 "${AUR_SUDOERS_DROPIN}"
    if ! visudo -cf "${AUR_SUDOERS_DROPIN}"; then
        echo "Generated sudoers drop-in failed validation, aborting."
        rm -f "${AUR_SUDOERS_DROPIN}"
        exit 1
    fi
    trap 'rm -f "${AUR_SUDOERS_DROPIN}"' EXIT

    su - "${AUR_USER}" -c "bash '${AUR_BUILD_DIR}/3-user-software.sh'"

    rm -f "${AUR_SUDOERS_DROPIN}"
    trap - EXIT
    rm -rf "${AUR_BUILD_DIR}"
else
    bash "${SCRIPT_DIR}/3-user-software.sh"
fi

echo
echo ">>> Stage 4: Secure system"
if [[ ${EUID} -eq 0 ]]; then
    bash "${SCRIPT_DIR}/4-firewall.sh"
else
    sudo bash "${SCRIPT_DIR}/4-firewall.sh"
fi

echo
echo ">>> Stage 5: Deploy dotfiles (running as ${AUR_USER})"
if [[ ${EUID} -eq 0 ]]; then
    # Same /root permission problem as stage 3 above -- stage a throwaway
    # copy inside the AUR user's own home directory so `su -` can read it.
    AUR_USER_HOME="$(getent passwd "${AUR_USER}" | cut -d: -f6)"
    if [[ -z "${AUR_USER_HOME}" || ! -d "${AUR_USER_HOME}" ]]; then
        echo "Could not resolve a home directory for '${AUR_USER}'. Aborting."
        exit 1
    fi
    DOTFILES_BUILD_DIR="${AUR_USER_HOME}/.linux-installation-stage5"

    rm -rf "${DOTFILES_BUILD_DIR}"
    cp -r "${SCRIPT_DIR}" "${DOTFILES_BUILD_DIR}"
    chown -R "${AUR_USER}:" "${DOTFILES_BUILD_DIR}"

    su - "${AUR_USER}" -c "bash '${DOTFILES_BUILD_DIR}/5-dotfiles.sh'"

    rm -rf "${DOTFILES_BUILD_DIR}"
else
    bash "${SCRIPT_DIR}/5-dotfiles.sh"
fi

echo
echo ">>> Stage 6: Post setup"
bash "${SCRIPT_DIR}/6-post-setup.sh"

echo
echo "=== All stages complete ==="
