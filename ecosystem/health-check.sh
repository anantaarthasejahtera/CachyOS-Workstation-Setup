#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation — Post-Update Health Check (Doctor)
#  Validates system integrity after pacman -Syu / kernel updates
#  Usage: health-check  (or via Nexus → System Health Check)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# NOTE: We intentionally use `set -uo pipefail` WITHOUT `-e` here.
# Individual health checks are expected to fail (e.g., missing packages, disabled services)
# and we want to continue running all remaining checks rather than aborting on the first failure.
set -uo pipefail

# ── Colors ──
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

PASS=0
WARN=0
FAIL=0
REPORT=""

check_pass() { ((PASS++)); REPORT+="  ✅ $1\n"; }
check_warn() { ((WARN++)); REPORT+="  ⚠️  $1\n"; }
check_fail() { ((FAIL++)); REPORT+="  ❌ $1\n"; }

echo ""
echo -e "${CYAN}${BOLD}  🩺 CachyOS Workstation — Health Check${RESET}"
echo -e "${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# ═══════════════════════════════════════════════════════
# 1. GPU Driver Check
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [1/8] GPU Drivers${RESET}"
GPU_VENDOR=$(lspci | grep -i 'vga\|3d' | head -1)
if echo "$GPU_VENDOR" | grep -qi 'nvidia'; then
    if lsmod | grep -q '^nvidia'; then
        check_pass "NVIDIA driver loaded (kernel module active)"
    else
        check_fail "NVIDIA driver NOT loaded — may need: sudo mkinitcpio -P && reboot"
    fi
elif echo "$GPU_VENDOR" | grep -qi 'intel'; then
    if lsmod | grep -q '^i915'; then
        check_pass "Intel i915 driver loaded"
    else
        check_warn "Intel i915 not detected (may use modesetting instead — usually fine)"
    fi
elif echo "$GPU_VENDOR" | grep -qi 'amd\|radeon'; then
    if lsmod | grep -q '^amdgpu'; then
        check_pass "AMD GPU driver loaded"
    else
        check_fail "AMD GPU driver NOT loaded — may need: sudo mkinitcpio -P && reboot"
    fi
fi

# ═══════════════════════════════════════════════════════
# 2. Hyprland Config Syntax
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [2/8] Hyprland Config${RESET}"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Check if Hyprland can parse the config (dry-run)
    if command -v hyprctl &>/dev/null; then
        # If Hyprland is running, check for errors in the log
        HYPR_LOG="$HOME/.local/share/hyprland/hyprlandError.log"
        if [ -f "$HYPR_LOG" ] && [ -s "$HYPR_LOG" ]; then
            ERROR_COUNT=$(wc -l < "$HYPR_LOG")
            check_warn "Hyprland has $ERROR_COUNT error(s) in log — check: $HYPR_LOG"
        else
            check_pass "Hyprland config OK (no errors in log)"
        fi
    else
        check_warn "Hyprland not installed or not in PATH"
    fi
else
    check_warn "Hyprland config not found (module 09 not installed?)"
fi

# ═══════════════════════════════════════════════════════
# 3. Waybar Config & CSS
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [3/8] Waybar${RESET}"
WAYBAR_CONF="$HOME/.config/waybar/config.jsonc"
WAYBAR_CSS="$HOME/.config/waybar/style.css"
if [ -f "$WAYBAR_CONF" ]; then
    # Validate JSON syntax
    if command -v python3 &>/dev/null; then
        # Strip jsonc comments and validate
        if sed 's|//.*||g' "$WAYBAR_CONF" | python3 -m json.tool &>/dev/null; then
            check_pass "Waybar config.jsonc syntax valid"
        else
            check_fail "Waybar config.jsonc has JSON syntax errors"
        fi
    else
        check_pass "Waybar config exists (syntax check skipped — no python3)"
    fi
    if [ -f "$WAYBAR_CSS" ]; then
        check_pass "Waybar style.css exists"
    else
        check_warn "Waybar style.css missing — bar will look broken"
    fi
else
    check_warn "Waybar config not found (module 13 not installed?)"
fi

