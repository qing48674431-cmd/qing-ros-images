# MikroTik RouterOS DD Installation Script

一个用于将 Linux 系统强制替换为 MikroTik RouterOS 的暴力重装/DD 脚本。

A brute force reinstall/DD script to forcibly replace a Linux system with MikroTik RouterOS.

## ⚠️ 警告 / WARNING

**此脚本会销毁目标磁盘上的所有数据！请谨慎使用！**

**This script will DESTROY all data on the target disk! Use at your own risk!**

## 功能特性 / Features

- ✅ 自动检测系统架构
- ✅ 支持自定义 RouterOS 版本
- ✅ 保存当前网络配置（供参考）
- ✅ 自动下载并解压 RouterOS 镜像
- ✅ 完整的错误处理和日志记录
- ✅ 支持多种磁盘设备
- ✅ 安全确认机制

---

- ✅ Automatic architecture detection
- ✅ Support for custom RouterOS versions
- ✅ Save current network configuration (for reference)
- ✅ Automatic download and extraction of RouterOS images
- ✅ Comprehensive error handling and logging
- ✅ Support for various disk devices
- ✅ Safety confirmation mechanism

## 系统要求 / Requirements

- Linux 系统（Debian, Ubuntu, CentOS, 等）
- Root 权限
- 至少 512MB 内存
- /tmp 目录至少 100MB 可用空间
- 网络连接（用于下载 RouterOS 镜像）

---

- Linux system (Debian, Ubuntu, CentOS, etc.)
- Root privileges
- At least 512MB RAM
- At least 100MB free space in /tmp
- Internet connection (for downloading RouterOS image)

## 快速开始 / Quick Start

### 基本用法 / Basic Usage

```bash
# 下载脚本 / Download the script
wget https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/install-ros.sh

# 赋予执行权限 / Make it executable
chmod +x install-ros.sh

# 运行脚本（默认配置）/ Run with default settings
sudo bash install-ros.sh
```

### 自定义参数 / Custom Parameters

```bash
# 指定版本和目标磁盘 / Specify version and target disk
sudo bash install-ros.sh -v 7.12.1 -d /dev/sda

# 指定架构 / Specify architecture
sudo bash install-ros.sh -v 7.12.1 -a x86_64 -d /dev/vda

# 使用自定义下载 URL / Use custom download URL
sudo bash install-ros.sh -u https://your-mirror.com/routeros.img.gz -d /dev/vda

# 强制模式（跳过确认）/ Force mode (skip confirmations)
sudo bash install-ros.sh -f -v 7.12.1 -d /dev/vda
```

### 使用配置文件 / Using Configuration File

```bash
# 复制示例配置 / Copy example configuration
cp config.example config.conf

# 编辑配置 / Edit configuration
nano config.conf

# 加载配置并运行 / Load config and run
source config.conf && sudo -E bash install-ros.sh
```

## 命令行选项 / Command Line Options

| 选项 Option | 说明 Description | 默认值 Default |
|------------|-----------------|----------------|
| `-v, --version` | RouterOS 版本 / RouterOS version | 7.12.1 |
| `-a, --arch` | 架构 / Architecture (x86, x86_64, arm, arm64) | auto |
| `-d, --disk` | 目标磁盘 / Target disk | /dev/vda |
| `-u, --url` | 自定义下载 URL / Custom download URL | - |
| `-f, --force` | 强制模式，跳过确认 / Force mode, skip confirmations | - |
| `-h, --help` | 显示帮助信息 / Show help message | - |

## 环境变量 / Environment Variables

可以通过环境变量配置脚本：

You can configure the script via environment variables:

```bash
export ROS_VERSION=7.12.1
export ROS_ARCH=x86_64
export TARGET_DISK=/dev/sda
export FORCE_MODE=1

sudo -E bash install-ros.sh
```

## 工作流程 / Workflow

