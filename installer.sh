#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation Installer — TUI Panel
#  Uses `dialog` for aesthetic terminal GUI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
source "$MODULES_DIR/00-common.sh"

# Default Language
GUI_LANG="en"

loc() {
    local en="$1"
    local id="$2"
    if [ "$GUI_LANG" = "id" ]; then
        echo -e "$id"
    else
        echo -e "$en"
    fi
}

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

# ─── Language Selector ────────────────────────────────────
select_language() {
    local result
    result=$(dialog --clear --title " 🌐 Language / Bahasa " \
        --menu "\nSelect Installer Language / Pilih Bahasa Installer:\n" 12 55 2 \
        "en" "English" \
        "id" "Bahasa Indonesia" \
        3>&1 1>&2 2>&3 || true)
    
    if [ -n "$result" ]; then
        GUI_LANG="$result"
    else
        GUI_LANG="en"
    fi
}

# ─── Welcome Screen ─────────────────────────────────────
show_welcome() {
    local msg=""
    if [ "$GUI_LANG" = "id" ]; then
        msg="\n\
    ╔══════════════════════════════════════╗\n\
    ║  🚀  Installer CachyOS Workstation  ║\n\
    ║  ──────────────────────────────────  ║\n\
    ║  Tema: Catppuccin Mocha              ║\n\
    ║  Modul: 15 (modular penuh)           ║\n\
    ║  Tools: 50+ terkonfigurasi           ║\n\
    ║  Panduan: 160+ referensi command     ║\n\
    ║                                      ║\n\
    ║  Pilih modul di layar selanjutnya.   ║\n\
    ║  Centang semua = install lengkap.    ║\n\
    ║  Hapus centang yang tidak perlu.     ║\n\
    ╚══════════════════════════════════════╝\n"
    else
        msg="\n\
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
    ╚══════════════════════════════════════╝\n"
    fi

    dialog --title " $(loc '🚀 CachyOS Workstation Setup' '🚀 Setup CachyOS Workstation') " \
        --msgbox "$msg" 20 50
}

# ─── Module Selector ─────────────────────────────────────
select_modules() {
    local result
    result=$(dialog --title " $(loc '📦 Select Modules' '📦 Pilih Modul') " \
        --checklist "\n$(loc 'Space = toggle, Enter = confirm' 'Spasi = pilih, Enter = konfirmasi')\n" 26 65 14 \
        "01" "$(loc 'Base & GPU Drivers' 'Sistem Dasar & Driver GPU')         [${MODULE_SIZES[01]}]" ON \
        "02" "$(loc 'Kernel & Performance' 'Kernel Custom & Performa')       [${MODULE_SIZES[02]}]" ON \
        "03" "$(loc 'Security & Maintenance' 'Keamanan & Perawatan Otomatis')     [${MODULE_SIZES[03]}]" ON \
        "04" "$(loc 'Dev Tools (Node,Py,Rust,Go)' 'Dev Tools (Node,Py,Rust,Go)') [${MODULE_SIZES[04]}]" ON \
        "05" "$(loc 'Mobile Dev (Flutter)' 'Mobile Dev (Flutter/SDK)')       [${MODULE_SIZES[05]}]" ON \
        "06" "$(loc 'Shell & Dotfiles' 'Zsh Shell & Dotfiles')           [${MODULE_SIZES[06]}]" ON \
        "07" "$(loc 'Editors (Antigravity)' 'Code Editor (Antigravity)')      [${MODULE_SIZES[07]}]" ON \
        "08" "$(loc 'Desktop Theme (KDE)' 'Tema Desktop (KDE/SDDM)')        [${MODULE_SIZES[08]}]" ON \
        "09" "$(loc 'Hyprland WM' 'Hyprland Window Manager')                [${MODULE_SIZES[09]}]" ON \
        "10" "$(loc 'Extra Apps (Browser, etc)' 'Aplikasi (Chrome, Flatpak)')  [${MODULE_SIZES[10]}]" ON \
        "11" "$(loc 'Gaming (Steam, PCSX2)' 'Gaming (Steam, PCSX2)')      [${MODULE_SIZES[11]}]" OFF \
        "12" "$(loc 'Windows VM & Bottles' 'Windows VM & Bottles')       [${MODULE_SIZES[12]}]" OFF \
        "13" "$(loc 'Waybar Status Bar' 'Waybar Status Bar')          [${MODULE_SIZES[13]}]" ON \
        "14" "$(loc 'Nexus & Guide System' 'Nexus & Sistem Guide')       [${MODULE_SIZES[14]}]" ON \
        "15" "$(loc 'Living Ecosystem Utils' 'Utilitas Ecosystem AI')     [${MODULE_SIZES[15]}]" ON \
        3>&1 1>&2 2>&3)

    echo "$result"
}

