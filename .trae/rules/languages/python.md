---
description: 编写 Python 代码，或为 Python 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.py,*.pyi
alwaysApply: false
---

# Python 语言规范（编码实践 + 库选型）

> 本文件自洽：编写 Python 时所需的编码实践、日志、库选型与工具链均在此。跨语言版本基线与工程化（结构/配置/CI/发版）可选参考 `engineering.md`（非必需同时加载）。

## 0. 语言版本与语法

- **全量使用类型注解**，配合 `mypy` / `pyright` 做静态检查。
- **版本锁定**：`pyproject.toml` 设置 `requires-python = ">=3.12"`；用 `uv` 管理并锁定（`.python-version` + `uv.lock`）。
- 优先采用现代语法简化代码，例如：
  - 结构化模式匹配 `match`/`case`，替代冗长的 `if/elif` 链。
  - 内置泛型与新式类型语法（`list[int]`、`X | None`、`type` 别名语句），替代 `typing.List`、`Optional`。
  - f-string（含 `f"{x=}"` 调试写法），替代 `%` 与 `.format()`。
  - 用 `pydantic` 模型替代手写 `__init__` 样板（默认首选）；仅当明确不需要校验/序列化、且要零依赖或极致轻量时才用标准库 `dataclasses`。
  - 海象运算符 `:=`、`pathlib`、上下文管理器 `with`、推导式等惯用法。
- **新语法以可读性为准绳**：新写法更难懂时（把简单分支硬写成 `match`、深度嵌套 `:=`）选直观写法，不为「显得现代」而用。
- **禁止**：`from x import *`、可变默认参数（`def f(a=[])`，改用 `None` 哨兵）、`typing.List`/`Dict`/`Optional` 等旧式泛型（用内置 `list`/`dict`/`X | None`）、用 `os.path` 拼路径（用 `pathlib`）；裸 `except:` 见 §3。

## 1. 命名与代码风格

- **大小写惯例**：变量/函数/模块 `snake_case`、类 `PascalCase`、常量 `UPPER_SNAKE_CASE`，遵循 PEP 8。
- **命名即文档**：用完整可检索的名字，布尔加 `is`/`has` 前缀。
- **避免魔法值**：字面量提取为有名常量或 `Enum`。
- **格式不进 review**：交给 `ruff format` 自动处理，review 中不讨论格式。

## 2. 函数与模块设计

- **单一职责、小而专一**：出现「阶段性注释」、超过一屏、或函数名需用「and」才能描述时 → 拆成更小的具名函数。
- **参数精简**：参数超过 3 个时改用关键字参数 + `pydantic` 模型（默认首选，无需校验的轻量场景可用 `dataclass`）；避免布尔陷阱参数。
- **明确公共 API**：用 `__all__` 或下划线前缀标记私有。
- **依赖倒置**：高层逻辑依赖 `Protocol`/ABC，由外部注入实现；避免循环依赖。

## 3. 类型安全与错误处理

- **不使用逃逸类型**：禁止裸 `Any`，用具体类型、`Protocol` 或泛型。
- **在边界校验外部输入**：API 响应、用户输入、配置、环境变量等用 `pydantic` 做 Schema 校验，之后内部代码可信任其类型。
- **`pydantic` 模型默认拒绝额外字段**：使用 `pydantic` 时尽量显式声明 `model_config = ConfigDict(extra="forbid")`，默认禁止未声明字段混入系统；仅在确需透传/兼容额外字段时才放宽，并注明原因。
- **让非法状态不可表示**：用 `Literal` + `match` 建模互斥状态，避免「多个布尔标志组合出非法态」。
- **避免「可能不存在」的隐式约定**：对「可能不存在」的返回值用显式类型标注（`T | None`），不靠隐式约定。
- **错误分流判据：可预期失败优先用返回值表达**：业务上可预期的失败（找不到、校验失败、外部调用失败）**优先返回显式结果**（如状态码/枚举 + error message），不用异常做控制流。Python 无 `neverthrow` 式的成熟 `Result`/`Either` 库，**不引入此类三方库**，用以下惯用法之一表达：
  - 返回结构化结果对象：`pydantic` 模型或 `dataclass`（如含 `ok: bool` / `code` + `error: str | None` + `value`），字段用 `Literal` 表达状态，配合 `match` 消费。
  - 简单场景返回 `T | None`（配合显式类型标注）或 `(value, error)` 二元组，调用方显式判断。
