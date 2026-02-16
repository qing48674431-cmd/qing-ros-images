

针对 **RouterOS CHR v7.21.3** 相关脚本与文档的本轮修改说明。

---

## 一、脚本调整

| 修改 | 说明 |
|------|------|
| **新增** `v7.21.3 install-ros-onekey.sh` | 一键安装脚本：从本仓库 [Releases v7.21.3](https://github.com/qing48674431-cmd/qing-ros-images/releases/tag/v7.21.3) 下载 chr-7.21.3.img / chr-7.21.3-legacy-bios.img（按 UEFI/BIOS 自动选择），注入网络与密码、device-mode container=yes，DD 写盘后重启。支持传入**本地 .img 路径**，跳过下载。 |
| **移除** `v7.21.3install.sh` | 功能已由 `v7.21.3 install-ros-onekey.sh` 覆盖，故删除旧脚本。 |

---

## 二、Container 相关

| 修改 | 说明 |
|------|------|
| **autorun 注入** | 一键脚本在镜像中写入 `/system device-mode update container=yes`。装好后首次启动会执行该命令；若需 WinBox 里出现 Container，需在 **5 分钟内做一次冷关机再开机**（控制面板/宿主机断电再开）。 |
| **文档** | 新增 [制作已启用Container的CHR镜像.md](制作已启用Container的CHR镜像.md)：如何制作「DD 后直接有 Container」的 .img，以及用 npk 把 container 包加入镜像的说明。 |

---

## 三、MikroTikPatch 与 npk

| 修改 | 说明 |
|------|------|
| **MikroTikPatch 副本** | 将 [elseif/MikroTikPatch](https://github.com/elseif/MikroTikPatch) 仓库内容复制到本仓库 `MikroTikPatch/`，便于本地使用 npk.py、chr.sh、patch.py 等。 |
| **prepare_container_npk.sh** | 新增脚本：从 MikroTikPatch Releases 下载 all_packages-x86-7.21.3.zip，解出 container.npk 到 `MikroTikPatch/container_npk/`，无需去官方下载。可选执行 npk.py verify（需配置公钥环境变量）。 |
| **MikroTikPatch/SOURCE.md** | 说明副本来源，以及「用 npk.py 做一遍 Container」的用法（含 prepare_container_npk.sh）。 |

---

## 四、其他

| 修改 | 说明 |
|------|------|
| **SOURCE.md** | 仓库根目录来源说明（若存在）。 |
| **总结.md** | 本文档：仅针对 v7.21.3 的**本次修改**总结，非全仓库说明。 |

---

## 五、v7.21.3 一键安装用法（简要）

```bash
# 从 Releases 下载并安装
bash "v7.21.3 install-ros-onekey.sh"

# 使用本地已解压的镜像
bash "v7.21.3 install-ros-onekey.sh" /path/to/chr-7.21.3.img

# 自定义密码
ROS_PASSWORD="你的密码" bash "v7.21.3 install-ros-onekey.sh"
```

详细说明见 [v7.21.3.md](v7.21.3.md)。
