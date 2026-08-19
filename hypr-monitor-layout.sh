#!/usr/bin/env bash
set -euo pipefail
#-------------------------------------------------------------------------
# Lays out a 3-monitor Hyprland setup:
#   - a vertical (portrait) monitor on the left
#   - the main monitor along the bottom, normal orientation
#   - a monitor above the main one, rotated 180 (upside down)
#
# Reads currently connected monitors from `hyprctl monitors`, lets you pick
# which physical monitor is which role, resets those three to their native
# untransformed mode (see NOTE below for why), applies the layout live via
# `hyprctl keyword monitor`, and saves it to ~/.config/hypr/monitors.conf
# so it survives a restart (source it from hyprland.conf -- see the note
# printed at the end).
#-------------------------------------------------------------------------

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "ERROR: hyprctl not found -- run this from inside a Hyprland session." >&2
    exit 1
fi

declare -a mon_names=()
declare -A mon_w=() mon_h=() mon_rate=()

# Populates mon_names/mon_w/mon_h/mon_rate from the CURRENT `hyprctl
# monitors` output. Only takes the first resolution line seen per monitor
# block, and tolerates either "144.00000 at" or "144.00Hz at" formatting
# for the refresh rate (this has changed across Hyprland versions).
read_monitors() {
    mon_names=()
    mon_w=(); mon_h=(); mon_rate=()
    local name=""
    while IFS= read -r line; do
        if [[ "${line}" =~ ^Monitor\ ([^[:space:]]+)\ \(ID\ [0-9]+\): ]]; then
            name="${BASH_REMATCH[1]}"
            mon_names+=("${name}")
        elif [[ -n "${name}" && "${line}" =~ ^[[:space:]]*([0-9]+)x([0-9]+)@([0-9.]+)(Hz)?\ at\ (-?[0-9]+)x(-?[0-9]+) ]]; then
            mon_w[${name}]="${BASH_REMATCH[1]}"
            mon_h[${name}]="${BASH_REMATCH[2]}"
            mon_rate[${name}]="${BASH_REMATCH[3]}"
            name=""
        fi
    done < <(hyprctl monitors)
}

read_monitors

