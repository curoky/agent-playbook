---
scene: git_message
---

# Git 提交内容规范

生成提交内容（Git Commit Message）时遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

- 格式：`<type>(<scope>): <subject>`，必要时附 body 与 footer。
- 常用 `type`：`feat`（新功能，minor）、`fix`（修复，patch）、`docs`/`style`/`refactor`/`perf`/`test`/`build`/`ci`/`chore`。
- **破坏性变更**：`type` 后加 `!`（如 `feat!:`）或 footer 写 `BREAKING CHANGE:`，触发 major。
- `subject` 用祈使句、简洁，聚焦「为什么」而非逐条罗列「改了什么」；一次提交聚焦单一逻辑变更。
- 用中文撰写正文（与项目沟通语言一致）；type/scope 等关键字保持英文。

> 完整的版本与协作规范（SemVer、changelog、依赖治理、CI/CD）见 [`versioning.md`](./versioning.md)。
