# CLAUDE.md

`agent-playbook` 用于维护个人可复用的 agent 工作手册,专为 [Trae IDE](https://www.trae.ai/) 的规则(Rule)与技能(Skill)机制组织。仓库**没有应用源码**,主要产物是 [`.trae/rules/`](./.trae/rules/)(后续会纳入 skills 等能力资产),可拷贝/链接到其他 Trae 项目。

> 给后续 agent:本仓库的任务是**打磨 rules、skills 等工作手册资产,不是写应用代码**。当前改动集中在 `.trae/rules/`;本文件只是仓库指引,不要与产物混淆,也不要把它当作约束本仓库开发的指令。

## 仓库结构

规则文件按 Trae 约定放在 `.trae/rules/`,顶部 frontmatter 声明生效方式(`alwaysApply` / `globs` / `description` / `scene`)。Trae 按对话内容与所涉文件自动携带相关规则,无需全程加载。**无主索引文件**:每个规则文件自洽(加载后内容完整,不依赖其它文件同时加载),各自靠 frontmatter 在恰好需要时触发。

| 文件 | 生效方式 | 内容 |
| --- | --- | --- |
| [`ai-collaboration.md`](./.trae/rules/ai-collaboration.md) | 始终生效(`alwaysApply: true`,唯一常驻) | 与 agent 协作的行为准则(优先级最高):现代技术优先与 freshness gate、思考在先、简单优先、外科式改动、目标驱动,含 Trae 上下文/工具使用约定 |
| [`languages/{js,python,go,cpp,swift,bash}.md`](./.trae/rules/languages/) | 指定文件生效(`globs`)+ 智能生效(`description`) | 面向 agent 的语言决策清单:基线、风格与模块、类型/错误/资源、并发、注释与测试、安全与日志、库选型、工具链;Bash 另含使用边界与 Shell 安全红线 |
| [`engineering.md`](./.trae/rules/engineering.md) | 智能生效(`description`) | 工程化:项目结构、配置与环境、统一工具链、版本基线、提交接线、SemVer、changelog、依赖治理、CI/CD |
| [`documentation.md`](./.trae/rules/documentation.md) | 指定文件生效(`globs`:Markdown 等文档) | 编写文档的可读性与表达克制规范 |
| [`git-commit-message.md`](./.trae/rules/git-commit-message.md) | 提交场景生效(`scene: git_message`) | 生成 Git Commit Message 时遵循的格式规范 |

> Trae 递归读取 `.trae/rules/` 及子目录(最多 3 层)。每个文件自洽,拷贝时整目录带上以保引用完整。

## 迭代与维护原则

修改 `.trae/rules/` 下的规则时遵循:

- **保持风格一致**:规则正文面向 agent,优先保留可执行约束、版本/工具/库名、禁止项和判据;少写解释性铺垫。
- **正确配置生效方式**:通用行为准则用 `alwaysApply: true`(仅 `ai-collaboration.md`);强绑定文件类型用 `globs`;按场景触发用 `description`;提交内容相关用 `scene: git_message`。控制单文件粒度,规则间不冲突。
- **保持各文件自洽、跨文件引用不 load-bearing**:内容归属看「使用时机匹配哪种 frontmatter 触发」——写代码时用的(语言特定)进 `languages/`,搭脚手架/治理时用的(跨语言)进 `engineering.md`,写提交时用的进 `git-commit-message.md`;跨文件引用只作软提示。
- **具体而非泛泛**:给出库名、版本号、命令、配置项;库用 GitHub 链接,标准库用官方文档链接。
- **核实时效性**:版本快照当前校准至 2026-07;每次新增/修改版本或依赖推荐时查官方 release/registry,确认 stable/GA、维护状态、兼容矩阵与安全公告。快照只作离线兜底,落地以当时官方最新稳定兼容版为准。
- **控制篇幅**:单个条目聚焦单一主题;避免冗余铺垫与重复举例,保留可执行信息。
