# ADR 0004: tatha-frontend 线上部署链——真源、Vercel 组织归属与义务边界

- **Status**: Proposed
- **Date**: 2026-09-05
- **Deciders**: szpeter2026, zervi-genz（待 Accept）
- **Consulted**: xiajason, szjason72, zervi-genz 维护者
- **Tags**: tatha-frontend, vercel, deployment, canonical, 组织治理

## Context

`tatha-frontend`（Tatha 求职匹配平台前端）当前存在**多账户平行副本**与**非 Git 集成的 Vercel 部署**，导致「线上跑的是什么、谁负责发布、哪个仓库才是真源」三个问题不可审计。事实如下：

### 现状证据（2026-09-05 核实）

1. **多个平行副本、均非 fork**（`fork:false, parent:null`）：
   - `xiajason/tatha-frontend` — **公开**，创建 2026-05-30，仅 1 提交（`df343955`，"Initial: Tatha frontend for Vercel deployment"）
   - `szjason72/tatha-frontend` — 私有，Vercel 本地部署工作仓，曾并入组织历史
   - `GenzLTD/tatha-frontend` — 私有，组织权威版（canonical 候选），含 `compliance.html` 等最新功能

2. **部署目标**：Vercel 项目对应域名 `api.genz.ltd`（后端）与前端静态站点；三个副本的 `vercel.json` **逐字节相同**。

3. **部署方式 = Vercel CLI 手动**（非 Git 集成）：
   - 提交 `c89322fb` "verify vercel deployment trigger"、`147aa512` "add gitignore for local Vercel project config"（注明 `.vercel` 为 **CLI deploys** 产生）
   - 组织仓内无 `.github/workflows` → 无 CI 触发部署
   - 提交 `a019b6a7` 把 `szjason72/tatha-frontend` 的 **Vercel deployment history** merge 进组织仓

4. **根因**：Vercel CLI 部署只校验「执行命令的账号对该 project 的权限」，**不校验 / 不区分 GitHub 仓库所有者**。因此 `xiajason`（或其他任何账号）的 GitHub 公开仓 owner 不一致**不影响发布**——发的是什么 = 本地产物，而不是 GitHub 上的某个 commit。

### 实操补充（2026-09-05 下午，szjason72）

成员侧已将本地开发入口切到 **canonical** `GenzLTD/tatha-frontend@a019b6a`，并按本 ADR「Allowed：staging / preview」拉起**个人预览站**（非生产 Authority）：

| 项 | 结果 |
|----|------|
| 本地路径 | `D:\surface-zervi\GitHub\szjason72\tatha-frontend`，`origin` → `GenzLTD/tatha-frontend` |
| 成员预览 URL | https://tatha-frontend-org.vercel.app （Vercel 账户 `szjason72-9160` / 项目 `tatha-frontend-org`） |
| 内容 | 含 `compliance.html` / `config.js` 等完整版；**不是** `C:\tmp` 早期 4 文件壳 |
| 临时副本 | `C:\tmp\tatha-frontend` 仍指向个人仓，应忽略或删除 |

**踩坑（建议写进成员 runbook）：**

1. 个人旧项目 `tatha-frontend` 在 CLI 部署带上 `GenzLTD` 私有仓 Git 元数据后，多次进入 **`readyState=BLOCKED`**（构建事件为空）；换**新 preview 项目** + `vercel deploy --prod --yes --archive=tgz` 后才 `READY`。
2. Hobby 新建项目默认 **SSO Deployment Protection**（`all_except_custom_domains`）→ 未登录同事只能看到 Vercel 登录页；分享前需 `vercel project protection disable <project> --sso`。
3. **切 Cursor workspace ≠ 完成生产部署链**：开发真源已对齐 org；生产 Git 集成 / 域名 Authority / 归档个人仓仍在下方 checklist，须 Admin。
4. 仓内交接文：`GenzLTD/tatha-frontend` → `docs/vercel-deploy-notes.md`、`docs/compliance-handover.md`（预览 URL 与 `SERVER_REGION` 阻断项）。

### 待决问题

1. 哪个仓库是「线上真源」（唯一 canonical）？
2. 个人账号能否用 Vercel 发布生产？可做什么、不可做什么？
3. 如何让「Vercel 账号 ↔ GitHub 仓库 owner ↔ 域名」对齐，重建组织权威？

## Decision

### 1. 真源单一化（Reject 多副本）

- **唯一 canonical = `GenzLTD/tatha-frontend`**（组织仓，私有），承担「线上生产真源」唯一身份。
- `xiajason/tatha-frontend`（公开）与 `szjason72/tatha-frontend`：**归档为只读镜像或删除**，不得承接线上声明。禁止再向组织仓 `merge` 第三副本的 deployment history。
- 与 ADR 0001（lab ↔ wukong canonical）精神一致：任何 promote 需经组织机审 + 组织 Admin 合入。

