> 📌 **框架说明（2026-10-11）**：本 ADR 引用的《聚焦决策-Career Cosmos 90 天》已于 2026-10-11 关闭（融资 / 创赛导向放弃，见 PR #42），其「已决策」表述转为历史背景。本 ADR 的「国内 Looma 微信支付 + 三端可运营」技术目标仍有效（属产品打磨），但不再以「服务融资」为理由；ADR-0010 仍为 Proposed。

# ADR 0010: 90 天技术欠债收敛为「国内 Looma 微信支付 + 三端可运营」

- **Status**: Proposed
- **Date**: 2026-09-07
- **Deciders**: 待 `szpeter2026` / `zervi-genz` Accept（**本 PR 不请求 Accept**）
- **Consulted**: szjason72（起草）、xiajason（PR #10 Request changes）、zervi-genz（Owner 产品化评审，已入 main）
- **Tags**: strategy, career-cosmos, payment, wechat-pay, looma-zervi, fundraising

## Context

[Career Cosmos 聚焦决策（90 天）](../聚焦决策-Career-Cosmos-90天.md)（2026-09-07，`szpeter2026` **已决策**）第 4 条原文是：

> Looma 微信支付 + 三端测试从零补齐，融资时能讲「产品可运营」

执行上会出现三种误读：把海外 Stripe 沙盒当成第 4 条完成；把「三端零测试」读成从空仓库写测试；把已归档的 Tatha / ErphpDown 支付接回主收银。

本 ADR **不废止** Career Cosmos，只给第 4 条一个可验收的读法。Accept 前仍以聚焦决策原文为准。

Owner 已在 main 写明：三端支付是统一现金流管道和商业期权，不是三条平均产品线；**「支付已接通」≠「某端已形成稳定收入」**。在统一身份 / 订单 / 支付 / 权益底座和首轮交易验证前，本 ADR 保持 Proposed。见 [Owner 产品化评审](../ADR-0010-owner产品化评审意见-20260907.md)。

### 证据分层（回应 xiajason：已实现 / 已验证 / 待交付必须分开）

权威代码基线：**`GenzLTD/looma-zervi` `origin/main` `08f38fc`**（2026-09-03）。不采用未提交工作区、`fix/pnpm-version`、或本机未入库文档作为 ADR 证据。

| 层 | 状态 | 说明 |
|---|---|---|
| **已实现（main 代码）** | 是 | `/v1/payment/*`、CN `payment.v1.json` provider=`wechat`、Stub 关闭后 `/upgrade` 不得直升、缺凭证下单应失败。回调代码路径为 **`POST /v1/payment/wechat/notify`**。 |
| **已验证（可复现、已入库）** | 否 | 国内微信实付、公网 notify、三端人工升档演示均未在权威 commit 上关闭。 |
| **工作区观察（不作证据）** | 仅备忘 | Win ServBay：`C:\ServBay\www\looma-zervi` 对应该仓；vhost `looma-zervi.local` 反代 `:5200`。核对当时 `:5200` 未监听；`.env` 无微信商户六项。`docs/STRIPE_SANDBOX_LOCAL_ACCEPTANCE.md` **仅存在于未跟踪本地文件**，`origin/main` **没有**该文件。 |
| **待交付 / 需团队配合** | 是 | 见下文 Decision 4 的采纳后条件，以及 [团队配合事项](../ADR-0010-团队配合事项-20260907.md)。 |

文档路径注意：`PAYMENT_TIER_CONTRACT.md`（main 有）§4.4 仍写 `POST /v1/payment/notify/wechat`，与代码真源不一致。以代码为准；契约文档须在 **looma-zervi** 仓修正，不在本 ADR 里假装已改。

## Decision

1. **第 4 条读成两句，且只这两句。**  
   - **国内 Looma 微信支付**：`PAYMENT_STUB_MODE=false` 时，CN 区走微信下单 + 回调升档，而不是 `POST /v1/payment/upgrade` 直升。  
   - **三端可运营**：T空间 SaaS、X星球 / PlaneX、微信小程序，都能演示「登录 → 付费门控 → 国内支付升档或已付费态」。这是 **Accept 之后的交付条件**，不是当前已验证事实。

2. **收银真源只有 Looma。**  
   `GenzLTD/looma-zervi` 的 `/v1/payment/*` + JWT / DB `tier`。Tatha、`tatha-frontend`、诗词 ErphpDown **不得**再当主收银。

