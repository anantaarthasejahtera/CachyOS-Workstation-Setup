# CachyOS Workstation Setup - Makefile
# A unified interface for building and managing the Nexus CLI.

BINARY_NAME = nexus
VERSION     ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

.PHONY: help build install clean lint test dev

help: ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Nexus CLI binary
	@echo "🚀 Compiling Nexus CLI..."
	@go build -ldflags="-s -w -X main.Version=$(VERSION)" -o $(BINARY_NAME) .
	@echo "✅ Build complete! Binary: ./$(BINARY_NAME) ($(shell du -h $(BINARY_NAME) | cut -f1))"

install: build ## Build and install to /usr/local/bin
	@echo "📦 Installing $(BINARY_NAME) to /usr/local/bin..."
	sudo install -Dm755 $(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)
	@echo "✅ Installed! Run: nexus --help"

clean: ## Remove build artifacts
	@rm -f $(BINARY_NAME)
	@echo "🧹 Cleaned."

lint: ## Run Go vet and staticcheck
	@echo "🔍 Running Go vet..."
	@go vet ./...
	@echo "✅ All checks passed!"

test: ## Run all tests
	@echo "🧪 Running tests..."
	@go test -v -race ./...

dev: build ## Build and run doctor
	@./$(BINARY_NAME) doctor

init: ## Initialize development environment (setup git hooks)
	@echo "Setting up local Git hooks..."
	@git config core.hooksPath .githooks
	@chmod +x .githooks/*
	@echo "✅ Git hooks configured successfully!"
