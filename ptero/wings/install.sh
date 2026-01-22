#!/bin/bash

# ==================================================
#  WINGS AUTO-INSTALLER v2.0 | CYBER EDITION
# ==================================================

# --- PALETTE ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

# --- UI ENGINE ---

# Hide Cursor
trap 'tput cnorm; echo -e "${C_RESET}"' EXIT
tput civis

draw_header() {
    clear
    local host=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    local os=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    local kernel=$(uname -r)

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_BOLD}${C_WHITE}PTERODACTYL WINGS INSTALLER${C_RESET} ${C_GRAY}::${C_RESET} ${C_CYAN}AUTOMATION SUITE${C_RESET}               ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}HOST:${C_RESET} ${C_WHITE}$host${C_RESET}   ${C_GRAY}IP:${C_RESET} ${C_WHITE}$ip${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}OS  :${C_RESET} ${C_WHITE}$os${C_RESET}   ${C_GRAY}KER:${C_RESET} ${C_WHITE}$kernel${C_RESET}"
    echo -e "${C_BLUE}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

msg_step() {
    echo -e "${C_PURPLE} :: ${C_BOLD}${C_WHITE}$1${C_RESET}"
    echo -e "${C_GRAY} ──────────────────────────────────────────${C_RESET}"
}

# $1 = Message, $2 = Command
run_task() {
    local msg="$1"
    local cmd="$2"
    local pid
    local spin='-\|/'
    local i=0

    echo -ne "   ${C_CYAN}➜${C_RESET} $msg... "
    
    # Run command silently
    eval "$cmd" > /dev/null 2>&1 &
    pid=$!

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\b${C_BLUE}${spin:$i:1}${C_RESET}"
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf "\r   ${C_GREEN}✔${C_RESET} $msg                                \n"
    else
        printf "\r   ${C_RED}✖${C_RESET} $msg ${C_RED}[FAILED]${C_RESET}\n"
        echo -e "\n${C_RED}Error executing: $cmd${C_RESET}"
        exit 1
    fi
}

# --- PRE-CHECKS ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${C_RED}✖ Error:${C_RESET} Please run as root."
    exit 1
fi

draw_header

# ------------------------
# 1. DOCKER SETUP
# ------------------------
msg_step "CONTAINER ENGINE SETUP"

if ! command -v docker >/dev/null 2>&1; then
    run_task "Downloading Docker Script" "curl -sSL https://get.docker.com/ -o /tmp/get-docker.sh"
    run_task "Installing Docker Engine" "sh /tmp/get-docker.sh"
    run_task "Enabling Docker Service" "systemctl enable --now docker"
else
    echo -e "   ${C_GREEN}✔${C_RESET} Docker is already installed."
fi
echo ""

# ------------------------
# 2. SYSTEM CONFIG
# ------------------------
msg_step "SYSTEM CONFIGURATION"

GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    if ! grep -q "swapaccount=1" "$GRUB_FILE"; then
        run_task "Enabling Swap Accounting" "sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"swapaccount=1\"/' $GRUB_FILE"
        run_task "Updating GRUB Config" "update-grub"
    else
        echo -e "   ${C_GREEN}✔${C_RESET} Swap Accounting active."
    fi
else
    echo -e "   ${C_YELLOW}⚠${C_RESET} GRUB not found (Container?). Skipping."
fi
echo ""

# ------------------------
# 3. WINGS BINARY
# ------------------------
msg_step "WINGS BINARY INSTALLATION"

run_task "Creating Directories" "mkdir -p /etc/pterodactyl"

ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then 
    DL_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
elif [ "$ARCH" == "aarch64" ]; then
    DL_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
else
    echo -e "   ${C_RED}✖ Unsupported Architecture: $ARCH${C_RESET}"
    exit 1
fi

run_task "Downloading Binary ($ARCH)" "curl -L -o /usr/local/bin/wings '$DL_URL'"
run_task "Setting Permissions" "chmod u+x /usr/local/bin/wings"
echo ""

# ------------------------
# 4. SERVICE SETUP
# ------------------------
msg_step "SERVICE CONFIGURATION"

cat <<EOF > /tmp/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

run_task "Creating Systemd Unit" "mv /tmp/wings.service /etc/systemd/system/wings.service"
run_task "Reloading Daemon" "systemctl daemon-reload"
run_task "Enabling Wings on Boot" "systemctl enable wings"
echo ""

# ------------------------
# 5. SSL SETUP
# ------------------------
msg_step "SECURITY & SSL"

run_task "Creating Cert Directory" "mkdir -p /etc/certs/wing"
run_task "Generating Self-Signed Cert" "openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj '/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate' -keyout /etc/certs/wing/privkey.pem -out /etc/certs/wing/fullchain.pem"
echo ""

# ------------------------
# 6. HELPER SCRIPT
# ------------------------
msg_step "FINALIZING"

cat <<'EOF' > /usr/local/bin/wing
#!/bin/bash
BLUE='\033[0;34m'
NC='\033[0m'
echo -e "${BLUE}:: WINGS CONTROLLER ::${NC}"
echo "  start    : systemctl start wings"
echo "  stop     : systemctl stop wings"
echo "  restart  : systemctl restart wings"
echo "  logs     : journalctl -u wings -f"
echo "  status   : systemctl status wings"
echo ""
EOF

run_task "Installing 'wing' Shortcut" "chmod +x /usr/local/bin/wing"
echo ""

# ------------------------
# COMPLETION
# ------------------------
echo -e "${C_GREEN}${C_BOLD}  ✅ INSTALLATION SUCCESSFUL${C_RESET}"
echo -e "${C_GRAY}  ──────────────────────────────────────────${C_RESET}"
echo -e "  ${C_WHITE}Next Steps:${C_RESET}"
echo -e "  1. Configure your node in the Panel."
echo -e "  2. Paste the configuration content into: ${C_CYAN}/etc/pterodactyl/config.yml${C_RESET}"
echo -e "  3. Start wings: ${C_GREEN}systemctl start wings${C_RESET}"
echo ""
echo -e "  ${C_GRAY}Shortcut command installed: Type ${C_WHITE}wing${C_GRAY} to manage the service.${C_RESET}"
echo ""
