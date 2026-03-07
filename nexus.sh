#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Nexus v2 — Smart Command Center for CachyOS Workstation
#  Trigger: Super+X (Hyprland keybind)
#  Features:
#    • Dynamic system stats header (battery, RAM, disk)
#    • Live service status (Docker, VM, recording)
#    • Smart app detection (only show installed apps)
#    • Smart recording toggle (start/stop based on state)
#    • Catppuccin Mocha themed rofi popup
#    • Near-zero RAM (only runs when invoked)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── Catppuccin Mocha Colors ───────────────────────────────
BG="#1e1e2e"
BG_ALT="#313244"
BG_SURFACE="#45475a"
FG="#cdd6f4"
ACCENT="#cba6f7"
RED="#f38ba8"
GREEN="#a6e3a1"
BLUE="#89b4fa"
YELLOW="#f9e2af"
TEAL="#94e2d5"
PINK="#f5c2e7"

# ─── System Stats Collection ──────────────────────────────
get_battery() {
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        local cap=$(cat /sys/class/power_supply/BAT0/capacity)
        local status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        if [ "$status" = "Charging" ]; then
            echo "󰂄 ${cap}%"
        elif [ "$cap" -le 20 ]; then
            echo "󰂃 ${cap}%"
        elif [ "$cap" -le 50 ]; then
            echo "󰁾 ${cap}%"
        else
            echo "󰁹 ${cap}%"
        fi
    else
        echo "󰚥 AC"
    fi
}

get_ram() {
    local used total
    read -r total used <<< $(free -m | awk '/Mem:/ {print $2, $3}')
    local percent=$(( (used * 100) / total ))
    local gb_used=$(awk "BEGIN {printf \"%.1f\", $used/1024}")
    local gb_total=$(awk "BEGIN {printf \"%.0f\", $total/1024}")
    if [ "$percent" -ge 80 ]; then
        echo "󰍛 ${gb_used}/${gb_total}GB"
    else
        echo "󰍛 ${gb_used}/${gb_total}GB"
    fi
}

get_disk() {
    local avail=$(df -h / | awk 'NR==2 {print $4}')
    echo "󰋊 ${avail} free"
}

get_cpu_temp() {
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "󰔏 $((temp/1000))°C"
    fi
}

# ─── Service Status Indicators ────────────────────────────
status_icon() {
    if "$@" &>/dev/null; then echo "🟢"; else echo "🔴"; fi
}

