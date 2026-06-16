#!/bin/env bash

# WARNING: THIS IS AN AI-GENERATED AND HARDENED CONFIGURATION SCRIPT

# START OF USER CONFIGURATION SECTION -------------------------------------------------------------------------------------------

# To configure the actions that this script will perform, adjust the flag variables below (0 == False; 1 == True). 
# WARNING: It is recommended to read and understand this script fully before running it.

UPDATE_SYSTEM=1                         # Update and upgrade packages with apt
ADD_DEFAULT_GNOME_SESSION=0             # Add default Gnome session with tweaks and extension manager
REPLACE_SNAP_STORE_W_GNOME_SOFTWARE=1   # Replace snap-store with gnome-software (with plugins for snap/flatpak if configured)

CONFIGURE_FLATPAK=1                     # Configure system to use flatpak
REMOVE_SNAP_FROM_SYSTEM=0               # Fully uninstall snaps and snapd from the system

# WARNING: The HIDE_SNAP_FOLDER action only works if the only snaps installed are those that were preinstalled with the system.
HIDE_SNAP_FOLDER=1                      # Enable experimental option to hide the ~/snap/ folder and reinstall snaps

# END OF USER CONFIGURATION SECTION ---------------------------------------------------------------------------------------------

# Terminal Colors
YELLOW="\e[1;33m"
GREEN="\e[1;32m"
RED="\e[1;31m"
RESET="\e[0m"

# Make command failure stop execution
set -e

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] This script must be run as root or with sudo.${RESET}"
   exit 1
fi

# Determine Ubuntu Version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep -oP '(?<=^VERSION_ID=")[^"]*' /etc/os-release)

# Strict Version Check Guard Clause
if [[ "$UBUNTU_VERSION" != "24.04" && "$UBUNTU_VERSION" != "26.04" ]]; then
    echo -e "${RED}=================================================================${RESET}"
    echo -e "${RED}[CRITICAL ERROR] Unsupported Ubuntu Version Detected: ${UBUNTU_VERSION}${RESET}"
    echo -e "${RED}This script only supports Ubuntu 24.04 and 26.04.${RESET}"
    echo -e "${RED}Execution safely aborted to prevent breaking system packages.${RESET}"
    echo -e "${RED}=================================================================${RESET}"
    exit 1
fi

# ==========================================
# UTILITY & ENVIRONMENT GUARD FUNCTIONS
# ==========================================

# Asserts command presence dynamically before executing steps
assert_cmd() {
    local cmd="$1"
    local feature_desc="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${YELLOW}[SKIP] Required command '${cmd}' is missing. Skipping: ${feature_desc}${RESET}"
        return 1
    fi
    return 0
}

# Returns the version-specific list of snaps to remove sequentially
get_snap_list() {
    if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
        # 24.04 Noble Numbat Defaults
        echo "firefox gtk-common-themes snap-store firmware-updater prompting-client desktop-security-center snapd-desktop-integration gnome-42-2204 core22 bare snapd"
    else
        # 26.04 Resolute Raccoon Defaults
        echo "firefox gtk-common-themes snap-store firmware-updater prompting-client desktop-security-center snapd-desktop-integration gnome-46-2404 mesa-2404 core24 bare snapd"
    fi
}

check_snap_folder() {
    local USER_HOME
    USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
    local SNAP_DIR="$USER_HOME/snap"

    if [ -d "$SNAP_DIR" ]; then
        if [ -z "$(ls -A "$SNAP_DIR")" ]; then
            echo "The ~/snap folder is empty. Deleting..."
            sleep 2
            rmdir "$SNAP_DIR"
        else
            echo "The old ~/snap folder is NOT empty."
            echo "Current contents:"
            ls -A "$SNAP_DIR"
        fi
    else
        echo "The ~/snap folder does not exist. Your config is already clean!"
    fi
}

# ==========================================
# CORE ACTIONS
# ==========================================

update_system() {
    assert_cmd "apt" "Update & Upgrade System" || return 0
    apt update -y && apt upgrade -y
}

hide_snap_folder() {
    if [ "$REMOVE_SNAP_FROM_SYSTEM" -eq 1 ]; then
        echo -e "${YELLOW}[SKIP] 'Completely Remove Snap' is enabled. Hiding folder is redundant.${RESET}"
        return 0
    fi

    assert_cmd "snap" "Hide ~/snap/ Folder" || return 0

    printf "Removing individual snap packages in target order...\n"
    local snaps
    snaps=$(get_snap_list)
    
    for s in $snaps; do
        snap remove "$s" || true
    done

    printf "${YELLOW}Enabling experimental option to hide the snap folder.${RESET}\n"
    snap set system experimental.hidden-snap-folder=true

    check_snap_folder
}

replace_store_w_software() {
    assert_cmd "apt" "Replace Snap Store with GNOME Software" || return 0

    if command -v snap >/dev/null 2>&1; then
        snap remove --purge snap-store || true
    fi

    apt install gnome-software -y

    if command -v snap >/dev/null 2>&1; then
        apt install gnome-software-plugin-snap -y
    fi

    if command -v flatpak >/dev/null 2>&1; then
        apt install gnome-software-plugin-flatpak -y
    fi
}

