---
description: 为 Python 项目做技术选型、引入第三方库、或在多个候选库间抉择时使用
globs: *.py,*.pyi
alwaysApply: false
---

# Python 库选型

> 本文件是「技术栈与工具基线 · 优先复用成熟的开源组件」的 Python 明细。
>
> **选型标准**（库须同时满足）：现代化、主流、积极维护。
> **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件除非用户手动指定，否则不主动引入；确需引入先说明风险并请用户确认。
> **引入判定**：
>
> - **必须**：能大幅简化代码或 API 明显更好、更不易出错（如 `pydantic`、`typer`），作为默认选择。
> - **按需**：与标准库差别不大、仅有性能或便利收益（如 `orjson`），仅在确有需求时引入。
> - **标准库优先**：`pathlib`、`zoneinfo`、`dataclasses`、`subprocess`、`logging`、`secrets` 等够用时不引第三方。

## 速查表

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

## 选型判据（多候选时如何选）

- **ORM `sqlalchemy` vs `sqlmodel`**：通用、复杂查询、需要完全控制用 `sqlalchemy` 2.0；项目本就用 `fastapi`、希望「一个模型同时当 ORM 表和 API schema」用 `sqlmodel`（它是 `sqlalchemy` + `pydantic` 的薄封装，复杂查询仍会落回 sqlalchemy）。轻量只读脚本可直接用标准库 `sqlite3`。
- **DataFrame `polars` vs `pandas`**：新项目、看重性能与内存、列式/惰性计算用 `polars`；**必须对接既有 `pandas` 生态**（如 `scikit-learn`、绘图库、同事代码）时用 `pandas`，不要为「更快」强行迁移既有分析栈。
- **任务队列 `celery` vs `arq`**：纯 asyncio 应用、想要轻量、Redis 即可用 `arq`；需要**成熟生态、多 broker、定时任务（beat）、复杂路由/重试**用 `celery`。
- **日期 `pendulum` vs 标准库 `datetime`+`zoneinfo`**：Python 3.9+ 标准库 `zoneinfo` 已能处理时区，简单场景直接用标准库；需要**更顺手的链式 API、时长/区间运算、解析**时才引 `pendulum`。
- **日志 `loguru` vs 标准库 `logging`**：**应用/脚本**追求开箱即用、零配置用 `loguru`；**被别人 import 的库**应保持用标准 `logging`（不替使用方决定日志配置）。
- **类型检查 `mypy` vs `pyright`**：CI 严格门禁、配置稳定用 `mypy`；要**编辑器内实时反馈、对新语法支持更快**（尤其配 VS Code/Pylance）用 `pyright`，两者可并存。
- **JSON `orjson` vs 标准库 `json`**：默认标准库 `json`；仅当**序列化是热点路径**（高 QPS API、大批量）时换 `orjson`（更快、原生支持 `datetime`/`numpy`）。
- **HTTP `httpx` vs `requests`**：新项目一律 `httpx`（同步异步统一、API 与 requests 近似）；维护老代码可沿用 `requests`，不新引入 `aiohttp`（除非需要其特定服务端能力）。

> 注：以上为截至 2026-06 的推荐默认项。项目已有等价成熟方案则沿用，保持技术栈一致；定期复核维护状态，及时替换停更依赖。工具链（`uv` / `ruff` / CI / pre-commit）见 [`toolchain.md`](./toolchain.md)。
