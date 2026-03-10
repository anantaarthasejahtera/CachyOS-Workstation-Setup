#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation Installer — GUI Wizard (zenity)
#  Uses zenity for graphical popup dialogs
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
        echo "$id"
    else
        echo "$en"
    fi
}

# ─── Define Modules ──────────────────────────────────────
declare -A MODULE_SCRIPTS
declare -A MODULE_SIZES

MODULE_SCRIPTS[01]="01-base.sh";      MODULE_SIZES[01]="~2 GB"
MODULE_SCRIPTS[02]="02-kernel.sh";    MODULE_SIZES[02]="~50 MB"
MODULE_SCRIPTS[03]="03-security.sh";  MODULE_SIZES[03]="~50 MB"
MODULE_SCRIPTS[04]="04-dev.sh";       MODULE_SIZES[04]="~4 GB"
MODULE_SCRIPTS[05]="05-mobile.sh";    MODULE_SIZES[05]="~5 GB"
MODULE_SCRIPTS[06]="06-dotfiles.sh";  MODULE_SIZES[06]="~100 MB"
MODULE_SCRIPTS[07]="07-editors.sh";   MODULE_SIZES[07]="~5 GB"
MODULE_SCRIPTS[08]="08-desktop.sh";   MODULE_SIZES[08]="~300 MB"
MODULE_SCRIPTS[09]="09-hyprland.sh";  MODULE_SIZES[09]="~200 MB"
MODULE_SCRIPTS[10]="10-apps.sh";      MODULE_SIZES[10]="~500 MB"
MODULE_SCRIPTS[11]="11-gaming.sh";    MODULE_SIZES[11]="~3 GB"
MODULE_SCRIPTS[12]="12-vm.sh";        MODULE_SIZES[12]="~2 GB"
MODULE_SCRIPTS[13]="13-waybar.sh";    MODULE_SIZES[13]="~5 MB"
MODULE_SCRIPTS[14]="14-nexus-guide.sh"; MODULE_SIZES[14]="~1 MB"
MODULE_SCRIPTS[15]="15-ecosystem.sh"; MODULE_SIZES[15]="~1 MB"

MODULE_ORDER=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15)

# ─── Language Selector ────────────────────────────────────
select_language() {
    local result
    result=$(zenity --list --radiolist \
        --title="🌐 Language / Bahasa" \
        --text="Select Installer Language / Pilih Bahasa Installer:" \
        --column="" --column="Code" --column="Language" \
        --width=400 --height=250 \
        --print-column=2 --hide-column=2 \
        TRUE "en" "English" \
        FALSE "id" "Bahasa Indonesia" 2>/dev/null) || true

    if [ -n "$result" ]; then
        GUI_LANG="$result"
    fi
}

# ─── Welcome Screen ─────────────────────────────────────
show_welcome() {
    zenity --info \
        --title="🚀 $(loc 'CachyOS Workstation Setup' 'Setup CachyOS Workstation')" \
        --width=500 --height=350 \
        --text="$(loc \
'<big><b>🚀 CachyOS Workstation Installer</b></big>

<b>Theme:</b> Catppuccin Mocha
<b>Modules:</b> 15 (fully modular)
<b>Tools:</b> 50+ pre-configured
<b>Guide:</b> 130+ searchable entries

This wizard will guide you through the setup
step by step. Select what you need at each stage.

• All configs are backed up automatically
• Unchanged modules are skipped on re-run
• You can go Back at any step' \
'<big><b>🚀 Installer CachyOS Workstation</b></big>

<b>Tema:</b> Catppuccin Mocha
<b>Modul:</b> 15 (modular penuh)
<b>Tools:</b> 50+ terkonfigurasi
<b>Panduan:</b> 130+ referensi command

Wizard ini akan memandu kamu langkah demi langkah.
Pilih apa yang kamu butuhkan di setiap tahap.

• Semua konfigurasi di-backup otomatis
• Modul yg tidak berubah di-skip saat re-run
• Kamu bisa kembali (Back) di setiap langkah')" 2>/dev/null || true
}