# ─── Build Dynamic Menu ──────────────────────────────────
build_menu() {
    local entries=""
    
    # ── Header: Live System Stats ──
    local bat=$(get_battery)
    local ram=$(get_ram)
    local disk=$(get_disk)
    local temp=$(get_cpu_temp)
    entries+="── $bat  │  $ram  │  $disk  │  $temp ──\n"
    entries+="─────────────────────────────────────────\n"

    # ── Quick Actions ──
    entries+="  System Update (pacman + flatpak)\n"
    entries+="  Cleanup Packages & Cache\n"
    entries+="󰒲  Lock Screen\n"
    entries+="  Power Off\n"
    entries+="  Reboot\n"
    entries+="  Logout (Hyprland)\n"
    entries+="─────────────────────────────────────────\n"

    # ── Smart Screenshot & Recording ──
    entries+="  Screenshot — Region (slurp)\n"
    entries+="  Screenshot — Full Screen\n"
    
    # Smart recording toggle
    if pgrep -x wf-recorder &>/dev/null; then
        entries+="  Stop Recording (currently recording...)\n"
    else
        entries+="  Record Screen (full)\n"
        entries+="  Record Region (select area)\n"
    fi
    entries+="─────────────────────────────────────────\n"

    # ── AI Tools (only show if ollama installed) ──
    if command -v ollama &>/dev/null; then
        local ollama_status=""
        if pgrep -x ollama &>/dev/null; then
            ollama_status="🟢"
        else
            ollama_status="🔴"
        fi
        entries+="  󰧑  AI Chat — Reasoning (qwen3) $ollama_status\n"
        entries+="  󰧑  AI Chat — Code (qwen2.5-coder) $ollama_status\n"
        entries+="  󰧑  AI Chat — Math/Logic (deepseek-r1) $ollama_status\n"
        entries+="  🧠 AI Auto-Tuner (Suggest Optimizations) $ollama_status\n"
    fi
    entries+="─────────────────────────────────────────\n"

    # ── Development (dynamic detection) ──
    command -v antigravity &>/dev/null && entries+="  Antigravity (AI Editor)\n"
    command -v nvim &>/dev/null && entries+="  Neovim\n"
    
    if command -v docker &>/dev/null; then
        local DOCKER_STATUS=""
        if systemctl is-active docker &>/dev/null; then
            DOCKER_STATUS="🟢"
        else
            DOCKER_STATUS="🔴"  
        fi
        entries+="  Docker Manager (lazydocker) $DOCKER_STATUS\n"
    fi
    
    command -v flutter &>/dev/null && entries+="  Flutter Doctor\n"
    command -v scrcpy &>/dev/null && entries+="  Phone Mirror (scrcpy)\n"
    entries+="  🏪 GUI App Store (Browse & Install)\n"
    entries+="─────────────────────────────────────────\n"

    # ── Apps (dynamic detection) ──
    command -v zen-browser &>/dev/null && entries+="  Zen Browser\n"
    command -v firefox &>/dev/null && ! command -v zen-browser &>/dev/null && entries+="  Firefox\n"
    command -v thunar &>/dev/null && entries+="  File Manager\n"
    command -v obsidian &>/dev/null && entries+="  Obsidian Notes\n" || \
        flatpak list 2>/dev/null | grep -qi obsidian && entries+="  Obsidian Notes\n"
    command -v keepassxc &>/dev/null && entries+="  Password Manager\n"
    entries+="─────────────────────────────────────────\n"

    # ── Gaming (dynamic detection) ──
    local has_gaming=false
    if command -v steam &>/dev/null; then
        entries+="  Steam\n"; has_gaming=true
    fi
    command -v prismlauncher &>/dev/null && { entries+="  Minecraft\n"; has_gaming=true; }
    command -v pcsx2 &>/dev/null && { entries+="  PS2 Emulator\n"; has_gaming=true; }
    flatpak list 2>/dev/null | grep -qi sober && { entries+="  Roblox\n"; has_gaming=true; }
    $has_gaming && entries+="─────────────────────────────────────────\n"

    # ── System & Productivity ──
    if command -v virt-manager &>/dev/null; then
        local vm_status=""
        if virsh list 2>/dev/null | grep -q running; then
            vm_status="🟢 VM running"
        else
            vm_status="🔴"
        fi
        entries+="  Virtual Machine Manager $vm_status\n"
    fi
    
    flatpak list 2>/dev/null | grep -qi bottles && entries+="  Bottles (Windows Apps)\n"
    command -v libreoffice &>/dev/null && entries+="  LibreOffice\n"
    command -v obs &>/dev/null && entries+="  OBS Studio\n"
    command -v kdeconnect-cli &>/dev/null && entries+="  KDE Connect\n"
    entries+="─────────────────────────────────────────\n"

    # ── System Tools ──
    entries+="  🛡️ Time Machine (Config Rollback)\n"
    entries+="  ☁️ Dotfiles Cloud Sync\n"
    entries+="  System Monitor (btm)\n"
    entries+="  Disk Usage\n"
    entries+="  System Info (fastfetch)\n"
    entries+="  Public IP\n"
    entries+="  Audio Settings\n"
    entries+="  WiFi Settings\n"
    command -v blueman-manager &>/dev/null && entries+="  Bluetooth\n"
    entries+="  🎨 Dynamic Theme Switcher\n"
    entries+="─────────────────────────────────────────\n"
    
    # ── Search ──
    entries+="  Guide Popup (160+ entries)\n"
    entries+="  Guide in Terminal (fzf + preview)\n"
    entries+="  cheat.sh Web Lookup\n"

    echo -e "$entries"
}

