---
description: 编写 Go 代码，或为 Go 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.go
alwaysApply: false
---

# Go 语言规范（编码实践 + 库选型）

> 本文件自洽：编写 Go 时所需的编码实践、日志、库选型与工具链均在此。跨语言版本基线与工程化（结构/配置/CI/发版）可选参考 `engineering.md`（非必需同时加载）。

## 0. 语言版本与语法

- **必用 Go Modules**：`go.mod` 中用 `go 1.25`（或更高）声明语言版本基线；用 `toolchain` 指令固定团队工具链版本。
- 优先采用现代语法简化代码，例如：
  - 泛型（类型参数）写通用容器与算法，替代 `interface{}` + 类型断言的样板。
  - 标准库 `slices`、`maps`、`cmp` 操作切片与映射，替代手写循环与 `golang.org/x/exp/*`。
  - 结构化日志 `log/slog`，替代 `log` 裸打印与第三方日志门面。
  - `errors.Is`/`errors.As` + `fmt.Errorf("...: %w", err)` 包装与判别错误，替代字符串比较与 `github.com/pkg/errors`。
  - `context.Context` 贯穿请求生命周期，传递取消、超时与请求级值。
  - `for range n`（整数范围循环，1.22+）、`range over func`（迭代器，1.23+）等惯用法。
- **新语法以可读性为准绳**：新写法更难懂时选直观写法，不为「显得现代」而用。
- **禁止**：用 `panic` 处理可预期错误（仅用于不可恢复的程序错误）、用 `ioutil.*`（已废弃，用 `os`/`io`）、裸 `goroutine` 不管理生命周期（见 §4）；忽略 `error`、滥用空 `interface{}`/`any` 见 §3。

## 1. 命名与代码风格

- **大小写惯例**：标识符用 `MixedCaps`/`mixedCaps`（不用下划线），靠首字母大小写控制导出（大写导出、小写包内私有）；包名用简短小写单词、避免 `util`/`common` 等无意义名；缩写词保持统一大小写（`HTTPServer`、`userID`）。
- **命名即文档**：用完整可检索的名字，布尔加 `is`/`has` 前缀（遵循 Go 惯例，如 `isValid`）。
- **避免魔法值**：字面量提取为 `const` 块 + `iota`。
- **格式不进 review**：交给 `gofmt` + `goimports` 自动处理（`goimports` 兼做 import 分组排序），review 中不讨论格式。

## 2. 函数与模块设计

- **单一职责、小而专一**：出现「阶段性注释」、超过一屏、或函数名需用「and」才能描述时 → 拆成更小的具名函数。
- **参数精简**：参数超过 3 个时用 config struct 或 functional options 模式；避免布尔陷阱参数。
- **明确公共 API**：靠首字母大小写控制导出、`internal/` 包限制可见性。
- **依赖倒置**：在使用方定义小接口、由实现方隐式满足，由外部注入实现。
- **避免循环依赖**：Go 中包级循环导入会直接编译报错，须及早分层。

## 3. 类型安全与错误处理

- **不使用逃逸类型**：避免空 `interface{}`/`any`（用具体类型或泛型），仅在边界且无法静态描述时局部使用并加注释说明。
- **在边界校验外部输入**：用 `go-playground/validator` 或显式校验后转为内部类型。
- **让非法状态不可表示**：用具名类型 + `const`/`iota` 枚举与小接口约束取值范围。
- **避免「可能不存在」的隐式约定**：用 `(T, bool)`/`(T, error)` 多返回值或指针明确表达「可能缺失」，注意 nil 指针解引用。
- **错误分流判据：可预期错误用值表达**：业务上可预期的失败以 `error` 作为最后一个返回值显式返回（定义哨兵错误 `errors.New` 或自定义 error 类型）；`panic` 仅用于真正不可恢复的情况。
- **捕获即处理**：禁止忽略 `error`（不写 `_ = fn()` 除非确有理由并注明）、禁止 `if err != nil {}` 空处理。
- **重抛保根因**：用 `fmt.Errorf("...: %w", err)` 包装，并用 `errors.Is`/`As` 判别，不丢失根因。
- **资源清理可靠**：用 `defer` 确保文件/连接/锁等资源释放。

## 4. 异步与并发

