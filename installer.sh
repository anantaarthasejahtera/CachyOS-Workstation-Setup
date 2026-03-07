#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation Installer — TUI Panel
#  Uses `dialog` for aesthetic terminal GUI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
source "$MODULES_DIR/00-common.sh"

# ─── Catppuccin Mocha .dialogrc ──────────────────────────
setup_dialog_theme() {
    cat > "$HOME/.dialogrc" << 'DRCEOF'
# Catppuccin Mocha theme for dialog
use_shadow = OFF
use_colors = ON

screen_color = (WHITE,BLACK,ON)
shadow_color = (BLACK,BLACK,ON)

dialog_color = (WHITE,BLACK,OFF)
title_color = (MAGENTA,BLACK,ON)
border_color = (MAGENTA,BLACK,ON)

button_active_color = (BLACK,MAGENTA,ON)
button_inactive_color = (WHITE,BLACK,OFF)
button_key_active_color = (BLACK,MAGENTA,ON)
button_key_inactive_color = (MAGENTA,BLACK,OFF)
button_label_active_color = (BLACK,MAGENTA,ON)
button_label_inactive_color = (WHITE,BLACK,ON)

inputbox_color = (WHITE,BLACK,OFF)
inputbox_border_color = (BLUE,BLACK,ON)

searchbox_color = (WHITE,BLACK,OFF)
searchbox_title_color = (MAGENTA,BLACK,ON)
searchbox_border_color = (BLUE,BLACK,ON)

position_indicator_color = (MAGENTA,BLACK,ON)

menubox_color = (WHITE,BLACK,OFF)
menubox_border_color = (BLUE,BLACK,ON)

item_color = (WHITE,BLACK,OFF)
item_selected_color = (BLACK,MAGENTA,ON)

tag_color = (CYAN,BLACK,ON)
tag_selected_color = (BLACK,MAGENTA,ON)
tag_key_color = (CYAN,BLACK,ON)
tag_key_selected_color = (BLACK,MAGENTA,ON)

check_color = (WHITE,BLACK,OFF)
check_selected_color = (BLACK,MAGENTA,ON)

uarrow_color = (BLUE,BLACK,ON)
darrow_color = (BLUE,BLACK,ON)

gauge_color = (MAGENTA,BLACK,ON)

border2_color = (BLUE,BLACK,ON)
inputbox_border2_color = (BLUE,BLACK,ON)
searchbox_border2_color = (BLUE,BLACK,ON)
menubox_border2_color = (BLUE,BLACK,ON)
DRCEOF
}

# ─── Define Modules ──────────────────────────────────────
# Format: "tag" "description" "status"
declare -A MODULE_SCRIPTS
declare -A MODULE_SIZES

MODULE_SCRIPTS[01]="01-base.sh";      MODULE_SIZES[01]="~2 GB"
MODULE_SCRIPTS[02]="02-kernel.sh";    MODULE_SIZES[02]="~0 MB"
MODULE_SCRIPTS[03]="03-security.sh";  MODULE_SIZES[03]="~50 MB"
MODULE_SCRIPTS[04]="04-dev.sh";       MODULE_SIZES[04]="~4 GB"
MODULE_SCRIPTS[05]="05-mobile.sh";    MODULE_SIZES[05]="~5 GB"
MODULE_SCRIPTS[06]="06-dotfiles.sh";  MODULE_SIZES[06]="~100 MB"
MODULE_SCRIPTS[07]="07-editors.sh";   MODULE_SIZES[07]="~700 MB"
MODULE_SCRIPTS[08]="08-desktop.sh";   MODULE_SIZES[08]="~300 MB"
MODULE_SCRIPTS[09]="09-hyprland.sh";  MODULE_SIZES[09]="~200 MB"
MODULE_SCRIPTS[10]="10-apps.sh";      MODULE_SIZES[10]="~500 MB"
MODULE_SCRIPTS[11]="11-gaming.sh";    MODULE_SIZES[11]="~3 GB"
MODULE_SCRIPTS[12]="12-vm.sh";        MODULE_SIZES[12]="~2 GB"
MODULE_SCRIPTS[13]="13-waybar.sh";    MODULE_SIZES[13]="~5 MB"
MODULE_SCRIPTS[14]="14-nexus-guide.sh"; MODULE_SIZES[14]="~1 MB"
MODULE_SCRIPTS[15]="15-ecosystem.sh"; MODULE_SIZES[15]="~1 MB"

# Module order for execution
MODULE_ORDER=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15)

# ─── Welcome Screen ─────────────────────────────────────
show_welcome() {
    dialog --title " 🚀 CachyOS Workstation Setup " \
        --msgbox "\n\
    ╔══════════════════════════════════════╗\n\
    ║  🚀  CachyOS Workstation Installer  ║\n\
    ║  ──────────────────────────────────  ║\n\
    ║  Theme: Catppuccin Mocha            ║\n\
    ║  Modules: 15 (fully modular)        ║\n\
    ║  Tools: 50+ pre-configured          ║\n\
    ║  Guide: 160+ searchable entries     ║\n\
    ║                                      ║\n\
    ║  Select modules on next screen.      ║\n\
    ║  All checked = full install.         ║\n\
    ║  Uncheck what you don't need.        ║\n\
    ╚══════════════════════════════════════╝\n" \
        20 50
}

