#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Nexus — Command Center for CachyOS Workstation
#  Trigger: Super+X (Hyprland keybind)
#  UI: Rofi popup with Catppuccin Mocha theme
#  RAM: 0 MB idle — only runs when invoked
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── Catppuccin Mocha Colors ───────────────────────────────
BG="#1e1e2e"
BG_ALT="#313244"
FG="#cdd6f4"
ACCENT="#cba6f7"
RED="#f38ba8"
GREEN="#a6e3a1"
BLUE="#89b4fa"

# ─── Menu Entries (icon | label | command) ─────────────────
# Format: "icon  Label" → mapped to command in case statement

declare -A COMMANDS
ENTRIES=""

add_entry() {
    ENTRIES+="$1\n"
    COMMANDS["$1"]="$2"
}

# ── Quick Actions ──
add_entry "  System Update"          "kitty --hold -e bash -c 'sudo pacman -Syu && flatpak update -y && echo Done!'"
add_entry "  Cleanup Packages"       "kitty --hold -e bash -c 'sudo pacman -Sc --noconfirm; pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null; echo ✅ Cleanup done'"
add_entry "󰒲  Lock Screen"            "hyprlock"
add_entry "  Power Off"              "systemctl poweroff"
add_entry "  Reboot"                 "systemctl reboot"
add_entry "  Logout"                 "hyprctl dispatch exit"

# ── Screenshots & Recording ──
add_entry "  Screenshot (Region)"    "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && notify-send '📸 Screenshot saved'"
add_entry "  Screenshot (Full)"      "grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && notify-send '📸 Screenshot saved'"
add_entry "  Record Screen"          "wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4 & notify-send '🎥 Recording started' 'Press Super+X → Stop to end'"
add_entry "  Stop Recording"         "pkill -SIGINT wf-recorder && notify-send '🎥 Recording saved'"

# ── AI & Productivity ──
add_entry "󰧑  AI Chat (Reasoning)"    "kitty -e ollama run qwen3:30b-a3b"
add_entry "  AI Code Assistant"      "kitty -e ollama run qwen2.5-coder:7b"
add_entry "  AI Math/Logic"          "kitty -e ollama run deepseek-r1:7b"
add_entry "  Search Guide"           "kitty -e guide"
add_entry "  Obsidian Notes"         "obsidian &"

# ── Development ──
add_entry "  Antigravity"            "antigravity &"
add_entry "  Neovim"                 "kitty -e nvim"
add_entry "  Docker Manager"         "kitty -e lazydocker"
add_entry "  Flutter Doctor"         "kitty --hold -e flutter doctor"
add_entry "  Phone Mirror (scrcpy)"  "scrcpy &"

# ── Apps ──
add_entry "  Zen Browser"            "zen-browser &"
add_entry "  File Manager"           "thunar &"
add_entry "  Steam"                  "steam &"
add_entry "  Minecraft"              "prismlauncher &"
add_entry "  PS2 Emulator"           "pcsx2 &"
add_entry "  Roblox"                 "flatpak run org.vinegarhq.Sober &"

# ── System ──
add_entry "  System Monitor"         "kitty -e btm"
add_entry "  VM Manager"             "virt-manager &"
add_entry "  Bottles (Windows)"      "flatpak run com.usebottles.bottles &"
add_entry "  Password Manager"       "keepassxc &"
add_entry "  LibreOffice Writer"     "libreoffice --writer &"
add_entry "  OBS Studio"             "obs &"
add_entry "  KDE Connect"            "kdeconnect-app &"
add_entry "  Audio Settings"         "pavucontrol &"
add_entry "  WiFi Settings"          "kitty --hold -e nmtui"
add_entry "  Bluetooth"              "blueman-manager &"

# ── Info ──
add_entry "  System Info"            "kitty --hold -e fastfetch"
add_entry "  Disk Usage"             "kitty --hold -e duf"
add_entry "  Public IP"              "notify-send \"🌐 Public IP\" \"$(curl -s ifconfig.me)\""

# ─── Launch Rofi ──────────────────────────────────────────
CHOSEN=$(echo -e "$ENTRIES" | sed '/^$/d' | rofi -dmenu \
    -i \
    -p " Nexus" \
    -theme-str "
        * {
            font: \"JetBrainsMono Nerd Font 12\";
            bg: $BG;
            bg-alt: $BG_ALT;
            fg: $FG;
            accent: $ACCENT;
            red: $RED;
            green: $GREEN;
            blue: $BLUE;
        }
        window {
            width: 420px;
            border: 2px;
            border-color: $ACCENT;
            border-radius: 16px;
            background-color: $BG;
            transparency: \"real\";
            location: center;
        }
        mainbox {
            background-color: transparent;
        }
        inputbar {
            background-color: $BG_ALT;
            border-radius: 12px;
            padding: 10px 16px;
            margin: 12px;
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
            placeholder: \"Search...\";
            placeholder-color: #6c7086;
        }
        listview {
            columns: 1;
            lines: 12;
            scrollbar: false;
            background-color: transparent;
            padding: 0 8px 8px 8px;
        }
        element {
            padding: 8px 16px;
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

# ─── Execute Selected Command ─────────────────────────────
if [ -n "$CHOSEN" ]; then
    CMD="${COMMANDS[$CHOSEN]}"
    if [ -n "$CMD" ]; then
        eval "$CMD" &
    fi
fi
