---
globs: *.ts,*.tsx,*.js,*.jsx,*.py,*.go,*.cpp,*.cc,*.cxx,*.hpp,*.hh,*.hxx,*.h,*.ixx,*.cppm
alwaysApply: false
---

# 编码实践

> 本文件是主规范「编码实践」领域的明细，列出各主题核心原则下的具体要点；写代码时按需查阅。主文件只保留每节的核心原则与关键禁令。

## 0. 语言版本与语法

**核心原则**：用主流支持的较新版本（版本基线总表见 [`main.md`](./main.md)「技术栈与工具基线 · 2」）；优先用新语法简化代码、提升可读性与类型安全，但不为用而用——新写法反而更难懂时（如深度嵌套 `:=`、把简单分支硬写成 `match`、过度类型体操）选直观写法；不用已 EOL 版本，不用实验性/非 Stage 4 语法于生产。版本号须显式锁定以保团队一致。

### JavaScript / TypeScript

- **一律使用 TypeScript**，不写裸 JavaScript；新文件使用 `.ts` / `.tsx`。
- `tsconfig.json` 中必须启用 `strict: true`（建议再开 `noUncheckedIndexedAccess`）；模块系统统一用 **ESM**（`import`/`export`），不用 CommonJS。
- **版本锁定**：`package.json` 设置 `"engines": { "node": ">=22" }` 与 `"type": "module"`；用 `.nvmrc` / Volta 固定本地 Node 版本。
- 优先采用现代语法简化代码，例如：
  - 可选链 `?.` 与空值合并 `??`，替代层层 `&&` 判空。
  - 解构、展开运算符 `...`、模板字符串，替代手动拼接。
  - `async`/`await` 替代回调与裸 `Promise.then` 链。
  - 顶层 `await`、`Array` 新方法（`at`、`findLast`、`toSorted` 等）、逻辑赋值运算符（`??=`、`||=`）。
- **禁止**：`var`（用 `const`/`let`）、`==`/`!=`（用 `===`/`!==`）、`namespace`（用 ESM 模块）、CommonJS `require`/`module.exports`、`enum`（优先 `as const` 联合类型）；`any` 见 §3「类型安全」。

### Python

- **全量使用类型注解**，配合 `mypy` / `pyright` 做静态检查。
- **版本锁定**：`pyproject.toml` 设置 `requires-python = ">=3.12"`；用 `uv` 管理并锁定（`.python-version` + `uv.lock`）。
- 优先采用现代语法简化代码，例如：
  - 结构化模式匹配 `match`/`case`，替代冗长的 `if/elif` 链。
  - 内置泛型与新式类型语法（`list[int]`、`X | None`、`type` 别名语句），替代 `typing.List`、`Optional`。
  - f-string（含 `f"{x=}"` 调试写法），替代 `%` 与 `.format()`。
  - `dataclasses` / `pydantic` 模型，替代手写 `__init__` 样板。
  - 海象运算符 `:=`、`pathlib`、上下文管理器 `with`、推导式等惯用法。
- **禁止**：`from x import *`、可变默认参数（`def f(a=[])`，改用 `None` 哨兵）、`typing.List`/`Dict`/`Optional` 等旧式泛型（用内置 `list`/`dict`/`X | None`）、用 `os.path` 拼路径（用 `pathlib`）；裸 `except:` 见 §3「错误处理」。

### Go

- **必用 Go Modules**：`go.mod` 中用 `go 1.25`（或更高）声明语言版本基线；用 `toolchain` 指令固定团队工具链版本。
- 优先采用现代语法简化代码，例如：
  - 泛型（类型参数）写通用容器与算法，替代 `interface{}` + 类型断言的样板。
  - 标准库 `slices`、`maps`、`cmp` 操作切片与映射，替代手写循环与 `golang.org/x/exp/*`。
  - 结构化日志 `log/slog`，替代 `log` 裸打印与第三方日志门面。
  - `errors.Is`/`errors.As` + `fmt.Errorf("...: %w", err)` 包装与判别错误，替代字符串比较与 `github.com/pkg/errors`。
  - `context.Context` 贯穿请求生命周期，传递取消、超时与请求级值。
  - `for range n`（整数范围循环，1.22+）、`range over func`（迭代器，1.23+）等惯用法。
- **禁止**：用 `panic` 处理可预期错误（仅用于不可恢复的程序错误）、用 `ioutil.*`（已废弃，用 `os`/`io`）、裸 `goroutine` 不管理生命周期（见 §4「异步与并发」）；忽略 `error`、滥用空 `interface{}`/`any` 见 §3「类型安全与错误处理」。

