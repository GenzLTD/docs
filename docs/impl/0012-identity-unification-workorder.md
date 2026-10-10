# 跨系统身份认证统一 · 对齐施工单（v2 · 已按 ADR-0012 对齐）

> **本文为 [ADR-0012](../adrs/0012-thomas-identity-unification.md) 的实现层附件（施工单）** —— 裁决口径以 ADR-0012 为准，本文只讲"怎么落地"，不重议口径。
> 状态：**口径已裁定** —— 本单为实现层施工单，**不再重议口径**
> 裁决源：`GenzLTD/docs` → [ADR-0012《THOMAS 生态身份统一》](../adrs/0012-thomas-identity-unification.md)（Status: **Accepted**，2026-10-10 签署生效，口径冻结）
> 目标：实现**跨域、跨系统身份认证统一** —— Supabase Auth 为唯一 IdP，`supabase_uid` 为唯一稳定主键，网关为唯一验签点，下游只信任网关注入头。
> 适用范围：`zervi-rust`（网关）· `Tatha` / `planetx-tatha` · `looma-zervi` · 微信小程序 / Web / H5 前端
> 依据：`looma-zervi/docs/rfc/supabase-unified-auth-v1.md`（D1–D6）· `zervi-rust/api-gateway/src/tatha.rs` · `Tatha/src/tatha/api/auth.py` · `looma-zervi/backend/src/db/manager.py` · 实测源码
> 日期：2026-10-10（v1 草案）· 2026-10-10（v2 订正）

---

## 变更记录（v1 → v2）

| # | v1 原文 | v2 订正 | 依据 |
|---|---|---|---|
| 1 | 跨端关联键 = `email_hash`，**并把它当身份主键**；§2.1 写「`email_hash` 改用 `claims.email`，缺失即拒」 | **推翻**。身份主键改为 `supabase_uid`（网关以 `sha256(sub)` 注入 `X-User-Id`）；`email_hash` 降为**可选关联头** `X-User-Email-Hash` | ADR-0012 D2。邮箱可变（改邮箱 / 小程序后绑），做 ID 不稳定 |
| 2 | 微信/华为用户「`email_hash` 用占位值算」为候选方案（D2-A） | **否决**。`manager.py:43` 明写 `email_hash` 对 miniprogram-only 用户**返回 `None`**，绑定时排除 `.thomas.local` 占位邮箱 ⇒ **不造假值**，保持 `None` 语义 | ADR-0012 F4 / R1 |
| 3 | §4 列 4 个待拍板决策点 | 全部**已裁定**（D1 双轨 / D2 双头 / D3 拆三单 / D4 单裁决载体），本单不再悬置 | ADR-0012 Decision |
| 4 | 接缝② 定性为 "bug：同一用户两套 ID" | 改定性为 **"接口定义缺失"**：`sub` 语义未写死；ADR-0012 D2 已写死 `X-User-Id = sha256(sub)` | ADR-0012 D2-2 |
| 5 | （未载） | 新增 §5「分歧登记与裁决对照」，把各仓 PR 的阻塞映射到 ADR 裁决 | ADR-0012 F1–F6 |

---

## 0. 目标口径（单一事实源）

| 项 | 口径 |
|---|---|
| 唯一 IdP | Supabase Auth（项目 ref `ftsnrqwynofsxdvoxnsw`，JWKS 返回 ES256/P-256） |
| **身份主键** | `supabase_uid`（= token `sub`）；网关侧以 `sha256(sub)` 呈现为 **`X-User-Id`**，**必有、跨端稳定、与 provider 无关** |
| **跨端关联键** | `email_hash = sha256(lower(trim(email)))`；**无真实邮箱时不注入**（小程序-only 用户为 `None`，跳过，**不造假值**） |
| 验签点 | **网关（zervi-rust/api-gateway）唯一**；下游不自行验签，只信任网关注入的身份头 |
| Token 双轨 | ① Supabase 原生：**ES256**（JWKS，`aud=authenticated`） ② 微信/华为代签：**HS256**（`SUPABASE_JWT_SECRET`） ③ 存量 looma（过渡期）：HS256，`iss=looma` |
| 业务属性 | `tier` / `role` 留 looma DB（RFC D4），token claims 不承载权限 |
| 失败语义 | 一律 **fail-closed**：验不过即 401，**不回落 stub、不静默放行** |

