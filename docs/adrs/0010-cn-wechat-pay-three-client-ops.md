# ADR 0010: 90 天技术欠债收敛为「国内 Looma 微信支付 + 三端可运营」

- **Status**: Proposed
- **Date**: 2026-09-07
- **Deciders**: 待 `szpeter2026` / `zervi-genz` Accept
- **Consulted**: szjason72（起草）、本机 `looma-zervi` 支付验收（2026-09-06 Stripe Test Mode）、Career Cosmos 90 天决策
- **Tags**: strategy, career-cosmos, payment, wechat-pay, looma-zervi, fundraising

## Context

[Career Cosmos 聚焦决策（90 天）](../聚焦决策-Career-Cosmos-90天.md)（2026-09-07，`szpeter2026` **已决策**）把组织主线收成四块拼图：T空间（怎么收钱）、X星球（用户从哪来）、信任层（ADR-0009）、Looma（共用引擎）。90 天硬动作第 4 条原文是：

> Looma 微信支付 + 三端测试从零补齐，融资时能讲「产品可运营」

同日对照本机资源后，执行上会出现三种误读：

1. **把海外沙盒当成第 4 条完成。**  
   `GenzLTD/looma-zervi` 已于 2026-09-06 跑通 Stripe **Test Mode**（Checkout → 测试卡 $1.99 → webhook 升 `supporter`）。这是海外 `region=US` 的 P2 证据，商户是沙盒、币种 USD。深创赛要讲的是**国内可运营收款**，不是 localhost 测试卡。
2. **把「三端零测试」读成从空仓库写测试。**  
   主仓已有支付单测、部分 `e2e/*.live.spec.ts`、小程序支付骨架。缺口是：**CN 区实付 + 三端能给评委复现**，不是文件数为零。
3. **把归档线的 Stripe 接回主收银。**  
   Tatha / 诗词 ErphpDown 仍有支付代码。Career Cosmos 已把这些产品归档/暂停；`PAYMENT_TIER_CONTRACT` 已禁止它们当主收银台。再接会和砍线决策打架。

支付契约（`looma-zervi` `payment.v1.json`）本来就写了：`CN` → `wechat`（P0 Stub → P1 实付）；`US` → `stripe`（P2 跨境）。与第 4 条一致。尚未变成组织 ADR。

待决问题：90 天技术欠债，到底交付「Stripe 已测过」还是交付「国内 Looma 能收微信、三端能演示可运营」？

本 ADR **不废止** Career Cosmos 决策，只对其第 4 条给出可验收的读法。Accept 前仍以聚焦决策原文为准。

## Decision

1. **第 4 条的承诺读成两句，且只这两句。**  
   - **国内 Looma 微信支付**：`PAYMENT_STUB_MODE=false` 时，CN 区走微信下单 + 回调升档，而不是 `POST /v1/payment/upgrade` 直升。  
   - **三端可运营**：T空间 SaaS、X星球 / PlaneX、微信小程序，都能让评委看到「能登录、能碰到付费门控、能完成或复现一次国内支付升档」。

2. **收银真源只有 Looma。**  
   路径：`GenzLTD/looma-zervi` 的 `/v1/payment/*` + JWT / DB `tier`。门户与端只消费 API，不自建第二套会员。Tatha、`tatha-frontend`、诗词 ErphpDown **不得**再当主收银。

3. **Stripe 的位置：架构证据，不是 90 天交付。**  
   - 本机 Stripe Test Mode 闭环**保留**，证明 Looma 会写订单、验签、升档。  
   - **不**把 Stripe Live、香港主体审核、`genz.ltd` 公网 webhook 列为深创赛 90 天 P0。那是海外站后续，编号上对应既有 PAY-L1b，排在国内微信之后。

4. **「可运营」的验收口径（Proposed，Accept 后才约束排期）。**  
   最少同时满足：  
   - CN 区 `GET /v1/payment/plans?region=CN` 的 provider 为 `wechat`，金额与契约一致（supporter ¥9.9 / pro ¥29.9）。  
   - 关闭 Stub 后，微信下单不再 400 `stub_mode`；缺商户凭证时允许 503 `payment_not_configured`，但**不得**用 Stub 冒充已收款。  
   - 一次真实或商户沙箱支付成功后，`GET /v1/payment/status` 的 `tier` 升档（不以定价卡片文案为准）。  
   - 三端至少各有一条可重复步骤（人工清单即可）：登录 → 支付入口或已付费态 → 一个受 tier 门控的产品动作（例如 T空间候选人池 / 职位发布）。  
   - 评委故事用**人民币 + 微信**；禁止用 Stripe 测试卡充当国内可运营证据。

5. **与 ADR-0009 的分工。**  
   - ADR-0009：护城河 = 信任层，不承诺世界模型大脑。  
   - 本 ADR：变现 = 国内怎么收钱、三端怎么演示。  
   两条同时成立。不新开 Agent loop / 五槽 / 世界模型来「带动」支付。

6. **本季度明确不做。**  
   - 以 Stripe Live 过审代替微信实付。  
   - 复活 Tatha 支付链或 WP 会员当融资 Demo。  
   - 把「补测试文件数量」当成第 4 条完成条件。

## Consequences

### Positive

- 编制对向深创赛：国内收款与三端演示有同一套验收语言。
- Stripe 沙盒不贬值：它证明计费骨架，只是不再占用 90 天 P0 名额。
- 与 Career Cosmos 砍线一致：归档产品的支付代码不再回流。

### Negative

- 海外 Live 收款、香港 Stripe 商户审核会排后；`genz.ltd` 审核站不能当本季度主叙事。
- 微信商户号、API v3 证书、公网 `notify` URL 是外部依赖；代码骨架就绪不等于第 4 条完成。

### Risks

- 有人把「Stripe 已 OK」读成「技术欠债已还」。本 ADR 把两条拆开：海外沙盒 ≠ 国内可运营。
- 商户资质（与硬动作第 5 条许可证）卡住时，允许报告阻塞，**不允许**用 Stub 或 Stripe 测试卡对外讲「已经能收款」。

## Implementation checklist

- [ ] Accept 本 ADR（owner）
- [ ] Accept 后在《聚焦决策-Career-Cosmos-90天》第 4 条加一句：验收口径见 ADR-0010（不改另外四条硬动作）
- [ ] `looma-zervi` PAY-L1：CN 区微信替换 Stub（凭证 + 0.01 元或官方沙箱一单 + notify 升档）
- [ ] 三端（SaaS / PlaneX / 小程序）各一条可重复的国内升档演示步骤，写入主仓验收文档
- [ ] 90 天 P0 任务板不把 Stripe Live / 香港商户审核列为必交
- [ ] 不把 Tatha / ErphpDown 支付重新接入 Looma 主收银

## Links

- 组织决策：[聚焦决策-Career-Cosmos-90天.md](../聚焦决策-Career-Cosmos-90天.md)
- 护城河：[ADR 0009](0009-trust-layer-over-world-model.md)
- 主仓契约（代码真源，非本仓）：`GenzLTD/looma-zervi` · `backend/contracts/payment.v1.json` · `docs/PAYMENT_TIER_CONTRACT.md` · `docs/COMMERCE_CLOSURE_STATUS.md` · `docs/STRIPE_SANDBOX_LOCAL_ACCEPTANCE.md`
- Supersedes: （无；不废止 Career Cosmos 全文，只约束第 4 条读法）
- Superseded by: （无）
