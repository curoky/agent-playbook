---
description: 编写 C++ 代码，或为 C++ 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.cpp,*.cc,*.cxx,*.hpp,*.hh,*.hxx,*.h,*.ixx,*.cppm
alwaysApply: false
---

# C++ 规则

## 0. 基线

- 基线 C++23/20；优先 RAII、值语义、移动语义，避免手动资源管理。
- `.bazelrc` 固定 `build --cxxopt=-std=c++23` 或 per-target `copts`；`.bazelversion` 锁 Bazel；`MODULE.bazel` + `MODULE.bazel.lock` 锁依赖。
- 现代语法优先：智能指针、`auto`、结构化绑定、范围 `for`、`if`/`switch` 初始化、`std::optional`、`std::variant`、`std::expected`、`std::string_view`、`std::span`、`constexpr`/`consteval`、Concepts、Ranges、`fmt`、`<chrono>`；可读性优先。
- 禁止：裸 `new`/`delete` 或 owning 裸指针、C 风格强转、头文件/全局 `using namespace std;`、宏当常量/函数、裸数组和不安全 C API、未初始化变量、头文件定义非 `inline` 非模板函数/全局变量。

## 1. 风格与模块

- 类型/类 `PascalCase`；函数/变量跟随既有项目（常见 `snake_case` 或 `camelCase`）；常量/`enum class` 枚举值 `PascalCase` 或 `kCamelCase`；宏 `UPPER_SNAKE_CASE`；成员变量统一后缀/前缀；命名空间小写。
- 布尔用 `is`/`has` 前缀；魔法值提取为 `constexpr` 或 `enum class`。
- 格式用 `clang-format`。
- 函数超过一屏、出现阶段性注释、或名称需用 `and` 描述时拆分。
- 参数超过 3 个用 config struct + 聚合初始化；只读入参用 `const&`/`std::string_view`/`std::span`，转移所有权用值 + `std::move`；避免布尔陷阱参数。
- 头文件只暴露公共声明；实现细节放 `.cpp`、`detail` 或匿名命名空间；类成员默认 `private`；接口优先 C++20 modules 的 `export`。
- 依赖倒置用抽象基类/纯虚接口，或模板 + Concepts；由外部注入实现。

## 2. 类型、错误、资源

- 避免 `void*`、无约束模板、`std::any`；用具体类型、`std::variant`、Concepts。
- 外部输入显式校验后转强类型领域对象；缓冲区/索引做边界检查。
- 非法状态用 `enum class`、`std::variant` + `std::visit`、强类型包装裸标量。
- 可能缺失用 `std::optional<T>`；必然存在用引用或 `gsl::not_null`。
- 可预期失败用 `std::expected<T, E>`；C++20 用 `tl::expected`；真正不可恢复才 `throw`。
- 捕获具体异常并按 `const&`；不 `catch(...)` 后吞掉；析构函数 `noexcept` 且不抛。
- 重抛保因由：`std::nested_exception`/`std::throw_with_nested` 或 error 类型字段。
- 资源全部由 RAII 管理；优先标准容器、`std::unique_ptr`、`std::shared_ptr`；遵循 Rule of Zero；锁用 `std::lock_guard`/`std::scoped_lock`。

## 3. 并发

- 用 `std::jthread`、线程池、`std::async`/`std::future`；复杂异步用协程或 Asio；避免裸 `std::thread` 后忘记 join/detach。
- 批量任务提交后汇聚 `future`，或用 `std::execution::par`；并发度用固定线程池或 `std::counting_semaphore`。
- `future` 必须取结果以传播异常；线程函数内捕获并上报异常。
- 用 `std::stop_token`/`std::stop_source` 协作式取消。
- 共享状态用 `std::mutex` + `std::scoped_lock` 或 `std::atomic`；用 TSan/ASan 检测。
- 性能确认用 `google/benchmark`、`perf`、`valgrind --tool=callgrind`、编译器优化报告；需要时 `reserve()`、移动语义、视图传参、关注缓存局部性。

## 4. 注释与测试

