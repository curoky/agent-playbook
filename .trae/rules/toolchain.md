---
description: 搭建项目脚手架、配置包管理/Lint/格式化/类型检查/测试/构建/pre-commit 工具链时使用
alwaysApply: false
---

# 统一工具链（跨语言）

> 本文件是主规范「技术栈与工具基线 · 统一工具链」的**跨语言通用约定**，在搭项目脚手架、配工具时查阅。**各语言的具体工具表与 pre-commit 命令**见 `languages/` 下分语言文件的「§10 工具链」：[`js.md`](./languages/js.md)、[`python.md`](./languages/python.md)、[`go.md`](./languages/go.md)、[`cpp.md`](./languages/cpp.md)（编辑对应源文件时自动生效）。

## 核心原则

- 用统一现代的工具链，配置入库，本地与 CI 命令一致、结果可复现。
- 优先选速度快、配置少、能合并多职责的工具（如 `biome`、`ruff` 一体化 Lint + 格式化）。

## 通用要求

- **配置文件必须入库**：`package.json`、`pyproject.toml`、`tsconfig.json`、`biome.json`、`go.mod`、`.golangci.yml`、`MODULE.bazel`、`BUILD.bazel`、`.bazelrc`、`.bazelversion`、`.clang-format`、`.clang-tidy` 等。
- **锁文件/校验入库**：`pnpm-lock.yaml`、`uv.lock`、`go.sum`、`MODULE.bazel.lock` 等一并提交，保证依赖可复现。
- **关键检查可一键运行**，并在 CI 与 pre-commit 强制执行。
- **格式不进 review**：缩进、引号、分号、import 排序全部交给格式化工具处理，review 中不讨论格式。

## 提交前检查（pre-commit）与 CI 一致性

- 各语言的 pre-commit 钩子与命令见对应 `languages/{语言}.md` 的「§10 工具链」（JS/TS 用 `husky` + `lint-staged`，Python/Go/C++ 用 `pre-commit` 框架或 Git 钩子/Makefile）。
- **CI 中重复执行同一套检查**（格式化校验、Lint/静态分析、类型检查/vet、测试），确保与本地、pre-commit 完全一致，避免「本地过、CI 挂」。
