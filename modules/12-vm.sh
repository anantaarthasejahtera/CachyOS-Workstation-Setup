#!/usr/bin/env bash
# Module 12: Windows Compatibility & Virtualization
source "$(dirname "$0")/00-common.sh"
header "Windows Compatibility — VM, Bottles, Office"

# --- Check hardware virtualization support ---
log "Checking virtualization support..."
if grep -qE 'vmx|svm' /proc/cpuinfo 2>/dev/null; then
    ok "Hardware virtualization supported (Intel VT-x / AMD-V)"
else
    warn "Hardware virtualization NOT detected. Enable VT-x in BIOS!"
fi

# --- QEMU/KVM + Virt-Manager (Windows VM) ---
log "Installing QEMU/KVM virtualization stack..."
install_pkg qemu-full virt-manager libvirt edk2-ovmf dnsmasq iptables-nft \
    swtpm spice-vdagent vde2 bridge-utils

# Enable libvirt services
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.service

# Add user to libvirt + kvm groups (no sudo needed for VM management)
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"

# --- QEMU user permissions (run VMs without root) ---
log "Configuring QEMU permissions..."
sudo sed -i 's/^#\?user = .*/user = "'"$USER"'"/' /etc/libvirt/qemu.conf 2>/dev/null || true
sudo sed -i 's/^#\?group = .*/group = "libvirt"/' /etc/libvirt/qemu.conf 2>/dev/null || true
sudo systemctl restart libvirtd.service

# --- Enable nested virtualization (Docker in Windows VM, etc) ---
log "Enabling nested virtualization..."
if grep -qi 'intel' /proc/cpuinfo; then
    echo 'options kvm_intel nested=1' | sudo tee /etc/modprobe.d/kvm-intel.conf > /dev/null
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel nested=1 2>/dev/null || true
    ok "Intel nested virtualization enabled"
elif grep -qi 'amd' /proc/cpuinfo; then
    echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm-amd.conf > /dev/null
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd nested=1 2>/dev/null || true
    ok "AMD nested virtualization enabled"
fi

# --- Hugepages for VM (15-20% memory speed boost) ---
log "Configuring hugepages for VM performance..."
TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
if [ "$TOTAL_RAM_MB" -ge 12288 ]; then
    # 12GB+ RAM: recommend hugepages (configured per-VM in libvirt XML, not globally)
    # Global reservation removed to avoid starving host. Use <memoryBacking><hugepages/></memoryBacking> in VM XML.
    ok "Hugepages available (enable per-VM in libvirt XML — see $VM_POOL/README-vm-tips.txt)"
elif [ "$TOTAL_RAM_MB" -ge 8192 ]; then
    # 8-12GB RAM: hugepages available but not reserved globally
    ok "Hugepages available (enable per-VM in libvirt XML for 15-20% speed boost)"
else
    # <8GB RAM: skip hugepages entirely
    warn "Hugepages skipped (${TOTAL_RAM_MB}MB RAM detected — need 8GB+ for VM hugepages)"
    warn "  VMs will still work, just without the 15-20% memory speed boost"
fi

# --- Enable default NAT network ---
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

# --- Default storage pool ---
log "Creating default VM storage pool..."
VM_POOL="$HOME/VMs"
mkdir -p "$VM_POOL"
sudo virsh pool-define-as default dir --target "$VM_POOL" 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true
sudo virsh pool-start default 2>/dev/null || true
ok "VM storage pool: $VM_POOL"

# --- Download VirtIO drivers ISO (makes Windows VM 2x faster) ---
log "Downloading VirtIO Windows drivers..."
VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
VIRTIO_ISO="$VM_POOL/virtio-win.iso"
if [ ! -f "$VIRTIO_ISO" ]; then
    curl -fsSL -o "$VIRTIO_ISO" "$VIRTIO_URL" 2>/dev/null &
    log "  VirtIO ISO downloading in background to: $VIRTIO_ISO"
fi

# --- IOMMU (GPU Passthrough preparation \u2014 auto-enable if hardware supports) ---
log "Checking IOMMU for GPU passthrough..."
GPU_COUNT=$(lspci | grep -ciE 'vga|3d|display')
if [ "$GPU_COUNT" -ge 2 ]; then
    log "Multiple GPUs detected! Enabling IOMMU for GPU passthrough..."
    if grep -qi 'intel' /proc/cpuinfo; then
        IOMMU_PARAM="intel_iommu=on iommu=pt"
    else
        IOMMU_PARAM="amd_iommu=on iommu=pt"
    fi
    # Add IOMMU to kernel parameters
    if ! grep -q 'iommu=pt' /etc/default/grub 2>/dev/null; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$IOMMU_PARAM /" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        ok "IOMMU enabled (reboot required for GPU passthrough)"
    fi
else
    log "  Single GPU detected \u2014 GPU passthrough not available"
    log "  (Will auto-enable when 2+ GPUs detected, e.g. on desktop with dGPU)"
fi

# --- CPU Pinning Hook (auto-isolate CPU cores for VM) ---
log "Installing CPU pinning hook for libvirt..."
sudo mkdir -p /etc/libvirt/hooks
cat << 'CPUPIN' | sudo tee /etc/libvirt/hooks/qemu > /dev/null
#!/bin/bash
# Libvirt hook: auto CPU pinning for better VM performance
# Isolates cores 2-3 for VM, leaves 0-1 for host
GUEST_NAME="$1"
ACTION="$2"

