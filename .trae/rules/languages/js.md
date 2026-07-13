---
description: 编写 JavaScript/TypeScript 代码，或为 JS/TS 项目做技术选型、引入第三方库、在多个候选库间抉择时使用（编码实践 + 库选型）
globs: *.ts,*.tsx,*.js,*.jsx,*.mts,*.cts
alwaysApply: false
---

# JavaScript / TypeScript 语言规范（编码实践 + 库选型）

> JS/TS 明细：通用原则见 [`common.md`](./common.md)，版本基线见 [`main.md`](../main.md)，工具链通用约定见 [`toolchain.md`](../toolchain.md)。

## 0. 语言版本与语法

- **一律使用 TypeScript**，不写裸 JavaScript；新文件使用 `.ts` / `.tsx`。
- `tsconfig.json` 中必须启用 `strict: true`（建议再开 `noUncheckedIndexedAccess`）；模块系统统一用 **ESM**（`import`/`export`），不用 CommonJS。
- **版本锁定**：`package.json` 设置 `"engines": { "node": ">=22" }` 与 `"type": "module"`；用 `.nvmrc` / Volta 固定本地 Node 版本。
- 优先采用现代语法简化代码，例如：
  - 可选链 `?.` 与空值合并 `??`，替代层层 `&&` 判空。
  - 解构、展开运算符 `...`、模板字符串，替代手动拼接。
  - `async`/`await` 替代回调与裸 `Promise.then` 链。
  - 顶层 `await`、`Array` 新方法（`at`、`findLast`、`toSorted` 等）、逻辑赋值运算符（`??=`、`||=`）。
- **禁止**：`var`（用 `const`/`let`）、`==`/`!=`（用 `===`/`!==`）、`namespace`（用 ESM 模块）、CommonJS `require`/`module.exports`、`enum`（优先 `as const` 联合类型）；`any` 见 §3。

## 1. 命名与代码风格

- **大小写惯例**：变量/函数 `camelCase`、类型/类 `PascalCase`、常量 `UPPER_SNAKE_CASE`、文件名 `kebab-case`。
- **避免魔法值**：字面量提取为有名常量或 `as const` 联合类型。
- **格式工具**：缩进、引号、分号、import 排序统一交给 `biome`（配置 `biome.json`）自动处理，作为唯一 format 工具。

## 2. 函数与模块设计

- **参数精简**：参数超过 3 个时改用 options 对象。
- **明确公共 API**：用具名导出（避免 default export）暴露最小必要接口。
- **依赖倒置**：高层逻辑依赖 `interface`，由外部注入实现，避免在深处直接 `new` 具体依赖。

## 3. 类型安全与错误处理

- **不使用逃逸类型**：禁止 `any`，用 `unknown` + 类型收窄。
- **在边界校验外部输入**：API 响应、用户输入、配置、环境变量等用 `zod` 做 Schema 校验，之后内部代码可信任其类型。
- **让非法状态不可表示**：用 discriminated union 建模互斥状态，避免「多个布尔标志组合出非法态」。
- **避免 `null`/`undefined` 蔓延**：用可选链与空值合并就近处理；对「可能不存在」的返回值用显式类型标注（`T | undefined`），不靠隐式约定。
- **可预期错误用值表达**：业务上可预期的失败优先用 `neverthrow` 的 `Result`，而非裸 `throw`。
- **异常用于不可恢复错误**：捕获时区分具体错误类型，禁止裸 `catch (e)` 不处理、禁止只 `console.log` 后继续。
- **保留上下文**：重新抛出时用 `new Error(msg, { cause })` 携带原始错误。
- **资源清理可靠**：用 `try/finally` 或 `using`/`await using`（TS 5.2+）确保资源释放。

## 4. 异步与并发

