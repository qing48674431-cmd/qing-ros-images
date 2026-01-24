#!/bin/bash

# ================= 必改区域 =================
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
# 把下面双引号里的内容改成你自己的强密码！！
MY_PASSWORD="SetYourStrongPasswordHere123!" 
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
# ===========================================

# --- 1. 自动备份网络信息 ---
echo "正在备份当前网络配置..."
# 获取默认网卡
ETH=$(ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')
# 获取IP地址(带掩码)
ADDRESS=$(ip addr show "$ETH" | grep global | awk '{print $2}' | head -n 1)
# 获取网关
GATEWAY=$(ip route list | grep default | awk '{print $3}')

echo "网卡: $ETH | IP: $ADDRESS | 网关: $GATEWAY"

if [ -z "$ADDRESS" ] || [ -z "$GATEWAY" ]; then
    echo "❌ 错误：没获取到IP信息，脚本停止以防失联！"
    exit 1
fi
sleep 3

# --- 2. 下载镜像 ---
if [ -d /sys/firmware/efi ]; then
    IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6.img"
    echo "模式: UEFI"
else
    IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6-legacy-bios.img"
    echo "模式: BIOS"
fi

wget "$IMG_URL" -O /tmp/chr.img
cd /tmp

# --- 3. 写入磁盘 ---
STORAGE=$(lsblk | grep disk | awk '{print $1}' | head -n 1)
echo "正在刷入镜像到 /dev/$STORAGE ..."
dd if=chr.img of=/dev/"$STORAGE" bs=4M oflag=sync status=progress

# --- 4. 注入密码和网络配置 ---
echo "正在注入安全配置..."
partprobe /dev/"$STORAGE"
sleep 5
mkdir -p /mnt/ros_boot
# 挂载启动分区
mount /dev/"$STORAGE"2 /mnt/ros_boot || mount /dev/"$STORAGE"1 /mnt/ros_boot

if mountpoint -q /mnt/ros_boot; then
    # 写入自动运行脚本 (Autorun)
    cat > /mnt/ros_boot/autorun.scr <<EOF
/user set admin password=$MY_PASSWORD
/user add name=backup_admin group=full password=$MY_PASSWORD
/interface ethernet set [ find default-name=ether1 ] name=wan
/ip address add address=$ADDRESS interface=wan
/ip route add gateway=$GATEWAY
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
EOF
    
    echo "✅ 成功！密码已设置为: $MY_PASSWORD"
    echo "✅ Telnet/FTP/WWW 已默认关闭，仅保留 WinBox/SSH"
    umount /mnt/ros_boot
else
    echo "⚠️ 挂载失败！密码可能未生效，请重启后立刻通过 VNC 修改！"
    sleep 5
fi

# --- 5. 重启 ---
echo "安装完毕，重启中..."
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
