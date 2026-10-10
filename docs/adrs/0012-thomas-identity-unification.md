# ADR 0012: THOMAS 生态身份统一 —— Supabase 唯一 IdP、稳定主键注入、网关唯一验签点

- **Status**: **Accepted**（2026-10-10 由组织 owner 签署生效；**口径冻结**）
- **Signed-off-by**: `szpeter2026`（GenzLTD owner / admin，2026-10-10）
- **Co-sign**: `szjason72`（会签待补 —— 按 `adrs/README.md` 规则，组织 Admin **单人 Accept 即生效**，不阻塞）
- **Date**: 2026-10-10
- **Deciders**: `szpeter2026`（GenzLTD owner / admin，本 ADR 发起）
- **Consulted**: `szjason72`（`Tatha#5` CHANGES_REQUESTED 提出方，2026-10-09）· `looma-zervi/docs/rfc/supabase-unified-auth-v1.md`（2026-09-01，Jason 著）· `zervi-rust/api-gateway/src/tatha.rs` 源码 · `Tatha/src/tatha/api/auth.py` 源码 · `looma-zervi/backend/src/db/manager.py` 源码
- **Tags**: identity, auth, sso, supabase, gateway, email-hash, cross-repo, docs-ssot

---

## Context

### 为什么需要本 ADR

同一件"身份认证统一"的事，成员在不同仓分别开 PR：`Tatha#5`、`planetx-tatha#3`、`jobfirst-claw#64`、`looma-zervi#24/#25`。口径在多轮 review 中被反复重议，`Tatha#5` 被挂 CHANGES_REQUESTED，形成**同一决策在多个仓各评一次、结论互不知情**的循环。

本 ADR 把这组决策一次收口为组织口径：**此后口径争议走本 ADR 的 Amendment，不再在实现 PR 里辩论。**

### 已完成的地基（事实，非空）

`looma-zervi` 已实施 Supabase 统一认证（RFC `supabase-unified-auth-v1.md` D1–D6），实测源码：

| 能力 | 实现 | 位置 |
|---|---|---|
| 唯一 IdP | Supabase Auth，项目 ref `ftsnrqwynofsxdvoxnsw` | `looma-zervi/.env.example` |
| Supabase 原生 token 验签 | **JWKS / ES256（P-256）/ `aud=authenticated`**，缓存 600s | `backend/src/api/auth/jwt_handler.py:102-116` |
| 微信/华为代签 | **HS256 + `SUPABASE_JWT_SECRET`**，`iss` 指向 Supabase `auth/v1` | `jwt_handler.py:123-148` |
| 存量 looma token | `iss=looma` HS256，过渡期双轨（D6） | `resolve_auth_token` |
| 身份映射 | `sub`（Supabase UUID）→ `users.supabase_uid` → looma user，首见自动建/绑 | `decorators.py:_resolve_user` |

**结论：认证地基是实心的，且已自主可控。** 本 ADR 不动它。

### 三处接缝（阻碍"跨域、跨系统统一"的实体）

| # | 位置 | 事实 | 后果 |
|---|---|---|---|
| ① | `zervi-rust/api-gateway/src/tatha.rs:102` | 固定 `Validation::new(Algorithm::HS256)` + 单一 `DecodingKey::from_secret(GATEWAY_JWT_SECRET)` | **Supabase 原生 ES256 token 打到网关一律 401**；只有 custom HS256 代签 token 能过 |
| ② | `tatha.rs:46` 注释假定 `sub` = 邮箱 | 实际：Supabase `sub`=UUID；looma 代签 `sub`=`supabase_uid`；`zervi-rust/auth-service` `sub`=`user_id` 且 **Claims 无 email** | `email_hash(sub)` = `sha256(uuid)` ≠ looma 的 `sha256(email)` ⇒ **同一用户两套 ID** |
| ③ | `Tatha/src/tatha/api/auth.py:75` | Tatha **只读 `Authorization`，从不读 `X-User-Id`/`X-User-Tier`**（逐文件 grep 证实）；而网关把 Authorization 换成**静态** `TATHA_SERVICE_TOKEN` | Tatha 的 `user_id` 派生自该服务 token 的 `sub` ⇒ **经网关的所有用户在 Tatha 侧不可区分**，配额与技能证据塌成一个身份 |

