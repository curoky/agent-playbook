---
description: 编写 Python 代码，或为 Python 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.py,*.pyi
alwaysApply: false
---

# Python 语言规范（编码实践 + 库选型）

> 本文件汇总 Python 的**编码实践**（[`common.md`](./common.md) 的 Python 明细）与**库选型**（「技术栈与工具基线 · 优先复用成熟的开源组件」的 Python 明细）。通用核心原则见 [`common.md`](./common.md)，版本基线总表见 [`main.md`](../main.md)，工具链（`uv` / `ruff` / CI / pre-commit）见 [`toolchain.md`](../toolchain.md)。

## 0. 语言版本与语法

- **全量使用类型注解**，配合 `mypy` / `pyright` 做静态检查。
- **版本锁定**：`pyproject.toml` 设置 `requires-python = ">=3.12"`；用 `uv` 管理并锁定（`.python-version` + `uv.lock`）。
- 优先采用现代语法简化代码，例如：
  - 结构化模式匹配 `match`/`case`，替代冗长的 `if/elif` 链。
  - 内置泛型与新式类型语法（`list[int]`、`X | None`、`type` 别名语句），替代 `typing.List`、`Optional`。
  - f-string（含 `f"{x=}"` 调试写法），替代 `%` 与 `.format()`。
  - `dataclasses` / `pydantic` 模型，替代手写 `__init__` 样板。
  - 海象运算符 `:=`、`pathlib`、上下文管理器 `with`、推导式等惯用法。
- **禁止**：`from x import *`、可变默认参数（`def f(a=[])`，改用 `None` 哨兵）、`typing.List`/`Dict`/`Optional` 等旧式泛型（用内置 `list`/`dict`/`X | None`）、用 `os.path` 拼路径（用 `pathlib`）；裸 `except:` 见 §3。

## 1. 命名与代码风格

- **大小写惯例**：变量/函数/模块 `snake_case`、类 `PascalCase`、常量 `UPPER_SNAKE_CASE`，遵循 PEP 8。
- **避免魔法值**：字面量提取为有名常量或 `Enum`。
- **格式工具**：交给 `ruff format` 自动处理。

## 2. 函数与模块设计

- **参数精简**：参数超过 3 个时改用关键字参数 + `dataclass`/`pydantic`。
- **明确公共 API**：用 `__all__` 或下划线前缀标记私有。
- **依赖倒置**：高层逻辑依赖 `Protocol`/ABC，由外部注入实现。

## 3. 类型安全与错误处理

- **不使用逃逸类型**：禁止裸 `Any`，用具体类型、`Protocol` 或泛型。
- **在边界校验外部输入**：API 响应、用户输入、配置、环境变量等用 `pydantic` 做 Schema 校验，之后内部代码可信任其类型。
- **让非法状态不可表示**：用 `Literal` + `match` 建模互斥状态，避免「多个布尔标志组合出非法态」。
- **避免「可能不存在」的隐式约定**：对「可能不存在」的返回值用显式类型标注（`T | None`），不靠隐式约定。
- **可预期错误用值表达**：业务上可预期的失败优先返回显式结果或抛出**自定义领域异常**。
- **异常用于不可恢复错误**：捕获时必须捕获**具体异常类型**，禁止裸 `except:`、禁止空 `except` 后继续。
- **保留上下文**：重新抛出时用 `raise X from e` 携带原始错误。
- **资源清理可靠**：用 `with` 上下文管理器确保文件/连接/锁等资源释放。

## 4. 异步与并发

- **统一异步模型**：用 `asyncio`，不在异步代码中调用阻塞 I/O。
- **并发要并行**：独立任务用 `asyncio.gather` 并发执行，不要串行 `await`。
- **限制并发度**：批量并发用 `asyncio.Semaphore` 限制上限。
- **不吞异步异常**：每个 Task 的失败都必须被处理；不留「发射后不管」的悬空 Task。
- **支持取消与超时**：长任务用 `asyncio.timeout`/取消，避免无限等待。
- **CPU 密集**：用多进程 / worker，不阻塞事件循环。

## 5. 性能与优化

- **基准可复现**：关键算法/接口用 `pytest-benchmark` 写 benchmark，优化前后对比并纳入回归。
- **绕开 GIL 的选择**：CPU 密集用 `multiprocessing`/`ProcessPoolExecutor`（或 3.13+ free-threaded、`Cython`/`numpy` 向量化），不用线程；IO 密集才用 `asyncio`/线程。
- **热点数值计算向量化**：大批量数值运算优先 `numpy`/`polars` 向量化，避免 Python 层逐元素 `for` 循环。

## 6. 注释与文档

- **公共 API 文档**：用 docstring（约定如 Google/NumPy 风格，配合类型注解，不在 docstring 里重复类型）。

## 7. 测试规范

- **框架**：用 `pytest`，配合 `pytest-cov` 覆盖率。
- **隔离与确定性**：外部依赖用 mock/stub/fake，时间用可注入的时钟。

## 8. 安全编码

- **校验并转义输入**：外部输入先用 `pydantic`/`validator` 校验再使用；按输出上下文转义防注入。
- **杜绝注入**：SQL 用参数化或 ORM（`sqlalchemy`），禁止拼接 SQL；执行子进程用 `subprocess` 传参数数组，不用 `shell=True`。
- **安全使用加密**：密码用 `argon2`/`bcrypt` 哈希（不用 MD5/SHA1）；随机数用 `secrets`，不用 `random`。

## 9. 库选型

> **选型标准**（库须同时满足）：现代化、主流、积极维护。
> **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件除非用户手动指定，否则不主动引入；确需引入先说明风险并请用户确认。
> **引入判定**：
>
> - **必须**：能大幅简化代码或 API 明显更好、更不易出错（如 `pydantic`、`typer`），作为默认选择。
> - **按需**：与标准库差别不大、仅有性能或便利收益（如 `orjson`），仅在确有需求时引入。
> - **标准库优先**：`pathlib`、`zoneinfo`、`dataclasses`、`subprocess`、`logging`、`secrets` 等够用时不引第三方。

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

> 注：以上为截至 2026-06 的推荐默认项。项目已有等价成熟方案则沿用，保持技术栈一致；定期复核维护状态，及时替换停更依赖。

## 10. 工具链

> 跨语言通用要求（配置入库、本地/pre-commit/CI 一致、CI 重复执行同一套检查）见 [`toolchain.md`](../toolchain.md)。

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包 / 环境 / 版本管理 | [`uv`](https://github.com/astral-sh/uv) | 管理依赖、虚拟环境与 Python 版本；提交 `uv.lock`。 |
| Lint + 格式化 | [`ruff`](https://github.com/astral-sh/ruff) | `ruff check` + `ruff format`，替代 `flake8` + `black` + `isort`。 |
| 类型检查 | [`mypy`](https://github.com/python/mypy) / [`pyright`](https://github.com/microsoft/pyright) | 开启 strict。 |
| 测试 | [`pytest`](https://github.com/pytest-dev/pytest) | 配合 `pytest-cov` 覆盖率。 |

- **提交前检查（pre-commit）**：用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理 git hook，在 `lefthook.yml` 的 `pre-commit` 中对暂存文件跑 `ruff check`、`ruff format` 与 `mypy` 等。