# ─── Wizard Steps ────────────────────────────────────────

# Global array for selections
declare -a WIZARD_SELECTED=()

# Helper: show a zenity checklist for a wizard step
# Args: step_num total title text [TRUE/FALSE "id" "label" "size"]...
# Returns: 0=Next, 1=Cancel/Back
# Populates STEP_RESULT with selected IDs (space-separated)
STEP_RESULT=""

wizard_step() {
    local step_num="$1"
    local total="$2"
    local title="$3"
    local text="$4"
    shift 4

    STEP_RESULT=""
    local result
    result=$(zenity --list --checklist \
        --title="$title  [$step_num/$total]" \
        --text="$text\n\n$(loc 'Check the modules you want to install:' 'Centang modul yang ingin diinstall:')" \
        --column="" --column="ID" --column="Module" --column="Size" \
        --width=700 --height=420 \
        --separator=" " --print-column=2 \
        --ok-label="$(loc 'Next →' 'Lanjut →')" \
        --cancel-label="$(loc '← Back' '← Kembali')" \
        "$@" 2>/dev/null) || return 1

    STEP_RESULT="$result"
    return 0
}

run_wizard() {
    local step=1
    local total=5

    # Arrays to hold selections per step (for back/forward navigation)
    local step1="" step2="" step3="" step4="" step5=""

    while true; do
        case $step in
            1)
                if wizard_step "$step" "$total" \
                    "$(loc '🔧 Step 1: Foundation' '🔧 Langkah 1: Fondasi Sistem')" \
                    "$(loc 'Core system: GPU drivers, kernel tuning, security hardening.' 'Sistem inti: driver GPU, tuning kernel, keamanan.')" \
                    TRUE  "01" "$(loc 'Base & GPU Drivers' 'Sistem Dasar & Driver GPU')" "${MODULE_SIZES[01]}" \
                    TRUE  "02" "$(loc 'Kernel & Performance Tuning' 'Kernel & Tuning Performa')" "${MODULE_SIZES[02]}" \
                    TRUE  "03" "$(loc 'Security & Maintenance' 'Keamanan & Perawatan')" "${MODULE_SIZES[03]}"
                then
                    step1="$STEP_RESULT"
                    step=2
                fi
                # Cancel from step 1 = exit wizard (no "Back" possible)
                if [ $step -eq 1 ]; then
                    zenity --question \
                        --title="$(loc 'Exit Wizard?' 'Keluar Wizard?')" \
                        --text="$(loc 'Are you sure you want to exit the setup wizard?\nNo changes have been made.' 'Yakin ingin keluar dari wizard setup?\nBelum ada perubahan yang dibuat.')" \
                        --ok-label="$(loc 'Exit' 'Keluar')" \
                        --cancel-label="$(loc 'Stay' 'Tetap')" \
                        --width=350 2>/dev/null || continue
                    echo ""
                    return
                fi
                ;;
            2)
                if wizard_step "$step" "$total" \
                    "$(loc '💻 Step 2: Development' '💻 Langkah 2: Development')" \
                    "$(loc 'Programming tools: Docker, Node.js, Python, Rust, Go, Flutter, editors.' 'Tools pemrograman: Docker, Node.js, Python, Rust, Go, Flutter, editor.')" \
                    TRUE  "04" "$(loc 'Dev Tools (Docker, Node, Python, Rust, Go)' 'Dev Tools (Docker, Node, Python, Rust, Go)')" "${MODULE_SIZES[04]}" \
                    FALSE "05" "$(loc 'Mobile Dev (Flutter, Android SDK)' 'Mobile Dev (Flutter, Android SDK)')" "${MODULE_SIZES[05]}" \
                    TRUE  "07" "$(loc 'Editors (Antigravity, Neovim, Ollama AI)' 'Editor (Antigravity, Neovim, Ollama AI)')" "${MODULE_SIZES[07]}"
                then
                    step2="$STEP_RESULT"
                    step=3
                else
                    step=1  # Back
                fi
                ;;
            3)
                if wizard_step "$step" "$total" \
                    "$(loc '🎨 Step 3: Desktop & Appearance' '🎨 Langkah 3: Desktop & Tampilan')" \
                    "$(loc 'Shell environment, Hyprland WM, Catppuccin themes, status bar.' 'Lingkungan shell, Hyprland WM, tema Catppuccin, status bar.')" \
                    TRUE  "06" "$(loc 'Shell & Dotfiles (Zsh, Kitty, Starship)' 'Shell & Dotfiles (Zsh, Kitty, Starship)')" "${MODULE_SIZES[06]}" \
                    TRUE  "08" "$(loc 'Desktop Theme (KDE Catppuccin, GRUB)' 'Tema Desktop (KDE Catppuccin, GRUB)')" "${MODULE_SIZES[08]}" \
                    TRUE  "09" "$(loc 'Hyprland Window Manager' 'Hyprland Window Manager')" "${MODULE_SIZES[09]}" \
                    TRUE  "13" "$(loc 'Waybar Status Bar' 'Waybar Status Bar')" "${MODULE_SIZES[13]}"
                then
                    step3="$STEP_RESULT"
                    step=4
                else
                    step=2  # Back
                fi
                ;;
            4)
                if wizard_step "$step" "$total" \
                    "$(loc '📦 Step 4: Apps & Ecosystem' '📦 Langkah 4: Aplikasi & Ekosistem')" \
                    "$(loc 'Browser, productivity apps, Nexus command center, ecosystem tools.' 'Browser, aplikasi produktivitas, Nexus, tools ekosistem.')" \
                    TRUE  "10" "$(loc 'Apps (Browser, Productivity, Flatpak)' 'Aplikasi (Browser, Produktivitas, Flatpak)')" "${MODULE_SIZES[10]}" \
                    TRUE  "14" "$(loc 'Nexus & Guide System' 'Nexus & Sistem Guide')" "${MODULE_SIZES[14]}" \
                    TRUE  "15" "$(loc 'Living Ecosystem (8 AI Tools)' 'Ekosistem AI (8 Tools)')" "${MODULE_SIZES[15]}"
                then
                    step4="$STEP_RESULT"
                    step=5
                else
                    step=3  # Back
                fi
                ;;
            5)
                if wizard_step "$step" "$total" \
                    "$(loc '🎮 Step 5: Extras (Optional)' '🎮 Langkah 5: Extras (Opsional)')" \
                    "$(loc 'Heavy optional modules. Uncheck to save disk space & time.' 'Modul opsional berat. Hapus centang untuk hemat ruang & waktu.')" \
                    FALSE "11" "$(loc 'Gaming (Steam, PCSX2, Wine)' 'Gaming (Steam, PCSX2, Wine)')" "${MODULE_SIZES[11]}" \
                    FALSE "12" "$(loc 'Virtualization (QEMU/KVM, Bottles)' 'Virtualisasi (QEMU/KVM, Bottles)')" "${MODULE_SIZES[12]}"
                then
                    step5="$STEP_RESULT"
                    break  # All steps done
                else
                    step=4  # Back
                fi
                ;;
        esac
    done

    # Merge all step selections
    local all_selected="$step1 $step2 $step3 $step4 $step5"

    # Build output in module execution order
    local result=""
    for mod in "${MODULE_ORDER[@]}"; do
        if echo "$all_selected" | grep -qw "$mod"; then
            result+="\"$mod\" "
        fi
    done

    echo "$result"
}

