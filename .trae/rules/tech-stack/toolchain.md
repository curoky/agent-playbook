---
description: 搭建项目脚手架、配置包管理/Lint/格式化/类型检查/测试/构建/pre-commit 工具链时使用
alwaysApply: false
---

# 统一工具链

> 本文件是主规范「技术栈与工具基线 · 统一工具链」的明细，在搭项目脚手架、配工具时查阅。
>
> **核心原则**：用统一现代的工具链，配置入库，本地与 CI 命令一致、结果可复现。
> **通用要求**：工具配置文件（`package.json`、`pyproject.toml`、`tsconfig.json`、`biome.json`、`go.mod`、`.golangci.yml` 等）必须入库；关键检查可一键运行，并在 CI 与 pre-commit 强制执行；优先选速度快、配置少、能合并多职责的工具。

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

## Go

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 依赖 / 版本管理 | 标准 `go mod` + `toolchain` 指令 | 提交 `go.mod` 与 `go.sum`；`go mod tidy` 保持依赖整洁。 |
| 格式化 | `gofmt` / [`goimports`](https://pkg.go.dev/golang.org/x/tools/cmd/goimports) | `goimports` 兼做 import 分组排序；格式不入 review 讨论。 |
| Lint 聚合 | [`golangci-lint`](https://github.com/golangci/golangci-lint) | v2.x；`.golangci.yml` 入库，聚合 `govet`、`staticcheck`、`errcheck` 等。 |
| 静态检查 | `go vet` / [`staticcheck`](https://github.com/dominikh/go-tools) | `go vet` 基础检查；`staticcheck` 已含于 `golangci-lint`。 |
| 测试 + 覆盖率 | 标准 `go test` | `go test -race -cover ./...`，开启竞态检测。 |
| 漏洞扫描 | [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | `govulncheck ./...`，CI 强制。 |
| 构建 | 标准 `go build` | 交叉编译用 `GOOS`/`GOARCH`；发布可配 [`goreleaser`](https://github.com/goreleaser/goreleaser)。 |

## 提交前检查（pre-commit）

- JS/TS：用 [`husky`](https://github.com/typicode/husky) + [`lint-staged`](https://github.com/lint-staged/lint-staged) 在提交前对暂存文件跑 `biome` 与 `tsc`。
- Python：用 [`pre-commit`](https://github.com/pre-commit/pre-commit) 框架挂载 `ruff`、`mypy` 等钩子。
- Go：用 `pre-commit` 框架或 Makefile 在提交前跑 `gofmt -l`/`goimports`、`go vet`、`golangci-lint run`、`go test`。
- CI 中重复执行同一套检查（格式化校验、Lint、类型检查/vet、测试），确保与本地一致。