- **统一并发模型**：用 goroutine + channel，每个 goroutine 都有明确的退出条件，不开后无人管。
- **并发要并行**：独立任务用 `errgroup` 并发执行，不要串行。
- **限制并发度**：用带缓冲 channel 作信号量或 `errgroup.SetLimit`。
- **生命周期闭环**：不留泄漏的 goroutine；用 `recover` 兜底 goroutine panic；用 `context.Context`（`WithCancel`/`WithTimeout`）贯穿调用链支持取消与超时。
- **保护共享状态**：倡导「以通信共享内存」，必要时用 `sync.Mutex`，并以 `go test -race` 检测竞态。

## 5. 性能与优化

- **先测后调**：用 `go test -bench` 配 `testing.B` 写 benchmark，用 `pprof` 定位 CPU/内存热点，不靠直觉过早优化。
- **避免常见浪费**：预分配切片容量 `make([]T, 0, n)`、复用对象用 `sync.Pool`；规避 N+1、循环内重复 IO。

## 6. 注释与文档

- **写 why 不写 what**：注释解释意图、权衡、坑与非显而易见的约束，不复述代码字面逻辑。
- **同步与清理**：改代码同步更新注释；删死代码；`TODO`/`FIXME`/`HACK` 必须附负责人或 issue 链接。
- **公共 API 文档**：用 doc 注释（紧贴声明、以被注释的标识符名开头，如 `// Parse parses ...`）。

## 7. 测试规范

- **框架**：用标准库 `testing`，表驱动测试 + `t.Run` 子测试覆盖多组用例。
- **测行为非实现**：针对公共接口与可观察行为断言，不断言私有细节。
- **隔离与确定性**：外部依赖用接口 + `uber-go/mock` 或手写 fake，用 `t.Parallel()` 并以 `-race` 跑。
- **覆盖优先级**：先覆盖核心逻辑、分支与边界，覆盖率作参考非目标；修 bug 先写能复现的失败用例再修。

## 8. 安全编码

- **校验并转义输入**：HTML 输出用 `html/template` 自动转义，不用 `text/template`。
- **杜绝注入**：SQL 用 `database/sql` 占位符 + `sqlc`，禁止拼接 SQL；用 `exec.Command(name, args...)` 不经 shell。
- **安全使用加密**：密码用 `argon2`/`bcrypt` 哈希；随机数用 `crypto/rand`，不用 `math/rand`。

## 9. 日志

- **用结构化日志库**：用标准库 `log/slog` 输出结构化日志；禁止 `fmt.Println` 裸打印做正式日志（仅临时调试可用，提交前清理）。需极致性能再看 `zap`。
- **日志级别约定**：`debug`（开发细节）/`info`（关键流程节点）/`warn`（可恢复异常）/`error`（失败需关注）；生产默认 `info`。
- **结构化字段**：用 `slog` 的键值属性带上下文字段（请求 ID、用户 ID、模块名），不靠拼接字符串。
- **不在热路径滥打**：避免在循环/高频调用里打 `info`，防止刷屏与性能损耗。
- **错误日志带上下文**：记录错误时带上原始错误（配合 §3「重抛保根因」的 `%w`）。
- **不记敏感信息**：日志不输出口令、令牌、个人隐私数据。

## 10. 库选型

**选型元原则**（标准库优先、现代化、主流、积极维护）：

- **Go 标准库优先**：下表「标准库」项一律优先使用；引第三方前先确认 `net/http`、`encoding/json`、`log/slog`、`slices`、`maps`、`errors`、`context` 等是否够用。
- **选型标准**：满足现代化（用泛型与模块）、主流（社区广泛采用、生产验证充分）、积极维护；不确定就核实最新发布时间与活跃度。
- **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件，除非用户指定否则不主动引入；确需引入时先说明维护、安全、可替代性风险并请用户确认。
- **避免停更/被取代的库**：如不用 `github.com/pkg/errors`（改用标准库 `errors` + `%w`）。
- **不因体积/依赖复杂度而拒绝**：满足选型标准且能显著提升可读性与可维护性时，不把体积作为否决项；这些因素只影响多个合格候选之间的选择。

