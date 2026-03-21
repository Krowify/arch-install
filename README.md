# krow-linux-applications
This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a desktop environment, all the support packages (network, bluetooth, audio, etc.), along with all my preferred applications and utilities. 

Arch Linux First Boot
```
pacman -S --noconfirm pacman-contrib curl git
git clone https://github.com/Krowify/krow-linux-applications
cd Arch
sh 0-setup.sh
sh 1-base.sh
sh 2-software-pacman.sh
su username
sh 3-software-aur.sh
su
sh 4-secure-system.sh
sh 9-post-setup.sh
```
# System Description

This runs KDE-Plasma, and installs known drivers, and applications for quick and easy linux start up.
This also configures firewall, and other known processes considered at startup.

# Troubleshooting Arch Linux
Arch Linux Installation Gude