- 注释写意图、约束、权衡、坑；不复述代码。公共头文件用 Doxygen 风格注释，说明前置/后置条件和所有权语义。
- 改代码同步改注释；删死代码；`TODO`/`FIXME`/`HACK` 附负责人或 issue。
- 测试用 `Catch2`，经 `bazel test //...` 运行；用 `GENERATE`/`SECTION` 覆盖多组用例。
- 测公共行为和边界，不测私有实现；mock 用 `trompeloeil` 或接口/模板 fake。
- 测试在 ASan/UBSan/TSan 下运行；修 bug 先写复现用例。

## 5. 安全与日志

- SQL 用 prepared statement 绑定参数；禁止拼接 SQL。
- 子进程用 `posix_spawn` 或参数数组；禁止 `system()`。
- 随机数用 `libsodium` 或操作系统 CSPRNG；不用 `std::rand`。
- 内存安全：用边界安全容器、`std::span`、`at()`；避免裸指针运算和 `strcpy`/`sprintf`/`gets`；CI 跑 ASan/UBSan 与 `clang-tidy` 的 `cppcoreguidelines`/`bugprone`。
- 日志用 `spdlog`（基于 `fmt`）；`std::cout` 只作临时调试，提交前清理。
- 级别：`debug`/`info`/`warn`/`error`；生产默认 `info`。日志带请求 ID、用户 ID、模块名等字段。
- 热路径避免高频 `info`；错误日志带因由；禁止记录口令、令牌、隐私数据。

## 6. 库选型

- 标准库够用时不引第三方；库须支持 C++20/23，并能通过 Bazel/bzlmod 引入。
- 选现代、主流、积极维护的库；不确定时核实发布时间与活跃度。
- 高风险依赖（久未维护、star 少、小众）先说明维护/安全/替代风险并确认。
- `folly`/`wangle`、Boost、abseil 只引实际用到的子库；与标准库重叠功能优先标准库。
- 引入依赖走 `MODULE.bazel` 的 `bazel_dep`，提交 `MODULE.bazel.lock`；避免手动 vendoring。

