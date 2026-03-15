#!/usr/bin/env bash
set -euo pipefail

# Build Script for Nexus CLI

echo "🚀 Compiling Nexus CLI (Go V2) for CachyOS Workstation Setup..."

# Ensure we have tidy modules
go mod tidy

# Build the binary with size optimization flags
# main.go lives at project root (relocated from cmd/nexus/)
go build -ldflags="-s -w" -o nexus .

echo "✅ Build complete! Binary generated at ./nexus"
echo "   Size: $(du -h nexus | cut -f1)"
echo "   Test: ./nexus doctor"
