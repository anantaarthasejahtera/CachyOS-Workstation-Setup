#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Common functions & variables — sourced by all modules
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── Prevent double-sourcing ──────────────────────────────
[[ -n "${_COMMON_LOADED:-}" ]] && return
_COMMON_LOADED=1

# ─── Configuration ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"


GIT_NAME="${GIT_NAME:-Your Name}"
GIT_EMAIL="${GIT_EMAIL:-you@example.com}"
COLORSCHEME="catppuccin-mocha"
FONT_MONO="JetBrainsMono Nerd Font"
NODE_VERSION="lts"

LOGFILE="$HOME/cachy-setup.log"
BACKUP_BASE="$HOME/.config-backup"

# ─── Colors ───────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

# ─── Logging ─────────────────────────────────────────────
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOGFILE"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1" | tee -a "$LOGFILE"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1" | tee -a "$LOGFILE"; }
err()  { echo -e "${RED}  ✗${NC} $1" | tee -a "$LOGFILE"; }

header() {
    echo "" | tee -a "$LOGFILE"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOGFILE"
    echo -e "${BOLD}${BLUE}  $1${NC}" | tee -a "$LOGFILE"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOGFILE"
}

# ─── Package Management ──────────────────────────────────
install_pkg() {
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        sudo pacman -S --noconfirm --needed "${to_install[@]}" 2>&1 | tee -a "$LOGFILE"
    fi
}

install_aur() {
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null 2>&1 && ! paru -Qi "$pkg" &>/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        paru -S --noconfirm --needed "${to_install[@]}" 2>&1 | tee -a "$LOGFILE"
    fi
}

# Remove a package if installed (idempotent, won't fail if not present)
remove_pkg() {
    local pkg="$1"
    if pacman -Qi "$pkg" &>/dev/null 2>&1; then
        log "Removing deprecated package: $pkg"
        sudo pacman -Rns --noconfirm "$pkg" 2>&1 | tee -a "$LOGFILE" || true
    fi
}

# Migrate from old package to new (remove old → install new)
migrate_pkg() {
    local old="$1" new="$2"
    if pacman -Qi "$old" &>/dev/null 2>&1; then
        log "Migrating: $old → $new"
        sudo pacman -Rns --noconfirm "$old" 2>&1 | tee -a "$LOGFILE" || true
    fi
    install_pkg "$new"
}

# Batch-remove deprecated packages from previous versions.
# Usage: cleanup_deprecated pkg1 pkg2 pkg3 ...
# Each module calls this at the top with its own deprecated list.
# Idempotent: silently skips packages that aren't installed.
cleanup_deprecated() {
    local found=0
    for pkg in "$@"; do
        if pacman -Qi "$pkg" &>/dev/null 2>&1; then
            # Disable any associated service before removal
            sudo systemctl disable --now "${pkg}.service" 2>/dev/null || true
            log "Cleaning up deprecated package: $pkg"
            sudo pacman -Rns --noconfirm "$pkg" 2>&1 | tee -a "$LOGFILE" || true
            found=1
        fi
    done
    if [ "$found" -eq 1 ]; then
        ok "Deprecated packages cleaned up"
    fi
}

# ─── Idempotent Config Helper ────────────────────────────
# Backs up existing config before overwriting.
# Uses per-call timestamp + module name to avoid backup collisions
# when multiple modules run within the same second.
safe_config() {
    local target="$1"
    if [ -f "$target" ]; then
        # Generate unique backup dir: timestamp + calling module name
        local caller_module
        caller_module=$(basename "${BASH_SOURCE[1]:-unknown}" .sh)
        local backup_dir="$BACKUP_BASE/$(date +%Y%m%d-%H%M%S)-${caller_module}"
        mkdir -p "$backup_dir"
        local backup_name
        backup_name="$backup_dir/$(echo "$target" | sed 's|/|__|g')"
        cp "$target" "$backup_name"
        log "  Backed up: $target → $backup_name"
    fi
    # Create parent directory
    mkdir -p "$(dirname "$target")"
}

