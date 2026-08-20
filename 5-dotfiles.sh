#!/usr/bin/env bash
set -euo pipefail
#-------------------------------------------------------------------------
# Stage 5: Deploy dotfiles and activate the installed themes -- must run
# as a regular, non-root user (same constraint as stage 3), since it
# writes into that user's home directory. The one root-owned exception
# (SDDM's theme selection under /etc/sddm.conf.d) is done via sudo, inside
# theme.sh -- see below.
#-------------------------------------------------------------------------

echo
echo "DEPLOYING DOTFILES"
echo

if [[ ${EUID} -eq 0 ]]; then
    echo "This script must be run as a normal (non-root) user -- it deploys"
    echo "into that user's \$HOME."
    echo "Run: su <your-username>   then re-run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

if [[ ! -d "${DOTFILES_DIR}" ]]; then
    echo "ERROR: ${DOTFILES_DIR} not found -- can't deploy dotfiles." >&2
    exit 1
fi

# --- Copy a dotfiles subdirectory into ~/.config, backing up anything
# already there once (to *.bak) rather than silently overwriting it.
deploy_dir() {
    local name="$1"
    local src="${DOTFILES_DIR}/${name}"
    local dest="${HOME}/.config/${name}"

    if [[ -e "${dest}" || -L "${dest}" ]]; then
        # -L too: catches symlinks (e.g. from a dotfile manager), including
        # broken ones -e alone would miss. mv moves the link itself rather
        # than following it, so this never writes through to whatever a
        # symlink points at.
        echo "Backing up existing ~/.config/${name} -> ~/.config/${name}.bak"
        rm -rf "${dest}.bak"
        mv "${dest}" "${dest}.bak"
    fi
    mkdir -p "$(dirname "${dest}")"
    cp -r "${src}" "${dest}"
    echo "Deployed ~/.config/${name}"
}

for dir in hypr waybar alacritty wlogout eww nwg-dock-hyprland swaync matugen waypaper fastfetch rofi hyde-themes; do
    deploy_dir "${dir}"
done
chmod +x "${HOME}/.config/hyde-themes/theme.sh"

# --- gtk-3.0/gtk-4.0: only settings.ini is ours (theme.sh fills in the
# actual theme/icon/cursor names) -- deploy just that file rather than the
# whole directory via deploy_dir, so an existing ~/.config/gtk-*.0 with
# other GTK-managed files (bookmarks, gtkfilechooser.ini, ...) doesn't get
# moved aside wholesale.
for gtk_dir in gtk-3.0 gtk-4.0; do
    dest="${HOME}/.config/${gtk_dir}/settings.ini"
    mkdir -p "$(dirname "${dest}")"
    if [[ -e "${dest}" ]]; then
        echo "Backing up existing ~/.config/${gtk_dir}/settings.ini -> .bak"
        cp "${dest}" "${dest}.bak"
    fi
    cp "${DOTFILES_DIR}/${gtk_dir}/settings.ini" "${dest}"
    echo "Deployed ~/.config/${gtk_dir}/settings.ini"
done

# --- starship.toml is a flat file (starship's own default config path,
# unlike everything else here which lives in its own ~/.config subdir).
STARSHIP_DEST="${HOME}/.config/starship.toml"
if [[ -e "${STARSHIP_DEST}" || -L "${STARSHIP_DEST}" ]]; then
    echo "Backing up existing ~/.config/starship.toml -> ~/.config/starship.toml.bak"
    rm -f "${STARSHIP_DEST}.bak"
    mv "${STARSHIP_DEST}" "${STARSHIP_DEST}.bak"
fi
cp "${DOTFILES_DIR}/starship.toml" "${STARSHIP_DEST}"
echo "Deployed ~/.config/starship.toml"

# --- zshrc: append the plugin-sourcing snippet once, idempotently
ZSHRC="${HOME}/.zshrc"
MARKER=">>> linux-installation dotfiles (stage 5) >>>"
touch "${ZSHRC}"
if grep -qF "${MARKER}" "${ZSHRC}"; then
    echo "~/.zshrc already has the stage 5 block, skipping"
else
    echo "Appending zsh plugin config to ~/.zshrc"
    {
        echo
        cat "${DOTFILES_DIR}/zshrc-snippet.sh"
    } >> "${ZSHRC}"
fi

# --- Apply the default theme -- resolves/installs the GTK theme, icon
# theme, cursor theme, and SDDM theme (the last needs sudo -- see
# theme.sh), and deploys the color files every other app in this repo
# imports. Re-run `~/.config/hyde-themes/theme.sh menu` (or Super+Shift+T
# once you're in Hyprland) any time to switch to another theme -- see the
# README's theme switching section.
echo
"${HOME}/.config/hyde-themes/theme.sh" set catppuccin-mocha

echo
echo "Done!"
echo "Log out and back into the 'Hyprland (uwsm-managed)' session (or"
echo "restart Hyprland with 'hyprctl reload' from inside one) to pick up"
echo "the new config. Pick a wallpaper with 'waypaper' (or Super+Shift+W) --"
echo "until you do, Hyprland/Waybar/SwayNC/Alacritty stay on the current"
echo "theme's static palette."
echo "Want a different look? Super+Shift+T (or"
echo "'~/.config/hyde-themes/theme.sh menu') opens a theme picker -- see"
echo "the README's theme switching section."
echo "Got more than one monitor? Once you're logged into Hyprland, run"
echo "'./hypr-monitor-layout.sh' from this repo to lay them out interactively."
echo
