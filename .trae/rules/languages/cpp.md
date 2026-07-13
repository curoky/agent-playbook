---
description: 编写 C++ 代码，或为 C++ 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.cpp,*.cc,*.cxx,*.hpp,*.hh,*.hxx,*.h,*.ixx,*.cppm
alwaysApply: false
---

# C++ 语言规范（编码实践 + 库选型）

> C++ 明细：通用原则见 [`common.md`](./common.md)，版本基线见 [`main.md`](../main.md)，工具链通用约定见 [`toolchain.md`](../toolchain.md)。基线为 C++23/20。

## 0. 语言版本与语法

- **现代 C++ 优先**：编写 RAII 风格代码，资源生命周期绑定对象；用值语义与移动语义，避免手动 `new`/`delete`。
- **版本锁定**：在 `.bazelrc` 固定 `build --cxxopt=-std=c++23`（或 per-target `copts`），并用 `.bazelversion` 锁定 Bazel 版本；通过 `MODULE.bazel` + `MODULE.bazel.lock` 锁定外部依赖。
- 优先采用现代语法简化代码，例如：
  - 智能指针 `std::unique_ptr`/`std::shared_ptr` + `std::make_unique`/`std::make_shared`，替代裸 `new`/`delete`（见 §3 的资源管理）。
  - `auto`、结构化绑定 `auto [a, b] = ...`、范围 `for`、`if`/`switch` 初始化语句，简化样板。
  - `std::optional`/`std::variant`/`std::expected`（C++23）表达「可能缺失/多态/可失败」，替代裸指针哨兵与错误码。
  - `std::string_view`/`std::span` 传递只读视图，避免不必要拷贝；`constexpr`/`consteval` 把计算前移到编译期。
  - Concepts 约束模板（替代 SFINAE）、Ranges（`std::ranges::`、视图与管道 `|`）替代手写循环与迭代器对。
  - `<format>` 风格的格式化：默认用 [`fmt`](https://github.com/fmtlib/fmt)（`fmt::format`/`fmt::print`），替代 `printf` 与 iostream 拼接；`<chrono>` 处理时间。
- **禁止**：裸 `new`/`delete` 与裸 owning 指针管理资源（用智能指针/容器/RAII）、C 风格强制转换（用 `static_cast`/`reinterpret_cast` 等具名转换）、`using namespace std;` 写在头文件或全局作用域、宏充当常量/函数（用 `constexpr`/`inline` 函数/`enum class`）、裸数组与 `strcpy`/`sprintf` 等不安全 C API（用 `std::array`/`std::vector`/`fmt::format`）、未初始化变量、在头文件定义非 `inline` 的非模板函数/全局变量。

## 1. 命名与代码风格

- **大小写惯例**：类型/类 `PascalCase`，函数/变量在团队内统一（常见 `snake_case` 或 `camelCase`，跟随既有代码库），常量/`enum class` 枚举值 `PascalCase` 或 `kCamelCase`，宏（应尽量避免）`UPPER_SNAKE_CASE`；成员变量用统一后缀/前缀（如 `member_`）；命名空间小写。
- **避免魔法值**：字面量提取为 `constexpr` 常量与 `enum class`。
- **格式工具**：交给 `clang-format` 自动处理。

## 2. 函数与模块设计

- **参数精简**：参数超过 3 个时用 config struct + 聚合初始化；入参按所有权语义传递（只读用 `const&` 或 `std::string_view`/`std::span`，转移所有权用值 + `std::move`，不滥用裸指针）。
- **明确公共 API**：头文件只暴露公共声明、实现细节放 `.cpp` 或 `detail`/匿名命名空间、类成员默认 `private`（接口优先 C++20 modules 的 `export`）。
- **依赖倒置**：用抽象基类/纯虚接口或模板 + Concepts 约束，由外部注入实现。

## 3. 类型安全与错误处理

- **不使用逃逸类型**：避免 `void*` 与无约束模板/`std::any`（用具体类型、`std::variant` 或 Concepts 约束的模板），不用 C 风格转换绕过类型系统。
- **在边界校验外部输入**：显式校验后转为强类型领域对象、对缓冲区/索引做边界检查。
- **让非法状态不可表示**：用 `enum class`、`std::variant` + `std::visit` 建模互斥状态，强类型包装裸标量（避免 `int`/`bool` 满天飞）。
- **避免「可能不存在」的隐式约定**：用 `std::optional<T>` 表达「可能缺失」，引用/`gsl::not_null` 表达「必然存在」，避免裸指针兼作哨兵。
- **可预期错误用值表达**：用 `std::expected<T, E>`（C++23；C++20 用 `tl::expected`）表达可失败结果，而非裸异常或整型错误码。
- **异常用于不可恢复错误**：按 `const&` 捕获具体类型、不 `catch(...)` 后吞掉，析构函数不抛异常（标记 `noexcept`）。
- **保留上下文**：用 `std::nested_exception`/`std::throw_with_nested` 或在 error 类型中携带因由。
- **资源用 RAII 管理**：所有资源（内存、文件、锁、句柄）由对象生命周期管理——优先标准容器与智能指针（`std::unique_ptr` 独占、`std::shared_ptr` 共享），遵循「Rule of Zero」；用 `std::lock_guard`/`std::scoped_lock` 管锁，不裸 `new`/`delete`、不手动 `lock`/`unlock`、不裸 `fopen`/`malloc`。

## 4. 异步与并发

- **统一并发模型**：用 `std::jthread`（自动 join、支持 `stop_token`）或线程池、`std::async`/`std::future`，复杂异步用协程（C++20 `co_await`）或 `Asio`，不裸 `std::thread` 后忘记 join/detach。
- **并发要并行**：用线程池/`std::async` 批量提交后汇聚 `future`，或并行算法 `std::execution::par`。
- **限制并发度**：用固定大小线程池或 `std::counting_semaphore`。
- **不吞异步异常**：确保 `future` 被取走以传播异常、线程函数内捕获并上报异常。
- **支持取消与超时**：用 `std::stop_token`/`std::stop_source`（配合 `std::jthread`）协作式取消。
- **保护共享状态**：用 `std::mutex` + `std::scoped_lock` 或 `std::atomic`，避免数据竞争，并用 TSan/ASan 检测。

## 5. 性能与优化

- **基准可复现**：用 `google/benchmark` 写微基准；用 `perf`/`valgrind --tool=callgrind`/编译器优化报告定位热点。
- **避免常见浪费**：`reserve()` 预分配容器、用移动语义避免拷贝、按 `const&`/`string_view`/`span` 传只读视图、注意缓存局部性。

## 6. 注释与文档

- **公共 API 文档**：在头文件用 Doxygen 风格注释（`@brief`/`@param`/`@return`，说明前置/后置条件与所有权语义）。

## 7. 测试规范

- **框架**：用 `Catch2`，经 `bazel test //...` 统一运行；用 `GENERATE`/`SECTION` 覆盖多组用例与分支。
- **隔离与确定性**：用 `trompeloeil` 或对接口/模板做 fake；测试在 ASan/UBSan/TSan 下运行。

## 8. 安全编码

- **杜绝注入**：用预处理语句 `prepared statement` 绑定参数，禁止拼接 SQL；用 `posix_spawn`/参数数组而非 `system()`。
- **安全使用加密**：随机数用 `libsodium` 或操作系统 CSPRNG，不用 `std::rand`。
- **C++ 内存安全**：杜绝缓冲区溢出、越界访问、悬垂指针/引用、use-after-free、整型溢出——优先用边界安全的容器与 `std::span`/`at()`，避免裸指针运算与不安全 C API（`strcpy`/`sprintf`/`gets`）；CI 用 ASan/UBSan 与 `clang-tidy` 的 `cppcoreguidelines`/`bugprone` 检查兜底。

## 9. 库选型

> 继承 [`main.md`](../main.md) 的选型规则，并要求支持 C++20/23、提供 Bazel 模块或可被 bzlmod 引入。标准库够用时不引第三方；高风险依赖先说明风险并确认。引入务必走 Bazel（`MODULE.bazel` 声明 `bazel_dep`、`MODULE.bazel.lock` 锁版本），避免手动 vendoring。

### 速查表

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

### 选型判据（多候选时如何选）

- **测试 mock**：`Catch2` 为默认测试框架（header-only、零配置、BDD 风格，`bazel test` 直接跑）；需要 mock 时配 `trompeloeil`（与 Catch2 配合好），不必为 mock 切到其他框架。
- **格式化 `fmt` vs 标准库 `<format>`**：默认用 `fmt`，特性最全、跨编译器行为一致、含彩色输出与编译期检查；标准库 `std::format`/`std::print` 本就源自 `fmt`，仅在追求零依赖且目标编译器已完整支持时才考虑退回标准库。
- **JSON `nlohmann/json` vs `glaze`**：默认 `nlohmann/json`（API 直观、文档全、生态广），**易用性优先**；当 **JSON 解析/序列化是性能热点**、且结构体已知时用 `glaze`（编译期反射、零拷贝、快一个量级）。
- **错误处理 `std::expected` vs 异常 vs 错误码**：库的可预期失败（解析、查找、校验）优先 `std::expected<T, E>`（C++23；C++20 用 `tl::expected`），让调用方在类型上必须处理；**真正异常、不可恢复**才 `throw`；避免裸错误码（`int` 返回 + out 参数）这类易忽略的 C 风格。
- **网络 `Boost.Asio` vs `Drogon` vs `cpr`**：只做**HTTP 客户端请求**用 `cpr`（最简单）；需要**底层 TCP/UDP、自定义协议、协程异步**用 `Asio`；需要**完整 HTTP 服务端框架（路由、ORM、模板）**用 `Drogon`。
- **加密 `libsodium` vs OpenSSL**：新代码优先 `libsodium`（API 简洁、默认安全、难以误用）；必须做 **TLS、X.509、或对接既有 OpenSSL 生态**时用 OpenSSL，不自行实现加密原语。
- **RPC `grpc` vs `fbthrift`**：新建**跨语言**服务默认 `grpc`（生态最广、配 protobuf、社区与工具链成熟）；仅在**对接既有 Thrift/Facebook 生态**或需 fbthrift 特有能力（与 `folly`/`wangle` 深度整合的异步/流式）时用 `fbthrift`，并接受其 `folly`/`wangle` 重依赖。
- **是否引入 `folly`/`wangle` 与 `Boost`/`abseil`**：仅当标准库确有缺口时引入，且**只依赖用到的子库**，不整包拉入；与标准库重叠的功能（智能指针、`optional`、`filesystem`）一律用标准库。`folly`/`wangle` 体量大、编译重、依赖链长，仅在**高并发服务端确需其性能/能力**时引入，普通项目优先 `abseil` 或标准库。

> 注：截至 2026-06 的默认推荐；既有项目沿用等价成熟方案，并定期复核维护状态。

## 10. 工具链

> 跨语言要求见 [`toolchain.md`](../toolchain.md)：配置入库，本地/pre-commit/CI 一致。

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 构建系统 | [`Bazel`](https://bazel.build/)（启用 bzlmod） | 用 `BUILD.bazel` 声明 target，`.bazelversion` 固定版本；`.bazelrc` 固定 `build --cxxopt=-std=c++23`。 |
| 依赖管理 | Bazel bzlmod + [Bazel Central Registry](https://registry.bazel.build/) | `MODULE.bazel` 声明 `bazel_dep`，`MODULE.bazel.lock` 锁版本并入库；BCR 未收录的库用 `git_override`/`http_archive`。 |
| 格式化 | [`clang-format`](https://clang.llvm.org/docs/ClangFormat.html) | `.clang-format` 入库；格式不入 review 讨论。 |
| 静态分析 / Lint | [`clang-tidy`](https://clang.llvm.org/extra/clang-tidy/) | `.clang-tidy` 入库，启用 `bugprone`/`performance`/`modernize`/`cppcoreguidelines` 等；CI 强制。 |
| 编译期检查 | 编译器 warning | 在 `.bazelrc` 配 `build --cxxopt=-Wall --cxxopt=-Wextra --cxxopt=-Wpedantic` 并视情况 `-Werror`（MSVC 用 `/W4 /WX`）。 |
| 运行期检查 | Sanitizers | 用 `--config=asan`/`--config=ubsan`（`.bazelrc` 预置）跑 ASan/UBSan、必要时 TSan；定位内存与未定义行为。 |
| 测试 + 覆盖率 | [`Catch2`](https://github.com/catchorg/Catch2) | 通过 `bazel test //...` 统一运行；覆盖率用 `bazel coverage` + `llvm-cov`/`gcov`。 |
| 基准测试 | [`google/benchmark`](https://github.com/google/benchmark) | 微基准，配合性能优化。 |

- **提交前检查（pre-commit）**：用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理 git hook，在 `lefthook.yml` 的 `pre-commit` 中对暂存文件跑 `clang-format --dry-run -Werror`（或格式校验）与 `clang-tidy`；`bazel build`/`bazel test //...` 在 CI 执行。
