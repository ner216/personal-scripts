#!/bin/env bash

# Make command failure stop execution
set -e

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

# Function to remove snap packages along with snapd
remove_snap() {
    printf "Removing individual snap packages...\n"
    snap remove --purge firefox
    snap remove --purge gtk-common-themes
    snap remove --purge snap-store
    snap remove --purge firmware-updater
    snap remove --purge prompting-client
    snap remove --purge desktop-security-center
    snap remove --purge snapd-desktop-integration
    snap remove --purge gnome-42-2204
    snap remove --purge core22
    snap remove --purge bare
    snap remove --purge snapd
    
    printf "Removing snapd...\n"
    apt remove --purge -y snapd
    apt-mark hold snapd
    rm -rf ~/snap
    apt autoremove -y
}

setup_flatpak() {
    # Installing flatpak
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    read -p "Replace pdf viewer and Firefox with flatpak? (y/n)> " choice
    if [ $choice == "y" ]; then
        apt remove -y papers
        apt autoremove -y
        flatpak install flathub org.gnome.Papers
        flatpak install flathub org.mozilla.firefox
    elif [ $choice != "n" ]; then 
        printf "Invalid input!\n"
        exit 1
    fi
}

remove_yaru() {
    apt remove -y yaru-theme-gnome-shell yaru-theme-gtk
    apt autoremove -y
    # Reconfigure Gnome in case of package removal
    apt install --reinstall -y gnome-shell gnome-session
    # Install commonly used Gnome packages
    apt install -y gnome-shell-extension-manager gnome-tweaks
}

# Install posterior packages for system (apt)
install_extras() {
    apt install -y git lm-sensors fastfetch neovim
    
    read -p "Change default system editor? (y/n)> " choice
    if [ $choice == "y" ]; then
        update-alternatives --config editor
    elif [ $choice != "n" ]; then
        printf "Invalid input!\n"
        exit 1
    fi
}

main() {
    read -p "Update system packages? (y/n)> " choice
    if [ $choice == "y" ]; then
        apt update -y && apt upgrade -y
    elif [ $choice != "n" ]; then
        printf "Invalid input!\n"
        exit 1
    fi
    
    read -p "Remove snap from system? (y/n)> " choice
    if [ $choice == "y" ]; then
        remove_snap
    elif [ $choice != "n" ]; then
        printf "Invalid input!\n"
        exit 1
    fi
    
    read -p "Remove Yaru desktop theme? (y/n)> " choice
    if [ $choice == "y" ]; then
        remove_yaru
    elif [ $choice != "n" ]; then
        printf "Invalid input!\n"
        exit 1
    fi
    
    read -p "Configure flatpak? (y/n)> " choice
    if [ $choice == "y" ]; then
        setup_flatpak
    elif [ $choice != "n" ]; then 
        printf "Invalid input!\n"
        exit 1
    fi
    
    read -p "Install extra packages? (y/n)> " choice
    if [ $choice == "y" ]; then
        install_extras
    elif [ $choice != "n" ]; then
        printf "Invalid input!\n"
        exit 1
    fi
    
    read -p "Remove unnecessary packages? [yelp, info] (y/n)> " choice
    if [ $choice == "y" ]; then
        apt remove yelp info -y
    elif [ $choice != "n" ]; then
        printf "Invalid input!\n"
        exit 1
    fi
    
    printf "All done! Please reboot system.\n"
}

# Call main function
main



