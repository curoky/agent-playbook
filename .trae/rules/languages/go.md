---
description: 编写 Go 代码，或为 Go 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.go
alwaysApply: false
---

# Go 规则

## 0. 基线

- 必用 Go Modules；`go.mod` 声明 `go 1.25` 或更高，并用 `toolchain` 固定团队工具链。
- 现代语法/标准库优先：泛型、`slices`、`maps`、`cmp`、`log/slog`、`errors.Is/As`、`fmt.Errorf("...: %w", err)`、`context.Context`、`for range n`、`range over func`；可读性优先。
- 禁止：用 `panic` 处理可预期错误、`ioutil.*`、裸 goroutine 无生命周期管理、忽略 `error`、滥用 `interface{}`/`any`。

## 1. 风格与模块

- 标识符用 `MixedCaps`/`mixedCaps`；导出靠首字母大小写；包名短小写，避免 `util`/`common`；缩写统一如 `HTTPServer`、`userID`。
- 布尔用 `is`/`has` 前缀；魔法值提取为 `const` 块和 `iota`。
- 格式用 `gofmt` + `goimports`。
- 函数超过一屏、出现阶段性注释、或名称需用 `and` 描述时拆分。
- 参数超过 3 个用 config struct 或 functional options；避免布尔陷阱参数。
- 公共 API 靠导出控制；`internal/` 限制可见性。
- 在使用方定义小接口，由实现方隐式满足，外部注入实现；尽早分层避免循环依赖。

## 2. 类型、错误、资源

- 避免空 `interface{}`/`any`；仅在边界且无法静态描述时局部使用并注明原因。
- 外部输入用 `go-playground/validator` 或显式校验后转为内部类型。
- 非法状态用具名类型、`const`/`iota` 枚举、小接口约束。
- 可能缺失用 `(T, bool)`、`(T, error)` 或指针表达；注意 nil 解引用。
- 可预期失败以最后一个返回值 `error` 表达；定义哨兵错误或自定义 error 类型；`panic` 只用于不可恢复错误。
- 禁止忽略 `error`；`_ = fn()` 必须有理由并注明；禁止空 `if err != nil {}`。
- 包装错误用 `%w`，判别用 `errors.Is/As`；资源释放用 `defer`。

## 3. 并发

- goroutine 必须有退出条件；不留泄漏 goroutine。
- 独立任务用 `errgroup`；批量并发用带缓冲 channel 信号量或 `errgroup.SetLimit`。
- `context.Context` 贯穿调用链，用 `WithCancel`/`WithTimeout` 支持取消与超时。
- goroutine 内 panic 要 recover 并上报。
- 共享状态优先通过 channel 协调；必要时用 `sync.Mutex`；用 `go test -race` 检测竞态。
- 性能确认用 `go test -bench` 和 `pprof`；需要时预分配切片、复用对象。

## 4. 注释与测试

- 注释写意图、约束、权衡、坑；不复述代码。导出标识符用 doc 注释，紧贴声明并以标识符名开头。
- 改代码同步改注释；删死代码；`TODO`/`FIXME`/`HACK` 附负责人或 issue。
- 测试用标准库 `testing`，表驱动 + `t.Run`。
- 测公共行为和边界，不测私有实现；外部依赖用接口 + `uber-go/mock` 或手写 fake。
- 可并行测试用 `t.Parallel()`；CI 跑 `-race`；修 bug 先写复现用例。

## 5. 安全与日志

- HTML 输出用 `html/template`，不用 `text/template`。
- SQL 用 `database/sql` 占位符 + `sqlc`；禁止拼接 SQL。
- 子进程用 `exec.Command(name, args...)`，不经 shell。
- 密码用 `argon2`/`bcrypt`；随机数用 `crypto/rand`，不用 `math/rand`。
- 日志用标准库 `log/slog` 结构化输出；`fmt.Println` 只作临时调试，提交前清理。
- 级别：`debug`/`info`/`warn`/`error`；生产默认 `info`。日志字段用 `slog` 键值属性。
- 热路径避免高频 `info`；错误日志带原始错误；禁止记录口令、令牌、隐私数据。

## 6. 库选型

- 标准库优先；先确认 `net/http`、`encoding/json`、`log/slog`、`slices`、`maps`、`errors`、`context` 是否够用。
- 选现代、主流、积极维护的库：Go modules、泛型友好、生产验证充分；不确定时核实发布时间与活跃度。
- 高风险依赖（久未维护、star 少、小众）先说明维护/安全/替代风险并确认。
- 避免停更/被取代库，如 `github.com/pkg/errors`；体积/依赖复杂度只在多个合格候选间加权。

