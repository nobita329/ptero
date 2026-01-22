#!/bin/bash
# ===========================================================
# CODING HUB Terminal Control Panel (v3.5 - Stable Fix)
# UI Layout: Fixed Left | Colors: Old (Standard)
# ===========================================================

# --- 1. COLORS ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[1;30m'
NC='\033[0m'
BOLD='\033[1m'

# --- 2. UI CONFIGURATION ---
BORDER_COLOR=$GRAY
LOGO_COLOR=$CYAN
ACCENT_COLOR=$BLUE
TEXT_COLOR=$WHITE

# Box Drawing Characters
CORNER_TL="┌"
CORNER_TR="┐"
CORNER_BL="└"
CORNER_BR="┘"
LINE_H="─"
LINE_V="│"

# FIXED WIDTH (Matches the large banner size)
UI_WIDTH=98

# ===================== HELPER FUNCTIONS =====================

center_text_inner() {
    local text="$1"
    # Remove color codes to measure length
    local clean_text=$(echo -e "$text" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
    local text_len=${#clean_text}
    
    # Calculate padding to center text INSIDE the box
    local padding=$(( (UI_WIDTH - text_len) / 2 ))
    
    printf "%${padding}s" ""
    echo -ne "$text"
    
    local remaining=$(( UI_WIDTH - padding - text_len ))
    printf "%${remaining}s" ""
}

loading_bar() {
    echo -ne "\n${CYAN}  Loading: ${NC}[ "
    for i in {1..40}; do
        echo -ne "${GREEN}▓${NC}"
        sleep 0.01
    done
    echo -e " ] ${GREEN}Done!${NC}\n"
    sleep 0.3
}

# ===================== HEADER & DASHBOARD =====================
header(){
    clear
    # Top Border
    echo -e "${BORDER_COLOR}${CORNER_TL}$(printf '%.0s─' $(seq 1 $UI_WIDTH))${CORNER_TR}${NC}"
    
    # --- LOGO AREA ---
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${LOGO_COLOR} ██████╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗     ██╗  ██╗██╗   ██╗██████╗ ${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${LOGO_COLOR}██╔════╝██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝     ██║  ██║██║   ██║██╔══██╗${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${ACCENT_COLOR}██║     ██║   ██║██║  ██║██║██╔██╗ ██║██║  ███╗    ███████║██║   ██║██████╔╝${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${ACCENT_COLOR}██║     ██║   ██║██║  ██║██║██║╚██╗██║██║   ██║    ██╔══██║██║   ██║██╔══██╗${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${LOGO_COLOR}╚██████╗╚██████╔╝██████╔╝██║██║ ╚████║╚██████╔╝    ██║  ██║╚██████╔╝██████╔╝${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${LOGO_COLOR} ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${WHITE}CODING HUB CONTROL PANEL v3.5${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    echo -e "${BORDER_COLOR}${LINE_V}${NC}$(center_text_inner "${BOLD}>> DEVELOPED BY NOBITA (2026) <<${NC}")  ${BORDER_COLOR}${LINE_V}${NC}"
    
    # Separator
    echo -e "${BORDER_COLOR}${LINE_V}$(printf '%.0s─' $(seq 1 $UI_WIDTH))${LINE_V}${NC}"
}

draw_status_bar() {
    # 1. Capture Data
    local u=$(whoami)
    local h=$(hostname)
    local t=$(date +'%H:%M')
    
    # 2. Calculate Length
    # We create a dummy string to measure the exact length of the text
    # Format: " User: [15 chars] Host: [15 chars] Time: [10 chars]"
    local clean_str=$(printf " User: %-15s Host: %-15s Time: %-10s" "$u" "$h" "$t")
    local str_len=${#clean_str}
    
    # 3. Calculate Padding needed to fill the box
    local pad_len=$(( UI_WIDTH - str_len ))
    
    # 4. Print Left Border
    echo -ne "${BORDER_COLOR}${LINE_V}${NC}"
    
    # 5. Print Content with Colors
    printf " ${GRAY}User:${NC} %-15s ${GRAY}Host:${NC} %-15s ${GRAY}Time:${NC} %-10s" "$u" "$h" "$t"
    
    # 6. Print Padding & Right Border
    printf "%${pad_len}s" ""
    echo -e "${BORDER_COLOR}${LINE_V}${NC}"
    
    # 7. Bottom Border
    echo -e "${BORDER_COLOR}${CORNER_BL}$(printf '%.0s─' $(seq 1 $UI_WIDTH))${CORNER_BR}${NC}"
}

# ===================== MAIN MENU =====================
main_menu(){
    clear
    echo -e "\n${CYAN}Starting Coding Hub Panel...${NC}"
    sleep 0.5
    loading_bar
    
    while true; do 
        header
        
        SPACER="                   " # Gap between columns
        
        echo -e "${BORDER_COLOR}${LINE_V}${NC}$(printf "%${UI_WIDTH}s" "")${BORDER_COLOR}${LINE_V}${NC}"
        
        # Row 1
        printf "${BORDER_COLOR}${LINE_V}${NC}    ${WHITE}[01]${NC} ${CYAN}VPS Run Setup${NC}            ${SPACER} ${WHITE}[05]${NC} ${CYAN}Theme Manager${NC}            ${BORDER_COLOR}${LINE_V}${NC}\n"
        
        # Row 2
        printf "${BORDER_COLOR}${LINE_V}${NC}    ${WHITE}[02]${NC} ${CYAN}Panel Manager${NC}            ${SPACER} ${WHITE}[06]${NC} ${CYAN}System Options${NC}           ${BORDER_COLOR}${LINE_V}${NC}\n"
        
        # Row 3
        printf "${BORDER_COLOR}${LINE_V}${NC}    ${WHITE}[03]${NC} ${CYAN}Wings Installation${NC}       ${SPACER} ${WHITE}[07]${NC} ${CYAN}External Infra${NC}           ${BORDER_COLOR}${LINE_V}${NC}\n"
        
        # Row 4
        printf "${BORDER_COLOR}${LINE_V}${NC}    ${WHITE}[04]${NC} ${CYAN}Tools Utility${NC}            ${SPACER} ${RED}[08]${NC} ${RED}Exit Panel${NC}               ${BORDER_COLOR}${LINE_V}${NC}\n"
        
        echo -e "${BORDER_COLOR}${LINE_V}${NC}$(printf "%${UI_WIDTH}s" "")${BORDER_COLOR}${LINE_V}${NC}"
        
        # Separator before status
        echo -e "${BORDER_COLOR}${LINE_V}$(printf '%.0s─' $(seq 1 $UI_WIDTH))${LINE_V}${NC}"
        
        draw_status_bar
        
        echo -e ""
        echo -e "  ${GRAY}Enter the number corresponding to your choice:${NC}"
        echo -ne "  ${BOLD}${GREEN}root@codinghub:~#${NC} "
        read -p "" c

        case $c in
            1) loading_bar; bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/vm/vps.sh) ;;
            2) loading_bar; bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/panel/pterodactyl/run.sh) ;;
            3) loading_bar; bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/wings/www.sh) ;;
            4) loading_bar; tools_menu ;;
            5) loading_bar; theme_menu ;;
            6) loading_bar; bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/menu/System1.sh) ;;
            7) bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/External/INFRA.sh) ;;
            8) 
                echo -e ""
                echo -e "  ${GREEN}Thank you for using CODING HUB!${NC}"
                echo -e "  ${GRAY}See you soon, Nobita.${NC}"
                echo -e ""
                exit 
                ;;
            *) 
                echo -e "  ${RED}Invalid Selection. Try again.${NC}"
                sleep 1 
                ;;
        esac
    done
}

# Start the script
main_menu
