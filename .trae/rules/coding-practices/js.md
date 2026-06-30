---
description: 编写 JavaScript/TypeScript 代码时的编码实践明细（命名、类型与错误、异步、测试、安全等的 JS/TS 特有写法）
globs: *.ts,*.tsx,*.js,*.jsx,*.mts,*.cts
alwaysApply: false
---

# 编码实践 · JavaScript / TypeScript

> 本文件是 [`common.md`](./common.md) 的 JS/TS 明细，列出各主题在 JS/TS 下的特有写法；通用核心原则见 `common.md`，版本基线总表见 [`main.md`](../main.md)。

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
- **格式工具**：缩进、引号、分号、import 排序交给 `biome`（或 `eslint` + `prettier`）自动处理。

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
