# Architecture Decision Records (ADR)

GenzLTD 架构决策记录。格式参考 [Michael Nygard ADR](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)。

## 规则

- 文件名：`NNNN-短标题.md`（四位序号，单调递增）
- 状态：`Proposed` → `Accepted` → `Superseded`（被新 ADR 取代时 **不可改原文**，只链到新 ADR）
- 存放：`GenzLTD/docs/adrs/`
- Owner：组织 Admin（`szpeter2026`、`zervi-genz`）Accept；Member 可提 Proposed

## 索引

| ADR | 标题 | 状态 |
|-----|------|------|
| [0001](0001-lab-wukong-canonical.md) | lab-genz-brain-m2 与 wukong-core  canonical 关系 | Proposed |
| [0002](0002-l0-pii-sg-deny-policy.md) | L0_PII ↔ SG 四向 deny 业务口径 | Proposed |
| [0003](0003-cortex-policy-bundle-pin.md) | cortex-mcp 策略包加载与 pin | Proposed |
| [0004](0004-tatha-frontend-deployment-pipeline.md) | tatha-frontend 部署流水线（私有主仓 + Vercel REST API） | Accepted |

## 与 M 路线图

- **M2 门控真源**：以 ADR 0001 + lab 64 矩阵 fixture 为准
- **M3 记忆合规**：以 ADR 0003 + cortex `compliance.py` 为准
- **Evidence**：`lab-genz-brain-m2` 测试、`genz-gate` CI 日志、本地验证报告

## Links

- tatha-frontend 部署流水线：[ADR-0004](0004-tatha-frontend-deployment-pipeline.md) → workflow 模板位于 `GenzLTD/tatha-frontend/.github/workflows/deploy.yml`
