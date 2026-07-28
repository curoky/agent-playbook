---
description: 编写 Python 代码，或为 Python 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.py,*.pyi,pyproject.toml,.python-version,uv.lock,ruff.toml
alwaysApply: false
---

# Python 规则

## 0. 基线

- 全量类型注解；用 `mypy` 或 `pyright` 做静态检查。
- 新项目用官方最新稳定 Python（落地时查官方发布页核实，不用 pre-release）；`pyproject.toml` 声明 `requires-python` 下限，`.python-version` 锁定该稳定版最新 patch。用 `uv` 管理环境与依赖，提交 `.python-version`、`uv.lock`。
- 现代语法优先：`match`/`case`、`list[int]`、`X | None`、`type` 别名、f-string、t-string（需结构化模板时）、`pydantic` 模型、`:=`、`pathlib`、`with`、推导式；可读性优先。
- 数据模型默认 `pydantic`；无需校验/序列化且要求轻量时用 `dataclasses`。
- 禁止：`from x import *`、可变默认参数、旧式 `typing.List/Dict/Optional`、用 `os.path` 拼路径、裸 `except:`、裸 `Any`。

## 1. 风格与模块

- 命名：变量/函数/模块 `snake_case`，类 `PascalCase`，常量 `UPPER_SNAKE_CASE`；布尔用 `is`/`has` 前缀。
- 魔法值提取为有名常量或 `Enum`；格式交给 `ruff format`。
- 函数超过一屏、出现阶段性注释、或名称需用 `and` 描述时拆分。
- 参数超过 3 个用关键字参数加 `pydantic` 模型；轻量无校验场景可用 `dataclass`；避免布尔陷阱参数。
- 公共 API 用 `__all__` 或下划线前缀标记私有。
- 高层逻辑依赖 `Protocol`/ABC 并由外部注入实现；避免循环依赖。

## 2. 类型、错误、资源

- 裸 `Any` 禁止；用具体类型、`Protocol` 或泛型。
- API 响应、用户输入、配置、环境变量等边界用 `pydantic` 校验。
- `pydantic` 模型默认 `model_config = ConfigDict(extra="forbid")`；确需透传额外字段时注明原因。
- 互斥状态用 `Literal` + `match`；可能缺失写成 `T | None`。
- 可预期失败用返回值表达，不用异常做控制流；不引入 `Result`/`Either` 三方库。
- 结果形态：结构化 `pydantic`/`dataclass`（如 `ok`/`code`/`error`/`value`）、`T | None`、或 `(value, error)`。
- 异常只表示不可恢复/意外错误；捕获具体异常；边界统一转换为返回值形态。
- 重抛用 `raise X from e`；资源释放用 `with`。

## 3. 异步与并发

- 统一 `asyncio`；异步代码中不调用阻塞 I/O。
- IO 密集用 `asyncio`/线程；CPU 密集默认 `ProcessPoolExecutor`，解释器隔离适用时用 `InterpreterPoolExecutor`。free-threaded CPython 仅在依赖兼容且 benchmark 证明有收益时采用。
- 独立任务用 `asyncio.gather` 或 `TaskGroup`；批量并发用 `asyncio.Semaphore`。
- Task 失败必须被处理；长任务用 `asyncio.timeout` 和取消。
- 大批量数值/表格计算优先 `numpy`/`polars` 向量化。

## 4. 注释与测试

- 注释写意图、约束、权衡、坑；不复述代码。公共 API 用 docstring，配合类型注解，不重复类型。
- 改代码同步改注释；删被注释掉的死代码；`TODO`/`FIXME`/`HACK` 附负责人或 issue。
- 测试用 `pytest` + `pytest-cov`。
- 测公共行为和边界，不测私有实现；外部依赖 mock/stub/fake，时间用可注入时钟。
- 修 bug 先写复现用例；覆盖率是参考，不是目标。

## 5. 安全与日志

- 外部输入先用 `pydantic`/validator 校验，按输出上下文转义。
- SQL 用参数化或 `sqlalchemy`；子进程用 `subprocess` 参数列表；禁止 `shell=True`。
- 密码用 `argon2`/`bcrypt`；随机数/令牌用 `secrets`，不用 `random`。
- 应用/脚本日志用 `loguru`；被 import 的库用标准 `logging`。
- `print` 只作临时调试，提交前清理。级别：`debug`/`info`/`warn`/`error`；生产默认 `info`。
- 日志带请求 ID、用户 ID、模块名等字段；热路径避免高频 `info`；错误日志带原始错误/堆栈；禁止记录口令、令牌、隐私数据。

