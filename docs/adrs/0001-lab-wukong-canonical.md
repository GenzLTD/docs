# ADR 0001: lab-genz-brain-m2 与 wukong-core 的 canonical 关系

- **Status**: Proposed
- **Date**: 2026-09-05
- **Deciders**: szpeter2026, zervi-genz（待 Accept）
- **Consulted**: szjason72, 8bt8rcrg95-coder, xiajason
- **Tags**: M2, gate, lab, wukong-core, policy

## Context

GenzLTD 在 M2 阶段出现两条并行实现：

| 仓库 | 角色 | 现状 |
|------|------|------|
| `lab-genz-brain-m2` | Rust↔Python 三方对拍验收 | 64 组合 fixture、17 测试、YamlPolicy/RustPolicy |
| `wukong-core` | M1 认知内核 PoC | gate/trace/verify 黑匣子双组件 |

问题：

1. `wukong-core/src/gate.py` 曾用手工转录 `RULES[]`，与 yaml 存在漂移风险（v1.1 已部分对齐）。
2. 成员不清楚「改规则改哪个仓」「哪个矩阵是权威」。
3. 是否应物理 merge 两仓尚无组织决议。

## Decision

采用 **「Assets 验收仓 + Runtime 消费仓」** 双仓模型，**不**在 M2 阶段做 git merge：

1. **Canonical 策略与验收资产**（改规则先改这里）  
   - 仓库：`GenzLTD/lab-genz-brain-m2`  
   - 真源文件：`config/policy_rules.yaml`  
   - 权威矩阵：`tests/fixtures/rust_cartesian_matrix.json`（64 = allow 51 / deny 6 / redact 7）  
   - 验收：`python -m unittest discover -s tests`（17 用例）

2. **Runtime 认知内核**（消费策略，不重复发明规则）  
   - 仓库：`GenzLTD/wukong-core`  
   - 职责：gate / trace / verify（决策⑧ 黑匣子）  
   - `rules/policy_rules.yaml` 与 lab **保持语义全等**（由 CI `genz-gate` 对拍，见 ADR-0003 配套 workflow）  
   - `gate.py` **必须**改为读 yaml（或生成自 yaml），禁止长期维护平行硬编码 RULES

3. **晋升（Promote）流程**  
   - lab 中 yaml/fixture/测试全绿 → PR merge  
   - 同步 PR 到 `wukong-core`（更新 `rules/` + 跑 `_verify/verify_matrix.py`）  
   - 不要求把 lab 的 `rust-parity/` 迁入 wukong（本机 YeDall 路径，仅维护者重跑 fixture）

4. **命名与 topic**（GitHub）  
   - `lab-genz-brain-m2`: topics `genzltd-assets`, `m2-gate-parity`  
   - `wukong-core`: topics `genzltd-production`, `m1-cognitive-kernel`

## Consequences

### Positive

- 验收与运行时职责清晰；64 矩阵有唯一权威。
- lab 仓可继续作为「只读验证资产」，新成员无需 Rust 即可跑 Python 测试。
- 避免大 merge 冲突；CI 绑定语义一致。

### Negative

- 策略变更需 **两个 PR**（lab + wukong），或自动化 promote bot（后续）。
- 若无人跑 promote，wukong 可能再次漂移 → **genz-gate CI 必须阻断**。

### Risks

- `rust-parity` 仍依赖本机 `zervi-looma` 路径；fixture 更新仅维护者执行（文档化于 lab README）。

## Compliance

- 路线图 M2 交付标准：「字段 → tier → verdict 全路径 + Rust 锚定」由 **lab + fixture** 证明；wukong 为消费方。
- 与 `docs/M2归属对账与决策清单.md` 结论一致：lab 已归位，本 ADR 将关系 **冻结为 Accepted 后可执行规范**。

## Links

- [lab-genz-brain-m2 README](https://github.com/GenzLTD/lab-genz-brain-m2)
- [wukong-core README](https://github.com/GenzLTD/wukong-core)
- [parity-verification.md](https://github.com/GenzLTD/lab-genz-brain-m2/blob/main/docs/parity-verification.md)
- Supersedes: （无）
- Superseded by: （无）
