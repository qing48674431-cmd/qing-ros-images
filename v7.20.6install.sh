cat >/root/fix_install.sh <<'SH'
#!/bin/bash
set -u

# ================= 必改区域 =================
MY_PASSWORD="QWERqwer123"   # 务必修改！
# ===========================================

# 1. 备份网络信息
echo "正在备份网络配置..."
ETH=$(ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p' | head -n 1)
ADDRESS=$(ip -o -4 addr show "$ETH" | awk '{print $4}' | head -n 1)
GATEWAY=$(ip route list default | awk '{print $3}' | head -n 1)

echo "网卡: ${ETH} | IP: ${ADDRESS} | 网关: ${GATEWAY}"
if [ -z "$ADDRESS" ] || [ -z "$GATEWAY" ]; then echo "❌ 网络信息获取失败"; exit 1; fi

# 2. 下载镜像
echo "正在下载镜像..."
# 统一使用 UEFI 包 (CHR 的 7.x 镜像通常是混合模式，如果无法启动再尝试 Legacy)
# 这里为了稳妥，我们还是检测一下
if [ -d /sys/firmware/efi ]; then
  IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6.img"
else
  IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6-legacy-bios.img"
fi

cd /tmp
wget -O chr.img "$IMG_URL"

# 3. 【核心修复】直接挂载镜像文件注入配置
# 这样避免了 dd 后无法挂载物理磁盘的问题
echo "正在注入配置到镜像文件..."

# 计算分区偏移量 (通常第二个分区是启动分区)
# 使用 kpartx 或 fdisk 计算 offset。RouterOS 镜像通常分区2是 EFI/Boot
# 这里采用最通用的挂载第一个 FAT 分区的方法
OFFSET=$(fdisk -l chr.img | grep -i "FAT" | awk '{print $2 * 512}')
if [ -z "$OFFSET" ]; then 
    # 如果没找到 FAT，尝试挂载第一个分区
    OFFSET=$(fdisk -l chr.img | grep chr.img | tail -n +2 | head -n 1 | awk '{print $2 * 512}')
fi

mkdir -p /mnt/ros_img
if mount -o loop,offset=$OFFSET chr.img /mnt/ros_img; then
    
    # 写入 Autorun 脚本 (严格按照官方 autorun.scr 命名)
    cat > /mnt/ros_img/autorun.scr <<EOF
/user set [find name=admin] password="$MY_PASSWORD"
/user add name=backup_admin group=full password="$MY_PASSWORD"

/interface ethernet set [ find default-name=ether1 ] name=wan
/ip address add address=$ADDRESS interface=wan
/ip route add gateway=$GATEWAY

/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes

# 防火墙配置：仅允许 Winbox(8291) 和 SSH(22)
/ip firewall filter
add chain=input protocol=tcp dst-port=8291 action=accept comment="Allow Winbox"
add chain=input protocol=tcp dst-port=22 action=accept comment="Allow SSH"
add chain=input protocol=icmp action=accept comment="Allow Ping"
add chain=input connection-state=established,related action=accept comment="Allow Established"
add chain=input action=drop comment="Drop Everything Else"
EOF

    echo "✅ 配置已直接注入镜像文件！"
    umount /mnt/ros_img
else
    echo "⚠️ 无法挂载镜像文件，尝试直接写入（如果失败请手动配置 VNC）"
fi

# 4. 彻底写入磁盘
STORAGE=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | head -n 1)
echo "目标磁盘: /dev/$STORAGE"

echo "正在写入... (Magic SysRq 重启法)"

# 写入
dd if=chr.img of=/dev/"$STORAGE" bs=4M oflag=sync status=progress

# 5. 强制重启
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
SH

chmod +x /root/fix_install.sh
bash /root/fix_install.sh