| 场景 | 默认 | 条件 |
| --- | --- | --- |
| HTTP 服务/路由 | 标准库 [`net/http`](https://pkg.go.dev/net/http) | 简单服务直接用；中间件/分组路由用 [`chi`](https://github.com/go-chi/chi)；重生态再看 `echo`/`gin`。 |
| 日志 | 标准库 [`log/slog`](https://pkg.go.dev/log/slog) | 日志是确认性能热点时再看 [`zap`](https://github.com/uber-go/zap)。 |
| 错误处理 | 标准库 [`errors`](https://pkg.go.dev/errors) | `errors.Is/As` + `%w`。 |
| 切片/映射 | 标准库 [`slices`](https://pkg.go.dev/slices) / [`maps`](https://pkg.go.dev/maps) | 替代手写循环和 `golang.org/x/exp/*`。 |
| CLI | 标准库 `flag` / [`cobra`](https://github.com/spf13/cobra) | 单层参数用 `flag`；复杂多级子命令用 `cobra`。 |
| 配置 | [`envconfig`](https://github.com/kelseyhightower/envconfig) / [`viper`](https://github.com/spf13/viper) | 纯环境变量用 `envconfig`；多来源/热加载/多格式用 `viper`。 |
| 校验 | [`go-playground/validator`](https://github.com/go-playground/validator) | 必须；struct tag 校验外部输入。 |
| SQL | [`sqlc`](https://github.com/sqlc-dev/sqlc) / [`sqlx`](https://github.com/jmoiron/sqlx) / [`gorm`](https://github.com/go-gorm/gorm) | 默认 `sqlc`；轻量增强用 `sqlx`；全功能 ORM 才用 `gorm`。 |
| 迁移 | [`golang-migrate`](https://github.com/golang-migrate/migrate) | 必须。 |
| 并发组 | [`errgroup`](https://pkg.go.dev/golang.org/x/sync/errgroup) | 必须；等待、首错取消、限流。 |
| 测试断言 | 标准库 `testing` / [`testify`](https://github.com/stretchr/testify) | 核心逻辑优先标准库；断言样板多时用 `require/assert`。 |
| Mock | [`uber-go/mock`](https://github.com/uber-go/mock) | 按需；替代已归档 `golang/mock`。 |
| HTTP 重试 | 标准库 `net/http` + [`go-retryablehttp`](https://github.com/hashicorp/go-retryablehttp) | 需退避重试时用。 |
| UUID | [`google/uuid`](https://github.com/google/uuid) | 按需。 |
| DI | 手动注入 / [`wire`](https://github.com/google/wire) | 小中型项目手动；依赖图庞大时用编译期 `wire`。 |
| Lint | [`golangci-lint`](https://github.com/golangci/golangci-lint) | 必须；v2.x。 |
| 漏洞扫描 | [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | 必须。 |
| PostgreSQL | [`pgx`](https://github.com/jackc/pgx) | 必须；不新选 `lib/pq`。 |
| Redis | [`redis/go-redis`](https://github.com/redis/go-redis) | 按需。 |
| Kafka | [`twmb/franz-go`](https://github.com/twmb/franz-go) / `segmentio/kafka-go` | 纯 Go 优先 `franz-go`；生态兼容需求用 `kafka-go`。 |
| 限流 | [`x/time/rate`](https://pkg.go.dev/golang.org/x/time/rate) | 标准库扩展；令牌桶。 |
| 进度条 | [`progressbar`](https://github.com/schollz/progressbar) / [`mpb`](https://github.com/vbauerster/mpb) | 单条用 `progressbar`；多条并发/装饰器用 `mpb`。 |
| gRPC | [`grpc-go`](https://github.com/grpc/grpc-go) | 必须；配 `protoc-gen-go`。 |
| 时间 | 标准库 [`time`](https://pkg.go.dev/time) | 测试中注入时钟。 |

## 7. 多候选判据

- `sqlc` vs `sqlx` vs `gorm`: 默认 `sqlc`；少量样板增强仍写 SQL 用 `sqlx`；团队明确要全功能 ORM、动态查询、自动迁移且接受反射开销时用 `gorm`。
- `net/http` vs `chi` vs `echo/gin`: 简单服务用 Go 1.22+ `net/http`；中间件链/分组路由用 `chi`；绑定/校验/渲染等重型生态用 `echo`/`gin`。
- `log/slog` vs `zap`: 默认 `slog`；benchmark 证明 `slog` 不够时换 `zap`。
- `testify` vs `testing`: 核心逻辑优先表驱动 + `t.Run`；断言极多时用 `require/assert`，避免 `testify/suite` 掩盖结构。
- `viper` vs `envconfig`: 只读环境变量用 `envconfig`；多来源/热加载/多格式用 `viper`。
- `errgroup` vs `sync.WaitGroup`: 需要首错取消和统一等待用 `errgroup`；简单等待可用 `WaitGroup`。
- `pgx` vs `lib/pq`: 新项目用 `pgx`；`lib/pq` 不新选。
- `wire` vs 手动注入: 小中型项目手动；依赖图庞大再用 `wire`；不用运行时反射 DI。

## 8. 工具链

| 用途 | 工具 |
| --- | --- |
| 依赖/版本 | `go mod` + `toolchain`，提交 `go.mod`、`go.sum`；用 `go mod tidy`。 |
| 格式化 | `gofmt` / [`goimports`](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)。 |
| Lint | [`golangci-lint`](https://github.com/golangci/golangci-lint) v2.x，配置 `.golangci.yml`。 |
| 静态检查 | `go vet` / [`staticcheck`](https://github.com/dominikh/go-tools)。 |
| 测试 | `go test -race -cover ./...`。 |
| 漏洞扫描 | [`govulncheck ./...`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)。 |
| 构建 | `go build`；交叉编译用 `GOOS`/`GOARCH`；发布可配 [`goreleaser`](https://github.com/goreleaser/goreleaser)。 |

- pre-commit 用 [`lefthook`](https://github.com/evilmartians/lefthook)：跑 `gofmt -l`/`goimports`、`go vet`、`golangci-lint run`、`go test`。