> v1 把 `email_hash` 同时当"身份主键 + 关联键"，是本次最大的订正点。**两个头、两种语义**：`X-User-Id`（谁）与 `X-User-Email-Hash`（能否跨端关联）。

---

## 1. 现状取证：三处接缝

### 接缝 ① 网关只认 HS256，Supabase 原生 token 打不进

- 位置：`zervi-rust/api-gateway/src/tatha.rs:102`
- 事实：
  ```rust
  let mut validation = Validation::new(Algorithm::HS256);
  let data = decode::<GatewayClaims>(token, &DecodingKey::from_secret(secret.as_bytes()), &validation)
  ```
  只有一个共享密钥 `GATEWAY_JWT_SECRET`，算法硬编码 HS256。
- 后果：**Web 端走 Supabase 原生登录（ES256）拿到的 token → 网关一律 401**。只有微信/华为代签的 custom HS256 token 能过（且前提 `GATEWAY_JWT_SECRET == SUPABASE_JWT_SECRET`）。
- 佐证：RFC D2 原文已自标「微信 custom token 用 JWT secret（HS256）签发，**网关接受性实施时验证**」—— 本项即该待验证项。

### 接缝 ② `sub` 语义未写死，同一用户可能算出两套 ID

- 位置：`zervi-rust/api-gateway/src/tatha.rs:46` 注释 vs 两侧实现
- 事实：
  | 来源 | `sub` 实际值 | v1 误算的 `sha256(sub)` |
  |---|---|---|
  | 网关注释（`tatha.rs:46`） | 假定为**邮箱** | `sha256(email)` |
  | Supabase Auth 原生 | **user UUID** | `sha256(uuid)` |
  | looma 代签 custom（`sign_supabase_custom_token`） | `supabase_uid` | `sha256(uuid)` |
  | `zervi-rust/auth-service` 自签（`utils/jwt.rs`） | `user_id`，且 **Claims 无 email 字段** | `sha256(user_id)` |
- 定性（v2 订正）：**不是"算法 bug"，是"接口定义缺失"** —— `sub` 到底是什么、下游拿它算什么，从未被写死。
- 后果：若不写死，同一用户在网关与 looma 会得到两个不同的 `user_id` ⇒ 配额（free=3 / basic=20 / pro=9999）与技能证据（`get_claims` / `get_verified` 按 `user_id_hash` 聚合）跨端分裂。
- 解决：**ADR-0012 D2 写死 `X-User-Id = sha256(sub)`，且 `sub` 一律为 Supabase UUID**（存量 looma token 例外，见 R3）。

### 接缝 ③ Tatha 不读 `X-User-Id`，`user_id` 实际来自"服务 token"

- 位置：`Tatha/src/tatha/api/auth.py:75` + `app.py:230/287/394`
- 事实：
  - Tatha 全仓**只读 `Authorization` 头**（`get_bearer_token`），**从不读 `X-User-Id` / `X-User-Tier`**（逐文件 grep 证实）
  - `/v1/ask`、`/v1/jobs/match`、`/v1/rag/query` 全部 `Depends(get_auth)` → `verify_token(Authorization)`
  - 网关转发给 Tatha 时（`tatha.rs:143-152`）把 `Authorization` **换成静态的 `TATHA_SERVICE_TOKEN`**，另注入 `X-User-Id`
