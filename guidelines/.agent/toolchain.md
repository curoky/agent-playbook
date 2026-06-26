# 统一工具链

> 本文件是主规范「技术栈与工具基线 · 统一工具链」的明细，在搭项目脚手架、配工具时查阅。
>
> **核心原则**：用统一现代的工具链，配置入库，本地与 CI 命令一致、结果可复现。
> **通用要求**：工具配置文件（`package.json`、`pyproject.toml`、`tsconfig.json`、`biome.json` 等）必须入库；关键检查可一键运行，并在 CI 与 pre-commit 强制执行；优先选速度快、配置少、能合并多职责的工具。

## JavaScript / TypeScript

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包管理 | [`pnpm`](https://github.com/pnpm/pnpm) | 原生支持 workspace；提交 `pnpm-lock.yaml`。 |
| Lint + 格式化 | [`biome`](https://github.com/biomejs/biome) | 一体化；需丰富插件时退回 `eslint` + `prettier`。 |
| 类型检查 | `tsc --noEmit` | `strict: true`。 |
| 测试 | [`vitest`](https://github.com/vitest-dev/vitest) | 统一单测与覆盖率。 |
| 构建 / 打包 | [`tsup`](https://github.com/egoist/tsup) / [`tsdown`](https://github.com/rolldown/tsdown) | 库用零配置打包；应用按框架自带构建（Vite 等）。 |
| 直接运行 TS | [`tsx`](https://github.com/privatenumber/tsx) | 免编译执行 `.ts`。 |

## Python

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包 / 环境 / 版本管理 | [`uv`](https://github.com/astral-sh/uv) | 管理依赖、虚拟环境与 Python 版本；提交 `uv.lock`。 |
| Lint + 格式化 | [`ruff`](https://github.com/astral-sh/ruff) | `ruff check` + `ruff format`，替代 `flake8` + `black` + `isort`。 |
| 类型检查 | [`mypy`](https://github.com/python/mypy) / [`pyright`](https://github.com/microsoft/pyright) | 开启 strict。 |
| 测试 | [`pytest`](https://github.com/pytest-dev/pytest) | 配合 `pytest-cov` 覆盖率。 |

## 提交前检查（pre-commit）

- JS/TS：用 [`husky`](https://github.com/typicode/husky) + [`lint-staged`](https://github.com/lint-staged/lint-staged) 在提交前对暂存文件跑 `biome` 与 `tsc`。
- Python：用 [`pre-commit`](https://github.com/pre-commit/pre-commit) 框架挂载 `ruff`、`mypy` 等钩子。
- CI 中重复执行同一套检查（格式化校验、Lint、类型检查、测试），确保与本地一致。