# ─── Module Selector ─────────────────────────────────────
select_modules() {
    local result
    result=$(dialog --title " 📦 Select Modules " \
        --checklist "\nSpace = toggle, Enter = confirm\n" 26 65 14 \
        "01" "Base & GPU Drivers         [${MODULE_SIZES[01]}]" ON \
        "02" "Kernel & Performance       [${MODULE_SIZES[02]}]" ON \
        "03" "Security & Maintenance     [${MODULE_SIZES[03]}]" ON \
        "04" "Dev Tools (Node,Py,Rust,Go)[${MODULE_SIZES[04]}]" ON \
        "05" "Mobile Dev (Flutter)       [${MODULE_SIZES[05]}]" ON \
        "06" "Shell & Dotfiles           [${MODULE_SIZES[06]}]" ON \
        "07" "Editors (Antigravity)      [${MODULE_SIZES[07]}]" ON \
        "08" "Desktop Theme (KDE)        [${MODULE_SIZES[08]}]" ON \
        "09" "Hyprland WM                [${MODULE_SIZES[09]}]" ON \
        "10" "Extra Apps (Browser, etc)  [${MODULE_SIZES[10]}]" ON \
        "11" "Gaming (Steam, PCSX2)      [${MODULE_SIZES[11]}]" OFF \
        "12" "Windows VM & Bottles       [${MODULE_SIZES[12]}]" OFF \
        "13" "Waybar Status Bar          [${MODULE_SIZES[13]}]" ON \
        "14" "Nexus & Guide System       [${MODULE_SIZES[14]}]" ON \
        "15" "Living Ecosystem Utils     [${MODULE_SIZES[15]}]" ON \
        3>&1 1>&2 2>&3)

    echo "$result"
}

# ─── Confirmation ────────────────────────────────────────
confirm_install() {
    local selected="$1"
    local count
    count=$(echo "$selected" | wc -w)

    dialog --title " ✅ Confirm Installation " \
        --yesno "\nYou selected $count modules:\n\n$selected\n\nProceed with installation?" \
        12 50
}

# ─── Run Modules with Progress ───────────────────────────
run_modules() {
    local selected="$1"
    local modules=($selected)
    local total=${#modules[@]}
    local current=0

    for mod in "${modules[@]}"; do
        # Remove quotes from dialog output
        mod=$(echo "$mod" | tr -d '"')
        current=$((current + 1))
        local script="${MODULE_SCRIPTS[$mod]}"
        local percent=$(( (current * 100) / total ))

        # Show progress
        (
            echo "XXX"
            echo "$percent"
            echo "\nInstalling module $current/$total: $script\n"
            echo "XXX"
        ) | dialog --title " ⚡ Installing... " \
            --gauge "\nStarting installation..." 10 60 0 &
        local dialog_pid=$!

        # Run the actual module
        log "━━━ Running: $script ($current/$total) ━━━"
        if bash "$MODULES_DIR/$script" >> "$LOGFILE" 2>&1; then
            ok "Module $script completed"
        else
            warn "Module $script had errors (check log)"
        fi

        # Kill the gauge dialog
        kill $dialog_pid 2>/dev/null || true
        wait $dialog_pid 2>/dev/null || true
    done

    # Final progress
    dialog --title " ⚡ Installing... " \
        --gauge "\n✅ All modules installed!" 10 60 100
    sleep 2
}

# ─── Post-Install Summary ───────────────────────────────
show_summary() {
    dialog --title " 🎉 Setup Complete! " \
        --msgbox "\n\
    ╔══════════════════════════════════════╗\n\
    ║    🎉 Installation Complete!         ║\n\
    ╠══════════════════════════════════════╣\n\
    ║                                      ║\n\
    ║  Please reboot your system:          ║\n\
    ║  $ sudo reboot                       ║\n\
    ║                                      ║\n\
    ║  After reboot:                       ║\n\
    ║  • Super+X    → Nexus Command Center ║\n\
    ║  • Super+D    → App Launcher         ║\n\
    ║  • guide      → Searchable Help      ║\n\
    ║  • ff         → System Info          ║\n\
    ║                                      ║\n\
    ║  Log: ~/cachy-setup.log              ║\n\
    ╚══════════════════════════════════════╝\n" \
        22 50
}

# ─── Main Flow ───────────────────────────────────────────
main() {
    # Pre-flight
    if [ "$EUID" -eq 0 ]; then
        err "Do NOT run as root. Run as normal user."
        exit 1
    fi

    # Ensure dialog is available (CachyOS base should have it)
    if ! command -v dialog &>/dev/null; then
        echo "Installing dialog..."
        sudo pacman -S --noconfirm dialog
    fi

    # Setup Catppuccin theme for dialog
    setup_dialog_theme

    # Check for --all flag (skip selector, install everything)
    if [[ "${1:-}" == "--all" ]]; then
        log "Installing ALL modules..."
        for mod in "${MODULE_ORDER[@]}"; do
            local script="${MODULE_SCRIPTS[$mod]}"
            log "━━━ Running: $script ━━━"
            bash "$MODULES_DIR/$script"
        done
        return
    fi

    # Interactive flow
    show_welcome

    local selected
    selected=$(select_modules)

    if [ -z "$selected" ]; then
        dialog --title " Cancelled " --msgbox "\nNo modules selected. Exiting." 7 40
        exit 0
    fi

    confirm_install "$selected" || exit 0

    # Clear dialog and run
    clear
    echo -e "${BOLD}${PURPLE}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║   🚀 Installing selected modules...  ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}"
    echo "  Log: $LOGFILE"
    echo ""

    run_modules "$selected"

    show_summary

    clear
    echo ""
    echo -e "${GREEN}${BOLD}  🎉 Setup complete! Reboot with: sudo reboot${NC}"
    echo -e "  Log: ${CYAN}$LOGFILE${NC}"
    echo ""
}

main "$@"
