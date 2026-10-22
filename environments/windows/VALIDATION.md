# Windows (WSL2) 验证记录

日期：2026-10-22。主机：Windows 11 + WSL2，Ubuntu 24.04.1 LTS，x86_64，
内核 `5.15.167.4-microsoft-standard-WSL2`，文件系统 ext4（仓库位于 WSL 文件系统）。
SHEAF 基础提交：`4866abd`，加本次 Windows 环境文件。

| 项目 | 验证结果 |
| --- | --- |
| Python | 本地 venv，3.12.3；doctor 通过全部语法检查 |
| Bash | 5.2.21（系统自带）；`mapfile` 可用 |
| GNU 工具 | 复制、符号链接镜像、`realpath -m`、`find -xtype`、PCRE grep、纳秒时间均通过能力检查（系统 coreutils/findutils/grep） |
| tmux | 3.4；独立测试 socket 中创建会话并通过 SHEAF 健康检查，已清理 |
| Lean / Lake | Lean 4.35.0 x86_64（commit eb6cafb）；Lake 5.0.0-src+eb6cafb；elan 4.2.4 |
| Lean 技能 | 固定 commit `83582df9d9172456993929f32ac4dd9d99c6211c`；安装到 `.agents/skills/lean4`；辅助扫描命令实际运行成功 |
| Mathlib | v4.35.0 / `56a005855ea17e0b0958f73ec801ae140b0a1679`；依赖（plausible、batteries 等 8 个）按 manifest 检出；154 个缓存文件经 `cache.mathlib.org` 下载成功；`Mathlib.Data.Nat.Basic` 导入与 `Nat.add_comm` 检查通过 |
| SHEAF 集成测试 | Lake 模板编译、排他领取/释放（WIN1/WIN2）、空 DAG/队列、共享构建及发布、worker 镜像编译、文件落库后重新构建均通过 |
| 快照回归 | `test_snapshot.py` 4 项检查全部 OK |
| Comparator | 未验证完整沙箱验收；WSL2 可 `sudo apt install bubblewrap` 后执行，见 README |

重跑本地检查：

```bash
./environments/windows/run.sh python3 environments/windows/doctor.py
./environments/windows/run.sh python3 environments/windows/smoke.py
./environments/windows/run.sh python3 environments/windows/test_snapshot.py
./environments/windows/prepare-mathlib.sh
```

`smoke.py` 的测试工程及 tmux 会话已自动清理。没有启动论文项目、后台 AI 会话，
也没有向远端提交或推送修改。未验证整篇论文工作流、完整 Mathlib 缓存
（`prepare-mathlib.sh Mathlib`）、模型登录/额度或带沙箱的 `lake comparator`。

## 本机网络备注

本机经环境变量代理（`http(s)_proxy=http://127.0.0.1:7890`）访问网络，验证时观察到：

- `github.com`、`api.github.com`、`releases.lean-lang.org`、`cache.mathlib.org`、
  release 资源（objects.githubusercontent.com）均可达；
- `raw.githubusercontent.com` 间歇性被重置。`bootstrap.sh` 已含回退：
  elan-init.sh 拉取失败时自动改用 `api.github.com` 解析的 elan release 二进制
  （本次实际运行走了主路径成功，回退路径经单独验证可达）。

代理只经环境变量传入，未写入 Git 配置、脚本默认值或 shell 启动文件。
若在新终端使用，注意 `run.sh` 交互 Bash 使用 `--noprofile --norc`，
代理变量需已在环境中或通过命令前缀传入。

## 与 macOS 验证的差异

- elan 经 `elan-init.sh` 主路径 + GitHub release 二进制回退安装，而非 Homebrew；
- GNU 工具与 Bash 5 为系统自带，无 Homebrew gnubin 前置；
- VS Code 走 WSL 远程扩展，不提供 macOS 的 `editor-bin/` 包装器；
- `lake comparator` 完整沙箱验收可行（安装 bubblewrap 后），本次未执行。
