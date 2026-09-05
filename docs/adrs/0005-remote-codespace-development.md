# ADR 0005: 远程开发模式（GitHub Codespaces）

- **Status**: Accepted
- **Date**: 2026-09-05
- **Deciders**: zervi-genz（owner）
- **Consulted**: szpeter2026
- **Tags**: dev-experience, codespace, devcontainer, governance, m2, m3

## Context

M2/M3 阶段需要多人远程协同开发 Tatha / tatha-frontend / cortex-mcp 等仓。问题：

1. **本地环境漂移**：成员之间 Python 版本（3.10/3.11/3.12）、PostgreSQL client、vercel CLI 版本各异，曾出现「本地过、CI 挂」的反复（典型例：ADR-0004 部署流水线首次失败就是 v25 CLI 版本过低）。
2. **入职摩擦**：新成员克隆仓后需 30~120 分钟配齐工具链，期间无法贡献。
3. **审计压力**：合规审查需要确认「所有开发环境的配置可追溯」，本地环境无法满足。
4. **零信任网络**：远程成员无法稳定访问公司 VPN/内网 PostgreSQL。

GitHub Codespaces 可解决上述四点，但引入三个问题：

| 风险 | 触发 |
|------|------|
| Free plan 配额（每月 120 core-hours）| 多人长时间挂机易爆 |
| 启动延迟（首次 60~120 秒）| 紧急调试体验下降 |
| Org owner 配置耦合 | codespace 计费默认挂在 user 账户上 |

## Decision

采用 **「私有主仓 + .devcontainer 标准化 + Codespace 用户级计费」** 方案：

### 1. 基础设施：`.devcontainer/`

每个核心仓**必须**包含 `.devcontainer/devcontainer.json` + `.devcontainer/post-create.sh`：

| 仓 | 状态 | 用途 |
|----|------|------|
| `GenzLTD/Tatha` | ✅ commit `70455cb` 已推 | FastAPI 后端 dev |
| `GenzLTD/tatha-frontend` | ⏳ TODO | 静态前端 dev |
| `GenzLTD/cortex-mcp` | ⏳ TODO | MCP 服务 dev |
| `GenzLTD/wukong-core` | ⏳ TODO | 决策内核 dev |
| `GenzLTD/lab-genz-brain-m2` | ⏳ TODO | 验收 fixture dev |

**devcontainer.json 必须包含**（参考 Tatha commit 70455cb）：

- 基础 image：`mcr.microsoft.com/devcontainers/python:3.11-bullseye`（后端类）或对应语言的官方 devcontainer image
- VS Code 扩展栈：python/pylance/black-formatter + YAML/TOML + GitHub Copilot
- 端口转发：业务端口 + 静态服务端口
- `hostRequirements`：声明 CPU/内存/storage 下限（Free plan 兼容：2 cpus / 4 GB / 32 GB）
- `postCreateCommand`：幂等启动脚本（venv + uv sync + vercel CLI + .env 模板）

### 2. Codespace 创建入口

| 路径 | 用途 | 谁来操作 |
|------|------|----------|
| **GitHub 网页 UI** | 成员自助创建 | 每个成员本人 |
| **API（`POST /user/codespaces`）** | 自动化/批量创建 | 仅 owner + PAT 含 `codespace` scope |
| **CLI（`gh codespace create`）** | 本地 CLI 用户 | 需 gh auth + codespace scope |

**默认推荐** 网页 UI：
```
https://github.com/codespaces/new?repo=GenzLTD/Tatha
```
（仓库切换即可：`?repo=GenzLTD/<repo-name>`）

### 3. 计费策略

| 维度 | 决策 |
|------|------|
| **账单人** | zervi-genz 个人账户（120 core-hours/月免费层） |
| **谁启用** | 仅 zervi-genz 可创建 codespace（PAT scope 控制） |
| **成员范围** | GenzLTD 内部成员；外部人员需先 PR 申请加入 org |
| **超时** | 30 分钟无操作自动停止；过期策略保留 Vercel 默认 |
| **告警** | 心度余额 < 20 hours 时 zervi-genz 收 GitHub 邮件 |

