# GenzLTD GitHub Free 计划：治理能力清单（免费 vs 付费增强）

- **对象**: GitHub Organization `GenzLTD`
- **当前实测（2026-09-05）**: plan = `free` · 私人仓 32 · 公开 0 · 成员席位 7/占用 4 [API 实测]
- **目的**: 让 owner / 成员快速对齐——哪些治理现在就能免费做，哪些要花钱（Team 计划）才做得到。

---

## 一、当前 Free 计划 · 免费可做

| 治理动作 | 免费 | 说明 / 在本工作流中的作用 |
|---|---|---|
| 私有仓库（组织内） | ✅ | 32 个私有仓已满额承载 |
| **给单仓库提权**（如 `docs` 给某成员/ci 账号 Write） | ✅ | 上一步"给 `8bt8rcrg95-coder` docs Write"**不花钱** |
| **基础分支保护**（main 开保护） | ✅ free 组织也支持 | Web 可配：`Require PR`、`Require 1 review`、`Protect admin` |
| 普通 PR 流程 / review / 评论 / 对话 | ✅ | 默认功能 |
| Actions 公共仓分钟数 | ✅（公共） | 公开仓库 CI 有免费额度 |
| **私有仓 Actions / 分钟** | ⚠️ 有免费额度但**超量按量计** | 仅在大量私有 CI 时才可能触及（当前无 .github 依赖） |
| 团队（Team）基础集合 | ✅ | 可建团队做基础可见性分组 |
| Issues / Projects（基础看板） | ✅ | 基础项目看板可用 |

---

## 二、需付费（GitHub Team 计划）才能做的增强

> 升级后的关键增量（计费 ~$4/用户/月，按**活跃成员数**）。

| 治理增强 | Team 计划 | 为什么需要它（如适用） |
|---|---|---|
| **受保护分支的"限制推送者"**（仅特定 TEAM 能 push main） | ✅ | 若想严格"只有 Admin/维护团队能碰 main" |
| **required status checks**（强制 CI 全绿才可 merge） | ✅ | 在 main 上强制"真源仓 CI 通过"的硬门禁 |
| **CODEOWNERS 强制审批**（代码/文档归属人必须 approve） | ✅ | 让 ADR 决策必须由 Deciders 亲批 |
| **多审查人 required approvers >1** | ✅ | 双人 review 才合入 |
| **SAML SSO / 单点登录** | ✅ | 组织强制登录、统一身份 |
| **审计日志（audit log）导出** | ✅ | 完整记录谁改了什么（治理还原能力） |
| **细粒度 repository 权限（每仓每团队 matrix）** | ✅ | 复杂多团队时更精细 |
| 高级依赖/安全策略面板 | ✅ | 更强的供应链与安全治理 |

---

## 三、放回我们的实际诉求（ADR 0007 落地路径）

我们真正需要的治理量级，**当前 Free 覆盖得住**：

| 我们要做的事 | 免费可做？ |
|---|---|
| 提权：给 ci 账号 docs 的 Write | ✅ |
| 合入 ADR 0007（仓库级 PR / 直推） | ✅ |
| main 的**基本保护**：Require PR + 1 review + 保护 admin | ✅ |
| **现在**就做 CODEOWNERS 强制、多审批、SAML | ❌ 需 Team（可选，暂非必须） |

### 建议
- **短期（Free，零成本）**：完成提权 + docs/main 基础分支保护 + 合入 ADR 0007。
- **将来若需要**（成员变多、真源仓要"硬门禁"）：再评估升级 **GitHub Team**，届时优先落地 `required status checks` + `CODEOWNERS` + `限制 main 推送者`。

---

## References
- [GenzLTD/docs 仓库](https://github.com/GenzLTD/docs)
- [ADR 0007 草案](0007-tatha-frontend-deploy-governance.md)（同目录；注：原 PR #1 用 ADR 0004 编号，与 main 已有的 [ADR 0004 部署流水线](0004-tatha-frontend-deployment-pipeline.md) 冲突，已重编号为 0007 治理层）
- 计划信息：`gh api orgs/GenzLTD` → `plan`