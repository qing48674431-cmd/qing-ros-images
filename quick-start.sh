#!/bin/bash

#################################################################
# Quick Start Helper for RouterOS DD Installation
# 
# This script provides an interactive wizard for new users
#################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print header
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     RouterOS DD Installation - Interactive Wizard        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

EOF

echo -e "${BLUE}This wizard will help you configure the RouterOS installation.${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This wizard must be run as root!${NC}"
    echo "Please run: sudo bash quick-start.sh"
    exit 1
fi

# Show current system info
echo -e "${GREEN}Current System Information:${NC}"
echo "  OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo 'Unknown')"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo ""

# Show available disks
echo -e "${GREEN}Available Disks:${NC}"
lsblk -d -o NAME,SIZE,TYPE | grep disk | awk '{printf "  %s (%s)\n", "/dev/" $1, $2}'
echo ""

# Ask for disk selection
echo -e "${YELLOW}Select target disk:${NC}"
read -p "Enter disk path (e.g., /dev/vda, /dev/sda): " TARGET_DISK

if [[ ! -b "$TARGET_DISK" ]]; then
    echo -e "${RED}Error: Invalid disk device: $TARGET_DISK${NC}"
    exit 1
fi

# Confirm disk selection
echo ""
echo -e "${RED}WARNING: All data on $TARGET_DISK will be DESTROYED!${NC}"
echo -e "${RED}Are you sure you want to continue? Type 'YES' to proceed:${NC} "
read -r confirm

if [[ "$confirm" != "YES" ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Ask for RouterOS version
echo ""
echo -e "${YELLOW}RouterOS Version:${NC}"
echo "  Recommended: 7.12.1 (CHR stable)"
echo "  Other versions: https://mikrotik.com/download/archive"
read -p "Enter version (or press Enter for 7.12.1): " ROS_VERSION
ROS_VERSION=${ROS_VERSION:-7.12.1}

# Ask for architecture
echo ""
echo -e "${YELLOW}Architecture:${NC}"
echo "  1) x86_64 (64-bit, recommended for most systems)"
echo "  2) x86 (32-bit)"
echo "  3) auto (detect automatically)"
read -p "Select architecture [1-3, default: 3]: " arch_choice
arch_choice=${arch_choice:-3}

case $arch_choice in
    1) ROS_ARCH="x86_64" ;;
    2) ROS_ARCH="x86" ;;
    3) ROS_ARCH="auto" ;;
    *) 
        echo "Invalid choice, using auto-detect"
        ROS_ARCH="auto"
        ;;
esac

# Save network config
echo ""
echo -e "${GREEN}Current Network Configuration:${NC}"
primary_if=$(ip route | grep default | awk '{print $5}' | head -1)
if [[ -n "$primary_if" ]]; then
    ip_addr=$(ip addr show "$primary_if" | grep "inet " | awk '{print $2}' | head -1)
    gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    
    echo "  Interface: $primary_if"
    echo "  IP Address: $ip_addr"
    echo "  Gateway: $gateway"
    
    echo ""
    echo -e "${YELLOW}IMPORTANT: Save this network configuration!${NC}"
    echo "You will need to reconfigure it in RouterOS after installation."
    echo ""
    read -p "Press Enter to continue..."
fi

# Summary
echo ""
echo -e "${GREEN}Installation Summary:${NC}"
echo "  RouterOS Version: $ROS_VERSION"
echo "  Architecture: $ROS_ARCH"
echo "  Target Disk: $TARGET_DISK"
echo ""

# Final confirmation
echo -e "${RED}Last chance to cancel! Type 'INSTALL' to proceed:${NC} "
read -r final_confirm

if [[ "$final_confirm" != "INSTALL" ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Download install script if not present
if [[ ! -f "install-ros.sh" ]]; then
    echo ""
    echo -e "${GREEN}Downloading installation script...${NC}"
    wget -O install-ros.sh https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/install-ros.sh
    chmod +x install-ros.sh
fi

# Run installation
echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

export ROS_VERSION="$ROS_VERSION"
export ROS_ARCH="$ROS_ARCH"
export TARGET_DISK="$TARGET_DISK"

bash install-ros.sh