### 4. 与本地开发的关系

- **本地仍为主力**（开发体验更好、零网络延迟）
- **Codespace = 标准化 fallback**（远程成员 + 临时接手）
- **CI/CD 不动**（继续走 GitHub Actions + Vercel REST API，见 ADR-0004）

## Consequences

### ✅ 收益

| 维度 | before | after |
|------|--------|-------|
| 入职耗时 | 30~120 分钟 | 5~10 分钟（点链接即可） |
| 环境一致 | 完全靠成员自觉 | image + post-create 强制 |
| 远程准入 | 需 VPN + 内网配置 | 仅 GitHub 认证即可 |
| 审计 | 难追踪 | codespace 创建/删除有 Actions 日志 |

### ⚠️ 风险与缓解

| 风险 | 触发 | 缓解 |
|------|------|------|
| **Free plan 配额耗尽** | 多人长时间挂 codespace | 30 分钟空闲超时 + 周报监控用量；超限后临时禁用 codespace |
| **Codespace 实例被遗忘** | 成员离职 / 切换项目 | GitHub UI 列出全部 codespace（默认 30 天保留） |
| **Org 升 Pro 后策略变更** | GenzLTD 升 Pro 解锁 branch protection（见今天 ADR-0001~0003 待办） | 决策可逆；迁到 org-level billing 即可 |
| **devcontainer 漂移** | 各仓各自写一份 | 强制所有核心仓含 `.devcontainer/`，PR review check |

### 🛡️ 治理副作用

- **新成员 onboarding** 必须走 codespace 路径（统一环境）
- **本地开发** 不限制，但需要走 `make dev` 或同等的 env-sh 脚本，避免「我本地能跑」的借口
- **devcontainer.json 修改** 走 PR review（同代码），避免被单边覆盖
- **禁止**在 codespace 内硬编码 `.env` 值后 commit（`.gitignore` 已拒绝 `.env*`）

## Alternatives Considered

### A. 全部本地开发 + 文档化
- **否决**：远程成员无法稳定接入，环境漂移无法根治。

### B. Docker Compose + 自家 Web IDE（code-server）
- **否决**：维护成本高于直接用 GitHub Codespaces；与平台耦合弱。

### C. GitHub Codespaces on Org（org-level billing）
- **否决**：需 GenzLTD 升 Pro 解锁 org-level codespaces；当前 free plan 限制下 user-level 更轻。

### D. JetBrains Space / Gitpod 等替代
- **否决**：生态孤立、GitHub 集成较弱；保持工具栈单一原则。

## Implementation

| Commit | 仓 | 说明 |
|--------|----|------|
| `70455cb` | `GenzLTD/Tatha` | 引入 `.devcontainer/devcontainer.json` + `.devcontainer/post-create.sh` |
| TODO | `GenzLTD/tatha-frontend` | 复制模板，按需调整（无 Python 依赖） |
| TODO | `GenzLTD/cortex-mcp` | 复制模板，端口改为 8001（cortex 默认端口） |
| 紧随本 ADR | `GenzLTD/docs` | 在 onboarding 区补充「如何创建你的第一个 codespace」 |

## Validation

| 验证项 | 结果 |
|--------|------|
| devcontainer.json 字段完整性 | ✅ 通过 Tatha commit 验证 |
| post-create.sh 幂等 | ✅ 设计上 `if-not-exists` 全分支 |
| Codespace 创建 API 可用性 | ⚠️ **当前 zervi-genz PAT 缺 `codespace` scope**，需用户去 settings/tokens 加一次 |
| 与 ADR-0004 部署流水线一致 | ✅ Vercel CLI 已预装在 post-create |

## References

- GitHub Docs: <https://docs.github.com/en/codespaces>
- devcontainer spec: <https://containers.dev/implementors/json/>
- ADR-0004: 部署流水线（codespace 默认装好 Vercel CLI，与 deploy.yml 一致）
- [ADR-0001](0001-lab-wukong-canonical.md) lab/wukong 双仓模型（codespace 应用于「验收仓」开发）