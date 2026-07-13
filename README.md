# agent-playbook

`agent-playbook` 用于维护个人可复用的 agent 工作手册，专为 [Trae IDE](https://www.trae.ai/) 的规则（Rule）与技能（Skill）机制组织。仓库没有应用源码，主要产物是 [`.trae/rules/`](./.trae/rules/)；后续也会纳入 skills 等 agent 能力资产。这些内容面向 agent 与人共同阅读，可拷贝或链接到其他 Trae 项目。

> 给后续 agent：本仓库的任务是打磨 rules、skills 等工作手册资产，不是写应用代码。当前改动主要集中在 `.trae/rules/`；根目录的 `CLAUDE.md` 只是仓库指引，不要与产物混淆。

## 仓库结构

规则文件按 Trae 约定放在 `.trae/rules/`，顶部 frontmatter 声明生效方式（`alwaysApply` / `globs` / `description` / `scene`）。Trae 会按对话内容与所涉文件自动携带相关规则，无需全程加载。**无主索引文件**：每个规则文件自洽（加载后内容完整，不依赖其它文件同时加载），各自靠 frontmatter 在恰好需要时触发。

| 文件 | 生效方式 | 内容 |
| --- | --- | --- |
| [`ai-collaboration.md`](./.trae/rules/ai-collaboration.md) | 始终生效（`alwaysApply: true`，唯一常驻） | 与 agent 协作的行为准则（优先级最高），含 Trae 上下文/工具使用约定 |
| [`languages/{js,python,go,cpp,bash}.md`](./.trae/rules/languages/) | 各自指定文件生效（`globs`：对应语言）+ 智能生效（`description`） | 各语言的**编码实践 + 日志 + 库选型 + 工具链**：版本锁定与语法（§0）、各主题该语言的具体做法与跨语言判据（§1–8）、日志（§9，bash 为 §9）、分场景库选型表与选型判据（§10，bash 无）、工具链与 pre-commit（§11，bash 为 §10） |
| [`engineering.md`](./.trae/rules/engineering.md) | 智能生效（`description`） | 工程化 9 节：项目结构、配置与环境、统一工具链（跨语言约束 + 对照表）、语言与工具版本基线、提交接线、SemVer、changelog、依赖治理、CI/CD |
| [`documentation.md`](./.trae/rules/documentation.md) | 指定文件生效（`globs`：Markdown 等文档） | 编写文档的可读性与表达克制规范 |
| [`git-commit-message.md`](./.trae/rules/git-commit-message.md) | 提交场景生效（`scene: git_message`） | Trae 生成 Git Commit Message 时遵循的完整格式规范 |

> Trae 会递归读取 `.trae/rules/` 及其子目录（最多 3 层）。因每个文件自洽，拷贝时缺失个别文件也不致内容残缺；建议整目录带上以保引用（软提示）完整。

## 产物结构导览

规范按五个领域组织（供人阅读的地图；**文件不与领域一一对应**，同一领域可能分布在多个自洽文件中），条目统一为「**核心原则** + 要点列表」：

- **技术栈与工具基线**：开源组件选型、现代语言版本与语法、统一工具链。语法/版本锁定见 `languages/{语言}.md` §0，版本基线总表与跨语言工具链约定见 `engineering.md`，库选型见 `languages/{语言}.md` §10。
- **编码实践**：命名、函数与模块、类型安全与错误、异步、性能、注释、测试、安全、日志。入口为 `languages/{语言}.md` §1–9。
- **项目与工程化**：项目结构、配置与环境管理。入口为 `engineering.md`。
- **版本与协作**：提交（格式见 `git-commit-message.md`、接线见 `engineering.md`）、SemVer、changelog、依赖治理、CI/CD。入口为 `engineering.md`。
- **与 agent 协作**：思考在先、简单优先、外科式改动、目标驱动、Trae 上下文与工具、沟通交付、设计文档与规则同步。入口为 `ai-collaboration.md`，优先级最高。

具体技术栈以 **JavaScript/TypeScript**、**Python**、**Go** 与 **C++** 为准；其他语言沿用语言无关原则，并套用对应生态的等价工具。

## 迭代与维护原则

修改 `.trae/rules/` 下的规则时遵循：

- **保持风格一致**：新条目沿用「核心原则 + 要点列表」格式，并按所属主题归入对应文件。
- **正确配置生效方式**：通用行为准则用 `alwaysApply: true`（仅 `ai-collaboration.md`）；强绑定文件类型用 `globs`；按场景触发用 `description`；提交内容相关用 `scene: git_message`。控制单文件粒度，规则间不冲突。
- **保持各文件自洽、跨文件引用不 load-bearing**：内容归属看「使用时机匹配哪种 frontmatter 触发」——写代码时用的（语言特定）进 `languages/`，搭脚手架/治理时用的（跨语言）进 `engineering.md`，写提交时用的进 `git-commit-message.md`；跨文件引用只作软提示，不让某文件依赖另一文件被同时加载。
- **具体而非泛泛**：给出库名、版本号、命令、配置项；库用 GitHub 链接，标准库用官方文档链接。
- **核实时效性**：涉及推荐库、语言/工具版本时，定期核实维护状态并校准版本号（文档中标注「截至 2026-06」的内容，落地时以官方最新稳定版为准）。
- **控制篇幅**：单个条目聚焦单一主题；要点避免冗余铺垫与重复举例，保留可执行信息。

## 使用方式

将 `agent-playbook` 应用到其他 Trae 项目：

- **拷贝**：把整个 `.trae/rules/` 目录复制到目标项目根目录（含 `languages/` 子目录）。Trae 会自动识别并按各文件的生效方式加载，无需额外配置。
- **校验生效方式**：在 Trae 的「设置 → 规则」面板可查看/调整各项目规则的应用模式（始终生效 / 指定文件 / 智能生效 / 手动 `#Rule`）。
- **同步**：也可用 git submodule / 软链等方式引入 `.trae/rules/`，便于统一更新。
- **全局复用**：希望某些准则（如「与 agent 协作」）在所有项目生效，可在 Trae「设置 → 规则 → 全局规则」中粘贴对应内容。

应用后按目标项目实际情况裁剪（如只用其中某些领域、调整版本基线）。
