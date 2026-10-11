# ADR 0013: 跨系统隔离边界 —— 身份统一的对偶命题、隔离等级（L0–L4）与边界矩阵

- **Status**: Proposed
- **Date**: 2026-10-11
- **Deciders**: 组织 Admin（`szpeter2026` / `zervi-genz` / `szjason72`）Accept；Member 可提 Proposed（按 `adrs/README.md` 规则，Admin **单人 Accept 即生效**）
- **Drafted-by**: `szjason72`（ADR 起草主线，见 `.github/CODEOWNERS`：`/docs/adrs/` → `@szjason72 @xiajason`）
- **Consulted**: [ADR 0012](0012-thomas-identity-unification.md)（对偶命题）· [ADR 0002](0002-l0-pii-sg-deny-policy.md)（L0 分级词根）· [ADR 0008](0008-docs-single-source-site.md)（文档单真源）· 本机组织仓快照取证（2026-10-11，见下「现状取证」）· `looma-zervi/.env.example` · `looma-zervi/backend/src/api/auth/supabase_auth.py`
- **Tags**: isolation, boundary, multi-tenant, secrets, cross-repo, cross-cloud, evidence, docs-ssot
- **附件**: [isolation-boundary-notes.md](isolation-boundary-notes.md)（现状快照与待办，**会过期，非决策记录**）

---

## Context

### 为什么需要本 ADR

[ADR 0012](0012-thomas-identity-unification.md) 解决的是「**谁是谁**」：身份统一到 `supabase_uid`、网关唯一验签点、跨端关联键 `email_hash` 口径冻结。

但身份统一只回答了一半问题：**统一之后，谁能看见谁？** 这一半在现有文档体系里没有载体，后果是可观察的：

1. **同一「隔离」议题无裁决出口** —— 与 0012 的 F6（各仓 PR 互相请示 review）同构；隔离口径在实现 PR 里被反复重议。
2. **「已经隔离了」这句话不可比** —— 它可能指 RLS 策略、可能指一个 `where user_id=?`、也可能指「表名加了前缀」。三者的安全性差一个数量级，但在口头沟通里长得一模一样。
3. **误读会沉淀成"事实"** —— 本轮取证即发现：**"looma-zervi 已有 Supabase RLS" 这一说法在本机快照中无任何证据支持**（详见「现状取证」#1、以及「一条必须澄清的误读」）。

本 ADR 与 0012 互为对偶：**0012 管「身份可识别」，0013 管「边界可隔离」**。二者合起来才构成完整的身份域口径，单独任何一条都不是完整答案。

### 术语来源（不引入新体系）

本 ADR 的隔离等级 **L0–L4** 沿用 [ADR 0002](0002-l0-pii-sg-deny-policy.md) 已确立的 `L0_PII` 分级语言。L0 在 0002 中表示"最高敏感级"，在本 ADR 中表示"隔离强度最低级"——**同名不同轴**，已在冻结口径表中显式区分，避免混淆。

### 现状取证（2026-10-11）

> 取证方法：对 `GenzLTD_org_backup_github` 本机快照逐仓 grep 与目录核读；命令可复现，见附件「取证方法」。
> 下表区分【已取证】与【未取证】。**未取证的断言不得作为裁决依据**（见 Risks R1）。

