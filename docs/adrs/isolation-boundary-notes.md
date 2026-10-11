# 跨系统隔离边界：现状快照与待办清单

- **对象**: GenzLTD 组织 · 四类隔离边界（B1 用户级 / B2 环境 / B3 主体与云 / B4 仓）
- **性质**: **参考件 —— 状态会过期，不是决策记录。** 决策一律以 [ADR 0013](0013-cross-system-isolation-boundary.md) 为准
- **取证日期**: 2026-10-11（本机 `GenzLTD_org_backup_github` 快照核读）
- **目的**: 让 owner / 成员快速对齐——每条边界现在到底处于哪一级、哪一维最弱、下一步修什么

---

## 一、隔离边界矩阵（应然取值，取自 ADR 0013 D2）

> 取值：**共享** / **隔离** / **单向**。此表是"应该长什么样"，不是"现在长什么样"；现状见第二节。

| 隔离维度 | B1 用户级 | B2 环境 dev-prod | B3 主体与云 | B4 仓 |
|---|---|---|---|---|
| **身份** | 隔离：由服务端裁决，前端不参与判断 | 隔离：不同 project + 不同 JWT secret | 隔离：账号级分离，不交叉登录 | 单向：组织成员可读；镜像 bot 仅只读 |
| **数据** | 隔离：数据库级强制策略 + 独立 bucket | 隔离：禁止 prod 数据落 dev，脱敏后才可下沉 | 隔离：数据存放与备案／合规主体对应 | 单向：Gitee → GitHub 单向同步，禁止反向写 |
| **密钥** | 共享平台密钥但按用户独立配额计量 | **隔离：secret key 绝不共用** | 隔离：各自 AK/SK、DNS 凭据分开 | 隔离：per-repo token；禁个人 PAT 全域授权 |
| **网络出口** | 共享：同域；需防共享错误页／缓存侧信道 | 隔离：不同域名 + 回调白名单分开 | 隔离：独立 DNS 凭据与解析权 | 共享 |
| **日志审计** | 隔离：按 user_id 分账、可单独导出 | 隔离 | 隔离：谁的主体谁留痕 | 隔离：push / PR / 权限变更留痕到人 |
| **时序与配额** | 共享：但配额计数必须按用户独立 | 共享 | 共享 | 共享 |

---

## 二、现状快照（2026-10-11 取证）

### B1 用户级边界 —— 当前 **L1**（假隔离档）

| 维度 | 现状 | 等级 | 证据 |
|---|---|---|---|
| 身份 | 后端有鉴权中间件层 | — | `looma-zervi/backend/src/api/{auth,middleware,routes}` |
| 数据 | **无 RLS 策略**；隔离依赖应用层代码内用户过滤 | **L1** | 全仓 `grep -ril "enable row level security\|create policy"` → **0 命中**；无 migrations / supabase / policies 目录 |
| 数据 | **无多租户建模**（单租户） | — | `backend/src` 中 `tenant` 仅 `db/manager.py` 1 处词面命中 |
| 密钥 | `SUPABASE_SECRET_KEY` 用途为 Auth Admin API（建/绑微信·华为用户） | — | `api/auth/supabase_auth.py:5` 注释、`:33-35` |
| 日志审计 | 待取证 | — | — |

> ⚠️ **重要更正**：此前组织内出现过「`looma-zervi` 租户隔离已到 L2，因为 Supabase RLS 已落地」的表述。取证表明**该说法不成立**——既无 RLS 策略，也无多租户建模。请以本表为准。

### B2 环境 dev-prod —— 当前 **未建立**（证据缺失）

| 维度 | 现状 | 证据 |
|---|---|---|
| 密钥 / 身份 | **仅 1 个 Supabase project ref**，未见 dev / prod 第二 ref | `.env.example:20` → `SUPABASE_URL=https://ftsnrqwynofsxdvoxnsw.supabase.co` |
| 网络出口 | 环境分流落在 **nginx 层**（4 份 conf），非部署级隔离 | `deploy/nginx` + 仓根 `nginx-looma-zervi.conf` / `-ip.conf` / `-overseas.conf` / `nginx-vultr.conf` |

### B3 主体与云 —— 待填

| 边界对象 | 现状 |
|---|---|
| 企业主体（szbolent.com.cn @腾讯云） | 待登记 AK/SK、DNS 凭据归属 |
| 个人主体（szbolent.cn @阿里云） | 待登记 |
| 海外（Vercel + Vultr） | 待登记 |

### B4 仓边界 —— 部分到位