> 接缝①的成因已被 RFC 自己标注：D2 原文「微信 custom token 用 JWT secret（HS256）签发，**网关接受性实施时验证**」。本 ADR 即该待验证项的裁决。

### 一条被误读的事实（本 ADR 予以澄清）

`looma-zervi/backend/src/db/manager.py:43` 明写：`email_hash` **"Returns None for empty email (miniprogram-only users)"**；`get_or_create_user_by_supabase` 绑定时**排除 `.thomas.local` 占位邮箱**；`game_routes.py:1150` 对空 `email_hash` 直接 `skip`。

⇒ **微信/华为小程序用户的 `email_hash` 本来就是 `None`，跨端信号按设计跳过** —— 这**不是缺陷**，更**不应用占位邮箱的 hash 冒充**。任何"让 `email_hash` 覆盖小程序用户"的方案都是错的。

---

## Decision

### D1 网关验签：双轨（JWKS 优先 → HS256 回落），保持 fail-closed

**裁定**：网关同时支持两类 token，任一通过即放行，都不通过即 401。

1. **JWKS 轨**：新增 `GATEWAY_JWKS_URL`（= `https://ftsnrqwynofsxdvoxnsw.supabase.co/auth/v1/.well-known/jwks.json`），`decode_header` 取 `kid` → `DecodingKey::from_jwk` → 接受 `ES256 / RS256 / EdDSA`，校验 `aud`。**JWKS 必须缓存**（对齐 looma `PyJWKClient(cache_keys=True, lifespan=600)`），不得每请求拉网。
2. **HS256 轨**：保留 `GATEWAY_JWT_SECRET`，用于 looma 代签的 custom token 与存量 looma token。
3. **顺序与安全**：两轨按 `kid`/`alg` 互斥，且 `Validation::new(header.alg)` 显式指定算法、JWKS 用非对称 key、HS256 用共享 secret ⇒ **不存在算法混淆空间**。
4. **未配任何密钥 ⇒ 一律 401**（维持现状的 fail-closed，不回退、不降级）。

**理由**：保持"网关唯一验签点"架构不变（否决"网关转发给 looma 代验"——那会让 Rust 网关依赖 Python 服务，扩大故障面）；不采纳"统一只发 custom HS256 token"——与 RFC D1（Supabase = 唯一 IdP、托管 email/OAuth 登录）冲突。

### D2 身份注入：`X-User-Id` 用**稳定主键**，`email_hash` **不冒充** ID

**裁定**：网关注入两个头，语义分离。

| 头 | 值 | 性质 | 用途 |
|---|---|---|---|
| `X-User-Id` | `sha256(supabase_uid)`（即 `sha256(sub)`，**规范化小写 hex**） | **必有、跨端稳定、与登录 provider 无关** | 配额计数、技能证据归属（Tatha `user_id`） |
| `X-User-Email-Hash` | `sha256(lower(trim(email)))`，**无真实邮箱时不注入该头** | 可选 | 跨端关联（信号桥 / DemoPPI / GFCC）、`email_hash` 语义 |

**关键裁决**：

1. **不得用 `email` 当身份主键。** 邮箱可变（用户改邮箱、小程序用户后绑邮箱），做 ID 不稳定；`supabase_uid` 才是不变主键。故**否决**上一版草案中"`email_hash` 改用 `claims.email`、缺失即拒"的写法。
2. **`X-User-Id` = `sha256(sub)` 的定义写死为"Supabase UUID 的 hash"**（而非"邮箱的 hash"）—— 接缝②由此从"bug"转为"明确定义的接口"。`sub` 语义不再歧义。
3. **小程序-only 用户**：`X-User-Id` 有值（配额可计数），`X-User-Email-Hash` 省略（跨端信号按既有设计跳过）。**保持 `email_hash=None` 语义不变。**
4. **反查**：下游如需邮箱，凭 `supabase_uid` 走 looma `get_user_by_supabase_uid`（不新增网关到 Supabase 的网络调用）。
5. **过渡期（存量 looma token）**：`iss=looma` 的 `sub` 是 looma user_id，与 `supabase_uid` 不同 ⇒ 同一用户持两类 token 会得到两个 `X-User-Id`。**过渡期要求 looma 侧在签发时写入 `supabase_uid` claim；未写入的 token 归入"待迁移"并在清单中登记**（见 Risks R3）。

