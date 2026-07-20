#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

mkdir -p $HOME/.trae/user_rules
mkdir -p $HOME/.trae/skills
mkdir -p $HOME/.trae-cn/user_rules
mkdir -p $HOME/.trae-cn/skills

rsync -a --delete $SCRIPT_DIR/.trae/rules/ $HOME/.trae/user_rules/
rsync -a --delete $SCRIPT_DIR/.trae/skills/ $HOME/.trae/skills/
rsync -a --delete $SCRIPT_DIR/.trae/rules/ $HOME/.trae-cn/user_rules/
rsync -a --delete $SCRIPT_DIR/.trae/skills/ $HOME/.trae-cn/skills/

rm -rf $HOME/.trae/rules
rm -rf $HOME/.trae-cn/rules
ln -s -r $HOME/.trae/user_rules $HOME/.trae/rules 
ln -s -r $HOME/.trae-cn/user_rules $HOME/.trae-cn/rules