## 6. 库选型

- 标准库够用时不引第三方；`pathlib`、`zoneinfo`、`subprocess`、`logging`、`secrets` 优先。

| 场景 | 默认 | 条件 |
| --- | --- | --- |
| 路径 | 标准库 `pathlib` | 必须；用 `Path`。 |
| CLI | `typer` | 必须；替代 `argparse`。 |
| 数据校验/模型 | `pydantic` | 必须；v2。 |
| 配置 | `pydantic-settings` | 必须；环境变量/`.env` 加载并校验。 |
| HTTP | `httpx` | 必须；同步/异步统一；维护老代码可沿用 `requests`；不新引入 `aiohttp`，除非需要特定服务端能力。 |
| 日期/时间 | 标准库 `datetime` + `zoneinfo` / `pendulum` | 简单场景标准库；链式 API、区间/解析需求用 `pendulum`。 |
| 终端输出 | `rich` | 按需；表格、进度条、彩色输出。 |
| 日志 | `loguru` / `logging` | 应用/脚本用 `loguru`；库用 `logging`。 |
| 测试 | `pytest` | 必须。 |
| 重试 | `tenacity` | 必须；退避、超时、条件。 |
| Web/API | `fastapi` | 必须；配 `pydantic` 和 async。 |
| 包/环境 | `uv` | 必须。 |
| Lint/格式化 | `ruff` | 必须；`ruff check` + `ruff format`。 |
| 类型检查 | `mypy` / `pyright` | 必须；CI 严格门禁偏 `mypy`，编辑器反馈偏 `pyright`。 |
| ORM | `sqlalchemy` / `sqlmodel` | 必须；复杂查询用 `sqlalchemy` 2.0，FastAPI 模型复用用 `sqlmodel`，轻量只读脚本可用标准库 `sqlite3`。 |
| 迁移 | `alembic` | 必须。 |
| DataFrame | `polars` / `pandas` | 新项目性能优先 `polars`；既有 pandas 生态用 `pandas`。 |
| 任务队列 | `taskiq` / `celery` | asyncio-native、类型友好用 `taskiq`；成熟生态、多 broker/beat/复杂路由用 `celery`；存量 `arq` 仅维护或迁移。 |
| 子进程 | 标准库 `subprocess` | 参数列表；不用 `shell=True`。 |
| JSON | 标准库 `json` / `orjson` | 默认标准库；序列化是热点时用 `orjson`。 |
| 异步编排 | 标准库 `asyncio` | `gather`/`TaskGroup`/`timeout`；限流用 `Semaphore`。 |
| 进程内缓存 | `cachetools` | 按需；标准库 `functools.cache/lru_cache` 不够时用。 |
| 密码哈希 | `argon2-cffi` | 必须；令牌用 `secrets`。 |
| ASGI 运行 | `uvicorn` / `granian` | 默认用 `uvicorn`，多进程直接用 `uvicorn --workers`；现有 Gunicorn 部署用独立 `uvicorn-worker`，不用已废弃的 `uvicorn.workers`；需要 HTTP/2 或 benchmark 证明有收益时评估 `granian`。 |
| Redis | `redis` | 按需；支持 asyncio。 |
| 数值 | `numpy` | 按需；高层分析配 `polars`/`pandas`。 |
| CLI 交互 | `questionary` | 按需；纯展示进度用 `rich`。 |

## 7. 工具链

| 用途 | 工具 |
| --- | --- |
| 包/环境/版本 | `uv`，提交 `uv.lock`。 |
| Lint/格式化 | `ruff`，`ruff check` + `ruff format`。 |
| 类型检查 | `mypy` / `pyright`，开启 strict。 |
| 测试 | `pytest` + `pytest-cov`。 |

- pre-commit 用 `lefthook` 对暂存 Python 文件跑 `ruff check` 与 `ruff format --check`；CI 跑全项目 `ruff check`、`ruff format --check`、strict `mypy`/`pyright` 与 `pytest`。