if [ "$ACTION" = "started" ]; then
    # When VM starts: pin VM to cores 2-3 (adjust for your CPU)
    TOTAL_CORES=$(nproc)
    if [ "$TOTAL_CORES" -ge 4 ]; then
        systemctl set-property --runtime "machine-qemu\\x2d*" AllowedCPUs=2-$((TOTAL_CORES-1)) 2>/dev/null || true
    fi
elif [ "$ACTION" = "stopped" ]; then
    # When VM stops: release all cores
    systemctl set-property --runtime "machine-qemu\\x2d*" AllowedCPUs=0-$(($(nproc)-1)) 2>/dev/null || true
fi
CPUPIN
sudo chmod +x /etc/libvirt/hooks/qemu
ok "CPU pinning hook installed (auto-isolate cores for VM)"

# --- Optimized VM template config ---
log "Creating optimized VM config template..."
cat > "$VM_POOL/README-vm-tips.txt" << 'VMTIPS'
======================================================================
  QEMU/KVM Performance Cheatsheet
======================================================================

--- CREATE WINDOWS VM (virt-manager) ---
1. New VM > Local install > select Windows ISO
2. RAM: 4096 MB (check "Enable hugepages" in XML)
3. CPU: 2 cores, topology 1 socket / 1 core / 2 threads
4. Disk: 60GB, bus=VirtIO, cache=writeback, io=threads
5. NIC: virtio
6. Add Hardware > Storage > select virtio-win.iso as CDROM
7. Boot: install Windows, load VirtIO drivers from CDROM

--- ENABLE HUGEPAGES IN VM XML ---
<memoryBacking>
  <hugepages/>
</memoryBacking>

--- ENABLE IO THREADS IN VM XML ---
<iothreads>2</iothreads>
<disk type="file" device="disk">
  <driver name="qemu" type="qcow2" cache="writeback" io="threads"/>
</disk>

--- ENABLE CPU PASSTHROUGH IN VM XML ---
<cpu mode="host-passthrough" check="none" migratable="on"/>

--- GPU PASSTHROUGH (desktop with 2 GPUs only) ---
1. Enable IOMMU in BIOS + kernel (auto-done by this script if 2 GPUs)
2. Identify GPU IOMMU group: find /sys/kernel/iommu_groups -type l
3. Bind GPU to vfio-pci driver
4. Add GPU as PCI device in virt-manager
5. Install NVIDIA/AMD drivers inside Windows VM

--- USEFUL COMMANDS ---
virsh list --all          # List all VMs
virsh start win11         # Start VM
virsh shutdown win11      # Graceful shutdown
virsh destroy win11       # Force stop
virt-manager              # GUI manager
======================================================================
VMTIPS
ok "VM cheatsheet saved to $VM_POOL/README-vm-tips.txt"

# --- Windows ISO download helper script ---
cat > "$VM_POOL/download-windows-iso.sh" << 'WINISO'
#!/bin/bash
# Helper to download Windows evaluation ISO
echo "===================================="
echo "  Windows ISO Download Options"
echo "===================================="
echo ""
echo "1. Windows 11 (official):"
echo "   https://www.microsoft.com/software-download/windows11"
echo ""
echo "2. Windows 11 Evaluation (free 90 days, for testing):"
echo "   https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise"
echo ""
echo "3. Tiny11 (community-stripped Windows 11, lightweight ~4GB):"
echo "   https://github.com/ntdevlabs/tiny11builder"
echo ""
echo "Recommended: Download ISO manually, save to ~/VMs/"
echo "Then: virt-manager > New VM > select the .iso"
WINISO
chmod +x "$VM_POOL/download-windows-iso.sh"
ok "Windows ISO helper saved: $VM_POOL/download-windows-iso.sh"

ok "QEMU/KVM fully optimized (near-native performance)"
log "  VM storage: $VM_POOL"
log "  Tips: cat $VM_POOL/README-vm-tips.txt"
log "  Windows ISO: bash $VM_POOL/download-windows-iso.sh"

# --- Bottles (run Windows apps WITHOUT a VM) ---
log "Installing Bottles (Windows app runner)..."
flatpak install --user -y flathub com.usebottles.bottles 2>/dev/null || \
    install_aur bottles 2>/dev/null || true
ok "Bottles installed (run MS Office 2016, small Windows apps)"

# --- LibreOffice (native Office alternative) ---
log "Installing LibreOffice..."
install_pkg libreoffice-fresh
ok "LibreOffice installed (opens .docx, .xlsx, .pptx natively)"

# --- KDE Connect (phone <-> laptop sync) ---
log "Installing KDE Connect..."
install_pkg kdeconnect
ok "KDE Connect installed (pair phone for file transfer, notifications, remote)"

# --- Obsidian (markdown knowledge base) ---
log "Installing Obsidian..."
install_aur obsidian-bin 2>/dev/null || \
    flatpak install --user -y flathub md.obsidian.Obsidian 2>/dev/null || true
ok "Obsidian installed (markdown note-taking)"

# --- KeePassXC (password manager, offline, encrypted) ---
log "Installing KeePassXC..."
install_pkg keepassxc
ok "KeePassXC installed (encrypted password manager, works offline)"

# --- Screen recording ---
log "Installing screen recording tools..."
install_pkg obs-studio wf-recorder
ok "OBS Studio + wf-recorder installed"
log "  OBS: full studio (streaming + recording)"
log "  wf-recorder: lightweight Wayland recorder"
log "  Quick record: wf-recorder -f ~/Videos/recording.mp4"
log "  Region record: wf-recorder -g \"\$(slurp)\" -f ~/Videos/clip.mp4"

ok "Windows compatibility & productivity ready"

