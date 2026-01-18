#!/bin/bash

# ==========================================
#  CYBERPUNK UI THEME
# ==========================================

# --- COLORS ---
NEON_GREEN="\e[1;32m"
NEON_CYAN="\e[1;36m"
WHITE="\e[1;37m"
GRAY="\e[0;90m"
RED="\e[1;31m"
RESET="\e[0m"

# --- EFFECTS ---

# Typing effect for text
type_write() {
    text="$1"
    delay=0.02
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

# Block progress bar
loading_bar() {
    echo -ne "${NEON_GREEN}[ SYSTEM ]${RESET} "
    for i in {1..20}; do
        echo -ne "█"
        sleep 0.04
    done
    echo -e " ${NEON_CYAN}COMPLETE${RESET}"
}

# --- HEADER ---
clear
echo -e "${NEON_GREEN}"
cat << "BANNER"
   ____  ____  ____  ____  ____ 
  (  _ \(  __)(  _ \(_  _)(  _ \
   ) __/ ) _)  )   /  )(   )   /
  (__)  (____)(__\_) (__) (__\_)
BANNER
echo -e "${RESET}"
echo -e "${GRAY} :: PTERODACTYL AUTO-DEPLOYMENT SYSTEM :: ${RESET}"
echo -e "${GRAY} ---------------------------------------- ${RESET}"
echo ""

# --- BOOT SEQUENCE ---
echo -ne "${NEON_GREEN} [+] ${RESET}"
type_write "Initializing kernel modules..."
echo -ne "${NEON_GREEN} [+] ${RESET}"
type_write "Checking environment variables..."
sleep 0.5
loading_bar
echo ""

# --- INPUT SECTION ---
echo -e "${NEON_CYAN}>> CONFIGURATION REQUIRED <<${RESET}"
echo ""

# Domain
type_write "ENTER TARGET DOMAIN:"
echo -ne "${NEON_GREEN} ➜  ${RESET}"
read DOMAIN
DOMAIN=${DOMAIN:-panel.example.com}

echo ""
echo -e "${NEON_CYAN}>> EXECUTING ROOT PROTOCOLS...${RESET}"
# Add install logic here

# --- Dependencies ---
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "ubuntu" ]]; then
    echo "✅ Detected Ubuntu. Adding PPA for PHP..."
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    echo "✅ Detected Debian. Skipping PPA and adding PHP repo manually..."
    # Add SURY PHP repo for Debian
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Add Redis GPG key and repo
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

apt update

# --- Install PHP + extensions ---
apt install -y php8.3 php8.3-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server

# --- Install Composer ---
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# --- Download Pterodactyl Panel ---
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# --- MariaDB Setup ---
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=yourPassword
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"

# --- .env Setup ---
if [ ! -f ".env.example" ]; then
    curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
fi
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi

# --- Install PHP dependencies ---
echo "✅ Installing PHP dependencies..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# --- Generate Application Key ---
echo "✅ Generating application key..."
php artisan key:generate --force

# --- Run Migrations ---
php artisan migrate --seed --force

# --- Permissions ---
chown -R www-data:www-data /var/www/pterodactyl/*
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
# --- Nginx Setup ---
mkdir -p /etc/certs/panel
cd /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem

tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf || true
nginx -t && systemctl restart nginx
ok "Nginx online"

# --- Queue Worker ---
tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
ok "Queue running"
clear
step "Create admin user"
# --- Admin User ---
cd /var/www/pterodactyl
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
php artisan p:user:make

# ---------------- DONE ----------------
line
echo -e "${C_GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY${C_RESET}"
line
echo -e "${C_CYAN}🌐 Panel URL    : ${C_WHITE}https://${DOMAIN}${C_RESET}"
echo -e "${C_CYAN}🗄 DB User      : ${C_WHITE}${DB_USER}${C_RESET}"
echo -e "${C_CYAN}🔑 DB Password  : ${C_WHITE}${DB_PASS}${C_RESET}"
line
echo -e "${C_PURPLE}🚀 Panel live. Control the servers.${C_RESET}"
line
