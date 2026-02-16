# 制作已启用 Container 的 CHR 镜像

按以下步骤可得到一块「DD 装好后 WinBox 里直接有 Container、无需再冷重启」的 .img 镜像。

---

## 一、准备环境（二选一）

### 方案 A：本地虚拟机（推荐，便于导出 .img）

- 用 **KVM / VirtualBox / VMware / Hyper-V** 建一台虚拟机。
- 磁盘大小建议 ≥ 1GB，格式随意（后面会导出成 raw .img）。
- 用 **MikroTikPatch 或官方 CHR 镜像** 装进这块磁盘（DD 或挂载镜像安装均可）。

### 方案 B：VPS / 云主机

- 先确认该 VPS 是否支持 **导出磁盘/做快照并下载**（部分厂商支持，部分不支持）。
- 用现有 DD 脚本把 CHR 装到系统盘，后续步骤与方案 A 一致，最后用厂商提供的「导出磁盘」或「自定义镜像导出」得到 .img 或可转换的磁盘文件。

---

## 二、安装 CHR 并首次启动

1. 用你现有的 **v7.21.3install.sh** 或 MikroTikPatch 的 **chr.sh**，把 CHR 装到目标磁盘（虚拟机的一块盘，或 VPS 系统盘）。
2. 启动 CHR，用 **admin** 登录（密码为你脚本里设的或默认空的）。
3. **不要**在 autorun 里写 `/system device-mode update container=yes`（做「模板镜像」时建议用未注入 device-mode 的镜像，或先做本流程再决定是否在模板里加）。

---

## 三、在 CHR 里启用 Container

1. 在 WinBox 或 SSH/Terminal 里执行：
   ```text
   /system device-mode update container=yes
   ```
2. 终端会提示类似：
   ```text
   update: please activate by turning power off or pressing reset or mode button in 5m00s
   ```
3. **在 5 分钟内**做一次 **冷关机**（不能只用 ROS 里的 Reboot）：
   - **虚拟机**：在宿主机上对这台 VM 执行「关机/关闭电源」或「强制关机」，再「开机」。
   - **VPS**：在控制面板里「强制关机/断电」再「开机」（或让运营商执行等价操作）。
4. 再次启动后，打开 WinBox → **Tools**，确认 **Container** 已出现且可用。

---

## 四、导出磁盘为 .img

此时系统盘里的 CHR 已经「开好 Container」，把这块盘导出成单文件 .img 即可。

### 4.1 虚拟机（KVM / VirtualBox / VMware 等）

1. **先关闭 CHR 虚拟机**（正常关机或强制关机均可，保证磁盘不再被写入）。
2. 在**宿主机**上操作：
   - 找到该虚拟机的**系统盘文件**（如 `.qcow2`、`.vdi`、`.vmdk` 等）。
   - 用 `qemu-img` 转成 raw .img（若已是 raw 可跳过）：
     ```bash
     # 例：qcow2 → raw
     qemu-img convert -f qcow2 -O raw chr-disk.qcow2 chr-7.21.3-container.img
     ```
   - 若虚拟机有多块盘，只导出**装 CHR 的那一块**即可。
3. 得到的 **chr-7.21.3-container.img** 即为「已启用 Container」的镜像，可用于后续 DD。

### 4.2 VPS（有导出/快照下载功能）

1. 在控制面板里对当前 CHR 系统盘做 **快照 / 自定义镜像 / 导出磁盘**。
2. 下载得到的文件若是 **raw .img**，可直接用；若是其他格式，用 `qemu-img convert` 转成 raw .img。
3. 将该 .img 上传到你自己的 Releases 或文件服务器，供 DD 脚本使用。

### 4.3 物理机 / 无导出功能的 VPS

1. 用 **Linux Live / Rescue** 从 U 盘或网络启动，不挂载 CHR 所在系统盘为根分区。
2. 确认 CHR 系统盘设备名（如 `/dev/sda`），执行：
   ```bash
   dd if=/dev/sda of=/path/to/chr-7.21.3-container.img bs=4M status=progress
   ```