- **统一异步模型**：全程 `async`/`await`，不混用裸 `.then` 链与回调。
- **并发要并行**：独立任务用 `Promise.all`/`Promise.allSettled` 并发执行，不要串行 `await`。
- **限制并发度**：批量并发用 `p-limit` 限制上限。
- **不吞异步异常**：每个 Promise 的拒绝都必须被处理；禁止「发射后不管」的悬空 Promise。
- **支持取消与超时**：长任务用 `AbortController`/`AbortSignal` 取消，避免无限等待。

## 5. 性能与优化

- **基准可复现**：关键算法/接口用 `vitest bench` 写 benchmark，优化前后对比并纳入回归。
- **CPU 密集放 worker**：阻塞超过个位数毫秒的同步计算（大 JSON、加解密、图像处理）移到 `worker_threads`/`Worker`，不卡事件循环。
- **React memo 有据再加**：`useMemo`/`memo` 仅在「该计算被 profiler 证明昂贵」或「引用稳定性影响下游渲染」时加，不默认包裹，避免缓存开销反而拖慢。

## 6. 注释与文档

- **公共 API 文档**：导出的函数/类/模块用 TSDoc（`@param`/`@returns`/`@throws`）。

## 7. 测试规范

- **框架**：用 `vitest` 统一单测与覆盖率。
- **隔离与确定性**：外部依赖用 mock/stub，时间用可注入的时钟。

## 8. 安全编码

- **校验并转义输入**：外部输入先用 `zod` 校验再使用；按输出上下文转义（HTML/SQL/Shell/URL）防注入。
- **杜绝注入**：SQL 用参数化或 ORM（`drizzle-orm` + 占位符），禁止拼接 SQL；执行子进程用 `execa` 传参数数组，不拼接命令行。
- **安全使用加密**：密码用 `argon2`/`bcrypt` 哈希（不用 MD5/SHA1）；随机数用 `crypto`，不用 `Math.random`。

## 9. 库选型

> 继承 [`main.md`](../main.md) 的选型规则：现代化、主流、积极维护；高风险依赖先说明风险并确认。JS/TS 还遵循：
>
> - **必须**：能大幅简化代码或 API 明显更不易出错（如 `zod`）。
> - **按需**：与平台/标准能力差别不大、仅有性能或便利收益（如 `picocolors`）。
> - **平台优先**：Node 22+ 与浏览器原生能力够用时不引库，如 `crypto.randomUUID()`、`structuredClone`、`fetch`、`URL`、`Intl`。
> - **WebUI AI 友好**：同等条件下优先文档全/语料多、约定固定、强类型、源码可见可改的技术栈；这只是加权因素，不凌驾于现代化/主流/积极维护之上。