| 场景 | 默认 | 条件 |
| --- | --- | --- |
| 构建/包管理 | [`Bazel`](https://bazel.build/) bzlmod | 必须；优先 Bazel Central Registry，未收录用 `git_override`/`http_archive`。 |
| 单元测试 | [`Catch2`](https://github.com/catchorg/Catch2) | 必须；mock 配 [`trompeloeil`](https://github.com/rollbear/trompeloeil)。 |
| 基准测试 | [`google/benchmark`](https://github.com/google/benchmark) | 按需。 |
| 格式化/输出 | [`fmt`](https://github.com/fmtlib/fmt) | 必须；默认 `fmt::format`/`fmt::print`。 |
| 日志 | [`spdlog`](https://github.com/gabime/spdlog) | 必须；基于 `fmt`。 |
| JSON | [`nlohmann/json`](https://github.com/nlohmann/json) / [`glaze`](https://github.com/stephenberry/glaze) | 默认 `nlohmann/json`；性能热点且结构体已知用 `glaze`。 |
| HTTP 客户端 | [`cpr`](https://github.com/libcpr/cpr) | 必须；基于 libcurl。 |
| HTTP/网络服务 | [`Boost.Asio`](https://github.com/boostorg/asio) / [`Drogon`](https://github.com/drogonframework/drogon) | 底层 TCP/UDP/协程异步用 Asio；完整 Web 框架用 Drogon。 |
| CLI | [`CLI11`](https://github.com/CLIUtils/CLI11) | 必须。 |
| 配置 | [`toml++`](https://github.com/marzer/tomlplusplus) / [`yaml-cpp`](https://github.com/jbeder/yaml-cpp) | TOML/YAML；JSON 配置复用 `nlohmann/json`。 |
| 错误结果 | `std::expected` / [`tl::expected`](https://github.com/TartanLlama/expected) | C++23 用标准库；C++20 用 `tl::expected`。 |
| 通用补全 | [`abseil`](https://github.com/abseil/abseil-cpp) | 按需；标准库缺口时用。 |
| 高性能基础库 | [`folly`](https://github.com/facebook/folly) | 按需；高并发服务端确需其能力时用。 |
| 异步网络框架 | [`wangle`](https://github.com/facebook/wangle) | 按需；依赖 `folly`。 |
| Thrift RPC | [`fbthrift`](https://github.com/facebook/fbthrift) | 按需；既有 Thrift/Facebook 生态。 |
| gRPC | [`grpc`](https://github.com/grpc/grpc) | 必须；新建跨语言服务默认。 |
| SQLite | [`sqlite_orm`](https://github.com/fnc12/sqlite_orm) / [`SQLiteCpp`](https://github.com/SRombauts/SQLiteCpp) | 嵌入式 SQLite；服务端 DB 用厂商官方驱动。 |
| 加密 | [`libsodium`](https://github.com/jedisct1/libsodium) / OpenSSL | 新代码优先 `libsodium`；TLS/X.509/既有 OpenSSL 生态用 OpenSSL。 |
| 协程补全 | 标准库 `<coroutine>` + [`cppcoro`](https://github.com/lewissbaker/cppcoro) | 复杂异步可用 `cppcoro` 或 Asio 协程。 |
| 数值/线代 | [`Eigen`](https://gitlab.com/libeigen/eigen) | 按需。 |
| Boost | [`Boost`](https://github.com/boostorg/boost) | 按需；只依赖用到的子库。 |

## 7. 多候选判据

- `Catch2` + `trompeloeil`: 默认测试/mock 组合；不为 mock 切测试框架。
- `fmt` vs `<format>`: 默认 `fmt`；目标编译器完整支持且追求零依赖时才退回标准库。
- `nlohmann/json` vs `glaze`: 默认 `nlohmann/json`；解析/序列化是热点且结构体已知时用 `glaze`。
- `std::expected` vs 异常 vs 错误码: 可预期失败用 `expected`；不可恢复才异常；避免 `int` 返回 + out 参数。
- `Boost.Asio` vs `Drogon` vs `cpr`: 客户端请求用 `cpr`；底层协议/协程异步用 Asio；完整 HTTP 服务端用 Drogon。
- `libsodium` vs OpenSSL: 新代码优先 `libsodium`；TLS、X.509、OpenSSL 生态对接用 OpenSSL；不自行实现加密原语。
- `grpc` vs `fbthrift`: 新建跨语言服务默认 `grpc`；既有 Thrift/Facebook 生态或 fbthrift 特有异步/流式能力才用 `fbthrift`。
- `folly/wangle`、Boost、abseil: 标准库有能力时不用；普通项目优先标准库或 abseil，只有高并发服务端确需时用 `folly/wangle`。

## 8. 工具链

| 用途 | 工具 |
| --- | --- |
| 构建 | [`Bazel`](https://bazel.build/) bzlmod；`BUILD.bazel` 声明 target，`.bazelversion` 固定版本，`.bazelrc` 固定 C++ 标准。 |
| 依赖 | `MODULE.bazel` + `MODULE.bazel.lock`；BCR 优先，未收录用 `git_override`/`http_archive`。 |
| 格式化 | [`clang-format`](https://clang.llvm.org/docs/ClangFormat.html)，提交 `.clang-format`。 |
| 静态分析 | [`clang-tidy`](https://clang.llvm.org/extra/clang-tidy/)，启用 `bugprone`/`performance`/`modernize`/`cppcoreguidelines`。 |
| 编译警告 | `.bazelrc` 配 `-Wall -Wextra -Wpedantic`，按需 `-Werror`；MSVC 用 `/W4 /WX`。 |
| Sanitizers | `.bazelrc` 预置 `--config=asan`/`--config=ubsan`，必要时 TSan。 |
| 测试/覆盖率 | [`Catch2`](https://github.com/catchorg/Catch2)，`bazel test //...`；覆盖率用 `bazel coverage` + `llvm-cov`/`gcov`。 |
| 基准 | [`google/benchmark`](https://github.com/google/benchmark)。 |

- pre-commit 用 [`lefthook`](https://github.com/evilmartians/lefthook)：对暂存 C++ 文件跑 `clang-format --dry-run -Werror` 或格式校验、`clang-tidy`；CI 跑 `bazel build`/`bazel test //...`。
