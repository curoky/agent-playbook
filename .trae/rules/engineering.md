---
description: 搭建项目初期、调整目录结构、配置与环境管理、配置包管理/Lint/格式化/类型检查/测试/构建/pre-commit 工具链、锁定语言与工具版本、Git 提交接线、版本发布（SemVer/changelog）、依赖治理、CI/CD 流水线时使用
alwaysApply: false
---

# 工程化（项目结构 · 工具链 · 版本与协作）

> 搭项目、配工具链、发版与治理依赖时查阅。跨语言通用；各语言的具体工具命令、配置/锁文件名、pre-commit 命令见对应语言规范的版本/工具链相关章节（§0 版本锁定与 §工具链节），日志写法见其「日志」节。

## 1. 项目结构与组织

**核心原则**：按功能组织，目录可预测、职责单一、入口清晰。

- **标准目录布局**：源码放 `src/`、脚本放 `scripts/`、文档放 `docs/`；配置文件放仓库根。测试就近放 `*.test.ts` / `test_*.py` 或集中放 `tests/`，团队内统一其一。Go 用 `cmd/<app>/main.go`、`internal/`、`pkg/`、就近 `*_test.go`。C++ 用 `src/` + `include/<project>/` + `tests/`，各目录放 `BUILD.bazel`，根目录放 `MODULE.bazel`/`.bazelrc`/`.bazelversion`，公共头与实现分离，第三方依赖经 Bazel（`bazel_dep`）引入不入库。
- **按功能分模块**：优先按业务领域/功能切分目录，而非 controllers/services/utils 等技术层大杂烩。Go 避免 `util`/`common`/`base` 等无意义包；C++ 按职责划分命名空间与目录，避免 `utils.h` 大杂烩头文件。
- **单包 vs monorepo**：单一职责项目用单包；多个可独立发布的包用 monorepo（JS `pnpm` workspace，Python `uv` workspace，Go module + `go.work`，C++ 单一 Bazel workspace + 多 `BUILD.bazel`）。跨包用 `//path/to:target` 标签引用，库 target 设 `visibility`。
- **文件职责单一**：一个文件聚焦一个模块/类/功能；文件过大（经验值数百行）即按职责拆分（C++ 中头文件 `.hpp` 与实现 `.cpp` 配对、一个主要类一对文件）。
- **入口清晰**：明确入口（`src/index.ts` / `src/main.py` 或 `__main__.py` / Go `cmd/<app>/main.go` / C++ `src/main.cpp`），对外 API 通过入口、`index`、包导出、公共头或 C++20 module 接口单元统一暴露。

## 2. 配置与环境管理

**核心原则**：配置集中声明、启动即校验、按环境注入；代码不散落读取裸环境变量。

- **配置集中且校验**：所有配置集中定义并在启动时校验。JS 用 `zod` 解析 `process.env`，Python 用 `pydantic-settings`，Go 用 `envconfig`/`viper` 映射到 struct，C++ 解析到强类型 struct（`toml++`/`CLI11`/环境变量）；校验失败立即 fail-fast。
- **分层来源**：优先级「默认值 < 配置文件 < 环境变量」；多环境（dev/staging/prod）通过环境变量切换，不在代码里散落 `if env === 'prod'` 判断。
- **`.env` 约定**：本地用 `.env`（不提交），仓库提供 `.env.example` 列出所有必填项与说明。
- **必填与默认**：明确区分必填项（缺失即报错）与可选项（有合理默认值）；类型在 Schema / struct tag 中声明。
- **配置不可变**：启动后配置视为只读，集中通过一个 typed config 对象访问，不在各处直接读 `process.env` / `os.environ` / `os.Getenv`。

## 3. 统一工具链（跨语言）

**核心原则**：用统一现代的工具链，配置入库，本地/pre-commit/CI 命令一致、结果可复现。

