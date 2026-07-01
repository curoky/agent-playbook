#!/usr/bin/env bash
# 将本仓库 .trae/rules/ 下的规则文件覆盖安装到 ~/.trae/user_rules/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/.trae/rules"
DEST_DIR="$HOME/.trae/user_rules"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "错误：源目录不存在：$SRC_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

# -a 保留目录结构与属性，--delete 让目标与源保持一致（覆盖并清理多余文件）
rsync -a --delete "$SRC_DIR"/ "$DEST_DIR"/

echo "已将规则安装到：$DEST_DIR"
