---
scene: git_message
---

生成提交内容（Git Commit Message）遵循 [Conventional Commits](https://www.conventionalcommits.org/)。关键格式判据：

- **格式**：`<type>(<scope>): <subject>`，必要时附 body 与 footer；subject 用祈使句、简洁，一次提交聚焦单一逻辑变更。
- **type 选择**：`feat`（新功能）、`fix`（修复）、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`——按本次改动的**主要意图**选其一，不堆砌多个 type。
- **破坏性变更**：`type` 后加 `!`（如 `feat!:`）或在 footer 写 `BREAKING CHANGE: <说明>`。
- **语言**：默认中文描述（与本仓库一致），保持简洁，不写客套话。
