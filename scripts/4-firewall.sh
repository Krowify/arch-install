#!/usr/bin/env bash

set -euo pipefail
#-------------------------------------------------------------------------
# Stage 4: Firewall, sysctl hardening, fail2ban -- must run as root
#-------------------------------------------------------------------------
 
if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi
 
echo "-------------------------------------------------"
echo "Secure Linux"
echo "-------------------------------------------------"
 
# --- openssh: install the binaries either way (harmless -- it's not
# listening on anything until the service is actually started), but only
# enable+start the daemon, and only open port 22 in the firewall, if you
# actually want remote access. The lowest-risk open port on a desktop
# machine is the one that was never opened -- rate-limiting and fail2ban
# (further down) reduce SSH's exposure, but they don't beat not exposing
# it at all if you're not going to use it.
echo "Installing openssh"
pacman -S --noconfirm --needed openssh

read -rp "Enable and start the SSH server now? [y/N] " ENABLE_SSH
if [[ "${ENABLE_SSH,,}" == "y" ]]; then
    ENABLE_SSH=true
    systemctl enable --now sshd.service
else
    ENABLE_SSH=false
    echo "Leaving sshd installed but disabled. Enable it later with:"
    echo "  sudo systemctl enable --now sshd.service"
    echo "  sudo ufw limit 22/tcp comment 'SSH (rate-limited)'"
fi

# --- Firewall rules
# Default-deny everything inbound, then open only what's needed. SSH (if
# enabled above) is allowed via `limit` rather than `allow`, which
# rate-limits repeat connection attempts from the same IP (roughly 6
# within 30s trigger a temporary deny) -- this blunts brute-force attempts
# at the firewall level, on top of the bans fail2ban applies further down.
# Set defaults and rules BEFORE enabling, and run sequentially (not
# backgrounded) so ordering is guaranteed and the script doesn't exit
# before ufw finishes applying them. --force skips the interactive y/n
# prompt that would otherwise hang a non-interactive/backgrounded run.
echo "Configuring ufw"
ufw default deny incoming
ufw default allow outgoing
ufw logging on
if [[ "${ENABLE_SSH}" == true ]]; then
    ufw limit 22/tcp comment 'SSH (rate-limited)'
fi
# This is a desktop firewall, so everything else inbound stays closed by
# default. If you're running a local web server and need it reachable
# from other machines on your network, uncomment as needed:
#   ufw allow 80/tcp
#   ufw allow 443/tcp
ufw --force enable
systemctl enable --now ufw

# --- IPv6 sanity check: 'ufw default deny incoming' above only actually
# covers IPv6 if ufw itself has IPv6 handling turned on. It's the Arch
# package default, but if something (you, a config-management tool, a
# previous install) flipped it off, the deny-incoming policy would be
# silently IPv4-only while IPv6 stayed wide open -- worth failing loudly
# on rather than assuming.
if grep -qx 'IPV6=yes' /etc/default/ufw 2>/dev/null; then
    echo "ufw IPv6 support confirmed enabled (/etc/default/ufw: IPV6=yes)"
else
    echo "WARNING: /etc/default/ufw does not have 'IPV6=yes' -- the rules" >&2
    echo "above are only being enforced for IPv4. Set IPV6=yes in that" >&2
    echo "file and run 'ufw disable && ufw enable' to also cover IPv6." >&2
fi
 
# --- Persist sysctl hardening to a drop-in file (not just a live-only value)
echo "Writing sysctl hardening rules"
cat <<'EOF' > /etc/sysctl.d/90-hardening.conf
# Enable source route verification (anti IP-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
 
# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
 
# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1
 
# Log packets with impossible addresses (martians)
net.ipv4.conf.all.log_martians = 1
EOF
sysctl --system
 
# NOTE: kernel.modules_disabled=1 is intentionally left out. It blocks
# loading of ANY further kernel modules for the rest of the boot session,
# with no exceptions -- applying it mid-setup can silently break Wi-Fi,
# Bluetooth, or other hardware whose driver modules haven't loaded yet.
# If you want it, set it from a systemd unit that runs late in boot,
# after confirming every driver you need is already loaded.
 
# --- Prevent IP spoofing via /etc/host.conf
echo "Writing /etc/host.conf"
cat <<EOF > /etc/host.conf
order bind,hosts
multi on
EOF

# NOTE: the [sshd] jail below is configured regardless of whether SSH
# was enabled above -- it's inert (nothing to scan) until sshd is
# actually running and generating auth logs, and having it ready means
# turning SSH on later is a two-command job (see the message above) with
# no need to re-run this stage. If you open up another service later
# (VNC, a web app, etc.), follow the same pattern: a rate-limited ufw
# rule AND a matching fail2ban jail, not just 'ufw allow'.
echo "Configuring fail2ban"
mkdir -p /etc/fail2ban
cat <<'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
EOF
systemctl enable --now fail2ban
 
echo
echo "Done!"
echo