- **工具选型偏好**：优先选速度快、配置少、能合并多职责的工具（如 `biome`、`ruff` 一体化 Lint + 格式化）。
- **配置与锁文件入库**：项目的配置文件与锁文件必须提交，保证依赖可复现；具体文件名清单见各语言规范的版本/工具链相关章节。
- **git hook 统一用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理**：`lefthook.yml` 入库，支持并行执行与暂存文件过滤（`{staged_files}` + `glob`），替代 `husky`/`lint-staged`/`pre-commit` 框架/Makefile；`pre-commit` 跑格式/lint/类型/测试，`commit-msg` 挂 `commitlint`（见 §5）。
- **关键检查可一键运行**，并在 CI 与 pre-commit 强制执行。
- **CI 与 pre-commit 命令完全一致**：格式化校验、Lint/静态分析、类型检查/vet、测试与本地、pre-commit 完全一致，避免「本地过、CI 挂」。

**跨语言工具链对照表**（概览；具体命令/配置文件名/flag 见各语言规范的版本/工具链相关章节）：

| 语言 | 包管理 | Lint + 格式化 | 类型 / 静态检查 | 测试 |
| --- | --- | --- | --- | --- |
| JS/TS | `pnpm` | `biome` | `tsc --noEmit` | `vitest` |
| Python | `uv` | `ruff` | `mypy` / `pyright` | `pytest` |
| Go | `go mod` | `gofmt`/`goimports` + `golangci-lint` | `go vet` / `staticcheck` | `go test -race` |
| C++ | Bazel(bzlmod) | `clang-format` | `clang-tidy` | `Catch2` |
| Bash | —（系统） | `shfmt` | `shellcheck` | `bats` |

## 4. 语言与工具版本基线

**核心原则**：用当前主流支持的较新版本，避免 EOL；版本号在配置中显式锁定以保团队一致。锁定方式与推荐/禁止语法见各语言规范 §0。

**版本基线**（「最低」为下限、「推荐」为新项目默认；截至 2026-06，落地按官方最新稳定版校准）：

| 语言 / 项 | 最低版本 | 推荐版本 |
| --- | --- | --- |
| Node.js | 22 LTS | 24 LTS / 最新 26.x |
| TypeScript | 5.9 | 6.0.x（`strict: true`、`target: es2025`、`module: esnext`） |
| Python | 3.12 | 3.14.x |
| Go | 1.25（官方支持最新两个大版本） | 1.26.x |
| C++ 标准 | C++20 | C++23 |
| C++ 编译器 | GCC 12 / Clang 15 / MSVC 19.3x | 最新稳定版（GCC 14+ / Clang 18+） |
| Bazel | 7.x（bzlmod） | 最新（`.bazelversion` 固定） |
| Bash | 4.4 | 5.x（`#!/usr/bin/env bash` + `set -euo pipefail`） |

## 5. 提交规范（接线）

