---
description: 编写 Bash/Shell 脚本，或为 Shell 脚本做写法与工具选型时使用（编码实践 + 工具链）
globs: *.sh,*.bash
alwaysApply: false
---

# Bash/Shell 脚本规范（编码实践 + 工具链）

> 本文件汇总 Bash/Shell 脚本的**编码实践**（[`common.md`](./common.md) 的 Shell 明细）与**工具链**。通用核心原则见 [`common.md`](./common.md)，版本基线总表见 [`main.md`](../main.md)，跨语言工具链约定见 [`toolchain.md`](../toolchain.md)。基线以 **Bash** 为准（`#!/usr/bin/env bash` + `set -euo pipefail`）。
>
> **何时不该用 Shell**：脚本一旦出现复杂数据结构、非平凡的字符串/数值处理、需要单元测试的业务逻辑，就改用 Python/Go 重写，不要硬撑 Bash。Shell 只适合「粘合命令、编排流程」。

## 0. 语言版本与语法

- **固定 shebang**：可移植脚本用 `#!/usr/bin/env bash`；确需 POSIX 兼容（如 `sh`/`dash`）才用 `#!/bin/sh`，并避免 Bash 专属语法。
- **严格模式**：脚本头统一 `set -euo pipefail`（遇错即停、未定义变量报错、管道任一环节失败即失败）；需要遍历文件名等场景时谨慎设置 `IFS=$'\n\t'`。
- **版本锁定**：以 Bash 4.4+ 为基线（推荐 5.x），需要 4.x 以上特性（关联数组、`mapfile`）时在文件头注释说明最低版本要求。
- 优先采用现代 Bash 语法简化代码，例如：
  - `[[ ... ]]` 做条件判断（替代 `[ ... ]`，避免词分割与解引用陷阱），算术用 `(( ... ))`。
  - 命令替换用 `$(...)`（替代反引号），参数展开用 `${var:-default}`/`${var:?msg}`/`${var//a/b}`。
  - 数组 `arr=(...)` 与关联数组 `declare -A map`，读文件用 `mapfile -t lines < file`（替代 `for line in $(cat ...)`）。
- **禁止**：`eval` 拼接命令、反引号命令替换、解析 `ls` 输出（改用 glob 或 `find -print0` + `read -d ''`）、无引号的变量展开（词分割/glob 展开风险）、用 `[ $var == ... ]` 这类未加引号的裸测试。

## 1. 命名与代码风格

- **大小写惯例**：函数与局部变量用 `snake_case`，常量与导出的环境变量用 `UPPER_SNAKE_CASE`；只读常量用 `readonly`/`declare -r`。
- **变量必加引号**：一律 `"$var"`/`"${arr[@]}"`，防止词分割与通配符展开（除非确需展开）。
- **局部化变量**：函数内变量一律 `local` 声明，避免污染全局命名空间。
- **格式工具**：缩进、对齐、换行统一交给 `shfmt` 自动处理，不在 review 讨论格式。

## 2. 函数与模块设计

- **单一职责**：函数小而专一；用 `main "$@"` 作为入口，把顶层逻辑收拢到 `main` 而非散在文件顶层。
- **参数处理**：位置参数用 `"$1"`/`"$@"` 并加引号；带选项的脚本用 `getopts` 解析短选项，复杂 CLI 优先转用其他语言。
- **复用拆分**：可复用逻辑拆到 `lib/*.sh`，用 `source`（`.`）引入；被 source 的库文件不写顶层副作用，仅定义函数。

## 3. 健壮性与错误处理

- **严格模式兜底**：依赖 `set -euo pipefail`；对确需容错的命令显式 `|| true` 或单独判断，不靠全局关闭。
- **清理用 trap**：临时文件/后台进程用 `trap 'cleanup' EXIT` 或 `trap ... ERR` 保证退出时清理，不留残留。
- **前置校验**：使用外部命令前用 `command -v tool >/dev/null || { echo "..." >&2; exit 1; }` 检查存在性；参数缺失/非法时向 `>&2` 打印用法并以非零码 `exit`。
- **明确退出码**：成功 `exit 0`、失败用有区分度的非零码；错误信息一律输出到 stderr（`>&2`），正常结果输出到 stdout。

