---
description: 编写 C++ 代码时的编码实践明细（命名、类型与错误、RAII、并发、测试、安全等的 C++ 特有写法）
globs: *.cpp,*.cc,*.cxx,*.hpp,*.hh,*.hxx,*.h,*.ixx,*.cppm
alwaysApply: false
---

# 编码实践 · C++

> 本文件是 [`common.md`](./common.md) 的 C++ 明细，列出各主题在 C++ 下的特有写法；通用核心原则见 `common.md`，版本基线总表见 [`main.md`](../main.md)。

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