### D3 推行：拆三单，网关先行

| 单 | 仓 | 内容 | 依赖 |
|---|---|---|---|
| 单 1 | `zervi-rust` | D1 双轨 + D2 双头注入 | 无（**先行**） |
| 单 2 | `Tatha` / `planetx-tatha` | 改读 `X-User-Id`/`X-User-Tier` + 校验请求来自网关；并入 `Tatha#5` 的 stub fail-closed | 单 1 |
| 单 3 | 前端（`shared-core` / `saas` / `planetx` / 小程序） | 切 Supabase 原生登录（RFC §7） | 单 1（否则切了必 401） |

**顺序理由**：网关是唯一验签点，前端先切会全量 401；Tatha 先改会失去身份来源。

### D4 本 ADR 为唯一裁决载体，各仓 PR 降级为"实现核对"

1. 本 ADR 生效后，`Tatha` / `planetx-tatha` / `zervi-rust` / `looma-zervi` / `jobfirst-claw` 的相关 PR **只做实现**；Review 范围限**「是否按本 ADR 实现」**，**不再重议口径**。
2. 有新的口径意见 → 向**本 ADR 提 Amendment**（改 `GenzLTD/docs`），不在实现 PR 的评论区辩论。
3. 各仓 PR **并行推进**，不再互相串行等待 review；收口在本 ADR 的 Implementation checklist。
4. **一次集中评审（本 ADR）替代 N 个仓的分散 review** —— 这是本 ADR 的直接目的。

---

## 分歧登记与裁决

| # | 分歧 / 阻塞 | 来源 | 裁决 |
|---|---|---|---|
| F1 | `Tatha#5` PR 正文与代码不一致（正文写"未配置时返回 None"，代码实际走 `_verify_token_stub`） | `szjason72` CHANGES_REQUESTED（2026-10-09） | **修订正文 + `.env.example` 第 50-51 行旧口径**；`verify_token` 分支逻辑评审已认可，**不改**. 归入单 2 一并处理 |
| F2 | 网关该不该改、改多少 | 跨仓 | **D1**：双轨。执行仓 `zervi-rust` |
| F3 | `X-User-Id` 到底生效没有 | 本 ADR 发现（接缝③） | **D2**：Tatha 改读网关注入头，删除 `Depends(get_auth)` 的服务 token 二次验签 |
| F4 | 微信/华为用户的跨端键 | RFC §11 留白 | **D2-3**：`email_hash` 保持 `None`（既有设计正确）；其身份由 `X-User-Id = sha256(supabase_uid)` 承载 |
| F5 | `yedall_attestation` 由谁签发 | `looma-zervi#24` §9 | **不在本 ADR 范围**。属**凭证背书层**（`proofs[]` 类型），与认证无关，另案推进 |
| F6 | 各仓 PR 互相请示 review | 用户反馈（2026-10-10） | **D4**：本 ADR 为唯一裁决载体，PR 只做实现核对 |

---

## 冻结口径表（生效后不得单方面变更）

| 项 | 口径 |
|---|---|
| 唯一 IdP | Supabase Auth（`ftsnrqwynofsxdvoxnsw`） |
| Token 双轨 | ① Supabase 原生 ES256/JWKS ② 微信/华为代签 HS256；存量 looma 过渡期 |
| 身份主键 | `supabase_uid`（网关侧以 `sha256(sub)` 呈现为 `X-User-Id`） |
| 跨端关联键 | `email_hash = sha256(lower(trim(email)))`，**无真实邮箱时为 `None`（跳过，不造假值）** |
| 验签点 | 网关唯一；下游不自行验签，只信任网关注入头 |
| 业务属性 | `tier` / `role` 留 looma DB（RFC D4） |
| 失败语义 | 一律 fail-closed：验不过即 401，**不回落 stub、不静默放行** |

**部署口径（三处不得漂移）**