### 2. Vercel 组织归属与账号对齐

- Vercel 上 `api.genz.ltd` / 前端 project 的 Authority（Owner）必须是 **GenzLTD 组织 Admin**，不得挂在个人账号下。
- 部署绑定改为 **Git 集成**：Vercel 后台 Import Git Repository = `GenzLTD/tatha-frontend`，监听 `main`（生产）/ `prod` 分支自动构建。**"Vercel 账号 ↔ 仓库 owner"严格对齐 = GenzLTD**。
- Vercel project 的部署凭据（含 CLI/`gh` 侧关联）登记在 `docs` 映射表中，由组织 Admin 持有。

### 3. 个人账号（member）发布 Vercel 的边界

**可以（Allowed）**
- 本地开发 / 沙盒：用 Vercel CLI `vercel dev` 或部署到 **staging / preview project**（非生产域名）验证页面效果。
- 在 canonical 仓内经 **PR → review → 组织 Admin merge**，由 Git 集成自动触发生产发布。
- 维护本地个人副本作为开发草稿（仅本地、不作为线上声明源）。

**不可以（Not Allowed）**
- 用个人账号对**生产域名**执行 `vercel --prod` 直接发布。
- 以个人账号的平行副本（`xiajason` / `szjason72` 等）声称「这是线上真源」或承载生产可追溯责任。
- 用个人 Vercel 账号绑定 / 删除 / 重映射**生产 project 或 `api.genz.ltd` 域名**（仅组织 Admin）。
- 在非 canonical 仓库产生 `.vercel` 部署历史并 merge 回组织仓。

### 4. 线上可追溯义务（是否能发不重要，能否对账才重要）

- 每次生产发布必须可回溯到 **canonical 仓的一个 git commit SHA**；Vercel 部署记录的构建 `SHA` 与 GitHub commit 一致。
- `docs` 内固化「域名 ↔ project ↔ 仓库 ↔ 义务人」映射（见 checklist），并记录一次基线对账：当前线上 `api.genz.ltd` 对应哪个 SHA。

## Consequences

### Positive

- 真源唯一，个人账号无序发布被刹停，组织权威重建。
- 「GitHub commit ↔ 线上行为」可审计、可回滚、可 review。
- 消除「owner 不一致却可发布」的隐忧：发布不再绕过 GitHub 仓库归属。

### Negative

- 迁移成本：Vercel 后台需重做 Git 集成 + 权限收敛，短期间断发布窗口需排期。
- 个人成员生产直接发布权被回收，走 PR/CI 增加流程感（符合组织化预期）。
- 需清理并发行的公开/私有个人副本，避免他人 clone 到旧代码。

## Implementation checklist

- [ ] Accept ADR-0004
- [ ] Vercel：将**生产** `tatha-frontend` project 改为 Git 集成绑定 `GenzLTD/tatha-frontend`，监听 main/prod（勿把个人 preview `tatha-frontend-org` 误当生产）
- [ ] 收敛客户端：回收成员对生产 project 的 CLI 部署权，仅保留 dev/preview
- [x] 成员预览先例：`szjason72-9160/tatha-frontend-org` → https://tatha-frontend-org.vercel.app（对齐 `a019b6a`；符合 §3 Allowed）
- [ ] 归档/删除 `xiajason/tatha-frontend`、`szjason72/tatha-frontend`（改只读镜像或交接至 org）；本地勿再依赖 `C:\tmp\tatha-frontend`
- [ ] `docs` 登记「域名 ↔ Vercel project ↔ canonical 仓库 ↔ 义务人」映射表（预览站可另列一行，标明非生产）
- [ ] 做一次基线对账：记录线上生产前端域名 + `api.genz.ltd` 后端对应的 git SHA
- [ ] 补 CI/Release：canonical 仓加 `genz-gate` 类部署 workflow（复用 ADR 0003 思路）
- [ ] `config.js` 的 `SERVER_REGION` 由掌握后端部署区域者定案后经 PR 合入（当前预览站仍为评估模式）

## Links

- [GenzLTD/tatha-frontend](https://github.com/GenzLTD/tatha-frontend)
- [成员预览站 tatha-frontend-org](https://tatha-frontend-org.vercel.app)
- 仓内 runbook：`docs/vercel-deploy-notes.md`（随 canonical 仓发布）
- [GenzLTD/Tatha（后端）](https://github.com/GenzLTD/Tatha)
- [docs/CATALOG.md](../CATALOG.md)（组织仓库清单）
- [ADR 0001](0001-lab-wukong-canonical.md)
- [ADR 0003](0003-cortex-policy-bundle-pin.md)
- Supersedes: （无）
- Superseded by: （无）
