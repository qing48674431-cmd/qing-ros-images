# Troubleshooting Guide / 故障排除指南

This guide helps you resolve common issues when using the RouterOS DD installation script.

本指南帮助您解决使用 RouterOS DD 安装脚本时的常见问题。

## Table of Contents / 目录

1. [Installation Issues / 安装问题](#installation-issues)
2. [Network Issues / 网络问题](#network-issues)
3. [System Requirements / 系统要求](#system-requirements)
4. [Download Issues / 下载问题](#download-issues)
5. [Post-Installation Issues / 安装后问题](#post-installation-issues)

---

## Installation Issues / 安装问题

### Error: "This script must be run as root!"

**Problem / 问题**: The script requires root privileges to modify disks.

**Solution / 解决方案**:
```bash
# Use sudo to run the script
sudo bash install-ros.sh

# Or switch to root user
su -
bash install-ros.sh
```

---

### Error: "Target disk /dev/xxx not found!"

**Problem / 问题**: The specified disk device doesn't exist.

**Solution / 解决方案**:
```bash
# List all available disks
lsblk -d

# Or use fdisk
fdisk -l

# Then specify the correct disk
sudo bash install-ros.sh -d /dev/sda  # or /dev/vda, /dev/nvme0n1, etc.
```

---

### Error: "Insufficient space in /tmp"

**Problem / 问题**: Not enough space to download and extract RouterOS image.

**Solution / 解决方案**:
```bash
# Check available space
df -h /tmp

# Option 1: Clean up /tmp
sudo rm -rf /tmp/*

# Option 2: Use a different temporary directory
export TMPDIR=/var/tmp
sudo bash install-ros.sh

# Option 3: Mount tmpfs with more space
sudo mount -o remount,size=2G /tmp
```

---

### Error: "Low memory detected"

**Problem / 问题**: System has less than 512MB RAM.

**Solution / 解决方案**:
```bash
# Check memory
free -m

# Option 1: Close unnecessary services
systemctl stop apache2 mysql

# Option 2: Create swap space
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Then run the installation
sudo bash install-ros.sh
```

---

### Error: "Required command 'xxx' not found!"

**Problem / 问题**: Missing required system utilities.

**Solution / 解决方案**:
```bash
# For Debian/Ubuntu
sudo apt-get update
sudo apt-get install wget gzip coreutils

# For CentOS/RHEL
sudo yum install wget gzip coreutils

# For Alpine
sudo apk add wget gzip coreutils
```

---

## Network Issues / 网络问题

### Cannot access server after installation

**Problem / 问题**: Server is unreachable after RouterOS installation.

**Solution / 解决方案**:

1. **Access via console** (VNC, IPMI, KVM):
   ```bash
   # Login as: admin (no password)
   
   # Check interfaces
   /interface print
   
   # Configure IP address
   /ip address add address=YOUR_IP/NETMASK interface=ether1
   
   # Configure gateway
   /ip route add gateway=YOUR_GATEWAY
   
   # Configure DNS
   /ip dns set servers=8.8.8.8,8.8.4.4
   ```

2. **Enable DHCP** (if applicable):
   ```bash
   /ip dhcp-client add interface=ether1 disabled=no
   ```

3. **Check firewall**:
   ```bash
   # Temporarily disable firewall for testing
   /ip firewall filter disable [find]
   ```

---

### Lost network configuration

**Problem / 问题**: Forgot to save network configuration before installation.

**Solution / 解决方案**:

If you forgot to save the configuration:

1. Contact your hosting provider for network details
2. Check provider's control panel for IP configuration
3. Look for provider documentation or welcome emails

Typical configuration pattern:
```bash
# Static IP
/ip address add address=x.x.x.x/24 interface=ether1
/ip route add gateway=x.x.x.1

# DNS
/ip dns set servers=8.8.8.8,8.8.4.4
```

---

## System Requirements / 系统要求

### Script won't work on my architecture

**Problem / 问题**: ARM or other non-x86 architectures.

**Solution / 解决方案**:

For ARM/ARM64 systems:
```bash
# You need to provide a custom RouterOS ARM image URL
sudo bash install-ros.sh -u https://your-mirror.com/arm-routeros.img.gz -d /dev/sda

# Or manually download and use DD
wget https://your-arm-routeros-url/image.img.gz
gunzip image.img.gz
dd if=image.img of=/dev/sda bs=4M status=progress
sync
reboot
```

---

## Download Issues / 下载问题

### Download fails or times out

**Problem / 问题**: Cannot download RouterOS image from MikroTik servers.

**Solution / 解决方案**:

**Option 1: Use a mirror**
```bash
# Find a working mirror and use custom URL
sudo bash install-ros.sh -u https://mirror.example.com/chr-7.12.1.img.gz
```

**Option 2: Manual download**
```bash
# Download manually first
wget https://download.mikrotik.com/routeros/7.12.1/chr-7.12.1.img.gz -O /tmp/routeros.img.gz

# Verify download
ls -lh /tmp/routeros.img.gz

# Extract
gunzip /tmp/routeros.img.gz

# Then use DD directly
sudo dd if=/tmp/routeros.img of=/dev/vda bs=4M status=progress
sudo sync
sudo reboot
```

**Option 3: Resume download**
```bash
# Use wget with continue option
wget -c https://download.mikrotik.com/routeros/7.12.1/chr-7.12.1.img.gz
```

---

### Cannot access MikroTik download servers

**Problem / 问题**: Firewall or network restrictions.

**Solution / 解决方案**:
```bash
# Test connectivity
ping download.mikrotik.com
curl -I https://download.mikrotik.com

# If blocked, use proxy or VPN
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
sudo -E bash install-ros.sh
```

---

## Post-Installation Issues / 安装后问题

### Server won't boot after installation

**Problem / 问题**: System fails to boot into RouterOS.

**Possible causes / 可能原因**:
1. DD process was interrupted
2. Disk write errors
3. Boot configuration issues

**Solution / 解决方案**:

1. **Retry installation**:
   - Boot into rescue mode
   - Run the installation script again
   - Ensure it completes without errors

2. **Check GRUB/boot settings**:
   - Some VPS require specific boot parameters
   - Contact hosting provider for support

---

### Can't login to RouterOS

**Problem / 问题**: Unable to access RouterOS after installation.

**Solution / 解决方案**:

**Default credentials**:
- Username: `admin`
- Password: (empty - just press Enter)

**Access methods**:
```bash
# SSH
ssh admin@your-server-ip

# Telnet (if SSH fails)
telnet your-server-ip

# Web interface
http://your-server-ip
# or
https://your-server-ip
```

**If login fails**:
1. Try console access (VNC/IPMI)
2. Verify network connectivity
3. Check if services are running:
   ```bash
   # From console
   /ip service print
   /ip service enable ssh,telnet,www
   ```

---

### RouterOS license issues

**Problem / 问题**: RouterOS CHR requires a license.

**Solution / 解决方案**:

RouterOS CHR (Cloud Hosted Router) has free and paid tiers:

**Free tier (P1)**:
- 1 Mbps bandwidth limit
- All features available
- No time limit

**Paid licenses**:
- P10: 10 Mbps - $45/year
- P-unlimited: unlimited - $95/year
- Perpetual licenses available

To upgrade license:
```bash
# Login to RouterOS
/system license print

# Upload license key
/system license import file=license.key
```

Visit: https://mikrotik.com/download

---

## Performance Issues / 性能问题

### System is slow after installation

**Problem / 问题**: RouterOS running slower than expected.

**Solution / 解决方案**:

1. **Check resource usage**:
   ```bash
   /system resource print
   /system resource monitor
   ```

2. **Disable unnecessary features**:
   ```bash
   # Disable IPv6 if not needed
   /ipv6 settings set disable-ipv6=yes
   
   # Disable bandwidth test server
   /tool bandwidth-server set enabled=no
   ```

3. **Optimize settings**:
   ```bash
   # Enable fasttrack
   /ip firewall filter add chain=forward action=fasttrack-connection connection-state=established,related
   ```

---

## Recovery / 恢复

### Need to restore original OS

**Problem / 问题**: Want to go back to original Linux system.

**Solution / 解决方案**:

⚠️ **Important**: Once DD overwrites the disk, the original system cannot be recovered unless you have backups.

**If you have backups**:
1. Boot from rescue/recovery mode
2. Restore from backup

**If you don't have backups**:
1. Reinstall your original OS using your provider's tools
2. Or install a new OS manually

**Prevention**:
- Always backup important data before running DD
- Test in a staging environment first
- Keep server backups updated

---

## Getting Help / 获取帮助

If you're still experiencing issues:

1. **Check the logs**:
   ```bash
   # Script creates logs during installation
   cat /tmp/download.log
   cat /tmp/network_config.txt
   ```

2. **Enable verbose mode**:
   ```bash
   # Run with bash -x for debugging
   bash -x install-ros.sh
   ```

3. **Submit an issue**:
   - Go to GitHub repository
   - Provide detailed error messages
   - Include system information (OS, version, architecture)

4. **MikroTik resources**:
   - Forum: https://forum.mikrotik.com
   - Wiki: https://wiki.mikrotik.com
   - Docs: https://help.mikrotik.com/docs/

---

## Common Questions / 常见问题

### Q: Will this work with any VPS provider?

**A**: Yes, as long as:
- You have root access
- The disk is accessible as a block device
- You have console access (VNC/IPMI) for post-install configuration

### Q: Can I run this on a production server?

**A**: Not recommended! Always test in staging first. This script DESTROYS all data.

### Q: How long does installation take?

**A**: Typically 5-15 minutes depending on:
- Download speed
- Disk write speed
- Server specifications

### Q: Can I automate this?

**A**: Yes, use force mode:
```bash
export FORCE_MODE=1
sudo -E bash install-ros.sh
```

### Q: What if I have multiple disks?

**A**: Specify the exact disk you want to use:
```bash
sudo bash install-ros.sh -d /dev/sda  # Target first disk
```

---

## Safety Checklist / 安全检查清单

Before running the script:

- [ ] Backed up all important data
- [ ] Noted current network configuration (IP, gateway, DNS)
- [ ] Verified target disk device name
- [ ] Have console access (VNC/IPMI) available
- [ ] Tested in staging environment (if possible)
- [ ] Read the documentation thoroughly
- [ ] Understand that ALL DATA will be destroyed
- [ ] Have a recovery plan if something goes wrong

---

**Remember / 记住**: This script performs a destructive operation. Always proceed with caution and ensure you have proper backups and recovery options available.