# ─── Ecosystem Tool Installer ────────────────────────────
# Copies from local repo if available, else curls from GitHub.
# Usage: install_ecosystem "script-name.sh" "target-binary-name"
ECOSYSTEM_REPO_URL="https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem"
install_ecosystem() {
    local script_name="$1"
    local target_name="${2:-${script_name%.sh}}"
    local install_dir="/usr/local/bin"
    local repo_dir
    repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ecosystem"

    if [ -f "$repo_dir/$script_name" ]; then
        sudo cp "$repo_dir/$script_name" "$install_dir/$target_name"
    else
        sudo curl -fsSL --retry 3 --retry-delay 2 \
            -o "$install_dir/$target_name" \
            "$ECOSYSTEM_REPO_URL/$script_name" 2>/dev/null || true
    fi
    sudo chmod +x "$install_dir/$target_name"
}

# ─── Catppuccin Wallpaper Generator ──────────────────────
# Generates a 4K Catppuccin Mocha gradient wallpaper via ImageMagick.
# Returns 0 on success, 1 on failure.
generate_catppuccin_wallpaper() {
    local output_path="$1"
    local magick_cmd=""
    if command -v magick &>/dev/null; then
        magick_cmd="magick"
    elif command -v convert &>/dev/null; then
        magick_cmd="convert"
    else
        return 1
    fi
    $magick_cmd -size 3840x2160 \
        xc:'#1e1e2e' \
        \( -size 3840x2160 gradient:'#302d41'-'#1e1e2e' \) -compose overlay -composite \
        \( -size 200x200 xc:'#cba6f7' -blur 0x80 -resize 3840x2160! \) -compose softlight -composite \
        \( -size 200x200 xc:'#89b4fa' -gravity southeast -blur 0x60 -resize 3840x2160! \) -compose softlight -composite \
        "$output_path" 2>/dev/null
}


# ─── Module Versioning ───────────────────────────────────
# Tracks which modules have been run via checksum of the script.
# On re-run: if the script hasn't changed, the module is skipped entirely.
# Override with: FORCE_RERUN=1 bash setup.sh
MODULE_VERSION_DIR="$HOME/.config/cachy-setup/versions"
mkdir -p "$MODULE_VERSION_DIR"

# Record that a module has been run (call at end of each module)
mark_module_done() {
    local module_name
    module_name="$(basename "${BASH_SOURCE[1]}" .sh)"
    local script_path="${BASH_SOURCE[1]}"
    local checksum
    checksum=$(md5sum "$script_path" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    echo "$checksum" > "$MODULE_VERSION_DIR/$module_name"
}

# Check if module needs to be re-run (returns 0 if needs update, 1 if current)
module_needs_update() {
    local module_name
    module_name="$(basename "${BASH_SOURCE[1]}" .sh)"
    local script_path="${BASH_SOURCE[1]}"
    local version_file="$MODULE_VERSION_DIR/$module_name"
    if [ ! -f "$version_file" ]; then
        return 0  # Never run
    fi
    local stored_checksum
    stored_checksum=$(cat "$version_file")
    local current_checksum
    current_checksum=$(md5sum "$script_path" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    if [ "$stored_checksum" = "$current_checksum" ]; then
        return 1  # Up to date
    fi
    return 0  # Needs update
}

# Call at the TOP of each module (after source + set -euo pipefail).
# Skips the module if it's already been run and the script hasn't changed.
# User can force re-run with: FORCE_RERUN=1
skip_if_current() {
    if [ "${FORCE_RERUN:-0}" = "1" ]; then
        log "Force re-run: $(basename "${BASH_SOURCE[1]}")"
        return 0
    fi
    if ! module_needs_update; then
        ok "Module $(basename "${BASH_SOURCE[1]}" .sh) is up to date — skipping (use FORCE_RERUN=1 to re-run)"
        exit 0
    fi
}