# ─── Module Dependencies ─────────────────────────────────
check_dependencies() {
    local selected="$1"
    local warnings=""

    if echo "$selected" | grep -q '"13"' && ! echo "$selected" | grep -q '"09"'; then
        warnings+="$(loc '⚠ Waybar (13) works best with Hyprland (09)\n' '⚠ Waybar (13) butuh Hyprland (09) untuk konfigurasi maksimal\n')"
    fi
    if echo "$selected" | grep -q '"15"' && ! echo "$selected" | grep -q '"14"'; then
        warnings+="$(loc '⚠ Ecosystem (15) needs Nexus (14) for GUI access\n' '⚠ Ecosystem (15) butuh Nexus (14) untuk akses GUI\n')"
    fi
    if echo "$selected" | grep -q '"06"' && ! echo "$selected" | grep -q '"04"'; then
        warnings+="$(loc '⚠ Dotfiles (06) references tools from Dev (04)\n' '⚠ Dotfiles (06) menggunakan command dari Dev Tools (04)\n')"
    fi
    if echo "$selected" | grep -q '"11"' && ! echo "$selected" | grep -q '"02"'; then
        warnings+="$(loc '⚠ Gaming (11) benefits from Kernel tuning (02)\n' '⚠ Gaming (11) mendapat boost dari Kernel tuning (02)\n')"
    fi

    if [ -n "$warnings" ]; then
        zenity --warning \
            --title="$(loc '⚠ Dependency Hints' '⚠ Saran Dependensi')" \
            --width=500 \
            --text="$(loc 'Some selected modules have dependencies:' 'Beberapa modul saling bergantung:')\n\n$warnings\n$(loc 'These are recommendations, not requirements.' 'Ini rekomendasi, bukan keharusan.')" 2>/dev/null || true
    fi
}

