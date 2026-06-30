---
description: 编写 Python 代码时的编码实践明细（命名、类型与错误、异步、测试、安全等的 Python 特有写法）
globs: *.py
alwaysApply: false
---

# 编码实践 · Python

> 本文件是 [`common.md`](./common.md) 的 Python 明细，列出各主题在 Python 下的特有写法；通用核心原则见 `common.md`，版本基线总表见 [`main.md`](../main.md)。

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

## 6. 注释与文档

- **公共 API 文档**：用 docstring（约定如 Google/NumPy 风格，配合类型注解，不在 docstring 里重复类型）。

## 7. 测试规范

- **框架**：用 `pytest`，配合 `pytest-cov` 覆盖率。
- **隔离与确定性**：外部依赖用 mock/stub/fake，时间用可注入的时钟。

## 8. 安全编码

- **校验并转义输入**：外部输入先用 `pydantic`/`validator` 校验再使用；按输出上下文转义防注入。
- **杜绝注入**：SQL 用参数化或 ORM（`sqlalchemy`），禁止拼接 SQL；执行子进程用 `subprocess` 传参数数组，不用 `shell=True`。
- **安全使用加密**：密码用 `argon2`/`bcrypt` 哈希（不用 MD5/SHA1）；随机数用 `secrets`，不用 `random`。