**核心原则**：提交遵循 [Conventional Commits](https://www.conventionalcommits.org/)，使历史可读、可机器解析，并驱动版本与 changelog。提交信息「怎么写」的完整格式见 `git-commit-message.md`；本节只讲工具接线。

- 用 [`commitlint`](https://github.com/conventional-changelog/commitlint) 强制校验（在 `lefthook.yml` 的 `commit-msg` 钩子中挂载）；交互式提交可用 [`commitizen`](https://github.com/commitizen/cz-cli)。
- 提交历史由 Conventional Commits 驱动版本推导（§6）与 changelog 自动生成（§7）。

## 6. 语义化版本（SemVer）

**核心原则**：版本号遵循 [SemVer 2.0.0](https://semver.org/)：`MAJOR.MINOR.PATCH`。

- **MAJOR** 破坏性变更、**MINOR** 向后兼容新功能、**PATCH** 向后兼容修复；预发布用 `-alpha`/`-beta`/`-rc`。
- **由 Conventional Commits 自动推导**：`feat` → minor、`fix` → patch、`!`/`BREAKING CHANGE` → major；不手动随意 bump。
- 版本号唯一来源并与 Git tag（`vX.Y.Z`）一致：JS 看 `package.json`、Python 看 `pyproject.toml`、Go 直接以 Git tag 为准（无独立版本文件）。
- **Go 模块版本特殊约定**：major 版本 ≥ 2 时，模块路径须带 `/vN` 后缀（如 `example.com/foo/v2`）并对应 `vN.x.x` tag，否则下游无法正确升级。

## 7. 变更日志（Changelog）

**核心原则**：维护面向使用者的 `CHANGELOG.md`，遵循 [Keep a Changelog](https://keepachangelog.com/)。

- 按版本分组，分类列出 `Added`/`Changed`/`Fixed`/`Deprecated`/`Removed`/`Security` 并标注日期。
- 由 Conventional Commits **自动生成**：JS/TS 用 [`changesets`](https://github.com/changesets/changesets)（推荐，适合 monorepo）或 `release-please`；Python 用 [`towncrier`](https://github.com/twisted/towncrier) 或 `git-cliff`。
- 破坏性变更须显著标注并说明迁移方式。

## 8. 依赖治理

**核心原则**：依赖**可复现、可追溯、可审计**；锁定版本、定期升级、主动扫漏洞。

- **锁文件必须提交**：JS `pnpm-lock.yaml`、Python `uv.lock`、Go `go.mod` + `go.sum`、C++ `MODULE.bazel` + `MODULE.bazel.lock`（与 §3 一致）；CI 校验一致性（`pnpm install --frozen-lockfile`、`uv sync --locked`、`go mod verify` + `go mod tidy` 后无 diff、`bazel mod deps --lockfile_mode=error`），禁静默更新。
- **版本约束清晰**：直接依赖声明明确范围，运行版本以锁文件为准。

**自动升级**：

- **工具**：统一用 [Renovate](https://github.com/renovatebot/renovate)（跨生态）；纯 GitHub 仓库可用 Dependabot；配置入库。
- **调度**：每周固定窗口批量提 PR（`schedule`），设并发上限（`prConcurrentLimit`）避免 PR 风暴。
- **分级合并**：`patch`/`devDependencies` CI 通过后自动合并；生产 `minor` 至少 1 人评审；`major`/破坏性必须人工评审 + 迁移说明 + 回归。
- **聚合降噪**：非主要版本按生态分组（`groupName`）；锁文件维护（`lockFileMaintenance`）每周单独跑。
- **安全升级优先**：开启 `vulnerabilityAlerts`，安全补丁不受调度限制第一时间提 PR。
- **质量门禁**：所有升级 PR 必须 CI 全绿（含自动合并）才可合并。

**安全审计**：

- **CI 强制扫描**：每次 PR 与主分支扫漏洞，达阈值即阻断。JS/TS 用 `pnpm audit --audit-level=high`（或 `osv-scanner`），Python 用 [`pip-audit`](https://github.com/pypa/pip-audit)（或 `osv-scanner`），Go 用 [`govulncheck ./...`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)（或 `osv-scanner`），C++ 用 [`osv-scanner`](https://github.com/google/osv-scanner) 扫 `MODULE.bazel.lock`。
- **阻断阈值**：`high` 及以上（CVSS ≥ 7.0）须修复或显式豁免；`moderate` 及以下记录跟踪。
- **修复 SLA**：`critical` 24h、`high` 7d、`moderate` 30d 内处理。
- **豁免机制**：无法立即修复时登记白名单（`pip-audit --ignore-vuln`、`pnpm` overrides），注明原因/责任人/复审日期，并经评审。
- **供应链加固**：CI 用最小权限 token；锁文件保证可复现；定期生成 SBOM（如 CycloneDX）。
- **依赖精简**：定期清理未使用依赖（`knip`/`depcheck`、`deptry`、Go `go mod tidy`）；引入新依赖前对照各语言规范「库选型」的选型判据。
- **许可证合规**：避免引入与项目协议冲突的依赖（如 GPL 进闭源），必要时用工具校验。

## 9. CI/CD 流水线

**核心原则**：CI 检查与本地一致、快速反馈、全绿才合并；发布自动化、可复现。

- **必跑检查清单**：安装（锁文件校验）→ 格式校验 → Lint → 类型检查/`go vet` → 测试（带覆盖率，Go 加 `-race`）→ 构建 → 漏洞扫描；任一失败即阻断。
- **与本地一致**：CI 命令与本地、pre-commit 一致（见 §3），避免「本地过、CI 挂」。
- **快速反馈**：拆分并行任务、用缓存缩短时长；快检查（Lint/类型）前置。
- **发布自动化**：合并主分支后由 Conventional Commits 驱动版本与 changelog（`changesets`/`release-please`/`towncrier`），自动打 tag 并发布。
- **最小权限与可复现**：CI 凭据最小权限，安装用 `--frozen-lockfile`/`--locked`。
- **分支保护**：主分支要求 PR + CI 全绿 + 至少 1 人评审，禁止直接推送。
