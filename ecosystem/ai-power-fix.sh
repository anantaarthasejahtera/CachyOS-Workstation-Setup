#!/usr/bin/env bash
# 🚀 AI Turbo Mode — CPU Governor Switcher
# Usage: ai-power-fix.sh [on|off]

set -euo pipefail

MODE="${1:-status}"

set_governor() {
    local gov="$1"
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g "$gov" > /dev/null
    else
        # Fallback to direct sysfs write if cpupower is missing
        echo "$gov" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    fi
    notify-send -a "Nexus AI" -i "processor" "Power Profile: $gov" "CPU optimized for $gov mode"
}

case "$MODE" in
    "on")
        set_governor "performance"
        ;;
    "off")
        set_governor "powersave"
        ;;
    "status")
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        ;;
    *)
        echo "Usage: $0 [on|off]"
        exit 1
        ;;
esac