- 实际链路：
  ```
  客户端 --Bearer(用户 token)--> 网关
     网关 verify_bearer(GATEWAY_JWT_SECRET)        ← 接缝①
     算出 uid = sha256(claims.sub)                 ← 接缝②
     注入 X-User-Id=sha256(sub)、X-User-Tier       ← 被下游忽略
     Authorization := Bearer <TATHA_SERVICE_TOKEN> ← 静态、不区分用户
     转发 POST /v1/ask
        ↓
     Tatha /v1/ask → Depends(get_auth)
       verify_token(TATHA_SERVICE_TOKEN)
         → GET QUANTUM_AUTH_URL(=网关 /v1/auth/verify) with Bearer <TATHA_SERVICE_TOKEN>
         → 网关返回 { user_id: sha256(服务身份.sub), tier }
       Tatha 按这个 user_id 计配额
  ```
- 后果：**经网关的请求，Tatha 侧无法区分用户** —— `user_id` 恒定派生自同一个服务账号 ⇒ 所有用户的配额与技能证据塌到一个身份上；网关注入的 `X-User-Id`（真实用户）被白算。
- 性质：与 `tatha.rs:14` 的设计意图（"身份注入 `X-User-Id = sha256(email)`…下游身份统一为生态 `email_hash`"）**意图与实现不符**。属 Tatha S2 未施工完的缺口。

---

## 2. 对齐方案

> 三单法（ADR-0012 D3）：**单 1 网关先行 → 单 2 Tatha 跟进 → 单 3 前端切原生登录**。禁止跳单。

### 2.1 单 1 · 网关（zervi-rust）：支持 JWKS/ES256 + 双头注入 —— 吃掉 ①②

**改动文件**：`api-gateway/src/tatha.rs`（+ 可能的 `main.rs` / `Cargo.toml`）

1. **新增配置**
   ```
   GATEWAY_JWKS_URL=https://ftsnrqwynofsxdvoxnsw.supabase.co/auth/v1/.well-known/jwks.json
   GATEWAY_JWT_SECRET=<legacy SUPABASE_JWT_SECRET，用于 custom HS256 代签 token>
   GATEWAY_JWT_AUDIENCE=authenticated
   ```
2. **`GatewayClaims` 增加 `email`**（用于可选头，**不用于主键**）
   ```rust
   struct GatewayClaims {
       sub: String,
       #[serde(default)] email: Option<String>,   // 新增：仅用于 X-User-Email-Hash
       #[serde(default)] tier: Option<String>,
   }
   ```
3. **`verify_bearer` 改为双轨**（两轨按 `kid`/`alg` 互斥，且 `Validation::new(header.alg)` 显式指定算法 ⇒ 无算法混淆风险）
   ```rust
   // 1) JWKS：Supabase 原生 ES256/RS256/EdDSA
   if let Some(url) = env_nonempty(ENV_JWKS_URL) {
       if let Some(c) = decode_via_jwks(token, &url) { return Some(c); }
   }
   // 2) HS256：looma 代签 / 存量
   if let Some(secret) = env_nonempty(ENV_JWT_SECRET) {
       let mut v = Validation::new(Algorithm::HS256);
       v.validate_aud = false;
       if let Ok(d) = decode::<GatewayClaims>(token, &DecodingKey::from_secret(secret.as_bytes()), &v) {
           return Some(d.claims);
       }
   }
   None   // 保持 fail-closed：都不通过即 401
   ```
   `decode_via_jwks` 用 `decode_header` 取 `kid` → 在 **AppState 里缓存 JWKS**（对齐 looma 的 `PyJWKClient(cache_keys=True, lifespan=600)`，勿每请求拉网）→ `DecodingKey::from_jwk` → `Validation::new(header.alg)` + `aud=authenticated`。**JWKS 取不到 ⇒ 401，不降级。**