| 维度 | 现状 | 证据 |
|---|---|---|
| 日志审计（身份归属） | ⚠️ `docs` 仓 CODEOWNERS **文件已就位**，但 **Free 计划 + 私有仓下 GitHub 无法强制审批** —— `/docs/adrs/` 指定的 reviewer 不具约束力 | `.github/CODEOWNERS`；`gh api repos/GenzLTD/docs/branches/main/protection` → **403** `Upgrade to GitHub Pro or make this repository public`（`rulesets` 同为 403） |
| 门禁可用性（CI） | ⚠️ **间歇不可用**：近 40 次 run 中 11 次 failure，失败 job 为 `runner=-`、**0 step**、约 2s 退出（runner 未被分配，非文档断链） | 失败 run `38100275469` / `38062715391` vs 成功 run `38063534617`（`runner=GitHub Actions 1000002863`、5 step） |
| 密钥 | ⚠️ **【未取证】** `gitee-sync-bot` 被声明使用全域写权限 PAT | 该仓不在本机快照（属 `zervi-genz` 个人账号），需 GitHub 侧查 workflow secrets 与 token scope |

> ⚠️ **U4 是本表中唯一的高危待核项，但在取证前不得据此评级或指控**（ADR 0013 D1「取证」纪律 / R1）。

---

## 三、待办（按 ADR 0013 D4 优先级：密钥 > 日志 > 数据 > 网络）

| # | 边界 | 动作 | 优先级 | 前置 |
|---|---|---|---|---|
| U1 | B1 | 确认 `SUPABASE_SECRET_KEY` 未用于业务表读写（全仓 grep 取证） | **P0 密钥** | 无 |
| U2 | B4 | `gitee-sync-bot` 凭据作用域**取证**，再决定是否降为 per-repo / 只读 | **P0 密钥** | 需 GitHub 权限访问该仓 |
| U3 | B1 | 定路线：L1 → L2（RLS）→ L3（独立 bucket / 独立密钥） | P1 数据 | ADR 0013 Accept |
| U4 | B2 | 定案 dev / prod 是否共用 Supabase project；若共用，明写为"接受的例外"并登记理由 | P1 数据 | 无 |
| U5 | B3 | 企业主体 / 个人主体的 AK-SK、DNS 凭据分账登记 | P1 数据 | 无 |
| U6 | B4 | 补 branch protection 与审计导出（**前置：评估 Pro 升级** —— Free + 私有仓下 `protection` / `rulesets` 均 403，CODEOWNERS 无法强制） | P2 日志 | 组织计划决策 |
| U7 | 全 | 把第二节矩阵逐格填实（现状值 + 取证），替换占位 | P2 | U1–U5 |
| U8 | 全 | 门禁不可用时启用「本地 `mkdocs build --strict` 等效证据」流程，并回写 README —— 明确区分「平台侧 runner 不可用」与「真实破坏 build」两类失败 | **P1 日志** | 无 |

---

## 四、取证方法（可复现）

```bash
# 取证 #1 —— RLS 策略是否存在（预期：0 命中 = 无 RLS）
grep -ril "enable row level security\|create policy" looma-zervi \
  --include=*.sql --include=*.py --include=*.md

# 取证 #2 —— 是否存在多租户建模
grep -ril "tenant_id\|tenant" looma-zervi/backend/src --include=*.py

# 取证 #3 —— Supabase project 数量（环境分离线索）
grep -in "supabase" looma-zervi/.env.example

# 取证 #4 —— secret key 使用点
grep -rl "service_role\|SERVICE_ROLE_KEY\|SUPABASE_SECRET_KEY" looma-zervi \
  --include=*.py --include=*.ts --include=*.tsx

# 取证 #7 —— CODEOWNERS 文件内容
cat docs/.github/CODEOWNERS

# 取证 #7b —— CODEOWNERS 是否真能被 GitHub 强制（预期：403 = 不能强制）
gh api repos/GenzLTD/docs/branches/main/protection
gh api repos/GenzLTD/docs/rulesets

# 取证 #7c —— CI 失败是"平台侧不可用"还是"内容破坏 build"（看 runner 与 steps）
gh api repos/GenzLTD/docs/actions/runs/<run_id>/jobs
#   runner=- 且 steps 为空 → runner 未被分配（平台侧）；有 step 且 Build 步骤失败 → 内容问题

# 取证 #8 —— gitee-sync-bot 凭据作用域（需在 GitHub 侧另做，本机无法完成）
#   查其 .github/workflows/*.yml 引用的 secrets 名，再核对应 PAT 的 scope
```

> **纪律**：任何新增的"已隔离"结论，都必须在本文件登记一条与之匹配的取证命令或 `文件:行` 引用。**没有取证的结论不进本表。**
>
> **同样适用于"设施已生效/门禁已就位"一类结论** —— 2026-10-11 巡检即发现：`CODEOWNERS 已生效` 与 `CI 为唯一守门人` 两条既有表述，在 Free + 私有仓的现实下均需降级为「文件就位，但无法强制 / 间歇可用」（见 B4）。**"文件存在"不等于"约束生效"。**
