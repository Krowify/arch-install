# krow-linux-applications
This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a desktop environment, all the support packages (network, bluetooth, audio, etc.), along with all my preferred applications and utilities. 

Arch Linux First Boot
```
pacman -S --noconfirm pacman-contrib curl git
git clone 
cd ArchMatic
sh 0-setup.sh
sh 1-base.sh
sh 2-software-pacman.sh
su username
sh 3-software-aur.sh
su
sh 4-secure-system.sh
sh 9-post-setup.sh
```