# ─── Confirmation ────────────────────────────────────────
confirm_install() {
    local selected="$1"
    local count
    count=$(echo "$selected" | grep -oP '"[0-9]+"' | wc -l)

    # Build a readable list
    local module_list=""
    for mod in "${MODULE_ORDER[@]}"; do
        if echo "$selected" | grep -q "\"$mod\""; then
            module_list+="  • ${MODULE_SCRIPTS[$mod]}  [${MODULE_SIZES[$mod]}]\n"
        fi
    done

    zenity --question \
        --title="$(loc '✅ Confirm Installation' '✅ Konfirmasi Instalasi')" \
        --width=500 --height=400 \
        --ok-label="$(loc '🚀 Install Now' '🚀 Install Sekarang')" \
        --cancel-label="$(loc 'Cancel' 'Batal')" \
        --text="$(loc "You selected <b>$count modules</b>:" "Kamu memilih <b>$count modul</b>:")\n\n$module_list\n$(loc 'Proceed with installation?' 'Lanjutkan proses instalasi?')" 2>/dev/null
}

# ─── Run Modules with Progress ───────────────────────────
run_modules() {
    local selected="$1"
    local -a modules
    read -ra modules <<< "$selected"
    local total=${#modules[@]}
    # Temp file for error dialog communication between subshell and parent
    local error_flag_file
    error_flag_file=$(mktemp /tmp/cachy-setup-error.XXXXXX)
    rm -f "$error_flag_file"

    (
        local current=0
        for mod in "${modules[@]}"; do
            mod=$(echo "$mod" | tr -d '"')
            current=$((current + 1))
            local script="${MODULE_SCRIPTS[$mod]}"
            local pct=$(( ((current - 1) * 100) / total ))

            echo "$pct"
            echo "# $(loc "Installing module $current/$total: $script" "Menginstall modul $current/$total: $script")"

            # Run module
            FORCE_RERUN="${FORCE_RERUN:-0}" bash "$MODULES_DIR/$script" >> "$LOGFILE" 2>&1
            local exit_code=$?

            if [ $exit_code -ne 0 ]; then
                # Module failed — write error info and break out of progress pipe
                # Zenity dialogs CANNOT be shown inside a piped subshell (stdout is the pipe)
                # Instead, signal the parent process to handle error recovery
                echo "$script:$exit_code:$current" > "$error_flag_file"
                echo "100"
                echo "# $(loc "Module $script failed — handling error..." "Modul $script gagal — menangani error...")"
                exit 2
            fi
        done

        echo "100"
        echo "# $(loc '✅ All modules installed successfully!' '✅ Semua modul berhasil diinstall!')"
        sleep 1
    ) | zenity --progress \
        --title="$(loc '⚡ Installing...' '⚡ Menginstall...')" \
        --text="$(loc 'Preparing modules...' 'Menyiapkan modul...')" \
        --width=550 --height=150 \
        --auto-close --no-cancel \
        --percentage=0 2>/dev/null

    local pipe_exit=${PIPESTATUS[0]}

    # Check if a module failed and handle error recovery outside the pipe
    if [ -f "$error_flag_file" ]; then
        local error_info
        error_info=$(cat "$error_flag_file")
        rm -f "$error_flag_file"
        local failed_script failed_code failed_idx
        IFS=':' read -r failed_script failed_code failed_idx <<< "$error_info"

        local choice
        choice=$(zenity --list --radiolist \
            --title="$(loc '❌ Module Failed' '❌ Modul Gagal')" \
            --text="$(loc "Module <b>$failed_script</b> failed (exit code $failed_code).\nLog: $LOGFILE\n\nWhat would you like to do?" "Modul <b>$failed_script</b> gagal (exit code $failed_code).\nLog: $LOGFILE\n\nApa yang ingin dilakukan?")" \
            --column="" --column="Action" --column="Description" \
            --width=550 --height=300 \
            --print-column=2 --hide-column=2 \
            TRUE  "Retry"  "$(loc 'Try running this module again' 'Coba jalankan modul ini lagi')" \
            FALSE "Ignore" "$(loc 'Skip and continue remaining modules' 'Lewati dan lanjut modul berikutnya')" \
            FALSE "Abort"  "$(loc 'Stop the entire installation' 'Hentikan seluruh instalasi')" \
            2>/dev/null) || choice="Abort"

        case "$choice" in
            "Retry")
                # Retry failed module, then continue with remaining modules
                if ! FORCE_RERUN="${FORCE_RERUN:-0}" bash "$MODULES_DIR/$failed_script" >> "$LOGFILE" 2>&1; then
                    zenity --warning \
                        --title="$(loc '⚠️ Retry Failed' '⚠️ Percobaan Ulang Gagal')" \
                        --text="$(loc "Module $failed_script failed again. Continuing with remaining modules." "Modul $failed_script gagal lagi. Melanjutkan modul berikutnya.")" \
                        --width=400 2>/dev/null || true
                fi
                ;& # fall through to shared remaining-module logic
            "Ignore")
                # Continue with remaining modules (shared by both Retry and Ignore)
                local remaining=""
                local skip=true
                for mod in "${modules[@]}"; do
                    mod=$(echo "$mod" | tr -d '"')
                    if [ "$skip" = true ] && [ "${MODULE_SCRIPTS[$mod]}" = "$failed_script" ]; then
                        skip=false
                        continue
                    fi
                    [ "$skip" = false ] && remaining+="$mod "
                done
                if [ -n "$remaining" ]; then
                    run_modules "$remaining"
                fi
                ;;
            *)
                zenity --error \
                    --title="$(loc '❌ Installation Aborted' '❌ Instalasi Dibatalkan')" \
                    --text="$(loc 'Installation was stopped. Check log:' 'Instalasi dihentikan. Cek log:')\n$LOGFILE" \
                    --width=400 2>/dev/null || true
                return 1
                ;;
        esac
        return 0
    fi

    rm -f "$error_flag_file"
    if [ "$pipe_exit" -ne 0 ]; then
        zenity --error \
            --title="$(loc '❌ Installation Aborted' '❌ Instalasi Dibatalkan')" \
            --text="$(loc 'Installation was stopped. Check log:' 'Instalasi dihentikan. Cek log:')\n$LOGFILE" \
            --width=400 2>/dev/null || true
        return 1
    fi
    return 0
}

