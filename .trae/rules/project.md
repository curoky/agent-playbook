---
description: 搭建项目初期、调整目录结构、配置与环境管理、日志与可观测性时使用
alwaysApply: false
---

# 项目与工程化

> 本文件是主规范「项目与工程化」领域的明细，多在搭项目初期或调整结构/配置/日志时查阅。

## 1. 项目结构与组织

**核心原则**：结构按功能而非技术分层组织；目录可预测、职责单一、入口清晰。

- **标准目录布局**：源码放 `src/`、脚本放 `scripts/`、文档放 `docs/`；配置文件统一放仓库根。测试就近放 `*.test.ts` / `test_*.py` 或集中放 `tests/`，团队内统一其一。Go 用社区惯例布局：入口放 `cmd/<app>/main.go`，私有代码放 `internal/`，可复用库放 `pkg/`，测试文件 `*_test.go` 与源码同包就近放置。C++ 用 `src/`（实现）+ `include/<project>/`（公共头）+ `tests/`（测试），每个目录放 `BUILD.bazel` 声明 target，仓库根放 `MODULE.bazel`/`.bazelrc`/`.bazelversion`，公共头与实现分离，第三方依赖经 Bazel（`bazel_dep`）引入不入库。
- **按功能分模块**：优先按业务领域/功能切分目录（feature-based），而非把 controllers/services/utils 等技术层各自堆成大杂烩（Go 中尤其避免 `util`/`common`/`base` 等无意义包，按职责命名包；C++ 中按职责划分命名空间与目录，避免 `utils.h` 大杂烩头文件）。
- **单包 vs monorepo**：单一职责项目用单包；多个可独立发布的包用 monorepo（JS 用 `pnpm` workspace，Python 用 `uv` workspace，Go 用 module + `go.work` 多模块工作区，C++ 用单一 Bazel workspace + 多 `BUILD.bazel`（按目录拆 `cc_library`/`cc_binary` target），跨包用 `//path/to:target` 标签引用，库 target 设 `visibility` 控制可见性）。
- **文件职责单一**：一个文件聚焦一个模块/类/功能；文件过大（经验值数百行）即按职责拆分（C++ 中头文件 `.hpp` 与实现 `.cpp` 配对、一个主要类一对文件）。
- **入口清晰**：明确程序入口（`src/index.ts` / `src/main.py` 或 `__main__.py` / Go `cmd/<app>/main.go` / C++ `src/main.cpp`），对外 API 通过入口/`index`/包导出统一暴露（C++ 通过 `include/<project>/` 下的公共头或 C++20 module 接口单元统一暴露），配合「编码实践 · 函数与模块设计」的「明确公共 API」。

## 2. 配置与环境管理

**核心原则**：配置集中声明、启动即校验、按环境注入；代码不散落读取裸环境变量。

- **配置集中且校验**：所有配置集中定义并在启动时校验——JS 用 `zod` 解析 `process.env`，Python 用 `pydantic-settings`，Go 用 `envconfig`/`viper` 映射到 struct 并校验，C++ 把配置解析到强类型 struct（来源用 `toml++`/`CLI11`/环境变量）并在启动时校验；校验失败立即 fail-fast 报错退出。
- **分层来源**：优先级「默认值 < 配置文件 < 环境变量」；多环境（dev/staging/prod）通过环境变量切换，不在代码里散落 `if env === 'prod'` 判断。
- **`.env` 约定**：本地用 `.env`（不提交），仓库提供 `.env.example` 列出所有必填项与说明。
- **必填与默认**：明确区分必填项（缺失即报错）与可选项（有合理默认值）；类型在 Schema / struct tag 中声明。
- **配置不可变**：启动后配置视为只读，集中通过一个 typed config 对象访问，不在各处直接读 `process.env` / `os.environ` / `os.Getenv`。

## 3. 日志与可观测性

**核心原则**：日志是排障的一手证据；用结构化日志、合理分级，带足上下文且不泄漏敏感信息。

- **用结构化日志库**：JS 用 `pino`，Python 用 `loguru`，Go 用标准库 `log/slog`，C++ 用 `spdlog`；禁止用 `console.log` / `print` / `fmt.Println` / `std::cout` 做正式日志（仅临时调试可用，提交前清理）。
- **日志级别约定**：`debug`（开发细节）/`info`（关键流程节点）/`warn`（可恢复异常）/`error`（失败需关注）；生产默认 `info`。
- **结构化字段**：输出 JSON 结构化日志并带上下文字段（请求 ID、用户 ID、模块名），便于检索；不靠拼接字符串。
- **不在热路径滥打日志**：避免在循环/高频调用里打 `info`，防止刷屏与性能损耗。
- **错误日志带上下文**：记录错误时带上原始错误与堆栈（配合「编码实践 · 类型安全与错误处理」的「保留上下文」）。
- **不记敏感信息**：日志不输出口令、令牌、个人隐私数据。
