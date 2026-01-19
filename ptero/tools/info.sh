#!/bin/bash

# ==================================================
#  OMNI-ADMIN v50 | 50 TOOLS IN ONE SCRIPT
# ==================================================

# --- THEME & COLORS ---
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[37m"; N="\e[0m"
BOLD="\e[1m"

# --- CONFIG ---
LOG_FILE="$HOME/omni_admin.log"
BACKUP_DIR="$HOME/omni_backups"
mkdir -p "$BACKUP_DIR"

# --- UTILS ---
pause() { echo; read -p "↩ Press Enter to return..." _; }
log() { echo "[$(date '+%T')] $1" >> "$LOG_FILE"; }
header() { clear; echo -e "${C}══ OMNI-ADMIN v50 ══${N} | ${Y}$(hostname)${N} | ${G}$(date '+%R')${N}"; echo -e "${B}────────────────────────────────────────${N}"; }

# --- AUTO INSTALLER ---
need() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${Y}➜ Installing $1...${N}"
        if command -v apt &>/dev/null; then sudo apt install -y "$1" -qq >/dev/null
        elif command -v yum &>/dev/null; then sudo yum install -y "$1" -q
        fi
    fi
}

# ==================================================
#  CATEGORY 1: SYSTEM & HARDWARE (Tools 1-10)
# ==================================================
menu_system() {
    header
    echo -e "${M} [ SYSTEM & HARDWARE ]${N}"
    echo -e "${G} 1.${N} OS Information      ${G} 6.${N} CPU Info (Detailed)"
    echo -e "${G} 2.${N} Ram Usage           ${G} 7.${N} Hardware Lister (lshw)"
    echo -e "${G} 3.${N} Disk Usage          ${G} 8.${N} USB Devices"
    echo -e "${G} 4.${N} Load Average        ${G} 9.${N} Kernel Version"
    echo -e "${G} 5.${N} Uptime History      ${G}10.${N} Sensor Temps"
    echo -e "${R} 0. Back${N}"
    echo
    read -p "Select Tool (1-10): " opt
    case $opt in
        1) hostnamectl ;;
        2) free -h ;;
        3) df -hT | grep -v tmpfs ;;
        4) echo "Load: $(uptime | awk -F'load average:' '{print $2}')" ;;
        5) uptime -p ;;
        6) lscpu | head -15 ;;
        7) need lshw; sudo lshw -short ;;
        8) lsusb ;;
        9) uname -sr ;;
        10) need lm-sensors; sensors ;;
        0) return ;;
        *) echo "Invalid";;
    esac
    pause
}

# ==================================================
#  CATEGORY 2: NETWORK & INTERNET (Tools 11-20)
# ==================================================
menu_network() {
    header
    echo -e "${B} [ NETWORK & INTERNET ]${N}"
    echo -e "${G}11.${N} Public/Local IP     ${G}16.${N} Active Connections"
    echo -e "${G}12.${N} Ping Test (Google)  ${G}17.${N} Listening Ports"
    echo -e "${G}13.${N} DNS Lookup          ${G}18.${N} Route Table"
    echo -e "${G}14.${N} Speedtest           ${G}19.${N} Live Traffic (iftop)"
    echo -e "${G}15.${N} Traceroute          ${G}20.${N} Bandwidth (nload)"
    echo -e "${R} 0. Back${N}"
    echo
    read -p "Select Tool (11-20): " opt
    case $opt in
        11) echo "Public: $(curl -s ifconfig.me)"; echo "Local: $(hostname -I)" ;;
        12) ping -c 4 google.com ;;
        13) read -p "Domain: " d; nslookup "$d" ;;
        14) need speedtest-cli; speedtest-cli --simple ;;
        15) read -p "Target: " t; traceroute "$t" ;;
        16) ss -tuna ;;
        17) ss -tuln ;;
        18) ip route show ;;
        19) need iftop; sudo iftop ;;
        20) need nload; nload ;;
        0) return ;;
        *) echo "Invalid";;
    esac
    pause
}

# ==================================================
#  CATEGORY 3: SECURITY & AUDIT (Tools 21-30)
# ==================================================
menu_security() {
    header
    echo -e "${R} [ SECURITY & AUDIT ]${N}"
    echo -e "${G}21.${N} Firewall Status     ${G}26.${N} Sudo Users"
    echo -e "${G}22.${N} Fail2Ban Status     ${G}27.${N} File Permissions"
    echo -e "${G}23.${N} Last Logins         ${G}28.${N} Rootkit Check"
    echo -e "${G}24.${N} Failed Auths        ${G}29.${N} SSH Config Audit"
    echo -e "${G}25.${N} Who Is Online       ${G}30.${N} Process Audit (top)"
    echo -e "${R} 0. Back${N}"
    echo
    read -p "Select Tool (21-30): " opt
    case $opt in
        21) sudo ufw status 2>/dev/null || sudo firewall-cmd --state ;;
        22) systemctl status fail2ban | head -10 ;;
        23) last -n 10 ;;
        24) sudo grep "Failed password" /var/log/auth.log | tail -10 ;;
        25) w ;;
        26) grep '^sudo:.*$' /etc/group | cut -d: -f4 ;;
        27) read -p "File: " f; ls -l "$f" ;;
        28) need rkhunter; sudo rkhunter --check --sk ;;
        29) grep -E "^(PermitRootLogin|PasswordAuth)" /etc/ssh/sshd_config ;;
        30) htop ;;
        0) return ;;
        *) echo "Invalid";;
    esac
    pause
}

