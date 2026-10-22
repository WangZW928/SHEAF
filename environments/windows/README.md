# SHEAF 工作环境 — Windows（WSL2）

平台标记：`windows`。目标主机：Windows 11 + WSL2（Ubuntu 24.04 x86_64 验证）。
macOS 配置另见 [`../macos/`](../macos/README.md)。
验证日期与结果见 [`VALIDATION.md`](VALIDATION.md)。

SHEAF 的工具基于 POSIX shell、`fcntl` 锁、符号链接、tmux 和 Unix 进程组，
因此 Windows 支持走 **WSL2**，且仓库必须放在 **WSL 文件系统**内。
不支持原生 PowerShell；不要运行 `environments/macos/bootstrap.sh`。

## 前置条件

1. Windows 侧安装 WSL2 与 Ubuntu（PowerShell 管理员）：

   ```powershell
   wsl --install -d Ubuntu
   wsl -l -v    # 确认 VERSION 列为 2；若为 1，执行 wsl --set-version Ubuntu 2
   ```

2. 在 WSL 内把本仓库克隆到 Linux home（**不要**放 `/mnt/c` 等 Windows 盘：
   锁与符号链接在 drvFS 上不可靠）：

   ```bash
   git clone <本仓库地址> ~/SHEAF
   ```

3. 版本基线复用 [`../macos/versions.env`](../macos/versions.env)（全平台一份钉，
   脚本直接 source 它）：Lean / Mathlib `v4.35.0`，Lean 技能固定到具体 Git commit。

## 进入环境

在 SHEAF 仓库根目录运行：

```bash
./environments/windows/run.sh
```

这会打开一个已经配置好 PATH 的 Bash。也可以只执行一条命令：

```bash
./environments/windows/run.sh lean --version
./environments/windows/run.sh python3 environments/windows/doctor.py
./environments/windows/run.sh python3 environments/windows/smoke.py
```

入口保留当前工作目录，因此可以从具体项目目录通过绝对路径调用。
退出 Bash 用 `exit`。不需要修改 `~/.bashrc`、系统默认 shell 或全局 Git 配置。
`run.sh` 会拒绝在 `/mnt/` 下的检出；非 WSL 的 Linux 给出提示但不拦截。

VS Code：在 Windows 侧安装 VS Code 与 “WSL” 扩展，然后在 WSL 终端内
`code .` 打开仓库；Lean 4 扩展装在 WSL 侧即可。不移植 macOS 的
`editor-bin/` 包装器方案。

## 安装与版本

新 WSL2 Ubuntu 上（已装 sudo）：

```bash
./environments/windows/bootstrap.sh
./environments/windows/prepare-mathlib.sh
```

APT 依赖：`tmux bash coreutils findutils grep git curl wget rsync python3
python3-venv build-essential`。Python 使用仓库本地 venv（Ubuntu 24.04 自带
Python 3.12）；GNU 工具链与 Bash 5 为系统自带，无需额外等价物。

下载需要代理时，在命令前设置 `HTTPS_PROXY` 和 `HTTP_PROXY`，例如：

```bash
HTTPS_PROXY=http://127.0.0.1:7897 HTTP_PROXY=http://127.0.0.1:7897 \
  ./environments/windows/bootstrap.sh
```

端口只是本机配置示例；代理没有写入 Git 配置、脚本默认值或 shell 启动文件。
注意：代理要能被 WSL 访问（Windows 侧代理需允许局域网/WSL 访问，
或用 `$(hostname).local` 指向 Windows 主机）。

各论文项目依旧使用自己的 `lean-toolchain` 和 Lake manifest；
环境入口不会用 `ELAN_TOOLCHAIN` 强制覆盖项目版本。

## 本地文件与 Mathlib

所有下载、缓存和验证临时文件都在 Git 忽略的 `.local/windows/` 下：

| 目录 | 用途 |
| --- | --- |
| `venv/` | Python 3.12 虚拟环境 |
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
./environments/windows/prepare-mathlib.sh Mathlib
```

这份验证副本不是论文项目。开始正式项目时，按仓库 `AGENTS.md` 创建独立项目，
固定 Mathlib 依赖并在该项目的 `lean/` 目录运行 `lake exe cache get`。
SHEAF 全局构建器要求完整的 Mathlib 缓存，避免从共享构建副本重建依赖。

## 持久会话

从 SHEAF 根目录启动一个专用 tmux 服务器中的工作终端：

```bash
./environments/windows/run.sh tmux -L sheaf-windows new-session -s sheaf-windows \
  "$PWD/environments/windows/run.sh"
```

这样即使机器上已有别的 tmux 服务器，新会话也会明确加载本环境。
进入后再运行 `codex`/`claude` 或项目命令；离开但保持运行用 `Ctrl-b d`，
重新连接：

```bash
./environments/windows/run.sh tmux -L sheaf-windows attach -t sheaf-windows
```

本次配置不启动论文任务或后台 AI 会话。

## 验证范围与 comparator

`doctor.py` 检查可执行文件、Python/Bash 语法、GNU 工具的实际能力、WSL2 与
文件系统位置及 Lean 版本。`smoke.py` 在临时独立 Git 仓库中用 Lake 自带模板
创建测试工程，检查 Lean 编译、排他任务领取、队列、构建快照、构建产物发布、
worker 镜像、文件落库和 tmux 健康检查。它只关闭自己创建的独立 tmux socket，
结束后清理自己的临时项目。

以上验证不代表论文证明已经完成，也不验证模型账号额度。
最终目标验收仍应检查锁定目标的语义与允许的公理。

Lean 4.35.0 已内置 `lake comparator` 和 `lake check`。WSL2 是完整 Linux，
正式项目可 `sudo apt install bubblewrap` 后执行带默认沙箱的完整
`lake comparator` 验收（比原生 macOS 更完整）。本环境默认不装 bubblewrap；
项目自己的编译、目标类型检查和公理检查在本环境即可进行。

重跑本地检查：

```bash
./environments/windows/run.sh python3 environments/windows/doctor.py
./environments/windows/run.sh python3 environments/windows/smoke.py
./environments/windows/run.sh python3 environments/windows/test_snapshot.py
./environments/windows/prepare-mathlib.sh
```

参考：[WSL 安装文档](https://learn.microsoft.com/windows/wsl/install)、
[Lean 官方安装说明](https://lean-lang.org/install/manual/)、
[elan](https://github.com/leanprover/elan)、
[Lean 技能安装说明](https://github.com/cameronfreer/lean4-skills/blob/83582df9d9172456993929f32ac4dd9d99c6211c/INSTALLATION.md)。