1. **系统检查** / System checks
   - 检查 root 权限 / Check root privileges
   - 检测系统架构 / Detect system architecture
   - 验证目标磁盘 / Verify target disk
   - 检查系统要求 / Check system requirements

2. **网络配置保存** / Network configuration backup
   - 保存当前 IP、网关、DNS / Save current IP, gateway, DNS
   - 生成配置文件供参考 / Generate config file for reference

3. **下载镜像** / Download image
   - 构建下载 URL / Build download URL
   - 下载 RouterOS 镜像 / Download RouterOS image
   - 解压镜像文件 / Extract image file

4. **DD 安装** / DD installation
   - 卸载目标磁盘分区 / Unmount target disk partitions
   - 写入 RouterOS 镜像 / Write RouterOS image
   - 同步数据到磁盘 / Sync data to disk

5. **重启系统** / Reboot system
   - 提示后续步骤 / Show next steps
   - 重启进入 RouterOS / Reboot into RouterOS

## 安装后配置 / Post-Installation Configuration

安装完成后，系统将重启进入 RouterOS。

After installation, the system will reboot into RouterOS.

### 默认登录 / Default Login

- **用户名 / Username**: `admin`
- **密码 / Password**: (无密码 / no password)

### 访问方式 / Access Methods

1. **SSH**: `ssh admin@<your-server-ip>`
2. **Telnet**: `telnet <your-server-ip>`
3. **Web 界面 / WebFig**: `http://<your-server-ip>`
4. **WinBox**: 下载 WinBox 客户端连接 / Download WinBox client to connect

### 网络配置 / Network Configuration

脚本会将当前网络配置保存到 `/tmp/network_config.txt`，但该文件会在重启后丢失。请在运行脚本前记录以下信息：

The script saves current network config to `/tmp/network_config.txt`, but this file will be lost after reboot. Please note the following before running:

```bash
# 查看网络配置 / View network configuration
ip addr show
ip route show
cat /etc/resolv.conf
```

RouterOS 网络配置示例 / RouterOS network configuration example:

```bash
# SSH 登录后执行 / Execute after SSH login
/ip address add address=<your-ip>/<netmask> interface=ether1
/ip route add gateway=<your-gateway>
/ip dns set servers=<dns-server>
```

## 支持的架构 / Supported Architectures

- ✅ **x86**: 32位 x86 架构 / 32-bit x86 architecture
- ✅ **x86_64**: 64位 x86 架构 / 64-bit x86 architecture
- ⚠️ **ARM/ARM64**: 需要手动提供镜像 URL / Requires manual image URL

## 常见问题 / FAQ

### 1. 如何选择正确的 RouterOS 版本？

