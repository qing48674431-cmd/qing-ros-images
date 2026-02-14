# qing-ros-images

MikroTik RouterOS CHR（Cloud Hosted Router）镜像与一键重装脚本仓库。

## 简介

本仓库提供 **RouterOS v7.x** 的 CHR 镜像及配套安装脚本，适用于在 VPS、云主机或物理机上快速部署或重装 MikroTik RouterOS。脚本会自动检测 UEFI / Legacy BIOS，选择对应镜像，并支持在安装前注入网络配置与管理员密码，避免安装后失联。

## 功能特点

- **一键重装**：通过 Shell 脚本从 GitHub 下载镜像并写入本地硬盘
- **双启动支持**：自动识别 UEFI 与 Legacy BIOS，下载对应镜像（标准包 / Legacy BIOS 包）
- **配置预注入**：在写入前将当前 IP、网关、SSH 密码等写入镜像，安装完成即可用当前网络访问
- **安全与可重复**：使用官方/兼容 CHR 镜像，脚本逻辑透明，便于审计与二次修改

## 快速开始

1. 在目标机器上获取 root 或 sudo 权限，并确保可访问 GitHub。
2. 下载并执行安装脚本（以 v7.20.6 为例）：

   ```bash
   wget -qO- https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/v7.20.6install.sh | bash
   ```

   或先下载脚本，修改其中的 `ROS_PASSWORD` 等配置后再执行：

   ```bash
   wget https://raw.githubusercontent.com/qing48674431-cmd/qing-ros-images/main/v7.20.6install.sh
   chmod +x v7.20.6install.sh
   ./v7.20.6install.sh
   ```

3. 脚本会下载镜像、注入配置、写入硬盘并提示重启；重启后使用脚本中设置的密码通过 SSH 或 Winbox 登录。

## 版本与镜像

| 版本 / 标签 | 说明 |
| ----------- | ----- |
| v7.20.6     | 提供 UEFI 标准镜像与 Legacy BIOS 专用镜像，详见 [Releases](https://github.com/qing48674431-cmd/qing-ros-images/releases) |

具体镜像文件名与下载地址以脚本和 Releases 页面为准。

## 注意事项

- **网络**：需能访问 GitHub；若环境受限，可自行将镜像与脚本放到内网或对象存储后修改脚本中的下载地址。
- **数据**：脚本会将镜像写入当前系统识别到的**第一块物理硬盘**，会**覆盖该盘所有数据**，请确认目标机器与磁盘无误后再执行。
- **密码**：安装前请在脚本中修改 `ROS_PASSWORD`，避免使用默认密码。

## 安全与支持

安全策略与漏洞报告方式见 [SECURITY.md](SECURITY.md)。

## 许可证与免责

本仓库中的脚本为方便个人与实验环境使用而提供；镜像来源与合规性请自行确认。使用本仓库内容所造成的任何损失由使用者自行承担。