# ─── Command Dispatcher ──────────────────────────────────
execute_action() {
    local chosen="$1"
    
    case "$chosen" in
        *"GUI App Store"*)
            ~/.local/bin/app-store &
            ;;
        *"AI Auto-Tuner"*)
            ~/.local/bin/ai-tuner &
            ;;
        *"Dotfiles Cloud Sync"*)
            ~/.local/bin/dotfiles-sync &
            ;;
        *"Time Machine"*)
            ~/.local/bin/config-rollback &
            ;;
        *"Dynamic Theme Switcher"*)
            ~/.local/bin/theme-switch &
            ;;
        *"System Update"*)
            kitty --hold -e bash -c 'echo "🔄 Updating system..."; sudo pacman -Syu && flatpak update -y 2>/dev/null && rustup update 2>/dev/null; echo ""; echo "✅ Update complete!"' ;;
        *"Cleanup"*)
            kitty --hold -e bash -c 'echo "🧹 Cleaning up..."; sudo pacman -Sc --noconfirm; pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null; echo "✅ Cleanup done"' ;;
        *"Lock Screen"*)
            hyprlock ;;
        *"Power Off"*)
            systemctl poweroff ;;
        *"Reboot"*)
            systemctl reboot ;;
        *"Logout"*)
            hyprctl dispatch exit ;;
        
        # Screenshots
        *"Screenshot"*"Region"*)
            grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && \
                notify-send "📸 Screenshot saved" "~/Pictures/Screenshots/" ;;
        *"Screenshot"*"Full"*)
            grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && \
                notify-send "📸 Screenshot saved" "~/Pictures/Screenshots/" ;;
        
        # Recording (smart toggle)
        *"Stop Recording"*)
            pkill -SIGINT wf-recorder && \
                notify-send "🎥 Recording saved" "~/Videos/" ;;
        *"Record Screen"*)
            wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4 & disown
            notify-send "🎥 Recording started" "Super+X → Stop to end" ;;
        *"Record Region"*)
            wf-recorder -g "$(slurp)" -f ~/Videos/clip-$(date +%Y%m%d-%H%M%S).mp4 & disown
            notify-send "🎥 Recording region" "Super+X → Stop to end" ;;
        
        # AI
        *"AI Chat"*"Reasoning"*|*"qwen3"*)
            if ! pgrep -x ollama &>/dev/null; then ollama serve &>/dev/null & sleep 1; fi
            kitty -e ollama run qwen3:30b-a3b ;;
        *"AI Chat"*"Code"*|*"qwen2.5-coder"*)
            if ! pgrep -x ollama &>/dev/null; then ollama serve &>/dev/null & sleep 1; fi
            kitty -e ollama run qwen2.5-coder:7b ;;
        *"AI Chat"*"Math"*|*"deepseek-r1"*)
            if ! pgrep -x ollama &>/dev/null; then ollama serve &>/dev/null & sleep 1; fi
            kitty -e ollama run deepseek-r1:7b ;;
        
        # Dev
        *"Antigravity"*)     antigravity & ;;
        *"Neovim"*)          kitty -e nvim ;;
        *"Docker Manager"*)  kitty -e lazydocker ;;
        *"Flutter Doctor"*)  kitty --hold -e flutter doctor ;;
        *"Phone Mirror"*)    scrcpy & ;;
        
        # Apps
        *"Zen Browser"*)     zen-browser & ;;
        *"Firefox"*)         firefox & ;;
        *"File Manager"*)    thunar & ;;
        *"Obsidian"*)        (obsidian || flatpak run md.obsidian.Obsidian) &>/dev/null & ;;
        *"Password"*)        keepassxc & ;;
        
        # Gaming
        *"Steam"*)           steam & ;;
        *"Minecraft"*)       prismlauncher & ;;
        *"PS2"*)             pcsx2 & ;;
        *"Roblox"*)          flatpak run org.vinegarhq.Sober & ;;
        
        # System
        *"Virtual Machine"*) virt-manager & ;;
        *"Bottles"*)         flatpak run com.usebottles.bottles & ;;
        *"LibreOffice"*)     libreoffice --writer & ;;
        *"OBS"*)             obs & ;;
        *"KDE Connect"*)     kdeconnect-app & ;;
        *"System Monitor"*)  kitty -e btm ;;
        *"Disk Usage"*)      kitty --hold -e duf ;;
        *"System Info"*)     kitty --hold -e fastfetch ;;
        *"Public IP"*)       notify-send "🌐 Public IP" "$(curl -s ifconfig.me)" ;;
        *"Audio"*)           pavucontrol & ;;
        *"WiFi"*)            kitty --hold -e nmtui ;;
        *"Bluetooth"*)       blueman-manager & ;;
        *"Guide Popup"*)     guide --popup ;;
        *"Guide in Terminal"*) kitty -e guide ;;
        *"cheat.sh"*)        kitty -e bash -c 'echo -n "🔍 Enter topic: "; read q; guide --web "$q"' ;;
    esac
}

