#!/bin/env bash

# START OF USER CONFIGURATION SECTION -------------------------------------------------------------------------------------------

# To configure the actions that this script will perform, adjust the flag variables below(0==False; 1==True). 
# WARNING: It is recommended to read and understand this script fully before running it.

UPDATE_SYSTEM=1                         # Update and upgrade packages with apt
ADD_DEFAULT_GNOME_SESSION=1             # Add default Gnome session with tweaks and extension manager
REPLACE_SNAP_STORE_W_GNOME_SOFTWARE=1   # Replace snap-store with gnome-software (with plugins for snap and flatpak if configured)

CONFIGURE_FLATPAK=0                     # Configure system to use flatpak
REMOVE_SNAP_FROM_SYSTEM=0               # Fully uninstall snaps and snapd from the system

# WARNING: The HIDE_SNAP_FOLDER action only works if the only snaps installed are those that were preinstalled with the system.
HIDE_SNAP_FOLDER=1                      # Enable expiremental option to hide the ~/snap/ folder and reinstall snaps

# END OF USER CONFIGURATION SECTION ---------------------------------------------------------------------------------------------

# Terminal Colors
YELLOW="\e[1;33m"
RESET="\e[0m"

# Make command failure stop execution
set -e

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

check_snap_folder() {
    SNAP_DIR="$HOME/snap"

    if [ -d "$SNAP_DIR" ]; then
    # Check if it's empty (including hidden files, but excluding . and ..)
    # 'A' ignores . and .., but finds everything else.
    if [ -z "$(ls -A "$SNAP_DIR")" ]; then
        echo "The ~/snap folder is empty. Deleting..."
        sleep 6
        rmdir "$SNAP_DIR"
    else
        echo "The old ~/snap folder is NOT empty."
        echo "Current contents:"
        ls -A "$SNAP_DIR"
        exit 0
    fi
    else
        echo "The ~/snap folder does not exist. Your config is already clean!"
    fi
}

hide_snap_folder() {
    printf "$YELLOW Will perform hide-snap-folder action in 6 seconds...$RESET\n"
    sleep 6

    printf "Removing individual snap packages in order...\n"
    snap remove firefox
    snap remove gtk-common-themes
    snap remove snap-store
    snap remove firmware-updater
    snap remove prompting-client
    snap remove desktop-security-center
    snap remove snapd-desktop-integration
    snap remove gnome-42-2204
    snap remove core22
    snap remove bare
    snap remove snapd

    printf "$YELLOW Enabling expiremental option to hide the snap folder. $RESET\n"
    snap set system experimental.hidden-snap-folder=true

    printf "Installing individual snap packages...\n"
    snap install snapd
    snap install bare
    snap install core22
    snap install gnome-42-2204
    snap install snapd-desktop-integration
    snap install desktop-security-center
    snap install prompting-client
    snap install gtk-common-themes
    snap install firmware-updater
    snap install firefox
    snap install snap-store

    check_snap_folder
    printf "$YELLOW hide-snap-folder successful$RESET\n"
    sleep 1
}

# Function to remove snap packages along with snapd
remove_snap() {
    printf "$YELLOW Will perform remove-snap action in 6 seconds...$RESET\n"
    sleep 6

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

    printf "$YELLOW remove-snap successful$RESET\n"
    sleep 1
}

replace_store_w_software() {
    printf "$YELLOW Will perform replace-snap-store-w-gnome-software action in 6 seconds...$RESET\n"
    sleep 6

    snap remove --purge snap-store
    apt install gnome-software

    if command -v snap >/dev/null 2>&1; then
        apt install gnome-software-plugin-snap -y
    fi

    if command -v flatpak >/dev/null 2>&1; then
        apt install gnome-software-plugin-flatpak -y
    fi

    printf "$YELLOW replace-snap-store-w-gnome-software successful$RESET\n"
    sleep 1
}

setup_flatpak() {
    printf "$YELLOW Will perform configure-flatpak action in 6 seconds...$RESET\n"
    sleep 6

    # Installing flatpak
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    printf "$YELLOW Flatpak setup successful$RESET\n"
    sleep 1
}

setup_default_gnome() {
    printf "$YELLOW Will perform add-default-gnome-session action in 6 seconds...$RESET\n"
    sleep 6

    apt install -y gnome-session
    # Install commonly used Gnome packages
    apt install -y gnome-shell-extension-manager gnome-tweaks

    printf "$YELLOW default-gnome-session setup successful$RESET\n"
    sleep 1
}

main() {
    if [ $UPDATE_SYSTEM -eq 1 ]; then
        printf "$YELLOW Will perform update-system action in 6 seconds...$RESET\n"
        sleep 6

        apt update -y && apt upgrade -y
    fi

    if [ $HIDE_SNAP_FOLDER -eq 1 ]; then
        hide_snap_folder
    fi

    if [ $ADD_DEFAULT_GNOME_SESSION -eq 1 ]; then
        setup_default_gnome
    fi

    if [ $CONFIGURE_FLATPAK -eq 1 ]; then
        setup_flatpak
    fi

    if [ $REMOVE_SNAP_FROM_SYSTEM -eq 1 ]; then
        remove_snap
    fi

    if [ $REPLACE_SNAP_STORE_W_GNOME_SOFTWARE -eq 1 ]; then
        replace_store_w_software
    fi
}

# Call main function
main



