cat >/root/v7.20.6install.sh <<'SH'
#!/bin/bash
set -euo pipefail

# ================= 必改区域 =================
MY_PASSWORD="QWERqwer123"   # 改成你自己的强密码
# ===========================================

echo "正在备份当前网络配置..."
ETH=$(ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p' | head -n 1 || true)
ADDRESS=$(ip -o -4 addr show "$ETH" 2>/dev/null | awk '{print $4}' | head -n 1 || true)
GATEWAY=$(ip route list default 2>/dev/null | awk '{print $3}' | head -n 1 || true)

echo "网卡: ${ETH:-N/A} | IP: ${ADDRESS:-N/A} | 网关: ${GATEWAY:-N/A}"

if [ -z "${ADDRESS:-}" ] || [ -z "${GATEWAY:-}" ]; then
  echo "❌ 错误：没获取到IP信息，脚本停止以防失联！"
  exit 1
fi
sleep 2

echo "准备下载镜像..."
if [ -d /sys/firmware/efi ]; then
  IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6.img"
  echo "模式: UEFI"
else
  IMG_URL="https://github.com/qing48674431-cmd/qing-ros-images/releases/download/v7.20.6/chr-7.20.6-legacy-bios.img"
  echo "模式: BIOS"
fi

mkdir -p /tmp/ros_install
cd /tmp/ros_install
rm -f chr.img
wget -O chr.img "$IMG_URL"

echo "准备写入磁盘..."
STORAGE=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | head -n 1)
if [ -z "${STORAGE:-}" ]; then
  echo "❌ 找不到磁盘"
  exit 1
fi
echo "目标磁盘: /dev/$STORAGE"
sleep 2

echo "正在刷入镜像到 /dev/$STORAGE ..."
dd if=chr.img of=/dev/"$STORAGE" bs=4M oflag=sync status=progress
sync

echo "正在注入安全配置..."
partprobe /dev/"$STORAGE" || true
sleep 5

mkdir -p /mnt/ros_boot
umount /mnt/ros_boot 2>/dev/null || true

# 枚举该磁盘所有分区，找到“可写”的那个分区，把 autorun 写进去
PARTS=$(lsblk -ln /dev/"$STORAGE" -o NAME,TYPE | awk '$2=="part"{print $1}')
FOUND=""

for P in $PARTS; do
  umount /mnt/ros_boot 2>/dev/null || true
  if mount /dev/"$P" /mnt/ros_boot 2>/dev/null; then
    if touch /mnt/ros_boot/.writetest 2>/dev/null; then
      rm -f /mnt/ros_boot/.writetest
      FOUND="$P"
      echo "✅ 已找到可写分区: /dev/$FOUND"
      break
    else
      umount /mnt/ros_boot 2>/dev/null || true
    fi
  fi
done

if [ -z "$FOUND" ]; then
  echo "⚠️ 未找到可写分区，无法注入配置！密码可能不会生效。"
else
  cat > /mnt/ros_boot/autorun.rsc <<EOF
/user set [find name=admin] password="$MY_PASSWORD"
/user add name=backup_admin group=full password="$MY_PASSWORD"
/interface ethernet set [ find default-name=ether1 ] name=wan
/ip address add address=$ADDRESS interface=wan
/ip route add gateway=$GATEWAY
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
EOF

  # 兼容：多写几个常见文件名，提高被导入概率
  cp -f /mnt/ros_boot/autorun.rsc /mnt/ros_boot/autorun.scr
  cp -f /mnt/ros_boot/autorun.rsc /mnt/ros_boot/auto.rsc

  sync
  echo "已写入文件："
  ls -al /mnt/ros_boot | grep -E 'autorun|auto\.rsc' || true

  umount /mnt/ros_boot
  echo "✅ 注入完成！密码: $MY_PASSWORD"
  echo "✅ Telnet/FTP/WWW 已默认关闭，仅保留 WinBox/SSH"
fi

echo "安装完毕，重启中..."
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
SH

chmod +x /root/v7.20.6install.sh
bash /root/v7.20.6install.sh
