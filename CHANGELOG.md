# Changelog

All notable changes to the RouterOS DD Installation Script will be documented in this file.

## [1.0.0] - 2026-01-24

### Added
- Initial release of RouterOS DD installation script
- Automatic system architecture detection
- Support for custom RouterOS versions
- Network configuration backup functionality
- Automatic download and extraction of RouterOS images
- Comprehensive error handling and logging
- Support for multiple disk devices (VirtIO, SCSI, NVMe)
- Safety confirmation mechanism
- Force mode for automated deployments
- Configuration file support (config.example)
- Interactive wizard (quick-start.sh)
- Comprehensive bilingual documentation (中文/English)
- .gitignore for temporary files

### Features
- ✅ Root privilege checking
- ✅ System requirements validation
- ✅ Disk detection and validation
- ✅ Network configuration preservation
- ✅ Progress monitoring during DD operation
- ✅ Automatic cleanup on exit
- ✅ Multiple architecture support (x86, x86_64)
- ✅ Custom download URL support
- ✅ Command-line arguments parsing
- ✅ Environment variable configuration

### Supported Platforms
- Debian/Ubuntu
- CentOS/RHEL
- Other Linux distributions with standard tools

### Dependencies
- wget
- gunzip
- dd
- sync
- Optional: pv (for progress display)

### Download URLs
- Main script: https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/install-ros.sh
- Interactive wizard: https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/quick-start.sh

### Default Configuration
- RouterOS Version: 7.12.1
- Architecture: auto-detect
- Target Disk: /dev/vda
- Force Mode: disabled

### Known Limitations
- ARM/ARM64 architectures require manual image URL
- Network configuration must be manually reconfigured in RouterOS
- Temporary files stored in /tmp (requires 100MB+ free space)
- Minimum 512MB RAM recommended

### Security Notes
- All data on target disk will be destroyed
- Script requires root privileges
- Safety confirmations required unless force mode is enabled
- Network configuration backup provided for reference only

### Documentation
- README.md: Complete usage guide in Chinese and English
- config.example: Configuration file template
- CHANGELOG.md: Version history and changes

### Future Plans
- Support for custom cloud-init configurations
- Pre-configured network templates
- Support for multiple RouterOS channels (stable, testing, development)
- Integration with cloud provider APIs
- Automated post-installation configuration