### 速查表

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| HTTP 服务 / 路由 | 标准库 [`net/http`](https://pkg.go.dev/net/http)（1.22+ 增强路由） | 标准库 | 简单服务直接用；复杂中间件/路由再考虑 [`chi`](https://github.com/go-chi/chi) 或 [`echo`](https://github.com/labstack/echo)。 |
| 日志 | 标准库 [`log/slog`](https://pkg.go.dev/log/slog) | 标准库 | 结构化日志，替代第三方日志门面；需极致性能再看 [`zap`](https://github.com/uber-go/zap)。 |
| 错误处理 | 标准库 [`errors`](https://pkg.go.dev/errors) | 标准库 | `errors.Is`/`As` + `fmt.Errorf("...: %w")`；不用 `github.com/pkg/errors`。 |
| 切片 / 映射操作 | 标准库 [`slices`](https://pkg.go.dev/slices) / [`maps`](https://pkg.go.dev/maps) | 标准库 | 替代手写循环与 `golang.org/x/exp/*`。 |
| 命令行接口 | [`cobra`](https://github.com/spf13/cobra) | 按需 | 复杂多级子命令用 `cobra`；极简场景用标准库 `flag`。 |
| 配置管理 | [`viper`](https://github.com/spf13/viper) / [`kelseyhightower/envconfig`](https://github.com/kelseyhightower/envconfig) | 必须 | 多来源配置用 `viper`，纯环境变量映射用 `envconfig`，启动即校验。 |
| 数据校验 | [`go-playground/validator`](https://github.com/go-playground/validator) | 必须 | 基于 struct tag 校验外部输入。 |
| 数据库 / SQL | [`sqlc`](https://github.com/sqlc-dev/sqlc) / [`sqlx`](https://github.com/jmoiron/sqlx) | 必须 | `sqlc` 由 SQL 生成类型安全代码（推荐）；轻量增强用 `sqlx`；需完整 ORM 用 [`gorm`](https://github.com/go-gorm/gorm)。 |
| 数据库迁移 | [`golang-migrate`](https://github.com/golang-migrate/migrate) | 必须 | 版本化管理 schema 迁移。 |
| 并发组 / 错误聚合 | [`golang.org/x/sync/errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup) | 必须 | 并发任务统一等待与首错取消，替代手写 `WaitGroup` + channel。 |
| 测试断言 | [`testify`](https://github.com/stretchr/testify) | 按需 | `require`/`assert` 简化断言；优先标准库 `testing` 表驱动。 |
| Mock 生成 | [`uber-go/mock`](https://github.com/uber-go/mock) | 按需 | 由接口生成 mock（`mockgen`），替代已归档的 `golang/mock`。 |
| HTTP 客户端重试 | 标准库 `net/http` + [`hashicorp/go-retryablehttp`](https://github.com/hashicorp/go-retryablehttp) | 按需 | 标准库客户端够用，需退避重试时引入。 |
| 唯一 ID | [`google/uuid`](https://github.com/google/uuid) | 按需 | 生成 UUID。 |
| 依赖注入 | [`google/wire`](https://github.com/google/wire) | 按需 | 编译期 DI；小项目手动注入即可，避免过度设计。 |
| Lint 聚合 | [`golangci-lint`](https://github.com/golangci/golangci-lint) | 必须 | 聚合多 linter，见 §11。 |
| 漏洞扫描 | [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | 必须 | 官方漏洞扫描，CI 强制。 |
| PostgreSQL 驱动 | [`jackc/pgx`](https://github.com/jackc/pgx) | 必须 | Postgres 首选驱动，性能与功能优于 `lib/pq`；可配 `sqlc`/`sqlx`。 |
| Redis 客户端 | [`redis/go-redis`](https://github.com/redis/go-redis) | 按需 | 主流 Redis 客户端。 |
| 消息队列 / Kafka | [`twmb/franz-go`](https://github.com/twmb/franz-go) | 按需 | 纯 Go Kafka 客户端；需广泛生态可选 `segmentio/kafka-go`。 |
| 限流 | 标准库 [`golang.org/x/time/rate`](https://pkg.go.dev/golang.org/x/time/rate) | 标准库 | 令牌桶限流器。 |
| 终端进度条 | [`schollz/progressbar`](https://github.com/schollz/progressbar) / [`vbauerster/mpb`](https://github.com/vbauerster/mpb) | 按需 | 单条进度条用 `progressbar`（API 极简）；多条并发/装饰器需求用 `mpb`。 |
| HTTP 中间件 / 框架 | [`chi`](https://github.com/go-chi/chi) | 按需 | 贴近标准库 `net/http` 的轻量路由；重生态用 `echo`/`gin`。 |
| gRPC | [`google.golang.org/grpc`](https://github.com/grpc/grpc-go) | 必须 | 官方 gRPC 实现，配 `protoc-gen-go`。 |
| 配置热加载 / CLI 旗标 | 标准库 `flag` | 标准库 | 单层简单参数够用；复杂才上 `cobra`+`viper`。 |
| 时间 / 定时 | 标准库 [`time`](https://pkg.go.dev/time) | 标准库 | `time` 已足够；测试中通过接口注入时钟以便 mock。 |

### 选型判据（多候选时如何选）

- **数据访问 `sqlc` vs `sqlx` vs `gorm`**：默认 `sqlc`——手写 SQL、由工具生成**类型安全**的查询代码，零运行时反射、性能好、SQL 可控。需要**少量样板增强但仍写 SQL**用 `sqlx`。只有在团队明确想要**全功能 ORM、动态查询、自动迁移**且接受其反射开销与「魔法」时才用 `gorm`，新服务优先避免。
- **HTTP 路由 标准库 vs `chi` vs `echo`/`gin`**：Go 1.22+ 的 `net/http` 已支持方法与路径参数，**简单服务直接用标准库**；需要**中间件链、分组路由但想贴近标准库语义**用 `chi`（handler 仍是 `http.Handler`）；需要**开箱即用的绑定/校验/渲染等重型生态**才用 `echo`/`gin`。
- **日志 `log/slog` vs `zap`**：一律默认标准库 `log/slog`（结构化、无依赖、生态统一）；仅当**日志是确认的性能热点**（极高吞吐、分配敏感）且 benchmark 证明 `slog` 不够时换 `zap`。
- **断言 `testify` vs 标准库 `testing`**：核心逻辑优先**标准库表驱动 + `t.Run`**（无依赖、错误信息清晰）；断言极多、想减少样板时用 `testify` 的 `require`/`assert`，但避免 `testify/suite` 等重型用法掩盖测试结构。
- **配置 `viper` vs `envconfig`**：只从**环境变量**映射到 struct、启动即校验，用轻量 `envconfig`；需要**多来源（文件 + env + flag）、热加载、多格式**才用 `viper`（它较重，别为读几个 env 引入）。
- **并发 `errgroup` vs 手写 `sync.WaitGroup`**：一组并发子任务需要**首个错误就取消其余 + 统一等待**用 `errgroup`；纯 fire-and-forget、无需聚合错误的简单等待用标准库 `sync.WaitGroup`。
- **Postgres 驱动 `pgx` vs `lib/pq`**：新项目一律 `pgx`（活跃维护、性能好、支持 Postgres 特性）；`lib/pq` 已进入维护停滞，不新选用。
- **DI `google/wire` vs 手动注入**：小到中型项目**手动构造依赖**即可，最清晰；仅当依赖图庞大、手写 wiring 成为负担时引入编译期 `wire`，不用运行时反射型 DI 容器。
- **进度条 `schollz/progressbar` vs `vbauerster/mpb`**：只需**单条**进度条、追求 API 极简（`NewOptions` + `Add`）用 `progressbar`；需要**多条并发进度条、动态增删、丰富装饰器（ETA/字节计数/宽度对齐）**用 `mpb`（配合 goroutine + `WaitGroup`），代价是 API 更重、学习曲线更陡。一次性脚本用 `fmt.Printf` 即可，别引依赖。

> 注：截至 2026-06 的默认推荐；既有项目沿用等价成熟方案，并定期复核维护状态。

## 11. 工具链

> 跨语言工具链约定（配置/锁文件入库、本地/pre-commit/CI 一致）可选参考 `engineering.md` 工具链节。

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 依赖 / 版本管理 | 标准 `go mod` + `toolchain` 指令 | 提交 `go.mod` 与 `go.sum`；`go mod tidy` 保持依赖整洁。 |
| 格式化 | `gofmt` / [`goimports`](https://pkg.go.dev/golang.org/x/tools/cmd/goimports) | `goimports` 兼做 import 分组排序；格式不入 review 讨论。 |
| Lint 聚合 | [`golangci-lint`](https://github.com/golangci/golangci-lint) | v2.x；`.golangci.yml` 入库，聚合 `govet`、`staticcheck`、`errcheck` 等。 |
| 静态检查 | `go vet` / [`staticcheck`](https://github.com/dominikh/go-tools) | `go vet` 基础检查；`staticcheck` 已含于 `golangci-lint`。 |
| 测试 + 覆盖率 | 标准 `go test` | `go test -race -cover ./...`，开启竞态检测。 |
| 漏洞扫描 | [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | `govulncheck ./...`，CI 强制。 |
| 构建 | 标准 `go build` | 交叉编译用 `GOOS`/`GOARCH`；发布可配 [`goreleaser`](https://github.com/goreleaser/goreleaser)。 |

- **提交前检查（pre-commit）**：用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理 git hook，在 `lefthook.yml` 的 `pre-commit` 中跑 `gofmt -l`/`goimports`、`go vet`、`golangci-lint run`、`go test`。