4. **身份注入改为双头**（**v2 订正**，取代 v1 的「`email_hash` 改用 `claims.email`，缺失即拒」）
   ```rust
   // 主键：必有。sub = Supabase UUID ⇒ 跨端稳定、与 provider 无关
   let uid = sha256_hex(claims.sub.to_lowercase());       // 必定注入
   // 关联：可选。无真实邮箱（小程序-only）则不注入该头，不造假值
   let email_hash = claims.email.as_deref()
       .map(str::trim)
       .filter(|e| !e.is_empty())
       .map(|e| sha256_hex(&e.to_lowercase()));           // Option<String>
   ```
   转发时：`X-User-Id = uid`（必发）、`X-User-Email-Hash = email_hash`（有则发）、`X-User-Tier = claims.tier`。
   > ⚠️ **不得**把 `email_hash` 当身份主键，也**不得**在缺邮箱时用占位值（`@wechat.thomas.local`）算 hash 顶替 —— 见 ADR-0012 R1。

### 2.2 单 2 · Tatha（+ planetx-tatha）：信任网关注入，停止"服务 token 二次验签" —— 吃掉 ③

- **改法（推荐）**：`/v1/ask`、`/v1/jobs/match`、`/v1/rag/query` 改为读 `X-User-Id`（**主键，配额/技能证据用**）与 `X-User-Email-Hash`（可选，跨端关联用），并校验请求确实来自网关（内网来源 + 可选 `X-Gateway-Auth` 共享密钥），**不再 `Depends(get_auth)`**。
- **同时做（Tatha#5 已备）**：`verify_token` 去掉 stub 回落，配了 URL 就 fail-closed（保持纵深防御一致性）。
- **F1 一并处理**：修 `.env.example` 第 50-51 行旧口径 + PR 正文与代码不一致（只改文案，分支逻辑不动）。
- **协调**：与 looma-zervi S2 施工单口径合并，一次性把"网关按路由鉴权 + claw 带 token"收口。
- ⚠️ 若保留 Tatha 侧二次验签，则 `TATHA_SERVICE_TOKEN` 必须能承载用户上下文（**不建议**：等于把用户身份放进服务凭据）。

### 2.3 单 3 · 前端：切 Supabase 原生登录

- 范围：`shared-core` / `saas` / `planetx` / 小程序（RFC §7）。
- **必须等单 1 上线**：网关未支持 JWKS 前切原生登录 = 全量 401。

### 2.4 部署配置口径（三处不得漂移）

| 变量 | 位置 | 值 |
|---|---|---|
| `GATEWAY_JWKS_URL` | 网关 | `https://ftsnrqwynofsxdvoxnsw.supabase.co/auth/v1/.well-known/jwks.json` |
| `GATEWAY_JWT_SECRET` | 网关 | = Supabase 项目 legacy JWT secret（与 looma `SUPABASE_JWT_SECRET` 同源） |
| `GATEWAY_JWT_AUDIENCE` | 网关 | `authenticated` |
| `QUANTUM_AUTH_URL` | Tatha | = 网关 `GET /v1/auth/verify`（单 2 后若 Tatha 不再自验则置空） |
| `SUPABASE_JWT_SECRET` | looma 后端 | 同源 |
| `ALLOWED_SKILL_ISSUERS` | Tatha | `guibu`（凭证层，与本单无耦合） |

---

## 3. 验收

1. ES256 token（Supabase 原生登录）→ 网关 `POST /v1/ask` **200**；HS256 代签 token → **200**；无效/过期 → **401**（fail-closed 不回退）。
2. **主键稳定性**：同一 `supabase_uid` 经不同 provider（密码 / Google OAuth / 微信代签）登录，网关注入的 `X-User-Id` **逐字节相同**。
3. **关联键正确性**：同邮箱两条路径的 `X-User-Email-Hash` **逐字节相同**；**小程序-only 用户不注入 `X-User-Email-Hash`**（且不得出现占位值 hash）。
4. **接缝③回归**：两个不同用户经网关打到 Tatha，Tatha 侧 `user_id` **必须不同**。
5. 网关未配 `GATEWAY_JWKS_URL` 且未配 `GATEWAY_JWT_SECRET` → 一律 401，无放行。
6. 本地 dry-run 通过后再谈上线（遵既定纪律）。

---

## 4. 决策点（v1 悬置 → v2 已裁定）

