---
description: 为 C++ 项目做技术选型、引入第三方库、或在多个候选库间抉择时使用
globs: *.cpp,*.cc,*.cxx,*.hpp,*.hh,*.hxx,*.h,*.ixx,*.cppm
alwaysApply: false
---

# C++ 库选型

> 本文件是「技术栈与工具基线 · 优先复用成熟的开源组件」的 C++ 明细。基线为 C++23/20。
>
> **选型标准**（库须同时满足）：现代化（支持 C++20/23、提供 Bazel 模块或可被 bzlmod 引入）、主流、积极维护。
> **标准库优先**：`<memory>`（智能指针）、`<optional>`、`<variant>`、`<expected>`（C++23）、`<chrono>`、`<filesystem>`、`<span>`、`<string_view>`、`<ranges>`、`<algorithm>`、`<random>`、并发原语（`<thread>`/`<mutex>`/`<atomic>`）等够用时不引第三方。
> **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件除非用户手动指定，否则不主动引入；确需引入先说明风险并请用户确认。引入务必走 Bazel（`MODULE.bazel` 声明 `bazel_dep`、`MODULE.bazel.lock` 锁版本），避免手动 vendoring。

## 速查表

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| 包管理 / 构建 | [`Bazel`](https://bazel.build/)（bzlmod） | 必须 | 用 `MODULE.bazel` 声明 `bazel_dep` 引入依赖，依赖优先取自 [Bazel Central Registry](https://registry.bazel.build/)；提交 `MODULE.bazel.lock` 锁版本，未收录的库用 `git_override`/`http_archive`。 |
| 单元测试 | [`Catch2`](https://github.com/catchorg/Catch2) | 必须 | header-only、零配置、BDD 风格；通过 `bazel test //...` 运行。需 mock 时配 [`trompeloeil`](https://github.com/rollbear/trompeloeil)。 |
| 基准测试 | [`google/benchmark`](https://github.com/google/benchmark) | 按需 | 微基准测试，配合性能优化。 |
| 格式化 / 输出 | [`fmt`](https://github.com/fmtlib/fmt) | 必须 | 默认用 `fmt::format`/`fmt::print`；特性全、跨编译器一致，`std::format` 本即源自 `fmt`。 |
| 日志 | [`spdlog`](https://github.com/gabime/spdlog) | 必须 | 快速、结构化、基于 `fmt`；替代手写 iostream 日志。 |
| JSON | [`nlohmann/json`](https://github.com/nlohmann/json) / [`glaze`](https://github.com/stephenberry/glaze) | 必须 | 易用优先用 `nlohmann/json`；极致性能/反射式序列化用 `glaze`。 |
| HTTP 客户端 | [`cpr`](https://github.com/libcpr/cpr) | 必须 | 基于 libcurl 的现代封装，API 友好。 |
| HTTP / 网络服务 | [`Boost.Asio`](https://github.com/boostorg/asio) / [`Drogon`](https://github.com/drogonframework/drogon) | 必须 | 底层异步 I/O 用 `Asio`；需完整 Web 框架用 `Drogon`。 |
| 命令行解析 | [`CLI11`](https://github.com/CLIUtils/CLI11) | 必须 | header-only，类型安全，子命令支持好。 |
| 配置文件 | [`toml++`](https://github.com/marzer/tomlplusplus) / [`yaml-cpp`](https://github.com/jbeder/yaml-cpp) | 按需 | TOML 用 `toml++`，YAML 用 `yaml-cpp`，JSON 配置复用 `nlohmann/json`。 |
| 错误处理 | 标准库 `std::expected`（C++23）/ [`tl::expected`](https://github.com/TartanLlama/expected) | 标准库 | C++23 用标准库；C++20 退回 header-only 的 `tl::expected`。 |
| 通用工具 / 缺失补全 | [`abseil`](https://github.com/abseil/abseil-cpp)（absl） | 按需 | 容器（`flat_hash_map` 等）、字符串、时间、同步等增强；与标准库重叠部分优先标准库。Google 系库（gRPC 等）的共同基础。 |
| 高性能基础库 | [`folly`](https://github.com/facebook/folly) | 按需 | Facebook 的核心 C++ 库：高性能容器、字符串、`Future`/`coro`、并发原语等；体量大、依赖重，仅在确需其能力（高并发服务端）时引入。 |
| 异步网络框架 | [`wangle`](https://github.com/facebook/wangle) | 按需 | 基于 `folly` 的 C++ 网络应用框架（pipeline/服务端骨架），构建高性能 RPC/服务端时用；依赖 `folly`。 |
| RPC（Thrift） | [`fbthrift`](https://github.com/facebook/fbthrift) | 按需 | Facebook 的 Thrift 实现，支持 Thrift IDL、异步与流式；依赖 `folly`/`wangle`，适合既有 Thrift 生态。 |
| RPC（gRPC） | [`grpc`](https://github.com/grpc/grpc) | 必须 | 跨语言 RPC 事实标准，配 Protocol Buffers；新建跨语言服务默认选它，依赖 `absl`/`protobuf`。 |
| 数据库 / SQL | [`sqlite_orm`](https://github.com/fnc12/sqlite_orm) / [`SQLiteCpp`](https://github.com/SRombauts/SQLiteCpp) | 必须 | SQLite 嵌入式；服务端 DB 用厂商官方 C++ 驱动。 |
| 加密 / 哈希 | [`libsodium`](https://github.com/jedisct1/libsodium) / OpenSSL | 必须 | 通用加密优先 `libsodium`（API 不易误用）；需 TLS/兼容生态用 OpenSSL。 |
| 协程 / 异步 | 标准库 `<coroutine>` + [`cppcoro`](https://github.com/lewissbaker/cppcoro) | 按需 | C++20 协程基础设施仍薄，复杂异步可借 `cppcoro` 或 `Asio` 协程支持。 |
| 反射 / 序列化（高性能） | [`glaze`](https://github.com/stephenberry/glaze) | 按需 | 编译期反射式 JSON/结构体序列化。 |
| 数值 / 线性代数 | [`Eigen`](https://gitlab.com/libeigen/eigen) | 按需 | header-only 矩阵/线代库。 |
| 进程间 / 协程调度 | [`Boost`](https://github.com/boostorg/boost) | 按需 | 标准库缺口的成熟补充；只引用到的子库，不整包依赖。 |

## 选型判据（多候选时如何选）

- **测试 mock**：`Catch2` 为默认测试框架（header-only、零配置、BDD 风格，`bazel test` 直接跑）；需要 mock 时配 `trompeloeil`（与 Catch2 配合好），不必为 mock 切到其他框架。
- **格式化 `fmt` vs 标准库 `<format>`**：默认用 `fmt`，特性最全、跨编译器行为一致、含彩色输出与编译期检查；标准库 `std::format`/`std::print` 本就源自 `fmt`，仅在追求零依赖且目标编译器已完整支持时才考虑退回标准库。
- **JSON `nlohmann/json` vs `glaze`**：默认 `nlohmann/json`（API 直观、文档全、生态广），**易用性优先**；当 **JSON 解析/序列化是性能热点**、且结构体已知时用 `glaze`（编译期反射、零拷贝、快一个量级）。
- **错误处理 `std::expected` vs 异常 vs 错误码**：库的可预期失败（解析、查找、校验）优先 `std::expected<T, E>`（C++23；C++20 用 `tl::expected`），让调用方在类型上必须处理；**真正异常、不可恢复**才 `throw`；避免裸错误码（`int` 返回 + out 参数）这类易忽略的 C 风格。
- **网络 `Boost.Asio` vs `Drogon` vs `cpr`**：只做**HTTP 客户端请求**用 `cpr`（最简单）；需要**底层 TCP/UDP、自定义协议、协程异步**用 `Asio`；需要**完整 HTTP 服务端框架（路由、ORM、模板）**用 `Drogon`。
- **加密 `libsodium` vs OpenSSL**：新代码优先 `libsodium`（API 简洁、默认安全、难以误用）；必须做 **TLS、X.509、或对接既有 OpenSSL 生态**时用 OpenSSL，不自行实现加密原语。
- **RPC `grpc` vs `fbthrift`**：新建**跨语言**服务默认 `grpc`（生态最广、配 protobuf、社区与工具链成熟）；仅在**对接既有 Thrift/Facebook 生态**或需 fbthrift 特有能力（与 `folly`/`wangle` 深度整合的异步/流式）时用 `fbthrift`，并接受其 `folly`/`wangle` 重依赖。
- **是否引入 `folly`/`wangle` 与 `Boost`/`abseil`**：仅当标准库确有缺口时引入，且**只依赖用到的子库**，不整包拉入；与标准库重叠的功能（智能指针、`optional`、`filesystem`）一律用标准库。`folly`/`wangle` 体量大、编译重、依赖链长，仅在**高并发服务端确需其性能/能力**时引入，普通项目优先 `abseil` 或标准库。

> 注：以上为截至 2026-06 的推荐默认项。项目已有等价成熟方案则沿用，保持技术栈一致；定期复核维护状态，及时替换停更依赖。工具链（Bazel / clang-tidy / sanitizers / CI）见 [`toolchain.md`](./toolchain.md)。
