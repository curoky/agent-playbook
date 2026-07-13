# agent-playbook

`agent-playbook` 用于维护个人可复用的 agent 工作手册，专为 [Trae IDE](https://www.trae.ai/) 的规则（Rule）与技能（Skill）机制组织。仓库没有应用源码，主要产物是 [`.trae/rules/`](./.trae/rules/)；后续也会纳入 skills 等 agent 能力资产。这些内容面向 agent 与人共同阅读，可拷贝或链接到其他 Trae 项目。

> 给后续 agent：本仓库的任务是打磨 rules、skills 等工作手册资产，不是写应用代码。当前改动主要集中在 `.trae/rules/`；根目录的 `CLAUDE.md` 只是仓库指引，不要与产物混淆。

## 仓库结构

规则文件按 Trae 约定放在 `.trae/rules/`，顶部 frontmatter 声明生效方式（`alwaysApply` / `globs` / `description` / `scene`）。Trae 会按对话内容与所涉文件自动携带相关规则，无需全程加载。

| 文件 | 生效方式 | 内容 |
| --- | --- | --- |
| [`main.md`](./.trae/rules/main.md) | 始终生效（`alwaysApply: true`） | **主索引**：五大领域导览 + 高频遵守的核心原则与关键禁令 |
| [`ai-collaboration.md`](./.trae/rules/ai-collaboration.md) | 始终生效（`alwaysApply: true`） | 与 agent 协作的行为准则（优先级最高），含 Trae 上下文/工具使用约定 |
| [`languages/common.md`](./.trae/rules/languages/common.md) | 指定文件生效（`globs`：JS/TS/PY/GO/C++/Shell） | 编码实践各主题的**核心原则与语言无关要点**（命名、函数与模块、类型与错误、异步、性能、注释、测试、安全） |
| [`languages/{js,python,go,cpp,bash}.md`](./.trae/rules/languages/) | 各自指定文件生效（`globs`：对应语言）+ 智能生效（`description`） | 各语言的**编码实践 + 库选型 + 工具链**：版本锁定与语法（§0）、各主题该语言的具体做法、分场景库选型表与选型判据、工具链与 pre-commit（§10） |
| [`project.md`](./.trae/rules/project.md) | 智能生效（`description`） | 项目结构、配置与环境管理、日志与可观测性 |
| [`versioning.md`](./.trae/rules/versioning.md) | 智能生效（`description`） | 提交规范、SemVer、changelog、依赖治理、CI/CD |
| [`git-commit-message.md`](./.trae/rules/git-commit-message.md) | 提交场景生效（`scene: git_message`） | Trae 生成 Git Commit Message 时遵循的规范 |
| [`toolchain.md`](./.trae/rules/toolchain.md) | 智能生效（`description`） | 统一工具链的**跨语言通用约定**（配置/锁文件入库、pre-commit 与 CI 一致性）；各语言具体工具见 `languages/{语言}.md` §10 |

> Trae 会递归读取 `.trae/rules/` 及其子目录（最多 3 层）。拷贝到其他项目时带上整个 `.trae/rules/` 目录，避免相对链接失效。

## 产物结构导览

规范按五个领域组织，条目统一为「**核心原则** + 要点列表」：

- **技术栈与工具基线**：开源组件、现代语言版本与语法、统一工具链。入口为 `main.md` + `toolchain.md`；库选型、语法、工具链明细在 `languages/{语言}.md`。
- **编码实践**：命名、函数与模块、类型安全与错误、异步、性能、注释、测试、安全。入口为 `main.md` + `languages/`。
- **项目与工程化**：项目结构、配置与环境管理、日志与可观测性。入口为 `project.md`。
- **版本与协作**：提交规范、SemVer、changelog、依赖治理、CI/CD。入口为 `versioning.md` + `git-commit-message.md`。
- **与 agent 协作**：思考在先、简单优先、外科式改动、目标驱动、Trae 上下文与工具、沟通交付、设计文档与规则同步。入口为 `ai-collaboration.md`，优先级最高。

具体技术栈以 **JavaScript/TypeScript**、**Python**、**Go** 与 **C++** 为准；其他语言沿用语言无关原则，并套用对应生态的等价工具。

## 迭代与维护原则

修改 `.trae/rules/` 下的规则时遵循：

- **保持风格一致**：新条目沿用「核心原则 + 要点列表」格式，并按所属领域归类编号。
- **正确配置生效方式**：通用准则用 `alwaysApply: true`；强绑定文件类型用 `globs`；按场景触发用 `description`；提交内容相关用 `scene: git_message`。控制单文件粒度，规则间不冲突。
- **具体而非泛泛**：给出库名、版本号、命令、配置项；库用 GitHub 链接，标准库用官方文档链接。
- **增删条目**：跨领域调整时同步更新 `main.md` 顶部领域描述、条目间交叉引用文字（如「见『类型安全与错误处理』」）和指向其他规则文件的相对链接，避免引用失效。
- **核实时效性**：涉及推荐库、语言/工具版本时，定期核实维护状态并校准版本号（文档中标注「截至 2026-06」的内容，落地时以官方最新稳定版为准）。
- **控制篇幅**：单个条目聚焦单一主题；要点避免冗余铺垫与重复举例，保留可执行信息。

## 使用方式

将 `agent-playbook` 应用到其他 Trae 项目：

- **拷贝**：把整个 `.trae/rules/` 目录复制到目标项目根目录（含 `languages/` 子目录）。Trae 会自动识别并按各文件的生效方式加载，无需额外配置。
- **校验生效方式**：在 Trae 的「设置 → 规则」面板可查看/调整各项目规则的应用模式（始终生效 / 指定文件 / 智能生效 / 手动 `#Rule`）。
- **同步**：也可用 git submodule / 软链等方式引入 `.trae/rules/`，便于统一更新。
- **全局复用**：希望某些准则（如「与 agent 协作」）在所有项目生效，可在 Trae「设置 → 规则 → 全局规则」中粘贴对应内容。

应用后按目标项目实际情况裁剪（如只用其中某些领域、调整版本基线）。
