#!/bin/bash

# Colors
G="\e[32m"; R="\e[31m"; Y="\e[33m"; C="\e[36m"; W="\e[0m"

# Detect IPs
PUBLIC_IP=$(curl -s ifconfig.me)
LOCAL_IP=$(hostname -I | awk '{print $1}')

CONTAINER="xrdp-server"
IMAGE="danielguerra/ubuntu-xrdp"

install_xrdp() {
    echo -e "${C}Installing Docker XRDP...${W}"

    if ! command -v docker &>/dev/null; then
        echo -e "${Y}Docker not found, installing...${W}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker --now
    fi

    docker rm -f $CONTAINER 2>/dev/null

    docker pull $IMAGE

    docker run -d \
    --name $CONTAINER \
    -p 3389:3389 \
    --privileged \
    --restart unless-stopped \
    $IMAGE

    echo -e "${G}XRDP Installed Successfully!${W}"
    show_info
}

uninstall_xrdp() {
    echo -e "${R}Removing XRDP Container...${W}"
    docker rm -f $CONTAINER 2>/dev/null
    echo -e "${G}XRDP Uninstalled!${W}"
}

status_xrdp() {
    echo -e "${C}XRDP Status:${W}"
    docker ps | grep $CONTAINER || echo "❌ Not Running"
}

show_info() {
    echo -e "${C}====================================${W}"
    echo -e "${G}🖥️ XRDP READY${W}"
    echo -e "${C}Public IP : ${Y}$PUBLIC_IP${W}"
    echo -e "${C}Local IP  : ${Y}$LOCAL_IP${W}"
    echo -e "${C}Port      : ${Y}3389${W}"
    echo -e "${C}Username  : ${Y}ubuntu${W}"
    echo -e "${C}Password  : ${Y}ubuntu${W}"
    echo -e "${C}====================================${W}"
}

menu() {
clear
echo -e "${C}====================================${W}"
echo -e "${G}   🖥️ DOCKER XRDP PRO MANAGER${W}"
echo -e "${C}====================================${W}"
echo -e "${Y}Public IP : ${W}$PUBLIC_IP"
echo -e "${Y}Local IP  : ${W}$LOCAL_IP"
echo -e "${C}------------------------------------${W}"
echo -e "${G}1) Install XRDP${W}"
echo -e "${R}2) Uninstall XRDP${W}"
echo -e "${C}3) XRDP Status${W}"
echo -e "${Y}4) Show Login Info${W}"
echo -e "${R}0) Exit${W}"
echo -e "${C}====================================${W}"
read -p "Select Option: " opt

case $opt in
1) install_xrdp ;;
2) uninstall_xrdp ;;
3) status_xrdp ;;
4) show_info ;;
0) exit ;;
*) echo "Invalid Option" ;;
esac

read -p "Press Enter to return..." tmp
menu
}

menu