3. 若磁盘大于你希望分发的镜像大小，可先对 CHR 分区做 resize 再 dd，或 dd 后用 `truncate` 裁掉尾部空白（需注意分区表与文件系统一致性）。一般直接 dd 整盘最简单。

---

## 五、使用做好的镜像

1. 把 **chr-7.21.3-container.img** 放到你的 GitHub Releases（或其它可直链下载的地址）。
2. 在 **v7.21.3install.sh** 里：
   - 将 `IMG_URL` 改为指向该 **container 镜像** 的下载地址。
   - **去掉** autorun 里的 `/system device-mode update container=yes`（镜像里已启用，无需再执行）。
   - 保留网络、密码、SSH/Winbox 等配置。
3. DD 装好后首次启动，WinBox 里 **Tools → Container** 应直接可用，无需再冷关机。

---

## 六、注意事项

- 做模板时建议用 **MikroTikPatch 的 CHR 镜像**，装好后跑一次 **keygen** 再执行 device-mode，这样导出的镜像同时带授权和 Container。
- 导出的 .img 不要在做完 device-mode 冷重启**之前**导出，否则新镜像里 Container 仍是未确认状态。
- 若需 UEFI / Legacy BIOS 各一份，分别在不同引导方式的虚拟机里做一遍「安装 → device-mode → 冷重启 → 导出」即可。

---

## 七、可选：用 npk.py 把包「加入」镜像

[MikroTikPatch](https://github.com/elseif/MikroTikPatch) 提供 **npk.py**，可对 RouterOS 的 **.npk 包**进行：解包、修改、创建、签名和验证。见 [README #npk.py](https://github.com/elseif/MikroTikPatch/tree/main?tab=readme-ov-file#npkpy)。

### 可以「加入进去」的内容

| 加入内容 | 作用 | 说明 |
|----------|------|------|
| **container.npk** | 让镜像自带 Container 包 | 从 [MikroTikPatch Releases](https://github.com/elseif/MikroTikPatch/releases) 的 `all_packages-x86-7.21.3.zip` 里解出 `container-7.21.3.npk`，用 npk.py 验证/签名（若需），在制作镜像时放入 CHR 镜像的包目录，DD 后系统即有 Container 包。**注意**：device-mode 仍须在系统里执行一次并冷重启，或使用「已启用 Container」的模板镜像。 |
| **option-*.npk** | 自动激活授权 + Shell | 镜像里带上 option 包后，首次启动会按 README 流程自动跑 keygen，无需手进 Shell 打 keygen。 |
| **rc.local** | 开机自动执行 shell 脚本 | 在镜像里放好 rc.local，启动时会执行 `/bin/sh rc.local`，可跑自定义 shell 命令（不能直接写 ROS 命令如 device-mode）。 |

### 基本思路（以加入 container 包为例）

1. 克隆 MikroTikPatch 仓库，使用其中的 **npk.py**（及依赖）。
2. 从 Releases 下载 **all_packages-x86-7.21.3.zip**，解压得到 **container-7.21.3.npk** 等。
3. 用 npk.py 对 container.npk 做**验证**（必要时按仓库说明**签名**，以通过 ROS 校验）。
4. 在**制作自定义 CHR 镜像**时：挂载 CHR 的 .img，把处理好的 container.npk 放到 ROS 能识别的包目录（具体路径需根据 CHR 分区与 ROS 7 包布局查阅或实验），然后卸载、导出 .img。
5. 用该 .img DD 后，系统会自带 Container 包；**若要让 WinBox 里直接出现 Container**，仍需在系统内执行 `device-mode update container=yes` 并冷重启，或直接使用「三～五」步做好的已启用 Container 模板镜像。

### 小结

- **npk.py** 适合把 **container、option 等 .npk 包** 提前「加入」镜像，实现预装包、自动 keygen 等。
- **Container 在 WinBox 里可用** 仍依赖 **device-mode 已确认**（冷重启或使用已开好 Container 的 .img）；单靠加入 container.npk 不能省掉 device-mode 确认。
