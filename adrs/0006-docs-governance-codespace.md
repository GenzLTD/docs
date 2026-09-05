# ADR-0006: docs 仓启用 GitHub Codespace（治理协同）

| 字段 | 值 |
| --- | --- |
| Status | **Accepted** |
| Date | 2026-09-05 |
| Deciders | zervi-genz (owner) |
| Scope | `GenzLTD/docs` |
| Supersedes | — |

## Context

`GenzLTD/docs` 是组织级治理仓：所有 ADR、CODEOWNERS、PR 模板、执行计划都从此仓发出。在「补 ADR-0001~0005 → 配 CODEOWNERS → 写 ADR-0004/0005」这波密集落地中，**owner 在本地写一份 + 另一成员在他处也补一份**，会出现两份内容冲突、谁先 push、commit 提示符顺序混乱等摩擦。

后果：
1. **冲突频次上升**：多人同时编辑时 `git pull --rebase` 需要反复解决。
2. **真实可信源漂移**：本地副本可能成为事实，但 `GenzLTD/docs` 的远端才是治理唯一源。
3. **新人 onboarding 路径长**：clone + pip + mkdocs 配置散落各处。

## Decision

**为 `GenzLTD/docs` 启用 GitHub Codespace（轻量文档栈）+ 网页 UI 自助创建**。

具体配置：

1. **轻量文档栈**（区别于 Tatha 的全栈模板）：
   - 基础镜像 `python:3.11-bullseye` + Node 20
   - 工具：`git`、`gh`、`ripgrep`、`python3-pip`
   - VS Code 扩展：GitLens、markdownlint、Markdown All in One、Markdown Mermaid、Draw.io Integration、Code Spell Checker、TOML、YAML
   - 端口：`8000`（mkdocs 预览，自动开浏览器）
   - `postCreateCommand`：幂等安装 `mkdocs-material` + `mkdocs-mermaid2-plugin` + 写 `mkdocs.yml` 脚手架

2. **网页 UI 创建**（不依赖 PAT codespace scope）：
   - 用户进入 `github.com/codespaces/new?repo=GenzLTD/docs`
   - 选机器规格（2 vCPU / 4 GB RAM / 16 GB 磁盘）
   - 容器自动从 `devcontainer.json` 装配，启动 <60s
   - 成员通过 Codespace 内置 git 配置走 `gh auth login` 即可

3. **治理约束**：
   - `devcontainer.json` 是治理基础设施，**改它也需 PR review**（由 CODEOWNERS 落点）
   - `.devcontainer/post-create.sh` 幂等可重复执行
   - 容器只装**文档编辑必需**的工具；扩展/数据库/CLI 不入容器（避免镜像膨胀）

## Alternatives Considered

| 方案 | 否决原因 |
| --- | --- |
| **复用 Tatha 全栈 devcontainer** | 镜像重（80s 启动），含 docker-in-docker、vercel CLI，文档编辑用 80% 是浪费 |
| **API 创建（要求 PAT codespace scope）** | classic PAT 需勾 `codespace + delete:codespace` 两个 scope；扩 scope 是组织级决定，不应被「一个成员的便利」触发 |
| **Fine-grained PAT 仅 docs 仓 codespace** | 仍需新建 PAT + 设 expiration 提醒，对一个 devcontainer 仓偏重 |
| **纯本地多写手靠 git pull --rebase** | 仍是用户当前痛点，且 ADRs 一旦冲突，编号错乱很难恢复 |
| **Codespace + 同步本地** | 同一 workspace 跑两个 git remote 是反模式，弃 |

## Consequences

### Positive
- **原子化编辑**：每个人在容器里改完直接 commit & push 到 `GenzLTD/docs`，无本地副本
- **零 token 操作**：网页 UI 创建路径不依赖 zervi-genz 凭证扩 scope
- **可逆性强**：删 `.devcontainer/` 即可让 Codespace 入口消失
- **新人 onboarding 5 分钟**：点链接 → 选机器 → 写文档

### Negative / Risks
- **Codespace 实例是 zervi-genz 计费**：每月 free quota 120 core-hours / 15 GB，2 vCPU 4 GB 大约 60 小时/月，owner 需监控 usage
- **本地 vs Codespace 编辑不能并行**：成员若同时在本地和 Codespace 改同一文件，仍会冲突——只能二选一
- **mkdocs 预览仅容器内可见**：本地浏览器需连 `https://<codespace>-8000.app.github.dev/`