# ═══════════════════════════════════════════════════════
# 4. Critical Packages Still Installed
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [4/8] Critical Packages${RESET}"
CRITICAL_PKGS="base-devel git curl kitty rofi-wayland hyprland waybar"
for pkg in $CRITICAL_PKGS; do
    if pacman -Qi "$pkg" &>/dev/null; then
        check_pass "$pkg installed"
    else
        # Some packages have variant names
        case "$pkg" in
            rofi-wayland) pacman -Qi rofi &>/dev/null && check_pass "rofi installed (wayland variant)" || check_warn "$pkg not found" ;;
            *) check_warn "$pkg not found — may have been removed by update" ;;
        esac
    fi
done

# ═══════════════════════════════════════════════════════
# 5. Services Status
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [5/8] Services${RESET}"
# Only check services that should be enabled
for svc in NetworkManager bluetooth; do
    if systemctl is-active "$svc" &>/dev/null; then
        check_pass "$svc running"
    elif systemctl is-enabled "$svc" &>/dev/null; then
        check_warn "$svc enabled but not running"
    fi
done

# Optional services (only check if installed)
if command -v docker &>/dev/null; then
    if systemctl is-active docker &>/dev/null; then
        check_pass "Docker running"
    else
        check_warn "Docker installed but not running (start: sudo systemctl start docker)"
    fi
fi

if command -v libvirtd &>/dev/null || systemctl list-unit-files | grep -q libvirtd; then
    if systemctl is-active libvirtd &>/dev/null; then
        check_pass "libvirtd (VM) running"
    else
        check_warn "libvirtd installed but not running"
    fi
fi

# ═══════════════════════════════════════════════════════
# 6. Kernel & Boot Integrity
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [6/8] Kernel${RESET}"
RUNNING_KERNEL=$(uname -r)
INSTALLED_KERNELS=$(ls /usr/lib/modules/ 2>/dev/null | tr '\n' ', ')
check_pass "Running kernel: $RUNNING_KERNEL"

# Check if running kernel modules dir still exists (broken after kernel update without reboot)
if [ -d "/usr/lib/modules/$RUNNING_KERNEL" ]; then
    check_pass "Kernel modules directory intact"
else
    check_fail "Kernel modules directory MISSING for $RUNNING_KERNEL — REBOOT REQUIRED!"
    check_fail "  After kernel update, modules are rebuilt for new kernel only."
    check_fail "  Your running kernel's modules were removed. Reboot to load new kernel."
fi

# ═══════════════════════════════════════════════════════
# 7. Config Backup Integrity
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [7/8] Backups${RESET}"
BACKUP_DIR="$HOME/.config-backup"
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(find "$BACKUP_DIR" -maxdepth 1 -type d | wc -l)
    LATEST=$(ls -1t "$BACKUP_DIR" 2>/dev/null | head -1)
    check_pass "Config backups: $((BACKUP_COUNT - 1)) snapshots (latest: $LATEST)"
else
    check_warn "No config backups found — run setup to create initial backup"
fi

# ═══════════════════════════════════════════════════════
# 8. Disk Space
# ═══════════════════════════════════════════════════════
echo -e "${BOLD}  [8/8] Disk Space${RESET}"
ROOT_FREE=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
HOME_FREE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | tr -d 'G')
if [ "$ROOT_FREE" -lt 2 ]; then
    check_fail "Root partition critically low: ${ROOT_FREE}GB free"
elif [ "$ROOT_FREE" -lt 5 ]; then
    check_warn "Root partition low: ${ROOT_FREE}GB free — consider cleanup"
else
    check_pass "Root partition: ${ROOT_FREE}GB free"
fi

if [ "$HOME_FREE" -lt 5 ]; then
    check_warn "Home partition low: ${HOME_FREE}GB free"
else
    check_pass "Home partition: ${HOME_FREE}GB free"
fi

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  📊 Results${RESET}"
echo -e "${CYAN}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "$REPORT"

echo -e "  ${GREEN}✅ Passed: $PASS${RESET}  ${YELLOW}⚠️  Warnings: $WARN${RESET}  ${RED}❌ Failed: $FAIL${RESET}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}${BOLD}Action required! Fix the ❌ items above.${RESET}"
    echo -e "  ${RED}Most common fix: sudo mkinitcpio -P && reboot${RESET}"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo -e "  ${YELLOW}${BOLD}System is functional with minor warnings.${RESET}"
    exit 0
else
    echo -e "  ${GREEN}${BOLD}System is healthy! Everything looks great. 🎉${RESET}"
    exit 0
fi
