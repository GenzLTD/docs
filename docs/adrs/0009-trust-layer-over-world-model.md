# ADR 0009: 近期目标收敛为「人与虚拟世界交互的信任层」

- **Status**: Accepted
- **Date**: 2026-09-07
- **Deciders**: `szpeter2026`（Accepted 2026-09-07）
- **Consulted**: szjason72（起草）、xiajason、本机 M2/ADR-0003 验证
- **Tags**: strategy, trust-layer, M2, capacity, human-in-the-loop

## Context

《新一代智能大脑架构设计》v0.2 与《落地路线图》v0.1（2026-09-03）把目标写成：以 Wukong Layer0/1/2 为世界模型，以 cortex-mcp 为分层记忆，以五槽 Runtime + LLM Agent 为编排，做成「有认知、有记忆、能自主规划」的智能体。路线图 M0–M6 把这件事当成交付合同。

2026-09-07 对照代码与个人仓 CI 后，事实是：

1. **已锁住的**：跨境策略 64 组合（51 allow / 6 deny / 7 redact）、lab 三方对拍、wukong `gate.py` 读 yaml、cortex `remember` 前按声明拦截。这是 ADR-0001 / 0002 / 0003 的门控切片。
2. **未开始的**：Layer0/1/2 作为可读写世界模型、记忆三层物理分布、Agent loop、能力 MCP 化、边缘小脑、黑匣子事后纠偏。Tatha 仍是 5 意图 + 关键词分发——正是架构 §2 诊断的旧病。
3. **人手**：组织约 6 人，主仓与归档仓并存（见 `CATALOG.md`）。以现编制兑现 M3–M6，是把研讨稿当成排期。
4. **模型幻觉**：无论多新的通用模型（含近期 Astra 一类发布），**没有人类在场的判定与追责，输出只是或然文本，不能当信任来源。**

待决问题：近期到底承诺「构建世界模型大脑」，还是承诺「人与虚拟世界交互时，有一层可审计、可拒绝、由人负责的信任」？

## Decision

1. **近期不承诺世界模型大脑。**  
   架构 v0.2 降为**远景研讨稿**，不是交付合同。M3–M6（记忆三层化、编排+五槽+MCP、边缘小脑、端到端闭环）以及「M2 认知内核本体」中「工具读写 Layer0/1/2 canonical」部分，**不作为当前编制的承诺项**。

2. **近期只承诺信任层。**  
   信任层是人与虚拟世界交互的接口，不是模型替人思考。最小集：
   - **人定口径**：跨境 / 隐私 / 放行规则由人改、由人审（CODEOWNERS + ADR），模型不得静默改规则。
   - **机执行阀门**：同一输入给出同一 verdict；64 矩阵与 `genz-gate` 是执行证据，不是「大脑已认知」。
   - **可拒绝 / 可追溯**：`deny_plaintext` 必须对调用方可见；生产 pin `policy_bundle_commit`；人类可否决、可回放。
   - **人类在场**：无人类参与的模型调用，不写入「已信任」状态。Astra 或任何后继模型都适用同一条。

3. **已落地工作重新归位，不贬值。**  
   ADR-0001/0002/0003、lab 64 矩阵、wukong 门控、cortex compliance **就是信任层第一块砖**。停止用「智慧大脑进度」衡量它们；改用「规则是否单源、是否可对拍、是否有人签字」。

4. **产品面保持诚实。**  
   Tatha 5 意图分发可以继续当产品入口，不升格为「自主 Agent」近期目标。cortex-mcp 先当带合规挂钩的记忆服务，不当「知识皮层已完成」。

5. **组织 CI 必须成为真阀门。**  
   个人仓快照 CI 只能证明语义；GenzLTD 三仓 `genz-gate` 仍缺 `GENZ_GATE_PAT`。信任层若不能挡组织 `main`，只是演示。

## Consequences

### Positive

- 编制与承诺对齐，不再用 M4–M6 制造虚假进度。
- 门控与 CI 获得正确叙事：这是稀缺的信任资产，不是失败的大脑。
- 新模型可以换，信任层契约（人审规则 + 可对拍执行 + 可追溯拒绝）不随模型发布改写。

### Negative

- 「智慧大脑」对外话术需要收敛，避免与研讨稿标题冲突。
- 若未来编制或合资足以做世界模型，必须**新开 ADR** 才能把远景重新写成承诺，不可默默把路线图勾成完成。

### Risks

- 有人把「不建大脑」读成「门控也不做」。本 ADR 明确：阀门要加强，幻想要停。
- Free plan 下 `genz-gate` 仍是 advisory；owner 不配 secret，本决策的第 5 条落空。

## Implementation checklist

- [x] Accept 本 ADR（owner）— `szpeter2026` 2026-09-07
- [x] 路线图回写：M2 **门控切片** = 完成；M2 世界模型 / M3–M6 = 远景，非近期承诺
- [x] 架构设计文首增加「远景 / 受 ADR-0009 约束」状态
- [x] owner 配置 `GENZ_GATE_PAT`，三仓 genz-gate 真跑（2026-09-07 已配，三仓全绿）
- [x] 发布物补 `genz.policy_bundle_commit`（ADR-0003 未勾项）— cortex-mcp 已补
- [x] 不新开「Agent loop / 五槽落地」作为本季度必交

## Links

- 评审正文：[新一代智能大脑-信任层评审-20260907.md](../新一代智能大脑-信任层评审-20260907.md)
- [架构设计 v0.2](../新一代智能大脑架构设计.md)
- [落地路线图 v0.1](../新一代智能大脑-落地路线图.md)
- [ADR 0001](0001-lab-wukong-canonical.md) · [ADR 0003](0003-cortex-policy-bundle-pin.md)
- 个人仓语义 CI（非组织硬门禁）：https://github.com/szjason72/genz-verify/actions/runs/34044822255
- Supersedes: （无；不废止 0001–0003，只约束路线图承诺范围）
- Superseded by: （无）