| # | 断言 | 等级 | 证据 |
|---|---|---|---|
| 1 | `looma-zervi` **无 RLS 策略**：全仓无 `ENABLE ROW LEVEL SECURITY` / `CREATE POLICY`，无 migrations / supabase / policies 目录 | 【已取证】 | `grep -ril "enable row level security\|create policy" looma-zervi --include=*.sql --include=*.py --include=*.md` → **0 命中** |
| 2 | `looma-zervi` **无多租户概念**：`backend/src` 中 `tenant` 仅 1 处词面命中（`db/manager.py`），无 `tenant_id` 建模 | 【已取证】 | `grep -ril "tenant_id\|tenant" backend/src --include=*.py` |
| 3 | **单一 Supabase project**：`.env.example` 仅一个 ref，无 dev/prod 第二 ref | 【已取证】 | `.env.example:20` → `SUPABASE_URL=https://ftsnrqwynofsxdvoxnsw.supabase.co` |
| 4 | `service_role` 用途为 **Auth Admin API**（upsert 微信/华为用户），非业务表读写 | 【已取证】 | `api/auth/supabase_auth.py:5` 注释 + `:33-35` 读 `SUPABASE_SECRET_KEY` |
| 5 | 后端已有鉴权中间件层 | 【已取证】 | `backend/src/api/{auth,middleware,routes}` 目录存在 |
| 6 | 环境分流落在 **nginx 层**，无部署级环境隔离配置 | 【已取证】 | `deploy/nginx` + 仓根 `nginx-looma-zervi.conf` / `-ip.conf` / `-overseas.conf` / `nginx-vultr.conf` |
| 7 | `docs` 仓 CODEOWNERS **文件已就位**（`/docs/adrs/` → `@szjason72 @xiajason`），但 **Free 计划 + 私有仓下 GitHub 无法强制审批** | 【已取证】 | `.github/CODEOWNERS`；`gh api repos/GenzLTD/docs/branches/main/protection` → **403** `Upgrade to GitHub Pro or make this repository public`（`rulesets` 同为 403） |
| 7b | `docs` 仓 CI **间歇性不可用**：近 40 次 run 中 11 次 failure，失败 job 为 `runner=-`、**0 step**、约 2s 退出（runner 未被分配） | 【已取证】 | 失败 run `38100275469` / `38062715391` 对比成功 run `38063534617`（`runner=GitHub Actions 1000002863`、5 step 全绿） |
| 8 | `gitee-sync-bot` 使用**全域写权限 PAT** | **【未取证】** | 该仓不在本机快照（属 `zervi-genz` 个人账号），需在 GitHub 侧查其 workflow secrets 与 token scope 后才能认定 |
| 9 | `looma-zervi` 会员三级（free/pro/enterprise）配额校验在前端 | **【未取证】** | 本轮未取证；不得据此外推 |

### 一条必须澄清的误读

组织内部（及本 ADR 的起草过程中）出现过这样的表述：

> 「`looma-zervi` 的租户隔离已经做到 L2，因为 Supabase RLS 已落地。」

**取证结论：#1 表明全仓不存在任何 RLS 策略；#2 表明连多租户建模都没有。该表述不成立。**

按本 ADR 的评级，`looma-zervi` 当前实际落在 **L1**（数据隔离依赖应用层代码里的用户过滤，无数据库级强制约束）。将 L2/L3 当作既成事实，会让后续风险判断整体偏移一个量级——这正是本 ADR 要建立的「**任何"已隔离"结论必须附取证**」纪律的直接动因。

---

## Decision

### D1 采用隔离等级 L0–L4 作为组织统一评级语言

| 等级 | 实现方式 | 失效方式 | 判定 |
|---|---|---|---|
| **L0** | 表名前缀 / 共享连接池 / 命名约定 | 一条 SQL 越权即全穿 | **假隔离**，不得声明为"已隔离" |
| **L1** | 应用层代码手工过滤（`where user_id=?`） | 漏写一处即越权 | 假隔离，不得声明为"已隔离" |
| **L2** | 数据库 RLS 策略强制 | 共用 project，密钥与元数据未分离 | 合格下限 |
| **L3** | 独立 schema / 独立 bucket / 独立密钥 | 项目仍共享，控制面元数据互见 | **组织目标位** |
| **L4** | 独立 project / 独立账户 / 独立网络出口 | 运维成本上升 | 企业版可考虑，非当前目标 |

**裁定**：任何"某边界已隔离"的结论，必须同时给出等级与取证；**只给 L0 / L1 的边界，一律不得对外表述为"已隔离"**。

### D2 采用「隔离边界矩阵」作为评审载体：四类边界 × 六维

**四类边界（当前组织全量）**

| 编号 | 边界 | 对象 |
|---|---|---|
| **B1** | 用户级边界 | `looma-zervi` 内用户 A 与用户 B 的数据（**现为单租户，无 tenant 建模**，见取证 #2） |
| **B2** | 环境边界 | dev / staging / prod |
| **B3** | 主体与云边界 | 企业主体（szbolent.com.cn @腾讯云）· 个人主体（szbolent.cn @阿里云）· 海外（Vercel + Vultr） |
| **B4** | 代码与仓边界 | `GenzLTD` 组织 · `szpeter2026` 个人 · `zervi-genz` 个人 · Gitee 镜像 |

**六个维度**：身份 · 数据 · 密钥 · 网络出口 · 日志审计 · 时序与配额。