# ─── Post-Install Summary ───────────────────────────────
show_summary() {
    zenity --info \
        --title="$(loc '🎉 Installation Complete!' '🎉 Instalasi Selesai!')" \
        --width=500 --height=380 \
        --text="$(loc \
'<big><b>🎉 Installation Complete!</b></big>

Please <b>reboot</b> your system:
<tt>  sudo reboot</tt>

<b>After reboot:</b>
  • <b>Super+X</b>  →  Nexus Command Center
  • <b>Super+D</b>  →  App Launcher (Rofi)
  • <b>guide</b>       →  Searchable Help
  • <b>ff</b>            →  System Info

Log: ~/cachy-setup.log' \
'<big><b>🎉 Instalasi Selesai!</b></big>

Silahkan <b>reboot</b> sistem kamu:
<tt>  sudo reboot</tt>

<b>Setelah reboot:</b>
  • <b>Super+X</b>  →  Nexus Command Center
  • <b>Super+D</b>  →  App Launcher (Rofi)
  • <b>guide</b>       →  Panduan Interaktif
  • <b>ff</b>            →  Info Sistem

Log: ~/cachy-setup.log')" 2>/dev/null || true
}

# ─── Main Flow ───────────────────────────────────────────
main() {
    # Pre-flight
    if [ "$EUID" -eq 0 ]; then
        zenity --error --title="Error" \
            --text="$(loc 'Do NOT run as root. Run as normal user (sudo is used internally).' 'JANGAN jalankan sebagai root. Jalankan sebagai user biasa.')" \
            --width=400 2>/dev/null || true
        exit 1
    fi

    # Colors for terminal output
    BOLD='\033[1m'
    NC='\033[0m'
    CYAN='\033[1;36m'
    GREEN='\033[1;32m'
    PURPLE='\033[1;35m'

    # Sudo Validation & Keep-Alive
    echo -e "${CYAN}Please enter your password to authorize the installation:${NC}"
    if sudo -v; then
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        keep_alive_pid=$!
        trap 'kill ${keep_alive_pid:-} 2>/dev/null || true' EXIT
    else
        zenity --error --title="Error" \
            --text="$(loc 'Sudo authorization failed.' 'Otorisasi sudo gagal.')" \
            --width=300 2>/dev/null || true
        exit 1
    fi

    # Ensure zenity is available
    if ! command -v zenity &>/dev/null; then
        echo "Installing zenity..."
        sudo pacman -S --noconfirm zenity
    fi

    # Check for --all flag
    if [[ "${1:-}" == "--all" ]]; then
        zenity --question \
            --title="$(loc '⚠ Install All Modules' '⚠ Install Semua Modul')" \
            --text="$(loc 'This will install ALL 15 modules (~18 GB).\n\nAre you sure?' 'Ini akan menginstall SEMUA 15 modul (~18 GB).\n\nYakin?')" \
            --width=400 2>/dev/null || exit 0

        log "Installing ALL modules..."
        local all_modules=""
        for mod in "${MODULE_ORDER[@]}"; do
            all_modules+="\"$mod\" "
        done
        run_modules "$all_modules" && show_summary
        return
    fi

    # Interactive Wizard Flow
    select_language
    show_welcome

    # ── Git Identity Configuration ──
    # Only prompt if identity hasn't been set yet
    local env_file="$SCRIPT_DIR/.env"
    local current_name="${GIT_NAME:-}"
    # Fallback: load from .env if GIT_NAME isn't in environment (e.g., direct invocation)
    if [ -z "$current_name" ] && [ -f "$env_file" ]; then
        current_name=$(grep -oP '^GIT_NAME="\K[^"]+' "$env_file" 2>/dev/null || echo "")
    fi

    if [ -z "$current_name" ] || [ "$current_name" = "Your Name" ] || [ "$current_name" = "Kamu" ]; then
        # Detect identity sources
        local gh_name="" gh_email="" git_name="" git_email=""

        if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
            gh_name=$(gh api user --jq '.name // empty' 2>/dev/null || echo "")
            gh_email=$(gh api user --jq '.email // empty' 2>/dev/null || echo "")
            [ -z "$gh_email" ] && gh_email=$(gh api user/emails --jq '[.[] | select(.primary)][0].email // empty' 2>/dev/null || echo "")
        fi

        git_name=$(git config --global user.name 2>/dev/null || echo "")
        git_email=$(git config --global user.email 2>/dev/null || echo "")

        # Build zenity list
        local list_items=()
        local default_set=false

        if [ -n "$gh_name" ] && [ -n "$gh_email" ]; then
            list_items+=(TRUE "GitHub" "🐙 $gh_name <$gh_email>")
            default_set=true
        fi

        if [ -n "$git_name" ] && [ -n "$git_email" ]; then
            if [ "$git_name" != "$gh_name" ] || [ "$git_email" != "$gh_email" ]; then
                if [ "$default_set" = false ]; then
                    list_items+=(TRUE "GitConfig" "⚙️ $git_name <$git_email>")
                    default_set=true
                else
                    list_items+=(FALSE "GitConfig" "⚙️ $git_name <$git_email>")
                fi
            fi
        fi

        if [ "$default_set" = false ]; then
            list_items+=(TRUE "Manual" "✏️ Enter name and email manually")
        else
            list_items+=(FALSE "Manual" "✏️ Enter name and email manually")
        fi
        list_items+=(FALSE "Skip" "⏭️ Skip for now (edit .env later)")

        local identity_choice
        identity_choice=$(zenity --list --radiolist \
            --title="$(loc '👤 Git Identity Setup' '👤 Konfigurasi Identitas Git')" \
            --text="$(loc 'Configure your Git identity for commits and SSH keys.' 'Konfigurasi identitas Git untuk commit dan SSH key.')" \
            --column="" --column="Source" --column="Identity" \
            --width=550 --height=320 \
            --print-column=2 --hide-column=2 \
            "${list_items[@]}" 2>/dev/null) || identity_choice="Skip"

        local input_name="" input_email=""

        case "$identity_choice" in
            "GitHub")  input_name="$gh_name"; input_email="$gh_email" ;;
            "GitConfig") input_name="$git_name"; input_email="$git_email" ;;
            "Manual")
                input_name=$(zenity --entry \
                    --title="$(loc '👤 Your Name' '👤 Nama Kamu')" \
                    --text="$(loc 'Enter your full name (for Git commits):' 'Masukkan nama lengkap (untuk commit Git):')" \
                    --entry-text="$git_name" --width=400 2>/dev/null) || input_name=""
                [ -n "$input_name" ] && input_email=$(zenity --entry \
                    --title="$(loc '📧 Your Email' '📧 Email Kamu')" \
                    --text="$(loc 'Enter your email (for Git commits):' 'Masukkan email (untuk commit Git):')" \
                    --entry-text="$git_email" --width=400 2>/dev/null) || input_email=""
                ;;
        esac

        if [ -n "$input_name" ] && [ -n "$input_email" ]; then
            if zenity --question \
                --title="$(loc '✅ Confirm Identity' '✅ Konfirmasi Identitas')" \
                --text="$(loc 'Save this identity?' 'Simpan identitas ini?')\n\n  <b>Name:</b>  $input_name\n  <b>Email:</b> $input_email" \
                --width=400 2>/dev/null
            then
                cat > "$env_file" << ENVEOF
