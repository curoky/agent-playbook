---
description: 编写 Bash/Shell 脚本，或为 Shell 脚本做写法与工具选型时使用（编码实践 + 工具链）
globs: *.sh,*.bash
alwaysApply: false
---

# Bash/Shell 规则

## 0. 使用边界与基线

- Shell 只做命令粘合和流程编排；出现复杂数据结构、非平凡字符串/数值处理、需单测的业务逻辑时改用 Python/Go。
- 可移植脚本用 `#!/usr/bin/env bash`；确需 POSIX 兼容才用 `#!/bin/sh` 并避免 Bash 专属语法。
- 脚本头统一 `set -euo pipefail`；遍历文件名等场景谨慎设置 `IFS=$'\n\t'`。
- Bash 4.4+ 为基线，推荐 5.x；使用关联数组、`mapfile` 等特性时在文件头标最低版本。
- 现代 Bash：`[[ ... ]]`、`(( ... ))`、`$(...)`、`${var:-default}`、`${var:?msg}`、`${var//a/b}`、数组、`declare -A`、`mapfile -t lines < file`。
- 禁止：`eval` 拼命令、反引号命令替换、解析 `ls` 输出、无引号变量展开、未加引号的裸测试如 `[ $var == ... ]`。

## 1. 风格与结构

- 函数和局部变量 `snake_case`；常量和导出环境变量 `UPPER_SNAKE_CASE`；只读常量用 `readonly`/`declare -r`。
- 变量展开默认加引号：`"$var"`、`"${arr[@]}"`；确需词分割/glob 时显式说明。
- 函数内变量用 `local`；格式用 `shfmt`。
- 用 `main "$@"` 作为入口；顶层只做定义和 `main "$@"` 调用。
- 位置参数用 `"$1"`/`"$@"`；短选项用 `getopts`；复杂 CLI 改用其他语言。
- 可复用逻辑放 `lib/*.sh` 并用 `source`/`.` 引入；被 source 的文件不写顶层副作用。

## 2. 错误、清理、子进程

- 依赖 `set -euo pipefail`；容错命令用显式判断或局部 `|| true`，不全局关闭严格模式。
- 临时文件、后台进程用 `trap 'cleanup' EXIT` 或 `trap ... ERR` 清理。
- 外部命令先 `command -v tool >/dev/null` 校验；参数缺失/非法时向 stderr 输出用法并非零退出。
- 成功 `exit 0`；失败用有区分度的非零码。正常结果输出 stdout，错误/日志输出 stderr。
- `&` 启动的后台任务必须 `wait`/`wait -n` 回收并捕获退出码。
- 批量并行优先 `xargs -P N -0`（配 `find -print0`）或 GNU `parallel`；避免无上限 `&`。
- 管道和 `( ... )` 会开子 shell；需要变量回传时用进程替换 `< <(...)` 或 `mapfile`。

## 3. 文本处理与性能

- 能用 Bash 内建就不 fork 外部命令：参数展开、`[[ ]]`、`(( ))`。
- 大文本批处理交给 `awk`/`grep`/`sort` 等一次性处理；避免逐行 Bash 循环里反复调外部命令。
- 避免 `cat file | cmd`；用 `cmd < file` 或让命令直接读文件。

## 4. 注释与测试

- 文件头写脚本用途、`Usage:`、外部命令依赖、最低 Bash 版本。
- 非平凡函数注释入参、全局副作用、返回约定；注释写意图，不复述命令。
- 测试用 [`bats-core`](https://github.com/bats-core/bats-core)；可测逻辑拆成函数后在测试中 `source`。
- `shellcheck` 零告警是最低门槛。
- 测试用 `mktemp -d`，通过 `PATH` 前置桩 mock 外部命令；不依赖真实网络/全局状态。

## 5. 安全与日志

- 外部输入当不可信数据；所有展开加引号防词分割和 glob。
- 禁止 `eval` 和拼接未过滤输入；调用命令用参数数组：`cmd "${args[@]}"`。
- 路径/参数用 `--` 终结选项，避免选项注入。
- 临时文件用 `mktemp`/`mktemp -d`，配 `trap ... EXIT`；不用可预测固定路径。
- 密钥/令牌不硬编码、不打日志。调试 `set -x` 注意敏感信息，用完 `set +x`。
- 非平凡脚本日志带时间戳与级别；批量循环避免逐条刷屏。
- 错误日志带命令、目标路径/参数、退出码。

## 6. 工具链

| 用途 | 工具 |
| --- | --- |
| 格式化 | [`shfmt`](https://github.com/mvdan/sh)，如 `shfmt -i 2 -ci`。 |
| Lint/静态分析 | [`shellcheck`](https://github.com/koalaman/shellcheck)，CI 零告警。 |
| 测试 | [`bats-core`](https://github.com/bats-core/bats-core)，可配 `bats-assert`/`bats-support`。 |

- pre-commit 用 [`lefthook`](https://github.com/evilmartians/lefthook)：对暂存 `*.sh`/`*.bash` 跑 `shfmt -d` 或 `-l`、`shellcheck`；CI 重复执行并运行 `bats`。
