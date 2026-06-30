---
description: 为 JavaScript/TypeScript 项目做技术选型、引入第三方库、或在多个候选库间抉择时使用
globs: *.ts,*.tsx,*.js,*.jsx,*.mts,*.cts
alwaysApply: false
---

# JavaScript / TypeScript 库选型

> 本文件是「技术栈与工具基线 · 优先复用成熟的开源组件」的 JS/TS 明细。
>
> **选型标准**（库须同时满足）：现代化、主流、积极维护。
> **谨慎引入高风险依赖**：久未维护、star 偏少、过于小众的组件除非用户手动指定，否则不主动引入；确需引入先说明风险并请用户确认，优先选标准库或更主流的成熟替代品。
> **引入判定**：
>
> - **必须**：能大幅简化代码或 API 明显更好、更不易出错（如 `zod`），作为默认选择。
> - **按需**：与平台/标准能力差别不大、仅有性能或便利收益（如 `picocolors`），仅在确有需求时引入。
> - **平台优先**：现代运行时（Node 22+、浏览器）原生能力够用时不引库，如 `crypto.randomUUID()`、`structuredClone`、`fetch`、`URL`、`Intl`。

## 速查表

| 场景 | 推荐库 | 引入要求 | 说明 |
| --- | --- | --- | --- |
| 路径操作 | [`pathe`](https://github.com/unjs/pathe) | 必须 | 跨平台一致，避免 Windows/POSIX 分隔符差异。 |
| 错误处理 | [`neverthrow`](https://github.com/supermacro/neverthrow) | 按需 | 用 `Result` 类型显式处理错误；团队接受函数式风格再引入，否则用原生 `try/catch` + 自定义 Error 子类。 |
| 日期 / 时间 | [`Temporal`](https://github.com/tc39/proposal-temporal) | 必须 | 替代易错的原生 `Date`；运行时未内置时用 `@js-temporal/polyfill`。 |
| 运行时类型校验 / Schema | [`zod`](https://github.com/colinhacks/zod) | 必须 | 校验外部输入（API、表单、配置），并推导 TS 类型。 |
| HTTP 请求 | [`ofetch`](https://github.com/unjs/ofetch) | 按需 | `fetch` 增强：自动解析、错误处理、重试。 |
| 命令行接口 | [`commander`](https://github.com/tj/commander.js) / [`citty`](https://github.com/unjs/citty) | 必须 | 通用选 `commander`，unjs/极简选 `citty`。 |
| 环境变量 | [`dotenv`](https://github.com/motdotla/dotenv) | 按需 | 从 `.env` 加载，配合 `zod` 校验；Node 20.6+ 可用内置 `--env-file`。 |
| 工具函数 | [`es-toolkit`](https://github.com/toss/es-toolkit) | 按需 | 替代 lodash，体积更小、原生 TS。 |
| 测试 | [`vitest`](https://github.com/vitest-dev/vitest) | 必须 | 原生支持 ESM/TS；纯 Node 库可用内置 `node:test`。 |
| 日志 | [`pino`](https://github.com/pinojs/pino) | 按需 | 结构化 JSON 日志。 |
| 唯一 ID | [`nanoid`](https://github.com/ai/nanoid) | 按需 | URL 友好短 ID；标准 UUID 直接用 `crypto.randomUUID()`。 |
| 数据库 / ORM | [`drizzle-orm`](https://github.com/drizzle-team/drizzle-orm) | 必须 | TS 原生、类型安全。 |
| 文件 glob 匹配 | [`tinyglobby`](https://github.com/SuperchupuDev/tinyglobby) | 按需 | 比 `glob`/`fast-glob` 更轻。 |
| Lint / 格式化 | [`biome`](https://github.com/biomejs/biome) | 必须 | 一体化；需丰富插件规则时改用 `eslint`(flat config) + `prettier`。 |
| 子进程 / 命令执行 | [`execa`](https://github.com/sindresorhus/execa) | 按需 | 替代原生 `child_process`；简单一次性命令可用 `node:child_process`。 |
| 终端美化 / Spinner | [`picocolors`](https://github.com/alexeyraspopov/picocolors) / [`ora`](https://github.com/sindresorhus/ora) | 按需 | 着色用 `picocolors`，加载动画用 `ora`。 |
| 异步并发控制 | [`p-limit`](https://github.com/sindresorhus/p-limit) | 按需 | 限制 Promise 并发数。 |
| Web 框架 | [`hono`](https://github.com/honojs/hono) / [`fastify`](https://github.com/fastify/fastify) | 必须 | 跨运行时/边缘选 `hono`，Node 高性能 API 选 `fastify`。 |
| 校验 / Schema（轻量） | [`valibot`](https://github.com/fabian-hiller/valibot) | 按需 | 极致 bundle 体积敏感（前端）时替代 `zod`。 |
| 日期格式化（仅展示） | [`date-fns`](https://github.com/date-fns/date-fns) | 按需 | 只做格式化/相对时间、不需完整时区运算时的轻量选择。 |
| 状态管理（前端） | [`zustand`](https://github.com/pmndrs/zustand) | 按需 | 轻量全局状态；复杂数据流再考虑 `redux-toolkit`。 |
| 数据请求 / 缓存（前端） | [`@tanstack/query`](https://github.com/TanStack/query) | 必须 | 服务端状态的缓存、重试、失效管理。 |
| 队列 / 后台任务 | [`bullmq`](https://github.com/taskforcesh/bullmq) | 必须 | 基于 Redis 的可靠任务队列。 |
| WebSocket / 实时 | [`ws`](https://github.com/websockets/ws) | 按需 | 底层 WS；需房间/降级用 `socket.io`。 |
| 数据库迁移 | `drizzle-kit` | 必须 | 与 `drizzle-orm` 配套生成与管理迁移。 |
| 加密 / 哈希 | 内置 [`node:crypto`](https://nodejs.org/api/crypto.html) | 标准库 | 密码哈希用 `scrypt`/`argon2`（`@node-rs/argon2`），不用 `Math.random`。 |

## 选型判据（多候选时如何选）

- **校验库 `zod` vs `valibot`**：默认 `zod`（生态最广、文档最全、与 `drizzle`/表单库集成多）。仅当**前端 bundle 体积是硬约束**、且校验逻辑简单时换 `valibot`（按需 tree-shaking，体积小一个量级）。后端/Node 一律 `zod`。
- **日期 `Temporal` vs `date-fns` vs `dayjs`**：涉及**时区、跨日历、时长运算**用 `Temporal`（未来标准，行为正确）；只做**展示层格式化/相对时间**且不碰时区，用更轻的 `date-fns`；维护既有 `dayjs` 代码时沿用，新项目不新引入 `moment`。
- **Web 框架 `hono` vs `fastify` vs `express`**：跑在**边缘/多运行时**（Cloudflare Workers、Deno、Bun）选 `hono`；**Node 上追求吞吐与 schema 驱动**选 `fastify`；维护老项目才用 `express`，新项目不选（中间件生态虽广但性能与类型支持落后）。
- **错误处理 `neverthrow` vs 原生 `try/catch`**：团队已习惯函数式、希望错误进入类型系统强制处理时用 `neverthrow`；否则用原生 `try/catch` + 自定义 `Error` 子类（保留 `cause`），不要为了「显得现代」强推 `Result`。
- **子进程 `execa` vs `node:child_process`**：需要**跨平台、Promise、流处理、自动转义**用 `execa`；脚本里跑一条简单命令、无复杂参数，直接用内置 `node:child_process`。
- **测试 `vitest` vs `node:test`**：应用/前端、需要 mock/快照/覆盖率一体化用 `vitest`；零依赖的纯 Node 工具库可用内置 `node:test` 减少依赖。
- **ID `nanoid` vs `crypto.randomUUID()`**：需要标准 UUID（数据库主键、跨系统）直接用内置 `crypto.randomUUID()`，不引库；需要**更短、URL 友好、可定制字母表**的 ID 才用 `nanoid`。

> 注：以上为截至 2026-06 的推荐默认项。项目已有等价成熟方案则沿用，保持技术栈一致；定期复核维护状态，及时替换停更依赖。工具链（包管理 / CI / pre-commit）见 [`toolchain.md`](./toolchain.md)。
