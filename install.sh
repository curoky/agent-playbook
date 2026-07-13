#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

mkdir -p $HOME/.trae/user_rules
mkdir -p $HOME/.trae/skills
rsync -a --delete $SCRIPT_DIR/.trae/rules/ $HOME/.trae/user_rules/
rsync -a --delete $SCRIPT_DIR/.trae/skills/ $HOME/.trae/skills/

rm -rf $HOME/.trae/rules
ln -s -r $HOME/.trae/user_rules $HOME/.trae/rules 
