# ADR 0004: tatha-frontend 部署流水线（私有主仓 + Vercel REST API）

- **Status**: Accepted
- **Date**: 2026-09-05
- **Deciders**: zervi-genz（owner）
- **Consulted**: szpeter2026, szjason72
- **Tags**: deployment, ci, vercel, github-actions, governance

## Context

`GenzLTD/tatha-frontend` 是 M2 阶段对外展示层，但**组织全私有 + 0 公网暴露**的设计碰到一个尖锐矛盾：

> Vercel 的 GitHub auto-deploy 依赖 Vercel GitHub App 安装到目标组织。Free plan + 私有 org 下，把 App 装到 GenzLTD 需要 Owner 在 Vercel 网页一次性操作（**Owner 长期不在场**），且即便装上，App 一旦被 `app-level` 范围限制，所有成员访问不到。

历史曾沿「成员自己 fork → 转公开 → Vercel 绑个人公开仓」流程，导致：

| 后果 | 影响 |
|------|------|
| 真相源分裂 | 同一站点至少两个可部署的 GitHub 仓，PR 与部署口径不一致 |
| 治理失效 | 公开仓可被任何 contributor 直推，绕过 Reviewer |
| 历史署名丢失 | 个人仓提交者署名 ≠ Org 治理下的署名 |
| Vercel 配额浪费 | 每人每仓一份部署，billing 分散且难审计 |

**核心问题**：如何在不依赖 GitHub App 安装到 Org 的前提下，让 `push → production` 全自动，且把真相源压在组织私有主仓？

## Decision

采用 **GitHub Actions + amondnet/vercel-action@v42.3.0 + Vercel REST API + 3 个 Org-scoped secret** 方案：

### 1. 部署流水线拓扑

```
dev push branch          → PR → Reviewer approve → squash merge → main
                                                            │
                                                            ▼
                                          GitHub Actions workflow_dispatch
                                          + push trigger on main
                                                            │
                                                            ▼
                       checkout → vercel pull (alias+prod env) → vercel deploy --prod --token
                                                            │
                                                            ▼
                                    Vercel REST API（不走 GitHub App）
                                                            │
                                                            ▼
                              production alias 自动指向最新 deployment
```

**关键洞察**：Vercel CLI / REST API **对私有仓无限制**（已用 commit `a019b6a` 验证）。
只有 GitHub App webhook 在私有 Org 下装不上，所以**绕开 App，走 REST token 是正解**。

### 2. Workflow（落地在 `GenzLTD/tatha-frontend/.github/workflows/deploy.yml`）

| 触发条件 | 行为 |
|----------|------|
| `push` to `main` | 自动 production 部署 |
| `workflow_dispatch` | 手动重放（rollback / 验证） |
| 任何路径非 vercel.json 改动 | 跳过（concurrency group 保证旧 build cancel） |

```yaml
name: Deploy to Vercel Production
on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: production
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v42.3.0
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod --yes'
          working-directory: ./
          comment-on-pr: false      # 静态站无 Preview URL
```

### 3. Secrets 配置矩阵

| Secret | 值 | Scope | 谁配的 |
|--------|----|----|--------|
| `VERCEL_TOKEN` | zervi-genz PAT（Vercel 全局） | Repo-level | owner 本人 |
| `VERCEL_ORG_ID` | `team_7ynBv0lhD0yzPjvZmLGiQTC6` | Repo-level | owner |
| `VERCEL_PROJECT_ID` | `prj_XovdL4lzAGz2WessFuP5YTbuxuBJ` | Repo-level | owner |

**Org-level secret 不开**——只 repo 级够用，且 blast radius 最小。

### 4. 关键约束

- **CLI 版本要求 ≥ 47.2.2**：v25 等老版本会拒绝部署。固定使用 `v42.3.0`。
- **tokyo region & Linux runner**：GitHub Actions `ubuntu-latest` 满足 Vercel 部署需求。
- **concurrency cancel**：防止 push 风暴导致部署队列堆积。

## Consequences

### ✅ 收益

| 维度 | before | after |
|------|--------|-------|
| 部署入口 | 个人 Vercel 账户、分散 | 组织中心化、单一 token |
| PR Review 流程 | 公开仓可绕过 | 私有主仓强制 CODEOWNERS review |
| 提交署名 | 个人仓 ≠ Org 治理 | 全在 `GenzLTD/tatha-frontend` |
| 部署间隔 | 手动 `vercel deploy` | push → 1~2 分钟 auto |
| 真相源 | 多仓（个人公开仓 + org 私有仓）| 单一私有主仓 |
| Rollback | 需 Vercel 网页 | workflow_dispatch 选历史 commit 即可 |
| 失败可见性 | Actions email | Actions UI + Status badge |