# ─── Module Dependencies ─────────────────────────────────
# Warn about missing pairings (soft dependency — not blocking)
check_dependencies() {
    local selected="$1"
    local warnings=""

    # 13-waybar needs 09-hyprland (waybar config needs hyprland installed)
    if echo "$selected" | grep -q '"13"' && ! echo "$selected" | grep -q '"09"'; then
        warnings+="$(loc '  ⚠ Module 13 (Waybar) works best with Module 09 (Hyprland)\n' '  ⚠ Modul 13 (Waybar) butuh Modul 09 (Hyprland) untuk konfigurasi maksimal\n')"
    fi

    # 15-ecosystem needs 14-nexus-guide (ecosystem tools are accessed via Nexus)
    if echo "$selected" | grep -q '"15"' && ! echo "$selected" | grep -q '"14"'; then
        warnings+="$(loc '  ⚠ Module 15 (Ecosystem) needs Module 14 (Nexus) for GUI access\n' '  ⚠ Modul 15 (Ecosystem) butuh Modul 14 (Nexus) untuk akses GUI\n')"
    fi

    # 06-dotfiles needs module 04-dev for fnm/pnpm/rustup referenced in .zshrc
    if echo "$selected" | grep -q '"06"' && ! echo "$selected" | grep -q '"04"'; then
        warnings+="$(loc '  ⚠ Module 06 (Dotfiles) .zshrc references tools from Module 04 (Dev)\n' '  ⚠ Modul 06 (Dotfiles) menggunakan command dari Modul 04 (Dev Tools)\n')"
    fi

    # 11-gaming benefits from 02-kernel for gamemode/performance tuning
    if echo "$selected" | grep -q '"11"' && ! echo "$selected" | grep -q '"02"'; then
        warnings+="$(loc '  ⚠ Module 11 (Gaming) benefits from Module 02 (Kernel tuning)\n' '  ⚠ Modul 11 (Gaming) mendapat boost performa jika pakai Modul 02 (Kernel)\n')"
    fi

    if [ -n "$warnings" ]; then
        dialog --title " ⚠ $(loc 'Dependency Hints' 'Saran Dependensi') " \
            --msgbox "\n$(loc 'Some selected modules have dependencies:' 'Beberapa modul yang dipilih saling bergantung:')\n\n$warnings\n$(loc 'These are recommendations, not requirements.' 'Ini hanya rekomendasi, bukan kewajiban mutlak.')\n$(loc 'You may continue without them.' 'Kamu boleh lanjut tanpanya.')" 16 65
    fi
}

# ─── Confirmation ────────────────────────────────────────
confirm_install() {
    local selected="$1"
    local count
    count=$(echo "$selected" | wc -w)

    dialog --title " ✅ $(loc 'Confirm Installation' 'Konfirmasi Instalasi') " \
        --yesno "\n$(loc "You selected $count modules:" "Kamu memilih $count modul:")\n\n$selected\n\n$(loc 'Proceed with installation?' 'Lanjutkan proses instalasi?')" \
        12 55
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
            echo "\n$(loc 'Installing module' 'Menginstall modul') $current/$total: $script\n"
            echo "XXX"
        ) | dialog --title " ⚡ $(loc 'Installing...' 'Menginstall...') " \
            --gauge "\n$(loc 'Starting installation...' 'Memulai instalasi...')" 10 60 0 &
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
    dialog --title " ⚡ $(loc 'Installing...' 'Menginstall...') " \
        --gauge "\n✅ $(loc 'All modules installed!' 'Semua modul berhasil diinstall!')" 10 60 100
    sleep 2
}

# ─── Post-Install Summary ───────────────────────────────
show_summary() {
    local msg=""
    if [ "$GUI_LANG" = "id" ]; then
        msg="\n\
    ╔══════════════════════════════════════╗\n\
    ║    🎉 Instalasi Selesai!             ║\n\
    ╠══════════════════════════════════════╣\n\
    ║                                      ║\n\
    ║  Silahkan reboot sistem kamu:        ║\n\
    ║  $ sudo reboot                       ║\n\
    ║                                      ║\n\
    ║  Setelah reboot:                     ║\n\
    ║  • Super+X    → Nexus Command Center ║\n\
    ║  • Super+D    → App Launcher (Rofi)  ║\n\
    ║  • guide      → Panduan Interaktif   ║\n\
    ║  • ff         → Info Sistem          ║\n\
    ║                                      ║\n\
    ║  Log: ~/cachy-setup.log              ║\n\
    ╚══════════════════════════════════════╝\n"
    else
        msg="\n\
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
    ╚══════════════════════════════════════╝\n"
    fi

    dialog --title " 🎉 $(loc 'Setup Complete!' 'Setup Selesai!') " \
        --msgbox "$msg" 22 50
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

    # Check for --all flag (skip selector, install everything via run_modules)
    if [[ "${1:-}" == "--all" ]]; then
        log "Installing ALL modules via run_modules()..."
        # Build selection string matching what dialog outputs
        local all_modules=""
        for mod in "${MODULE_ORDER[@]}"; do
            all_modules+="\"$mod\" "
        done
        run_modules "$all_modules"
        show_summary
        return
    fi

    # Interactive flow
    select_language
    show_welcome

    local selected
    selected=$(select_modules)

    if [ -z "$selected" ]; then
        dialog --title " Cancelled " --msgbox "\nNo modules selected. Exiting." 7 40
        exit 0
    fi

    check_dependencies "$selected"
    confirm_install "$selected" || exit 0

    # Clear dialog and run
    clear
    echo -e "${BOLD}${PURPLE}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║   🚀 $(loc 'Installing selected modules...' 'Menginstal modul secara otomatis...')  ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}"
    echo "  Log: $LOGFILE"
    echo ""

    run_modules "$selected"

    show_summary

    clear
    echo ""
    echo -e "${GREEN}${BOLD}  🎉 $(loc 'Setup complete! Reboot with: sudo reboot' 'Setup selesai! Silakan reboot dengan komando: sudo reboot')${NC}"
    echo -e "  Log: ${CYAN}$LOGFILE${NC}"
    echo ""
}

main "$@"
