---
description: 搭建项目脚手架、配置包管理/Lint/格式化/类型检查/测试/构建/pre-commit 工具链时使用
alwaysApply: false
---

# 统一工具链（跨语言）

> 跨语言通用约定。各语言工具表与 pre-commit 命令见 `languages/{js,python,go,cpp,bash}.md` 的「§10 工具链」。

## 核心原则

- 用统一现代的工具链，配置入库，本地/pre-commit/CI 命令一致、结果可复现。
- 优先选速度快、配置少、能合并多职责的工具（如 `biome`、`ruff` 一体化 Lint + 格式化）。

## 通用要求

- **配置文件必须入库**：`package.json`、`pyproject.toml`、`tsconfig.json`、`biome.json`、`go.mod`、`.golangci.yml`、`MODULE.bazel`、`BUILD.bazel`、`.bazelrc`、`.bazelversion`、`.clang-format`、`.clang-tidy`、`lefthook.yml` 等。
- **锁文件/校验入库**：`pnpm-lock.yaml`、`uv.lock`、`go.sum`、`MODULE.bazel.lock` 等一并提交，保证依赖可复现。
- **关键检查可一键运行**，并在 CI 与 pre-commit 强制执行。
- **格式不进 review**：缩进、引号、分号、import 排序全部交给格式化工具处理，review 中不讨论格式。

## 提交前检查（pre-commit）与 CI 一致性

- **git hook 统一用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理**：`lefthook.yml` 入库，支持并行执行与暂存文件过滤 `{staged_files}` + `glob`，替代 `husky`/`lint-staged`/`pre-commit` 框架/Makefile。具体命令见对应语言文件 §10。
- **CI 中重复执行同一套检查**：格式化校验、Lint/静态分析、类型检查/vet、测试与本地、pre-commit 完全一致，避免「本地过、CI 挂」。