访问 [MikroTik 下载页面](https://mikrotik.com/download) 查看可用版本。

Visit [MikroTik download page](https://mikrotik.com/download) to see available versions.

### 2. 支持哪些磁盘设备？

常见的磁盘设备：
- `/dev/vda` (VirtIO 磁盘)
- `/dev/sda` (SCSI/SATA 磁盘)
- `/dev/nvme0n1` (NVMe 磁盘)

使用 `lsblk` 命令查看可用磁盘。

Use `lsblk` command to view available disks.

### 3. 安装失败怎么办？

检查日志输出，确保：
- 有足够的内存和磁盘空间
- 网络连接正常
- 下载 URL 可访问
- 目标磁盘设备正确

Check the log output and ensure:
- Sufficient memory and disk space
- Network connection is working
- Download URL is accessible
- Target disk device is correct

### 4. 可以在生产环境使用吗？

**请谨慎使用！** 此脚本会清除所有数据。建议先在测试环境验证。

**Use with caution!** This script wipes all data. Test in a staging environment first.

### 5. 如何恢复原系统？

一旦执行 DD 操作，原系统数据将无法恢复。请务必提前备份重要数据。

Once DD is executed, the original system cannot be recovered. Always backup important data first.

## 安全注意事项 / Security Notes

1. ⚠️ **数据备份** / Data Backup
   - 执行前务必备份所有重要数据
   - Always backup all important data before execution

2. ⚠️ **网络配置** / Network Configuration
   - 记录当前网络配置
   - 准备好通过控制台访问（如 VNC、IPMI）
   - Note current network configuration
   - Prepare console access (VNC, IPMI, etc.)

3. ⚠️ **磁盘选择** / Disk Selection
   - 仔细确认目标磁盘
   - 避免选择错误的磁盘
   - Carefully verify target disk
   - Avoid selecting wrong disk

4. ⚠️ **版本兼容性** / Version Compatibility
   - 确保 RouterOS 版本与硬件兼容
   - 查阅 MikroTik 官方文档
   - Ensure RouterOS version is compatible with hardware
   - Check MikroTik official documentation

## 示例场景 / Example Scenarios

### VPS/云服务器安装 / VPS/Cloud Server Installation

```bash
# 1. 检查磁盘
lsblk

# 2. 下载脚本
wget https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/install-ros.sh
chmod +x install-ros.sh

# 3. 记录网络配置
ip addr show
ip route show

# 4. 执行安装
sudo bash install-ros.sh -v 7.12.1 -d /dev/vda

# 5. 等待重启后通过 SSH 连接
# ssh admin@<your-server-ip>
```

### 自动化部署 / Automated Deployment

```bash
#!/bin/bash
# 自动化部署脚本示例

# 配置参数
export ROS_VERSION=7.12.1
export TARGET_DISK=/dev/vda
export FORCE_MODE=1

# 下载并执行
wget -O /tmp/install-ros.sh https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/install-ros.sh
chmod +x /tmp/install-ros.sh
sudo -E bash /tmp/install-ros.sh
```

## 故障排除 / Troubleshooting

### 下载失败 / Download Failed

```bash
# 使用镜像 URL
sudo bash install-ros.sh -u https://mirror.example.com/chr-7.12.1.img.gz -d /dev/vda

# 或手动下载后指定
wget https://download.mikrotik.com/routeros/7.12.1/chr-7.12.1.img.gz -O /tmp/routeros.img.gz
gunzip /tmp/routeros.img.gz
# 然后修改脚本或使用 dd 命令
```

### DD 速度慢 / Slow DD Speed

```bash
# 安装 pv 工具以显示进度
apt-get install pv  # Debian/Ubuntu
yum install pv      # CentOS/RHEL

# 脚本会自动使用 pv
```

### 网络无法访问 / Network Not Accessible

通过控制台（VNC/IPMI）登录后配置网络：

Login via console (VNC/IPMI) and configure network:

```bash
# 查看接口
/interface print

# 配置 IP
/ip address add address=x.x.x.x/24 interface=ether1

# 配置网关
/ip route add gateway=x.x.x.x

# 配置 DNS
/ip dns set servers=8.8.8.8,8.8.4.4
```

## 贡献 / Contributing

欢迎提交问题和拉取请求！

Issues and pull requests are welcome!

## 许可证 / License

MIT License

## 免责声明 / Disclaimer

此脚本按"原样"提供，不提供任何明示或暗示的保证。使用此脚本的风险由您自行承担。作者不对因使用此脚本而导致的任何数据丢失或其他损害负责。

This script is provided "as is" without warranty of any kind, either express or implied. Use at your own risk. The authors are not responsible for any data loss or other damages resulting from the use of this script.

## 参考资料 / References

- [MikroTik RouterOS 官方网站](https://mikrotik.com/software)
- [RouterOS 文档](https://help.mikrotik.com/docs/)
- [CHR (Cloud Hosted Router) 文档](https://help.mikrotik.com/docs/display/ROS/CHR)

## 联系方式 / Contact

如有问题或建议，请在 GitHub 上提交 Issue。

For questions or suggestions, please submit an issue on GitHub.
