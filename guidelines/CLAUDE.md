# CLAUDE.md

本文件用于指导 AI 助手在本仓库中编写代码时应遵循的规范。规范分为五个领域：**技术栈与工具基线**（用什么）、**编码实践**（怎么写）、**项目与工程化**（项目怎么搭）、**版本与协作**（怎么协作发布）、**与 AI 协作**（AI 如何工作）。其中「与 AI 协作」是 AI 助手执行任务时的行为准则，优先级最高。

## 一、技术栈与工具基线

### 1. 优先复用成熟的开源组件

**核心原则**：能用成熟、维护良好的开源库解决的问题，就不要自己手写。

**选型标准**：引入的第三方库必须同时满足以下条件——

- **现代化**：基于当下主流的语言特性与生态设计（如原生 TS 类型、ESM、async/await、类型注解），而非依赖过时架构。
- **主流**：被社区广泛采用（下载量大、Star 多、生产环境验证充分），生态与文档成熟。
- **积极维护**：近期有持续的版本发布与 Issue/PR 响应，依赖与安全更新及时。

**适用要求**：

- 引入第三方库前，优先选择同时满足上述三项标准的方案；若不确定，先核实其最新发布时间与维护活跃度。
- 不要为已有优秀库覆盖的能力（路径处理、日期处理、参数解析、错误处理等）重复造轮子。
- 优先使用库提供的高层 API，避免手写易错的底层逻辑（如手动拼接路径、手动解析日期）。
- 避免引入已停止维护（deprecated / 长期无更新）或被社区公认已被取代的库（如新项目避免直接用 `moment`、`request`、`lodash` 等）。

**引入判定**：是否引入某个库，依据下表「引入要求」列判断——

- **必须引入**：相比系统库/手写能**大幅简化代码**，或其 API 设计**明显更好、更易理解、更不易出错**（如 `zod`、`typer`、`pydantic`）。这类库应作为默认选择。
- **按需引入**：接口与系统库差别不大，主要收益是**性能或便利**（如 `orjson`、`picocolors`）。仅在确有需求（如性能瓶颈、特定场景）时才引入，否则优先用标准库，避免不必要的依赖。

