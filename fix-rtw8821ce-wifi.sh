#!/bin/bash

# Script to fix RTL8821CE WiFi driver issue on Fedora
# Problem: Firmware is compressed (.xz) but driver can't read it on kernel 6.19+
# Solution: Blacklist module, decompress firmware, rebuild initramfs

set -e  # Stop on error

echo "=========================================="
echo "RTL8821CE WiFi Fix Script for Fedora"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# 1. Check if the module is currently loaded
echo "[1/5] Checking if rtw88_8821ce is loaded..."
if lsmod | grep -q rtw88_8821ce; then
    echo "Module is loaded. It will be blacklisted and removed after reboot."
else
    echo "Module is not loaded."
fi

# 2. Blacklist the module
echo "[2/5] Blacklisting rtw88_8821ce module..."
if [ -f /etc/modprobe.d/blacklist-rtw88.conf ]; then
    echo "Blacklist file already exists."
else
    echo "blacklist rtw88_8821ce" > /etc/modprobe.d/blacklist-rtw88.conf
    echo "Blacklist created."
fi

# 3. Decompress firmware if needed
echo "[3/5] Checking firmware..."
FW_FILE="/lib/firmware/rtw88/rtw8821c_fw.bin"
FW_XZ_FILE="/lib/firmware/rtw88/rtw8821c_fw.bin.xz"

if [ -f "$FW_XZ_FILE" ] && [ ! -f "$FW_FILE" ]; then
    echo "Decompressing firmware..."
    unxz "$FW_XZ_FILE"
    echo "Firmware decompressed."
elif [ -f "$FW_FILE" ]; then
    echo "Firmware already decompressed."
else
    echo "Firmware file not found!"
    exit 1
fi

# 4. Rebuild initramfs
echo "[4/5] Rebuilding initramfs (this may take a moment)..."
dracut --force
echo "Initramfs rebuilt."

# 5. Ask for reboot
echo "[5/5] Done!"
echo "=========================================="
echo "The WiFi fix has been applied."
echo "You need to REBOOT for changes to take effect."
echo "=========================================="
read -p "Reboot now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Please reboot manually later to apply the fix."
fi