| 变量 | 位置 | 值 |
|---|---|---|
| `GATEWAY_JWKS_URL` | 网关 | `https://ftsnrqwynofsxdvoxnsw.supabase.co/auth/v1/.well-known/jwks.json` |
| `GATEWAY_JWT_SECRET` | 网关 | = looma 的 `SUPABASE_JWT_SECRET`（同源） |
| `QUANTUM_AUTH_URL` | Tatha | 单 2 后置空（Tatha 不再自验） |

---

## Consequences

### Positive

- 跨域（Web / 微信 / 华为 / H5）、跨系统（网关 / Tatha / slice-service / claw）身份口径合一，`supabase_uid` 成为唯一主键。
- ES256 原生登录可用，前端才敢切 Supabase 托管登录（RFC §7 解锁）。
- 接缝③修复后，Tatha 配额与技能证据按真实用户区分，不再塌成服务账号。
- 口径争议有单一裁决出口（本 ADR），PR 只做实现，**消除多仓互评循环**。

### Negative

- 网关引入 JWKS 依赖（需缓存与失效处理），`zervi-rust` 需加 `jsonwebtoken/jwk` 相关依赖与一次实现投入。
- `X-User-Id` 语义变更会让**未同步更新的下游**读出非预期值 ⇒ 必须按单 1→2→3 顺序，禁止跳单。

### Risks

| # | 风险 | 缓解 |
|---|---|---|
| R1 | 有人把 `email_hash=None` 当"数据缺失"去补占位值 | 冻结口径表明写"**不造假值**"；`manager.py:43` 设计即如此 |
| R2 | JWKS 端点不可达时误放行 | D1-4：未配/取不到密钥即 401；JWKS 缓存但**失败不降级** |
| R3 | 存量 looma token 的 `sub` 是 looma user_id，与 `supabase_uid` 不一致 | 过渡期要求在 looma 签发侧写入 `supabase_uid` claim；未写入的 token 登记进迁移清单，限期清退 |
| R4 | 有人把"网关唯一验签点"读成"下游可以裸奔" | 下游必须校验请求来自网关（内网来源 + 可选网关共享头），不得暴露公网 |
| R5 | 口径又漂到各自仓讨论 | D4 硬约束：新意见走 Amendment，PR 不辩论 |

---

## Implementation checklist

- [x] **Accept 本 ADR** —— `szpeter2026` 于 2026-10-10 签署生效（`szjason72` 会签待补，不阻塞）
- [ ] 更新 `docs/adrs/README.md` 索引与 `mkdocs.yml` 导航（本 PR 已含）
- [ ] 单 1（`zervi-rust`）：`GATEWAY_JWKS_URL` + `verify_bearer` 双轨 + JWKS 缓存 + `X-User-Id`/`X-User-Email-Hash` 双头注入
- [ ] 单 2（`Tatha` / `planetx-tatha`）：改读注入头；`verify_token` 去 stub 回落；修 `.env.example` 旧口径与 PR 正文（F1）
- [ ] 单 3（前端 4 包）：切 Supabase 原生登录
- [ ] looma 签发侧写入 `supabase_uid` claim（R3）
- [ ] 验收：ES256/HS256 分别 200、无效 401；同邮箱双路径 `email_hash` 一致；**两个不同用户经网关到 Tatha 的 `user_id` 必须不同**
- [ ] 本地 dry-run 通过后方可上线（遵既定纪律）
- [ ] 成员停止在实现 PR / 聊天中重议本 ADR 已裁定的口径

---

## Links

- 实现层施工单：[`../impl/0012-identity-unification-workorder.md`](../impl/0012-identity-unification-workorder.md)（本 ADR 的实现附件，含三处接缝取证、双头注入方案、三单法与验收）
- RFC：[`looma-zervi/docs/rfc/supabase-unified-auth-v1.md`](https://github.com/GenzLTD/looma-zervi/blob/main/docs/rfc/supabase-unified-auth-v1.md)
- 相关 PR：`Tatha#5`、`planetx-tatha#3`、`jobfirst-claw#64`、`looma-zervi#24`、`looma-zervi#25`
- 相关 ADR：[ADR-0009](0009-trust-layer-over-world-model.md)（信任层）· [ADR-0003](0003-cortex-policy-bundle-pin.md)（记忆合规）
- Supersedes：（无）
- Superseded by：（无）
