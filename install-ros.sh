#!/bin/bash

#################################################################
# RouterOS DD Installation Script
# 
# Description: This script forcibly replaces the current Linux
#              system with MikroTik RouterOS (ROS) using DD.
#
# WARNING: This script will DESTROY all data on the target disk!
#          Use at your own risk!
#
# Usage: bash install-ros.sh [options]
#################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default configuration
ROS_VERSION="${ROS_VERSION:-7.12.1}"
ROS_ARCH="${ROS_ARCH:-x86}"
TARGET_DISK="${TARGET_DISK:-/dev/vda}"
DOWNLOAD_URL=""
FORCE_MODE="${FORCE_MODE:-0}"

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print banner
print_banner() {
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         MikroTik RouterOS DD Installation Script         ║
║                                                           ║
║         WARNING: This will DESTROY all data!             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
}

# Show usage
usage() {
    cat << EOF

Usage: $0 [options]

Options:
    -v, --version VERSION    RouterOS version (default: ${ROS_VERSION})
    -a, --arch ARCH          Architecture: x86, x86_64, arm, arm64 (default: ${ROS_ARCH})
    -d, --disk DISK          Target disk (default: ${TARGET_DISK})
    -u, --url URL            Custom download URL for RouterOS image
    -f, --force              Skip confirmations (dangerous!)
    -h, --help               Show this help message

Examples:
    $0 -v 7.12.1 -a x86_64 -d /dev/sda
    $0 --version 7.12.1 --arch x86 --disk /dev/vda --force

Environment Variables:
    ROS_VERSION              RouterOS version
    ROS_ARCH                 Architecture
    TARGET_DISK              Target disk device
    FORCE_MODE               Skip confirmations (1 for true)

EOF
    exit 1
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                ROS_VERSION="$2"
                shift 2
                ;;
            -a|--arch)
                ROS_ARCH="$2"
                shift 2
                ;;
            -d|--disk)
                TARGET_DISK="$2"
                shift 2
                ;;
            -u|--url)
                DOWNLOAD_URL="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_MODE=1
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root!"
        exit 1
    fi
}

# Detect system architecture
detect_arch() {
    local machine_arch=$(uname -m)
    
    if [[ -z "$ROS_ARCH" ]] || [[ "$ROS_ARCH" == "auto" ]]; then
        case "$machine_arch" in
            x86_64)
                ROS_ARCH="x86_64"
                ;;
            i386|i686)
                ROS_ARCH="x86"
                ;;
            aarch64|arm64)
                ROS_ARCH="arm64"
                ;;
            arm*)
                ROS_ARCH="arm"
                ;;
            *)
                log_warn "Unknown architecture: $machine_arch, defaulting to x86"
                ROS_ARCH="x86"
                ;;
        esac
    fi
    
    log_info "Target architecture: $ROS_ARCH"
}

# Detect target disk
detect_disk() {
    if [[ ! -b "$TARGET_DISK" ]]; then
        log_error "Target disk $TARGET_DISK not found!"
        
        log_info "Available disks:"
        lsblk -d -n -o NAME,SIZE,TYPE | grep disk | awk '{print "  /dev/" $1 " (" $2 ")"}'
        
        exit 1
    fi
    
    local disk_size=$(lsblk -b -d -n -o SIZE "$TARGET_DISK" 2>/dev/null)
    local disk_size_gb=$((disk_size / 1024 / 1024 / 1024))
    
    log_info "Target disk: $TARGET_DISK (${disk_size_gb}GB)"
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check for required commands
    local required_cmds=("wget" "gunzip" "dd" "sync")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found!"
            log_info "Please install required packages first."
            log_info "  Debian/Ubuntu: apt-get install wget gzip coreutils"
            log_info "  CentOS/RHEL: yum install wget gzip coreutils"
            exit 1
        fi
    done
    
    # Check available memory
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_total_mb=$((mem_total / 1024))
    
    if [[ $mem_total_mb -lt 512 ]]; then
        log_warn "Low memory detected: ${mem_total_mb}MB. Installation may fail."
    fi
    
    # Check available disk space in /tmp
    local tmp_space=$(df /tmp | tail -1 | awk '{print $4}')
    local tmp_space_mb=$((tmp_space / 1024))
    
    if [[ $tmp_space_mb -lt 100 ]]; then
        log_error "Insufficient space in /tmp: ${tmp_space_mb}MB (need at least 100MB)"
        exit 1
    fi
    
    log_info "System requirements check passed"
}

# Save network configuration
save_network_config() {
    log_info "Saving current network configuration..."
    
    # Get primary network interface
    local primary_if=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [[ -n "$primary_if" ]]; then
        # Get IP configuration
        local ip_addr=$(ip addr show "$primary_if" | grep "inet " | awk '{print $2}' | head -1)
        local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
        local dns_servers=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
        
        cat > /tmp/network_config.txt << EOF
# Network Configuration (for reference)
Interface: $primary_if
IP Address: $ip_addr
Gateway: $gateway
DNS Servers: $dns_servers
EOF
        
        log_info "Network config saved to /tmp/network_config.txt"
        log_info "  Interface: $primary_if"
        log_info "  IP: $ip_addr"
        log_info "  Gateway: $gateway"
        log_warn "Note: You will need to reconfigure network in RouterOS after installation"
    else
        log_warn "Could not detect network configuration"
    fi
}

