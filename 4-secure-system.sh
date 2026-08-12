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
# Stage 4: Firewall, sysctl hardening, fail2ban -- must run as root
#-------------------------------------------------------------------------
 
if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi
 
echo "-------------------------------------------------"
echo "Secure Linux"
echo "-------------------------------------------------"
 
# --- Firewall rules
# Set defaults and rules BEFORE enabling, and run sequentially (not
# backgrounded) so ordering is guaranteed and the script doesn't exit
# before ufw finishes applying them. --force skips the interactive
# y/n prompt that would otherwise hang a non-interactive/backgrounded run.
echo "Configuring ufw"
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp
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
 
