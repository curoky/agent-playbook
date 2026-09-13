#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

mkdir -p "$HOME/.trae/user_rules"
mkdir -p "$HOME/.trae/skills"
mkdir -p "$HOME/.trae-cn/user_rules"
mkdir -p "$HOME/.trae-cn/skills"

rsync -a "$SCRIPT_DIR/trae/rules/" "$HOME/.trae/user_rules/"
rsync -a "$SCRIPT_DIR/trae/skills/" "$HOME/.trae/skills/"
rsync -a "$SCRIPT_DIR/trae/rules/" "$HOME/.trae-cn/user_rules/"
rsync -a "$SCRIPT_DIR/trae/skills/" "$HOME/.trae-cn/skills/"

sync_rules_path() {
  local rules_path=$1
  local user_rules_path=$2

  if [[ -L "$rules_path" ]]; then
    return
  fi

  if [[ -d "$rules_path" ]]; then
    rsync -a "$SCRIPT_DIR/trae/rules/" "$rules_path/"
    return
  fi

  if [[ -e "$rules_path" ]]; then
    printf 'warning: %s exists and is not a directory; leaving it unchanged\n' "$rules_path" >&2
    return
  fi

  ln -s "$user_rules_path" "$rules_path"
}

sync_rules_path "$HOME/.trae/rules" "$HOME/.trae/user_rules"
sync_rules_path "$HOME/.trae-cn/rules" "$HOME/.trae-cn/user_rules"