# Build download URL
build_download_url() {
    if [[ -n "$DOWNLOAD_URL" ]]; then
        log_info "Using custom download URL"
        return
    fi
    
    # MikroTik RouterOS download URL pattern
    # Format: https://download.mikrotik.com/routeros/VERSION/chr-VERSION.img.gz
    
    case "$ROS_ARCH" in
        x86|x86_64)
            # CHR (Cloud Hosted Router) is the x86/x64 version
            DOWNLOAD_URL="https://download.mikrotik.com/routeros/${ROS_VERSION}/chr-${ROS_VERSION}.img.gz"
            ;;
        arm|arm64)
            log_error "ARM architecture support requires manual image preparation"
            log_info "Please provide a custom URL with -u option"
            exit 1
            ;;
        *)
            log_error "Unsupported architecture: $ROS_ARCH"
            exit 1
            ;;
    esac
    
    log_info "Download URL: $DOWNLOAD_URL"
}

# Download RouterOS image
download_image() {
    local image_file="/tmp/routeros.img.gz"
    local extracted_file="/tmp/routeros.img"
    
    log_info "Downloading RouterOS image..."
    
    # Remove old files if they exist
    rm -f "$image_file" "$extracted_file"
    
    # Download with progress
    if ! wget -O "$image_file" "$DOWNLOAD_URL" --progress=bar:force 2>&1 | tee /tmp/download.log; then
        log_error "Failed to download RouterOS image!"
        log_info "Please check the URL and your internet connection"
        exit 1
    fi
    
    log_info "Download completed"
    
    # Extract the image
    log_info "Extracting image..."
    
    if ! gunzip -f "$image_file"; then
        log_error "Failed to extract image!"
        exit 1
    fi
    
    if [[ ! -f "$extracted_file" ]]; then
        log_error "Extracted image not found!"
        exit 1
    fi
    
    local image_size=$(du -h "$extracted_file" | awk '{print $1}')
    log_info "Image extracted successfully (Size: $image_size)"
    
    echo "$extracted_file"
}

# Perform DD installation
perform_dd_installation() {
    local image_file="$1"
    
    log_info "Starting DD installation to $TARGET_DISK..."
    log_warn "This will DESTROY all data on $TARGET_DISK!"
    
    if [[ $FORCE_MODE -ne 1 ]]; then
        echo -e "${RED}Type 'YES' in capital letters to continue:${NC} "
        read -r confirmation
        
        if [[ "$confirmation" != "YES" ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
    
    log_info "Unmounting any partitions on $TARGET_DISK..."
    
    # Unmount all partitions on target disk
    for partition in $(lsblk -ln -o NAME "$TARGET_DISK" | tail -n +2); do
        local partition_path="/dev/$partition"
        # Check if mounted and unmount
        if grep -q "^$partition_path " /proc/mounts 2>/dev/null; then
            log_info "Unmounting $partition_path..."
            umount "$partition_path" 2>/dev/null || true
        fi
    done
    
    log_info "Writing RouterOS image to disk (this may take several minutes)..."
    
    # Perform DD with progress monitoring
    if command -v pv &> /dev/null; then
        pv "$image_file" | dd of="$TARGET_DISK" bs=4M conv=fsync status=none
    else
        dd if="$image_file" of="$TARGET_DISK" bs=4M conv=fsync status=progress
    fi
    
    # Sync to ensure all data is written
    sync
    sync
    
    log_info "DD installation completed successfully!"
}

# Prepare for reboot
prepare_reboot() {
    log_info "Installation completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. The system will reboot into RouterOS"
    log_info "2. Default login: admin (no password)"
    log_info "3. Access via SSH, Telnet, or WebFig/WinBox"
    log_info "4. Configure network settings (see /tmp/network_config.txt)"
    log_info ""
    
    if [[ $FORCE_MODE -ne 1 ]]; then
        echo -e "${YELLOW}Press Enter to reboot now, or Ctrl+C to cancel...${NC}"
        read -r
    fi
    
    log_info "Rebooting system..."
    sleep 2
    
    reboot
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code $exit_code"
    fi
    
    # Clean up temporary files
    rm -f /tmp/routeros.img.gz /tmp/routeros.img 2>/dev/null || true
}

trap cleanup EXIT

# Main function
main() {
    print_banner
    
    parse_args "$@"
    
    check_root
    
    log_info "Starting RouterOS DD installation..."
    log_info "Version: $ROS_VERSION"
    log_info "Architecture: $ROS_ARCH"
    log_info "Target disk: $TARGET_DISK"
    log_info ""
    
    detect_arch
    detect_disk
    check_requirements
    save_network_config
    build_download_url
    
    local image_file=$(download_image)
    
    perform_dd_installation "$image_file"
    
    prepare_reboot
}

# Run main function
main "$@"