if [[ ${#mon_names[@]} -lt 3 ]]; then
    echo "ERROR: only found ${#mon_names[@]} monitor(s) via hyprctl -- need 3." >&2
    exit 1
fi

echo "Detected monitors:"
for i in "${!mon_names[@]}"; do
    n="${mon_names[${i}]}"
    printf "  [%d] %-10s %sx%s@%s\n" "${i}" "${n}" "${mon_w[${n}]:-?}" "${mon_h[${n}]:-?}" "${mon_rate[${n}]:-?}"
done
echo

read -rp "Which number is the VERTICAL monitor (left side)? " V_IDX
read -rp "Which number is the MAIN monitor (bottom)? " B_IDX
read -rp "Which number is the UPSIDE-DOWN monitor (top)? " T_IDX

for n in "${V_IDX}" "${B_IDX}" "${T_IDX}"; do
    if ! [[ "${n}" =~ ^[0-9]+$ ]] || [[ "${n}" -ge ${#mon_names[@]} ]]; then
        echo "ERROR: '${n}' is not a valid monitor number." >&2
        exit 1
    fi
done
if [[ "${V_IDX}" == "${B_IDX}" || "${V_IDX}" == "${T_IDX}" || "${B_IDX}" == "${T_IDX}" ]]; then
    echo "ERROR: pick three different monitors." >&2
    exit 1
fi

echo
echo "Which way is the vertical monitor physically rotated?"
echo "  1) 90 clockwise   (top of the panel now faces right)  [default]"
echo "  2) 90 counter-clockwise / 270 (top of the panel now faces left)"
read -rp "Choice [1/2]: " ROT_CHOICE
VERT_TRANSFORM=1
[[ "${ROT_CHOICE:-1}" == "2" ]] && VERT_TRANSFORM=3

V_NAME="${mon_names[${V_IDX}]}"
B_NAME="${mon_names[${B_IDX}]}"
T_NAME="${mon_names[${T_IDX}]}"

# NOTE: `hyprctl monitors` reports whatever mode is CURRENTLY active, not
# necessarily the panel's native one -- if a transform is already applied
# (from a previous run of this script, or Hyprland's own auto-negotiation),
# the width/height it reports are already rotated. Computing a new
# transform on top of already-swapped dimensions rotates the picture a
# second time, and since the panel doesn't actually have a native mode at
# those swapped dimensions, Hyprland has to clamp/crop it -- this is the
# "half the monitor is unusable" failure mode. Force all three back to
# their native, untransformed mode first so the measurement below is
# always reliable, regardless of what state they were in before.
echo
echo "Resetting selected monitors to their native mode before measuring..."
hyprctl keyword monitor "${V_NAME},preferred,auto,1" >/dev/null
hyprctl keyword monitor "${B_NAME},preferred,auto,1" >/dev/null
hyprctl keyword monitor "${T_NAME},preferred,auto,1" >/dev/null
sleep 1
read_monitors

V_W="${mon_w[${V_NAME}]:-}"; V_H="${mon_h[${V_NAME}]:-}"; V_RATE="${mon_rate[${V_NAME}]:-}"
B_W="${mon_w[${B_NAME}]:-}"; B_H="${mon_h[${B_NAME}]:-}"; B_RATE="${mon_rate[${B_NAME}]:-}"
T_W="${mon_w[${T_NAME}]:-}"; T_H="${mon_h[${T_NAME}]:-}"; T_RATE="${mon_rate[${T_NAME}]:-}"

for pair in "V_W:${V_W}" "V_H:${V_H}" "B_W:${B_W}" "B_H:${B_H}" "T_W:${T_W}" "T_H:${T_H}"; do
    if [[ -z "${pair#*:}" ]]; then
        echo "ERROR: couldn't read a native resolution for one of the selected" >&2
        echo "monitors after resetting it (${pair%%:*} is empty). Run 'hyprctl" >&2
        echo "monitors' and check they're still connected/awake, then retry." >&2
        exit 1
    fi
done

# A 90/270 transform swaps the on-screen width/height; 180 (upside down)
# and 0 (normal) don't. These are native (pre-transform) dimensions --
# Hyprland's own resolution field in monitor= always wants the native
# mode, with transform applied on top, not the already-rotated size.
V_EFF_W=${V_H}

TOP_X=${V_EFF_W}
TOP_Y=0
BOTTOM_X=${V_EFF_W}
BOTTOM_Y=${T_H}

VERT_LINE="${V_NAME},${V_W}x${V_H}@${V_RATE},0x0,1,transform,${VERT_TRANSFORM}"
TOP_LINE="${T_NAME},${T_W}x${T_H}@${T_RATE},${TOP_X}x${TOP_Y},1,transform,2"
BOTTOM_LINE="${B_NAME},${B_W}x${B_H}@${B_RATE},${BOTTOM_X}x${BOTTOM_Y},1"

apply_monitor() {
    local line="$1" out
    echo "  monitor = ${line}"
    if ! out="$(hyprctl keyword monitor "${line}" 2>&1)"; then
        echo "    ERROR from hyprctl: ${out}" >&2
    elif [[ -n "${out}" && "${out}" != "ok" ]]; then
        echo "    hyprctl response: ${out}"
    fi
}

echo
echo "Applying:"
apply_monitor "${VERT_LINE}"
apply_monitor "${TOP_LINE}"
apply_monitor "${BOTTOM_LINE}"

CONF="${HOME}/.config/hypr/monitors.conf"
mkdir -p "$(dirname "${CONF}")"
{
    echo "# Generated by hypr-monitor-layout.sh"
    echo "# ${V_NAME}: vertical, left | ${B_NAME}: main, bottom | ${T_NAME}: upside-down, top"
    echo "monitor = ${VERT_LINE}"
    echo "monitor = ${TOP_LINE}"
    echo "monitor = ${BOTTOM_LINE}"
} > "${CONF}"

echo "Saved to ${CONF}"
echo
echo "To make this stick across restarts, add this to ~/.config/hypr/hyprland.conf"
echo "(and remove/comment out any other 'monitor =' line, e.g. the"
echo "'monitor = , preferred, auto, auto' one, so they don't conflict):"
echo
echo "  source = ~/.config/hypr/monitors.conf"
echo
echo "It's safe to re-run this script any time -- it always resets the"
echo "monitors you pick back to their native mode before measuring them,"
echo "so a previously-applied rotation won't throw off the numbers."
