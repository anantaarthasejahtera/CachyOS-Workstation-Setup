#!/usr/bin/env bash
# Module 05: Flutter & Android Development
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
header "Flutter & Android Development"

# --- JDK 17 (required by Gradle/Android) ---
log "Installing JDK 17..."
install_pkg jdk17-openjdk jdk17-openjdk-doc
sudo archlinux-java set java-17-openjdk 2>/dev/null || true
ok "JDK 17 set as default"

# --- Kotlin compiler ---
log "Installing Kotlin..."
install_pkg kotlin
ok "Kotlin installed"

# --- Gradle ---
log "Installing Gradle..."
install_pkg gradle
ok "Gradle installed"

# --- Android SDK CLI tools (lightweight, no Android Studio) ---
log "Installing Android SDK CLI tools..."
ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"

# Download latest cmdline-tools
CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    cd /tmp
    curl -fsSL -o cmdline-tools.zip "$CMDLINE_URL"
    unzip -q cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm cmdline-tools.zip
    cd ~
fi

# Add to PATH
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Accept licenses & install SDK components
yes | sdkmanager --licenses 2>/dev/null || true
sdkmanager --install \
    "platform-tools" \
    "build-tools;34.0.0" \
    "platforms;android-34" \
    "sources;android-34" \
    "emulator" \
    "system-images;android-34;google_apis;x86_64" \
    2>/dev/null || true
ok "Android SDK installed (API 34)"

# --- Create AVD (Android Virtual Device) ---
log "Creating Android emulator..."
avdmanager create avd -n "Pixel_7" -k "system-images;android-34;google_apis;x86_64" -d "pixel_7" --force 2>/dev/null || true
ok "Android emulator 'Pixel_7' created"

# --- Flutter SDK ---
log "Installing Flutter..."
FLUTTER_DIR="$HOME/.flutter-sdk"
if [ ! -d "$FLUTTER_DIR" ]; then
    git clone --depth=1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

# Pre-cache Flutter tools
flutter precache 2>/dev/null || true
flutter config --android-sdk "$ANDROID_HOME" 2>/dev/null || true
flutter config --no-analytics 2>/dev/null || true
dart --disable-analytics 2>/dev/null || true
ok "Flutter SDK installed"

# --- scrcpy (mirror Android device to screen) ---
log "Installing scrcpy (device mirror)..."
install_pkg scrcpy
ok "scrcpy installed (run: scrcpy, to mirror your phone)"

# --- ADB udev rules (USB debugging without root) ---
log "Setting up ADB udev rules..."
install_pkg android-udev
sudo usermod -aG adbusers "$USER" 2>/dev/null || true
ok "ADB udev rules configured"

log "Running flutter doctor..."
flutter doctor 2>&1 | tee -a "$LOGFILE" || true

ok "Flutter & Android development ready"