每个单元格取值为 **共享 / 隔离 / 单向**，取值理由与取证一并登记在附件清单中。

### D3 隔离强度以**最弱一维**计，不以平均值计

**裁定**：一条边界的等级 = 其六维中**最弱**的那一维的等级。密钥一维共享，身份与数据隔离即同时归零。

**理由**：隔离失效不是"平均失效"，是"最短木板失效"。分母是攻击者能找到的最弱那一维，不是设计者的平均投入。

### D4 修复优先级：密钥 > 日志 > 数据 > 网络

**裁定**：发现同一边界多处不足时，按此顺序先修。**理由**：取证与行业实践一致——泄漏绝大多数不发生在数据层，而发生在密钥层（一处凭据通吃）与日志层（一处报错回显反向打通）。数据层通常已被认真对待，密钥与日志层往往无人负责。

### D5 本 ADR 为隔离口径的唯一裁决载体

1. 本 ADR 生效后，各仓相关 PR **只做实现**；Review 范围限「是否按本 ADR 实现」，**不再重议口径**（对齐 ADR 0012 D4）。
2. 新意见 → 向本 ADR 提 **Amendment**（改 `GenzLTD/docs`），不在实现 PR 评论区辩论。
3. 新增边界（B5…）必须走本 ADR 的 Amendment，不得由单仓自行引入。

### D6 「隔离」不得用于规避审计（反模式声明）

**本 ADR 的隔离目标是「可追溯前提下的互不可见」，不是「不可关联」。**

组织不得以"防止被关联"为由规避留痕：所有隔离边界的操作日志必须**可溯源到人**。任何"为了隔离而删除/混淆审计线索"的做法，直接违反本 ADR。

---

## 分歧登记与裁决

| # | 分歧 / 阻塞 | 来源 | 裁决 |
|---|---|---|---|
| F1 | `looma-zervi` 到底处于哪一级 | 起草过程中出现"已是 L2"的说法 | **D1 + 取证 #1/#2**：实为 **L1**；"RLS 已落地"不成立，本 ADR 予以更正 |
| F2 | 要不要为多租户单独建边界 B1' | 起草讨论 | **暂不**。当前无 tenant 建模（取证 #2）；待 B2B 多租户立项时按 D5-3 走 Amendment 拆分 |
| F3 | 隔离与审计冲突（借"不可关联"逃留痕） | 本 ADR 起草时识别 | **D6**：明写为反模式，隔离不得削弱审计 |
| F4 | `gitee-sync-bot` 凭据是否确为全域写权限 PAT | 外部声明，本机无法取证 | **取证 #8【未取证】**：登记为待取证项；**取证前不得据此评级或指控**（R1） |
| F5 | 本议题该新开 ADR 还是并入 0012 的 Amendment | 起草讨论 | **新开 0013**。0012 是身份域（谁是谁），0013 是隔离域（谁能看见谁），议题独立、互为对偶；两条链互链即可 |

---

## 冻结口径表（生效后不得单方面变更）

| 项 | 口径 |
|---|---|
| 评级语言 | L0–L4；**词根承 ADR 0002 的 L0 命名，但轴不同**（0002 的 L0 = 敏感级最高；0013 的 L0 = 隔离强度最低），引用时必须写明出自哪条 ADR |
| 判定基线 | 一条边界的等级 = **最弱一维**；L0/L1 不得声明为"已隔离" |
| 边界清单 | B1 用户级 · B2 环境 · B3 主体与云 · B4 仓；新增须走 Amendment |
| 优先级 | 密钥 > 日志 > 数据 > 网络 |
| 证据要求 | **任何"已隔离"结论必须附取证**（`文件:行` 或可复现命令）；未取证不得作为结论 |
| 与 0012 的关系 | 0012 管身份可识别，0013 管边界可隔离；**互不替代**，争议各回本 ADR |
| 反模式 | 以"不可关联"为由削弱审计留痕（D6） |

---

## Consequences

### Positive

- 「隔离」从形容词变成**可比较的等级**：跨仓、跨云、跨主体的讨论有共同刻度。
- 误读被一次性定案（取证 #1/#2），避免"以为在 L2、实际在 L1"的风险误判继续外溢。
- 与 0012 形成完整的身份域口径：**身份可识别 + 边界可隔离**，两条 ADR 覆盖两端。
- 各仓 PR 的 review 范围收窄为「是否按本 ADR 实现」，消除重复辩论。

