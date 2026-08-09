# CLAUDE.md

`agent-playbook` 用于维护个人可复用的 agent 工作手册,专为 [Trae IDE](https://www.trae.ai/) 的规则(Rule)与技能(Skill)机制组织。仓库**没有应用源码**,主要产物是 [`trae/rules/`](./trae/rules/) 与 [`trae/skills/`](./trae/skills/),由 [`install.sh`](./install.sh) 部署到其他 Trae 项目。

> **为什么产物放在 `trae/` 而非 `.trae/`**:Trae 会自动加载工作目录 `.trae/rules/` 下的规则。若把产物直接放本仓库 `.trae/`,维护这些规则时它们会被当作生效规则全量注入,污染本仓库自身的上下文。故产物存于普通目录 `trae/`(无前导点,不被 IDE 自动加载),`install.sh` 再把它们同步到消费项目的 `.trae/`(及 `.trae-cn/`)使其生效。
>
> 给后续 agent:本仓库的任务是**打磨 rules、skills 等工作手册资产,不是写应用代码**。当前改动集中在 `trae/rules/`;本文件只是仓库指引,不要与产物混淆,也不要把它当作约束本仓库开发的指令。

## 仓库结构

规则文件按 Trae 约定放在 `trae/rules/`,顶部 frontmatter 声明生效方式(`alwaysApply` / `globs` / `description` / `scene`)。Trae 按对话内容与所涉文件自动携带相关规则,无需全程加载。**无主索引文件**:每个规则文件自洽(加载后内容完整,不依赖其它文件同时加载),各自靠 frontmatter 在恰好需要时触发。

| 文件 | 生效方式 | 内容 |
| --- | --- | --- |
| [`ai-collaboration.md`](./trae/rules/ai-collaboration.md) | 始终生效(`alwaysApply: true`,唯一常驻) | 与 agent 协作的行为准则(优先级最高):现代技术优先与 freshness gate、思考在先、简单优先、外科式改动、目标驱动,含 Trae 上下文/工具使用约定 |
| [`documentation.md`](./trae/rules/documentation.md) | 指定文件生效(`globs`:Markdown 等文档) | 编写文档的可读性与表达克制规范 |
| [`git-commit-message.md`](./trae/rules/git-commit-message.md) | 提交场景生效(`scene: git_message`) | 生成 Git Commit Message 时遵循的格式规范 |

> Trae 递归读取 `trae/rules/` 及子目录(最多 3 层)。每个文件自洽,拷贝时整目录带上以保引用完整。

**重量级、按场景手动加载的内容放 `refactor` skill,不进常驻 rule**:

- **语言规范** [`trae/skills/refactor/languages/{lang}.md`](./trae/skills/refactor/languages/)(js/ts、python、go、cpp、swift、bash):各语言完整规范,写/改/重构/评审该语言或起步(0→1)选型时加载。单文件自洽,含起步基线(§0,版本/标准/dialect)、「旧惯用法 → 现代惯用法」改写映射、风格/类型/错误/并发/注释测试/安全日志、库选型条件与场景→默认库表、工具链。
- **工程化篇** [`trae/skills/refactor/engineering.md`](./trae/skills/refactor/engineering.md):跨语言工程约定(项目结构、配置与环境、统一工具链、版本基线、提交接线、SemVer、changelog、依赖治理、CI/CD),搭项目、配工具链、发版或治理依赖时加载。

> 这些内容不放常驻 rule 的原因:体量大、多数对话用不上,靠 `globs`/`description` 全程注入会污染上下文;集中到 `refactor` skill 按需加载,写代码时不占 token,较真时手动拉齐全。skill 的 `description` 已把「重构 + 语言 + 搭项目/工程治理」场景词纳入,相关请求会触发挂载。

## 迭代与维护原则

修改 `trae/rules/` 下的规则时遵循:

- **保持风格一致**:规则正文面向 agent,优先保留可执行约束、工具/库名、禁止项和判据;少写解释性铺垫。
- **正确配置生效方式**:通用行为准则用 `alwaysApply: true`(仅 `ai-collaboration.md`);强绑定文件类型用 `globs`;按场景触发用 `description`;提交内容相关用 `scene: git_message`。控制单文件粒度,规则间不冲突。
- **保持各文件自洽、跨文件引用不 load-bearing**:内容归属看「使用时机匹配哪种 frontmatter 触发」——语言特定的写码/重构规范进 `skills/refactor/languages/`、跨语言的搭脚手架/治理约定进 `skills/refactor/engineering.md`(均按需加载,不进常驻 rule),写提交时用的进 `git-commit-message.md`;跨文件引用只作软提示。
- **规则写结论,不写过程**:规则给库名、命令、配置项等**可直接执行的结论**(如「用 `pydantic`」「用 `uv`」);**具体版本号、外部链接、以及「为什么选这个库」的理据**不进规则——前者会过期、后者部署到消费项目用不上,统一沉淀到本文件「维护参考」。规则里表述版本用「官方最新稳定版,落地核实」这类耐久措辞。
- **不放链接**:规则正文不写 Markdown 链接(库名保留反引号即可);权威链接集中在本文件「维护参考」,降低规则注入时的 token 开销。
- **控制篇幅**:单个条目聚焦单一主题;避免冗余铺垫与重复举例,保留可执行信息。

## 维护参考(不随规则部署)

> 本节是维护 `trae/rules/` 时的依据,**不会被 `install.sh` 部署**,也不进规则正文。规则只说「用官方最新稳定版」,具体快照、核实流程与选型理据放这里,避免易腐信息污染部署产物。

### 版本快照(校准至 2026-07;离线兜底,落地以官方最新稳定兼容版为准)

| 语言 / 项 | 新项目默认 | 发布轨道 / 兼容说明 |
| --- | --- | --- |
| Node.js | 24.x Active LTS(生产) | 26.x Current 仅用于明确追新且依赖已兼容的项目;生产遵循 Node 官方 LTS 建议 |
| TypeScript | 7.0.x(`strict: true`、`target: es2025`、`module: esnext`) | 需要 Compiler API 的工具可并装 `@typescript/typescript6`,不无声把项目编译器降回 6.x |
| Python | 3.14.x | 3.15 仍为 pre-release,不默认采用 |
| Go | 1.26.x | `go` 与 `toolchain` 指令锁定 1.26 最新 patch |
| C++ 标准 | C++23 | C++26 正式发布前不作为稳定默认 |
| C++ 编译器 | GCC 16.x / Clang 22.x / 最新稳定 MSVC | 选择目标平台最新稳定工具链并精确锁定 |
| Swift | 6.3.x(Swift 6 language mode) | 平台版本按 Apple / Linux / Windows / Wasm / Android 目标分别声明 |
| Bazel | 9.2.x LTS(bzlmod) | 不默认用 Bazel 10 rolling;`.bazelversion` 固定 patch |
| Bash | 5.3.x | 无法保证现代 Bash runtime 时改用 POSIX `sh` |

### freshness 核实流程(每次新增/修改版本或依赖推荐时)

1. 查官方 release/registry 确认 stable/GA、维护状态、兼容矩阵与安全公告;默认排除 nightly/preview/beta/RC。
2. 排除已归档、明确停维或仅有预发布版的候选。
3. 声明清晰版本范围并提交 lockfile,runtime 与工具链另用机器可读配置锁到具体 patch。
4. 最新稳定版与关键框架/平台不兼容时,记录具体阻塞与官方来源,使用「最新兼容稳定版」,不无声降级。

### 库选型方法论(判断哪些库该进规则的「结论」)

- 选现代、主流、积极维护的库:原生类型/注解、async/await、生产验证充分;不确定时核实发布时间与活跃度。
- 高风险依赖(久未维护、star 少、小众)先评估维护/安全/替代风险。
- 标准库/平台能力够用时不引第三方;能明显减少代码或降低误用概率时才默认引入,体积/依赖复杂度只在多个合格候选间加权。
- 权威链接(库主页/文档)在增删规则条目时查证即可,不写进规则正文。
