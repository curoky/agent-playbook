---
alwaysApply: true
---

# 通用编码规范（主文件）

本文件是 AI 助手在本项目中编写代码时应遵循的规范主索引，规范分为五个领域：**技术栈与工具基线**（用什么）、**编码实践**（怎么写）、**项目与工程化**（项目怎么搭）、**版本与协作**（怎么协作发布）、**与 AI 协作**（AI 如何工作）。其中「与 AI 协作」是行为准则、优先级最高，单独放在 [`ai-collaboration.md`](./ai-collaboration.md)（始终生效）。

> 本文件与 [`ai-collaboration.md`](./ai-collaboration.md) 为「始终生效」规则；技术栈、工具链、编码实践、项目工程化、版本协作的明细按场景生效（见各文件 frontmatter），无需全程加载，Trae 会按对话内容与所涉文件自动携带。
>
> 具体技术栈以 **JavaScript/TypeScript**、**Python**、**Go** 与 **C++** 为准；其他语言沿用各领域中与语言无关的通用原则，并套用对应生态的等价工具。

## 一、技术栈与工具基线

### 1. 优先复用成熟的开源组件

**核心原则**：能用成熟、维护良好的开源库解决的问题，就不要自己手写；不为已有优秀库覆盖的能力（路径、日期、参数解析等）重复造轮子，优先用库的高层 API。

- **选型标准**：同时满足现代化（原生 TS 类型、ESM、async/await、类型注解；Go 用泛型与模块）、主流（社区广泛采用、生产验证充分）、积极维护（近期持续发布与响应）三项；不确定就先核实最新发布时间与活跃度。
- **谨慎引入高风险依赖**：对**久未维护**（如一年以上无发布/无提交、issue 长期无人响应）、**star 数偏少**、**过于小众**（生产案例稀少、社区薄弱、文档缺失）的开源组件保持高度谨慎——除非用户手动指定，否则不主动引入；确需引入时先在沟通中说明风险（维护、安全、可替代性）并请用户确认，优先选标准库或更主流的成熟替代品。
- **避免停更/被取代的库**：如新项目不直接用 `moment`、`request`、`lodash`（JS）、`github.com/pkg/errors`（Go，改用标准库 `errors` + `%w`）等。
- **引入判定**：能**大幅简化代码**或 API **明显更好、更不易出错**的（如 `zod`、`typer`、`pydantic`）作为默认选择；与标准库差别不大、仅有性能/便利收益的（如 `orjson`、`picocolors`）按需引入，否则优先标准库。**Go 尤其推崇「标准库优先」**，引入第三方库前先确认标准库（`net/http`、`encoding/json`、`log/slog`、`slices`、`maps` 等）是否已够用。

**分语言的选型明细表与选型判据见** [`tech-stack/libraries-js.md`](./tech-stack/libraries-js.md)、[`tech-stack/libraries-python.md`](./tech-stack/libraries-python.md)、[`tech-stack/libraries-go.md`](./tech-stack/libraries-go.md)、[`tech-stack/libraries-cpp.md`](./tech-stack/libraries-cpp.md)（编辑对应语言源码时自动生效，聊选型时智能携带）。

### 2. 使用现代语言版本与语法

**核心原则**：用当前主流支持的较新版本，优先用最新语法简化代码、提升可读性与类型安全，避免过时或被取代的写法；新语法服务于可读性、不为用而用，不用已 EOL 版本与实验性/非 Stage 4 语法。版本号须在配置中显式锁定以保团队一致。

**版本基线**（「最低」为下限、「推荐」为新项目默认；截至 2026-06，落地按官方最新稳定版校准）：

| 语言 / 项 | 最低版本 | 推荐版本 |
| --- | --- | --- |
| Node.js | 22 LTS | 24 LTS / 最新 26.x |
| TypeScript | 5.9 | 6.0.x（`strict: true`、`target: es2025`、`module: esnext`） |
| Python | 3.12 | 3.14.x |
| Go | 1.25（官方支持最新两个大版本） | 1.26.x |
| C++ 标准 | C++20 | C++23 |
| C++ 编译器 | GCC 12 / Clang 15 / MSVC 19.3x | 最新稳定版（GCC 14+ / Clang 18+） |
| Bazel | 7.x（bzlmod） | 最新（`.bazelversion` 固定） |

各语言的版本锁定方式、推荐语法与禁止写法见 `coding-practices/` 下的分语言文件 [`js.md`](./coding-practices/js.md)、[`python.md`](./coding-practices/python.md)、[`go.md`](./coding-practices/go.md)、[`cpp.md`](./coding-practices/cpp.md) 的「§0 语言版本与语法」（编辑对应源文件时自动生效）。

### 3. 统一工具链

工具链明细（JS/TS、Python、Go 与 C++ 的包管理、Lint、类型检查、测试、构建、pre-commit）见 [`tech-stack/toolchain.md`](./tech-stack/toolchain.md)（搭脚手架、配工具时查阅）。要点：配置文件入库；本地、pre-commit、CI 跑同一套检查；JS 用 `pnpm`+`biome`+`tsc`+`vitest`，Python 用 `uv`+`ruff`+`mypy`/`pyright`+`pytest`，Go 用 `go mod`+`gofmt`/`goimports`+`golangci-lint`+`go vet`+`go test`，C++ 用 `Bazel`(bzlmod)+`clang-format`+`clang-tidy`+`Catch2`。

