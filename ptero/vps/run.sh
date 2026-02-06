#!/bin/bash

# ==================================================
#   DEV ENVIRONMENT MANAGER | v3.0
# ==================================================

# --- COLORS & STYLES ---
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[37m"; N="\e[0m"
BOLD="\e[1m"

# --- UTILS ---
pause() { echo; read -p "↩ Press Enter to return..." _; }

# --- HEADER ---
draw_header() {
    clear
    
    # Gather Info
    local user=$(whoami)
    local host=$(hostname)
    local time=$(date '+%H:%M')
    
    # KVM Check
    local kvm_status="${R}NO ${N}"
    if [ -e /dev/kvm ]; then kvm_status="${G}YES${N}"; fi

    # Dynamic Formatting using printf
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${N}"
    echo -e "${C}║${W}${BOLD}              🛠️  DEV ENVIRONMENT MANAGER v3.0               ${C}║${N}"
    echo -e "${C}╠══════════════════════════════════════════════════════════════╣${N}"
    echo -e "${C}║${M} SYSTEM INFO:${N}                                                 ${C}║${N}"
    
    # Data Lines
    printf "${C}║${W} • User :${N} %-20s ${W}• Host :${N} %-21s ${C}║${N}\n" "$user" "$host"
    printf "${C}║${W} • Time :${N} %-20s ${W}• KVM Support :${N} %-14b ${C}║${N}\n" "$time" "$kvm_status"
    
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
    btop
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
    bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/vm-1.sh)
    pause
}

# --- 3. VM 2 (NO KVM) ---
run_vm_2() {
    echo -e "${M}🌐 LAUNCHING VM 2 (NO KVM MODE)...${N}"
    bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/auto.sh)
    pause
}

# --- 4. PANEL SUB-MENU ---
panel_menu() {
    while true; do
        clear
        echo -e "${Y}╔════════════════════════════════════════╗${N}"
        echo -e "${Y}║          CONTROL PANELS MENU           ║${N}"
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
        apt update && apt install lxd lxc-client curl wget -y
        sudo usermod -aG lxd $USER
        sudo usermod -aG lxd root
        bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/lxcc.sh)
        echo -e "${G}✅ Installed. Please logout/login.${N}"
    else
        echo -e "${G}✔ LXD is already installed.${N}"
    fi
    pause
}

# --- 6. DOCKER ---
docker_setup() {
    echo -e "${C}🐳 DOCKER MANAGER${N}"
    if ! command -v docker &>/dev/null; then
        echo -e "${Y}Installing Docker...${N}"
        bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/Docker.sh)
    else
        echo -e "${G}✔ Docker is already installed.${N}"
    fi
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
