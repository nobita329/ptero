#!/bin/bash

# ==================================================
#   SERVER CONTROL CENTER | v3.1 (Color Update)
# ==================================================

# --- 1. COLORS & STYLING ---
# Backgrounds
BG_BLUE="\e[44;97m"; BG_GREEN="\e[42;97m"; BG_RED="\e[41;97m"

# Text Colors
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[97m"; GREY="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

# --- 2. CONFIGURATION ---
SHELLNGN_PORT_FILE="/root/.shellngn_port"

# --- 3. UTILITY FUNCTIONS ---
pause() { echo; read -p "  ↩ Press Enter to continue..." _; }

get_ts_ip() {
    if docker ps --format '{{.Names}}' | grep -q tailscale; then
        docker exec tailscale tailscale ip 2>/dev/null | head -n1
    else
        echo "N/A"
    fi
}

get_port() {
    if [ -f "$SHELLNGN_PORT_FILE" ]; then cat "$SHELLNGN_PORT_FILE"; else echo "8080"; fi
}

# --- 4. HEADER & DASHBOARD ---
draw_header() {
    clear
    local user=$(whoami)
    local host=$(hostname)
    
    # -- Status Logic --
    # Docker Status
    local doc_pill="${BG_RED} OFF ${RESET}"
    if command -v docker &>/dev/null; then doc_pill="${BG_GREEN} ON  ${RESET}"; fi

    # ShellNGN Status
    local sng_pill="${BG_RED} OFF ${RESET}"
    if docker ps -a --format '{{.Names}}' | grep -q shellngn; then sng_pill="${BG_GREEN} ON  ${RESET}"; fi
    local sng_port=$(get_port)

    # Tailscale Status
    local ts_pill="${BG_RED} OFF ${RESET}"
    local ts_ip="${GREY}No IP${RESET}"
    if docker ps -a --format '{{.Names}}' | grep -q tailscale; then 
        ts_pill="${BG_GREEN} ON  ${RESET}"
        ts_ip="${C}${BOLD}$(get_ts_ip)${RESET}"
    fi

    # -- Draw Interface --
    # Header Bar
    echo -e "${BG_BLUE}${BOLD}  ⚡ SERVER CONTROL CENTER  v3.0                                ${RESET}"
    
    # User Info Line
    echo -e "  ${C}User:${RESET} $user   ${GREY}|${RESET}   ${C}Host:${RESET} $host"
    
    # Decorative Separator
    echo -e "  ${M}────────────────────────────────────────────────────────────${RESET}"
    
    # Dashboard
    echo -e "  ${BOLD}SERVICES STATUS:${RESET}"
    printf "  ├── ${W}%-10s${RESET} %b\n" "Docker" "$doc_pill"
    printf "  ├── ${W}%-10s${RESET} %b  ${GREY}➜ Port: ${Y}$sng_port${RESET}\n" "ShellNGN" "$sng_pill"
    printf "  └── ${W}%-10s${RESET} %b  ${GREY}➜ IP:   ${RESET}%b\n" "Tailscale" "$ts_pill" "$ts_ip"
    
    echo -e "  ${M}────────────────────────────────────────────────────────────${RESET}"
    echo
}

# --- 5. CORE INSTALLERS ---

install_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "  ${B}[+] Installing Docker...${RESET}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
}

# --- SHELLNGN FUNCTIONS ---
install_shellngn() {
    draw_header
    install_docker

    echo -e "  ${BOLD}┌── [ INSTALL SHELLNGN ]${RESET}"
    echo -e "  ${BOLD}│${RESET}"
    echo -e "  ${GREY}[${Y}1${GREY}]${RESET} Default Port ${C}(8080)${RESET}"
    echo -e "  ${GREY}[${Y}2${GREY}]${RESET} Custom Port"
    echo -e "  ${BOLD}│${RESET}"
    read -p "  └─➤ Select Option: " port_choice

    if [ "$port_choice" == "2" ]; then
        read -p "    ➤ Enter Custom Port: " CUSTOM_PORT
        PORT=$CUSTOM_PORT
    else
        PORT=8080
    fi

    echo "$PORT" > "$SHELLNGN_PORT_FILE"
    echo -e "\n  ${B}[+] Installing ShellNGN on port ${PORT}...${RESET}"

    docker rm -f shellngn >/dev/null 2>&1
    docker run -d --name shellngn -p ${PORT}:8080 --restart=always shellngn/pro:latest

    echo -e "  ${G}[✓] ShellNGN Installed! Access: http://$HOSTNAME:${PORT}${RESET}"
    pause
    shellngn_menu
}