- **异常仅用于不可恢复/真正意外的错误**：捕获时必须捕获**具体异常类型**，禁止裸 `except:`、禁止空 `except` 后继续；确需抛出时用**自定义领域异常**并在边界统一转换回上述返回值形态。
- **重抛保根因**：重新抛出时用 `raise X from e` 携带原始错误。
- **资源清理可靠**：用 `with` 上下文管理器确保文件/连接/锁等资源释放。

## 4. 异步与并发

- **统一异步模型**：用 `asyncio`，不在异步代码中调用阻塞 I/O。
- **并发模型选择**：IO 密集 → `asyncio`/线程；CPU 密集 → 多进程 / worker，不阻塞事件循环。
- **并发要并行**：独立任务用 `asyncio.gather` 并发执行，不要串行 `await`。
- **限制并发度**：批量并发用 `asyncio.Semaphore` 限制上限。
- **生命周期闭环**：每个 Task 的失败都必须被处理，不留「发射后不管」的悬空 Task；长任务用 `asyncio.timeout`/取消，避免无限等待。

## 5. 性能与优化

- **先测后调**：优化前用 profiler/`pytest-benchmark` 定位真实热点，优化前后对比并纳入回归，不靠直觉过早优化。
- **常见浪费清单**：N+1 查询、循环内重复 IO/计算、无索引查询 → 优先批量与缓存；缓存必须有明确失效策略。
- **绕开 GIL 的选择**：CPU 密集用 `multiprocessing`/`ProcessPoolExecutor`（或 3.13+ free-threaded、`Cython`/`numpy` 向量化），不用线程；IO 密集才用 `asyncio`/线程。
- **热点数值计算向量化**：大批量数值运算优先 `numpy`/`polars` 向量化，避免 Python 层逐元素 `for` 循环。

## 6. 注释与文档

- **写 why 不写 what**：注释解释意图、权衡、坑与非显而易见的约束，不复述代码字面逻辑。
- **同步与清理**：改代码同步更新注释；删被注释掉的死代码；`TODO`/`FIXME`/`HACK` 必须附负责人或 issue 链接。
- **公共 API 文档**：用 docstring（约定如 Google/NumPy 风格，配合类型注解，不在 docstring 里重复类型）。

## 7. 测试规范

- **框架**：用 `pytest`，配合 `pytest-cov` 覆盖率。
- **测行为非实现**：针对公共接口与可观察行为断言，不断言私有细节；遵循 Arrange-Act-Assert。
- **隔离与确定性**：外部依赖用 mock/stub/fake，时间用可注入的时钟，不依赖网络/真实 DB/全局状态。
- **覆盖优先级**：先覆盖核心逻辑、分支与边界（空、极值、错误路径），覆盖率作参考非目标；修 bug 先写能复现的失败用例再修。

## 8. 安全编码

- **校验并转义输入**：默认不信任外部输入，先用 `pydantic`/`validator` 校验再使用；按输出上下文转义防注入。
- **杜绝注入**：SQL 用参数化或 ORM（`sqlalchemy`），禁止拼接 SQL；执行子进程用 `subprocess` 传参数数组，不用 `shell=True`。
- **安全使用加密**：密码用 `argon2`/`bcrypt` 哈希（不用 MD5/SHA1）；随机数用 `secrets`，不用 `random`。

## 9. 日志

- **用结构化日志库**：应用/脚本用 `loguru`；**被别人 import 的库**保持用标准 `logging`（不替使用方决定日志配置）。禁止 `print` 做正式日志（仅临时调试可用，提交前清理）。
- **日志级别约定**：`debug`（开发细节）/`info`（关键流程节点）/`warn`（可恢复异常）/`error`（失败需关注）；生产默认 `info`。
- **结构化字段**：带上下文字段（请求 ID、用户 ID、模块名），不靠拼接字符串。
- **不在热路径滥打**：避免在循环/高频调用里打 `info`，防止刷屏与性能损耗。
- **错误日志带上下文**：记录错误时带上原始错误与堆栈（配合 §3「重抛保根因」的 `raise ... from e`）。
- **不记敏感信息**：日志不输出口令、令牌、个人隐私数据。

## 10. 库选型

**选型元原则**（现代化、主流、积极维护）：

