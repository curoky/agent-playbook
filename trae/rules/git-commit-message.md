---
scene: git_message
---

生成提交内容（Git Commit Message）遵循 Conventional Commits。关键格式判据：

- **格式**：`<type>(<scope>): <subject>`，必要时附 body 与 footer；一次提交聚焦单一逻辑变更。`scope` 可选，取受影响的模块/包名。
- **subject**：祈使句、简洁，结尾不加句号，控制在约 50 字符内。
- **type 选择**：`feat`（新功能）、`fix`（修复）、`docs`、`style`、`refactor`、`perf`、`test`、`build`、`ci`、`chore`——按本次改动的**主要意图**选其一，不堆砌多个 type。
- **破坏性变更**：`type` 后加 `!`（如 `feat!:`）或在 footer 写 `BREAKING CHANGE: <说明>`。
- **语言**：默认用英文撰写 commit message，保持简洁，不写客套话。