uninstall_shellngn() {
    echo -e "\n  ${R}[!] Removing ShellNGN...${RESET}"
    docker rm -f shellngn >/dev/null 2>&1
    rm -f "$SHELLNGN_PORT_FILE"
    echo -e "  ${G}[✓] Removed Successfully.${RESET}"
    pause
    shellngn_menu
}

shellngn_menu() {
    while true; do
        draw_header
        echo -e "  ${BOLD}SHELLNGN OPTIONS:${RESET}"
        echo -e "  ${GREY}[${Y}1${GREY}]${RESET} ${G}Install${RESET} ShellNGN"
        echo -e "  ${GREY}[${Y}2${GREY}]${RESET} ${R}Uninstall${RESET} ShellNGN"
        echo -e "  ${GREY}[${Y}0${GREY}]${RESET} Back"
        echo
        read -p "  > Select: " opt
        case $opt in
            1) install_shellngn; return ;;
            2) uninstall_shellngn; return ;;
            0) return ;;
            *) echo -e "  ${R}Invalid option${RESET}"; sleep 1 ;;
        esac
    done
}

# --- TAILSCALE FUNCTIONS ---
install_tailscale() {
    draw_header
    install_docker
    
    echo -e "  ${BOLD}┌── [ INSTALL TAILSCALE ]${RESET}"
    echo -e "  ${BOLD}│${RESET}"
    read -p "  └─➤ Enter Tailscale Auth Key: " TSKEY

    docker volume create tailscale-data >/dev/null
    docker rm -f tailscale >/dev/null 2>&1

    echo -e "\n  ${B}[+] Starting Tailscale container...${RESET}"
    docker run -d --name tailscale --hostname=$(hostname) \
      --cap-add=NET_ADMIN --cap-add=SYS_MODULE --device=/dev/net/tun \
      --network=host -e TS_AUTHKEY=$TSKEY -e TS_STATE_DIR=/var/lib/tailscale \
      -v tailscale-data:/var/lib/tailscale --restart=always tailscale/tailscale:latest

    sleep 2
    echo -e "  ${G}[✓] Tailscale Connected!${RESET}"
    pause
    tailscale_menu
}

uninstall_tailscale() {
    echo -e "\n  ${R}[!] Removing Tailscale...${RESET}"
    docker rm -f tailscale >/dev/null 2>&1
    echo -e "  ${G}[✓] Removed Successfully.${RESET}"
    pause
    tailscale_menu
}

tailscale_menu() {
    while true; do
        draw_header
        echo -e "  ${BOLD}TAILSCALE OPTIONS:${RESET}"
        echo -e "  ${GREY}[${Y}1${GREY}]${RESET} ${G}Install${RESET} Tailscale"
        echo -e "  ${GREY}[${Y}2${GREY}]${RESET} ${R}Uninstall${RESET} Tailscale"
        echo -e "  ${GREY}[${Y}0${GREY}]${RESET} Back"
        echo
        read -p "  > Select: " opt
        case $opt in
            1) install_tailscale; return ;;
            2) uninstall_tailscale; return ;;
            0) return ;;
            *) echo -e "  ${R}Invalid option${RESET}"; sleep 1 ;;
        esac
    done
}

# --- 6. MAIN LOOP ---
while true; do
    draw_header
    echo -e "  ${BOLD}MAIN MENU:${RESET}"
    echo -e "  ${GREY}[${Y}1${GREY}]${RESET} Manage ${C}ShellNGN${RESET}"
    echo -e "  ${GREY}[${Y}2${GREY}]${RESET} Manage ${C}Tailscale${RESET}"
    echo -e "  ${GREY}[${R}0${GREY}]${RESET} Exit"
    echo
    read -p "  > Select Option: " opt

    case $opt in
        1) shellngn_menu ;;
        2) tailscale_menu ;;
        0) echo -e "\n  ${G}👋 Goodbye!${RESET}"; exit 0 ;;
        *) echo -e "\n  ${R}❌ Invalid Option${RESET}"; sleep 1 ;;
    esac
done