# ==================================================
#  CATEGORY 4: MAINTENANCE & OPS (Tools 31-40)
# ==================================================
menu_maintenance() {
    header
    echo -e "${Y} [ MAINTENANCE & OPS ]${N}"
    echo -e "${G}31.${N} Update System       ${G}36.${N} Restart Service"
    echo -e "${G}32.${N} Clean Cache         ${G}37.${N} Stop Service"
    echo -e "${G}33.${N} Vacuum Journal      ${G}38.${N} User Manager"
    echo -e "${G}34.${N} View Syslog         ${G}39.${N} Cron Jobs"
    echo -e "${G}35.${N} Backup Directory    ${G}40.${N} History Cleaner"
    echo -e "${R} 0. Back${N}"
    echo
    read -p "Select Tool (31-40): " opt
    case $opt in
        31) sudo apt update && sudo apt upgrade -y ;;
        32) sudo apt autoremove -y && sudo apt clean ;;
        33) sudo journalctl --vacuum-time=1d ;;
        34) tail -n 20 /var/log/syslog ;;
        35) read -p "Dir to Backup: " d; tar -czf "$BACKUP_DIR/bkp_$(date +%s).tar.gz" "$d"; echo "Done." ;;
        36) read -p "Service: " s; sudo systemctl restart "$s" ;;
        37) read -p "Service: " s; sudo systemctl stop "$s" ;;
        38) echo "1. Add 2. Del"; read -p "> " a; if [ "$a" == "1" ]; then read -p "User: " u; sudo adduser "$u"; else read -p "User: " u; sudo deluser "$u"; fi ;;
        39) crontab -l ;;
        40) history -c && echo "History Cleared" ;;
        0) return ;;
        *) echo "Invalid";;
    esac
    pause
}

# ==================================================
#  CATEGORY 5: APPS & EXTRAS (Tools 41-50)
# ==================================================
menu_apps() {
    header
    echo -e "${C} [ APPS & EXTRAS ]${N}"
    echo -e "${G}41.${N} Docker Stats        ${G}46.${N} Matrix Screensaver"
    echo -e "${G}42.${N} Docker Containers   ${G}47.${N} Weather Info"
    echo -e "${G}43.${N} Nginx Status        ${G}48.${N} Calendar"
    echo -e "${G}44.${N} MySQL Status        ${G}49.${N} Calculator (bc)"
    echo -e "${G}45.${N} Python Version      ${G}50.${N} Text Editor"
    echo -e "${R} 0. Back${N}"
    echo
    read -p "Select Tool (41-50): " opt
    case $opt in
        41) docker stats --no-stream ;;
        42) docker ps -a ;;
        43) systemctl status nginx --no-pager ;;
        44) systemctl status mysql --no-pager ;;
        45) python3 --version ;;
        46) need cmatrix; cmatrix ;;
        47) curl wttr.in ;;
        48) cal ;;
        49) read -p "Math: " m; echo "$m" | bc ;;
        50) nano ;;
        0) return ;;
        *) echo "Invalid";;
    esac
    pause
}

# ==================================================
#  MAIN DASHBOARD
# ==================================================
while true; do
    clear
    # LIVE DASHBOARD WIDGET
    CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    RAM=$(free -m | awk '/Mem/ {printf "%.1f", $3/$2*100}')
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    
    echo -e "${C}╔══════════════════════════════════════════════════════╗${N}"
    echo -e "${C}║${W}${BOLD}              OMNI-ADMIN v50 - DASHBOARD              ${C}║${N}"
    echo -e "${C}╠══════════════════════════════════════════════════════╣${N}"
    echo -e "${C}║${Y} CPU: ${G}${CPU}%${N}   ${Y}RAM: ${G}${RAM}%${N}   ${Y}DISK: ${G}${DISK}${N}   ${Y}UPTIME: ${G}$(uptime -p | cut -d' ' -f2-)${N} ${C}║${N}"
    echo -e "${C}╚══════════════════════════════════════════════════════╝${N}"
    
    echo -e "\n${BOLD}SELECT A CATEGORY:${N}"
    echo -e " ${M}[1]${N} System & Hardware    ${C}(Tools 1-10)"
    echo -e " ${B}[2]${N} Network & Internet   ${C}(Tools 11-20)"
    echo -e " ${R}[3]${N} Security & Audit     ${C}(Tools 21-30)"
    echo -e " ${Y}[4]${N} Maintenance & Ops    ${C}(Tools 31-40)"
    echo -e " ${C}[5]${N} Apps & Extras        ${C}(Tools 41-50)"
    echo -e " ${W}[0]${N} Exit"
    echo
    read -p "Option > " main_opt
    
    case $main_opt in
        1) menu_system ;;
        2) menu_network ;;
        3) menu_security ;;
        4) menu_maintenance ;;
        5) menu_apps ;;
        0) echo -e "${C}Exiting Omni-Admin...${N}"; exit 0 ;;
        *) echo -e "${R}Invalid Option${N}"; sleep 1 ;;
    esac
done