- **选型标准**：同时满足现代化（类型注解、async/await）、主流（社区广泛采用、生产验证充分）、积极维护；不确定就核实最新发布时间与活跃度。
- **谨慎引入高风险依赖**：久未维护（一年以上无发布/提交）、star 偏少、过于小众的组件，除非用户指定否则不主动引入；确需引入时先说明维护、安全、可替代性风险并请用户确认。
- **引入判定**：能大幅简化代码或 API 明显更不易出错（如 `pydantic`、`typer`）默认引入；与标准库差别不大、仅性能或便利收益（如 `orjson`）按需引入。
- **标准库优先**：`pathlib`、`zoneinfo`、`subprocess`、`logging`、`secrets` 等够用时不引第三方；数据模型默认 `pydantic`，仅无需校验的轻量场景才用 `dataclasses`。
- **不因体积/依赖复杂度而拒绝**：满足选型标准且能显著提升可读性与可维护性时，不把体积作为否决项；这些因素只影响多个合格候选之间的选择。

### 速查表

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| 路径操作 | 标准库 [`pathlib`](https://docs.python.org/3/library/pathlib.html) | 标准库 | 用 `Path`，不用 `os.path` 字符串拼接。 |
| 命令行接口 | [`typer`](https://github.com/fastapi/typer) | 必须 | 基于类型注解，替代 `argparse`。 |
| 数据校验 / 模型 | [`pydantic`](https://github.com/pydantic/pydantic) | 必须 | 基于类型注解做校验与序列化（v2）。 |
| 配置管理 | [`pydantic-settings`](https://github.com/pydantic/pydantic-settings) | 必须 | 从环境变量 / `.env` 加载并校验。 |
| HTTP 请求 | [`httpx`](https://github.com/encode/httpx) | 必须 | 同步/异步统一，替代 `requests` + `aiohttp`。 |
| 日期 / 时间 | [`pendulum`](https://github.com/python-pendulum/pendulum) | 按需 | 时区友好；简单场景用标准库 `datetime` + `zoneinfo`。 |
| 终端输出 / 富文本 | [`rich`](https://github.com/Textualize/rich) | 按需 | 表格、进度条、彩色输出。 |
| 日志 | [`loguru`](https://github.com/Delgan/loguru) | 按需 | 替代繁琐的 `logging` 配置；库（被他人 import）建议仍用标准 `logging`。 |
| 测试 | [`pytest`](https://github.com/pytest-dev/pytest) | 必须 | 配合 fixture 与参数化。 |
| 重试 | [`tenacity`](https://github.com/jd/tenacity) | 必须 | 声明式重试（退避、超时、条件）。 |
| Web / API 框架 | [`fastapi`](https://github.com/fastapi/fastapi) | 必须 | 基于类型注解与 `pydantic`，异步。 |
| 包 / 环境管理 | [`uv`](https://github.com/astral-sh/uv) | 必须 | 替代 `pip` + `venv` + `pip-tools`。 |
| 代码格式化 / Lint | [`ruff`](https://github.com/astral-sh/ruff) | 必须 | 替代 `flake8` + `black` + `isort`。 |
| 静态类型检查 | [`mypy`](https://github.com/python/mypy) / [`pyright`](https://github.com/microsoft/pyright) | 必须 | 基于类型注解做静态检查。 |
| 数据库 / ORM | [`sqlalchemy`](https://github.com/sqlalchemy/sqlalchemy) / [`sqlmodel`](https://github.com/fastapi/sqlmodel) | 必须 | 复杂查询/生产用 `sqlalchemy` 2.0；配 FastAPI、需类型安全模型用 `sqlmodel`。 |
| 数据库迁移 | [`alembic`](https://github.com/sqlalchemy/alembic) | 必须 | 与 `sqlalchemy` 配套的版本化迁移。 |
| 数据处理 / DataFrame | [`polars`](https://github.com/pola-rs/polars) | 按需 | 性能优先用 `polars`；需兼容既有 `pandas` 生态用 `pandas`。 |
| 任务队列 / 后台任务 | [`celery`](https://github.com/celery/celery) / [`arq`](https://github.com/python-arq/arq) | 必须 | `arq` 为轻量 asyncio 方案。 |
| 子进程 / 命令执行 | 标准库 [`subprocess`](https://docs.python.org/3/library/subprocess.html) | 标准库 | 用 `subprocess.run`，传参数列表不用 `shell=True`；避免 `sh` 等不支持 Windows 的库。 |
| 序列化 / 高性能 JSON | [`orjson`](https://github.com/ijl/orjson) | 按需 | 仅性能敏感时引入，否则用标准库 `json`。 |
| 异步任务编排 | 标准库 [`asyncio`](https://docs.python.org/3/library/asyncio.html) | 标准库 | `asyncio.gather`/`TaskGroup`/`timeout`；并发限流用 `asyncio.Semaphore`。 |
| 进程内缓存 | [`cachetools`](https://github.com/tkem/cachetools) | 按需 | 仅当标准库 `functools.cache` / `lru_cache` 不够、需要 TTL / LFU / 显式缓存对象时引入。 |
| 密码哈希 | [`argon2-cffi`](https://github.com/hynek/argon2-cffi) | 必须 | 密码用 `argon2`；随机数/令牌用标准库 `secrets`，不用 `random`。 |
| HTTP 服务运行 | [`uvicorn`](https://github.com/encode/uvicorn) | 必须 | ASGI 服务器，配 `fastapi`；多 worker 生产用 `gunicorn` + uvicorn worker。 |
| 缓存 / Redis | [`redis`](https://github.com/redis/redis-py) | 按需 | 官方客户端，支持 asyncio。 |
| 数据科学 / 数值 | [`numpy`](https://github.com/numpy/numpy) | 按需 | 数值计算基石；高层分析按需配 `polars`/`pandas`。 |
| CLI 进度 / 交互 | [`questionary`](https://github.com/tmbo/questionary) | 按需 | 交互式提问；纯展示进度用 `rich`。 |

### 选型判据（多候选时如何选）

- **ORM `sqlalchemy` vs `sqlmodel`**：通用、复杂查询、需要完全控制用 `sqlalchemy` 2.0；项目本就用 `fastapi`、希望「一个模型同时当 ORM 表和 API schema」用 `sqlmodel`（它是 `sqlalchemy` + `pydantic` 的薄封装，复杂查询仍会落回 sqlalchemy）。轻量只读脚本可直接用标准库 `sqlite3`。
- **DataFrame `polars` vs `pandas`**：新项目、看重性能与内存、列式/惰性计算用 `polars`；**必须对接既有 `pandas` 生态**（如 `scikit-learn`、绘图库、同事代码）时用 `pandas`，不要为「更快」强行迁移既有分析栈。
- **任务队列 `celery` vs `arq`**：纯 asyncio 应用、想要轻量、Redis 即可用 `arq`；需要**成熟生态、多 broker、定时任务（beat）、复杂路由/重试**用 `celery`。
- **日期 `pendulum` vs 标准库 `datetime`+`zoneinfo`**：Python 3.9+ 标准库 `zoneinfo` 已能处理时区，简单场景直接用标准库；需要**更顺手的链式 API、时长/区间运算、解析**时才引 `pendulum`。
- **日志 `loguru` vs 标准库 `logging`**：**应用/脚本**追求开箱即用、零配置用 `loguru`；**被别人 import 的库**应保持用标准 `logging`（不替使用方决定日志配置）。
- **类型检查 `mypy` vs `pyright`**：CI 严格门禁、配置稳定用 `mypy`；要**编辑器内实时反馈、对新语法支持更快**（尤其配 VS Code/Pylance）用 `pyright`，两者可并存。
- **JSON `orjson` vs 标准库 `json`**：默认标准库 `json`；仅当**序列化是热点路径**（高 QPS API、大批量）时换 `orjson`（更快、原生支持 `datetime`/`numpy`）。
- **HTTP `httpx` vs `requests`**：新项目一律 `httpx`（同步异步统一、API 与 requests 近似）；维护老代码可沿用 `requests`，不新引入 `aiohttp`（除非需要其特定服务端能力）。

> 注：截至 2026-06 的默认推荐；既有项目沿用等价成熟方案，并定期复核维护状态。

## 11. 工具链

> 跨语言工具链约定（配置/锁文件入库、本地/pre-commit/CI 一致）可选参考 `engineering.md` 工具链节。

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包 / 环境 / 版本管理 | [`uv`](https://github.com/astral-sh/uv) | 管理依赖、虚拟环境与 Python 版本；提交 `uv.lock`。 |
| Lint + 格式化 | [`ruff`](https://github.com/astral-sh/ruff) | `ruff check` + `ruff format`，替代 `flake8` + `black` + `isort`。 |
| 类型检查 | [`mypy`](https://github.com/python/mypy) / [`pyright`](https://github.com/microsoft/pyright) | 开启 strict。 |
| 测试 | [`pytest`](https://github.com/pytest-dev/pytest) | 配合 `pytest-cov` 覆盖率。 |

- **提交前检查（pre-commit）**：用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理 git hook，在 `lefthook.yml` 的 `pre-commit` 中对暂存文件跑 `ruff check`、`ruff format` 与 `mypy` 等。
