#!/bin/bash

# ================= 配置区 =================
# ！！！请务必修改下面的密码！！！
MY_PASSWORD="admin112233" 
# =========================================

# --- 1. 获取网络信息 (在重装前备份) ---
echo "正在获取网络配置..."

# 获取默认网卡接口名
ETH=$(ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')
# 获取带掩码的IP地址 (例如 192.168.1.5/24)
ADDRESS=$(ip addr show "$ETH" | grep global | awk '{print $2}' | head -n 1)
# 获取网关
GATEWAY=$(ip route list | grep default | awk '{print $3}')

echo "网卡设备: $ETH"
echo "IP地址:   $ADDRESS"
echo "网关地址: $GATEWAY"

if [ -z "$ADDRESS" ] || [ -z "$GATEWAY" ]; then
    echo "❌ 错误：无法自动获取网络信息！脚本停止。"
    exit 1
fi
echo "✅ 网络信息备份成功，稍后将写入 RouterOS。"
sleep 3

# --- 2. 准备镜像 ---
if [ -d /sys/firmware/efi ]; then
    IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6.img"
    echo "检测到 UEFI 启动"
else
    IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6-legacy-bios.img"
    echo "检测到 BIOS 启动"
fi

wget "$IMG_URL" -O /tmp/chr.img
cd /tmp

# --- 3. 写入磁盘 ---
STORAGE=$(lsblk | grep disk | awk '{print $1}' | head -n 1)
echo "目标磁盘: $STORAGE"
echo "正在写入镜像..."
dd if=chr.img of=/dev/"$STORAGE" bs=4M oflag=sync status=progress

# --- 4. 注入配置 (密码 + 静态IP) ---
echo "正在刷新分区表..."
partprobe /dev/"$STORAGE"
sleep 5

echo "正在注入配置脚本..."
mkdir -p /mnt/ros_boot
# 尝试挂载分区 (ROS通常有两个分区，配置脚本要在启动分区)
mount /dev/"$STORAGE"2 /mnt/ros_boot || mount /dev/"$STORAGE"1 /mnt/ros_boot

if mountpoint -q /mnt/ros_boot; then
    # 生成 RouterOS 自动执行脚本
    # 注意：ether1 是 CHR 默认的第一个网卡名称
    cat > /mnt/ros_boot/autorun.scr <<EOF
/user set admin password=$MY_PASSWORD
/user add name=backup_admin group=full password=$MY_PASSWORD
/interface ethernet set [ find default-name=ether1 ] name=wan
/ip address add address=$ADDRESS interface=wan
/ip route add gateway=$GATEWAY
/ip dns set servers=8.8.8.8,1.1.1.1
/ip service set telnet disabled=no
EOF
    
    echo "✅ 配置注入成功！"
    echo "   - 密码已设置"
    echo "   - IP已固定: $ADDRESS"
    echo "   - 网关已设置: $GATEWAY"
    
    umount /mnt/ros_boot
else
    echo "⚠️ 警告：无法挂载分区，配置注入失败！机器重启后可能需要 VNC 配置。"
    sleep 5
fi

# --- 5. 重启 ---
echo "安装完成，正在重启..."
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
