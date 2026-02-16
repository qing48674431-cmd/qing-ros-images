# 来源说明

本目录为 [elseif/MikroTikPatch](https://github.com/elseif/MikroTikPatch) 的副本（仅文件内容，非 fork），便于在本仓库内使用 npk.py、chr.sh、patch.py 等工具。

- 上游仓库：<https://github.com/elseif/MikroTikPatch>
- 复制时间：按你执行复制时的日期为准；后续更新请到上游仓库查看或重新复制。

---

## 用 npk.py 做一遍 Container

1. **一键拉取并解出 container.npk**（无需去官方下载）：
   ```bash
   cd MikroTikPatch
   chmod +x prepare_container_npk.sh
   ./prepare_container_npk.sh 7.21.3
   ```
   会从 MikroTikPatch Releases 下载 `all_packages-x86-7.21.3.zip`，解出 `container-7.21.3.npk` 到 `MikroTikPatch/container_npk/`。

2. **可选：验证签名**  
   若已设置环境变量 `CUSTOM_LICENSE_PUBLIC_KEY`、`CUSTOM_NPK_SIGN_PUBLIC_KEY`（上游 CI 用，本地一般无），脚本会自动执行 `python3 npk.py verify`；未设置则跳过，直接使用已签名的 npk。

3. **后续**  
   将 `container_npk/container-*.npk` 放入你制作 CHR 镜像时的包目录，或按《制作已启用Container的CHR镜像.md》第七节把该包加入镜像。要让 WinBox 里出现 Container，仍须在系统内执行 device-mode 并冷重启，或使用已启用 Container 的模板镜像。
