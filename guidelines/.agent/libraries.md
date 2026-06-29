# 库选型参考

> 本文件是「技术栈与工具基线 · 优先复用成熟的开源组件」的明细表，按需查阅。
>
> **选型标准**（库须同时满足）：现代化、主流、积极维护。
> **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件除非用户手动指定，否则不主动引入；确需引入先说明风险并请用户确认，优先选标准库或更主流的成熟替代品。
> **引入判定**：
>
> - **必须引入**：能大幅简化代码或 API 明显更好、更不易出错（如 `zod`、`typer`、`pydantic`），作为默认选择。
> - **按需引入**：与系统库差别不大、仅有性能或便利收益（如 `orjson`、`picocolors`），仅在确有需求时引入。

## JavaScript / TypeScript

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

## Python

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

## Go

> **标准库优先**：Go 标准库覆盖度高，下表「标准库」项一律优先使用，仅在确有缺口时引入第三方库。

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| HTTP 服务 / 路由 | 标准库 [`net/http`](https://pkg.go.dev/net/http)（1.22+ 增强路由） | 标准库 | 简单服务直接用；复杂中间件/路由再考虑 [`chi`](https://github.com/go-chi/chi) 或 [`echo`](https://github.com/labstack/echo)。 |
| 日志 | 标准库 [`log/slog`](https://pkg.go.dev/log/slog) | 标准库 | 结构化日志，替代第三方日志门面；需极致性能再看 [`zap`](https://github.com/uber-go/zap)。 |
| 错误处理 | 标准库 [`errors`](https://pkg.go.dev/errors) | 标准库 | `errors.Is`/`As` + `fmt.Errorf("...: %w")`；不用 `github.com/pkg/errors`。 |
| 切片 / 映射操作 | 标准库 [`slices`](https://pkg.go.dev/slices) / [`maps`](https://pkg.go.dev/maps) | 标准库 | 替代手写循环与 `golang.org/x/exp/*`。 |
| 命令行接口 | [`cobra`](https://github.com/spf13/cobra) | 按需 | 复杂多级子命令用 `cobra`；极简场景用标准库 `flag`。 |
| 配置管理 | [`viper`](https://github.com/spf13/viper) / [`kelseyhightower/envconfig`](https://github.com/kelseyhightower/envconfig) | 必须 | 多来源配置用 `viper`，纯环境变量映射用 `envconfig`，启动即校验。 |
| 数据校验 | [`go-playground/validator`](https://github.com/go-playground/validator) | 必须 | 基于 struct tag 校验外部输入。 |
| 数据库 / SQL | [`sqlc`](https://github.com/sqlc-dev/sqlc) / [`sqlx`](https://github.com/jmoiron/sqlx) | 必须 | `sqlc` 由 SQL 生成类型安全代码（推荐）；轻量增强用 `sqlx`；需完整 ORM 用 [`gorm`](https://github.com/go-gorm/gorm)。 |
| 数据库迁移 | [`golang-migrate`](https://github.com/golang-migrate/migrate) | 必须 | 版本化管理 schema 迁移。 |
| 并发组 / 错误聚合 | [`golang.org/x/sync/errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup) | 必须 | 并发任务统一等待与首错取消，替代手写 `WaitGroup` + channel。 |
| 测试断言 | [`testify`](https://github.com/stretchr/testify) | 按需 | `require`/`assert` 简化断言；优先标准库 `testing` 表驱动。 |
| Mock 生成 | [`uber-go/mock`](https://github.com/uber-go/mock) | 按需 | 由接口生成 mock（`mockgen`），替代已归档的 `golang/mock`。 |
| HTTP 客户端重试 | 标准库 `net/http` + [`hashicorp/go-retryablehttp`](https://github.com/hashicorp/go-retryablehttp) | 按需 | 标准库客户端够用，需退避重试时引入。 |
| 唯一 ID | [`google/uuid`](https://github.com/google/uuid) | 按需 | 生成 UUID。 |
| 依赖注入 | [`google/wire`](https://github.com/google/wire) | 按需 | 编译期 DI；小项目手动注入即可，避免过度设计。 |
| Lint 聚合 | [`golangci-lint`](https://github.com/golangci/golangci-lint) | 必须 | 聚合多 linter，见 [`toolchain.md`](./toolchain.md)。 |
| 漏洞扫描 | [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | 必须 | 官方漏洞扫描，CI 强制。 |

> 注：以上为截至当前的推荐默认项。项目已有等价成熟方案则沿用，保持技术栈一致；定期复核维护状态，及时替换停更依赖。
