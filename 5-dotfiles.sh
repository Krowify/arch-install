#!/usr/bin/env bash
set -euo pipefail
#-------------------------------------------------------------------------
# Stage 5: Deploy dotfiles and activate the installed themes -- must run
# as a regular, non-root user (same constraint as stage 3), since it
# writes into that user's home directory. The one root-owned exception
# (SDDM's theme selection under /etc/sddm.conf.d/) is done via sudo.
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

# --- Detect what actually got installed, instead of hardcoding a folder
# name that might not match (theme packages often ship several variants,
# and AUR packaging conventions drift over time).
detect_dir() {
    # $1 = search root, $2 = glob pattern (case-insensitive)
    local root="$1" pattern="$2" match
    match="$(find "${root}" -maxdepth 1 -iname "${pattern}" -printf '%f\n' 2>/dev/null | sort | head -n1)"
    echo "${match}"
}

GTK_THEME="$(detect_dir /usr/share/themes 'Catppuccin-Mocha-Standard-Mauve*')"
if [[ -z "${GTK_THEME}" ]]; then
    GTK_THEME="$(detect_dir /usr/share/themes 'Catppuccin-Mocha*')"
fi
ICON_THEME="$(detect_dir /usr/share/icons 'Papirus-Dark')"
if [[ -z "${ICON_THEME}" ]]; then
    ICON_THEME="$(detect_dir /usr/share/icons 'Papirus*')"
fi
CURSOR_THEME="$(detect_dir /usr/share/icons 'Bibata-Modern-Classic')"
if [[ -z "${CURSOR_THEME}" ]]; then
    CURSOR_THEME="$(detect_dir /usr/share/icons 'Bibata*')"
fi
SDDM_THEME="$(detect_dir /usr/share/sddm/themes 'elegant*')"

echo "Detected GTK theme:    ${GTK_THEME:-<not found>}"
echo "Detected icon theme:   ${ICON_THEME:-<not found>}"
echo "Detected cursor theme: ${CURSOR_THEME:-<not found>}"
echo "Detected SDDM theme:   ${SDDM_THEME:-<not found>}"
echo

if [[ -z "${GTK_THEME}" || -z "${ICON_THEME}" || -z "${CURSOR_THEME}" ]]; then
    echo "WARNING: one or more themes weren't found under /usr/share --"
    echo "did stages 2 and 3 finish successfully? Falling back to GTK/icon/"
    echo "cursor defaults for anything missing; re-run this script after"
    echo "fixing the underlying install to pick the real theme up."
fi
GTK_THEME="${GTK_THEME:-Adwaita}"
ICON_THEME="${ICON_THEME:-Adwaita}"
CURSOR_THEME="${CURSOR_THEME:-Adwaita}"

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

for dir in hypr waybar wofi mako alacritty wlogout eww; do
    deploy_dir "${dir}"
done

# --- Substitute the detected theme names into the deployed copies (never
# into the repo's own dotfiles/ source, which stays a clean template).
sed -i "s/__CURSOR_THEME__/${CURSOR_THEME}/g" "${HOME}/.config/hypr/hyprland.conf"

mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"
for gtk_dir in gtk-3.0 gtk-4.0; do
    dest="${HOME}/.config/${gtk_dir}/settings.ini"
    if [[ -e "${dest}" ]]; then
        echo "Backing up existing ~/.config/${gtk_dir}/settings.ini -> .bak"
        cp "${dest}" "${dest}.bak"
    fi
    cp "${DOTFILES_DIR}/${gtk_dir}/settings.ini" "${dest}"
    sed -i \
        -e "s/__GTK_THEME__/${GTK_THEME}/g" \
        -e "s/__ICON_THEME__/${ICON_THEME}/g" \
        -e "s/__CURSOR_THEME__/${CURSOR_THEME}/g" \
        "${dest}"
    echo "Deployed ~/.config/${gtk_dir}/settings.ini"
done

# --- Cursor theme for apps that read ~/.icons/default/index.theme instead
# of gtk settings (a lot of GTK2/Qt/legacy X11 apps do).
mkdir -p "${HOME}/.icons/default"
cat > "${HOME}/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=${CURSOR_THEME}
EOF
echo "Set ~/.icons/default -> ${CURSOR_THEME}"

# --- SDDM theme (root-owned, needs sudo)
if [[ -n "${SDDM_THEME}" ]]; then
    echo
    echo "Activating SDDM theme '${SDDM_THEME}' (needs sudo)"
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=%s\n' "${SDDM_THEME}" | sudo tee /etc/sddm.conf.d/10-theme.conf > /dev/null
else
    echo
    echo "WARNING: no SDDM theme found under /usr/share/sddm/themes --"
    echo "skipping SDDM theme activation. SDDM will keep using its"
    echo "built-in default theme."
fi

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

echo
echo "Done!"
echo "Log out and back into the 'Hyprland (uwsm-managed)' session (or"
echo "restart Hyprland with 'hyprctl reload' from inside one) to pick up"
echo "the new config. Swap the solid swaybg color for a real wallpaper by"
echo "editing the 'exec-once = swaybg' line in ~/.config/hypr/hyprland.conf."
echo
