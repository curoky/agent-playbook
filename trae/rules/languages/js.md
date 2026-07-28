---
description: 编写 JavaScript/TypeScript 代码，或为 JS/TS 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.ts,*.tsx,*.js,*.jsx,*.mts,*.cts,package.json,tsconfig*.json,biome.json,biome.jsonc,pnpm-workspace.yaml
alwaysApply: false
---

# JavaScript / TypeScript 规则

## 0. 基线

- 新代码使用官方最新稳定 TypeScript（截至 2026-07 为 7.0.x）；新文件用 `.ts`/`.tsx`。需 Compiler API 的工具并装 `@typescript/typescript6` 兼容包，不把项目编译器降级。
- `tsconfig.json`: `strict: true`、`target: es2025`、`module: esnext`；建议 `noUncheckedIndexedAccess`。模块统一 ESM (`import`/`export`)。
- 生产项目用 Node 24 Active LTS；明确追新且依赖已兼容时可用 Node 26 Current。`package.json` 写对应 `engines`、`"type": "module"` 与精确 `packageManager`，`.nvmrc` 或 Volta 锁具体 Node patch。
- 现代语法优先：`?.`、`??`、解构、展开、模板字符串、`async`/`await`、顶层 `await`、`Array.at/findLast/toSorted`、`??=`/`||=`；可读性优先。
- 禁止：`var`、`==`/`!=`、`namespace`、CommonJS `require`/`module.exports`、`enum`（用 `as const` 联合类型）、`any`。

## 1. 风格与模块

- 命名：变量/函数 `camelCase`，类型/类 `PascalCase`，常量 `UPPER_SNAKE_CASE`，文件 `kebab-case`；布尔用 `is`/`has` 前缀。
- 魔法值提取为有名常量或 `as const` 联合类型。
- 格式、分号、引号、import 排序交给 `biome`，配置入 `biome.json`。
- 函数超过一屏、出现阶段性注释、或名称需用 `and` 描述时拆分。
- 参数超过 3 个用 options 对象；避免布尔陷阱参数，改用枚举或拆函数。
- 公共 API 用具名导出，避免 default export；只暴露必要接口。
- 高层逻辑依赖 `interface` 并由外部注入实现；避免深处直接 `new` 具体依赖和循环依赖。

## 2. 类型、错误、资源

- 禁止 `any`；外部未知值用 `unknown` 加类型收窄。
- API 响应、用户输入、配置、环境变量等边界用 `zod` 校验后进入内部类型。
- 互斥状态用 discriminated union；可能缺失写成 `T | undefined` 并就近处理。
- 可预期失败（找不到、校验失败、外部调用失败）优先用 `neverthrow` 的 `Result`；不可恢复异常才 `throw`。
- `catch` 必须恢复、转换、上报或带上下文重抛；禁止吞错或只 `console.log` 后继续。
- 重抛用 `new Error(message, { cause })`；资源释放用 `try/finally` 或 `using`/`await using`。

## 3. 异步与并发

- 统一 `async`/`await`；不混用回调和裸 `.then` 链。
- IO 密集用 Promise 并发；CPU 密集用 `worker_threads`，不阻塞事件循环。
- 独立任务用 `Promise.all`/`Promise.allSettled`；批量并发用 `p-limit`。
- Promise 拒绝必须被处理；长任务用 `AbortController`/`AbortSignal` 支持取消和超时。
- `useMemo`/`memo` 仅在 profiler 证明昂贵或引用稳定性影响下游渲染时使用。

## 4. 注释与测试

- 注释写意图、约束、权衡、坑；不复述代码。公共导出用 TSDoc。
- 改代码同步改注释；删被注释掉的死代码；`TODO`/`FIXME`/`HACK` 附负责人或 issue。
- 测试默认 `vitest`；零依赖纯 Node 库可用 `node:test`。
- 测公共行为和边界，不测私有实现；外部依赖 mock/stub，时间用可注入时钟。
- 修 bug 先写复现用例；覆盖率是参考，不是目标。

## 5. 安全与日志

- 外部输入先校验，按 HTML/SQL/Shell/URL 输出上下文转义。
- SQL 用参数化或 `drizzle-orm` 占位符；子进程用 `execa` 参数数组；不拼 SQL/命令行。
- 密码用 `argon2`/`bcrypt`；随机数用 `node:crypto`，不用 `Math.random`。
- 正式日志用 `pino` 结构化 JSON；`console.log` 只作临时调试，提交前清理。
- 级别：`debug`/`info`/`warn`/`error`；生产默认 `info`。日志带请求 ID、用户 ID、模块名等字段。
- 热路径避免高频 `info`；错误日志带原始错误/堆栈；禁止记录口令、令牌、隐私数据。

