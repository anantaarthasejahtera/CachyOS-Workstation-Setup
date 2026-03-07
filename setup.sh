#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🚀 CachyOS Workstation Setup                                      ║
# ║  One-shot modular installer with TUI module selector                ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./setup.sh          Interactive mode (TUI module selector)
#   ./setup.sh --all    Install everything (no picker)
#
# Configure your identity below before running.

set -euo pipefail

# ─── Configuration (EDIT THESE) ───────────────────────────
export GIT_NAME="Your Name"          # ← CHANGE THIS
export GIT_EMAIL="you@example.com"   # ← CHANGE THIS

# ─── Launch Installer ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/installer.sh" "$@"
