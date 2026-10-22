# macOS 验证记录

日期：2026-10-21。主机：macOS 26.6.2，Apple Silicon / arm64。
SHEAF 基础提交：`6e5abd8`，加本次 Mac 环境兼容修改。

| 项目 | 验证结果 |
| --- | --- |
| Python | 本地 venv，3.14.6；全部 SHEAF Python 脚本通过语法检查 |
| Bash | Homebrew 5.3.15；脚本使用 PATH 中的 Bash；`mapfile` 可用 |
| GNU 工具 | 复制、符号链接镜像、`realpath -m`、`find -xtype`、PCRE grep、纳秒时间均通过能力检查 |
| tmux | 3.7b；独立测试 socket 中创建会话并通过 SHEAF 健康检查，已清理 |
| Lean / Lake | Lean 4.35.0 arm64；Lake 5.0.0-src+eb6cafb |
| Lean 技能 | 固定 commit `83582df9d9172456993929f32ac4dd9d99c6211c`；安装到 `.agents/skills/lean4`；辅助扫描命令实际运行成功 |
| Mathlib | v4.35.0 / `56a005855ea17e0b0958f73ec801ae140b0a1679`；基础模块及 154 个缓存文件准备成功；`Mathlib.Data.Nat.Basic` 导入与 `Nat.add_comm` 检查通过 |
| SHEAF 集成测试 | Lake 模板编译、排他领取/释放、空 DAG/队列、共享构建及发布、worker 镜像编译、文件落库后重新构建均通过 |
| VS Code | `leanprover.lean4` 0.0.240 安装成功；Mac 工作区及 elan/lean/lake 包装器已配置，包装器版本检查通过；未进行 GUI 交互测试 |
| Comparator | `lake help comparator` 可用；默认沙箱要求 Linux/bwrap，未在原生 Mac 上通过完整验收；未关闭沙箱 |

重跑本地检查：

```bash
./environments/macos/run.sh python3 environments/macos/doctor.py
./environments/macos/run.sh python3 environments/macos/smoke.py
./environments/macos/prepare-mathlib.sh
```

`smoke.py` 的测试工程及 tmux 会话已自动清理。没有启动论文项目、后台 AI 会话，
也没有向远端提交或推送修改。未验证整篇论文工作流、完整 Mathlib 缓存、
模型登录/额度或 Windows。完整 Mathlib 缓存按具体论文项目版本另行准备。

## 后续实际 AI 单目标测试

用户随后要求最简单通路测试，已在 `demo-macos-minimal/` 完成一个真实 AI 证明：
任意自然数加零等于自身。最终共享构建提交为
`1e024b97e0a6f4835d5b03033e83279f4c199d28`，目标类型检查通过，
目标无任何公理依赖，解答无 sorry，任务队列和有效 claims 均清空。
报告位于该项目的 `local/result.md`，会话日志保留，AI 会话已退出。

实际测试发现 Git 快照写入被沙箱拒绝时原 build.py 仍会记录绿色结果。
已改为快照失败即停止，并通过 `test_snapshot.py` 的 4 项回归检查以及完整
隔离 smoke 流程。AI worker 保留沙箱，Git 构建由单独获准的 launcher 步骤完成。
此结果验证单会话、单目标通路；未覆盖多 Agent 并发和 Linux/bwrap comparator。

## 后续实际双 Agent 并发测试

2026-10-22，在 `demo-macos-concurrent/` 完成两个真实 Codex 会话的最小并发流程。
两组从同一队列分别领取自然数加零、乘一两个独立目标，在各自沙箱编译和审查，
然后同步调用真实 `tools/land.sh`。会话运行重叠 302.091 秒，落库调用重叠 0.755 秒。
落库前两份不同 claim 同时存在，两次重复领取探测均正确被拒绝。

最终统一构建为 GREEN，提交 `a3a70579c9257e561106a8e0f341c57dd307aa7f`，
一次验证两个 landing。锁定 Challenge 哈希不变，两个目标类型均匹配，
解答无 sorry，两个目标均无任何公理依赖。队列、claims 和待构建请求清空，
两个会话正常退出。本次未发现需要修改 SHEAF 工具的问题。

完整证据留在本地 demo 的 `local/result.md` 和 `local/acceptance.json`。
此结果限于 macOS 单机、双 worker、单轮；未覆盖压力测试、故障恢复、跨机器同步、
Windows、真实论文或 Linux/bwrap comparator。详细 demo 被主仓库忽略，未推送。