## 6. 库选型

- 选现代、主流、积极维护的库：原生 TS 类型、ESM、async/await；不确定时核实发布时间与活跃度。
- 高风险依赖（久未维护、star 少、小众）先说明维护/安全/替代风险并确认。
- 新项目避免 `moment`、`request`、`lodash`；平台能力够用时不引库。
- 能明显减少代码或降低误用概率时默认引入；体积/依赖复杂度只在多个合格候选间加权。
- WebUI 加权：文档全、语料多、约定固定、强类型、源码可见可改；不凌驾于维护性和主流性。

| 场景 | 默认 | 条件 |
| --- | --- | --- |
| 路径 | `pathe` | 必须；跨平台路径一致。 |
| 错误结果 | `neverthrow` | 按需；希望错误进入类型系统时用，否则用原生 `try/catch` + 保留 `cause`。 |
| 日期/时间 | `Temporal` | 时区/跨日历/时长运算用；运行时缺失用 `@js-temporal/polyfill`；展示格式化/相对时间用 `date-fns`，既有 `dayjs` 可沿用。 |
| Schema | `zod` | 必须；前端 bundle 是硬约束且校验简单时用 `valibot`。 |
| HTTP | `ofetch` | 按需；需要自动解析、错误处理、重试时用。 |
| CLI | `commander` / `citty` | 必须；通用选 `commander`，unjs/极简选 `citty`。 |
| 环境变量 | `dotenv` | 按需；Node 20.6+ 可用 `--env-file`，仍配 `zod` 校验。 |
| 工具函数 | `es-toolkit` | 按需；替代 lodash。 |
| 测试 | `vitest` | 必须；纯 Node 库可用 `node:test`。 |
| 日志 | `pino` | 按需；结构化 JSON。 |
| ID | `crypto.randomUUID()` / `nanoid` | 标准 UUID 用内置；短 URL 友好 ID 用 `nanoid`。 |
| 数据库/ORM | `drizzle-orm` + `drizzle-kit` | 必须；TS 原生、类型安全、迁移配套。 |
| Glob | `tinyglobby` | 按需；替代 `glob`/`fast-glob`。 |
| Lint/格式化 | `biome` | 必须；需丰富插件规则时 Lint 可用 `eslint` flat config，format 仍用 `biome`。 |
| 子进程 | `execa` | 按需；简单一次性命令可用 `node:child_process`。 |
| 终端输出 | `picocolors` / `ora` | 按需；着色/加载动画。 |
| 并发限流 | `p-limit` | 按需。 |
| Web 框架 | `hono` / `fastify` | 必须；边缘/多运行时选 `hono`，Node 高吞吐/schema 驱动选 `fastify`，维护老项目才用 `express`。 |
| 前端数据缓存 | `@tanstack/query` | 必须；服务端状态缓存、重试、失效。 |
| React UI | `Radix Themes` | 按需；需组件源码入仓选 `shadcn/ui`（接受升级靠 copy/diff）。 |
| 前端状态 | `zustand` | 按需；复杂数据流再考虑 `redux-toolkit`。 |
| 队列 | `bullmq` | 必须；Redis 可靠任务队列。 |
| WebSocket | `ws` | 按需；需房间/降级用 `socket.io`。 |
| 加密/哈希 | `node:crypto` / `@node-rs/argon2` | 标准库优先；密码哈希用 `scrypt`/`argon2`。 |

## 7. 工具链

| 用途 | 工具 |
| --- | --- |
| 包管理 | `pnpm`，提交 `pnpm-lock.yaml`。 |
| Lint/格式化 | `biome`，配置 `biome.json`。 |
| 类型检查 | `tsc --noEmit`，`strict: true`。 |
| 测试 | `vitest`。 |
| 构建/打包 | `tsdown`；应用用框架构建；存量 `tsup` 项目按官方迁移指南升级。 |
| 直接运行 TS | `tsx`。 |

- pre-commit 用 `lefthook` 跑 `biome check --staged`；CI 跑全项目 `biome ci`、`tsc --noEmit`、`vitest` 与构建。
