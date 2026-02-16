#!/bin/bash
# ============================================================
# RouterOS 7.21.3 一键安装脚本
# 源: https://github.com/qing48674431-cmd/qing-ros-images/releases/tag/v7.21.3
# 用法: bash install-ros-onekey-v7.21.3.sh [本地镜像路径]
#       无参数则从 Releases 下载；有参数则用本地已解压的 .img，跳过下载
# ============================================================

set -e
GITHUB_REPO="qing48674431-cmd/qing-ros-images"
TAG="v7.21.3"
VERSION="7.21.3"
ROS_PASSWORD="${ROS_PASSWORD:-Admin112233}"
IMG_PATH="/tmp/chr.img"

# --- 1. 镜像来源：本地已有或从 Releases 下载 ---
if [ -n "$1" ] && [ -f "$1" ]; then
    echo "使用本地镜像: $1"
    cp -f "$1" "$IMG_PATH"
elif [ -n "$LOCAL_CHR_IMG" ] && [ -f "$LOCAL_CHR_IMG" ]; then
    echo "使用本地镜像 (LOCAL_CHR_IMG): $LOCAL_CHR_IMG"
    cp -f "$LOCAL_CHR_IMG" "$IMG_PATH"
else
    if [ -d /sys/firmware/efi ]; then
        echo "环境检测: [UEFI 模式]"
        IMG_URL="https://github.com/${GITHUB_REPO}/releases/download/${TAG}/chr-${VERSION}.img"
    else
        echo "环境检测: [BIOS 模式]"
        IMG_URL="https://github.com/${GITHUB_REPO}/releases/download/${TAG}/chr-${VERSION}-legacy-bios.img"
    fi
    echo "正在从 GitHub 下载镜像: $IMG_URL"
    curl -L -f -o "$IMG_PATH" "$IMG_URL" --connect-timeout 20 --retry 3
fi

# --- 2. 网络信息 ---
ETH=$(ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p' | head -n 1)
ADDRESS=$(ip addr show "$ETH" | grep global | awk '{print $2}' | head -n 1)
GATEWAY=$(ip route list | grep default | awk '{print $3}' | head -n 1)
if [ -z "$ADDRESS" ] || [ -z "$GATEWAY" ]; then
    echo "Error: 无法获取 IP 或网关，脚本终止。"
    exit 1
fi
echo "保留网络: IP=$ADDRESS 网关=$GATEWAY"

# --- 3. 注入配置到镜像 ---
echo "正在注入配置..."
mkdir -p /mnt/ros_tmp
LOOPDEV=$(losetup -f --show -P "$IMG_PATH")
sleep 1
FOUND_PART=""
for part in "${LOOPDEV}"p{1..5} "${LOOPDEV}"{1..5}; do
    [ -e "$part" ] || continue
    mount "$part" /mnt/ros_tmp 2>/dev/null
    if [ -d /mnt/ros_tmp/rw ]; then
        FOUND_PART="$part"
        break
    fi
    umount /mnt/ros_tmp 2>/dev/null
done
if [ -z "$FOUND_PART" ]; then
    echo "Error: 镜像中未找到 rw 目录。"
    losetup -d "$LOOPDEV"
    exit 1
fi

cat > /mnt/ros_tmp/rw/autorun.scr <<EOF
/user set [find name=admin] password="$ROS_PASSWORD"
/interface ethernet set [ find default-name=ether1 ] name=wan
/ip address add address=$ADDRESS interface=wan
/ip route add gateway=$GATEWAY
/ip service set telnet disabled=yes
/ip service set ssh disabled=no port=22
/ip service set winbox disabled=no
/system device-mode update container=yes
EOF
sync
umount /mnt/ros_tmp
losetup -d "$LOOPDEV"
echo "配置注入完成。"

# --- 4. 写盘 ---
STORAGE=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1; exit}')
if [ -z "$STORAGE" ]; then
    echo "Error: 未找到物理硬盘。"
    exit 1
fi
echo "---------------------------------------------"
echo "目标硬盘: /dev/$STORAGE | 密码: $ROS_PASSWORD"
echo "已注入 device-mode container=yes (首次启动后需冷重启生效)"
echo "---------------------------------------------"
echo "正在写入，请勿断电..."
dd if="$IMG_PATH" of=/dev/"$STORAGE" bs=4M oflag=sync status=progress

# --- 5. 重启 ---
echo "安装完成，3 秒后重启..."
echo "【Container】首次启动后 5 分钟内请做一次「冷关机」再开机，WinBox 里才会有 Container。"
sleep 3
echo 1 > /proc/sys/kernel/sysrq 2>/dev/null || true
echo b > /proc/sysrq-trigger 2>/dev/null || true
reboot -f 2>/dev/null || true
