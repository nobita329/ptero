#!/bin/bash

# ==================================================
#  SSH ACCESS MANAGER | DASHBOARD UI
# ==================================================

# --- COLORS & STYLES ---
C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

CONFIG_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.bak"

# --- UI DRAWING FUNCTIONS ---

get_setting_status() {
    local param=$1
    local default=$2
    # Grep the last occurrence of the setting, ignore comments
    local val=$(grep -E "^${param}" "$CONFIG_FILE" | tail -n 1 | awk '{print $2}')
    
    if [[ -z "$val" ]]; then val="$default"; fi
    
    if [[ "$val" == "yes" ]]; then
        echo -e "${C_GREEN}ENABLED${C_RESET}"
    else
        echo -e "${C_RED}DISABLED${C_RESET} ($val)"
    fi
}

draw_header() {
    clear
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    
    # Check Service Status
    local srv_status="${C_RED}STOPPED${C_RESET}"
    if systemctl is-active --quiet ssh; then srv_status="${C_GREEN}RUNNING${C_RESET}"; fi

    # Check Config Status
    local root_login=$(get_setting_status "PermitRootLogin" "prohibit-password")
    local pass_auth=$(get_setting_status "PasswordAuthentication" "no")

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}${C_PURPLE}🔐 SSH ACCESS MANAGER v2.0${C_RESET}                                      ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}HOST:${C_RESET} ${C_WHITE}$hostname${C_RESET}   ${C_GRAY}IP:${C_RESET} ${C_WHITE}$ip${C_RESET}                                   ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_CYAN}SSH SERVICE:${C_RESET} $srv_status                                         ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}ROOT LOGIN:${C_RESET}    $root_login                                  ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}PASSWORD AUTH:${C_RESET} $pass_auth                                  ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO")    echo -e " ${C_BLUE}➜${C_RESET} ${C_WHITE}$message${C_RESET}" ;;
        "WARN")    echo -e " ${C_YELLOW}⚠${C_RESET} ${C_YELLOW}$message${C_RESET}" ;;
        "ERROR")   echo -e " ${C_RED}✖${C_RESET} ${C_RED}$message${C_RESET}" ;;
        "SUCCESS") echo -e " ${C_GREEN}✔${C_RESET} ${C_GREEN}$message${C_RESET}" ;;
        "INPUT")   echo -ne " ${C_PURPLE}➤${C_RESET} ${C_CYAN}$message${C_RESET}" ;;
    esac
}

# --- ACTIONS ---

enable_access() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    
    # 1. Backup
    print_status "INFO" "Creating Config Backup..."
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    print_status "SUCCESS" "Backup saved to .bak"

    # 2. Modify Config
    print_status "INFO" "Enabling Root Login..."
    # Remove old settings
    sed -i '/^PermitRootLogin/d' "$CONFIG_FILE"
    sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
    # Append new settings
    echo "PermitRootLogin yes" >> "$CONFIG_FILE"
    echo "PasswordAuthentication yes" >> "$CONFIG_FILE"
    
    # 3. Restart
    print_status "INFO" "Restarting SSH Service..."
    systemctl restart ssh
    
    print_status "SUCCESS" "Configuration Applied!"
    echo -e "${C_YELLOW}NOTE: Ensure you have set a root password!${C_RESET}"
    read -p "Press Enter to return..."
}

set_root_pass() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Launching Password Utility..."
    echo ""
    passwd root
    echo ""
    if [ $? -eq 0 ]; then
        print_status "SUCCESS" "Root Password Updated."
    else
        print_status "ERROR" "Failed to set password."
    fi
    read -p "Press Enter to return..."
}

restore_backup() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    if [ -f "$BACKUP_FILE" ]; then
        print_status "INFO" "Restoring from backup..."
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl restart ssh
        print_status "SUCCESS" "Original Config Restored."
    else
        print_status "ERROR" "No backup found!"
    fi
    read -p "Press Enter..."
}

secure_lockdown() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "WARN" "This will DISABLE Root Login & Password Auth."
    read -p "$(print_status "INPUT" "Are you sure? (y/N): ")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i '/^PermitRootLogin/d' "$CONFIG_FILE"
        sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
        echo "PermitRootLogin no" >> "$CONFIG_FILE"
        echo "PasswordAuthentication no" >> "$CONFIG_FILE"
        systemctl restart ssh
        print_status "SUCCESS" "Server Locked Down (Key-Only)."
    else
        print_status "INFO" "Cancelled."
    fi
    read -p "Press Enter..."
}

# --- INIT CHECK ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${C_RED}Please run as root.${C_RESET}"
    exit 1
fi

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "${C_WHITE} AVAILABLE ACTIONS:${C_RESET}"
    echo -e " ${C_GREEN}[1]${C_RESET} Enable Root & Passwords    ${C_PURPLE}[3]${C_RESET} Set Root Password"
    echo -e " ${C_RED}[2]${C_RESET} Lockdown (Keys Only)       ${C_BLUE}[4]${C_RESET} Restore Backup"
    echo -e " ${C_GRAY}[0]${C_RESET} Exit"
    echo ""
    
    read -p "$(print_status "INPUT" "Select Option: ")" option
    
    case $option in
        1) enable_access ;;
        2) secure_lockdown ;;
        3) set_root_pass ;;
        4) restore_backup ;;
        0) echo -e "\n${C_PURPLE}👋 Exiting...${C_RESET}"; exit 0 ;;
        *) print_status "ERROR" "Invalid Option."; sleep 1 ;;
    esac
done
