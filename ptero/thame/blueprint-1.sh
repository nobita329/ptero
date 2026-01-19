#!/bin/bash

# ==================================================
#  BLUEPRINT v3.0 AUTO-RUN (INSTALL + FIX)
# ==================================================

# --- COLORS ---
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; W="\e[37m"; N="\e[0m"

# --- CONFIG ---
PT_DIR="/var/www/pterodactyl"

# --- 1. ROOT CHECK ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${R}❌ Error: Please run as root (sudo bash $0)${N}"
    exit 1
fi

# --- 2. HEADER ---
clear
echo -e "${B}╔══════════════════════════════════════════════════════╗${N}"
echo -e "${B}║${W}    🚀 BLUEPRINT v3.0 AUTO-INSTALLER & FIXER          ${B}║${N}"
echo -e "${B}╚══════════════════════════════════════════════════════╝${N}"
echo
echo -e "${Y}⚠️  Target Directory:${N} ${C}$PT_DIR${N}"
echo -e "${W}Starting automated sequence in 3 seconds...${N}"
sleep 3

# --- 3. SYSTEM PREP ---
echo -e "\n${B}[1/7] Checking Environment...${N}"
if [ ! -d "$PT_DIR" ]; then
    echo -e "${R}❌ Pterodactyl directory not found!${N}"
    exit 1
fi
echo -e "${G}✔ Pterodactyl found.${N}"

echo -e "\n${B}[2/7] Installing Dependencies...${N}"
apt update -y -q
apt install -y curl wget unzip ca-certificates git gnupg zip -q
echo -e "${G}✔ System packages ready.${N}"

# --- 4. NODE.JS SETUP ---
echo -e "\n${B}[3/7] Setting up Node.js 20 & Yarn...${N}"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
apt update -y -q
apt install -y nodejs -q
npm i -g yarn
echo -e "${G}✔ Node environment ready.${N}"

# --- 5. BLUEPRINT SETUP ---
echo -e "\n${B}[4/7] Downloading Blueprint Framework...${N}"
cd "$PT_DIR"
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)
wget -q "$DOWNLOAD_URL" -O "$PT_DIR/release.zip"
unzip -o -q release.zip
echo -e "${G}✔ Files extracted.${N}"

echo -e "\n${B}[5/7] Configuring Blueprint...${N}"
cat <<EOF > "$PT_DIR/.blueprintrc"
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
chmod +x "$PT_DIR/blueprint.sh"
echo -e "${G}✔ Configuration applied.${N}"

# --- 6. INSTALLATION ---
echo -e "\n${B}[6/7] Running Internal Installer...${N}"
# We execute the blueprint script. If it asks for prompts, this usually just runs through.
bash "$PT_DIR/blueprint.sh"

# --- 7. AUTO-FIX (THE v3.0 FEATURE) ---
echo -e "\n${B}[7/7] Running Auto-Fix Diagnostics...${N}"

echo -e "   ${Y}➜ Fixing Permissions...${N}"
chown -R www-data:www-data "$PT_DIR"
find "$PT_DIR" -type d -exec chmod 755 {} \;
find "$PT_DIR" -type f -exec chmod 644 {} \;
chmod +x "$PT_DIR/artisan" "$PT_DIR/blueprint.sh" 2>/dev/null

echo -e "   ${Y}➜ Ensuring Yarn Dependencies...${N}"
# Quietly ensure dependencies are installed
yarn install --production --silent

echo -e "   ${Y}➜ Clearing Panel Cache...${N}"
php artisan view:clear
php artisan config:clear
php artisan route:clear

# --- COMPLETION ---
echo -e "\n${G}══════════════════════════════════════════════════════${N}"
echo -e "${G}   🎉 COMPLETED SUCCESSFULLY!${N}"
echo -e "${W}   Blueprint is installed, permissions are fixed,${N}"
echo -e "${W}   and caches have been cleared.${N}"
echo -e "${G}══════════════════════════════════════════════════════${N}"