# ─── Launch Rofi ──────────────────────────────────────────
CHOSEN=$(build_menu | sed '/^$/d' | rofi -dmenu \
    -i \
    -p " Nexus" \
    -mesg "Super+X · $(get_battery) · $(get_ram)" \
    -theme-str "
        * {
            font: \"JetBrainsMono Nerd Font 11\";
            bg: $BG;
            bg-alt: $BG_ALT;
            bg-surface: $BG_SURFACE;
            fg: $FG;
            accent: $ACCENT;
            red: $RED;
            green: $GREEN;
            blue: $BLUE;
        }
        window {
            width: 460px;
            border: 2px;
            border-color: $ACCENT;
            border-radius: 16px;
            background-color: $BG;
            transparency: \"real\";
            location: center;
        }
        mainbox {
            background-color: transparent;
            spacing: 0;
        }
        inputbar {
            background-color: $BG_ALT;
            border-radius: 12px;
            padding: 10px 16px;
            margin: 12px 12px 4px 12px;
            children: [prompt, textbox-prompt-colon, entry];
        }
        prompt {
            background-color: transparent;
            text-color: $ACCENT;
            font: \"JetBrainsMono Nerd Font Bold 13\";
        }
        textbox-prompt-colon {
            str: \"\";
            background-color: transparent;
        }
        entry {
            background-color: transparent;
            text-color: $FG;
            placeholder: \"Search actions...\";
            placeholder-color: #6c7086;
        }
        message {
            background-color: $BG_ALT;
            border-radius: 8px;
            margin: 4px 12px;
            padding: 6px 12px;
        }
        textbox {
            background-color: transparent;
            text-color: #6c7086;
            font: \"JetBrainsMono Nerd Font 9\";
        }
        listview {
            columns: 1;
            lines: 16;
            scrollbar: false;
            background-color: transparent;
            padding: 4px 8px 8px 8px;
            fixed-height: false;
        }
        element {
            padding: 6px 16px;
            border-radius: 10px;
            background-color: transparent;
            text-color: $FG;
        }
        element selected {
            background-color: $BG_ALT;
            text-color: $ACCENT;
        }
        element-text {
            background-color: transparent;
            text-color: inherit;
            vertical-align: 0.5;
        }
    ")

# ─── Execute ─────────────────────────────────────────────
if [ -n "$CHOSEN" ] && [[ ! "$CHOSEN" =~ ^─ ]]; then
    execute_action "$CHOSEN"
fi