#### JavaScript / TypeScript

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| 路径操作 | [`pathe`](https://github.com/unjs/pathe) | 必须 | 跨平台一致，避免 Windows/POSIX 分隔符差异。 |
| 错误处理 | [`neverthrow`](https://github.com/supermacro/neverthrow) | 必须 | 用 `Result` 类型显式处理错误，避免隐式异常控制流。 |
| 日期 / 时间 | [`Temporal`](https://github.com/tc39/proposal-temporal) | 必须 | 替代易错的原生 `Date`。 |
| 运行时类型校验 / Schema | [`zod`](https://github.com/colinhacks/zod) | 必须 | 校验外部输入（API、表单、配置），并推导 TS 类型。 |
| HTTP 请求 | [`ofetch`](https://github.com/unjs/ofetch) | 按需 | `fetch` 增强：自动解析、错误处理、重试。 |
| 命令行接口 | [`commander`](https://github.com/tj/commander.js) / [`citty`](https://github.com/unjs/citty) | 必须 | 通用选 `commander`，unjs/极简选 `citty`。 |
| 环境变量 | [`dotenv`](https://github.com/motdotla/dotenv) | 按需 | 从 `.env` 加载，配合 `zod` 校验。 |
| 工具函数 | [`es-toolkit`](https://github.com/toss/es-toolkit) | 按需 | 替代 lodash，体积更小、原生 TS。 |
| 测试 | [`vitest`](https://github.com/vitest-dev/vitest) | 必须 | 原生支持 ESM/TS。 |
| 日志 | [`pino`](https://github.com/pinojs/pino) | 按需 | 结构化 JSON 日志。 |
| 唯一 ID | [`nanoid`](https://github.com/ai/nanoid) | 按需 | 简单场景可直接用 `crypto.randomUUID()`。 |
| 数据库 / ORM | [`drizzle-orm`](https://github.com/drizzle-team/drizzle-orm) | 必须 | TS 原生、类型安全。 |
| 文件 glob 匹配 | [`tinyglobby`](https://github.com/SuperchupuDev/tinyglobby) | 按需 | 比 `glob`/`fast-glob` 更轻。 |
| Lint / 格式化 | [`biome`](https://github.com/biomejs/biome) | 必须 | 一体化；需丰富插件规则时改用 `eslint`(flat config) + `prettier`。 |
| 子进程 / 命令执行 | [`execa`](https://github.com/sindresorhus/execa) | 按需 | 替代原生 `child_process`。 |
| 终端美化 / Spinner | [`picocolors`](https://github.com/alexeyraspopov/picocolors) / [`ora`](https://github.com/sindresorhus/ora) | 按需 | 着色用 `picocolors`，加载动画用 `ora`。 |
| 异步并发控制 | [`p-limit`](https://github.com/sindresorhus/p-limit) | 按需 | 限制 Promise 并发数。 |

#### Python

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| 路径操作 | [`pathlib`](https://docs.python.org/3/library/pathlib.html) | 必须 | 用 `Path`，不用 `os.path` 字符串拼接。 |
| 命令行接口 | [`typer`](https://github.com/fastapi/typer) | 必须 | 基于类型注解，替代 `argparse`。 |
| 数据校验 / 模型 | [`pydantic`](https://github.com/pydantic/pydantic) | 必须 | 基于类型注解做校验与序列化。 |
| 配置管理 | [`pydantic-settings`](https://github.com/pydantic/pydantic-settings) | 必须 | 从环境变量 / `.env` 加载并校验。 |
| HTTP 请求 | [`httpx`](https://github.com/encode/httpx) | 必须 | 同步/异步统一，替代 `requests` + `aiohttp`。 |
| 日期 / 时间 | [`pendulum`](https://github.com/python-pendulum/pendulum) | 按需 | 时区友好；简单场景用 `datetime` + `zoneinfo`。 |
| 终端输出 / 富文本 | [`rich`](https://github.com/Textualize/rich) | 按需 | 表格、进度条、彩色输出。 |
| 日志 | [`loguru`](https://github.com/Delgan/loguru) | 按需 | 替代繁琐的 `logging` 配置。 |
| 测试 | [`pytest`](https://github.com/pytest-dev/pytest) | 必须 | 配合 fixture 与参数化。 |
| 重试 | [`tenacity`](https://github.com/jd/tenacity) | 必须 | 声明式重试（退避、超时、条件）。 |
| Web / API 框架 | [`fastapi`](https://github.com/fastapi/fastapi) | 必须 | 基于类型注解与 `pydantic`，异步。 |
| 包 / 环境管理 | [`uv`](https://github.com/astral-sh/uv) | 必须 | 替代 `pip` + `venv`。 |
| 代码格式化 / Lint | [`ruff`](https://github.com/astral-sh/ruff) | 必须 | 替代 `flake8` + `black` + `isort`。 |
| 数据库 / ORM | [`sqlalchemy`](https://github.com/sqlalchemy/sqlalchemy) / [`sqlmodel`](https://github.com/fastapi/sqlmodel) | 必须 | 复杂查询/生产用 `sqlalchemy` 2.0；配 FastAPI、需类型安全模型用 `sqlmodel`。 |
| 静态类型检查 | [`mypy`](https://github.com/python/mypy) / [`pyright`](https://github.com/microsoft/pyright) | 必须 | 基于类型注解做静态检查。 |
| 数据处理 / DataFrame | [`polars`](https://github.com/pola-rs/polars) | 按需 | 性能优先用 `polars`；需兼容既有 `pandas` 生态用 `pandas`。 |
| 任务队列 / 后台任务 | [`celery`](https://github.com/celery/celery) / [`arq`](https://github.com/python-arq/arq) | 必须 | `arq` 为轻量 asyncio 方案。 |
| 子进程 / 命令执行 | 标准库 [`subprocess`](https://docs.python.org/3/library/subprocess.html) | 标准库 | 用 `subprocess.run`；避免 `sh` 等不支持 Windows 的库。 |
| 序列化 / 高性能 JSON | [`orjson`](https://github.com/ijl/orjson) | 按需 | 仅性能敏感时引入，否则用标准库 `json`。 |

> 注：以上均为截至当前现代化、主流、积极维护的推荐默认选项。若项目已有等价的成熟方案，沿用现有方案即可，保持技术栈一致性优先；随时间推移请定期复核各库的维护状态，及时替换已停更的依赖。

### 2. 使用现代语言版本与语法

**核心原则**：每种语言都应使用当前主流支持的较新版本，并尽可能采用最新的语法特性来简化代码、提升可读性与类型安全，避免使用已过时或被取代的写法。

**通用要求**：

- 下表的「最低版本」为允许的下限基线，「推荐版本」为新项目默认采用的目标版本；不使用已 EOL（停止维护）的版本。
- 优先使用最新语法糖与标准库能力来简化代码，而非沿用冗长的老式写法。
- **新语法服务于可读性，不为用而用**：当新写法反而让语义更难理解时（如深度嵌套的 `:=`、把简单分支硬写成 `match`、过度的 TS 类型体操），优先选直观写法；实验性/未定稿（非 Stage 4）的语法不用于生产代码。
- 升级版本时同步关注其废弃（deprecated）特性，及时迁移。
- 版本号会随时间演进，以下为截至 2026-06 的具体版本，落地时请按官方最新稳定版校准。

#### JavaScript / TypeScript

| 项 | 最低版本 | 推荐版本 |
| --- | --- | --- |
| Node.js | 22 LTS（Node 20 已于 2026-04 EOL） | 24 LTS（新项目）/ 最新 Current 26.x |
| TypeScript | 5.9 | 6.0.x（新默认 `strict: true`、`target: es2025`、`module: esnext`） |
| ECMAScript 目标 | ES2022 | ES2025 |

- **一律使用 TypeScript**，不写裸 JavaScript；新文件使用 `.ts` / `.tsx`。
- `tsconfig.json` 中必须启用 `strict: true`（建议再开 `noUncheckedIndexedAccess`）；模块系统统一用 **ESM**（`import`/`export`），不用 CommonJS。
- **版本声明（必须显式锁定）**：`package.json` 设置 `"engines": { "node": ">=22" }` 与 `"type": "module"`；用 `.nvmrc` / Volta 固定本地 Node 版本，确保团队一致。
- 优先采用现代语法简化代码，例如：
  - 可选链 `?.` 与空值合并 `??`，替代层层 `&&` 判空。
  - 解构、展开运算符 `...`、模板字符串，替代手动拼接。
  - `async`/`await` 替代回调与裸 `Promise.then` 链。
  - 顶层 `await`、`Array` 新方法（`at`、`findLast`、`toSorted` 等）、逻辑赋值运算符（`??=`、`||=`）。
- **禁止**：`var`（用 `const`/`let`）、`==`/`!=`（用 `===`/`!==`）、`any`（用 `unknown` 或具体类型）、`namespace`（用 ESM 模块）、CommonJS `require`/`module.exports`、`enum`（优先 `as const` 联合类型）。

#### Python

| 项 | 最低版本 | 推荐版本 |
| --- | --- | --- |
| Python | 3.12（3.9–3.11 均已停止常规支持/接近 EOL） | 3.14.x（最新稳定版，新项目默认） |

- 不使用已 EOL 的旧版本；新项目默认采用最新稳定的 3.14.x。
- **全量使用类型注解**，配合 `mypy` / `pyright` 做静态检查。
- **版本声明（必须显式锁定）**：`pyproject.toml` 设置 `requires-python = ">=3.12"`；用 `uv` 管理并锁定（`.python-version` + `uv.lock`），确保团队一致。
- 优先采用现代语法简化代码，例如：
  - 结构化模式匹配 `match`/`case`，替代冗长的 `if/elif` 链。
  - 内置泛型与新式类型语法（`list[int]`、`X | None`、`type` 别名语句），替代 `typing.List`、`Optional`。
  - f-string（含 `f"{x=}"` 调试写法），替代 `%` 与 `.format()`。
  - `dataclasses` / `pydantic` 模型，替代手写 `__init__` 样板。
  - 海象运算符 `:=`、`pathlib`、上下文管理器 `with`、推导式等惯用法。
- **禁止**：`from x import *`、可变默认参数（`def f(a=[])`，改用 `None` 哨兵）、裸 `except:`（捕获具体异常）、`typing.List`/`Dict`/`Optional` 等旧式泛型（用内置 `list`/`dict`/`X | None`）、用 `os.path` 拼路径（用 `pathlib`）。

### 3. 统一工具链

**核心原则**：每种语言使用统一、现代、高性能的工具链，覆盖包管理、格式化、Lint、类型检查与测试；工具配置纳入版本控制，本地与 CI 使用一致的命令与版本，保证结果可复现。

**通用要求**：

- 工具配置文件（如 `package.json`、`pyproject.toml`、`tsconfig.json`、`biome.json`）必须提交到仓库；不依赖个人本地环境。
- 关键检查（格式化、Lint、类型检查、测试）应可一键运行，并在 CI 与提交前（pre-commit）强制执行。
- 优先选择**速度快、配置少、能合并多职责**的工具，减少工具碎片化。

#### JavaScript / TypeScript

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包管理 | [`pnpm`](https://github.com/pnpm/pnpm) | 原生支持 workspace；提交 `pnpm-lock.yaml`。 |
| Lint + 格式化 | [`biome`](https://github.com/biomejs/biome) | 一体化；需丰富插件时退回 `eslint` + `prettier`。 |
| 类型检查 | `tsc --noEmit` | `strict: true`。 |
| 测试 | [`vitest`](https://github.com/vitest-dev/vitest) | 统一单测与覆盖率。 |
| 构建 / 打包 | [`tsup`](https://github.com/egoist/tsup) / [`tsdown`](https://github.com/rolldown/tsdown) | 库用零配置打包；应用按框架自带构建（Vite 等）。 |
| 直接运行 TS | [`tsx`](https://github.com/privatenumber/tsx) | 免编译执行 `.ts`。 |

#### Python

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包 / 环境 / 版本管理 | [`uv`](https://github.com/astral-sh/uv) | 管理依赖、虚拟环境与 Python 版本；提交 `uv.lock`。 |
| Lint + 格式化 | [`ruff`](https://github.com/astral-sh/ruff) | `ruff check` + `ruff format`，替代 `flake8` + `black` + `isort`。 |
| 类型检查 | [`mypy`](https://github.com/python/mypy) / [`pyright`](https://github.com/microsoft/pyright) | 开启 strict。 |
| 测试 | [`pytest`](https://github.com/pytest-dev/pytest) | 配合 `pytest-cov` 覆盖率。 |

#### 提交前检查（pre-commit）

- JS/TS：用 [`husky`](https://github.com/typicode/husky) + [`lint-staged`](https://github.com/lint-staged/lint-staged) 在提交前对暂存文件跑 `biome` 与 `tsc`。
- Python：用 [`pre-commit`](https://github.com/pre-commit/pre-commit) 框架挂载 `ruff`、`mypy` 等钩子。
- CI 中重复执行同一套检查（格式化校验、Lint、类型检查、测试），确保与本地一致。

## 二、编码实践

### 1. 命名与代码风格

**核心原则**：命名即文档；风格统一交给工具（`biome` / `ruff`）强制，人只关注命名与表达意图。

- **命名表意**：用完整、可检索的名字，避免缩写与单字母（循环计数器等惯例除外）；布尔值用 `is`/`has`/`should` 前缀；函数名用动词短语，变量/类用名词短语。
- **遵循语言惯例**：
  - JS/TS：变量/函数 `camelCase`、类型/类 `PascalCase`、常量 `UPPER_SNAKE_CASE`、文件名 `kebab-case`。
  - Python：变量/函数/模块 `snake_case`、类 `PascalCase`、常量 `UPPER_SNAKE_CASE`，遵循 PEP 8。
- **避免魔法值**：字面量数字/字符串提取为有名常量或枚举（TS `as const` 联合，Python `Enum`）。
- **格式不靠手写**：缩进、引号、分号、import 排序等全部交给 `biome` / `ruff format` 自动处理，不在 review 中讨论格式问题。

### 2. 函数与模块设计

**核心原则**：小而专一、低耦合高内聚；依赖于抽象而非实现，便于测试与复用。

- **单一职责**：一个函数只做一件事；函数过长或有多个「阶段性注释」时，拆分为更小的具名函数。
- **参数精简**：参数超过 3 个时改用对象/具名参数（TS options 对象，Python 关键字参数 + `dataclass`/`pydantic`）；避免布尔陷阱参数（用枚举或拆分函数）。
- **优先纯函数**：核心逻辑写成无副作用的纯函数，把 I/O、随机、时间等副作用推到边界。
- **明确公共 API**：模块通过显式导出暴露最小必要接口；TS 用具名导出（避免 default export），Python 用 `__all__` 或下划线前缀标记私有。
- **依赖倒置**：高层逻辑依赖接口/协议（TS `interface`，Python `Protocol`/ABC），由外部注入实现，避免在深处直接 `new` 具体依赖。
- **避免循环依赖**：模块依赖保持单向、分层清晰；出现循环引用时通过提取公共模块或反转依赖解决。

### 3. 类型安全与错误处理

**核心原则**：用类型表达约束、让非法状态不可表示；错误必须显式、就近、可追溯地处理，禁止静默吞掉。

**类型安全**：

- **不使用逃逸类型**：TS 禁止 `any`（用 `unknown` + 收窄）；Python 禁止裸 `Any`（用具体类型、`Protocol` 或泛型），仅在边界且无法静态描述时局部使用并加注释说明。
- **在边界校验外部输入**：API 响应、用户输入、配置、环境变量等不可信数据，必须在进入系统时用 Schema 校验（TS 用 `zod`，Python 用 `pydantic`），之后内部代码可信任其类型。
- **让非法状态不可表示**：优先用联合类型/可辨识联合（TS discriminated union、Python `Literal` + `match`）建模互斥状态，避免「多个布尔标志组合出非法态」。
- **避免 `null`/`undefined` 蔓延**：用可选链与空值合并就近处理；对「可能不存在」的返回值用显式类型标注（`T | undefined` / `T | None`），不靠隐式约定。

**错误处理**：

- **可预期错误用值表达**：业务上可预期的失败（找不到、校验失败、外部调用失败）优先用返回值表达——TS 用 `neverthrow` 的 `Result`，Python 优先返回显式结果或抛出**自定义领域异常**，而非裸 `Error`/`Exception`。
- **异常用于不可恢复错误**：`throw`/`raise` 仅用于真正异常、不可预期的情况；捕获时必须捕获**具体异常类型**，禁止裸 `catch (e)` 不处理、禁止 Python 裸 `except:`。
- **不静默吞错**：捕获后必须做有意义的处理（恢复、转换、上报、带上下文重抛），禁止空 catch、禁止只 `console.log` 后继续。
- **保留上下文**：重新抛出时携带原始错误（TS `new Error(msg, { cause })`，Python `raise X from e`），不丢失堆栈与根因。
- **资源清理可靠**：用 `try/finally`、`with`（Python）、`using`（TS 5.2+ `await using`）确保文件/连接/锁等资源释放，不依赖手动调用。

### 4. 异步与并发

**核心原则**：异步代码必须显式管理生命周期与错误；不阻塞、不泄漏、不丢异常。

- **统一异步模型**：JS/TS 全程 `async`/`await`，不混用裸 `.then` 链与回调；Python 用 `asyncio`，不在异步代码中调用阻塞 I/O。
- **并发要并行**：相互独立的异步任务用 `Promise.all`/`Promise.allSettled`（JS）、`asyncio.gather`（Python）并发执行，不要串行 `await`。
- **限制并发度**：批量并发时限制上限——JS 用 `p-limit`，Python 用 `asyncio.Semaphore`，避免压垮下游或耗尽连接/句柄。
- **不吞异步异常**：每个 Promise/Task 的拒绝都必须被处理；禁止「发射后不管」的悬空 Promise（需要后台执行时显式管理并捕获错误）。
- **支持取消与超时**：长任务支持取消与超时——JS 用 `AbortController`/`AbortSignal`，Python 用 `asyncio.timeout`/取消，避免无限等待。
- **保护共享状态**：并发访问共享可变状态时用锁/队列/不可变数据，避免竞态；优先用消息传递而非共享内存。

### 5. 性能与优化

**核心原则**：先用 profiler / benchmark 定位真实瓶颈再优化，不靠直觉做过早优化。

- **基准可复现**：关键算法/接口写 benchmark（JS `vitest bench`，Python `pytest-benchmark`），优化前后对比并纳入回归。
- **避免常见浪费**：N+1 查询、循环内重复计算/IO、不必要的深拷贝、未加索引的查询；批量与缓存优先于逐条处理。
- **按瓶颈选并发模型**：IO 密集用异步并发（见本域「异步与并发」），CPU 密集用 worker / 多进程，不阻塞事件循环 / 主线程。
- **缓存有度**：缓存须明确失效策略与一致性边界，避免难调试的陈旧数据。

### 6. 注释与文档

**核心原则**：注释解释「为什么」，而非「做了什么」；代码本身说明「做了什么」。

- **写 why 不写 what**：解释意图、权衡、坑与非显而易见的约束；不要复述代码字面逻辑。
- **公共 API 必须有文档**：导出的函数/类/模块写文档注释——TS 用 TSDoc（`@param`/`@returns`/`@throws`），Python 用 docstring（约定如 Google/NumPy 风格，配合类型注解，不在 docstring 里重复类型）。
- **标注临时与风险**：用统一标记 `TODO`/`FIXME`/`HACK` 并附负责人或 issue 链接；对已知坑、绕过方案写明原因。
- **注释与代码同步**：修改代码必须同步更新相关注释/文档，过时注释比没有注释更有害；删除被注释掉的「死代码」（依赖版本控制找回）。
- **不写废话注释**：禁止 `i++ // 自增` 这类复述型注释。

### 7. 测试规范

**核心原则**：测试是行为契约；测公共行为而非内部实现，保证可重构、可信任。

- **框架统一**：JS/TS 用 `vitest`，Python 用 `pytest`（见「技术栈与工具基线 · 统一工具链」）。
- **结构清晰**：遵循 Arrange-Act-Assert（准备-执行-断言）；用例名描述「在什么条件下、期望什么行为」。
- **测行为非实现**：针对公共接口与可观察行为断言，避免断言私有细节，减少重构时的脆性。
- **隔离与确定性**：单测不依赖网络/真实 DB/时钟/全局状态；外部依赖用 mock/stub/fake，时间用可注入的时钟，保证可重复、可并行。
- **覆盖关键路径**：优先覆盖核心逻辑、分支与边界条件（空、极值、错误路径），不盲目追求 100% 覆盖率；覆盖率作为参考而非目标。
- **回归即用例**：修复 bug 时先写一个能复现该 bug 的失败用例，再修复使其通过。

### 8. 安全编码

**核心原则**：默认不信任一切外部输入；最小权限、纵深防御。

- **校验并转义输入**：所有外部输入先校验（`zod`/`pydantic`）再使用；按输出上下文转义（HTML/SQL/Shell/URL），防注入。
- **杜绝注入**：SQL 用参数化查询或 ORM（`drizzle-orm`/`sqlalchemy`），禁止字符串拼接 SQL；执行子进程传参数数组而非拼接命令行字符串（`execa` / `subprocess` 不用 `shell=True`）。
- **最小权限**：进程、令牌、数据库账号、CI 凭据均按最小必要权限授予；敏感操作做鉴权与审计。
- **安全使用加密**：密码用专用算法哈希（如 `argon2`/`bcrypt`，不用 MD5/SHA1）；随机数用密码学安全源（`crypto`/`secrets`），不用 `Math.random`/`random`。
- **依赖与供应链安全**：见「版本与协作 · 依赖治理」，CI 强制漏洞扫描与升级。

## 三、项目与工程化

### 1. 项目结构与组织

**核心原则**：结构按功能而非技术分层组织；目录可预测、职责单一、入口清晰，便于定位与扩展。

- **标准目录布局**：源码放 `src/`、脚本放 `scripts/`、文档放 `docs/`；配置文件统一放仓库根。测试就近放 `*.test.ts` / `test_*.py` 或集中放 `tests/`，团队内统一其一。
- **按功能分模块**：优先按业务领域/功能切分目录（feature-based），而非把 controllers/services/utils 等技术层各自堆成大杂烩。
- **单包 vs monorepo**：单一职责项目用单包；多个可独立发布的包用 monorepo（JS 用 `pnpm` workspace，Python 用 `uv` workspace）。
- **文件职责单一**：一个文件聚焦一个模块/类/功能；文件过大（经验值数百行）即按职责拆分。
- **入口清晰**：明确程序入口（`src/index.ts` / `src/main.py` 或 `__main__.py`），对外 API 通过入口/`index` 统一导出（配合「编码实践 · 函数与模块设计」的「明确公共 API」）。

### 2. 配置与环境管理

**核心原则**：配置集中声明、启动即校验、按环境注入；代码不散落读取裸环境变量。

- **配置集中且校验**：所有配置集中定义并在启动时校验——JS 用 `zod` 解析 `process.env`，Python 用 `pydantic-settings`；校验失败立即 fail-fast 报错退出。
- **分层来源**：优先级「默认值 < 配置文件 < 环境变量」；多环境（dev/staging/prod）通过环境变量切换，不在代码里散落 `if env === 'prod'` 判断。
- **`.env` 约定**：本地用 `.env`（不提交），仓库提供 `.env.example` 列出所有必填项与说明。
- **必填与默认**：明确区分必填项（缺失即报错）与可选项（有合理默认值）；类型在 Schema 中声明。
- **配置不可变**：启动后配置视为只读，集中通过一个 typed config 对象访问，不在各处直接读 `process.env` / `os.environ`。

### 3. 日志与可观测性

**核心原则**：日志是排障的一手证据；用结构化日志、合理分级，带足上下文且不泄漏敏感信息。

- **用结构化日志库**：JS 用 `pino`，Python 用 `loguru`；禁止用 `console.log` / `print` 做正式日志（仅临时调试可用，提交前清理）。
- **日志级别约定**：`debug`（开发细节）/`info`（关键流程节点）/`warn`（可恢复异常）/`error`（失败需关注）；生产默认 `info`。
- **结构化字段**：输出 JSON 结构化日志并带上下文字段（请求 ID、用户 ID、模块名），便于检索；不靠拼接字符串。
- **不在热路径滥打日志**：避免在循环/高频调用里打 `info`，防止刷屏与性能损耗。
- **错误日志带上下文**：记录错误时带上原始错误与堆栈（配合「编码实践 · 类型安全与错误处理」的「保留上下文」）。
- **不记敏感信息**：日志不输出口令、令牌、个人隐私数据。

## 四、版本与协作

### 1. 提交规范（Conventional Commits）

**核心原则**：所有提交遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范，使提交历史可读、可机器解析，并能自动驱动版本号与变更日志。

- 提交信息格式：`<type>(<scope>): <subject>`，必要时附 body 与 footer。
- 常用 `type`：
  - `feat`：新功能（触发 minor 版本）。
  - `fix`：缺陷修复（触发 patch 版本）。
  - `docs` / `style` / `refactor` / `perf` / `test` / `build` / `ci` / `chore`：文档、格式、重构、性能、测试、构建、CI、杂项。
- **破坏性变更**：在 `type` 后加 `!`（如 `feat!:`）或在 footer 写 `BREAKING CHANGE:`，触发 major 版本。
- subject 用祈使句、简洁明确；一次提交聚焦单一逻辑变更。
- 用工具强制校验：[`commitlint`](https://github.com/conventional-changelog/commitlint)（配合 husky `commit-msg` 钩子）；交互式提交可用 [`commitizen`](https://github.com/commitizen/cz-cli)。

### 2. 语义化版本（SemVer）

**核心原则**：版本号遵循 [语义化版本 2.0.0](https://semver.org/)：`MAJOR.MINOR.PATCH`。

- **MAJOR**：不兼容的 API 变更（破坏性变更）。
- **MINOR**：向后兼容的新功能。
- **PATCH**：向后兼容的缺陷修复。
- 预发布版本用 `-alpha`/`-beta`/`-rc`（如 `1.2.0-rc.1`）。
- 版本号由 Conventional Commits 自动推导，不手动随意 bump。
- 版本号是发布事实的唯一来源：JS 以 `package.json` 的 `version` 为准，Python 以 `pyproject.toml` 的 `version` 为准，并与 Git tag（`vX.Y.Z`）保持一致。

### 3. 变更日志（Changelog）

**核心原则**：维护 `CHANGELOG.md` 记录每个版本的变更，面向使用者，遵循 [Keep a Changelog](https://keepachangelog.com/) 风格。

- 按版本分组，分类列出 `Added` / `Changed` / `Fixed` / `Deprecated` / `Removed` / `Security`，并标注发布日期。
- 由 Conventional Commits **自动生成**，避免手写遗漏：
  - JS/TS：[`changesets`](https://github.com/changesets/changesets)（推荐，适合 monorepo）或 `release-please`。
  - Python：[`towncrier`](https://github.com/twisted/towncrier) 或基于 commits 的 `git-cliff`。
- 破坏性变更必须在 changelog 中显著标注，并说明迁移方式。

### 4. 依赖治理

**核心原则**：依赖必须**可复现、可追溯、可审计**；锁定版本、定期升级、主动扫描安全漏洞，避免供应链风险与依赖腐化。

- **锁文件必须提交**：JS 提交 `pnpm-lock.yaml`，Python 提交 `uv.lock`；CI 安装时校验锁文件一致性（`pnpm install --frozen-lockfile`、`uv sync --locked`），禁止安装时静默更新。
- **版本约束清晰**：直接依赖在 `package.json` / `pyproject.toml` 中声明明确范围；运行版本以锁文件为准。

**自动升级**：

- **工具**：统一使用 [Renovate](https://github.com/renovatebot/renovate)（推荐，跨 JS/Python/Docker/CI 等生态统一配置）；GitHub 纯仓库也可用 Dependabot。配置文件（`renovate.json` / `.github/dependabot.yml`）入库。
- **调度**：每周固定窗口批量提交升级 PR（如 `schedule: ["before 6am on monday"]`），并设置并发上限（`prConcurrentLimit`）避免 PR 风暴。
- **分级合并策略**：
  - `patch` / `devDependencies`：CI 通过后**自动合并**（`automerge: true`）。
  - `minor`（生产依赖）：自动开 PR，至少 1 人评审后合并。
  - `major` / 破坏性升级：必须人工评审，附迁移说明与回归测试。
- **聚合与降噪**：非主要版本升级按生态分组提交（`groupName`），减少 PR 数量；锁文件维护（`lockFileMaintenance`）每周单独跑。
- **安全升级优先**：开启漏洞告警驱动的升级（`vulnerabilityAlerts`），安全补丁不受常规调度限制，第一时间提 PR。
- **质量门禁**：所有升级 PR 必须通过完整 CI（Lint、类型检查、测试、构建）才允许合并；自动合并同样以 CI 全绿为前提。

**安全审计**：

- **CI 强制扫描**：每次 PR 与主分支构建都执行依赖漏洞扫描；扫描失败（达到阈值）**阻断合并**。
  - JS/TS：`pnpm audit --audit-level=high`（或 `osv-scanner`，覆盖更全的漏洞源）。
  - Python：[`pip-audit`](https://github.com/pypa/pip-audit)（针对 `uv.lock` 导出的依赖），或同样用 `osv-scanner`。
- **阻断阈值**：`high` 及以上（CVSS ≥ 7.0）漏洞必须修复或显式豁免后方可合并；`moderate` 及以下记录并跟踪。
- **修复时限（SLA）**：`critical` 24 小时内、`high` 7 天内、`moderate` 30 天内处理（升级、打补丁或替换依赖）。
- **豁免机制**：确无法立即修复时，登记白名单（如 `pip-audit --ignore-vuln`、`pnpm` overrides）并注明原因、责任人与复审日期；豁免须经评审，禁止无说明的长期忽略。
- **供应链加固**：CI 使用最小权限 token；锁文件保证可复现安装；定期运行 SCA 工具生成 SBOM（如 CycloneDX），便于追溯。
- **依赖精简**：定期清理未使用依赖（`knip` / `depcheck`、`deptry`）；引入新依赖前对照「技术栈与工具基线 · 优先复用成熟的开源组件」的选型标准与引入判定。
- **许可证合规**：避免引入与项目协议冲突的依赖（如 GPL 进入闭源项目），必要时用工具校验 License。

### 5. CI/CD 流水线

**核心原则**：CI 是质量底线，与本地检查一致、快速反馈、全绿才合并；发布全程自动化、可复现。

- **CI 必跑检查清单**：每次 PR 与主分支构建依次执行——安装（锁文件校验）→ 格式校验 → Lint → 类型检查 → 测试（带覆盖率）→ 构建 → 依赖漏洞扫描；任一失败即阻断合并。
- **与本地一致**：CI 命令与本地、pre-commit 完全一致（见「技术栈与工具基线 · 统一工具链」），避免「本地过、CI 挂」。
- **快速反馈**：合理拆分并行任务、利用依赖与构建缓存缩短流水线时长；快检查（Lint/类型）前置。
- **发布自动化**：合并到主分支后由 Conventional Commits 驱动版本号与 changelog（`changesets` / `release-please` / `towncrier`），自动打 tag 并发布产物。
- **最小权限与可复现**：CI 凭据按最小必要权限授予，安装用 `--frozen-lockfile` / `--locked` 保证可复现。
- **分支保护**：主分支要求 PR + CI 全绿 + 至少 1 人评审方可合并，禁止直接推送。

## 五、与 AI 协作

> 本领域是 AI 助手执行任务时的行为准则（提炼自 Andrej Karpathy 对 LLM 编码常见陷阱的总结）。**取舍**：这些准则偏向「审慎优先于速度」；对琐碎任务请用判断力灵活把握。

### 1. 思考在先

**核心原则**：动手前先想清楚——不臆测、不藏混淆、亮出权衡。

- **显式说明假设**：实现前先讲清依赖的前提；不确定就问，不要默默替用户做决定。
- **多种理解都列出**：需求存在多种解读时全部摆出来请用户选，不静默挑一种。
- **有更简方案就说**：发现更简单的做法要主动指出，必要时据理反对。
- **不清楚就停下**：哪里看不懂，先点名说明、提问，再继续。

### 2. 简单优先

**核心原则**：用解决问题的最小代码，不写任何投机性内容。

- 不实现需求之外的功能；不为一次性代码造抽象。
- 不加未被要求的「灵活性」「可配置性」；不为不可能发生的场景加错误处理。
- 写了 200 行但其实 50 行能搞定，就重写。
- 自检：「资深工程师会觉得这过度设计吗？」会，就简化。（与「编码实践 · 函数与模块设计」一致）

### 3. 外科式改动

**核心原则**：只动该动的；只清理自己制造的「垃圾」。

- 改动现有代码时：不顺手「优化」相邻代码、注释或格式；不重构没坏的东西；沿用现有风格，即使你有别的偏好。
- 发现无关的 dead code：提一句，但不要删（除非用户要求）。
- 自己的改动产生了孤儿（不再被引用的 import/变量/函数）时清理掉；但不删既有的、与本次改动无关的 dead code。
- 检验标准：每一行改动都应能直接追溯到用户的需求。

### 4. 目标驱动执行

**核心原则**：先定义可验证的成功标准，再循环执行直到验证通过。

- 把任务转成可验证目标：「加校验」→「为非法输入写测试，再让它们通过」；「修 bug」→「先写能复现的测试，再修到通过」；「重构 X」→「确保重构前后测试都通过」。
- 多步任务先给简要计划，每步附验证点：`1. [步骤] → 验证：[检查] 2. …`。
- 强成功标准（可独立循环验证）优于弱标准（「能跑就行」，需反复澄清）。
