#!/bin/bash

# ==================================================
#  AUTO DATABASE SETUP | Production UI
# ==================================================

# --- STYLING & COLORS ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

# --- UI HELPERS ---
header() {
    clear
    echo -e "${C_BLUE}
    ╔════════════════════════════════════════════╗
    ║      ${C_BOLD}${C_WHITE}AUTO DATABASE SETUP UTILITY${C_BLUE}         ║
    ║      ${C_CYAN}MySQL/MariaDB • Remote Access${C_BLUE}         ║
    ╚════════════════════════════════════════════╝
    ${C_RESET}"
}

print_step() {
    echo -e "${C_BLUE}➜${C_RESET} ${C_BOLD}$1${C_RESET}"
}

print_success() {
    echo -e "  ${C_GREEN}✔${C_RESET} $1"
}

print_warn() {
    echo -e "  ${C_YELLOW}⚠${C_RESET} $1"
}

print_error() {
    echo -e "  ${C_RED}✖${C_RESET} $1"
}

# Spinner for long tasks (like apt install)
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "  [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

get_input() {
    # $1 = Prompt, $2 = Default, $3 = VarRef
    echo -ne "  ${C_CYAN}?${C_RESET} $1 ${C_GRAY}[$2]${C_RESET}: "
    read input
    if [ -z "$input" ]; then
        eval $3="'$2'"
    else
        eval $3="'$input'"
    fi
}

# --- START SCRIPT ---
header

# 1. Configuration Section
print_step "Configuration"
get_input "Enter Database Username" "root" DB_USER
get_input "Enter Database Password" "root" DB_PASS
echo ""

# 2. Installation Check
print_step "Checking System Requirements..."
if ! command -v mysql >/dev/null 2>&1; then
    echo -ne "  ${C_YELLOW}⟳ Installing MariaDB Server...${C_RESET}"
    
    # Run install silently in background
    (apt update -y && apt install mariadb-server mariadb-client -y) >/dev/null 2>&1 &
    spinner $!
    
    echo -e "\r  ${C_GREEN}✔ MariaDB Installed successfully.${C_RESET}   "
    systemctl enable mariadb >/dev/null 2>&1
    systemctl start mariadb >/dev/null 2>&1
else
    print_success "MariaDB is already installed."
fi

# 3. Database Operations
echo ""
print_step "Configuring Database..."

# Run SQL logic
sudo mysql <<MYSQL_SCRIPT >/dev/null 2>&1
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

if [ $? -eq 0 ]; then
    print_success "User '${C_WHITE}$DB_USER${C_GREEN}' created/updated."
    print_success "Global privileges granted."
else
    print_error "Failed to configure database user."
fi

# 4. Remote Access Logic
echo ""
print_step "Network Configuration..."

CONF_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"

if [ -f "$CONF_FILE" ]; then
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF_FILE"
    print_success "Remote access enabled (bind-address -> 0.0.0.0)."
else
    print_warn "Config file not found ($CONF_FILE). Skipping bind-address."
fi

# Restart Services
echo -ne "  ${C_YELLOW}⟳ Restarting database services...${C_RESET}"
systemctl restart mysql 2>/dev/null
systemctl restart mariadb 2>/dev/null
echo -e "\r  ${C_GREEN}✔ Database services restarted.   ${C_RESET}"

# Firewall
if command -v ufw &>/dev/null; then
    ufw allow 3306/tcp >/dev/null 2>&1
    print_success "Firewall port 3306 (TCP) opened."
else
    print_warn "UFW not detected, skipping firewall setup."
fi

# 5. Final Summary
echo ""
echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}   ✅  INSTALLATION COMPLETE${C_RESET}"
echo ""
echo -e "   ${C_GRAY}User      :${C_RESET}  ${C_WHITE}$DB_USER${C_RESET}"
echo -e "   ${C_GRAY}Password  :${C_RESET}  ${C_WHITE}$DB_PASS${C_RESET}"
echo -e "   ${C_GRAY}Remote IP :${C_RESET}  ${C_WHITE}0.0.0.0${C_RESET} ${C_GRAY}(Any)${C_RESET}"
echo -e "   ${C_GRAY}Port      :${C_RESET}  ${C_WHITE}3306${C_RESET}"
echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""
