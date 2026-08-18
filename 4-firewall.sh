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
 
# --- openssh: fail2ban's [sshd] jail below is meaningless without an
# actual sshd running to generate auth logs, and nothing else in these
# scripts installs it.
echo "Installing openssh"
pacman -S --noconfirm --needed openssh
systemctl enable --now sshd.service
 
# --- Firewall rules
# Default-deny everything inbound, then open only what's needed. SSH is
# allowed via `limit` rather than `allow`, which rate-limits repeat
# connection attempts from the same IP (roughly 6 within 30s trigger a
# temporary deny) -- this blunts brute-force attempts at the firewall
# level, on top of the bans fail2ban applies further down. Set defaults
# and rules BEFORE enabling, and run sequentially (not backgrounded) so
# ordering is guaranteed and the script doesn't exit before ufw finishes
# applying them. --force skips the interactive y/n prompt that would
# otherwise hang a non-interactive/backgrounded run.
echo "Configuring ufw"
ufw default deny incoming
ufw default allow outgoing
ufw logging on
ufw limit 22/tcp comment 'SSH (rate-limited)'
# This is a desktop firewall, so everything else inbound stays closed by
# default. If you're running a local web server and need it reachable
# from other machines on your network, uncomment as needed:
#   ufw allow 80/tcp
#   ufw allow 443/tcp
ufw --force enable
systemctl enable --now ufw
 
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
