#!/bin/bash
# ===========================================================
# WINGS AUTO-INSTALLER - OBSIDIAN NEXT GEN (v11.7)
# Style: Full Segmented UI / Nobita Edition / Auto-Detect
# ===========================================================

# --- 0. PRE-INITIALIZATION ---
hostnamectl set-hostname Nobita 2>/dev/null

# --- CLEAN COLORS ---
B_BLUE='\033[1;38;5;33m'
B_CYAN='\033[1;38;5;51m'
B_PURPLE='\033[1;38;5;141m'
B_GREEN='\033[1;38;5;82m'
B_RED='\033[1;38;5;196m'
GOLD='\033[38;5;220m'
W='\033[1;38;5;255m'
G='\033[0;38;5;244m'
BG_SHADE='\033[48;5;236m' 
NC='\033[0m'

# --- UI ENGINE ---
tput civis
trap 'tput cnorm; echo -ne "${NC}"' EXIT

# --- ROBUST METRICS (Zero Leak Fix) ---
get_metrics() {
    # CPU Load
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
    [[ -z "$CPU" ]] && CPU="0"
    
    # RAM Load
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}' 2>/dev/null)
    [[ -z "$RAM" ]] && RAM="0"
    
    UPT=$(uptime -p | sed 's/up //')
    IP=$(hostname -I | awk '{print $1}')
    OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    CURRENT_HOST=$(hostname)
}

draw_header() {
    clear
    get_metrics
    # Top Status Bar
    echo -e " ${B_BLUE}${NC}${BG_SHADE}${W}   HOST: $CURRENT_HOST ${NC}${B_BLUE}${NC}  ${B_PURPLE}${NC}${BG_SHADE}${W}   $UPT ${NC}${B_PURPLE}${NC}  ${B_GREEN}${NC}${BG_SHADE}${W} 🌐 IP: $IP ${NC}${B_GREEN}${NC}"
    echo -e ""

    # Big Custom Banner
    echo -e "${B_CYAN} ██████╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗      ██╗  ██╗██╗   ██╗██████╗ ${NC}"
    echo -e "${B_CYAN}██╔════╝██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝      ██║  ██║██║   ██║██╔══██╗${NC}"
    echo -e "${B_PURPLE}██║     ██║   ██║██║  ██║██║██╔██╗ ██║██║  ███╗     ███████║██║   ██║██████╔╝${NC}"
    echo -e "${B_PURPLE}██║     ██║   ██║██║  ██║██║██║╚██╗██║██║   ██║     ██╔══██║██║   ██║██╔══██╗${NC}"
    echo -e "${GOLD}╚██████╗╚██████╔╝██████╔╝██║██║ ╚████║╚██████╔╝     ██║  ██║╚██████╔╝██████╔╝${NC}"
    echo -e "${GOLD} ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝      ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ${NC}"
    
    echo -e "  ${G}───────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${W}System Stats:${NC} ${G}CPU:${NC} ${B_CYAN}${CPU}%${NC}  ${G}RAM:${NC} ${B_PURPLE}${RAM}%${NC}  ${G}Target OS:${NC} ${W}$OS${NC}"
    echo ""
}

msg_step() {
    echo -e "  ${B_PURPLE}${NC}${BG_SHADE}${W} 🛠️  $1 ${NC}${B_PURPLE}${NC}"
    echo -e "  ${G}└──────────────────────────────────────────────────────────${NC}"
}

run_task() {
    local msg="$1"
    local cmd="$2"
    local spin='-\|/'
    local i=0

    echo -ne "    ${B_CYAN}➜${NC} $msg... "
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\b${B_BLUE}${spin:$i:1}${NC}"
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r    ${B_GREEN}✔${NC} $msg                                \n"
    else
        printf "\r    ${B_RED}✖${NC} $msg ${B_RED}[FAILED]${NC}\n"
        exit 1
    fi
}

# --- PROCESS START ---

if [ "$EUID" -ne 0 ]; then
    echo -e "  ${B_RED}✖ Error:${NC} Please run as root."
    exit 1
fi

draw_header

# 1. DOCKER SETUP
msg_step "CONTAINER ENGINE SETUP"
if ! command -v docker >/dev/null 2>&1; then
    run_task "Detecting Environment" "sleep 1"
    run_task "Installing Docker Engine" "curl -sSL https://get.docker.com/ | sh"
    run_task "Enabling Docker Service" "systemctl enable --now docker"
else
    echo -e "    ${B_GREEN}✔${NC} Docker is already active."
fi
echo ""

# 2. WINGS BINARY (AUTO-DETECT ARCH)
msg_step "WINGS CORE INSTALLATION"
run_task "Creating Directories" "mkdir -p /etc/pterodactyl"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then 
    DL_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
elif [ "$ARCH" == "aarch64" ]; then
    DL_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
else
    echo -e "    ${B_RED}✖ Unsupported Arch: $ARCH${NC}"
    exit 1
fi

run_task "Downloading Binary ($ARCH)" "curl -L -o /usr/local/bin/wings '$DL_URL'"
run_task "Setting Permissions" "chmod u+x /usr/local/bin/wings"
echo ""

# 3. SERVICE SETUP
msg_step "SYSTEMD CONFIGURATION"
cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

run_task "Reloading Daemons" "systemctl daemon-reload"
run_task "Enabling Wings Service" "systemctl enable wings"
echo ""

# 4. SSL SETUP
msg_step "SECURITY & AUTO-SSL"
run_task "Generating Self-Signed Cert" "mkdir -p /etc/certs/wing && cd /etc/certs/wing && openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj '/C=NA/ST=NA/L=NA/O=NA/CN=Nobita' -keyout /etc/certs/wing/privkey.pem -out /etc/certs/wing/fullchain.pem"
echo ""

# 5. COMPLETION
echo -e "  ${B_GREEN}${NC}${BG_SHADE}${W} ✅ WINGS READY FOR NOBITA ${NC}${B_GREEN}${NC}"
echo -e "  ${G}─────────────────────────────────────────────────────────────${NC}"
echo -e "  ${W}Next Steps:${NC}"
echo -e "  ${B_CYAN}1.${NC} Paste config in: ${B_PURPLE}/etc/pterodactyl/config.yml${NC}"
echo -e "  ${B_CYAN}2.${NC} Run: ${B_GREEN}systemctl start wings${NC}"
echo -e "  ${B_CYAN}3.${NC} Manage with shortcut: ${B_GREEN}wing${NC}"
echo ""

# Shortcut command
cat <<'EOF' > /usr/local/bin/wing
#!/bin/bash
echo -e "\033[1;34m:: WINGS CONTROLLER ::\033[0m"
echo "  start/stop/restart/status/logs"
EOF
chmod +x /usr/local/bin/wing
