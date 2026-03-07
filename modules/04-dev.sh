#!/usr/bin/env bash
# Module 04: Development Environment (Docker, Node, Python, Rust, Go)
source "$(dirname "$0")/00-common.sh"
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

# --- Git & GitHub ---
log "Setting up Git & GitHub CLI..."
install_pkg git git-delta github-cli
install_aur gitui

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
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
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default lts-latest
ok "Node.js $(node --version) installed"

# Enable corepack for pnpm
corepack enable
corepack prepare pnpm@latest --activate 2>/dev/null || true
ok "pnpm activated via corepack"

# --- Python via uv ---
log "Installing uv (Python manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
ok "uv installed"

# --- Rust ---
log "Installing Rust via rustup..."
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
ok "Rust $(rustc --version | cut -d' ' -f2) installed"

# --- Go ---
install_pkg go
ok "Go installed"

# --- Editors ---
log "Installing editors..."
install_pkg neovim
# NOTE: Antigravity (VS Code fork) is installed in Module 07.
# No need for separate VS Code — saves ~400MB RAM + disk.

# --- CLI Power Tools ---
log "Installing CLI power tools..."
install_pkg ripgrep fd bat eza fzf zoxide jq yq tree \
    tokei bottom dust duf procs hyperfine wget aria2 \
    man-db man-pages openssh

ok "Development environment ready"