## 4. 并发与子进程

- **后台任务收口**：`&` 启动的后台任务必须 `wait`（或 `wait -n`）回收，捕获其退出码，不留悬空子进程。
- **限制并发度**：批量并行优先 `xargs -P N -0`（配 `find -print0`）或 GNU `parallel`，不要无上限地 `&`。
- **注意子 shell 作用域**：管道与 `( ... )` 会开子 shell，其中的变量赋值不回传父进程；需要回传时改用进程替换 `< <(...)` 或 `mapfile`。

## 5. 性能与优化

- **减少 fork**：能用 Bash 内建（参数展开 `${var//}`、`[[ ]]`、`(( ))`）就不 fork 外部命令（`sed`/`awk`/`cut`/`expr`）。
- **避免逐行 bash 循环处理大文本**：大批量文本交给 `awk`/`grep`/`sort` 一次性处理，而非 `while read` 里反复调外部命令。
- **无用 cat**：避免 `cat file | cmd`（UUOC），直接 `cmd < file` 或让命令读文件。

## 6. 注释与文档

- **文件头注释**：说明脚本用途、用法示例（`Usage:`）、依赖的外部命令与最低 Bash 版本。
- **函数注释**：非平凡函数在上方注释入参、全局副作用与返回约定；注释写「为什么」而非复述命令。

## 7. 测试规范

- **框架**：用 [`bats-core`](https://github.com/bats-core/bats-core) 编写脚本测试；把可测逻辑拆成函数便于在测试中 `source` 后单独调用。
- **静态检查即测试基线**：以 `shellcheck` 零告警作为最低门槛，覆盖大量常见 bug 与陷阱。
- **隔离确定**：测试用 `mktemp -d` 建临时目录、mock 外部命令（通过 `PATH` 前置桩），不依赖真实网络/全局状态。

## 8. 安全编码

- **变量引号化防注入**：所有展开加引号防词分割与通配；把外部输入当不可信数据处理。
- **杜绝命令注入**：禁止 `eval` 与用未过滤输入拼接命令；调用命令时用参数数组（`cmd "${args[@]}"`）而非拼接字符串；路径/参数以 `--` 终结选项，避免被当选项注入。
- **临时文件安全**：用 `mktemp`/`mktemp -d` 创建，配 `trap ... EXIT` 清理，不用可预测的固定路径。
- **不泄漏密钥**：密钥/令牌不硬编码进脚本、不打进日志；调试用 `set -x` 时注意敏感信息泄漏，用完 `set +x`。

## 10. 工具链

> 跨语言通用要求（配置入库、本地/pre-commit/CI 一致、CI 重复执行同一套检查）见 [`toolchain.md`](../toolchain.md)。

| 用途 | 工具 | 说明 |
| --- | --- | --- |
| 格式化 | [`shfmt`](https://github.com/mvdan/sh) | 统一缩进与风格（如 `shfmt -i 2 -ci`）；格式不入 review 讨论。 |
| Lint / 静态分析 | [`shellcheck`](https://github.com/koalaman/shellcheck) | 覆盖引号、词分割、未定义变量等常见陷阱；CI 强制零告警。 |
| 测试 | [`bats-core`](https://github.com/bats-core/bats-core) | 脚本行为测试；配 `bats-assert`/`bats-support` 简化断言。 |

- **提交前检查（pre-commit）**：用 [`lefthook`](https://github.com/evilmartians/lefthook) 管理 git hook，在 `lefthook.yml` 的 `pre-commit` 中对暂存 `*.sh`/`*.bash` 跑 `shfmt -d`（或 `-l`）与 `shellcheck`；CI 中重复执行同一套检查，并运行 `bats` 测试。
