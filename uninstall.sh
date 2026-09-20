#!/usr/bin/env bash
set -euo pipefail

rm -f "$HOME/.trae/rules"
rm -f "$HOME/.trae-cn/rules"
rm -rf "$HOME/.trae/user_rules"
rm -rf "$HOME/.trae-cn/user_rules"
rm -rf "$HOME/.trae/skills"
rm -rf "$HOME/.trae-cn/skills"
rm -f "${CODEX_HOME:-"$HOME/.codex"}/AGENTS.md"
rm -rf "${CODEX_HOME:-"$HOME/.codex"}/skills/git-commit-message"
rm -rf "${CODEX_HOME:-"$HOME/.codex"}/skills/project-setup"
rm -rf "${CODEX_HOME:-"$HOME/.codex"}/skills/refactor"
rm -rf "${CODEX_HOME:-"$HOME/.codex"}/skills/rewrite-git-history"