### Operational
- **Owner**：定期看 `github.com/settings/billing/codespaces` 用量
- **成员**：codespace 用完即停（默认 30 分钟 idle 自动停机）
- **治理变更**：devcontainer 改动也走 `/adrs/` 流程（PR + review）

## Update (2026-09-06): 实施回写（镜像 / 身份 / 多成员登入）

> 决策方向不变（docs 启用 Codespace + 网页 UI 自助创建）。以下事实层修正以本段为准：
> **Decision §1「基础镜像 `python:3.11-bullseye` + Node 20」未按原样落地**。

### 1. 镜像实际落地：自建 Dockerfile（`python:3.11-bookworm`）

原计划 bullseye 系 devcontainers image 自带 Yarn apt 源（`dl.yarnpkg.com`），其 GPG key（`NO_PUBKEY 62D54FD4003F6525`）自 2026-09 起无法验证 → 任何执行 `apt-get update` 的 feature（实测 sshd）构建失败 → **Codespaces 静默降级为裸 `devcontainers/base:alpine` 空容器**（无 gh / pip / GITHUB_TOKEN 注入 / git 认证）——本次 docs codespace 两次构建成 Alpine、git 无法认证，即此因。

落地：`.devcontainer/Dockerfile` `FROM python:3.11-bookworm` + 最小 apt 集（openssh-server/client、git、sudo、curl、ca-certificates）+ `vscode` 用户（UID/GID 1000）+ 免密 sudo；devcontainer.json 用 `build.dockerfile` 引用，feature 仅 `github-cli`（`containerUser: vscode` 要求镜像内置该用户，官方 python image 需自建）。

### 2. git 身份治理：移除无归属 stub

曾因 post-create.sh 兜底写入 `codespace@users.noreply.github.com`（非 GitHub 正规 `ID+username@users.noreply.github.com` 格式）→ commit 灰色、不归任何账号。修复（`60880cc`）：post-create.sh **不再写身份 stub**；容器 git identity 回落 Codespaces 平台注入的 system 层创建者身份（`/etc/gitconfig`），或由成员 `git config --global` 自设。commit 归属 = 各成员自己的 GitHub 账号（commit 归属取决于作者邮箱，与推送 token 属主无关）。

### 3. 多成员登入与验收（onboarding）

**成员前置**：org member（active）+ docs 仓库 Write 权限（owner 在 repo Settings → Collaborators 加人，或经 team 授权）。

**入口（任选）**：

1. **网页 UI（推荐）**：`github.com/codespaces/new?repo=GenzLTD/docs` → Create codespace on main → 等构建（Dockerfile 冷编译 1~3 分钟，warm cache <60s）→ 容器内直接改文档、commit & push。
2. **CLI**：`gh auth login`（本人账号）→ `gh codespace create -R GenzLTD/docs` → `gh codespace code -c <name>`。
3. **本地容器**：本机 Docker Desktop + VS Code「Reopen in Container」（devcontainer 配置在仓库内，无需 GitHub Codespaces）。

**验收三件套**：postCreate 无 error；`git var GIT_AUTHOR_IDENT` = 本人账号；commit push 后 GitHub 上头像正常（非灰）。

**计费提醒**：org 为 free plan、无组织统一 billing；成员创建 codespace 走各自个人免费额度（2 vCPU 档约 60h/月），owner 在 `github.com/settings/billing/codespaces` 监控。

## References

- [ADR-0005 remote-codespace-development](./0005-remote-codespace-development.md) — 决策框架
- [GitHub Docs: 创建 Codespace](https://docs.github.com/codespaces/developing-in-codespaces/creating-a-codespace-for-a-repository)
- [devcontainer.json schema](https://containers.dev/implementors/json_reference/)
- Tatha 仓的 devcontainer 配置（commit `70455cb`）作为参照——本 ADR 选择不复用其全栈模板

---

> **Action**: owner 立即在 `GenzLTD/docs` 加 `.devcontainer/` 并推送；成员去 `github.com/codespaces/new?repo=GenzLTD/docs` 自助创建。