### ⚠️ 风险与缓解

| 风险 | 触发条件 | 缓解 |
|------|----------|------|
| `VERCEL_TOKEN` 泄露 | 任何成员 clone 仓可读到 Actions log | 用 GitHub Actions 环境变量隔离 + 不打印 token；定期 rotate |
| Actions runner 故障 | GitHub 自身 outage | 手动 workflow_dispatch + Vercel 手动 fallback |
| CLI 强制升级 | Vercel 弃用 47.x | bump `amondnet/vercel-action` 版本（半年一检） |
| Organization 升 Pro 后策略失效 | Free plan 限制去掉后，可能想换 App 直绑 | 决策可逆；App 直绑会简化 secret 管理，但 governance 不变 |
| 旧 `szjason72/tatha-frontend` 公开仓残留 | 个人未清理 | **不影响治理**，但 README 加一行防误引导 |

### 🛡️ 治理副作用

- 公开仓退役=**成员不再走 "fork 公开仓 → 部署" 路径**。新人 onboarding 文档（`GenzLTD/docs` 待补）需更新。
- 若未来新增其他前端仓（如 `tatha-admin`、`tatha-mobile`），必须**复用同一 workflow 模板**，不允许每仓各写一份。
- 决策一旦落地，**禁止回到「个人仓公开部署」路径**——这是组织治理的硬底线。

## Alternatives Considered

### A. 把 Vercel GitHub App 装到 GenzLTD Org
- **否决**：需 Vercel 网页操作且只由 owner 在场时能完成；App 安装本身要求 owner 范围，operator 不能代操作；装了之后所有 org 仓默认有 webhook 触发面，需要额外 scope 限制。

### B. 维持「个人 fork → 转公开 → 个人 Vercel 部署」
- **否决**：违反 ADR-0001 「canonical 主仓」原则；治理盲区；历史曾因公开仓绕过 PR review 出现过 [事件示例]。

### C. 切 Cloudflare Pages / Netlify
- **否决**：迁移成本（DNS / CDN 缓存 / analytics 重置）；且生态优势 Vercel > Cloudflare Pages 对 Next.js/Vite 友好；本研究主力仓已是 vercel 部署。

### D. Self-host（自家 VPS + nginx + Let's Encrypt）
- **否决**：运维成本高、static site 本不需要、CI 流水线需要自己实现 roll-out 策略；ADR 体系应当最小化基础设施面积。

## Implementation

| Commit | 仓 | 说明 |
|--------|----|------|
| `41dee48` | `GenzLTD/tatha-frontend` | 首次引入 `.github/workflows/deploy.yml` |
| `bdbc8c0` | `GenzLTD/tatha-frontend` | amondnet/vercel-action `v25` → `v42.3.0` |
| `dpl_8Bsg5ZfWxJvyAobnxvY6S2jkmhbt` | Vercel | 手动 baseline deployment（commit a019b6a） |
| `dpl_G5rhcH776RtDT13CCEzc31pJaVGZ` | Vercel | Actions auto-deploy（commit bdbc8c0，pipeline 验证用） |
| 紧随本 ADR | `GenzLTD/tatha-frontend/README.md` | 加部署状态徽章 + 部署说明段 |
| 紧随本 ADR | `GenzLTD/docs/onboarding.md`（未来） | 把此流程写入新人 onboarding |

## Validation

| 验证项 | 结果 |
|--------|------|
| Actions run #33950739115 状态 | ✅ success |
| Production alias 是否切换 | ✅ `tatha-frontend-szpeter2006.vercel.app` 指向 bdbc8c0 |
| CLI 版本 | ✅ v42.3.0 安装的 vercel CLI ≥ 47.2.2 |
| `concurrency cancel` | ✅ 手动连发两次 push 只最新一次生效 |
| 失败 alarm | ⏳ 未配 webhook 通知（TODO） |

## References

- amondnet/vercel-action：<https://github.com/amondnet/vercel-action/releases/tag/v42.3.0>
- Vercel REST API deploy endpoint：`POST /v13/deployments`
- [ADR-0003](0003-cortex-policy-bundle-pin.md) cortex CI 配置先例（同套 Actions secret 模式）
- [ADR-0001](0001-lab-wukong-canonical.md) lab/wukong 双仓 canonical 原则的部署平移
