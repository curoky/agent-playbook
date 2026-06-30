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

**核心原则**：用当前主流支持的较新版本，优先用最新语法简化代码、提升可读性与类型安全，避免过时或被取代的写法。

**通用要求**：

- 下表「最低版本」为下限基线、「推荐版本」为新项目默认目标；不用已 EOL 的版本，升级时同步迁移废弃特性。
- **新语法服务于可读性，不为用而用**：新写法反而更难懂时（如深度嵌套 `:=`、把简单分支硬写成 `match`、过度类型体操）选直观写法；实验性/非 Stage 4 语法不用于生产。
- 版本号随时间演进，下列为截至 2026-06 的具体版本，落地时按官方最新稳定版校准。

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

#### Go

| 项 | 最低版本 | 推荐版本 |
| --- | --- | --- |
| Go | 1.25（Go 支持策略为最新两个大版本，更早版本已不再维护） | 1.26.x（最新稳定版，2026-02 发布，新项目默认） |

- 遵循 Go 官方「最新两个大版本」支持策略，不使用已失去支持的旧版本；新项目默认采用最新稳定的 1.26.x。
- **必用 Go Modules**：`go.mod` 中用 `go 1.25`（或更高）声明语言版本基线；用 `toolchain` 指令固定团队工具链版本，确保一致。
- 优先采用现代语法简化代码，例如：
  - 泛型（类型参数）写通用容器与算法，替代 `interface{}` + 类型断言的样板。
  - 标准库 `slices`、`maps`、`cmp` 操作切片与映射，替代手写循环与 `golang.org/x/exp/*`。
  - 结构化日志 `log/slog`，替代 `log` 裸打印与第三方日志门面。
  - `errors.Is`/`errors.As` + `fmt.Errorf("...: %w", err)` 包装与判别错误，替代字符串比较与 `github.com/pkg/errors`。
  - `context.Context` 贯穿请求生命周期，传递取消、超时与请求级值。
  - `for range n`（整数范围循环，1.22+）、`range over func`（迭代器，1.23+）等惯用法。
- **禁止**：忽略 `error` 返回值（必须显式处理或 `_` 并写明原因）、用 `panic` 处理可预期错误（仅用于不可恢复的程序错误）、滥用空 `interface{}`/`any`（优先具体类型或泛型）、用 `ioutil.*`（已废弃，用 `os`/`io`）、裸 `goroutine` 不管理生命周期（见「异步与并发」）。

#### C++

| 项 | 最低版本 | 推荐版本 |
| --- | --- | --- |
| C++ 标准 | C++20（`-std=c++20`） | C++23（`-std=c++23`，新项目默认） |
| 编译器 | GCC 12 / Clang 15 / MSVC 19.3x（VS 2022） | 最新稳定版（GCC 14+ / Clang 18+ / 最新 MSVC） |
| 构建系统 | Bazel 7.x（启用 bzlmod） | 最新 Bazel（`.bazelversion` 固定，bzlmod + Bazel Central Registry 管理依赖） |

- **现代 C++ 优先**：编写 RAII 风格代码，资源生命周期绑定对象；用值语义与移动语义，避免手动 `new`/`delete`。
- **标准声明（必须显式锁定）**：在 `.bazelrc` 固定 `build --cxxopt=-std=c++23`（或 per-target `copts`），并用 `.bazelversion` 锁定 Bazel 版本；通过 `MODULE.bazel` + `MODULE.bazel.lock` 锁定外部依赖，确保团队一致。
- 优先采用现代语法简化代码，例如：
  - 智能指针 `std::unique_ptr`/`std::shared_ptr` + `std::make_unique`/`std::make_shared`，替代裸 `new`/`delete`（见「编码实践 · 类型安全与错误处理」的资源管理）。
  - `auto`、结构化绑定 `auto [a, b] = ...`、范围 `for`、`if`/`switch` 初始化语句，简化样板。
  - `std::optional`/`std::variant`/`std::expected`（C++23）表达「可能缺失/多态/可失败」，替代裸指针哨兵与错误码。
  - `std::string_view`/`std::span` 传递只读视图，避免不必要拷贝；`constexpr`/`consteval` 把计算前移到编译期。
  - Concepts 约束模板（替代 SFINAE）、Ranges（`std::ranges::`、视图与管道 `|`）替代手写循环与迭代器对。
  - `<format>` 风格的格式化：默认用 [`fmt`](https://github.com/fmtlib/fmt)（`fmt::format`/`fmt::print`），替代 `printf` 与 iostream 拼接；`<chrono>` 处理时间。
- **禁止**：裸 `new`/`delete` 与裸 `owning` 指针管理资源（用智能指针/容器/RAII）、C 风格强制转换（用 `static_cast`/`reinterpret_cast` 等具名转换）、`using namespace std;` 写在头文件或全局作用域、宏充当常量/函数（用 `constexpr`/`inline` 函数/`enum class`）、裸数组与 `strcpy`/`sprintf` 等不安全 C API（用 `std::array`/`std::vector`/`fmt::format`）、未初始化变量、在头文件定义非 `inline` 的非模板函数/全局变量。

### 3. 统一工具链

工具链明细（JS/TS、Python、Go 与 C++ 的包管理、Lint、类型检查、测试、构建、pre-commit）见 [`tech-stack/toolchain.md`](./tech-stack/toolchain.md)（搭脚手架、配工具时查阅）。要点：配置文件入库；本地、pre-commit、CI 跑同一套检查；JS 用 `pnpm`+`biome`+`tsc`+`vitest`，Python 用 `uv`+`ruff`+`mypy`/`pyright`+`pytest`，Go 用 `go mod`+`gofmt`/`goimports`+`golangci-lint`+`go vet`+`go test`，C++ 用 `Bazel`(bzlmod)+`clang-format`+`clang-tidy`+`Catch2`。

## 二、编码实践

> 本域各主题的完整要点见 [`coding-practices.md`](./coding-practices.md)（编辑 JS/TS、Python、Go、C++ 源文件时自动生效）。主文件仅保留每节的核心原则与关键禁令。

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
