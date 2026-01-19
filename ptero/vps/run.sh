#!/bin/bash

# ==================================================
#  DEV ENVIRONMENT MANAGER | v3.0
# ==================================================

# --- COLORS & STYLES ---
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[37m"; N="\e[0m"
BOLD="\e[1m"

# --- UTILS ---
pause() { echo; read -p "↩ Press Enter to return..." _; }

# --- HEADER ---
draw_header() {
    clear
    local user=$(whoami)
    local host=$(hostname)
    local time=$(date '+%H:%M')
    local kvm_status="${R}NO${N}"
    if [ -e /dev/kvm ]; then kvm_status="${G}YES${N}"; fi

    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${N}"
    echo -e "${C}║${W}${BOLD}              🛠️  DEV ENVIRONMENT MANAGER v3.0                 ${C}║${N}"
    echo -e "${C}╠══════════════════════════════════════════════════════════════╣${N}"
    echo -e "${C}║${M} SYSTEM INFO:${N}                                                 ${C}║${N}"
    echo -e "${C}║${W} • User :${N} $user          ${W}• Host :${N} $host           ${C}║${N}"
    echo -e "${C}║${W} • Time :${N} $time          ${W}• KVM Support :${N} $kvm_status    ${C}║${N}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${N}"
    echo
}

# --- 1. RDX / IDX TOOL ---
setup_idx() {
    echo -e "${C}🔧 SETTING UP RDX / IDX ENVIRONMENT...${N}"
    cd "$HOME" || return
    rm -rf myapp flutter
    mkdir -p "$HOME/vm/.idx"
    cd "$HOME/vm/.idx" || return

    if [ -f "dev.nix" ]; then
        echo -e "${Y}⚠ Config exists.${N}"
    else
        cat <<EOF > dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = { };
    };

    previews = {
      enable = false;
    };
  };
}
EOF
        echo -e "${G}✅ Config created.${N}"
    fi
    pause
}

# --- 2. VM 1 (KVM) ---
run_vm_1() {
    echo -e "${B}🌐 LAUNCHING VM 1 (KVM MODE)...${N}"
    bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/vm/vm.sh)
    pause
}

# --- 3. VM 2 (NO KVM) ---
run_vm_2() {
    echo -e "${M}🌐 LAUNCHING VM 2 (NO KVM MODE)...${N}"
    bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/vm/dd.sh)
    bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/vm/vm2.sh)
    pause
}

# --- 4. PANEL SUB-MENU ---
panel_menu() {
    while true; do
        clear
        echo -e "${Y}╔════════════════════════════════════════╗${N}"
        echo -e "${Y}║         CONTROL PANELS MENU            ║${N}"
        echo -e "${Y}╚════════════════════════════════════════╝${N}"
        echo -e " ${G}[1]${N} Install Cockpit    ${C}(Web VM Manager)"
        echo -e " ${G}[2]${N} Install CasaOS     ${C}(Home Cloud UI)"
        echo -e " ${G}[3]${N} Install 1Panel     ${C}(Modern Hosting)"
        echo -e " ${R}[0]${N} Back to Main Menu"
        echo
        read -p " ➤ Select Panel: " p_opt
        
        case $p_opt in
            1) 
                echo -e "${B}➜ Installing Cockpit...${N}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/cockpit.sh)
                echo -e "${G}✅ Done. Access at http://IP:9090${N}"; pause 
                ;;
            2) 
                echo -e "${B}➜ Installing CasaOS...${N}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/casaos.sh)
                pause 
                ;;
            3) 
                echo -e "${B}➜ Installing 1Panel...${N}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/1panel.sh)
                pause 
                ;;
            0) return ;;
            *) echo -e "${R}Invalid Option${N}"; sleep 1 ;;
        esac
    done
}

# --- 5. LXC/LXD ---
lxc_setup() {
    echo -e "${G}📦 LXC/LXD MANAGER${N}"
    if ! command -v lxc &>/dev/null; then
        echo -e "${Y}Installing LXD...${N}"
        sudo usermod -aG lxd $USER
        sudo usermod -aG lxd root
        bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/lxc.sh)
        echo -e "${G}✅ Installed. Please logout/login.${N}"
    else
        echo -e "${C}LXD is installed.${N}"
        echo "1. List Containers"
        echo "2. Launch Ubuntu 22.04"
        read -p "Choice: " c
        if [ "$c" == "1" ]; then lxc list; fi
        if [ "$c" == "2" ]; then read -p "Name: " n; lxc launch ubuntu:22.04 "$n"; fi
    fi
    pause
}

# --- 6. DOCKER ---
docker_setup() {
    echo -e "${C}🐳 DOCKER MANAGER${N}"
    if ! command -v docker &>/dev/null; then
        echo -e "${Y}Installing Docker...${N}"
        bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/Docker.sh)
    pause
}

# --- MAIN MENU LOOP ---
while true; do
    draw_header
    
    echo -e "${W} MAIN MENU:${N}"
    echo -e " ${G}[1]${N} RDX/IDX Tool Setup"
    echo -e " ${Y}[2]${N} VM - 1 (KVM Supported)"
    echo -e " ${M}[3]${N} VM - 2 (No KVM / QEMU)"
    echo -e " ${C}[4]${N} PANEL"
    echo -e " ${B}[5]${N} LXC/LXD"
    echo -e " ${B}[6]${N} Docker"
    echo -e " ${R}[0]${N} Exit"
    echo
    read -p " ➤ Select Option: " opt
    
    case $opt in
        1) setup_idx ;;
        2) run_vm_1 ;;
        3) run_vm_2 ;;
        4) panel_menu ;;
        5) lxc_setup ;;
        6) docker_setup ;;
        0) 
            echo -e "\n${G}👋 Goodbye!${N}"
            exit 0 
            ;;
        *) 
            echo -e "\n${R}❌ Invalid Option${N}"
            sleep 1 
            ;;
    esac
done
