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
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

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
        if ! pacman -Qi "$pkg" &>/dev/null && ! paru -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        paru -S --noconfirm --needed "${to_install[@]}" 2>&1 | tee -a "$LOGFILE"
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

# Copy dotfile from repo to target, with backup.
# Returns 1 if source file is missing (allows callers to detect partial deployment).
DOTFILE_FAILURES=0
deploy_dotfile() {
    local src="$DOTFILES_DIR/$1"
    local dest="$2"
    if [ -f "$src" ]; then
        safe_config "$dest"
        cp "$src" "$dest"
        ok "Deployed: $1 → $dest"
    else
        warn "Dotfile not found: $src (skipped)"
        ((DOTFILE_FAILURES++)) || true
        return 1
    fi
}

# ─── Module Versioning ───────────────────────────────────
# Tracks which modules have been run via checksum of the script
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