### 速查表

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
| UI 组件库（React WebUI） | [`Radix Themes`](https://github.com/radix-ui/themes) | 按需 | React WebUI 默认选择；自带主题/样式系统（不依赖 Tailwind），无障碍性由 Radix 原语保证，官方文档完备。仅适用 React 栈。 |
| 队列 / 后台任务 | [`bullmq`](https://github.com/taskforcesh/bullmq) | 必须 | 基于 Redis 的可靠任务队列。 |
| WebSocket / 实时 | [`ws`](https://github.com/websockets/ws) | 按需 | 底层 WS；需房间/降级用 `socket.io`。 |
| 数据库迁移 | `drizzle-kit` | 必须 | 与 `drizzle-orm` 配套生成与管理迁移。 |
| 加密 / 哈希 | 内置 [`node:crypto`](https://nodejs.org/api/crypto.html) | 标准库 | 密码哈希用 `scrypt`/`argon2`（`@node-rs/argon2`），不用 `Math.random`。 |

### 选型判据（多候选时如何选）

- **校验库 `zod` vs `valibot`**：默认 `zod`（生态最广、文档最全、与 `drizzle`/表单库集成多）。仅当**前端 bundle 体积是硬约束**、且校验逻辑简单时换 `valibot`（按需 tree-shaking，体积小一个量级）。后端/Node 一律 `zod`。
- **日期 `Temporal` vs `date-fns` vs `dayjs`**：涉及**时区、跨日历、时长运算**用 `Temporal`（未来标准，行为正确）；只做**展示层格式化/相对时间**且不碰时区，用更轻的 `date-fns`；维护既有 `dayjs` 代码时沿用，新项目不新引入 `moment`。
- **Web 框架 `hono` vs `fastify` vs `express`**：跑在**边缘/多运行时**（Cloudflare Workers、Deno、Bun）选 `hono`；**Node 上追求吞吐与 schema 驱动**选 `fastify`；维护老项目才用 `express`，新项目不选（中间件生态虽广但性能与类型支持落后）。
- **错误处理 `neverthrow` vs 原生 `try/catch`**：团队已习惯函数式、希望错误进入类型系统强制处理时用 `neverthrow`；否则用原生 `try/catch` + 自定义 `Error` 子类（保留 `cause`），不要为了「显得现代」强推 `Result`。
- **子进程 `execa` vs `node:child_process`**：需要**跨平台、Promise、流处理、自动转义**用 `execa`；脚本里跑一条简单命令、无复杂参数，直接用内置 `node:child_process`。
- **测试 `vitest` vs `node:test`**：应用/前端、需要 mock/快照/覆盖率一体化用 `vitest`；零依赖的纯 Node 工具库可用内置 `node:test` 减少依赖。
- **ID `nanoid` vs `crypto.randomUUID()`**：需要标准 UUID（数据库主键、跨系统）直接用内置 `crypto.randomUUID()`，不引库；需要**更短、URL 友好、可定制字母表**的 ID 才用 `nanoid`。
- **UI 组件库 `Radix Themes` vs 其他方案**：**React** 项目默认 `Radix Themes`——它是传统 npm 组件库（作依赖安装、升级走包管理器），自带主题/样式系统、不依赖 Tailwind，无障碍性由底层 Radix 原语保证。选它的核心理由是**对 AI agent 友好**：React + TS 类型完备、约束强（强类型约束）；主题令牌与组件 API 约定式、模式固定（约定式）；官方文档完备、社区语料充分、AI 对其 API 熟悉少幻觉（文档全/语料多）。**不用 React** 时不适用，改选对应生态的成熟组件库（Vue 用 Element Plus、Svelte 用 shadcn-svelte 等），本规则暂不为其展开推荐。若需要「组件源码进仓库、可自由改」的形态，可改用同属 Radix 生态的 `shadcn/ui`（Radix 原语 + Tailwind），代价是升级靠 copy/diff 而非包管理器。

> 注：截至 2026-06 的默认推荐；既有项目沿用等价成熟方案，并定期复核维护状态。

## 10. 工具链

> 跨语言要求见 [`toolchain.md`](../toolchain.md)：配置入库，本地/pre-commit/CI 一致。

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 包管理 | [`pnpm`](https://github.com/pnpm/pnpm) | 原生支持 workspace；提交 `pnpm-lock.yaml`。 |
| Lint + 格式化 | [`biome`](https://github.com/biomejs/biome) | 一体化；format 统一用 `biome`（`biome.json`），需丰富插件规则时 Lint 可退回 `eslint`，但 format 仍用 `biome`。 |
| 类型检查 | `tsc --noEmit` | `strict: true`。 |
| 测试 | [`vitest`](https://github.com/vitest-dev/vitest) | 统一单测与覆盖率。 |
| 构建 / 打包 | [`tsup`](https://github.com/egoist/tsup) / [`tsdown`](https://github.com/rolldown/tsdown) | 库用零配置打包；应用按框架自带构建（Vite 等）。 |
| 直接运行 TS | [`tsx`](https://github.com/privatenumber/tsx) | 免编译执行 `.ts`。 |

- **提交前检查（pre-commit）**：用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理 git hook，在 `lefthook.yml` 的 `pre-commit` 中对暂存文件（`{staged_files}` + `glob: "*.{ts,tsx,js,jsx}"`）跑 `biome` 与 `tsc`。