3. **Stripe 的位置：海外计费骨架，不是 90 天交付。**  
   - 不把 Stripe Live、香港主体审核列为深创赛 P0。  
   - 不把未入库的本机 Stripe 验收文档链进本仓当作已验证证据。若将来要引用，须先合入 `looma-zervi` `main` 再改本 ADR Links。

4. **「可运营」口径（采纳后才约束排期；现在不构成 Accept 条件）。**  
   - CN 区 plans 的 provider 为 `wechat`，金额与 `payment.v1.json` 一致。  
   - 关 Stub 后不得用 `/upgrade` 冒充实付；缺商户凭证允许 503，禁止 Stub 对外讲已收款。  
   - 真实或商户沙箱支付成功后，以 `GET /v1/payment/status` 的 `tier` 为准。  
   - 三端各一条可重复步骤（人工清单即可），由前端负责人写入 **looma-zervi** 验收文档。  
   - 评委故事用人民币 + 微信。  
   - 按 Owner 评审：先统一身份 / 订单 / 回调 / 权益，再比较三端真实交易；未出现金流的端保持最小可运营。

5. **与 ADR-0009 的分工。** 0009 = 信任层护城河；本 ADR = 国内怎么收钱。不新开世界模型 / Agent loop 带动支付。

6. **本季度明确不做。** Stripe Live 代替微信；复活 Tatha/WP 收银；把「补测试文件数」当成第 4 条完成。

## Consequences

### Positive

- 第 4 条有读法，且与 Owner「管道 ≠ 收入」一致。
- 治理记录不再把未入库文档和未提交代码写成已验收。

### Negative

- Accept 要等商户、公网回调和至少一轮国内交易证据；合并本 Proposed 文本不等于产品已成立。
- looma-zervi 契约文档回调路径仍错，须该仓自己改。

### Risks

- 有人把「ADR 已合进 docs」读成「微信已能收款」。本 ADR 保持 Proposed，并单独列出团队配合事项。

## Implementation checklist

**本 PR / Proposed 文本（不请求 Accept）**

- [x] 修正悬空引用：去掉 `STRIPE_SANDBOX_LOCAL_ACCEPTANCE.md`；写明回调代码路径
- [x] 锁定权威基线为 `looma-zervi` `origin/main` `08f38fc`
- [x] 三端人工步骤列为采纳后交付，不列为当前已验证
- [ ] CODEOWNER 重新 review（xiajason / owner）

**Accept 仍由 owner 决定；下列为采纳后 / 阻塞交易验证的配合项（见配套文）**

- [ ] 内地微信商户六项凭证 + 公网 `WECHAT_NOTIFY_URL` 指向 `/v1/payment/wechat/notify`
- [ ] looma-zervi 修正 `PAYMENT_TIER_CONTRACT.md` / `TENCENT_CLOUD_COMMERCE.md` 回调路径
- [ ] SaaS / PlanetX / 小程序各一条可重复国内升档演示步骤（写入主仓，不写进本 ADR 当已完成）
- [ ] Accept 后在《聚焦决策》第 4 条加指针（不改另外四条硬动作）

## Links

- 组织决策：[聚焦决策-Career-Cosmos-90天.md](../聚焦决策-Career-Cosmos-90天.md)
- 调研建议（不替代决策）：[聚焦决策-Career-Cosmos-90天-调研建议.md](../聚焦决策-Career-Cosmos-90天-调研建议.md)
- Owner 评审：[ADR-0010-owner产品化评审意见-20260907.md](../ADR-0010-owner产品化评审意见-20260907.md)
- 需团队配合：[ADR-0010-团队配合事项-20260907.md](../ADR-0010-团队配合事项-20260907.md)
- 护城河：[ADR 0009](0009-trust-layer-over-world-model.md)
- 主仓（权威 `main`）：[`GenzLTD/looma-zervi`](https://github.com/GenzLTD/looma-zervi) · [`backend/contracts/payment.v1.json`](https://github.com/GenzLTD/looma-zervi/blob/main/backend/contracts/payment.v1.json) · [`docs/COMMERCE_CLOSURE_STATUS.md`](https://github.com/GenzLTD/looma-zervi/blob/main/docs/COMMERCE_CLOSURE_STATUS.md) · [`docs/PAYMENT_TIER_CONTRACT.md`](https://github.com/GenzLTD/looma-zervi/blob/main/docs/PAYMENT_TIER_CONTRACT.md)（回调路径以代码 `POST /v1/payment/wechat/notify` 为准）
- Supersedes: （无）
- Superseded by: （无）
