---
description: 搭建项目初期、调整目录结构、配置与环境管理、日志与可观测性时使用
alwaysApply: false
---

# 项目与工程化

> 搭项目初期或调整结构、配置、日志时查阅。

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

## 3. 日志与可观测性

**核心原则**：用结构化日志、合理分级，带足上下文且不泄漏敏感信息。

- **用结构化日志库**：JS 用 `pino`，Python 用 `loguru`，Go 用标准库 `log/slog`，C++ 用 `spdlog`；禁止用 `console.log` / `print` / `fmt.Println` / `std::cout` 做正式日志（仅临时调试可用，提交前清理）。
- **日志级别约定**：`debug`（开发细节）/`info`（关键流程节点）/`warn`（可恢复异常）/`error`（失败需关注）；生产默认 `info`。
- **结构化字段**：输出 JSON 结构化日志并带上下文字段（请求 ID、用户 ID、模块名）；不靠拼接字符串。
- **不在热路径滥打日志**：避免在循环/高频调用里打 `info`，防止刷屏与性能损耗。
- **错误日志带上下文**：记录错误时带上原始错误与堆栈（配合「编码实践 · 类型安全与错误处理」的「保留上下文」）。
- **不记敏感信息**：日志不输出口令、令牌、个人隐私数据。