### C++

- **现代 C++ 优先**：编写 RAII 风格代码，资源生命周期绑定对象；用值语义与移动语义，避免手动 `new`/`delete`。
- **版本锁定**：在 `.bazelrc` 固定 `build --cxxopt=-std=c++23`（或 per-target `copts`），并用 `.bazelversion` 锁定 Bazel 版本；通过 `MODULE.bazel` + `MODULE.bazel.lock` 锁定外部依赖。
- 优先采用现代语法简化代码，例如：
  - 智能指针 `std::unique_ptr`/`std::shared_ptr` + `std::make_unique`/`std::make_shared`，替代裸 `new`/`delete`（见 §3「类型安全与错误处理」的资源管理）。
  - `auto`、结构化绑定 `auto [a, b] = ...`、范围 `for`、`if`/`switch` 初始化语句，简化样板。
  - `std::optional`/`std::variant`/`std::expected`（C++23）表达「可能缺失/多态/可失败」，替代裸指针哨兵与错误码。
  - `std::string_view`/`std::span` 传递只读视图，避免不必要拷贝；`constexpr`/`consteval` 把计算前移到编译期。
  - Concepts 约束模板（替代 SFINAE）、Ranges（`std::ranges::`、视图与管道 `|`）替代手写循环与迭代器对。
  - `<format>` 风格的格式化：默认用 [`fmt`](https://github.com/fmtlib/fmt)（`fmt::format`/`fmt::print`），替代 `printf` 与 iostream 拼接；`<chrono>` 处理时间。
- **禁止**：裸 `new`/`delete` 与裸 owning 指针管理资源（用智能指针/容器/RAII）、C 风格强制转换（用 `static_cast`/`reinterpret_cast` 等具名转换）、`using namespace std;` 写在头文件或全局作用域、宏充当常量/函数（用 `constexpr`/`inline` 函数/`enum class`）、裸数组与 `strcpy`/`sprintf` 等不安全 C API（用 `std::array`/`std::vector`/`fmt::format`）、未初始化变量、在头文件定义非 `inline` 的非模板函数/全局变量。

## 1. 命名与代码风格

**核心原则**：命名即文档；风格统一交给工具（`biome` / `ruff`）强制，人只关注命名与表达意图。

- **命名表意**：用完整、可检索的名字，避免缩写与单字母（循环计数器等惯例除外）；布尔值用 `is`/`has`/`should` 前缀；函数名用动词短语，变量/类用名词短语。
- **遵循语言惯例**：
  - JS/TS：变量/函数 `camelCase`、类型/类 `PascalCase`、常量 `UPPER_SNAKE_CASE`、文件名 `kebab-case`。
  - Python：变量/函数/模块 `snake_case`、类 `PascalCase`、常量 `UPPER_SNAKE_CASE`，遵循 PEP 8。
  - Go：标识符用 `MixedCaps`/`mixedCaps`（不用下划线），靠首字母大小写控制导出（大写导出、小写包内私有）；包名用简短小写单词、避免 `util`/`common` 等无意义名；缩写词保持统一大小写（`HTTPServer`、`userID`）。
  - C++：类型/类 `PascalCase`，函数/变量在团队内统一（常见 `snake_case` 或 `camelCase`，跟随既有代码库），常量/`enum class` 枚举值 `PascalCase` 或 `kCamelCase`，宏（应尽量避免）`UPPER_SNAKE_CASE`；成员变量用统一后缀/前缀（如 `member_`）；命名空间小写。
- **避免魔法值**：字面量数字/字符串提取为有名常量或枚举（TS `as const` 联合，Python `Enum`，Go `const` 块 + `iota`，C++ `constexpr` 常量与 `enum class`）。
- **格式不靠手写**：缩进、引号、分号、import 排序等全部交给 `biome` / `ruff format` / `gofmt`+`goimports` / `clang-format` 自动处理，不在 review 中讨论格式问题。

## 2. 函数与模块设计

**核心原则**：小而专一、低耦合高内聚；依赖于抽象而非实现，便于测试与复用。

- **单一职责**：一个函数只做一件事；函数过长或有多个「阶段性注释」时，拆分为更小的具名函数。
- **参数精简**：参数超过 3 个时改用对象/具名参数（TS options 对象，Python 关键字参数 + `dataclass`/`pydantic`，Go 用 config struct 或 functional options 模式，C++ 用 config struct + 聚合初始化）；避免布尔陷阱参数（用枚举或拆分函数）；C++ 入参按所有权语义传递（只读用 `const&` 或 `std::string_view`/`std::span`，转移所有权用值 + `std::move`，不滥用裸指针）。
- **优先纯函数**：核心逻辑写成无副作用的纯函数，把 I/O、随机、时间等副作用推到边界。
- **明确公共 API**：模块通过显式导出暴露最小必要接口；TS 用具名导出（避免 default export），Python 用 `__all__` 或下划线前缀标记私有，Go 靠首字母大小写控制导出、`internal/` 包限制可见性，C++ 用头文件只暴露公共声明、实现细节放 `.cpp` 或 `detail`/匿名命名空间、类成员默认 `private`（接口优先 C++20 modules 的 `export`）。
- **依赖倒置**：高层逻辑依赖接口/协议（TS `interface`，Python `Protocol`/ABC，Go `interface`——在使用方定义小接口、由实现方隐式满足，C++ 用抽象基类/纯虚接口或模板 + Concepts 约束），由外部注入实现，避免在深处直接 `new` 具体依赖。
- **避免循环依赖**：模块依赖保持单向、分层清晰；出现循环引用时通过提取公共模块或反转依赖解决（Go 中包级循环导入会直接编译报错，须及早分层）。

## 3. 类型安全与错误处理

**核心原则**：用类型表达约束、让非法状态不可表示；错误必须显式、就近、可追溯地处理，禁止静默吞掉。

**类型安全**：

- **不使用逃逸类型**：TS 禁止 `any`（用 `unknown` + 收窄）；Python 禁止裸 `Any`（用具体类型、`Protocol` 或泛型）；Go 避免空 `interface{}`/`any`（用具体类型或泛型），仅在边界且无法静态描述时局部使用并加注释说明；C++ 避免 `void*` 与无约束模板/`std::any`（用具体类型、`std::variant` 或 Concepts 约束的模板），不用 C 风格转换绕过类型系统。
- **在边界校验外部输入**：API 响应、用户输入、配置、环境变量等不可信数据，必须在进入系统时用 Schema 校验（TS 用 `zod`，Python 用 `pydantic`，Go 用 `go-playground/validator` 或显式校验后转为内部类型，C++ 显式校验后转为强类型领域对象、对缓冲区/索引做边界检查），之后内部代码可信任其类型。
- **让非法状态不可表示**：优先用联合类型/可辨识联合（TS discriminated union、Python `Literal` + `match`）建模互斥状态，避免「多个布尔标志组合出非法态」；Go 用具名类型 + `const`/`iota` 枚举与小接口约束取值范围；C++ 用 `enum class`、`std::variant` + `std::visit` 建模互斥状态，强类型包装裸标量（避免 `int`/`bool` 满天飞）。
- **避免 `null`/`undefined` 蔓延**：用可选链与空值合并就近处理；对「可能不存在」的返回值用显式类型标注（`T | undefined` / `T | None`），不靠隐式约定；Go 用 `(T, bool)`/`(T, error)` 多返回值或指针明确表达「可能缺失」，注意 nil 指针解引用；C++ 用 `std::optional<T>` 表达「可能缺失」，引用/`gsl::not_null` 表达「必然存在」，避免裸指针兼作哨兵。

**错误处理**：

- **可预期错误用值表达**：业务上可预期的失败（找不到、校验失败、外部调用失败）优先用返回值表达——TS 用 `neverthrow` 的 `Result`，Python 优先返回显式结果或抛出**自定义领域异常**，Go 以 `error` 作为最后一个返回值显式返回（定义哨兵错误 `errors.New` 或自定义 error 类型），C++ 用 `std::expected<T, E>`（C++23；C++20 用 `tl::expected`）表达可失败结果，而非裸 `Error`/`Exception`/`panic` 或易忽略的整型错误码。
- **异常用于不可恢复错误**：`throw`/`raise`/`panic` 仅用于真正异常、不可预期的情况；捕获时必须捕获**具体异常类型**，禁止裸 `catch (e)` 不处理、禁止 Python 裸 `except:`、禁止 Go 忽略 `error`（不写 `_ = fn()` 除非确有理由并注明）；C++ 异常按 `const&` 捕获具体类型、不 `catch(...)` 后吞掉，析构函数不抛异常（标记 `noexcept`）。
- **不静默吞错**：捕获后必须做有意义的处理（恢复、转换、上报、带上下文重抛），禁止空 catch、禁止只 `console.log` 后继续、禁止 Go 中 `if err != nil {}` 空处理。
- **保留上下文**：重新抛出时携带原始错误（TS `new Error(msg, { cause })`，Python `raise X from e`，Go `fmt.Errorf("...: %w", err)` 并用 `errors.Is`/`As` 判别，C++ 用 `std::nested_exception`/`std::throw_with_nested` 或在 error 类型中携带因由），不丢失根因。
- **资源清理可靠**：用 `try/finally`、`with`（Python）、`using`（TS 5.2+ `await using`）、`defer`（Go）确保文件/连接/锁等资源释放，不依赖手动调用。
- **C++ 资源用 RAII 管理**：所有资源（内存、文件、锁、句柄）由对象生命周期管理——优先标准容器与智能指针（`std::unique_ptr` 独占、`std::shared_ptr` 共享），遵循「Rule of Zero」（让编译器生成特殊成员函数，不手写析构/拷贝/移动）；用 `std::lock_guard`/`std::scoped_lock` 管锁，不裸 `new`/`delete`、不手动 `lock`/`unlock`、不裸 `fopen`/`malloc`。

## 4. 异步与并发

**核心原则**：异步代码必须显式管理生命周期与错误；不阻塞、不泄漏、不丢异常。

- **统一异步模型**：JS/TS 全程 `async`/`await`，不混用裸 `.then` 链与回调；Python 用 `asyncio`，不在异步代码中调用阻塞 I/O；Go 用 goroutine + channel，每个 goroutine 都有明确的退出条件，不开后无人管；C++ 用 `std::jthread`（自动 join、支持 `stop_token`）或线程池、`std::async`/`std::future`，复杂异步用协程（C++20 `co_await`）或 `Asio`，不裸 `std::thread` 后忘记 join/detach。
- **并发要并行**：相互独立的异步任务用 `Promise.all`/`Promise.allSettled`（JS）、`asyncio.gather`（Python）、`errgroup`（Go）并发执行，不要串行 `await`；C++ 用线程池/`std::async` 批量提交后汇聚 `future`，或并行算法 `std::execution::par`。
- **限制并发度**：批量并发时限制上限——JS 用 `p-limit`，Python 用 `asyncio.Semaphore`，Go 用带缓冲 channel 作信号量或 `errgroup.SetLimit`，C++ 用固定大小线程池或 `std::counting_semaphore`，避免压垮下游或耗尽连接/句柄。
- **不吞异步异常**：每个 Promise/Task 的拒绝都必须被处理；禁止「发射后不管」的悬空 Promise / 泄漏 goroutine（需要后台执行时显式管理并捕获错误，Go 中用 `recover` 兜底 goroutine panic，C++ 中确保 `future` 被取走以传播异常、线程函数内捕获并上报异常）。
- **支持取消与超时**：长任务支持取消与超时——JS 用 `AbortController`/`AbortSignal`，Python 用 `asyncio.timeout`/取消，Go 用 `context.Context`（`WithCancel`/`WithTimeout`）贯穿调用链，C++ 用 `std::stop_token`/`std::stop_source`（配合 `std::jthread`）协作式取消，避免无限等待。
- **保护共享状态**：并发访问共享可变状态时用锁/队列/不可变数据，避免竞态；优先用消息传递而非共享内存（Go 倡导「以通信共享内存」，必要时用 `sync.Mutex`，并以 `go test -race` 检测竞态；C++ 用 `std::mutex` + `std::scoped_lock` 或 `std::atomic`，避免数据竞争，并用 TSan/ASan 检测）。

## 5. 性能与优化

**核心原则**：先用 profiler / benchmark 定位真实瓶颈再优化，不靠直觉做过早优化。

- **基准可复现**：关键算法/接口写 benchmark（JS `vitest bench`，Python `pytest-benchmark`，Go `go test -bench` 配 `testing.B`，C++ 用 `google/benchmark`），优化前后对比并纳入回归；Go 用 `pprof` 定位 CPU/内存热点，C++ 用 `perf`/`valgrind --tool=callgrind`/编译器优化报告定位。
- **避免常见浪费**：N+1 查询、循环内重复计算/IO、不必要的深拷贝、未加索引的查询；批量与缓存优先于逐条处理（Go 中预分配切片容量 `make([]T, 0, n)`、复用对象用 `sync.Pool`；C++ 中 `reserve()` 预分配容器、用移动语义避免拷贝、按 `const&`/`string_view`/`span` 传只读视图、注意缓存局部性）。
- **按瓶颈选并发模型**：IO 密集用异步并发（见本域「异步与并发」），CPU 密集用 worker / 多进程 / goroutine 池，不阻塞事件循环 / 主线程。
- **缓存有度**：缓存须明确失效策略与一致性边界，避免难调试的陈旧数据。

## 6. 注释与文档

**核心原则**：注释解释「为什么」，而非「做了什么」；代码本身说明「做了什么」。

- **写 why 不写 what**：解释意图、权衡、坑与非显而易见的约束；不要复述代码字面逻辑。
- **公共 API 必须有文档**：导出的函数/类/模块写文档注释——TS 用 TSDoc（`@param`/`@returns`/`@throws`），Python 用 docstring（约定如 Google/NumPy 风格，配合类型注解，不在 docstring 里重复类型），Go 用 doc 注释（紧贴声明、以被注释的标识符名开头，如 `// Parse parses ...`），C++ 在头文件用 Doxygen 风格注释（`@brief`/`@param`/`@return`，说明前置/后置条件与所有权语义）。
- **标注临时与风险**：用统一标记 `TODO`/`FIXME`/`HACK` 并附负责人或 issue 链接；对已知坑、绕过方案写明原因。
- **注释与代码同步**：修改代码必须同步更新相关注释/文档，过时注释比没有注释更有害；删除被注释掉的「死代码」（依赖版本控制找回）。
- **不写废话注释**：禁止 `i++ // 自增` 这类复述型注释。

## 7. 测试规范

**核心原则**：测试是行为契约；测公共行为而非内部实现，保证可重构、可信任。

- **框架统一**：JS/TS 用 `vitest`，Python 用 `pytest`，Go 用标准库 `testing`，C++ 用 `Catch2`，经 `bazel test //...` 统一运行（见「技术栈与工具基线 · 统一工具链」）。
- **结构清晰**：遵循 Arrange-Act-Assert（准备-执行-断言）；用例名描述「在什么条件下、期望什么行为」；Go 用表驱动测试 + `t.Run` 子测试覆盖多组用例（C++ 用 Catch2 的 `GENERATE`/`SECTION` 覆盖多组用例与分支）。
- **测行为非实现**：针对公共接口与可观察行为断言，避免断言私有细节，减少重构时的脆性。
- **隔离与确定性**：单测不依赖网络/真实 DB/时钟/全局状态；外部依赖用 mock/stub/fake（Go 用接口 + `uber-go/mock` 或手写 fake，C++ 用 `trompeloeil` 或对接口/模板做 fake），时间用可注入的时钟，保证可重复、可并行（Go 用 `t.Parallel()` 并以 `-race` 跑，C++ 测试在 ASan/UBSan/TSan 下运行）。
- **覆盖关键路径**：优先覆盖核心逻辑、分支与边界条件（空、极值、错误路径），不盲目追求 100% 覆盖率；覆盖率作为参考而非目标。
- **回归即用例**：修复 bug 时先写一个能复现该 bug 的失败用例，再修复使其通过。

## 8. 安全编码

**核心原则**：默认不信任一切外部输入；最小权限、纵深防御。

- **校验并转义输入**：所有外部输入先校验（`zod`/`pydantic`/`validator`）再使用；按输出上下文转义（HTML/SQL/Shell/URL），防注入（Go HTML 输出用 `html/template` 自动转义，不用 `text/template`）。
- **杜绝注入**：SQL 用参数化查询或 ORM（`drizzle-orm`/`sqlalchemy`/`database/sql` 占位符 + `sqlc`，C++ 用预处理语句 `prepared statement` 绑定参数），禁止字符串拼接 SQL；执行子进程传参数数组而非拼接命令行字符串（`execa` / `subprocess` 不用 `shell=True`、Go 用 `exec.Command(name, args...)` 不经 shell，C++ 用 `posix_spawn`/参数数组而非 `system()`）。
- **最小权限**：进程、令牌、数据库账号、CI 凭据均按最小必要权限授予；敏感操作做鉴权与审计。
- **安全使用加密**：密码用专用算法哈希（如 `argon2`/`bcrypt`，不用 MD5/SHA1）；随机数用密码学安全源（`crypto`/`secrets`/`crypto/rand`，C++ 用 `libsodium` 或操作系统 CSPRNG，不用 `std::rand`），不用 `Math.random`/`random`/`math/rand`。
- **C++ 内存安全**：杜绝缓冲区溢出、越界访问、悬垂指针/引用、use-after-free、整型溢出——优先用边界安全的容器与 `std::span`/`at()`，避免裸指针运算与不安全 C API（`strcpy`/`sprintf`/`gets`）；CI 用 ASan/UBSan 与 `clang-tidy` 的 `cppcoreguidelines`/`bugprone` 检查兜底。
- **依赖与供应链安全**：见「版本与协作 · 依赖治理」，CI 强制漏洞扫描与升级。
