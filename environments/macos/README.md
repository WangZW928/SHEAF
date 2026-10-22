# SHEAF 工作环境 — macOS

平台标记：`macos`。本次配置主机：Apple Silicon / arm64，macOS 26.6.2。
Windows 配置另放在 [`../windows/`](../windows/README.md)，尚未部署或验证。
验证日期：2026-10-21；结果见 [`VALIDATION.md`](VALIDATION.md)。

## 进入环境

在 SHEAF 仓库根目录运行：

```bash
./environments/macos/run.sh
```

这会打开一个已经配置好 PATH 的 Bash。也可以只执行一条命令：

```bash
./environments/macos/run.sh lean --version
./environments/macos/run.sh python3 environments/macos/doctor.py
./environments/macos/run.sh python3 environments/macos/smoke.py
```

入口保留当前工作目录，因此可以从具体项目目录通过绝对路径调用。
退出 Bash 用 `exit`。不需要修改 `~/.zshrc`、系统默认 shell 或全局 Git 配置。
不要用 `/bin/bash tools/…` 绕过入口；macOS 自带 Bash 3.2 不支持这些脚本的 `mapfile`。

VS Code 的 Lean 4 扩展已安装。打开专属工作区：

```bash
code environments/macos/SHEAF-macos.code-workspace
```

该工作区标为 `SHEAF (macOS)`，内置终端使用 Mac 环境入口，Lean 扩展通过
`editor-bin/` 包装器使用仓库本地的 elan 工具链，即使 VS Code 先前已启动也不依赖
它继承终端的 `ELAN_HOME`。这些设置只作用于这个工作区。

## 安装与版本

新 Mac 已有 Homebrew 时：

```bash
./environments/macos/bootstrap.sh
./environments/macos/prepare-mathlib.sh
```

Homebrew 依赖：`tmux bash coreutils findutils grep elan-init python@3.14`。
Python 使用本地 venv；脚本使用 Bash 4+ 和 GNU 工具。Linux 的 `ionice`
在 macOS 上是可选项，文件复制本身仍会执行。

版本基线集中在 [`versions.env`](versions.env)：Lean / Mathlib 为 `v4.35.0`，
Lean 技能固定到具体 Git commit。各论文项目依旧使用自己的 `lean-toolchain`
和 Lake manifest；环境入口不会用 `ELAN_TOOLCHAIN` 强制覆盖项目版本。

下载需要代理时，在命令前设置 `HTTPS_PROXY` 和 `HTTP_PROXY`，例如：

```bash
HTTPS_PROXY=http://127.0.0.1:7897 HTTP_PROXY=http://127.0.0.1:7897 \
  ./environments/macos/bootstrap.sh
```

这里的端口只是本机配置示例；另一台机器应使用自己的代理。代理没有写入 Git
配置、脚本默认值或 shell 启动文件。

## 本地文件与 Mathlib

所有下载、缓存和验证临时文件都在 Git 忽略的 `.local/macos/` 下：

| 目录 | 用途 |
| --- | --- |
| `venv/` | Python 3.14 虚拟环境 |
| `elan/` | 当前仓库专用 Lean 工具链和默认版本 |
| `lean4-skills-source/` | 固定版本的 Lean 4 技能及辅助脚本 |
| `mathlib/` | 固定版本的 Mathlib 验证副本 |
| `mathlib-cache/` | Mathlib 下载缓存 |

技能安装在仓库的 `.agents/skills/lean4`，供后续 SHEAF 会话发现。
`run.sh` 同时设置技能所需的 `LEAN4_PLUGIN_ROOT`、`LEAN4_SCRIPTS`、`LEAN4_REFS`
和辅助命令路径。这是项目范围的 portable 配置，不安装全局插件或 hooks。

`prepare-mathlib.sh` 默认只下载 `Mathlib.Data.Nat.Basic` 及其依赖的缓存，并实际
编译一次导入检查。下载整库缓存可运行：

```bash
./environments/macos/prepare-mathlib.sh Mathlib
```

这份验证副本不是论文项目。开始正式项目时，按仓库 `AGENTS.md` 创建独立项目，
固定 Mathlib 依赖并在该项目的 `lean/` 目录运行 `lake exe cache get`。
SHEAF 全局构建器要求完整的 Mathlib 缓存，避免从共享构建副本重建依赖。

## 持久会话

从 SHEAF 根目录启动一个专用 tmux 服务器中的工作终端：

```bash
./environments/macos/run.sh tmux -L sheaf-macos new-session -s sheaf-macos \
  "$PWD/environments/macos/run.sh"
```

这样即使机器上已有别的 tmux 服务器，新会话也会明确加载 Mac 环境。
进入后再运行 `codex` 或项目命令；离开但保持运行用 `Ctrl-b d`，重新连接：

```bash
./environments/macos/run.sh tmux -L sheaf-macos attach -t sheaf-macos
```

本次配置不启动论文任务或后台 AI 会话。

实际单目标演示发现：`workspace-write` AI 沙箱可能禁止写入项目 `.git`。
worker 可以在沙箱内领取任务、编译和落库；负责创建提交快照的 maintainer
需要另行获准的 Git 写权限。构建脚本现在遇到快照写入失败会停止，不会把
无效的 `HEAD` 当作已验证提交。相关回归检查：

```bash
./environments/macos/run.sh python3 environments/macos/test_snapshot.py
```

## 验证范围

`doctor.py` 检查可执行文件、Python/Bash 语法、GNU 工具的实际能力及 Lean 版本。
`smoke.py` 在临时独立 Git 仓库中用 Lake 自带模板创建测试工程，检查 Lean 编译、
排他任务领取、队列、构建快照、构建产物发布、worker 镜像、文件落库和 tmux 健康检查。
它只关闭自己创建的独立 tmux socket，结束后清理自己的临时项目。

以上验证不代表论文证明已经完成，也不验证模型账号额度。
最终目标验收仍应检查锁定目标的语义与允许的公理。

Lean 4.35.0 已内置 `lake comparator` 和 `lake check`；旧的
[`leanprover/comparator`](https://github.com/leanprover/comparator) 已声明迁移到这些命令。
已验证内置工具的帮助入口，但其默认沙箱需要 Linux `bubblewrap` / `bwrap`，
本机原生 macOS 未完成该沙箱验收。正式项目应在 Linux 或未来的 WSL 环境执行
完整的 `lake comparator` 验收；这里没有关闭沙箱。项目自己的编译、目标类型检查
和公理检查仍可在 Mac 上进行。

参考：[Lean 官方安装说明](https://lean-lang.org/install/manual/)、
[Homebrew elan-init](https://formulae.brew.sh/formula/elan-init)、
[Lean 技能安装说明](https://github.com/cameronfreer/lean4-skills/blob/83582df9d9172456993929f32ac4dd9d99c6211c/INSTALLATION.md)。
