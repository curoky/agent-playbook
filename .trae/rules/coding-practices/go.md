---
description: 编写 Go 代码时的编码实践明细（命名、类型与错误、并发、测试、安全等的 Go 特有写法）
globs: *.go
alwaysApply: false
---

# 编码实践 · Go

> 本文件是 [`common.md`](./common.md) 的 Go 明细，列出各主题在 Go 下的特有写法；通用核心原则见 `common.md`，版本基线总表见 [`main.md`](../main.md)。

## 0. 语言版本与语法

- **必用 Go Modules**：`go.mod` 中用 `go 1.25`（或更高）声明语言版本基线；用 `toolchain` 指令固定团队工具链版本。
- 优先采用现代语法简化代码，例如：
  - 泛型（类型参数）写通用容器与算法，替代 `interface{}` + 类型断言的样板。
  - 标准库 `slices`、`maps`、`cmp` 操作切片与映射，替代手写循环与 `golang.org/x/exp/*`。
  - 结构化日志 `log/slog`，替代 `log` 裸打印与第三方日志门面。
  - `errors.Is`/`errors.As` + `fmt.Errorf("...: %w", err)` 包装与判别错误，替代字符串比较与 `github.com/pkg/errors`。
  - `context.Context` 贯穿请求生命周期，传递取消、超时与请求级值。
  - `for range n`（整数范围循环，1.22+）、`range over func`（迭代器，1.23+）等惯用法。
- **禁止**：用 `panic` 处理可预期错误（仅用于不可恢复的程序错误）、用 `ioutil.*`（已废弃，用 `os`/`io`）、裸 `goroutine` 不管理生命周期（见 §4）；忽略 `error`、滥用空 `interface{}`/`any` 见 §3。

## 1. 命名与代码风格

- **大小写惯例**：标识符用 `MixedCaps`/`mixedCaps`（不用下划线），靠首字母大小写控制导出（大写导出、小写包内私有）；包名用简短小写单词、避免 `util`/`common` 等无意义名；缩写词保持统一大小写（`HTTPServer`、`userID`）。
- **避免魔法值**：字面量提取为 `const` 块 + `iota`。
- **格式工具**：交给 `gofmt` + `goimports` 自动处理（`goimports` 兼做 import 分组排序）。

## 2. 函数与模块设计

- **参数精简**：参数超过 3 个时用 config struct 或 functional options 模式。
- **明确公共 API**：靠首字母大小写控制导出、`internal/` 包限制可见性。
- **依赖倒置**：在使用方定义小接口、由实现方隐式满足，由外部注入实现。
- **避免循环依赖**：Go 中包级循环导入会直接编译报错，须及早分层。

## 3. 类型安全与错误处理

- **不使用逃逸类型**：避免空 `interface{}`/`any`（用具体类型或泛型），仅在边界且无法静态描述时局部使用并加注释说明。
- **在边界校验外部输入**：用 `go-playground/validator` 或显式校验后转为内部类型。
- **让非法状态不可表示**：用具名类型 + `const`/`iota` 枚举与小接口约束取值范围。
- **避免「可能不存在」的隐式约定**：用 `(T, bool)`/`(T, error)` 多返回值或指针明确表达「可能缺失」，注意 nil 指针解引用。
- **可预期错误用值表达**：以 `error` 作为最后一个返回值显式返回（定义哨兵错误 `errors.New` 或自定义 error 类型）。
- **异常用于不可恢复错误**：`panic` 仅用于真正不可恢复的情况；禁止忽略 `error`（不写 `_ = fn()` 除非确有理由并注明）、禁止 `if err != nil {}` 空处理。
- **保留上下文**：用 `fmt.Errorf("...: %w", err)` 包装，并用 `errors.Is`/`As` 判别，不丢失根因。
- **资源清理可靠**：用 `defer` 确保文件/连接/锁等资源释放。

## 4. 异步与并发

- **统一并发模型**：用 goroutine + channel，每个 goroutine 都有明确的退出条件，不开后无人管。
- **并发要并行**：独立任务用 `errgroup` 并发执行，不要串行。
- **限制并发度**：用带缓冲 channel 作信号量或 `errgroup.SetLimit`。
- **不吞异步异常**：不留泄漏的 goroutine；用 `recover` 兜底 goroutine panic。
- **支持取消与超时**：用 `context.Context`（`WithCancel`/`WithTimeout`）贯穿调用链。
- **保护共享状态**：倡导「以通信共享内存」，必要时用 `sync.Mutex`，并以 `go test -race` 检测竞态。

## 5. 性能与优化

- **基准可复现**：用 `go test -bench` 配 `testing.B` 写 benchmark，用 `pprof` 定位 CPU/内存热点。
- **避免常见浪费**：预分配切片容量 `make([]T, 0, n)`、复用对象用 `sync.Pool`。

## 6. 注释与文档

- **公共 API 文档**：用 doc 注释（紧贴声明、以被注释的标识符名开头，如 `// Parse parses ...`）。

## 7. 测试规范

- **框架**：用标准库 `testing`，表驱动测试 + `t.Run` 子测试覆盖多组用例。
- **隔离与确定性**：外部依赖用接口 + `uber-go/mock` 或手写 fake，用 `t.Parallel()` 并以 `-race` 跑。

## 8. 安全编码

- **校验并转义输入**：HTML 输出用 `html/template` 自动转义，不用 `text/template`。
- **杜绝注入**：SQL 用 `database/sql` 占位符 + `sqlc`，禁止拼接 SQL；用 `exec.Command(name, args...)` 不经 shell。
- **安全使用加密**：密码用 `argon2`/`bcrypt` 哈希；随机数用 `crypto/rand`，不用 `math/rand`。
