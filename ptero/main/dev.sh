#!/bin/bash
# ===========================================================
# CODING HUB - NEON CYBER DASHBOARD (v8.0)
# Style: Random Synthwave | Grid: High-Tech | Dev: Nobita
# ===========================================================

# --- 1. NEON RANDOM PALETTE ---
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'
GOLD='\033[38;5;220m'
ACID_GREEN='\033[38;5;118m'
SKY_BLUE='\033[38;5;39m'
CRIMSON='\033[38;5;196m'
W='\033[1;37m'
NC='\033[0m'

# --- 2. DATA COLLECTION ---
get_stats() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}')
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}')
    UPT=$(uptime -p | sed 's/up //; s/ minutes/m/; s/ hours/h/; s/ days/d/')
    IP=$(hostname -I | awk '{print $1}')
}

# --- 3. UI RENDERER ---
render_ui() {
    clear
    get_stats
    
    # --- CYBER GLOW HEADER ---
    echo -e "  ${MAGENTA}◈${NC} ${CYAN}TERMINAL_ACCESS${NC} ${MAGENTA}◈${NC} ${GOLD}HUB_OS V 4.1${NC} ${MAGENTA}◈${NC}"
    echo -e "${SKY_BLUE}◸${W}$(printf '%.0s━' {1..74})${SKY_BLUE}◹${NC}"
    
    # --- LOGO (RANDOM NEON GRADIENT) ---
    echo -e "${CYAN} ██████╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗     ██╗  ██╗██╗   ██╗██████╗ ${NC}"
    echo -e "${CYAN}██╔════╝██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝     ██║  ██║██║   ██║██╔══██╗${NC}"
    echo -e "${MAGENTA}██║     ██║   ██║██║  ██║██║██╔██╗ ██║██║  ███╗    ███████║██║   ██║██████╔╝${NC}"
    echo -e "${MAGENTA}██║     ██║   ██║██║  ██║██║██║╚██╗██║██║   ██║    ██╔══██║██║   ██║██╔══██╗${NC}"
    echo -e "${GOLD}╚██████╗╚██████╔╝██████╔╝██║██║ ╚████║╚██████╔╝    ██║  ██║╚██████╔╝██████╔╝${NC}"
    echo -e "${GOLD} ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ${NC}"
    
    echo -e "${SKY_BLUE}╟$(printf '%.0s─' {1..74})╢${NC}"
    
    # --- SYSTEM METRICS GRID ---
    printf "  ${GOLD}⬡ CPU:${NC} ${W}%-4s${NC} ${MAGENTA}⬡ RAM:${NC} ${W}%-4s${NC} ${ACID_GREEN}⬡ UPTIME:${NC} ${W}%-10s${NC} ${CYAN}⬡ IP:${NC} ${W}%-15s${NC}\n" "$CPU%" "$RAM%" "$UPT" "$IP"
    
    echo -e "${SKY_BLUE}╟──────────────┬───────────────────────────────┬────────────────────────────╢${NC}"
    
    # --- MAIN OPTIONS ---
    echo -e "  ${SKY_BLUE}│${NC} ${GOLD}CONTROL${NC}     ${SKY_BLUE}│${NC} ${W}[01] VPS Run Setup           ${SKY_BLUE}│${NC} ${W}[05] Theme Manager      ${SKY_BLUE}│${NC}"
    echo -e "  ${SKY_BLUE}│${NC} ${SKY_BLUE}───────────${NC} ${SKY_BLUE}│${NC} ${W}[02] Panel Manager           ${SKY_BLUE}│${NC} ${W}[06] System Options     ${SKY_BLUE}│${NC}"
    echo -e "  ${SKY_BLUE}│${NC} ${MAGENTA}NETWORK${NC}     ${SKY_BLUE}│${NC} ${W}[03] Wings Installation      ${SKY_BLUE}│${NC} ${W}[07] NO-KVM Mode        ${SKY_BLUE}│${NC}"
    echo -e "  ${SKY_BLUE}│${NC} ${SKY_BLUE}───────────${NC} ${SKY_BLUE}│${NC} ${W}[04] Utility Tools           ${SKY_BLUE}│${NC} ${CRIMSON}[08] EXIT SYSTEM        ${SKY_BLUE}│${NC}"
    
    echo -e "${SKY_BLUE}╘$(printf '%.0s━' {1..74})╛${NC}"
    
    # --- PROMPT ---
    echo -e "  ${MAGENTA}»${NC} ${GOLD}User:${NC} ${W}$(whoami)${NC} ${MAGENTA}»${NC} ${ACID_GREEN}Status:${NC} ${W}Operational${NC}"
    echo -ne "  ${CYAN}⚡${NC} ${W}root@hub${NC}:${MAGENTA}#${NC} "
}

# --- 4. MAIN LOOP ---
while true; do
    render_ui
    read -r opt
    case $opt in
        1) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/run.sh) ;;
        2) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/panel/run.sh) ;;
        3) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/wings/run.sh) ;;
        4) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/run.sh) ;;
        5) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/thame/chang/dev.sh) ;;
        6) bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/menu/System1.sh) ;;
        7) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/run.sh) ;;
        8|exit) 
            echo -e "\n  ${MAGENTA}System Offline.${NC} Goodbye, Nobita.\n"
            exit 0 ;;
        *) 
            echo -e "  ${CRIMSON}![Error] Unknown Command${NC}"
            sleep 0.5 ;;
    esac
done
