# 版本与协作

> 本文件是主规范「版本与协作」领域的明细，在做提交、发版、配 CI、治理依赖时查阅。

## 1. 提交规范（Conventional Commits）

**核心原则**：提交遵循 [Conventional Commits](https://www.conventionalcommits.org/)，使历史可读、可机器解析，并自动驱动版本与变更日志。

- 格式：`<type>(<scope>): <subject>`，必要时附 body 与 footer。
- 常用 `type`：`feat`（新功能，minor）、`fix`（修复，patch）、`docs`/`style`/`refactor`/`perf`/`test`/`build`/`ci`/`chore`。
- **破坏性变更**：`type` 后加 `!`（如 `feat!:`）或 footer 写 `BREAKING CHANGE:`，触发 major。
- subject 用祈使句、简洁；一次提交聚焦单一逻辑变更。
- 用 [`commitlint`](https://github.com/conventional-changelog/commitlint) 强制校验（配 husky `commit-msg`）；交互式提交可用 [`commitizen`](https://github.com/commitizen/cz-cli)。

## 2. 语义化版本（SemVer）

**核心原则**：版本号遵循 [SemVer 2.0.0](https://semver.org/)：`MAJOR.MINOR.PATCH`。

- **MAJOR** 破坏性变更、**MINOR** 向后兼容新功能、**PATCH** 向后兼容修复；预发布用 `-alpha`/`-beta`/`-rc`。
- 版本号由 Conventional Commits 自动推导，不手动随意 bump。
- 版本号唯一来源：JS 看 `package.json`、Python 看 `pyproject.toml`、Go 以 Git tag `vX.Y.Z` 为准（库无独立版本文件），并与 Git tag（`vX.Y.Z`）一致。
- **Go 模块版本特殊约定**：major 版本 ≥ 2 时，模块路径须带 `/vN` 后缀（如 `example.com/foo/v2`）并对应 `vN.x.x` tag，否则下游无法正确升级。

## 3. 变更日志（Changelog）

**核心原则**：维护 `CHANGELOG.md`，面向使用者，遵循 [Keep a Changelog](https://keepachangelog.com/)。

- 按版本分组，分类列出 `Added`/`Changed`/`Fixed`/`Deprecated`/`Removed`/`Security` 并标注日期。
- 由 Conventional Commits **自动生成**：JS/TS 用 [`changesets`](https://github.com/changesets/changesets)（推荐，适合 monorepo）或 `release-please`；Python 用 [`towncrier`](https://github.com/twisted/towncrier) 或 `git-cliff`。
- 破坏性变更须显著标注并说明迁移方式。

## 4. 依赖治理

**核心原则**：依赖**可复现、可追溯、可审计**；锁定版本、定期升级、主动扫漏洞。

- **锁文件必须提交**：JS `pnpm-lock.yaml`、Python `uv.lock`、Go `go.mod` + `go.sum`；CI 安装校验一致性（`pnpm install --frozen-lockfile`、`uv sync --locked`、`go mod verify` + `go mod tidy` 后无 diff），禁静默更新。
- **版本约束清晰**：直接依赖声明明确范围，运行版本以锁文件为准。

**自动升级**：

- **工具**：统一用 [Renovate](https://github.com/renovatebot/renovate)（跨生态）；纯 GitHub 仓库可用 Dependabot。配置入库。
- **调度**：每周固定窗口批量提 PR（`schedule`），设并发上限（`prConcurrentLimit`）避免 PR 风暴。
- **分级合并**：`patch`/`devDependencies` CI 通过后自动合并（`automerge`）；`minor`（生产）至少 1 人评审；`major`/破坏性必须人工评审 + 迁移说明 + 回归。
- **聚合降噪**：非主要版本按生态分组（`groupName`）；锁文件维护（`lockFileMaintenance`）每周单独跑。
- **安全升级优先**：开启 `vulnerabilityAlerts`，安全补丁不受调度限制第一时间提 PR。
- **质量门禁**：所有升级 PR 必须 CI 全绿（含自动合并）才可合并。

**安全审计**：

- **CI 强制扫描**：每次 PR 与主分支扫漏洞，达阈值即阻断合并。JS/TS 用 `pnpm audit --audit-level=high`（或 `osv-scanner`），Python 用 [`pip-audit`](https://github.com/pypa/pip-audit)（或 `osv-scanner`），Go 用 [`govulncheck ./...`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)（或 `osv-scanner`）。
- **阻断阈值**：`high` 及以上（CVSS ≥ 7.0）须修复或显式豁免；`moderate` 及以下记录跟踪。
- **修复 SLA**：`critical` 24h、`high` 7d、`moderate` 30d 内处理。
- **豁免机制**：无法立即修复时登记白名单（`pip-audit --ignore-vuln`、`pnpm` overrides）并注明原因/责任人/复审日期，须经评审。
- **供应链加固**：CI 用最小权限 token；锁文件保证可复现；定期生成 SBOM（如 CycloneDX）。
- **依赖精简**：定期清理未使用依赖（`knip`/`depcheck`、`deptry`、Go `go mod tidy`）；引入新依赖前对照「优先复用成熟的开源组件」的判定。
- **许可证合规**：避免引入与项目协议冲突的依赖（如 GPL 进闭源），必要时用工具校验。

## 5. CI/CD 流水线

**核心原则**：CI 是质量底线，与本地一致、快速反馈、全绿才合并；发布自动化、可复现。

- **必跑检查清单**：安装（锁文件校验）→ 格式校验 → Lint → 类型检查/`go vet` → 测试（带覆盖率，Go 加 `-race`）→ 构建 → 漏洞扫描；任一失败即阻断。
- **与本地一致**：CI 命令与本地、pre-commit 一致（见 [`toolchain.md`](./toolchain.md)），避免「本地过、CI 挂」。
- **快速反馈**：拆分并行任务、用缓存缩短时长；快检查（Lint/类型）前置。
- **发布自动化**：合并主分支后由 Conventional Commits 驱动版本与 changelog（`changesets`/`release-please`/`towncrier`），自动打 tag 并发布。
- **最小权限与可复现**：CI 凭据最小权限，安装用 `--frozen-lockfile`/`--locked`。
- **分支保护**：主分支要求 PR + CI 全绿 + 至少 1 人评审，禁止直接推送。
