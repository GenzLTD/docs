# ADR 0002: L0_PII 与 SG 四向跨境 verdict（deny vs redact）

- **Status**: Accepted
- **Date**: 2026-09-05
- **Deciders**: szpeter2026, zervi-genz（Accepted 2026-09-06，选择 A）
- **Consulted**: 法务/合规顾问（如有）、YeDall/zervi-looma 维护者
- **Tags**: M2, L0_PII, SG, PDPA, policy, compliance

## Context

`policy_rules.yaml` 从 v1.0 升至 v1.1 时，为与 `zervi-looma` Rust 引擎及 lab 64 组合矩阵一致，将 **L0_PII 与 SG 相关的四向传输** 从 `redact_or_aggregate` 调整为 **`deny_plaintext`**：

- CN ↔ SG（L0_PII）
- EU ↔ SG（L0_PII）

同时补充 L0_PII 自 OTHER 出境分支等（详见 wukong-core commit `2eace32` 说明）。

**业务疑问**（代码注释与 org 讨论）：SG 场景是否应 redact 而非 deny，取决于 PDPA 与产品口径，**Rust 实现与矩阵已按 deny 固化**。

若业务最终要求 redact，将改变 64 矩阵中 4+ 个组合，影响 M2 验收计数（当前 **deny 6 / redact 7**）。

## Decision

经 org owner 于 2026-09-06 书面确认，采用以下最终口径：

1. **工程 canonical**（CI、fixture、cortex 拦截）以 **v1.1 + 64 矩阵** 为准：L0_PII↔SG 四向 = **`deny_plaintext`**。
2. **业务复核结果：选择 A. Accept deny** — 确认继续使用 `deny_plaintext`，无需改矩阵；如未来改为 `redact`，必须新开 ADR 并同步更新 yaml、Rust、fixture 和三仓 CI。
3. **cortex-mcp** `remember` 对 `deny_plaintext` **硬拒绝**；对 `redact_or_aggregate` 要求 `metadata.redacted=true`（已实现，与本 ADR 一致）。
4. **文档**：对外（Tatha/用户）展示 deny 原因时，使用规则中的 `reason` 字符串，不暴露内部 tier 枚举。

## Consequences

### Positive

- 工程侧停止「SG 口径未决」导致的实现犹豫；CI 可全绿推进。
- 合规拦截与 lab 矩阵单一真源。

### Negative

- 若业务选 B，需一次有计划的全链路变更（非 hotfix）。

### Risks

- deny 口径在部分场景可能较严格；后续如业务或法务要求放宽，必须通过新 ADR 变更，不得直接修改运行时规则。

## Verification

- lab：`tests/test_policy_parity.py` 中 SG 相关用例（如 `test_e2e_phone_sg`）
- fixture：`tests/fixtures/rust_cartesian_matrix.json`
- wukong：`_verify/verify_matrix.py` 0 diff
- cortex：`tests/test_compliance.py` 矩阵语义用例

## Links

- [policy_rules.yaml v1.1](https://github.com/GenzLTD/wukong-core/blob/main/rules/policy_rules.yaml)
- Related: [ADR 0001](0001-lab-wukong-canonical.md)
- Supersedes: （无）
- Superseded by: （无）
