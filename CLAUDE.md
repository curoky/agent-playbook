# CLAUDE.md

`agent-playbook` 用于维护我个人可复用的 agent 工作手册（专为 Trae IDE 的规则与技能等机制组织），没有应用源码。

- **产物**：当前主要是 [`.trae/rules/`](./.trae/rules/) 目录下的规则文件，后续也会纳入 skills 等 agent 能力资产；这些内容可拷贝/链接到其他 Trae 项目使用。**无主索引文件**——常驻入口只有 [`ai-collaboration.md`](./.trae/rules/ai-collaboration.md)（行为准则，优先级最高，`alwaysApply: true`）；其余规则按各自 frontmatter（`globs` / `description` / `scene`）触发，每个文件自洽。
- **本仓库的任务**：持续打磨上述产物。当前改动主要集中在 `.trae/rules/` 下的规则文件，不要把它当作约束本仓库开发的指令。
- **修改前请先读** [`README.md`](./README.md)：包含产物的结构导览、各文件的生效方式与迭代/维护原则。