## 二、编码实践

> 本域各主题的核心原则与语言无关要点见 [`coding-practices/common.md`](./coding-practices/common.md)，各语言特有写法见同目录 [`js.md`](./coding-practices/js.md)/[`python.md`](./coding-practices/python.md)/[`go.md`](./coding-practices/go.md)/[`cpp.md`](./coding-practices/cpp.md)（编辑对应源文件时自动生效）。主文件仅保留每节的核心原则与关键禁令。

- **1. 命名与代码风格**：命名即文档，用完整可检索的名字（布尔加 `is`/`has` 前缀）；遵循语言惯例大小写（Go 用 `MixedCaps`、靠首字母大小写控制导出）；避免魔法值；格式全交给 `biome` / `ruff format` / `gofmt`，不手写、不在 review 讨论。
- **2. 函数与模块设计**：单一职责、小而专一；参数超 3 个改具名对象、避免布尔陷阱参数；核心逻辑写纯函数、副作用推到边界；显式导出最小公共 API（TS 具名导出、Python `__all__`、Go 靠首字母大写控制导出且接口宜小）；依赖抽象而非实现，避免循环依赖。
- **3. 类型安全与错误处理**：用类型让非法状态不可表示，禁 `any`/裸 `Any`/滥用 `interface{}`；外部输入在边界用 `zod`/`pydantic`（Go 用 `go-playground/validator` 或显式校验）校验。错误显式处理，禁裸 `catch (e)`/裸 `except:`/忽略 `error`、禁静默吞错；重抛保留 `cause`/`from e`/`%w`；资源用 `try/finally`/`with`/`using`/`defer` 可靠释放。
- **4. 异步与并发**：JS/Python 全程 `async`/`await`（Python `asyncio`），Go 用 goroutine + channel 并发；独立任务用 `Promise.all`/`asyncio.gather`/`errgroup` 并行；批量并发限流（`p-limit`/`Semaphore`/带缓冲 channel）；不留悬空 Promise/泄漏的 goroutine；长任务支持取消与超时（JS `AbortSignal`、Python `asyncio.timeout`、Go `context.Context`）。
- **5. 性能与优化**：先 profiler/benchmark（Go 用 `go test -bench` + `pprof`）定位再优化，不过早优化；规避 N+1、循环内重复 IO、无索引查询；IO 密集走异步/goroutine、CPU 密集走多进程/worker；缓存须有明确失效策略。
- **6. 注释与文档**：注释写「为什么」而非复述代码；公共 API 写 TSDoc/docstring/Go doc 注释（以标识符名开头）；`TODO`/`FIXME`/`HACK` 附负责人或 issue；改代码同步更新注释、删死代码；禁废话注释。
- **7. 测试规范**：JS 用 `vitest`、Python 用 `pytest`、Go 用标准库 `testing`（表驱动 + `t.Run` 子测试）；遵循 Arrange-Act-Assert，测公共行为而非内部实现；单测隔离确定（mock 外部依赖、注入时钟）；优先覆盖关键路径与边界，不为覆盖率而覆盖；修 bug 先写复现用例。
- **8. 安全编码**：默认不信任外部输入，先校验（`zod`/`pydantic`/`validator`）再按上下文转义；SQL 用参数化/ORM、子进程传参数数组（不 `shell=True`、Go 用 `exec.Command` 传参数切片）禁拼接；最小权限；密码用 `argon2`/`bcrypt`、随机数用 `crypto`/`secrets`/`crypto/rand`（不用 `Math.random`/`random`/`math/rand`）。

## 三、项目与工程化

项目结构、配置与环境管理、日志与可观测性的明细见 [`project.md`](./project.md)（搭项目初期或调整结构/配置/日志时查阅）。要点：按功能分模块、文件职责单一（Go 按包组织、避免 `util` 大杂烩）；配置集中声明并启动即校验（`zod`/`pydantic-settings`/`envconfig`），不散落读裸环境变量；用结构化日志库（`pino`/`loguru`/`log/slog`）、合理分级、不泄漏敏感信息。

## 四、版本与协作

提交规范、语义化版本、变更日志、依赖治理、CI/CD 流水线的明细见 [`versioning.md`](./versioning.md)（做提交、发版、配 CI、治理依赖时查阅）。要点：提交遵循 Conventional Commits；版本遵循 SemVer 并由 commit 自动推导（Go 模块以 `vX.Y.Z` tag 发布，major ≥ 2 需带 `/vN` 路径后缀）；锁文件/校验必须入库（`pnpm-lock.yaml` / `uv.lock` / `go.sum`）；CI 必须跑「格式 → Lint → 类型/vet → 测试 → 构建 → 漏洞扫描」且全绿才合并。

> Trae 生成提交内容（Git Commit Message）时会额外遵循带 `scene: git_message` 的规则，见 [`git-commit-message.md`](./git-commit-message.md)。

## 五、与 AI 协作

AI 助手执行任务时的行为准则（优先级最高）见 [`ai-collaboration.md`](./ai-collaboration.md)（始终生效）。
