---
description: 为 Go 项目做技术选型、引入第三方库、或在多个候选库间抉择时使用
globs: *.go
alwaysApply: false
---

# Go 库选型

> 本文件是「技术栈与工具基线 · 优先复用成熟的开源组件」的 Go 明细。
>
> **标准库优先**：Go 标准库覆盖度高，下表「标准库」项一律优先使用，仅在确有缺口时引入第三方库。引入前先确认 `net/http`、`encoding/json`、`log/slog`、`slices`、`maps`、`errors`、`context` 等是否已够用。
> **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件除非用户手动指定，否则不主动引入；确需引入先说明风险并请用户确认。

## 速查表

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
| Lint 聚合 | [`golangci-lint`](https://github.com/golangci/golangci-lint) | 必须 | 聚合多 linter，见 [`toolchain.md`](./toolchain.md)。 |
| 漏洞扫描 | [`govulncheck`](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) | 必须 | 官方漏洞扫描，CI 强制。 |
| PostgreSQL 驱动 | [`jackc/pgx`](https://github.com/jackc/pgx) | 必须 | Postgres 首选驱动，性能与功能优于 `lib/pq`；可配 `sqlc`/`sqlx`。 |
| Redis 客户端 | [`redis/go-redis`](https://github.com/redis/go-redis) | 按需 | 主流 Redis 客户端。 |
| 消息队列 / Kafka | [`twmb/franz-go`](https://github.com/twmb/franz-go) | 按需 | 纯 Go Kafka 客户端；需广泛生态可选 `segmentio/kafka-go`。 |
| 限流 | 标准库 [`golang.org/x/time/rate`](https://pkg.go.dev/golang.org/x/time/rate) | 标准库 | 令牌桶限流器。 |
| HTTP 中间件 / 框架 | [`chi`](https://github.com/go-chi/chi) | 按需 | 贴近标准库 `net/http` 的轻量路由；重生态用 `echo`/`gin`。 |
| gRPC | [`google.golang.org/grpc`](https://github.com/grpc/grpc-go) | 必须 | 官方 gRPC 实现，配 `protoc-gen-go`。 |
| 配置热加载 / CLI 旗标 | 标准库 `flag` | 标准库 | 单层简单参数够用；复杂才上 `cobra`+`viper`。 |
| 时间 / 定时 | 标准库 [`time`](https://pkg.go.dev/time) | 标准库 | `time` 已足够；测试中通过接口注入时钟以便 mock。 |

## 选型判据（多候选时如何选）

- **数据访问 `sqlc` vs `sqlx` vs `gorm`**：默认 `sqlc`——手写 SQL、由工具生成**类型安全**的查询代码，零运行时反射、性能好、SQL 可控。需要**少量样板增强但仍写 SQL**用 `sqlx`。只有在团队明确想要**全功能 ORM、动态查询、自动迁移**且接受其反射开销与「魔法」时才用 `gorm`，新服务优先避免。
- **HTTP 路由 标准库 vs `chi` vs `echo`/`gin`**：Go 1.22+ 的 `net/http` 已支持方法与路径参数，**简单服务直接用标准库**；需要**中间件链、分组路由但想贴近标准库语义**用 `chi`（handler 仍是 `http.Handler`）；需要**开箱即用的绑定/校验/渲染等重型生态**才用 `echo`/`gin`。
- **日志 `log/slog` vs `zap`**：一律默认标准库 `log/slog`（结构化、无依赖、生态统一）；仅当**日志是确认的性能热点**（极高吞吐、分配敏感）且 benchmark 证明 `slog` 不够时换 `zap`。
- **断言 `testify` vs 标准库 `testing`**：核心逻辑优先**标准库表驱动 + `t.Run`**（无依赖、错误信息清晰）；断言极多、想减少样板时用 `testify` 的 `require`/`assert`，但避免 `testify/suite` 等重型用法掩盖测试结构。
- **配置 `viper` vs `envconfig`**：只从**环境变量**映射到 struct、启动即校验，用轻量 `envconfig`；需要**多来源（文件 + env + flag）、热加载、多格式**才用 `viper`（它较重，别为读几个 env 引入）。
- **并发 `errgroup` vs 手写 `sync.WaitGroup`**：一组并发子任务需要**首个错误就取消其余 + 统一等待**用 `errgroup`；纯 fire-and-forget、无需聚合错误的简单等待用标准库 `sync.WaitGroup`。
- **Postgres 驱动 `pgx` vs `lib/pq`**：新项目一律 `pgx`（活跃维护、性能好、支持 Postgres 特性）；`lib/pq` 已进入维护停滞，不新选用。
- **DI `google/wire` vs 手动注入**：小到中型项目**手动构造依赖**即可，最清晰；仅当依赖图庞大、手写 wiring 成为负担时引入编译期 `wire`，不用运行时反射型 DI 容器。

> 注：以上为截至 2026-06 的推荐默认项。项目已有等价成熟方案则沿用，保持技术栈一致；定期复核维护状态，及时替换停更依赖。工具链（`go mod` / `golangci-lint` / CI）见 [`toolchain.md`](./toolchain.md)。
