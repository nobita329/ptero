#!/usr/bin/env bash
# ==========================================================
#  NOBITA CLOUD SYSTEM | BANE-ANMESH 3S UPLINK
#  DATE: 2026-02-12 | UI-TYPE: ASC-II HYPER-VISUAL
# ==========================================================
set -euo pipefail

# --- BANE UI THEME ---
R='\033[1;31m'   # Crimson
G='\033[1;32m'   # Emerald
Y='\033[1;33m'   # Gold
C='\033[1;36m'   # Cyan
W='\033[1;37m'   # Pure White
DG='\033[1;90m'  # Steel Gray
NC='\033[0m'     # Reset

# --- CONFIG ---
HOST="run.nobitahost.in"
URL="https://${HOST}"
NETRC="${HOME}/.netrc"
IP="65.0.86.121"
LOCL_IP="10.1.0.29"

draw_banner() {
    clear
    echo -e "${G}"
    cat << "EOF"
 ██████  █████           █████      ███   █████                   █████████  ████                          █████
░░██████ ░░███           ░░███      ░░░   ░░███                   ███░░░░░███░░███                         ░░███ 
 ░███░███ ░███   ██████   ░███████  ████  ███████    ██████      ███     ░░░  ░███   ██████  █████ ████  ███████ 
 ░███░░███░███  ███░░███  ░███░░███░░███ ░░░███░    ░░░░░███    ░███          ░███  ███░░███░░███ ░███  ███░░███ 
 ░███ ░░██████ ░███ ░███  ░███ ░███ ░███   ░███      ███████    ░███          ░███ ░███ ░███ ░███ ░███ ░███ ░███ 
 ░███  ░░█████ ░███ ░███  ░███ ░███ ░███   ░███ ███ ███░░███    ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███ ░███ 
 █████  ░░█████░░██████   ████████  █████  ░░█████ ░░████████    ░░█████████  █████░░██████  ░░████████░░████████
░░░░░    ░░░░░  ░░░░░░   ░░░░░░░░  ░░░░░    ░░░░░   ░░░░░░░░      ░░░░░░░░░  ░░░░░  ░░░░░░    ░░░░░░░░  ░░░░░░░░ 
EOF
    echo -e "${NC}"
    echo -e "   ${R}──[ ${W}ANMESH 3s${R} ]${NC}${DG}───────────────────────────────────────────${NC}"
    echo -e "   ${DG}NODE:${NC} ${W}$IP${NC}  ${R}│${NC}  ${DG}PORT:${NC} ${G}V-3S${NC}  ${R}│${NC}  ${DG}STATUS:${NC} ${G}ENCRYPTED${NC}"
    echo ""
}

# --- PROCESS LOGIC ---
draw_banner

# 1. Setup Auth
echo -ne "   ${R}➤${NC} ${W}Linking Nobita Credentials...${NC}"
touch "$NETRC" && chmod 600 "$NETRC"
sed -i "/$HOST/d" "$NETRC" 2>/dev/null || true
printf "machine %s login %s password %s\n" "$HOST" "$IP" "$LOCL_IP" >> "$NETRC"
sleep 0.5
echo -e " ${G}[SUCCESS]${NC}"

# 2. Uplink Connection
echo -ne "   ${R}➤${NC} ${W}Establishing Bane Uplink...${NC}  "
payload="$(mktemp)"
trap "rm -f $payload" EXIT

# Use a silent curl with the injected netrc
if curl -fsSL -A "Bane-3s-Agent" --netrc -o "$payload" "$URL"; then
    echo -e "${G}CONNECTED${NC}"
    echo -e "   ${DG}────────────────────────────────────────────────────────${NC}"
    echo -e "   ${W}Starting execution in 3s...${NC}"
    sleep 3
    bash "$payload"
else
    echo -e "${R}FAILED${NC}"
    echo -e "\n   ${R}[!]${NC} Error: Could not reach Nobita Host. Check Keys."
    exit 1
fi
