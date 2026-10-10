# Architecture Decision Records (ADR)

GenzLTD 架构决策记录。格式参考 [Michael Nygard ADR](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)。

## 规则

- 文件名：`NNNN-短标题.md`（四位序号，单调递增）
- 状态：`Proposed` → `Accepted` → `Superseded`（被新 ADR 取代时 **不可改原文**，只链到新 ADR）
- 存放：`GenzLTD/docs/adrs/`
- Owner：组织 Admin（`szpeter2026`、`zervi-genz`、`szjason72`）Accept；Member 可提 Proposed

## 索引

| ADR                                                | 标题                                                                   | 状态     |
| -------------------------------------------------- | ---------------------------------------------------------------------- | -------- |
| [0001](0001-lab-wukong-canonical.md)               | lab-genz-brain-m2 与 wukong-core  canonical 关系                       | Accepted |
| [0002](0002-l0-pii-sg-deny-policy.md)              | L0_PII ↔ SG 四向 deny 业务口径                                         | Accepted |
| [0003](0003-cortex-policy-bundle-pin.md)           | cortex-mcp 策略包加载与 pin                                            | Accepted |
| [0004](0004-tatha-frontend-deployment-pipeline.md) | tatha-frontend 部署流水线（私有主仓 + Vercel REST API）                | Accepted |
| [0005](0005-remote-codespace-development.md)       | 远程开发模式（GitHub Codespaces + devcontainer）                       | Accepted |
| [0006](0006-docs-governance-codespace.md)          | docs 仓启用 Codespace（治理协同）                                      | Accepted |
| [0007](0007-tatha-frontend-deploy-governance.md)   | tatha-frontend 部署链治理（真源、Vercel 组织归属、成员边界、追溯义务） | Accepted |
| [0008](0008-docs-single-source-site.md)            | docs 仓文档单真源化（根 ↔ `docs/` 双份收敛到 `docs/`）                 | Accepted |
| [0009](0009-trust-layer-over-world-model.md)       | 近期目标收敛为「人与虚拟世界交互的信任层」（不承诺世界模型大脑）       | Accepted |
| [0010](0010-cn-wechat-pay-three-client-ops.md)     | 90 天技术欠债收敛为「国内 Looma 微信支付 + 三端可运营」                 | Proposed |
| [0011](0011-dsh-bridle-freeze-career-cosmos.md)    | 冻结 dsh-bridle 产品化争论，注意力回到 Career Cosmos 90 天             | Accepted |
| [0012](0012-thomas-identity-unification.md)        | THOMAS 生态身份统一（Supabase 唯一 IdP / 稳定主键注入 / 网关唯一验签点） | Accepted |
| [治理清单](free-plan-governance-notes.md)          | GenzLTD GitHub Free 计划：治理能力清单（免费 vs 付费增强）             | 参考     |

> **编号说明**：原 PR #1（`ai-draft/adr-0004`）与 main 已有的 ADR-0004 部署流水线冲突，本修复版将 PR 提交内容**重编号为 ADR 0007**（治理层），与 ADR 0004（实现层）形成 What/How 互补。

## 与 M 路线图

- **M2 门控真源**：以 ADR 0001 + lab 64 矩阵 fixture 为准
- **M3 记忆合规**：以 ADR 0003 + cortex `compliance.py` 为准
- **近期承诺范围**：以 ADR 0009（Accepted）为准——信任层，而非世界模型大脑
- **90 天变现 / 可运营（Proposed）**：ADR 0010 提议把 Career Cosmos 第 4 条读成国内微信支付 + 三端可运营；**Accept 前仍以聚焦决策原文为准**。Stripe 沙盒不是深创赛交付
- **dsh-bridle / 内部 RAG 插件**：以 ADR 0011（Accepted）为准——冻结产品化；本机工作记忆探针（门控 pin SHA + 落地点名）；裸 hybrid 不当证据；记忆写入仍走 cortex（ADR-0003），不复活 ADR-0009 的 Agent loop 承诺
- **身份认证统一**：以 ADR 0012（**Accepted**，2026-10-10 签署生效）为准——Supabase 为唯一 IdP；网关唯一验签点（JWKS/ES256 + HS256 双轨）；`X-User-Id` 用稳定主键 `sha256(supabase_uid)`；跨端关联键 `email_hash` 无真实邮箱时为 `None`（**不造假值**）；口径争议走该 ADR 的 Amendment，不在实现 PR 辩论
- **Evidence**：`lab-genz-brain-m2` 测试、`genz-gate` CI 日志；支付以 `looma-zervi` `origin/main` 为准，未入库工作区不作 ADR 证据

## Links

- tatha-frontend 部署流水线：[ADR-0004](0004-tatha-frontend-deployment-pipeline.md) → workflow 模板位于 `GenzLTD/tatha-frontend/.github/workflows/deploy.yml`
- tatha-frontend 部署链治理：[ADR-0007](0007-tatha-frontend-deploy-governance.md) → 真源单一化、Vercel 组织归属、成员发布边界
- 远程 Codespace：[ADR-0005](0005-remote-codespace-development.md) → devcontainer 模板位于 `GenzLTD/Tatha/.devcontainer/`
- docs 仓 Codespace：[ADR-0006](0006-docs-governance-codespace.md) → devcontainer 模板位于 `GenzLTD/docs/.devcontainer/`
