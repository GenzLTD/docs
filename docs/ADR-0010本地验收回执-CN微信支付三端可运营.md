# 落地验收回执：ADR-0010「国内 Looma 微信支付 + 三端可运营」本机 review

> **发文**：8bt8rcrg95-coder（reviewer / 把关） · **收文**：szpeter2026（Decider，Accept 权）
> **日期**：2026-09-07 · **关联 ADR**：0010（Proposed，分支 `docs/adr-0010-cn-wechat-ops`）
> **依据**：`docs/adrs/0010-cn-wechat-pay-three-client-ops.md` · 本机真源 `~/THOMAS/looma-zervi`（GenzLTD GitHub，分支 `fix/pnpm-version` + 未提交改动）
> **结论先行**：**代码/逻辑层本机实测全部通过，ADR-0010 的 Decision 1/2/4（代码部分）与真实代码逐条吻合；可以 Accept。** 阻塞/遗留均为文档悬空、凭证外依与三端页面级人工核验，详见第四节，不构成代码否决。

---

## 一、本机验证对象与基线

- **代码真源**：`~/THOMAS/looma-zervi`（remote = `GenzLTD/looma-zervi`，本地 API 唯一活跃入口；`~/Projects/looma-zervi` 为生态工作副本，含三端前端）
- **基线 commit**：`5c7f5c5` + 未提交改动（`plans.py` SG→US 部署位别名、`tests/`、`QCC_CHINA_GATEWAY.md`、`PAYMENT_LAUNCH_PLAN.md` 等，未合 main）
- **运行环境**：Mac · `backend/venv` Python 3.12.13 · Flask 3.1.3 · pytest 9.1.1 · `.env` 在位

---

## 二、实测验证记录（本机运行）

### 1. 支付测试组（stub=false + temp DB + fake 凭证 夹具）

| 命令 | 结果 |
|---|---|
| `venv/bin/python -m pytest tests/test_payment_{plans,jsapi,notify,guard,refresh}.py` | ✅ **44 passed / 40.6s**（4 个 HMAC key 长度 warning，非错误） |

测试断言与 ADR 验收语义直接对应（`test_payment_guard.py`）：

| ADR-0010 验收口径 | 本机测试断言 | 结果 |
|---|---|---|
| 关 Stub 后不得用 `/upgrade` 直升 | `upgrade` + `stub=false` → **402 `payment_required`** | ✅ |
| Stub 模式下微信下单被拒 | `wechat/order` + `stub=true` → **400 `stub_mode`** | ✅ |
| 缺商户凭证时 503 | `wechat/order` + `stub=false` 无凭证 → **503 `payment_not_configured`** | ✅ |
| 不允许降级 / 不允许同档重复升 | 降级与同档 → 400 | ✅ |
| Stub 状态不泄漏到公开响应 | `plans` / `payment/status` 响应体**不含 `stub_mode`** | ✅ |
| 微信回调 RSA 验签 / 异常体处理 | `test_payment_notify.py` | ✅ |
| JSAPI openid 自动填充 + 下单入 DB | `test_payment_jsapi.py` | ✅ |

### 2. plans 模块真实运行（不经 mock）

```
CN provider: wechat | currency: CNY | providers: [wechat, huawei_iap]
  supporter = 支持者版  price_monthly 9.9  CNY  plan_id supporter_monthly_cn
  pro       = 专业版    price_monthly 29.9 CNY  plan_id pro_monthly_cn
US provider: stripe | currency: USD
  supporter / pro 均为 USD 美元档（supporter_monthly_us / pro_monthly_us）
```

→ 与 ADR 验收「CN 区 `provider=wechat`、supporter ¥9.9 / pro ¥29.9、US→stripe」**逐条一致**。

### 3. 三端接线（源码级核对，工作副本 `~/Projects/looma-zervi/frontend`）

| 端 | 证据 | 判定 |
|---|---|---|
| 微信小程序 | `packages/miniprogram/pages/pricing/index.ts` **源码实接**支付；`miniprogram_npm/@looma/shared-core` 注入 | ✅ 实接 |
| T空间 SaaS | `packages/saas/src/*` 大量 import `shared-core`（region/brand/candidates/chat），支付走 `shared-core` 封装 | ⚠️ 支付页/门控需人工清单复核 |
| X星球 PlanetX | `packages/planetx/src` import `shared-core`（auth/analytics）；`dist` 含支付打包 | ⚠️ 同上 |
| 共享层 | `shared-core/src/constants/routes.ts`：`PAYMENT_WECHAT_ORDER=/v1/payment/wechat/order`、`PAYMENT_WECHAT_NOTIFY=/v1/payment/wechat/notify` 等全量支付路由常量 | ✅ |

---

## 三、评审结论

**代码/逻辑：通过（approve）。** ADR-0010 约束的「国内微信下单 + 回调升档、禁止 Stub/upgrade 冒充实付、缺凭证 503 语义、金额与 provider 对齐契约」在真源代码中**已实现且被本机 44 项测试锁定**。ADR 不是待办蓝图，而是对已有代码的验收固化与排期红线——Accept 风险低。szjason72 起草内容与 `GenzLTD/looma-zervi` 现状一致，未见逻辑漂移。

---

## 四、⚠️ 阻塞与遗留（Accept 前需处理，不构成代码否决）

1. **ADR 引用文档悬空**：Links 列的 `docs/STRIPE_SANDBOX_LOCAL_ACCEPTANCE.md` 在本机所有 looma 树与 `origin/main` **均不存在**；实际存在 `DUAL_TRACK_ACCEPTANCE_CHECKLIST.md` / `COMMERCE_CLOSURE_STATUS.md` → 需更正链接。
2. **契约文档回调路径写错**：`PAYMENT_TIER_CONTRACT.md` 写 `/v1/payment/notify/wechat`；代码与 `PAYMENT_LAUNCH_PLAN.md` 真源为 **`/v1/payment/wechat/notify`** → 契约文档该行需修正。
3. **Stripe 沙盒证据无法在本机复现**：ADR 声称 2026-09-06 Stripe Test Mode 闭环，本机无对应验收文档留档。
4. **真源多副本不同步**：`~/THOMAS` / `~/Projects` / `~/Desktop/declare` 三份 HEAD 不一致；`THOMAS` 活跃分支为 `fix/pnpm-version`（非 main）且带未提交改动 → 评估基线需锁定到 main 后回填。
5. **本机无法实测项**（凭证外依，命中 ADR 自身"允许报告阻塞"红线）：真实微信 API v3 下单、真实平台回调签名、0.01 元沙箱实付——需商户 6 件套 + HTTPS 回调域到位后在 `~/THOMAS` 复测。
6. **三端页面级门控**：saas / planetx 是否已有「登录 → 付费门控 → 支付入口」页面需前端本地起服人工清单复核。

---

## 五、Accept 前置动作建议

- [ ] 修 ADR-0010 Links 悬空文档引用 + `PAYMENT_TIER_CONTRACT.md` 回调路径
- [ ] 明确发布者 `szjason72` 与权威工作区的关系（Decider 知情）
- [ ] saas / planetx 门控人工清单（前端本地起服）
- [ ] 微信凭证到位后，在 `~/THOMAS/looma-zervi` 补 Phase B-2 实测（0.01 元或商户沙箱一单 + notify 升档）

---

*本回执为 8bt8rcrg95-coder 本机实测定论，可作为 szjason72（起草）→ szpeter2026（Decider）Accept ADR-0010 的依据存档与下一步动作清单。*
