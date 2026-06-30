# 个人编码规范（Trae IDE 版）

本仓库用于**维护一份「我个人通用的编码规范」**，专为 [Trae IDE](https://www.trae.ai/) 的规则（Rule）机制组织。仓库没有应用源码，**唯一产物就是 [`.trae/rules/`](./.trae/rules/) 目录下的规则文件**——它们是给 AI 助手（及人）阅读的编码与协作规范，可被拷贝或链接到其他 Trae 项目中使用。

> 给后续 agent 的提示：本仓库的「任务」不是写应用代码，而是持续打磨 `.trae/rules/` 这套规则文件。对本仓库的改动，几乎都是在编辑它们。根目录的 `CLAUDE.md` 只是本仓库的简短指引，不要与产物混淆。

## 仓库结构

规则文件按 Trae 约定放在 `.trae/rules/`，每个文件用顶部 `---` frontmatter 声明**生效方式**（`alwaysApply` / `globs` / `description` / `scene`），Trae 会按对话内容与所涉文件自动携带相关规则，无需全程加载。

| 文件 | 生效方式 | 内容 |
| --- | --- | --- |
| [`main.md`](./.trae/rules/main.md) | 始终生效（`alwaysApply: true`） | **主索引**：五大领域导览 + 高频遵守的核心原则与关键禁令 |
| [`ai-collaboration.md`](./.trae/rules/ai-collaboration.md) | 始终生效（`alwaysApply: true`） | 与 AI 协作的行为准则（优先级最高），含 Trae 上下文/工具使用约定 |
| [`coding-practices.md`](./.trae/rules/coding-practices.md) | 指定文件生效（`globs`：JS/TS/PY/GO/C++） | 语言版本锁定与语法（推荐/禁止写法）+ 编码实践完整要点（命名、函数与模块、类型与错误、异步、性能、注释、测试、安全） |
| [`project.md`](./.trae/rules/project.md) | 智能生效（`description`） | 项目结构、配置与环境管理、日志与可观测性 |
| [`versioning.md`](./.trae/rules/versioning.md) | 智能生效（`description`） | 提交规范、SemVer、changelog、依赖治理、CI/CD |
| [`git-commit-message.md`](./.trae/rules/git-commit-message.md) | 提交场景生效（`scene: git_message`） | Trae 生成 Git Commit Message 时遵循的规范 |
| [`tech-stack/libraries-js.md`](./.trae/rules/tech-stack/libraries-js.md) | 指定文件生效（`globs`：JS/TS）+ 智能生效（`description`） | JS/TS 分场景库选型表与选型判据 |
| [`tech-stack/libraries-python.md`](./.trae/rules/tech-stack/libraries-python.md) | 指定文件生效（`globs`：PY）+ 智能生效（`description`） | Python 分场景库选型表与选型判据 |
| [`tech-stack/libraries-go.md`](./.trae/rules/tech-stack/libraries-go.md) | 指定文件生效（`globs`：GO）+ 智能生效（`description`） | Go 分场景库选型表与选型判据 |
| [`tech-stack/libraries-cpp.md`](./.trae/rules/tech-stack/libraries-cpp.md) | 指定文件生效（`globs`：C++）+ 智能生效（`description`） | C++ 分场景库选型表与选型判据 |
| [`tech-stack/toolchain.md`](./.trae/rules/tech-stack/toolchain.md) | 智能生效（`description`） | 统一工具链（包管理、Lint、类型检查、测试、构建、pre-commit） |

> Trae 会递归读取 `.trae/rules/` 及其子目录（最多 3 层）。拷贝到其他项目时把整个 `.trae/rules/` 目录一并带上，文件间的相对链接才不会失效。

## 产物结构导览

规范按五个领域组织，每个领域下是若干条目（`### N. xxx`），条目统一为「**核心原则**（一句导语）+ 要点列表」的风格：

| 领域 | 定位（管什么） | 主要内容 | 主要承载文件 |
| --- | --- | --- | --- |
| 一、技术栈与工具基线 | 用什么 | 优先复用开源组件、现代语言版本与语法、统一工具链 | `main.md` + `tech-stack/`（语法明细在 `coding-practices.md` §0） |
| 二、编码实践 | 怎么写 | 命名、函数与模块、类型安全与错误、异步、性能、注释、测试、安全 | `main.md` + `coding-practices.md` |
| 三、项目与工程化 | 项目怎么搭 | 项目结构、配置与环境管理、日志与可观测性 | `main.md` + `project.md` |
| 四、版本与协作 | 怎么协作发布 | 提交规范、SemVer、changelog、依赖治理、CI/CD | `main.md` + `versioning.md` + `git-commit-message.md` |
| 五、与 AI 协作 | AI 如何工作 | 思考在先、简单优先、外科式改动、目标驱动、善用 Trae 上下文与工具、沟通交付、设计文档与规则同步（行为准则，优先级最高） | `ai-collaboration.md` |

> 具体技术栈以 **JavaScript/TypeScript**、**Python**、**Go** 与 **C++** 为准；其他语言沿用各领域中与语言无关的通用原则，并套用对应生态的等价工具。

## 迭代与维护原则

修改 `.trae/rules/` 下的规则时遵循：

- **保持风格一致**：新条目沿用「核心原则 + 要点列表」格式；新增条目按所属领域归类并顺延编号（`### N.`）。
- **正确配置生效方式**：新增规则文件时按其用途选生效方式并写好 frontmatter——通用准则用 `alwaysApply: true`；强绑定文件类型的用 `globs`；按场景触发的用 `description`（智能生效）；提交内容相关用 `scene: git_message`。控制单文件粒度，规则间不冲突。
- **具体而非泛泛**：给出具体的库名、版本号、命令、配置项，而非空泛建议；库一律用 GitHub 链接（标准库用官方文档链接）。
- **增删条目**：跨领域调整时同步更新 `main.md` 顶部领域描述、条目间交叉引用文字（如「见『类型安全与错误处理』」）和指向其他规则文件的相对链接，避免引用失效。
- **核实时效性**：涉及推荐库、语言/工具版本时，定期核实其最新发布时间与维护状态，及时替换停更依赖、校准版本号（文档中标注了「截至 2026-06」的具体版本，落地时以官方最新稳定版为准）。
- **控制篇幅**：单个条目聚焦单一主题；要点避免冗余铺垫与重复举例，保留可执行信息。

## 使用方式

将这份规范应用到其他 Trae 项目：

- **拷贝**：把整个 `.trae/rules/` 目录复制到目标项目根目录（含 `tech-stack/` 子目录）。Trae 会自动识别并按各文件的生效方式加载，无需额外配置。
- **校验生效方式**：在 Trae 的「设置 → 规则」面板可查看/调整各项目规则的应用模式（始终生效 / 指定文件 / 智能生效 / 手动 `#Rule`）。
- **同步**：也可用 git submodule / 软链等方式引入 `.trae/rules/`，便于统一更新。
- **全局复用**：希望某些准则（如「与 AI 协作」）在所有项目生效，可在 Trae「设置 → 规则 → 全局规则」中粘贴对应内容。

应用后按目标项目实际情况裁剪（如只用其中某些领域、调整版本基线）。
