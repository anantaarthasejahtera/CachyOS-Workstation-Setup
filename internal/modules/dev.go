package modules

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/state"
)

// InstallDevAndEditors implements 04-dev.sh and 07-editors.sh logic.
func InstallDevAndEditors() error {
	fmt.Println("🌟 [Module 04 & 07: Dev] Setting up Development Environment...")

	setupDocker()
	setupGit()
	setupLanguages()
	setupCLITools()

	setupEditors()
	setupOllama()

	fmt.Println("✅ [Module 04 & 07: Dev] Development environment ready.")
	return nil
}

func setupDocker() {
	fmt.Println("-> Installing Docker Ecosystem...")
	pacman.Install("docker", "docker-compose", "docker-buildx", "lazydocker")
	
	// Ultra-Lightweight Adjustment: We do NOT enable docker.service by default.
	// Users can start it via 'systemctl start docker' or utilize docker.socket activation
	// to ensure 0 MB memory overhead when Docker is not in use.
	fmt.Println("   Note: Docker daemon is installed but disabled by default to save RAM.")

	fmt.Println("   Installing Docker Auto-Suspend (15m idle timeout)...")
	setupDockerIdleTimeout := `
	cat << 'EOF' | sudo tee /usr/local/bin/docker-idle-suspend.sh > /dev/null
#!/usr/bin/env bash
if systemctl is-active --quiet docker; then
    if [ -z "$(docker ps -q)" ]; then
        systemctl stop docker
    fi
fi
EOF
	sudo chmod +x /usr/local/bin/docker-idle-suspend.sh

	cat << 'EOF' | sudo tee /etc/systemd/system/docker-idle.service > /dev/null
[Unit]
Description=Suspend Docker when idle

[Service]
Type=oneshot
ExecStart=/usr/local/bin/docker-idle-suspend.sh
EOF

	cat << 'EOF' | sudo tee /etc/systemd/system/docker-idle.timer > /dev/null
[Unit]
Description=Run Docker idle suspend every 15m

[Timer]
OnBootSec=15m
OnUnitActiveSec=15m

[Install]
WantedBy=timers.target
EOF

	sudo systemctl daemon-reload
	sudo systemctl enable --now docker-idle.timer
	`
	exec.Command("bash", "-c", setupDockerIdleTimeout).Run()

	user := os.Getenv("USER")
	exec.Command("sudo", "usermod", "-aG", "docker", user).Run()
}

func setupGit() {
	fmt.Println("-> Setting up Git & GitHub CLI...")
	pacman.Remove("gitui") // Deprecated
	pacman.Install("git-delta", "github-cli", "lazygit")

	configs := map[string]string{
		"init.defaultBranch":     "main",
		"core.pager":             "delta",
		"interactive.diffFilter": "delta --color-only",
		"delta.navigate":         "true",
		"delta.side-by-side":     "true",
		"delta.line-numbers":     "true",
		"delta.syntax-theme":     "Catppuccin Mocha",
		"merge.conflictstyle":    "diff3",
		"diff.colorMoved":        "default",
		"pull.rebase":            "true",
		"push.autoSetupRemote":   "true",
		"rerere.enabled":         "true",
	}

	for k, v := range configs {
		exec.Command("git", "config", "--global", k, v).Run()
	}
}

func setupLanguages() {
	// Node.js (fnm)
	fmt.Println("-> Installing Node.js via fnm...")
	pacman.Install("fnm")
	// Since fnm requires shell sourcing, we execute its installation logic via bash
	bashFnm := `eval "$(fnm env)" && fnm install --lts && fnm default lts-latest && corepack enable && corepack prepare pnpm@latest --activate`
	exec.Command("bash", "-c", bashFnm).Run()

	// Python (uv)
	fmt.Println("-> Installing Python via uv...")
	exec.Command("bash", "-c", `curl -LsSf https://astral.sh/uv/install.sh | sh`).Run()

	// Rust
	fmt.Println("-> Installing Rust via rustup...")
	exec.Command("bash", "-c", `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y`).Run()

	// Go
	fmt.Println("-> Installing Go...")
	pacman.Install("go")
}

func setupCLITools() {
	fmt.Println("-> Installing CLI Power Tools...")
	pacman.Install(
		"ripgrep", "fd", "bat", "eza", "fzf", "zoxide", "jq", "yq", "tree",
		"tokei", "bottom", "dust", "duf", "procs", "hyperfine", "wget", "aria2",
		"man-db", "man-pages", "openssh",
	)
}

func setupEditors() {
	// Antigravity (AI Editor) - Try AUR first, then fallback to Cursor
	fmt.Println("-> Installing Antigravity Editor & Modern Tools (Ghostty, Zed)...")
	pacman.Install("ghostty-git", "zed-bin")
	if !pacman.IsInstalled("antigravity-bin") {
		pacman.Install("cursor-bin")
	}

	// VS Code Catppuccin Settings
	vscodeDir := filepath.Join(os.Getenv("HOME"), ".config/Code/User")
	os.MkdirAll(vscodeDir, 0755)

	vscSettings := `{
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "workbench.productIconTheme": "catppuccin-mocha",
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace",
    "editor.fontSize": 14,
    "editor.fontLigatures": true,
    "editor.lineHeight": 1.6,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": false,
    "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
    "window.titleBarStyle": "custom",
    "files.autoSave": "afterDelay",
    
    // --- Phase V: Aggressive RAM & CPU Minimization ---
    "git.autorefresh": false,
    "telemetry.enableTelemetry": false,
    "workbench.enableExperiments": false,
    "extensions.ignoreRecommendations": true,
    "update.mode": "none",
    "search.followSymlinks": false,
    "files.exclude": {
        "**/node_modules": true,
        "**/__pycache__": true,
        "**/.git": true,
        "**/.DS_Store": true,
        "**/.venv": true,
        "**/*.pyc": true
    },
    // Prevent language servers from parsing heavy ignored folders
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/*.code-search": true,
        "**/dist": true,
        "**/build": true
    }
}`
	state.SafeWriteConfig(filepath.Join(vscodeDir, "settings.json"), []byte(vscSettings), 0644)

	// Neovim & Lazy.nvim Catppuccin Setup
	fmt.Println("-> Configuring Neovim...")
	pacman.Install("neovim")
	nvimDir := filepath.Join(os.Getenv("HOME"), ".config/nvim")
	os.MkdirAll(filepath.Join(nvimDir, "lua/plugins"), 0755)

	nvimInit := `-- Neovim - Catppuccin Mocha
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({ flavour = "mocha", transparent_background = true })
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require("nvim-tree").setup() end },
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
})`
	state.SafeWriteConfig(filepath.Join(nvimDir, "init.lua"), []byte(nvimInit), 0644)
}

func setupOllama() {
	fmt.Println("-> Installing Ollama (Local LLM)...")
	// Try installing directly via curl as fallback if pacman fails (typical for arch/aur)
	if !pacman.IsInstalled("ollama") {
		exec.Command("bash", "-c", `curl -fsSL https://ollama.com/install.sh | sh`).Run()
	}
	
	// Ultra-Lightweight Adjustment: Do NOT enable ollama.service by default.
	// It consumes significant idle RAM. It will be started on-demand via Nexus Chat.
	fmt.Println("   Note: Ollama daemon installed but disabled by default to save RAM.")
	exec.Command("sudo", "systemctl", "disable", "ollama.service").Run()
}
