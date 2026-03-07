# CachyOS Workstation Setup - Makefile
# A unified interface for developers and users.

.PHONY: help install install-all uninstall lint init

help: ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Run the interactive TUI Setup (Default)
	@chmod +x setup.sh installer.sh
	@./setup.sh

install-all: ## Install everything silently without asking
	@chmod +x setup.sh installer.sh
	@./setup.sh --all

uninstall: ## Remove ecosystem tools, UI themes, and hooks gracefully
	@chmod +x uninstall.sh
	@./uninstall.sh

lint: ## Run ShellCheck to validate all bash scripts
	@echo "Running ShellCheck on all bash scripts..."
	@find . -type f -name "*.sh" -not -path "*/\.*" -exec shellcheck -x {} +
	@echo "✅ All scripts passed ShellCheck!"

init: ## Initialize development environment (setup git hooks)
	@echo "Setting up local Git hooks..."
	@git config core.hooksPath .githooks
	@chmod +x .githooks/*
	@echo "✅ Git hooks configured successfully!"
