#!/usr/bin/env bash
# Module 04: Development Environment (Docker, Node, Python, Rust, Go)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Docker & Container Environment"

install_pkg docker docker-compose docker-buildx

sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

# lazydocker — TUI for docker
install_aur lazydocker

ok "Docker installed (group change takes effect after reboot)"

# =====================================================================
# Node.js, Python, Rust, Go, CLI tools
# =====================================================================
header "Development Environment"

# ── Deprecated packages (auto-removed on re-run) ──────────
# When replacing a package, add the OLD one here so re-runs clean it up.
cleanup_deprecated \
    gitui           # replaced by lazygit (more mature, better UI)

# --- Git & GitHub ---
log "Setting up Git & GitHub CLI..."
install_pkg git-delta github-cli lazygit

# Only set git identity if it's not a placeholder default
# (avoid overwriting a valid existing identity if user skipped wizard)
if [ "$GIT_NAME" != "Your Name" ] && [ "$GIT_EMAIL" != "you@example.com" ]; then
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
elif [ -z "$(git config --global user.name 2>/dev/null)" ]; then
    warn "Git identity not configured — set it later: git config --global user.name 'Your Name'"
fi
git config --global init.defaultBranch main
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme "Catppuccin Mocha"
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true

# --- Node.js via fnm ---
log "Installing fnm (Fast Node Manager)..."
install_aur fnm
hash -r  # Refresh PATH cache so fnm is found immediately
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
    fnm install --lts
    fnm default lts-latest
    ok "Node.js $(node --version 2>/dev/null || echo 'LTS') installed"

    # Enable corepack for pnpm (requires Node in PATH)
    corepack enable 2>/dev/null || true
    corepack prepare pnpm@latest --activate 2>/dev/null || true
    ok "pnpm activated via corepack"
else
    warn "fnm not found in PATH after install — Node.js setup skipped"
    warn "  Fix: restart shell and run 'fnm install --lts'"
fi

# --- Python via uv ---
log "Installing uv (Python manager)..."
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Add uv to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    ok "uv installed"
else
    ok "uv already installed"
fi

# --- Rust ---
log "Installing Rust via rustup..."
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi
ok "Rust $(rustc --version 2>/dev/null | cut -d' ' -f2 || echo 'latest') installed"

# --- Go ---
install_pkg go
ok "Go installed"

# NOTE: Neovim and Antigravity are installed in Module 07 (Editors)
# with full Catppuccin configuration. No need to install separately here.

# --- CLI Power Tools ---
log "Installing CLI power tools..."
install_pkg ripgrep fd bat eza fzf zoxide jq yq tree \
    tokei bottom dust duf procs hyperfine wget aria2 \
    man-db man-pages openssh

ok "Development environment ready"
mark_module_done