# CachyOS Workstation — User Configuration
GIT_NAME="$input_name"
GIT_EMAIL="$input_email"
ENVEOF
                export GIT_NAME="$input_name"
                export GIT_EMAIL="$input_email"
                log "Git identity saved: $input_name <$input_email>"
            fi
        fi
    fi

    # Re-run mode check
    if [ -d "$HOME/.config/cachy-setup/versions" ] && [ -n "$(ls -A "$HOME/.config/cachy-setup/versions" 2>/dev/null)" ]; then
        local rerun_choice
        rerun_choice=$(zenity --list --radiolist \
            --title="$(loc '🔄 Re-run Mode' '🔄 Mode Re-run')" \
            --text="$(loc 'Some modules have been installed before.\nUnchanged modules will be skipped to save time.' 'Beberapa modul pernah diinstall.\nModul yg tidak berubah akan di-skip.')" \
            --column="" --column="Mode" --column="Description" \
            --width=550 --height=280 \
            --print-column=2 --hide-column=2 \
            TRUE  "Smart" "$(loc 'Skip unchanged, run updated only' 'Skip yg sama, jalankan yg baru')" \
            FALSE "Force" "$(loc 'Re-run ALL selected modules' 'Paksa jalankan SEMUA modul')" \
            FALSE "Reset" "$(loc 'Clear history and run fresh' 'Hapus riwayat, install ulang')" \
            2>/dev/null) || rerun_choice="Smart"

        case "$rerun_choice" in
            "Force") export FORCE_RERUN=1 ;;
            "Reset")
                rm -rf "$HOME/.config/cachy-setup/versions"
                mkdir -p "$HOME/.config/cachy-setup/versions"
                ;;
        esac
    fi

    # Run the 5-step wizard
    local selected
    selected=$(run_wizard)

    if [ -z "$selected" ]; then
        zenity --info --title="$(loc 'Cancelled' 'Dibatalkan')" \
            --text="$(loc 'No modules selected. Exiting.' 'Tidak ada modul dipilih. Keluar.')" \
            --width=300 2>/dev/null || true
        exit 0
    fi

    check_dependencies "$selected"
    confirm_install "$selected" || exit 0

    # Run installation
    echo ""
    echo -e "${BOLD}${PURPLE}  🚀 Setup Wizard — Installing modules...${NC}"
    echo -e "  Log: ${CYAN}$LOGFILE${NC}"
    echo ""

    if ! run_modules "$selected"; then
        exit 1
    fi

    show_summary

    # Post-install action
    local post_choice
    post_choice=$(zenity --list --radiolist \
        --title="$(loc '🎯 Next Steps' '🎯 Langkah Selanjutnya')" \
        --text="$(loc 'Installation is complete! What would you like to do next?' 'Instalasi selesai! Apa yang ingin dilakukan selanjutnya?')" \
        --column="" --column="Action" --column="Description" \
        --width=500 --height=280 \
        --print-column=2 --hide-column=2 \
        TRUE  "Wizard" "$(loc 'Run Post-Install Wizard (Recommended)' 'Jalankan Wizard Post-Install (Rekomendasi)')" \
        FALSE "Reboot" "$(loc 'Reboot the system now' 'Reboot sistem sekarang')" \
        FALSE "Exit"   "$(loc 'Finish and stay in terminal' 'Selesai dan tetap di terminal')" \
        2>/dev/null) || post_choice="Exit"

    case "$post_choice" in
        "Wizard")
            if [ -f "$MODULES_DIR/../ecosystem/post-install.sh" ]; then
                bash "$MODULES_DIR/../ecosystem/post-install.sh"
            fi
            ;;
        "Reboot")
            sudo reboot
            ;;
    esac

    echo ""
    echo -e "${GREEN}${BOLD}  🎉 $(loc 'Setup complete! Reboot with: sudo reboot' 'Setup selesai! Reboot dengan: sudo reboot')${NC}"
    echo -e "  Log: ${CYAN}$LOGFILE${NC}"
    echo ""
}

main "$@"