setup_flatpak() {
    assert_cmd "apt" "Configure Flatpak" || return 0
    apt install -y flatpak
    
    assert_cmd "flatpak" "Adding Flathub Repository" || return 0
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

setup_default_gnome() {
    assert_cmd "apt" "Install Default GNOME Session" || return 0
    apt install -y gnome-session gnome-shell-extension-manager gnome-tweaks
}

remove_snap() {
    assert_cmd "snap" "Completely Remove Snap" || return 0
    assert_cmd "apt" "Purging snapd Infrastructure" || return 0

    local USER_HOME
    USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")

    printf "Removing individual snap packages...\n"
    local snaps
    snaps=$(get_snap_list)
    
    for s in $snaps; do
        snap remove --purge "$s" || true
    done
    
    printf "Removing snapd infrastructure...\n"
    apt remove --purge -y snapd
    apt-mark hold snapd
    rm -rf "$USER_HOME/snap"
    apt autoremove -y
}

# ==========================================
# SYSTEM CORE & EXECUTION
# ==========================================

main() {
    # High-Visibility Environment Warning Block
    echo -e "${RED}#################################################################"
    echo -e "                                WARNING                                  "
    echo -e "#################################################################"
    echo -e " This optimization script is strictly designed to be executed on "
    echo -e " a FRESH, CLEAN INSTALLATION of Ubuntu.                         "
    echo -e " Running this on a seasoned workstation may break dependencies,  "
    echo -e " delete localized configs, or purge user applications unexpectedly."
    echo -e "#################################################################${RESET}\n"

    # CRITICAL: Ordered from least disruptive/constructive to structural removals
    # This prevents 'remove_snap' from destroying snap binary paths required by 'replace_store_w_software'
    local CONFIG_VARS=(  "$UPDATE_SYSTEM"         "$ADD_DEFAULT_GNOME_SESSION"    "$CONFIGURE_FLATPAK"    "$REPLACE_SNAP_STORE_W_GNOME_SOFTWARE" "$HIDE_SNAP_FOLDER"          "$REMOVE_SNAP_FROM_SYSTEM" )
    local DESCRIPTIONS=( "Update & Upgrade System" "Install Default GNOME Session" "Configure Flatpak"    "Replace Snap Store with GNOME Software" "Hide ~/snap/ Folder"      "Completely Remove Snap" )
    local FUNCTIONS=(    "update_system"           "setup_default_gnome"           "setup_flatpak"         "replace_store_w_software"             "hide_snap_folder"          "remove_snap" )

    local active_count=0

    echo -e "========================================="
    echo -e "        UBUNTU CONFIGURATION PLAN         "
    echo -e "  [Detected OS Target Version: ${GREEN}${UBUNTU_VERSION}${RESET}]"
    echo -e "========================================="
    
    # Preview loop
    for i in "${!CONFIG_VARS[@]}"; do
        if [ "${CONFIG_VARS[$i]}" -eq 1 ]; then
            # Warn user of automatic override visibility inside configuration plan preview
            if [[ "${FUNCTIONS[$i]}" == "hide_snap_folder" && "$REMOVE_SNAP_FROM_SYSTEM" -eq 1 ]]; then
                echo -e " [${YELLOW}OVERRIDDEN${RESET}] --> ${DESCRIPTIONS[$i]} (Will be bypassed by Snap Removal)"
            else
                echo -e " [${GREEN}ENABLED${RESET}]  --> ${DESCRIPTIONS[$i]}"
                active_count=$((active_count + 1))
            fi
        else
            echo -e " [${RED}DISABLED${RESET}] --> ${DESCRIPTIONS[$i]}"
        fi
    done
    echo -e "=========================================\n"

    if [ "$active_count" -eq 0 ]; then
        echo -e "${YELLOW}No actions are set to active. Exiting script safely.${RESET}"
        exit 0
    fi

    # Interactive User Confirmation Challenge
    read -rp "Are you absolutely sure you want to proceed? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Execution aborted by user.${RESET}"
        exit 1
    fi

    # Dynamic Execution Loop
    for i in "${!CONFIG_VARS[@]}"; do
        if [ "${CONFIG_VARS[$i]}" -eq 1 ]; then
            local current_func="${FUNCTIONS[$i]}"
            local current_desc="${DESCRIPTIONS[$i]}"

            echo -e "\n${YELLOW}>>> [STARTING] Will perform action: ${current_desc} in 3 seconds...${RESET}"
            sleep 3

            # Call functional target assignment safely
            if $current_func; then
                echo -e "${GREEN}>>> [SUCCESS] ${current_desc} step sequence processed.${RESET}"
            else
                echo -e "${RED}>>> [WARNING] ${current_desc} ran into unexpected non-fatal errors.${RESET}"
            fi
            sleep 1
        fi
    done

    echo -e "\n${GREEN}All selected optimization tasks finished processing!${RESET}\n"
}

# Run program
main