### Negative

- 引入一次跨仓盘点成本：四类边界 × 六维需逐格填实并取证。
- 附件清单**会随状态过期**，需要维护；不维护就会从"参考"退化为"误导"。
- 部分边界（B2/B3）可能需要新增配置或账户结构，非纯文档工作。

### Risks

| # | 风险 | 缓解 |
|---|---|---|
| R1 | **未取证断言被当成结论**（如取证 #8 的 PAT 作用域） | 冻结口径「证据要求」条；附件清单中未取证项显式标注 `【未取证】` |
| R2 | 有人把 L2 当成终点，不再往 L3 走 | D1 表中直接标注 **L3 = 组织目标位** |
| R3 | 只改一层就宣布"已隔离" | D3 最弱一维；评审时强制问"最弱是哪一维" |
| R4 | 借"指纹浏览器式"不可关联思路逃避审计留痕 | D6 明写反模式；日志维在矩阵中为必填列 |
| R5 | 0012 与 0013 口径互相漂移 | 两条 ADR 互链；争议各回本 ADR 走 Amendment，不在 PR 辩论 |
| R6 | 附件清单过期后被当作现状引用 | 附件首页标注「会过期，非决策记录，决策以 ADR 0013 为准」+ 取证日期 |
| R7 | **唯一门禁双重失效**：README 已把 CI 定为唯一守门人，但取证 #7/#7b 表明——① CI 因平台侧 runner 未分配而**间歇失败**；② branch protection / rulesets 在 Free + 私有仓下**不可用（403）**。二者叠加时，本仓事实上处于"无强制门禁"状态，本节「唯一裁决载体」的约束力随之悬空 | ① 门禁不可用时按 README 既有条款走**本地等效证据**（`mkdocs build --strict` dry-run 完整输出附 PR），并严格区分「平台侧不可用」与「真实破坏 build」；② 组织侧评估 Pro 升级以恢复 branch protection（费用见 `free-plan-governance-notes.md`） |

---

## Implementation checklist

- [ ] **Accept 本 ADR** —— Admin 单人签署即生效
- [ ] 更新 `docs/adrs/README.md` 索引与 `mkdocs.yml` 导航（本 PR 已含）
- [ ] 创建附件 `isolation-boundary-notes.md` 并填入四类边界 × 六维初版取值（本 PR 已含骨架）
- [ ] **B1**：确认 `SUPABASE_SECRET_KEY` 仅用于 Auth Admin API、未用于业务表读写（全仓 grep 取证）
- [ ] **B1**：明确 `looma-zervi` 的 L1 → L2/L3 路线（是否需要 RLS、是否需要独立 bucket）
- [ ] **B2**：定案 dev / prod 是否共用 Supabase project（当前仅 1 个 ref，取证 #3）；若共用，明写为"接受的例外"并登记理由
- [ ] **B3**：企业主体与个人主体的 AK/SK、DNS 凭据分账登记
- [ ] **B4**：`gitee-sync-bot` 凭据作用域**取证**（取证 #8），再决定是否降权
- [ ] **B4**：仓 push / PR / 权限变更留痕到人（CODEOWNERS 文件已就位，但 **Free + 私有仓下 GitHub 无法强制**，见取证 #7 / R7；补 branch protection 需先评估 Pro 升级）
- [ ] 评审人：`@szjason72` `@xiajason`（CODEOWNERS `/docs/adrs/`）；Admin Accept：`@szpeter2026` / `@zervi-genz`
- [ ] 成员停止在实现 PR / 聊天中重议本 ADR 已裁定的口径

---

## Links

- 对偶 ADR：[ADR 0012](0012-thomas-identity-unification.md) —— THOMAS 生态身份统一（身份可识别）
- 词根 ADR：[ADR 0002](0002-l0-pii-sg-deny-policy.md) —— L0 分级语言来源
- 单真源：[ADR 0008](0008-docs-single-source-site.md) —— 本 ADR 不进产品仓的理由
- 治理设施：[ADR 0006](0006-docs-governance-codespace.md) —— docs 仓 Codespace 改动路径
- 附件：[isolation-boundary-notes.md](isolation-boundary-notes.md)
- Supersedes：（无）
- Superseded by：（无）
