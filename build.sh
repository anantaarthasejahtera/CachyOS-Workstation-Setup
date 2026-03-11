#!/usr/bin/env bash
set -euo pipefail

# Build Script for Nexus CLI

echo "🚀 Compiling Nexus CLI (Go V2) for CachyOS Workstation Setup..."

# Ensure we have tidy modules
go mod tidy

# Build the binary with size optimization flags
go build -ldflags="-s -w" -o nexus ./cmd/nexus

echo "✅ Build complete! Binary generated at ./nexus"
echo "You can test it by running: ./nexus doctor"
