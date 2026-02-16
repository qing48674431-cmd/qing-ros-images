#!/bin/bash
# ============================================================
# 用 npk.py 做一遍 Container：从 MikroTikPatch 拉取并解出 container.npk
# 用法: ./prepare_container_npk.sh [版本号]
# 例:   ./prepare_container_npk.sh 7.21.3
# ============================================================

set -e
VERSION="${1:-7.21.3}"
ARCH="x86"
REPO="elseif/MikroTikPatch"
ZIP="all_packages-${ARCH}-${VERSION}.zip"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${ZIP}"
OUTDIR="$(cd "$(dirname "$0")" && pwd)/container_npk"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "版本: $VERSION"
echo "下载: $URL"
if ! curl -sL -f -o "$TMPDIR/$ZIP" "$URL"; then
    echo "Error: 下载失败。请检查版本号或网络，或到 https://github.com/${REPO}/releases 查看可用版本。"
    exit 1
fi

echo "解压并查找 container 包..."
unzip -q -o "$TMPDIR/$ZIP" -d "$TMPDIR"
CONTAINER_NPK=$(find "$TMPDIR" -maxdepth 1 -name "container-*.npk" -type f | head -n1)
if [ -z "$CONTAINER_NPK" ]; then
    echo "Error: 在 ${ZIP} 中未找到 container-*.npk"
    exit 1
fi

mkdir -p "$OUTDIR"
cp "$CONTAINER_NPK" "$OUTDIR/"
OUTFILE="$OUTDIR/$(basename "$CONTAINER_NPK")"
echo "已提取: $OUTFILE"

# 可选：用 npk.py 验证（需设置 CUSTOM_LICENSE_PUBLIC_KEY、CUSTOM_NPK_SIGN_PUBLIC_KEY）
if [ -n "${CUSTOM_LICENSE_PUBLIC_KEY}" ] && [ -n "${CUSTOM_NPK_SIGN_PUBLIC_KEY}" ]; then
    echo "正在用 npk.py 验证..."
    if (cd "$(dirname "$0")" && python3 npk.py verify "$OUTFILE"); then
        echo "验证通过。"
    else
        echo "Warning: npk.py verify 未通过（可能为未打补丁的官方包或密钥不一致）。"
    fi
else
    echo "跳过 npk.py verify（未设置 CUSTOM_LICENSE_PUBLIC_KEY / CUSTOM_NPK_SIGN_PUBLIC_KEY）。"
    echo "该 container.npk 来自 MikroTikPatch 已签名版本，可直接用于制作镜像。"
fi

echo ""
echo "完成。Container 包路径: $OUTFILE"
