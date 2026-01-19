#!/bin/bash

# ==================================================
#  MACK CONTROL PANEL v3.0 | Auto-Detect System
# ==================================================

# --- COLORS & STYLES ---
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
M="\e[35m"
C="\e[36m"
W="\e[97m"
GR="\e[90m"
N="\e[0m"
BOLD="\e[1m"

# --- SYSTEM AUTO-DETECT VARIABLES ---
detect_system() {
    # 1. OS Detection
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$PRETTY_NAME
    else
        OS_NAME=$(uname -s)
    fi

    # 2. IP Detection (Fast with timeout)
    PUBLIC_IP=$(curl -s --max-time 2 https://ipinfo.io/ip || echo "Unknown")
    LOCAL_IP=$(hostname -I | awk '{print $1}')

    # 3. RAM Usage
    if command -v free >/dev/null 2>&1; then
        RAM_USED=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    else
        RAM_USED="N/A"
    fi
}

# --- UI DRAWING FUNCTIONS ---

draw_line() {
    echo -e "${B}╠════════════════════════════════════════════════════════════╣${N}"
}

draw_top() {
    echo -e "${B}╔════════════════════════════════════════════════════════════╗${N}"
}

draw_bottom() {
    echo -e "${B}╚════════════════════════════════════════════════════════════╝${N}"
}

header() {
    clear
    draw_top
    echo -e "${B}║${W}${BOLD}              🚀 MACK CONTROL PANEL v3.0                    ${B}║${N}"
    echo -e "${B}║${GR}             Server Management Automation                   ${B}║${N}"
    draw_line
    # Auto-Detected Info Dashboard
    echo -e "${B}║${C} 🖥️  SYSTEM : ${W}${OS_NAME:0:36} ${B}║${N}"
    echo -e "${B}║${G} 🌐 PUBLIC : ${W}${PUBLIC_IP:-Detecting...}                   ${B}║${N}"
    echo -e "${B}║${Y} 🏠 LOCAL  : ${W}${LOCAL_IP:-Detecting...}                   ${B}║${N}"
    echo -e "${B}║${M} 🧠 MEMORY : ${W}${RAM_USED:-Checking...}                     ${B}║${N}"
    draw_line
}

show_menu() {
    echo -e "${B}║${W}                    📋 MAIN MENU                            ${B}║${N}"
    draw_line
    echo -e "${B}║${C}  1.${W} 🔐 SSL Configuration       ${GR}(Certbot/Nginx)           ${B}║${N}"
    echo -e "${B}║${G}  2.${W} 🚀 Install Wings           ${GR}(Nobita Script)           ${B}║${N}"
    echo -e "${B}║${Y}  3.${W} ⚡ Auto-Setup              ${GR}(One-Click)               ${B}║${N}"
    echo -e "${B}║${M}  4.${W} 🗄️ Database Manager        ${GR}(MySQL/MariaDB)         ${B}║${N}"
    echo -e "${B}║${R}  5.${W} 🗑️ Uninstall               ${GR}(Remove Wings)            ${B}║${N}"
    draw_line
    echo -e "${B}║${R}  0.${W} 🚪 Exit System                                         ${B}║${N}"
    draw_bottom
    echo ""
}

# --- ACTIONS ---

ssl_setup() {
    header
    echo -e "${C}┌─[ ${W}SSL CONFIGURATION ${C}]${N}"
    
    # Auto-fill domain if possible or ask
    echo -e "${C}│${N} Auto-detected IP: ${G}$PUBLIC_IP${N}"
    echo -ne "${C}└─╼ ${W}Enter Domain (e.g., panel.host.com): ${N}"
    read DOMAIN

    if [[ -z "$DOMAIN" ]]; then
        echo -e "\n${R}✖ Setup aborted.${N}"
        sleep 1
        return
    fi

    echo -e "\n${Y}➜ Installing Dependencies...${N}"
    apt update -y >/dev/null 2>&1
    apt install -y mysql-server mariadb-server certbot python3-certbot-nginx >/dev/null 2>&1
    
    echo -e "${Y}➜ Enabling Services...${N}"
    systemctl enable --now mysql >/dev/null 2>&1
    systemctl enable --now mariadb >/dev/null 2>&1

    echo -e "${Y}➜ Requesting Certificate for ${W}$DOMAIN${Y}...${N}"
    certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    
    echo -e "\n${G}✔ SSL Setup Complete.${N}"
    read -p "Press Enter to return..."
}

uninstall_menu() {
    clear
    echo -e "${R}╔════════════════════════════════════════════════════════════╗${N}"
    echo -e "${R}║              ⚠️  DANGER ZONE: UNINSTALL                   ║${N}"
    echo -e "${R}╚════════════════════════════════════════════════════════════╝${N}"
    echo -e "${W} This will remove Wings, Docker, and Configs.${N}"
    echo -e "${W} Panel files will remain safe.${N}\n"
    
    echo -ne "${R}Are you sure? [y/N]: ${N}"
    read CONFIRM
    [[ "$CONFIRM" != "y" ]] && return

    echo -e "\n${Y}➜ Stopping Wings...${N}"
    systemctl disable --now wings 2>/dev/null
    rm -f /etc/systemd/system/wings.service
    rm -rf /etc/pterodactyl /var/lib/pterodactyl /usr/local/bin/wings
    
    echo -e "${Y}➜ Pruning Docker...${N}"
    docker system prune -a -f 2>/dev/null

    echo -ne "\n${C}Delete Database? [y/N]: ${N}"
    read DEL_DB
    if [[ "$DEL_DB" == "y" ]]; then
        echo -ne "${W}DB Name: ${N}"; read DBN
        echo -ne "${W}DB User: ${N}"; read DBU
        mysql -e "DROP DATABASE IF EXISTS $DBN; DROP USER IF EXISTS '$DBU'@'127.0.0.1';" 2>/dev/null
        echo -e "${G}✔ Database cleared.${N}"
    fi

    echo -e "\n${G}✔ Uninstallation Finished.${N}"
    sleep 2
}

# --- MAIN LOOP ---

# 1. Detect System Info ONCE at startup
echo -e "${C}Please wait, detecting system info...${N}"
detect_system

while true; do
    header
    show_menu
    
    echo -ne "${C}root@mack-panel:~# ${N}"
    read opt
    
    case $opt in
        1) ssl_setup ;;
        2) bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/wings/wings.sh) ;;
        3) bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/wings/auto1.sh) ;;
        4) bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/wings/database.sh) ;;
        5) uninstall_menu ;;
        0) 
           echo -e "\n${G}👋 Goodbye!${N}"
           exit 0 
           ;;
        *) 
           echo -e "${R}Invalid Option.${N}"
           sleep 1 
           ;;
    esac
done