| # | 决策点 | 裁定 | 出处 |
|---|---|---|---|
| **D1** | 网关验签策略 | **双轨**：JWKS/ES256 优先 → HS256 回落，均 fail-closed（否决"网关转发 looma 代验"与"统一只发 custom HS256"） | ADR-0012 D1 |
| **D2** | 身份注入口径 | **双头**：`X-User-Id = sha256(sub)`（必有）+ `X-User-Email-Hash = sha256(email)`（可选，无则省略）。**不得用 email 当主键，不得造假值** | ADR-0012 D2 |
| **D3** | 推行方式 | **拆三单**：网关先行 → Tatha 跟进 → 前端切原生登录，禁止跳单 | ADR-0012 D3 |
| **D4** | 评审收口 | ADR-0012 为**唯一裁决载体**；各仓 PR 只做实现核对，新意见走 Amendment | ADR-0012 D4 |

---

## 5. 分歧登记与裁决对照（来源 ADR-0012 F1–F6）

| # | 分歧 / 阻塞 | 本单归属 | 状态 |
|---|---|---|---|
| F1 | `Tatha#5` PR 正文与代码不一致（正文写"未配置时返回 None"，代码走 `_verify_token_stub`） | §2.2 一并处理（只改文案） | 待施工 |
| F2 | 网关该不该改、改多少 | §2.1（单 1） | 已裁定 |
| F3 | `X-User-Id` 到底生效没有 | §2.2（单 2，接缝③） | 已裁定 |
| F4 | 微信/华为用户的跨端键 | §2.1-4 + §3 验收 3 | 已裁定（`email_hash=None`，不造假值） |
| F5 | `yedall_attestation` 由谁签发（`looma-zervi#24` §9） | **不在本单范围** —— 属**凭证背书层**（`proofs[]` 类型），与认证统一无耦合，另案推进 | 摘出 |
| F6 | 各仓 PR 互相请示 review | 本单 + ADR-0012 D4 | 已裁定 |

---

## 6. 风险与纪律

| # | 风险 | 缓解 |
|---|---|---|
| R1 | 有人把 `email_hash=None` 当"数据缺失"去补占位值 | 冻结口径写明"**不造假值**"；`manager.py:43` 设计即如此 |
| R2 | JWKS 端点不可达时误放行 | §2.1-3：未配/取不到密钥即 401；缓存但**失败不降级** |
| R3 | 存量 looma token 的 `sub` 是 looma user_id，与 `supabase_uid` 不一致 | 过渡期要求在 looma 签发侧写入 `supabase_uid` claim；未写入的 token 登记迁移清单，限期清退 |
| R4 | 有人把"网关唯一验签点"读成"下游可以裸奔" | 下游必须校验请求来自网关（内网来源 + 可选 `X-Gateway-Auth`），不得暴露公网 |
| R5 | 口径又漂到各自仓讨论 | ADR-0012 D4 硬约束：新意见走 Amendment，PR 不辩论 |

**既定纪律**：任何真实部署前必先完成本地 dry-run / simulation 验证。

---

## 7. 相关链接

- 裁决源：[`../adrs/0012-thomas-identity-unification.md`](../adrs/0012-thomas-identity-unification.md)
- RFC：`looma-zervi/docs/rfc/supabase-unified-auth-v1.md`
- 相关 PR：`Tatha#5`、`planetx-tatha#3`、`jobfirst-claw#64`、`looma-zervi#24`、`looma-zervi#25`
- 关键源码位置：
  - `zervi-rust/api-gateway/src/tatha.rs`（:46 注释 / :102 验签 / :143-152 转发）
  - `Tatha/src/tatha/api/auth.py:75`、`Tatha/src/tatha/api/app.py:230/287/394`
  - `looma-zervi/backend/src/api/auth/jwt_handler.py:102-148`、`decorators.py:_resolve_user`
  - `looma-zervi/backend/src/db/manager.py:43`（`email_hash` 对小程序-only 返回 `None`）
